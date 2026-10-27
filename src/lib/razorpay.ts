// src/lib/razorpay.ts
// Razorpay API integration (server-side only)

export interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
  receipt: string;
  status: string;
}

/** Create a Razorpay order via the Orders API */
export async function createRazorpayOrder(
  keyId: string,
  keySecret: string,
  amountPaise: number,
  receipt: string,
  notes: Record<string, string> = {}
): Promise<RazorpayOrder> {
  const credentials = btoa(`${keyId}:${keySecret}`);
  const response = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: 'INR',
      receipt,
      notes,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    // Log server-side, never expose to client
    console.error('[Razorpay] Order creation failed:', error);
    throw new Error('Payment service error. Please try again.');
  }

  return response.json() as Promise<RazorpayOrder>;
}

/** Issue a full or partial refund via Razorpay Refunds API */
export async function createRazorpayRefund(
  keyId: string,
  keySecret: string,
  paymentId: string,
  amountPaise: number,
  notes?: Record<string, string>
): Promise<{ id: string; amount: number; status: string }> {
  if (!keyId || !keySecret || keyId.includes('placeholder') || paymentId.startsWith('pay_demo_')) {
    return {
      id: 'rfnd_demo_' + Date.now(),
      amount: amountPaise,
      status: 'processed',
    };
  }

  const credentials = btoa(`${keyId}:${keySecret}`);
  const response = await fetch(
    `https://api.razorpay.com/v1/payments/${paymentId}/refund`,
    {
      method: 'POST',
      headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ amount: amountPaise, notes }),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    console.error('[Razorpay] Refund failed:', error);
    throw new Error('Refund failed. Please try again or contact support.');
  }

  return response.json();
}

export const refundRazorpayPayment = createRazorpayRefund;

/** Generate a Razorpay order number: PREFIX-YYMMDD-XXXXX */
export function generateOrderNumber(prefix: string = 'VL'): string {
  const now = new Date();
  const yy = String(now.getFullYear()).slice(-2);
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const rand = Array.from(
    { length: 5 },
    () => chars[Math.floor(Math.random() * chars.length)]
  ).join('');
  return `${prefix}-${yy}${mm}${dd}-${rand}`;
}
