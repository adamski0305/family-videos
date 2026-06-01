#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Personal/Family/Family Videos"
OUT="$HOME/family-videos/transcoded"
LOG="$HOME/family-videos/transcode.log"
mkdir -p "$OUT"
: > "$LOG"

shopt -s nullglob
for f in "$SRC"/*.mp4; do
  name="$(basename "$f")"
  out="$OUT/$(echo "${name%.*}" | tr '[:upper:] ' '[:lower:]-' | tr -cd '[:alnum:]-').mp4"

  if [[ -f "$out" ]]; then
    echo "SKIP (already done): $name"
    continue
  fi

  echo "----------------------------------------"
  echo "ENCODING: $name"
  echo "----------------------------------------"

  if ffmpeg -y -i "$f" \
      -vf "yadif=mode=1,format=yuv420p" \
      -c:v h264_videotoolbox -b:v 4000k \
      -c:a aac -b:a 160k \
      -movflags +faststart \
      "$out" 2>>"$LOG"; then
    echo "OK: $name -> $(basename "$out")"
  else
    echo "FAILED: $name  (see $LOG)"
  fi
done

echo "Done. Full ffmpeg log at: $LOG"
