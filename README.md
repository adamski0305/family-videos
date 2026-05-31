# theross.family Private Video Gallery

Password-protected family video archive at https://videos.theross.family.

## How it works

- Gallery page: static HTML encrypted with StatiCrypt, served by GitHub Pages
- Videos: H.264/AAC MP4s hosted on Bunny CDN at https://media.theross.family
- Originals: untouched source files stored in `/originals/` on Bunny

## First-time setup

1. Copy `.env.example` to `.env` and fill in all values
2. Run Bunny CDN setup: `bash scripts/setup-bunny.sh`
3. Add the DNS records it prints to GoDaddy
4. Run the full build: `./build.sh`

## Adding new videos

1. Drop the new video file into the source folder
2. Run `./build.sh`

The script skips files it has already transcoded, so only new videos are processed.

## Editing video titles

Edit `videos.json` directly — change the `"title"` field for any entry.  
Re-running `./build.sh` preserves your custom titles.

## Environment variables (`.env`)

| Variable | Description |
|---|---|
| `SOURCE_DIR` | Path to the source video folder |
| `BUNNY_ACCOUNT_API_KEY` | Bunny.net account API key |
| `BUNNY_STORAGE_ZONE_NAME` | Name of the Bunny Storage Zone |
| `BUNNY_STORAGE_ZONE_PASSWORD` | Password for the Bunny Storage Zone |
| `FAMILY_PASSPHRASE` | Passphrase shown to family members at the gallery URL |

## DNS records (GoDaddy)

| Type | Name | Value |
|---|---|---|
| CNAME | `videos` | `adamski0305.github.io` |
| CNAME | `media` | `<pull-zone>.b-cdn.net` (printed by `setup-bunny.sh`) |
