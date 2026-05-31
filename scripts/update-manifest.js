#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

// Inline .env parser (no external deps)
if (fs.existsSync('.env')) {
  fs.readFileSync('.env', 'utf8').split('\n').forEach(line => {
    const m = line.match(/^([^=\s]+)\s*=\s*(.*)$/);
    if (m) process.env[m[1]] = m[2].trim();
  });
}

const SOURCE_DIR = process.env.SOURCE_DIR ||
  '/Users/adamrossmini/Library/Mobile Documents/com~apple~CloudDocs/Personal/Family/Family Videos';

const MANIFEST = 'videos.json';

function slugify(filename) {
  return filename
    .replace(/\.[^.]+$/, '')            // remove extension
    .replace(/^\d+[\.\s]+/, '')          // strip leading "10. " / "5."
    .replace(/\.{2,}/g, ' ')            // run of dots → space
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')        // non-alnum → hyphen
    .replace(/^-+|-+$/g, '');           // trim hyphens
}

function autoTitle(filename) {
  return filename
    .replace(/\.[^.]+$/, '')
    .replace(/^\d+[\.\s]+/, '')
    .replace(/\.{2,}/g, ' ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

// Preserve any titles Adam has already edited
const existing = {};
if (fs.existsSync(MANIFEST)) {
  JSON.parse(fs.readFileSync(MANIFEST, 'utf8')).forEach(v => {
    existing[v.sourceFile] = v;
  });
}

const files = fs.readdirSync(SOURCE_DIR)
  .filter(f => /\.(mp4|mov|avi|mkv)$/i.test(f))
  .filter(f => {
    try { return !fs.statSync(path.join(SOURCE_DIR, f)).isDirectory(); } catch { return false; }
  })
  .sort();

const manifest = files.map(filename => {
  const slug = slugify(filename) || filename.replace(/\.[^.]+$/, '');
  const prev = existing[filename];
  return {
    title: prev ? prev.title : autoTitle(filename),
    slug,
    sourceFile: filename,
    transcodedFile: `${slug}.mp4`,
    posterFile: `${slug}.jpg`,
    originalFile: filename,
  };
});

fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2) + '\n');
console.log(`Wrote ${manifest.length} entries to ${MANIFEST}:`);
manifest.forEach(v => console.log(`  ${v.slug.padEnd(40)} "${v.title}"`));
