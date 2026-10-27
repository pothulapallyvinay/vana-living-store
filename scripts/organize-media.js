// scripts/organize-media.js
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const baseDir = path.resolve(__dirname, '../../..');
const targetBase = path.resolve(__dirname, '../public/media/products');

const mapping = {
  P01: ['1.svg', '2.svg', '3.svg'],
  P02: ['4.svg', '5.svg', '6.svg'],
  P03: ['7.svg', '8.svg', '9.svg'],
  P04: ['10.svg', '11.svg', '12.svg'],
  P05: ['13.svg', '14.svg', '15.svg'],
  P06: ['16.svg', '17.svg'],
  P07: ['18.svg', '19.svg', '20.svg'],
  P08: ['21.svg', '22.svg'],
  P09: ['23.svg', '24.svg', '25.svg'],
  P10: ['26.svg', '27.svg'],
  P11: ['28.svg'],
  P12: ['29.svg', '30.svg', '31.svg'],
  P13: ['32.svg', '33.svg', '34.svg'],
  P14: ['35.svg', '38.svg'],
  P15: ['36.svg'],
  P16: ['37.svg'],
  P17: ['39.svg', '40.svg', '41.svg', '43.jpg', '44.jpg', '45.jpg'],
  P18: ['42.svg', '43.svg', '44.svg'],
  P19: ['45.svg', '46.svg', '47.svg'],
  P20: ['48.svg', '49.svg', '50.svg'],
  P21: ['51.svg', '52.svg', '53.svg'],
  P22: ['54.svg', '55.svg', '56.svg'],
  P23: ['57.svg', '58.svg', '59.svg'],
  P24: ['60.svg', '61.svg', '62.svg'],
  P25: ['63.svg', '64.svg', '65.svg'],
  P26: ['66.svg', '67.svg', '68.svg'],
  P27: ['69.svg', '70.svg', '71.svg', '72.svg'],
  P28: ['73.svg', '74.svg', '76.svg'],
  P29: ['75.svg', '77.svg', '78.svg'],
  P30: ['79.svg'],
  P31: ['80.svg'],
  P32: ['81.svg', '82.svg']
};

const p17Renames = {
  'ChatGPT Image Apr 22, 2026, 11_47_30 AM.png': 'render-1.png',
  'ChatGPT Image Apr 22, 2026, 11_57_00 AM.png': 'render-2.png',
  'ChatGPT Image Apr 22, 2026, 11_57_35 AM.png': 'render-3.png',
  'Blue and Yellow Modern Online Course Flyer Landscape (2).mp4': 'video-1.mp4',
  'New_video2_ryece1.mp4': 'video-2.mp4'
};

let copiedCount = 0;

for (const [prodId, files] of Object.entries(mapping)) {
  const prodDir = path.join(targetBase, prodId);
  if (!fs.existsSync(prodDir)) {
    fs.mkdirSync(prodDir, { recursive: true });
  }

  for (const file of files) {
    const src = path.join(baseDir, file);
    const dest = path.join(prodDir, file);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, dest);
      copiedCount++;
    }
  }
}

const p17Dir = path.join(targetBase, 'P17');
for (const [orig, renamed] of Object.entries(p17Renames)) {
  const src = path.join(baseDir, orig);
  const dest = path.join(p17Dir, renamed);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dest);
    copiedCount++;
  }
}

console.log(`Successfully organized and copied ${copiedCount} catalog media files into public/media/products/`);
