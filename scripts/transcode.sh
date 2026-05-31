#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then set -a; source .env; set +a; fi

SOURCE_DIR="${SOURCE_DIR:-/Users/adamrossmini/Library/Mobile Documents/com~apple~CloudDocs/Personal/Family/Family Videos}"

mkdir -p work/transcoded work/posters

# Derive a URL-safe slug from a filename
slugify() {
  local name="${1%.*}"                          # strip extension
  name=$(echo "$name" | sed 's/^[0-9]*[. ]*//')  # strip leading "10. " / "5."
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
  name=$(echo "$name" | sed 's/[^a-z0-9]/-/g')   # non-alnum → hyphen
  name=$(echo "$name" | sed 's/-\{2,\}/-/g')     # collapse hyphens
  name=$(echo "$name" | sed 's/^-//;s/-$//')     # trim hyphens
  echo "$name"
}

found=0
while IFS= read -r -d '' src; do
  filename=$(basename "$src")
  slug=$(slugify "$filename")

  out_mp4="work/transcoded/${slug}.mp4"
  out_poster="work/posters/${slug}.jpg"

  if [ -f "$out_mp4" ]; then
    echo "  [skip]      $filename  (already transcoded)"
  else
    echo "  [transcode] $filename → ${slug}.mp4"
    ffmpeg -i "$src" \
      -c:v libx264 -preset medium -crf 21 \
      -c:a aac -b:a 128k \
      -movflags +faststart \
      -pix_fmt yuv420p \
      -vf "scale=-2:720" \
      -y "$out_mp4" \
      2>&1 | grep -E "^(frame|error|Error)" | tail -3 || true
  fi

  if [ -f "$out_poster" ]; then
    echo "  [skip]      poster exists: ${slug}.jpg"
  else
    echo "  [poster]    $filename → ${slug}.jpg"
    ffmpeg -ss 00:00:03 -i "$src" \
      -frames:v 1 \
      -vf "scale=1280:-2" \
      -q:v 3 \
      -y "$out_poster" \
      2>&1 | grep -E "^(frame|error|Error)" | tail -1 || true
  fi

  found=$((found + 1))
done < <(find "$SOURCE_DIR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" \) -print0 | sort -z)

echo "Transcoding complete. Processed ${found} source file(s)."
