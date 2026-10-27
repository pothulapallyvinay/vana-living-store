// src/lib/cart.ts
// Client & Server Cart types and helper utilities

export interface CartItem {
  variant_id: number;
  qty: number;
}

export interface CartPricedLine {
  variant_id: number;
  product_id: string;
  product_name: string;
  variant_label: string;
  image: string;
  sku: string;
  price_paise: number;
  compare_at_paise: number | null;
  qty: number;
  line_subtotal_paise: number;
  stock: number;
  is_available: boolean;
}

export interface CartPricedSummary {
  lines: CartPricedLine[];
  item_count: number;
  subtotal_paise: number;
  discount_paise: number;
  shipping_paise: number;
  total_paise: number;
  free_shipping_threshold_paise: number;
  amount_for_free_shipping_paise: number;
  coupon_code: string | null;
  coupon_valid: boolean;
  coupon_error?: string;
  cod_available: boolean;
  cod_advance_required: boolean;
  cod_advance_paise: number;
  cod_balance_paise: number;
}
