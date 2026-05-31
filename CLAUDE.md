# Project: theross.family private video gallery

## Goal
Build and deploy a password-protected family video gallery. The gallery is a
static site on GitHub Pages at https://videos.theross.family. The videos
themselves are stored on and streamed from Bunny (https://media.theross.family).
Audience is non-technical relatives on iPhone, Android, Mac and Windows. They
must NOT need any account — just the URL and one shared passphrase.

## Architecture
- Gallery: static HTML/CSS/JS, deployed via GitHub Pages from this repo's
  `main` branch (or `/docs`). Only small files live here (HTML, JS, CSS,
  poster thumbnails). NEVER commit video files to git.
- Videos + originals: uploaded to a Bunny Storage Zone, served via a linked
  Bunny Pull Zone at https://media.theross.family.
- The gallery HTML is encrypted with StatiCrypt using the family passphrase
  before deploy, so the published page is AES-encrypted ciphertext.

## Hard requirements
- Cross-platform: use H.264/AAC MP4 (yuv420p, faststart) so every browser and
  smart-TV browser can stream it. Generate adaptive sizes only if asked.
- Each video needs: a streamable MP4, a poster thumbnail (JPEG, ~1280px wide
  grabbed a few seconds in), a human title, and a "Download original" link.
- Keep the originals too: upload untouched masters to an `/originals/` path on
  Bunny and link them from a download button.
- Privacy: add `<meta name="robots" content="noindex,nofollow">`, ship a
  `robots.txt` disallowing all, and rely on Bunny Token Authentication +
  Allowed Referrers (videos.theross.family) so file URLs don't work off-site.
- No analytics, no third-party trackers, no external fonts/CDNs in the page.

## Source material
- Master videos are at: ~/family-videos-source  (Adam will confirm the path)
- Roughly 13 GB today; design so adding more later is a one-command job.

## Secrets (Adam will paste these; never hard-code them in committed files)
- BUNNY_ACCOUNT_API_KEY
- BUNNY_STORAGE_ZONE_PASSWORD (available after the storage zone is created)
- BUNNY_STORAGE_ZONE_NAME
- FAMILY_PASSPHRASE (used only at build time for StatiCrypt; never commit it)
Store working values in a local `.env` that is git-ignored. Confirm `.gitignore`
excludes `.env`, `*.mp4`, `*.mov`, `node_modules`, and the source video folder.

## Build pipeline (make it a single `./build.sh` or npm script)
1. Transcode each source video to web MP4 with ffmpeg
   (-c:v libx264 -preset medium -crf 21 -c:a aac -movflags +faststart -pix_fmt yuv420p).
2. Generate a poster JPEG per video (ffmpeg -ss 00:00:03 -frames:v 1).
3. Write/refresh a `videos.json` manifest (title, filename, poster, originalfile).
4. Build the gallery HTML/JS from the manifest (responsive grid, HTML5 <video>
   player, download button per item).
5. Upload transcoded MP4s, posters, and originals to Bunny Storage via the
   Storage API (PUT per file) using BUNNY_STORAGE_ZONE_PASSWORD.
6. Encrypt the built index.html with StatiCrypt + FAMILY_PASSPHRASE.
7. Commit the encrypted site + posters to git and push; GitHub Pages deploys.

## Deploy / ops
- Use the `gh` CLI for repo creation and auth (interactive browser login is fine).
- Adding new videos later = drop files in the source folder, run the build
  script, push. Document this in a README for Adam.
- Print a final summary: the live URL, the passphrase reminder, and the exact
  DNS records still needed at GoDaddy if not yet added.