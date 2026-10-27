// src/pages/api/admin/coupons.ts
import type { APIRoute } from 'astro';
import { getDB, run, all } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify([]), { headers: { 'Content-Type': 'application/json' } });
  const db = getDB(env);
  const coupons = await all(db, `SELECT * FROM coupons ORDER BY code ASC`);
  return new Response(JSON.stringify(coupons), { status: 200, headers: { 'Content-Type': 'application/json' } });
};

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const { code, type, value, min_order_rupees, max_discount_rupees, usage_limit, is_active } = body;

    if (!code || !type || value === undefined) {
      return new Response(JSON.stringify({ error: 'Code, type, and value are required.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    const minOrderPaise = min_order_rupees ? Math.round(Number(min_order_rupees) * 100) : 0;
    const maxDiscountPaise = max_discount_rupees ? Math.round(Number(max_discount_rupees) * 100) : null;

    await run(
      db,
      `INSERT INTO coupons (code, type, value, min_order_paise, max_discount_paise, usage_limit, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(code) DO UPDATE SET
        type = excluded.type,
        value = excluded.value,
        min_order_paise = excluded.min_order_paise,
        max_discount_paise = excluded.max_discount_paise,
        usage_limit = excluded.usage_limit,
        is_active = excluded.is_active`,
      [code.trim().toUpperCase(), type, Number(value), minOrderPaise, maxDiscountPaise, usage_limit || null, is_active ? 1 : 0]
    );

    return new Response(JSON.stringify({ success: true, message: 'Coupon saved successfully.' }), { status: 200 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Failed to save coupon.' }), { status: 500 });
  }
};
