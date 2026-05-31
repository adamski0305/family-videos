#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then set -a; source .env; set +a; fi

: "${FAMILY_PASSPHRASE:?Set FAMILY_PASSPHRASE in .env}"

# Copy freshly generated posters to docs/ (committed to git, served by GitHub Pages)
mkdir -p docs/posters
cp work/posters/*.jpg docs/posters/ 2>/dev/null || echo "  (no posters to copy)"

# Encrypt gallery with StatiCrypt
npx staticrypt work/gallery.html \
  --password "$FAMILY_PASSPHRASE" \
  --output docs/index.html \
  --template-title "The Ross Family" \
  --template-instructions "Enter the family passphrase to unlock the videos." \
  --template-button "Unlock" \
  --remember 30

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
