#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then set -a; source .env; set +a; fi

: "${FAMILY_PASSPHRASE:?Set FAMILY_PASSPHRASE in .env}"

# Copy freshly generated posters to docs/ (committed to git, served by GitHub Pages)
mkdir -p docs/posters
cp work/posters/*.jpg docs/posters/ 2>/dev/null || echo "  (no posters to copy)"

# Encrypt gallery with StatiCrypt
# staticrypt -o takes a directory; write to a temp dir then move to docs/index.html
rm -rf work/encrypted
npx staticrypt work/gallery.html \
  -p "$FAMILY_PASSPHRASE" \
  --short \
  -d work/encrypted \
  --template-title "The Ross Family" \
  --template-instructions "Enter the family passphrase to unlock the videos." \
  --template-button "Unlock" \
  --remember 30

mv work/encrypted/gallery.html docs/index.html
echo "Encrypted gallery written to docs/index.html"

# Commit and push
git add docs/
git status --short

if git diff --cached --quiet; then
  echo "Nothing new to commit."
else
  git commit -m "Update gallery $(date '+%Y-%m-%d')"
  git push
  echo "Pushed to GitHub Pages."
fi
