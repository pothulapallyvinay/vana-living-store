// src/pages/sitemap.xml.ts
// Dynamic sitemap generator incorporating products, collections, and editorial content pages
import type { APIRoute } from 'astro';
import { site } from '../config/site';
import { getDB, all } from '../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  let products: { slug: string; updated_at?: string }[] = [];
  let categories: { slug: string }[] = [];

  if (env?.DB) {
    try {
      const db = getDB(env);
      products = await all(db, `SELECT slug, updated_at FROM products WHERE is_active = 1`);
      categories = await all(db, `SELECT slug FROM categories WHERE is_active = 1`);
    } catch {}
  }

  const staticPages = [
    '',
    '/collections/all',
    '/collections/wall-art',
    '/collections/lighting',
    '/collections/clocks',
    '/collections/matra-haus',
    '/about',
    '/contact',
    '/faq',
    '/bulk-orders',
    '/policies/shipping-delivery',
    '/policies/returns-refunds',
    '/policies/terms',
    '/policies/privacy',
  ];

  const now = new Date().toISOString();

  let xml = `<?xml version="1.0" encoding="UTF-8"?>\n`;
  xml += `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n`;

  // Static Pages
  for (const p of staticPages) {
    xml += `  <url>\n`;
    xml += `    <loc>${site.url}${p}</loc>\n`;
    xml += `    <lastmod>${now}</lastmod>\n`;
    xml += `    <changefreq>${p === '' ? 'daily' : 'weekly'}</changefreq>\n`;
    xml += `    <priority>${p === '' ? '1.0' : '0.8'}</priority>\n`;
    xml += `  </url>\n`;
  }

  // Dynamic Categories
  for (const c of categories) {
    xml += `  <url>\n`;
    xml += `    <loc>${site.url}/collections/${c.slug}</loc>\n`;
    xml += `    <lastmod>${now}</lastmod>\n`;
    xml += `    <changefreq>weekly</changefreq>\n`;
    xml += `    <priority>0.85</priority>\n`;
    xml += `  </url>\n`;
  }

  // Dynamic Products
  for (const prod of products) {
    xml += `  <url>\n`;
    xml += `    <loc>${site.url}/products/${prod.slug}</loc>\n`;
    xml += `    <lastmod>${prod.updated_at || now}</lastmod>\n`;
    xml += `    <changefreq>weekly</changefreq>\n`;
    xml += `    <priority>0.9</priority>\n`;
    xml += `  </url>\n`;
  }

  xml += `</urlset>`;

  return new Response(xml, {
    status: 200,
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
};
