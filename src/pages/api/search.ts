// src/pages/api/search.ts
// Live product search suggestions
import type { APIRoute } from 'astro';
import { getDB, all } from '../../lib/db';
import { formatPrice } from '../../lib/format';

export const GET: APIRoute = async ({ url, locals }) => {
  const query = url.searchParams.get('q')?.trim().toLowerCase() || '';

  if (query.length < 2) {
    return new Response(JSON.stringify([]), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const env = (locals as any).runtime?.env;
  if (!env?.DB) {
    // Return sample matches if DB is not bound
    return new Response(JSON.stringify([
      { name: '3D Layered Wooden Circular Mandala Wall Art', slug: '3d-layered-wooden-circular-mandala-wall-art-with-backlit-led-glow', price: 'Price on request', image: '/media/products/P01/1.svg' },
      { name: 'MATRA HAUS Modern Curved Slat Lamp', slug: 'matra-haus-modern-wooden-curved-slat-pendant-lamp', price: 'Price on request', image: '/media/products/P17/39.svg' }
    ]), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const db = getDB(env);
  const rows = await all<{
    id: string;
    slug: string;
    name: string;
    price_paise: number | null;
    stock: number | null;
    image_path: string | null;
  }>(
    db,
    `SELECT p.id, p.slug, p.name, v.price_paise, v.stock, m.path as image_path
     FROM products p
     LEFT JOIN product_variants v ON v.product_id = p.id AND v.is_default = 1
     LEFT JOIN product_media m ON m.product_id = p.id AND m.is_primary = 1
     WHERE p.is_active = 1 AND (LOWER(p.name) LIKE ? OR LOWER(p.short_description) LIKE ?)
     LIMIT 5`,
    [`%${query}%`, `%${query}%`]
  );

  const results = rows.map(r => {
    let p = r.image_path || `/media/products/${r.id}/1.svg`;
    if (!p.startsWith('http://') && !p.startsWith('https://')) {
      if (!p.startsWith('/')) p = '/' + p;
      if (p.startsWith('/products/')) p = '/media' + p;
    }
    const currentStock = typeof r.stock === 'number' ? r.stock : 0;
    return {
      id: r.id,
      slug: r.slug,
      name: r.name,
      price: r.price_paise ? formatPrice(r.price_paise) : 'Price on request',
      image: p,
      stock: currentStock,
      in_stock: currentStock > 0,
    };
  });

  return new Response(JSON.stringify(results), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
};
