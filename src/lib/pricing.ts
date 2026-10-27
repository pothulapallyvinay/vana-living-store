// src/lib/pricing.ts
// Server-side pricing engine — NEVER trust the client for prices

import { all, one, type DB } from './db';
import { shipping } from '../config/site';

export interface CartLineInput {
  variant_id: number;
  qty: number;
}

export interface CartLine {
  variant_id: number;
  product_id: string;
  product_name: string;
  variant_label: string;
  image_path: string | null;
  unit_price_paise: number;
  qty: number;
  line_total_paise: number;
}

export interface PricingResult {
  lines: CartLine[];
  subtotal_paise: number;
  discount_paise: number;
  coupon_code: string | null;
  shipping_paise: number;
  total_paise: number;
  free_shipping: boolean;
  errors: string[];
}

export async function priceCart(
  db: DB,
  inputs: CartLineInput[],
  couponCode?: string
): Promise<PricingResult> {
  const errors: string[] = [];
  const lines: CartLine[] = [];
  let subtotal_paise = 0;

  for (const input of inputs) {
    if (input.qty < 1 || input.qty > 99) {
      errors.push(`Invalid quantity for variant ${input.variant_id}`);
      continue;
    }

    const variant = await one<{
      id: number;
      product_id: string;
      label: string;
      price_paise: number | null;
      stock: number;
      is_active: number;
      product_name: string;
      image_path: string | null;
    }>(
      db,
      `SELECT pv.id, pv.product_id, pv.label, pv.price_paise, pv.stock, pv.is_active,
              p.name as product_name,
              (SELECT pm.path FROM product_media pm 
               WHERE pm.product_id = pv.product_id AND pm.is_primary = 1 AND pm.is_watermarked = 0
               LIMIT 1) as image_path
       FROM product_variants pv
       JOIN products p ON p.id = pv.product_id
       WHERE pv.id = ? AND pv.is_active = 1 AND p.is_active = 1`,
      [input.variant_id]
    );

    if (!variant) {
      errors.push(`Product variant ${input.variant_id} not found or unavailable`);
      continue;
    }

    if (variant.price_paise == null) {
      errors.push(`${variant.product_name} is not available for online purchase (price on request)`);
      continue;
    }

    if (variant.stock < input.qty) {
      errors.push(`Only ${variant.stock} units of "${variant.product_name}" in stock`);
      continue;
    }

    let img = variant.image_path || `/media/products/${variant.product_id}/1.svg`;
    if (!img.startsWith('http://') && !img.startsWith('https://')) {
      if (!img.startsWith('/')) img = '/' + img;
      if (img.startsWith('/products/')) img = '/media' + img;
    }

    const line_total = variant.price_paise * input.qty;
    lines.push({
      variant_id: variant.id,
      product_id: variant.product_id,
      product_name: variant.product_name,
      variant_label: variant.label,
      image_path: img,
      image: img,
      unit_price_paise: variant.price_paise,
      price_paise: variant.price_paise,
      qty: input.qty,
      line_total_paise: line_total,
      line_subtotal_paise: line_total,
      is_available: true,
    } as any);
    subtotal_paise += line_total;
  }

  // Apply coupon
  let discount_paise = 0;
  let used_coupon: string | null = null;

  if (couponCode && lines.length > 0) {
    const now = new Date().toISOString();
    const coupon = await one<{
      code: string;
      type: 'percent' | 'fixed';
      value: number;
      min_order_paise: number;
      max_discount_paise: number | null;
      usage_limit: number | null;
      used_count: number;
      is_active: number;
    }>(
      db,
      `SELECT * FROM coupons
       WHERE code = ? AND is_active = 1
         AND (starts_at IS NULL OR starts_at <= ?)
         AND (expires_at IS NULL OR expires_at >= ?)`,
      [couponCode.toUpperCase(), now, now]
    );

    if (!coupon) {
      errors.push('Invalid or expired coupon code');
    } else if (subtotal_paise < coupon.min_order_paise) {
      errors.push(
        `Coupon requires minimum order of ₹${Math.floor(coupon.min_order_paise / 100)}`
      );
    } else if (coupon.usage_limit != null && coupon.used_count >= coupon.usage_limit) {
      errors.push('Coupon usage limit reached');
    } else {
      if (coupon.type === 'percent') {
        discount_paise = Math.floor((subtotal_paise * coupon.value) / 100);
      } else {
        discount_paise = coupon.value;
      }
      if (coupon.max_discount_paise != null) {
        discount_paise = Math.min(discount_paise, coupon.max_discount_paise);
      }
      discount_paise = Math.min(discount_paise, subtotal_paise);
      used_coupon = coupon.code;
    }
  }

  // Dynamic logistics and COD configuration
  let freeShippingThreshold = shipping.freeAbovePaise;
  let flatRatePaise = shipping.flatRatePaise;
  let codLimit = shipping.codLimitPaise;
  let codMaxLimit = shipping.codWithAdvanceLimitPaise;
  let advancePercent = shipping.advancePercent;
  let codEnabled = shipping.codEnabled;

  try {
    const settingRows = await all<{ key: string; value: string }>(db, 'SELECT key, value FROM settings');
    const settingsMap: Record<string, string> = {};
    for (const r of settingRows) settingsMap[r.key] = r.value;

    if (settingsMap.free_shipping_threshold) {
      freeShippingThreshold = parseInt(settingsMap.free_shipping_threshold, 10) * 100;
    } else if (settingsMap.free_shipping_threshold_paise) {
      freeShippingThreshold = parseInt(settingsMap.free_shipping_threshold_paise, 10);
    }

    if (settingsMap.flat_shipping_rate) {
      flatRatePaise = parseInt(settingsMap.flat_shipping_rate, 10) * 100;
    } else if (settingsMap.flat_shipping_paise) {
      flatRatePaise = parseInt(settingsMap.flat_shipping_paise, 10);
    }

    if (settingsMap.cod_limit && parseInt(settingsMap.cod_limit, 10) >= 1000) {
      codLimit = parseInt(settingsMap.cod_limit, 10) * 100;
    } else if (settingsMap.cod_limit_paise && parseInt(settingsMap.cod_limit_paise, 10) >= 100000) {
      codLimit = parseInt(settingsMap.cod_limit_paise, 10);
    }

    if (settingsMap.cod_advance_limit) {
      codMaxLimit = parseInt(settingsMap.cod_advance_limit, 10) * 100;
    } else if (settingsMap.cod_advance_limit_paise) {
      codMaxLimit = parseInt(settingsMap.cod_advance_limit_paise, 10);
    }

    if (settingsMap.advance_percent) {
      advancePercent = parseInt(settingsMap.advance_percent, 10);
    } else if (settingsMap.cod_advance_percent) {
      advancePercent = parseInt(settingsMap.cod_advance_percent, 10);
    }

    if (settingsMap.cod_enabled !== undefined) {
      codEnabled = settingsMap.cod_enabled === '1' || settingsMap.cod_enabled === 'true';
    }
  } catch (err) {
    // Fall back to config/site.ts defaults
  }

  const after_discount = subtotal_paise - discount_paise;
  const free_shipping = after_discount >= freeShippingThreshold;
  const shipping_paise = free_shipping || lines.length === 0 ? 0 : flatRatePaise;
  const total_paise = after_discount + shipping_paise;

  // COD Calculations
  const cod_available = codEnabled && total_paise <= codMaxLimit;
  const cod_advance_required = total_paise > codLimit && total_paise <= codMaxLimit;
  const cod_advance_paise = cod_advance_required ? Math.round((total_paise * advancePercent) / 100) : 0;
  const cod_balance_paise = cod_advance_required ? total_paise - cod_advance_paise : total_paise;
  const amount_for_free_shipping_paise = Math.max(0, freeShippingThreshold - after_discount);

  return {
    lines,
    subtotal_paise,
    discount_paise,
    coupon_code: used_coupon,
    shipping_paise,
    total_paise,
    free_shipping,
    free_shipping_threshold_paise: freeShippingThreshold,
    amount_for_free_shipping_paise,
    cod_available,
    cod_advance_required,
    cod_advance_paise,
    cod_balance_paise,
    cod_limit_paise: codLimit,
    cod_max_limit_paise: codMaxLimit,
    errors,
  } as any;
}

/** Decrement stock for all order items (call after payment confirmed) */
export async function decrementStock(
  db: DB,
  items: { variant_id: number; quantity: number }[]
): Promise<void> {
  for (const item of items) {
    await db
      .prepare('UPDATE product_variants SET stock = MAX(0, stock - ?) WHERE id = ?')
      .bind(item.quantity, item.variant_id)
      .run();
  }
}
