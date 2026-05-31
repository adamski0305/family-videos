#!/usr/bin/env bash
set -euo pipefail

# Load secrets from .env
if [ -f .env ]; then
  set -a; source .env; set +a
fi

SOURCE_DIR="${SOURCE_DIR:-/Users/adamrossmini/Library/Mobile Documents/com~apple~CloudDocs/Personal/Family/Family Videos}"

echo "==================================================================="
echo " theross.family video gallery — full build"
echo "==================================================================="
echo ""

echo "--- 1/5  Transcoding source videos ---"
bash scripts/transcode.sh

echo ""
echo "--- 2/5  Refreshing videos.json manifest ---"
node scripts/update-manifest.js

echo ""
echo "--- 3/5  Building gallery HTML ---"
node scripts/build-gallery.js

echo ""
echo "--- 4/5  Uploading to Bunny CDN ---"
: "${BUNNY_STORAGE_ZONE_PASSWORD:?Set BUNNY_STORAGE_ZONE_PASSWORD in .env}"
: "${BUNNY_STORAGE_ZONE_NAME:?Set BUNNY_STORAGE_ZONE_NAME in .env}"
bash scripts/upload-bunny.sh

echo ""
echo "--- 5/5  Encrypting + committing ---"
: "${FAMILY_PASSPHRASE:?Set FAMILY_PASSPHRASE in .env}"
bash scripts/encrypt-deploy.sh

echo ""
echo "==================================================================="
echo " BUILD COMPLETE"
echo " Live URL  : https://videos.theross.family"
echo " Passphrase: ${FAMILY_PASSPHRASE}"
echo ""
echo " DNS records needed at GoDaddy (if not already added):"
echo "   CNAME  videos   adamski0305.github.io"
echo "   CNAME  media    <your-bunny-pull-zone>.b-cdn.net"
echo "==================================================================="
