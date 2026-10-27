// src/pages/api/admin/bulk-import.ts
// Bulk CSV import and export for product prices, sizes, and stock
import type { APIRoute } from 'astro';
import { getDB, run, all } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  // Export current catalog as editable CSV
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) {
    return new Response('Database unavailable', { status: 503 });
  }

  const db = getDB(env);
  const rows = await all<{
    id: string;
    name: string;
    size_label: string | null;
    price_paise: number | null;
    compare_at_paise: number | null;
    stock: number;
    sku: string | null;
  }>(db, `
    SELECT p.id, p.name, v.size_label, v.price_paise, v.compare_at_paise, v.stock, v.sku
    FROM products p
    JOIN product_variants v ON v.product_id = p.id AND v.is_default = 1
    ORDER BY p.id ASC
  `);

  const headers = ['Product ID', 'Product Name', 'Size / Dimensions', 'Price in INR', 'Compare at INR', 'Stock Qty', 'SKU'];
  const lines = [headers.join(',')];

  for (const r of rows) {
    const priceRupees = r.price_paise ? (r.price_paise / 100).toFixed(0) : '';
    const compareRupees = r.compare_at_paise ? (r.compare_at_paise / 100).toFixed(0) : '';
    lines.push([
      r.id,
      `"${r.name.replace(/"/g, '""')}"`,
      `"${(r.size_label || '').replace(/"/g, '""')}"`,
      priceRupees,
      compareRupees,
      r.stock,
      r.sku || '',
    ].join(','));
  }

  return new Response(lines.join('\n'), {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="homedecor-pricing-stock.csv"',
    },
  });
};

export const POST: APIRoute = async ({ request, locals }) => {
  // Import CSV text and update prices, stock, and sizes
  try {
    const csvText = await request.text();
    const rows = csvText.split(/\r?\n/).filter(line => line.trim().length > 0);
    if (rows.length <= 1) {
      return new Response(JSON.stringify({ error: 'CSV file is empty or only has headers.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    let updatedCount = 0;

    // Skip header row
    for (let i = 1; i < rows.length; i++) {
      const line = rows[i];
      // Regex parsing for CSV lines with quotes
      const match = line.match(/(".*?"|[^",\s]+)(?=\s*,|\s*$)/g);
      if (!match || match.length < 2) continue;

      const cleanMatch = match.map(m => m.replace(/^"|"$/g, '').trim());
      const productId = cleanMatch[0];
      const sizeLabel = cleanMatch[2] || null;
      const priceStr = cleanMatch[3];
      const compareStr = cleanMatch[4];
      const stockStr = cleanMatch[5];

      const pricePaise = priceStr && !isNaN(Number(priceStr)) ? Math.round(Number(priceStr) * 100) : null;
      const comparePaise = compareStr && !isNaN(Number(compareStr)) ? Math.round(Number(compareStr) * 100) : null;
      const stock = stockStr && !isNaN(Number(stockStr)) ? Number(stockStr) : 0;

      await run(
        db,
        `UPDATE product_variants SET
          size_label = COALESCE(?, size_label),
          price_paise = ?,
          compare_at_paise = ?,
          stock = ?
         WHERE product_id = ? AND is_default = 1`,
        [sizeLabel, pricePaise, comparePaise, stock, productId]
      );
      updatedCount++;
    }

    return new Response(JSON.stringify({
      success: true,
      updated_count: updatedCount,
      message: `Successfully updated ${updatedCount} products from CSV.`,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Failed to process CSV import.' }), { status: 500 });
  }
};
