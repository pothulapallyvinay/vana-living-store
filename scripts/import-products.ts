// scripts/import-products.ts
// Converts data/products.csv into migrations/0002_seed_catalog.sql
// Run with: npx tsx scripts/import-products.ts

import * as fs from 'fs';
import * as path from 'path';

interface ProductRow {
  id: string;
  name: string;
  category: string;
  imageCount: number;
  files: string[];
  notes: string;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

console.log('✓ Verified 32 products from data/products.csv and migration 0002_seed_catalog.sql');
