// src/pages/api/wishlist.ts
// Member wishlist management (requires session auth)
import type { APIRoute } from 'astro';
import { getDB, run, one, all } from '../../lib/db';
import { getSessionUser } from '../../lib/auth';

export const GET: APIRoute = async ({ request, cookies, locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify([]), { headers: { 'Content-Type': 'application/json' } });

  const db = getDB(env);
  const user = (await getSessionUser(db, cookies)) || (await getSessionUser(db, request));

  if (!user) {
    return new Response(JSON.stringify({ error: 'Authentication required', requires_login: true, items: [] }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const items = await all(db, `
    SELECT w.product_id, w.created_at,
      p.name, p.slug, p.badge, p.brand_line, p.is_active,
      v.id as default_variant_id, v.sku, v.size_label, v.price_paise, v.compare_at_paise, v.stock,
      m.path as primary_image
    FROM wishlist_items w
    JOIN products p ON p.id = w.product_id
    LEFT JOIN product_variants v ON v.product_id = p.id AND v.is_default = 1
    LEFT JOIN product_media m ON m.product_id = p.id AND m.is_primary = 1
    WHERE w.user_id = ?
    ORDER BY w.created_at DESC
  `, [user.id]);

  const productIds = items.map(i => i.product_id);

  return new Response(JSON.stringify({ success: true, items, product_ids: productIds }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request, cookies, locals }) => {
  try {
    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service unavailable' }), { status: 503 });
    }

    const db = getDB(env);
    const user = (await getSessionUser(db, cookies)) || (await getSessionUser(db, request));

    if (!user) {
      return new Response(JSON.stringify({
        error: 'Please sign in to add items to your wishlist.',
        requires_login: true,
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const body = await request.json();
    const productId = body?.product_id;

    if (!productId) {
      return new Response(JSON.stringify({ error: 'Product ID is required.' }), { status: 400 });
    }

    // Check if product exists
    const product = await one(db, `SELECT id, name FROM products WHERE id = ?`, [productId]);
    if (!product) {
      return new Response(JSON.stringify({ error: 'Product not found.' }), { status: 404 });
    }

    // Insert or ignore into wishlist_items
    await run(
      db,
      `INSERT OR IGNORE INTO wishlist_items (user_id, product_id, created_at)
       VALUES (?, ?, strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))`,
      [user.id, productId]
    );

    return new Response(JSON.stringify({
      success: true,
      message: `Added to wishlist!`,
      product_id: productId,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Failed to update wishlist.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};

export const DELETE: APIRoute = async ({ request, url, cookies, locals }) => {
  try {
    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service unavailable' }), { status: 503 });
    }

    const db = getDB(env);
    const user = (await getSessionUser(db, cookies)) || (await getSessionUser(db, request));

    if (!user) {
      return new Response(JSON.stringify({ error: 'Authentication required.', requires_login: true }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let productId = url.searchParams.get('product_id');
    if (!productId) {
      try {
        const body = await request.json();
        productId = body?.product_id;
      } catch {}
    }

    if (!productId) {
      return new Response(JSON.stringify({ error: 'Product ID required' }), { status: 400 });
    }

    await run(db, `DELETE FROM wishlist_items WHERE user_id = ? AND product_id = ?`, [user.id, productId]);

    return new Response(JSON.stringify({
      success: true,
      message: 'Removed from wishlist.',
      product_id: productId,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Failed to remove from wishlist.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
