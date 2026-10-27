// src/pages/api/admin/products.ts
// Product and variant management API (CRUD)
import type { APIRoute } from 'astro';
import { getDB, run, one, all } from '../../../lib/db';

function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export const GET: APIRoute = async ({ url, locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify([]), { headers: { 'Content-Type': 'application/json' } });

  const db = getDB(env);
  const products = await all(db, `
    SELECT p.*,
      v.id as variant_id, v.sku, v.price_paise, v.compare_at_paise, v.stock, v.size_label,
      m.path as primary_image
    FROM products p
    LEFT JOIN product_variants v ON v.product_id = p.id AND v.is_default = 1
    LEFT JOIN product_media m ON m.product_id = p.id AND m.is_primary = 1
    ORDER BY p.id ASC
  `);

  return new Response(JSON.stringify(products), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const {
      action,
      id,
      name,
      slug,
      short_description,
      description,
      brand_line,
      badge,
      is_active,
      price_paise,
      compare_at_paise,
      stock,
      size_label,
      primary_image,
      category_id,
    } = body;

    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service is unavailable.' }), { status: 503 });
    }
    const db = getDB(env);

    // ==========================================
    // 1. CREATE NEW PRODUCT
    // ==========================================
    if (action === 'create' || (!id && name)) {
      if (!name || !name.trim()) {
        return new Response(JSON.stringify({ error: 'Product name is required.' }), { status: 400 });
      }

      // Determine Product ID (e.g. P33)
      let newId = (id || '').trim();
      if (!newId) {
        const rows = await all<{ id: string }>(db, `SELECT id FROM products WHERE id LIKE 'P%'`);
        let maxNum = 0;
        for (const r of rows) {
          const num = parseInt(r.id.replace(/\D/g, ''), 10);
          if (!isNaN(num) && num > maxNum) maxNum = num;
        }
        newId = `P${String(maxNum + 1).padStart(2, '0')}`;
      }

      // Check for ID conflict
      const existingId = await one(db, `SELECT id FROM products WHERE id = ?`, [newId]);
      if (existingId) {
        return new Response(JSON.stringify({ error: `Product ID "${newId}" already exists.` }), { status: 409 });
      }

      // Generate slug
      let finalSlug = slug ? slugify(slug) : slugify(name);
      if (!finalSlug) finalSlug = `product-${newId.toLowerCase()}`;

      const existingSlug = await one(db, `SELECT id FROM products WHERE slug = ?`, [finalSlug]);
      if (existingSlug) {
        finalSlug = `${finalSlug}-${Date.now().toString(36)}`;
      }

      const pPaise = price_paise !== undefined && price_paise !== null && price_paise !== '' ? Number(price_paise) : null;
      const cPaise = compare_at_paise !== undefined && compare_at_paise !== null && compare_at_paise !== '' ? Number(compare_at_paise) : null;
      const initStock = stock !== undefined && stock !== null && stock !== '' ? Number(stock) : 10;
      const validBadge = badge && ['HOT', 'NEW', 'SALE'].includes(badge) ? badge : null;

      // Insert product
      await run(
        db,
        `INSERT INTO products (id, slug, name, short_description, description, brand_line, badge, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          newId,
          finalSlug,
          name.trim(),
          short_description?.trim() || null,
          description?.trim() || null,
          brand_line?.trim() || null,
          validBadge,
          is_active !== undefined ? (is_active ? 1 : 0) : 1,
        ]
      );

      // Insert default variant
      const sku = `VAR-${newId}-STD`;
      await run(
        db,
        `INSERT INTO product_variants (product_id, label, size_label, sku, price_paise, compare_at_paise, stock, is_default, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)`,
        [newId, 'Standard', size_label?.trim() || 'Standard', sku, pPaise, cPaise, initStock]
      );

      // Insert primary media if provided
      if (primary_image && primary_image.trim()) {
        const cleanPath = primary_image.trim().startsWith('/') ? primary_image.trim() : `/${primary_image.trim()}`;
        await run(
          db,
          `INSERT INTO product_media (product_id, path, kind, is_primary, sort_order)
           VALUES (?, ?, 'image', 1, 1)`,
          [newId, cleanPath]
        );
      }

      // Link category if provided
      if (category_id) {
        await run(
          db,
          `INSERT OR IGNORE INTO product_categories (product_id, category_id, is_primary)
           VALUES (?, ?, 1)`,
          [newId, Number(category_id)]
        );
      }

      return new Response(JSON.stringify({
        success: true,
        message: `Product ${newId} created successfully!`,
        id: newId,
        slug: finalSlug,
      }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // ==========================================
    // 2. UPDATE EXISTING PRODUCT
    // ==========================================
    if (!id) return new Response(JSON.stringify({ error: 'Product ID required' }), { status: 400 });

    const validBadge = badge && ['HOT', 'NEW', 'SALE'].includes(badge) ? badge : null;

    // Update product info
    await run(
      db,
      `UPDATE products SET
        name = COALESCE(?, name),
        short_description = COALESCE(?, short_description),
        description = COALESCE(?, description),
        brand_line = COALESCE(?, brand_line),
        badge = ?,
        is_active = COALESCE(?, is_active),
        updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`,
      [
        name?.trim() || null,
        short_description?.trim() || null,
        description?.trim() || null,
        brand_line?.trim() || null,
        validBadge,
        is_active !== undefined ? (is_active ? 1 : 0) : null,
        id
      ]
    );

    // Update or insert default variant pricing and stock
    if (price_paise !== undefined || stock !== undefined || size_label !== undefined || compare_at_paise !== undefined) {
      const existingVar = await one(db, `SELECT id FROM product_variants WHERE product_id = ? LIMIT 1`, [id]);
      const finalPrice = price_paise === null || price_paise === '' || price_paise === undefined ? null : Number(price_paise);
      const finalCompare = compare_at_paise === null || compare_at_paise === '' || compare_at_paise === undefined ? null : Number(compare_at_paise);
      const finalStock = stock !== undefined && stock !== null && stock !== '' ? Number(stock) : 0;

      if (!existingVar) {
        await run(
          db,
          `INSERT INTO product_variants (product_id, sku, label, price_paise, compare_at_paise, stock, is_default)
           VALUES (?, ?, 'Standard Edition', ?, ?, ?, 1)`,
          [id, `VAR-${id}`, finalPrice, finalCompare, finalStock]
        );
      } else {
        await run(
          db,
          `UPDATE product_variants SET
            price_paise = ?,
            compare_at_paise = ?,
            stock = ?,
            size_label = COALESCE(?, size_label)
           WHERE product_id = ? AND (is_default = 1 OR id = (SELECT id FROM product_variants WHERE product_id = ? LIMIT 1))`,
          [
            finalPrice,
            finalCompare,
            finalStock,
            size_label?.trim() || null,
            id,
            id
          ]
        );
      }
    }

    // Update primary image if provided
    if (primary_image !== undefined) {
      const cleanPath = primary_image?.trim() ? (primary_image.trim().startsWith('/') ? primary_image.trim() : `/${primary_image.trim()}`) : null;
      if (cleanPath) {
        const existingMedia = await one(db, `SELECT id FROM product_media WHERE product_id = ? AND is_primary = 1`, [id]);
        if (existingMedia) {
          await run(db, `UPDATE product_media SET path = ? WHERE product_id = ? AND is_primary = 1`, [cleanPath, id]);
        } else {
          await run(db, `INSERT INTO product_media (product_id, path, kind, is_primary, sort_order) VALUES (?, ?, 'image', 1, 1)`, [id, cleanPath]);
        }
      }
    }

    return new Response(JSON.stringify({ success: true, message: 'Product updated successfully.' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Product update failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

export const DELETE: APIRoute = async ({ request, url, locals }) => {
  try {
    let id = url.searchParams.get('id');
    if (!id) {
      try {
        const body = await request.json();
        id = body?.id;
      } catch {}
    }
    if (!id) return new Response(JSON.stringify({ error: 'Product ID required' }), { status: 400 });

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    await run(db, `DELETE FROM product_media WHERE product_id = ?`, [id]);
    await run(db, `DELETE FROM product_variants WHERE product_id = ?`, [id]);
    await run(db, `DELETE FROM product_categories WHERE product_id = ?`, [id]);
    await run(db, `DELETE FROM product_tags WHERE product_id = ?`, [id]);
    await run(db, `DELETE FROM products WHERE id = ?`, [id]);

    return new Response(JSON.stringify({ success: true, message: `Product ${id} deleted successfully.` }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Product deletion failed.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
