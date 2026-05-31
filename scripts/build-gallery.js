#!/usr/bin/env node
'use strict';

const fs = require('fs');

if (fs.existsSync('.env')) {
  fs.readFileSync('.env', 'utf8').split('\n').forEach(line => {
    const m = line.match(/^([^=\s]+)\s*=\s*(.*)$/);
    if (m) process.env[m[1]] = m[2].trim();
  });
}

const CDN = 'https://media.theross.family';
// Posters are served from GitHub Pages (small files, committed to git)
const PAGES = 'https://videos.theross.family';

const videos = JSON.parse(fs.readFileSync('videos.json', 'utf8'));

function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

let cards = '';
videos.forEach((v, i) => {
  const videoUrl = `${CDN}/${v.transcodedFile}`;
  const posterUrl = `${PAGES}/posters/${v.posterFile}`;
  const origUrl   = `${CDN}/originals/${encodeURIComponent(v.originalFile)}`;

  cards += `
    <div class="card" onclick="playVideo(${i})">
      <div class="thumb">
        <img src="${esc(posterUrl)}" alt="${esc(v.title)}" loading="lazy">
        <div class="play-btn" aria-label="Play ${esc(v.title)}">&#9654;</div>
      </div>
      <div class="card-info">
        <h2>${esc(v.title)}</h2>
        <a class="dl-btn" href="${esc(origUrl)}" download="${esc(v.originalFile)}" onclick="event.stopPropagation()">&#8595; Download original</a>
      </div>
    </div>`;
});

const videoData = videos.map(v => ({
  title: v.title,
  src:   `${CDN}/${v.transcodedFile}`,
  poster: `${PAGES}/posters/${v.posterFile}`,
  orig:  `${CDN}/originals/${encodeURIComponent(v.originalFile)}`,
}));

const template = fs.readFileSync('templates/gallery.html', 'utf8');
const output = template
  .replace('<!-- VIDEO_CARDS -->', cards)
  .replace('/* VIDEO_DATA */', `const VIDEOS = ${JSON.stringify(videoData, null, 2)};`);

fs.mkdirSync('work', { recursive: true });
fs.writeFileSync('work/gallery.html', output);
console.log(`Built work/gallery.html with ${videos.length} video(s).`);
