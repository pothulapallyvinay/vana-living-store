// src/pages/api/webhooks/razorpay.ts
// Authoritative Razorpay Webhook listener with HMAC verification and idempotent event storage
import type { APIRoute } from 'astro';
import { getDB, run, one } from '../../../lib/db';
import { hmacSha256Hex, timingSafeEqual } from '../../../lib/crypto';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const signature = request.headers.get('x-razorpay-signature');
    if (!signature) {
      return new Response(JSON.stringify({ error: 'Missing webhook signature.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    const webhookSecret = env?.RAZORPAY_WEBHOOK_SECRET;

    if (!webhookSecret) {
      return new Response(JSON.stringify({ error: 'Webhook secret is not configured on server.' }), { status: 500 });
    }

    // Read RAW body text for accurate HMAC-SHA256 signature verification
    const rawBody = await request.text();
    const expectedSignature = await hmacSha256Hex(webhookSecret, rawBody);

    if (!timingSafeEqual(expectedSignature, signature)) {
      return new Response(JSON.stringify({ error: 'Invalid webhook signature.' }), { status: 400 });
    }

    const event = JSON.parse(rawBody);
    const eventId = event?.id || event?.event_id;
    const eventType = event?.event;

    if (!eventId || !eventType) {
      return new Response(JSON.stringify({ error: 'Malformed webhook payload.' }), { status: 400 });
    }

    const db = getDB(env);

    // Idempotency check: see if this event was already processed
    const existing = await one<{ id: string }>(
      db,
      `SELECT id FROM webhook_events WHERE id = ?`,
      [eventId]
    );

    if (existing) {
      // Event already handled, return 200 OK immediately
      return new Response(JSON.stringify({ status: 'already_processed' }), { status: 200 });
    }

    // Store event ID immediately for idempotency
    await run(
      db,
      `INSERT INTO webhook_events (id, event_type, payload) VALUES (?, ?, ?)`,
      [eventId, eventType, rawBody]
    );

    // Process event types
    const paymentEntity = event?.payload?.payment?.entity;
    const orderEntity = event?.payload?.order?.entity;
    const rzpOrderId = paymentEntity?.order_id || orderEntity?.id;

    if (eventType === 'payment.captured' || eventType === 'order.paid') {
      if (rzpOrderId) {
        const order = await one<{ id: number; payment_method: string; advance_paid_paise: number }>(
          db,
          `SELECT id, payment_method, advance_paid_paise FROM orders WHERE razorpay_order_id = ?`,
          [rzpOrderId]
        );

        if (order) {
          const isPartial = order.payment_method === 'cod_partial';
          const newStatus = isPartial ? 'partial' : 'paid';

          await run(
            db,
            `UPDATE orders SET
              payment_status = ?,
              status = CASE WHEN status = 'pending_payment' THEN 'confirmed' ELSE status END,
              razorpay_payment_id = COALESCE(razorpay_payment_id, ?),
              updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
             WHERE id = ?`,
            [newStatus, paymentEntity?.id || null, order.id]
          );
        }
      }
    } else if (eventType === 'payment.failed') {
      if (rzpOrderId) {
        await run(
          db,
          `UPDATE orders SET
            payment_status = 'failed',
            updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
           WHERE razorpay_order_id = ? AND payment_status != 'paid'`,
          [rzpOrderId]
        );
      }
    }

    return new Response(JSON.stringify({ status: 'success' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Webhook processing failure.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
