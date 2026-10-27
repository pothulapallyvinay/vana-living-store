// src/pages/api/admin/orders.ts
// Order status updates, tracking numbers, and Razorpay refunds
import type { APIRoute } from 'astro';
import { getDB, run, one, all } from '../../../lib/db';
import { refundRazorpayPayment } from '../../../lib/razorpay';

export const GET: APIRoute = async ({ url, locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify([]), { headers: { 'Content-Type': 'application/json' } });

  const db = getDB(env);
  const statusFilter = url.searchParams.get('status');

  let query = `SELECT * FROM orders`;
  const params: any[] = [];

  if (statusFilter && statusFilter !== 'all') {
    query += ` WHERE status = ?`;
    params.push(statusFilter);
  }

  query += ` ORDER BY id DESC LIMIT 100`;

  const orders = await all(db, query, params);
  return new Response(JSON.stringify(orders), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const { action, order_id, status, courier, tracking_number, refund_amount_paise } = body;

    if (!order_id) return new Response(JSON.stringify({ error: 'Order ID is required' }), { status: 400 });

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    if (action === 'update_status') {
      await run(
        db,
        `UPDATE orders SET
          status = COALESCE(?, status),
          courier = COALESCE(?, courier),
          tracking_number = COALESCE(?, tracking_number),
          updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
         WHERE id = ?`,
        [status || null, courier || null, tracking_number || null, order_id]
      );
      return new Response(JSON.stringify({ success: true, message: 'Order status updated.' }), { status: 200 });
    }

    if (action === 'refund') {
      const order = await one<{ razorpay_payment_id: string; total_paise: number }>(
        db,
        `SELECT razorpay_payment_id, total_paise FROM orders WHERE id = ?`,
        [order_id]
      );

      if (!order?.razorpay_payment_id) {
        return new Response(JSON.stringify({ error: 'Cannot refund: No Razorpay payment ID on record.' }), { status: 400 });
      }

      const keyId = env.RAZORPAY_KEY_ID;
      const keySecret = env.RAZORPAY_KEY_SECRET;

      if (!keyId || !keySecret) {
        return new Response(JSON.stringify({ error: 'Razorpay keys not configured.' }), { status: 500 });
      }

      const amountToRefund = refund_amount_paise ? Number(refund_amount_paise) : undefined;
      const refundResult = await refundRazorpayPayment(keyId, keySecret, order.razorpay_payment_id, amountToRefund);

      await run(
        db,
        `UPDATE orders SET payment_status = 'refunded', status = 'cancelled', updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') WHERE id = ?`,
        [order_id]
      );

      return new Response(JSON.stringify({ success: true, refund: refundResult }), { status: 200 });
    }

    return new Response(JSON.stringify({ error: 'Invalid action.' }), { status: 400 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Action failed' }), { status: 500 });
  }
};
