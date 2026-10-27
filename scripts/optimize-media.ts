// scripts/optimize-media.ts
// Inspects SVG and raster assets, verifies embedded bitmaps vs true vectors, reports sizes
// Run with: npx tsx scripts/optimize-media.ts

import * as fs from 'fs';
import * as path from 'path';

interface MediaReport {
  file: string;
  sizeBytes: number;
  type: string;
  hasEmbeddedRaster: boolean;
  recommendation: string;
}

const mediaDir = path.resolve(__dirname, '../../'); // drive-download root

function inspectFile(filename: string): MediaReport | null {
  const fullPath = path.join(mediaDir, filename);
  if (!fs.existsSync(fullPath)) return null;
  const stats = fs.statSync(fullPath);
  const ext = path.extname(filename).toLowerCase();

  let hasEmbeddedRaster = false;
  let recommendation = 'Serve as-is';

  if (ext === '.svg') {
    try {
      const content = fs.readFileSync(fullPath, 'utf8');
      if (content.includes('image/png') || content.includes('image/jpeg') || content.includes('<image')) {
        hasEmbeddedRaster = true;
        recommendation = 'Converts to WebP (400, 800, 1600px widths) for high-efficiency mobile delivery';
      } else {
        recommendation = 'True vector SVG — serve with gzip/brotli';
      }
    } catch {}
  } else if (ext === '.mp4') {
    recommendation = 'Compress to H.264 MP4 ≤8MB, generate WebP poster, preload="none"';
  } else if (['.jpg', '.jpeg', '.png'].includes(ext)) {
    recommendation = 'Convert to WebP / AVIF responsive srcset';
  }

  return {
    file: filename,
    sizeBytes: stats.size,
    type: ext,
    hasEmbeddedRaster,
    recommendation,
  };
}

console.log('=== Media Asset Inspection & Optimization Pipeline ===');
console.log('Scanning 91 catalog media assets...\n');

let totalSize = 0;
const reports: MediaReport[] = [];

for (let i = 1; i <= 82; i++) {
  const r = inspectFile(`${i}.svg`);
  if (r) {
    reports.push(r);
    totalSize += r.sizeBytes;
  }
}

// Special P17 files
const p17Extras = [
  '43.jpg', '44.jpg', '45.jpg',
  'ChatGPT Image Apr 22, 2026, 11_47_30 AM.png',
  'ChatGPT Image Apr 22, 2026, 11_57_00 AM.png',
  'ChatGPT Image Apr 22, 2026, 11_57_35 AM.png',
  'Blue and Yellow Modern Online Course Flyer Landscape (2).mp4',
  'New_video2_ryece1.mp4'
];

for (const extra of p17Extras) {
  const r = inspectFile(extra);
  if (r) {
    reports.push(r);
    totalSize += r.sizeBytes;
  }
}

console.log(`Total catalog media assets inspected: ${reports.length}`);
console.log(`Total raw assets size: ${(totalSize / (1024 * 1024)).toFixed(2)} MB`);
console.log('Sample reports:');
console.table(reports.slice(0, 10));
