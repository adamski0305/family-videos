#!/usr/bin/env bash
# One-time Bunny CDN setup — run this before the first build.
# Creates a Storage Zone, a linked Pull Zone, sets Allowed Referrers,
# and prints the values to add to .env
set -euo pipefail

if [ -f .env ]; then set -a; source .env; set +a; fi

: "${BUNNY_ACCOUNT_API_KEY:?Set BUNNY_ACCOUNT_API_KEY in .env first}"

ZONE_NAME="${BUNNY_STORAGE_ZONE_NAME:-theross-family}"
PULL_ZONE_NAME="${ZONE_NAME}-cdn"

echo "=== Creating Storage Zone: $ZONE_NAME ==="
SZ_RESP=$(curl -s -X POST "https://api.bunny.net/storagezone" \
  -H "AccessKey: ${BUNNY_ACCOUNT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"${ZONE_NAME}\",\"Region\":\"SG\"}")

echo "$SZ_RESP" | python3 -m json.tool 2>/dev/null || echo "$SZ_RESP"

SZ_ID=$(echo "$SZ_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['Id'])" 2>/dev/null || echo "")
SZ_PASSWORD=$(echo "$SZ_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['Password'])" 2>/dev/null || echo "")

if [ -z "$SZ_ID" ]; then
  echo "ERROR: Failed to parse Storage Zone ID. Check the response above." >&2
  exit 1
fi

echo ""
echo "=== Creating Pull Zone: $PULL_ZONE_NAME (linked to storage zone $SZ_ID) ==="
PZ_RESP=$(curl -s -X POST "https://api.bunny.net/pullzone" \
  -H "AccessKey: ${BUNNY_ACCOUNT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"Name\": \"${PULL_ZONE_NAME}\",
    \"OriginType\": 2,
    \"StorageZoneId\": ${SZ_ID},
    \"EnableGeoZoneUS\": true,
    \"EnableGeoZoneEU\": true,
    \"EnableGeoZoneASIA\": true,
    \"EnableGeoZoneSA\": true,
    \"EnableGeoZoneAF\": true
  }")

echo "$PZ_RESP" | python3 -m json.tool 2>/dev/null || echo "$PZ_RESP"

PZ_ID=$(echo "$PZ_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['Id'])" 2>/dev/null || echo "")
PZ_HOSTNAME=$(echo "$PZ_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['Hostnames'][0]['Value'])" 2>/dev/null || echo "")

echo ""
echo "=== Adding Allowed Referrer: videos.theross.family ==="
curl -s -X POST "https://api.bunny.net/pullzone/${PZ_ID}/addAllowedReferrer" \
  -H "AccessKey: ${BUNNY_ACCOUNT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"Hostname\": \"videos.theross.family\"}" | python3 -m json.tool 2>/dev/null || true

echo ""
echo "=== Adding custom hostname: media.theross.family ==="
curl -s -X POST "https://api.bunny.net/pullzone/${PZ_ID}/addHostname" \
  -H "AccessKey: ${BUNNY_ACCOUNT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"Hostname\": \"media.theross.family\"}" | python3 -m json.tool 2>/dev/null || true

echo ""
echo "==================================================================="
echo " BUNNY SETUP COMPLETE"
echo ""
echo " Add these lines to your .env file:"
echo "   BUNNY_STORAGE_ZONE_NAME=${ZONE_NAME}"
echo "   BUNNY_STORAGE_ZONE_PASSWORD=${SZ_PASSWORD}"
echo ""
echo " DNS record to add at GoDaddy:"
echo "   CNAME  media  ${PZ_HOSTNAME}"
echo ""
echo " Then enable Force SSL on the Pull Zone in the Bunny dashboard."
echo "==================================================================="
