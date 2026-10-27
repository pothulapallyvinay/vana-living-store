// src/pages/api/checkout/create-order.ts
// Server-side order creation and Razorpay order generation
import type { APIRoute } from 'astro';
import { getDB, run, one } from '../../../lib/db';
import { priceCart, decrementStock } from '../../../lib/pricing';
import { generateOrderNumber, createRazorpayOrder } from '../../../lib/razorpay';
import { randomHex } from '../../../lib/crypto';
import { isValidEmail, isValidIndianPhone, isValidIndianPincode } from '../../../lib/validate';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const {
      first_name,
      last_name,
      email,
      phone,
      address_line1,
      address_line2,
      city,
      state,
      pincode,
      payment_method, // 'online' | 'cod' | 'cod_partial'
      lines,
      coupon_code,
      customer_notes,
      gstin,
    } = body;

    // 1. Validate customer & shipping details
    if (!first_name || !last_name) {
      return new Response(JSON.stringify({ error: 'First name and last name are required.' }), { status: 400 });
    }
    if (!email || !isValidEmail(email)) {
      return new Response(JSON.stringify({ error: 'A valid email address is required.' }), { status: 400 });
    }
    if (!phone || !isValidIndianPhone(phone)) {
      return new Response(JSON.stringify({ error: 'A valid 10-digit Indian phone number is required.' }), { status: 400 });
    }
    if (!address_line1 || !city || !state) {
      return new Response(JSON.stringify({ error: 'Complete street address, city and state are required.' }), { status: 400 });
    }
    if (!pincode || !isValidIndianPincode(pincode)) {
      return new Response(JSON.stringify({ error: 'A valid 6-digit Indian PIN code is required.' }), { status: 400 });
    }
    if (!Array.isArray(lines) || lines.length === 0) {
      return new Response(JSON.stringify({ error: 'Your cart is empty.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service is currently initializing. Please try again shortly.' }), { status: 503 });
    }

    const db = getDB(env);

    // 2. Authoritative Server Re-Pricing (Never trust browser amounts)
    const pricing = await priceCart(db, lines, coupon_code);
    if (pricing.lines.length === 0 || pricing.total_paise <= 0) {
      return new Response(JSON.stringify({ error: 'Unable to calculate price for selected items.' }), { status: 400 });
    }

    // Check availability
    for (const line of pricing.lines) {
      if (!line.is_available) {
        return new Response(JSON.stringify({ error: `Item "${line.product_name}" is currently unavailable.` }), { status: 400 });
      }
    }

    // 3. Determine Payment Amounts
    let payablePaise = pricing.total_paise;
    let advancePaidPaise = 0;
    let balanceDuePaise = 0;
    let chosenMethod: 'online' | 'cod' | 'cod_partial' = payment_method === 'cod' ? 'cod' : 'online';

    if (payment_method === 'cod') {
      if (!pricing.cod_available) {
        return new Response(JSON.stringify({
          error: `Cash on Delivery is unavailable for this order value (orders must be under ₹${Math.floor((pricing.cod_max_limit_paise || 10000000) / 100).toLocaleString('en-IN')}). Please choose online payment.`
        }), { status: 400 });
      } else if (pricing.cod_advance_required) {
        chosenMethod = 'cod_partial';
        payablePaise = pricing.cod_advance_paise;
        balanceDuePaise = pricing.cod_balance_paise;
      } else {
        chosenMethod = 'cod';
        payablePaise = 0;
        balanceDuePaise = pricing.total_paise;
      }
    }

    // 4. Generate Unique Order Number & Unguessable Guest Access Token
    const orderNumber = String(generateOrderNumber('VL'));
    const accessToken = randomHex(16);
    const shippingAddressJson = JSON.stringify({
      first_name,
      last_name,
      line1: address_line1,
      line2: address_line2 || '',
      city,
      state,
      pincode,
      country: 'India',
    });

    const user = (locals as any).user;
    let userId = user ? user.id : null;
    if (!userId && email) {
      try {
        const matchedUser = await one<{ id: number }>(db, 'SELECT id FROM users WHERE LOWER(email) = ?', [email.toLowerCase().trim()]);
        if (matchedUser) userId = matchedUser.id;
      } catch {}
    }

    // 5. Create Razorpay Order if online payment / advance COD is required
    let rzpOrderId: string | null = null;
    let rzpKeyId: string | null = null;

    let isDemoMode = false;
    if (chosenMethod === 'online' || chosenMethod === 'cod_partial') {
      const keyId = env.RAZORPAY_KEY_ID;
      const keySecret = env.RAZORPAY_KEY_SECRET;

      if (!keyId || !keySecret || keyId.includes('placeholder')) {
        isDemoMode = true;
        rzpKeyId = 'rzp_test_demo';
        rzpOrderId = 'order_demo_' + randomHex(8);
      } else {
        try {
          rzpKeyId = keyId;
          const rzpOrder = await createRazorpayOrder(
            keyId,
            keySecret,
            payablePaise,
            orderNumber,
            {
              order_number: orderNumber,
              customer_email: email,
              customer_phone: phone,
              is_advance: chosenMethod === 'cod_partial' ? 'yes' : 'no',
            }
          );
          rzpOrderId = rzpOrder.id;
        } catch (e) {
          console.warn('Real Razorpay order creation failed, falling back to demo mode:', e);
          isDemoMode = true;
          rzpKeyId = 'rzp_test_demo';
          rzpOrderId = 'order_demo_' + randomHex(8);
        }
      }
    }

    // 6. Insert Order into D1
    const initialStatus = chosenMethod === 'cod' ? 'confirmed' : 'pending_payment';
    const initialPaymentStatus = 'unpaid';

    const insertResult = await run(
      db,
      `INSERT INTO orders (
        order_number, user_id, email, phone, shipping_address,
        subtotal_paise, discount_paise, shipping_paise, total_paise,
        coupon_code, payment_method, payment_status, status,
        razorpay_order_id, advance_paid_paise, balance_due_paise,
        customer_notes, gstin, access_token
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        orderNumber,
        userId,
        email.toLowerCase().trim(),
        phone.trim(),
        shippingAddressJson,
        pricing.subtotal_paise,
        pricing.discount_paise,
        pricing.shipping_paise,
        pricing.total_paise,
        pricing.coupon_code || null,
        chosenMethod,
        initialPaymentStatus,
        initialStatus,
        rzpOrderId,
        advancePaidPaise,
        balanceDuePaise,
        customer_notes || null,
        gstin || null,
        accessToken,
      ]
    );

    const orderId = insertResult.meta.last_row_id;

    // 7. Insert Order Snapshot Items
    for (const item of pricing.lines) {
      await run(
        db,
        `INSERT INTO order_items (
          order_id, product_id, variant_id, product_name,
          variant_label, image_path, unit_price_paise, quantity
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          orderId,
          item.product_id,
          item.variant_id,
          item.product_name,
          item.variant_label,
          item.image,
          item.price_paise,
          item.qty,
        ]
      );
    }

    // 8. Return response
    if (chosenMethod === 'cod') {
      try {
        await decrementStock(
          db,
          pricing.lines.map((i: any) => ({ variant_id: i.variant_id, quantity: i.qty }))
        );
      } catch (stockErr) {
        console.warn('Could not decrement stock on COD order:', stockErr);
      }

      return new Response(JSON.stringify({
        success: true,
        order_number: orderNumber,
        access_token: accessToken,
        redirect: `/order/${orderNumber}?token=${accessToken}`,
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      success: true,
      order_number: orderNumber,
      access_token: accessToken,
      razorpay_order_id: rzpOrderId,
      amount_paise: payablePaise,
      key_id: rzpKeyId,
      is_demo: isDemoMode,
      customer: {
        name: `${first_name} ${last_name}`,
        email,
        phone,
      },
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    console.error('CREATE-ORDER ERROR TRACE:', error);
    return new Response(JSON.stringify({ error: error.message || 'Failed to initialize order.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
