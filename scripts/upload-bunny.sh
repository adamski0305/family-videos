#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then set -a; source .env; set +a; fi

: "${BUNNY_STORAGE_ZONE_NAME:?Set BUNNY_STORAGE_ZONE_NAME in .env}"
: "${BUNNY_STORAGE_ZONE_PASSWORD:?Set BUNNY_STORAGE_ZONE_PASSWORD in .env}"

SOURCE_DIR="${SOURCE_DIR:-/Users/adamrossmini/Library/Mobile Documents/com~apple~CloudDocs/Personal/Family/Family Videos}"
BASE="https://storage.bunnycdn.com/${BUNNY_STORAGE_ZONE_NAME}"

bunny_put() {
  local local_file="$1"
  local remote_path="$2"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "AccessKey: ${BUNNY_STORAGE_ZONE_PASSWORD}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@${local_file}" \
    "${BASE}/${remote_path}")
  if [ "$code" = "201" ] || [ "$code" = "200" ]; then
    echo "  [ok $code] $remote_path"
  else
    echo "  [FAIL $code] $remote_path" >&2
    return 1
  fi
}

echo "Uploading transcoded MP4s..."
for f in work/transcoded/*.mp4; do
  [ -f "$f" ] || continue
  bunny_put "$f" "$(basename "$f")"
done

echo "Uploading originals..."
node -e "
const v = require('./videos.json');
v.forEach(x => process.stdout.write(x.originalFile + '\n'));
" | while IFS= read -r orig; do
  src="${SOURCE_DIR}/${orig}"
  if [ -f "$src" ]; then
    # URL-encode the remote path
    encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$orig")
    bunny_put "$src" "originals/${encoded}"
  else
    echo "  [warn] not found: $orig" >&2
  fi
done

echo "Upload complete."
