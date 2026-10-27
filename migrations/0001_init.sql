-- =============================================================================
-- Migration 0001: Initial Schema
-- Database: Cloudflare D1 (SQLite dialect)
-- All money stored as INTEGER PAISE (₹1 = 100 paise)
-- =============================================================================

-- Categories (hierarchical)
CREATE TABLE IF NOT EXISTS categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  description TEXT,
  image       TEXT,
  sort_order  INTEGER DEFAULT 0,
  is_active   INTEGER DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at  TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id               TEXT PRIMARY KEY,          -- e.g. P01
  slug             TEXT NOT NULL UNIQUE,
  name             TEXT NOT NULL,
  short_description TEXT,
  description      TEXT,
  brand_line       TEXT,                       -- e.g. MATRA HAUS
  badge            TEXT CHECK(badge IN ('NEW','HOT','SALE') OR badge IS NULL),
  is_featured      INTEGER DEFAULT 0,
  is_bestseller    INTEGER DEFAULT 0,
  is_active        INTEGER DEFAULT 1,
  tax_rate_bps     INTEGER DEFAULT 1800,       -- 18% GST in basis points
  created_at       TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
  updated_at       TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Product ↔ Category (many-to-many)
CREATE TABLE IF NOT EXISTS product_categories (
  product_id  TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  is_primary  INTEGER DEFAULT 0,
  PRIMARY KEY (product_id, category_id)
);

-- Product tags (spaces, brand, etc.)
CREATE TABLE IF NOT EXISTS product_tags (
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  tag        TEXT NOT NULL,
  PRIMARY KEY (product_id, tag)
);

-- Product variants (size / finish / LED options)
CREATE TABLE IF NOT EXISTS product_variants (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id      TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  label           TEXT NOT NULL,             -- e.g. "Small / Natural"
  size_label      TEXT,
  finish          TEXT,
  led_option      TEXT,
  sku             TEXT UNIQUE,
  price_paise     INTEGER,                   -- NULL = price on request
  compare_at_paise INTEGER,
  stock           INTEGER DEFAULT 0,
  is_default      INTEGER DEFAULT 0,
  is_active       INTEGER DEFAULT 1
);

-- Product media
CREATE TABLE IF NOT EXISTS product_media (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id     TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  path           TEXT NOT NULL,             -- R2 object key
  kind           TEXT NOT NULL DEFAULT 'image' CHECK(kind IN ('image','video')),
  alt            TEXT,
  sort_order     INTEGER DEFAULT 0,
  is_primary     INTEGER DEFAULT 0,
  is_watermarked INTEGER DEFAULT 0,
  is_render      INTEGER DEFAULT 0,
  poster_path    TEXT                        -- for videos
);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name    TEXT NOT NULL,
  last_name     TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  phone         TEXT,
  role          TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('member','admin','super_admin')),
  force_pw_change INTEGER DEFAULT 0,
  created_at    TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Sessions (only SHA-256 hash stored)
CREATE TABLE IF NOT EXISTS sessions (
  id         TEXT PRIMARY KEY,              -- SHA-256(token)
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Addresses
CREATE TABLE IF NOT EXISTS addresses (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  phone      TEXT NOT NULL,
  line1      TEXT NOT NULL,
  line2      TEXT,
  city       TEXT NOT NULL,
  state      TEXT NOT NULL,
  pincode    TEXT NOT NULL,
  is_default INTEGER DEFAULT 0
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number       TEXT NOT NULL UNIQUE,
  user_id            INTEGER REFERENCES users(id) ON DELETE SET NULL,
  email              TEXT NOT NULL,
  phone              TEXT NOT NULL,
  shipping_address   TEXT NOT NULL,           -- JSON snapshot
  subtotal_paise     INTEGER NOT NULL,
  discount_paise     INTEGER DEFAULT 0,
  shipping_paise     INTEGER DEFAULT 0,
  total_paise        INTEGER NOT NULL,
  coupon_code        TEXT,
  payment_method     TEXT NOT NULL DEFAULT 'online' CHECK(payment_method IN ('online','cod_partial','cod')),
  payment_status     TEXT NOT NULL DEFAULT 'unpaid' CHECK(payment_status IN ('unpaid','partial','paid','failed','refunded')),
  status             TEXT NOT NULL DEFAULT 'pending_payment' CHECK(status IN ('pending_payment','confirmed','processing','shipped','delivered','cancelled')),
  razorpay_order_id  TEXT,
  razorpay_payment_id TEXT,
  advance_paid_paise INTEGER DEFAULT 0,
  balance_due_paise  INTEGER DEFAULT 0,
  courier            TEXT,
  tracking_number    TEXT,
  customer_notes     TEXT,
  gstin              TEXT,
  access_token       TEXT NOT NULL,           -- unguessable guest access token
  created_at         TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
  updated_at         TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Order line items (snapshot at purchase time)
CREATE TABLE IF NOT EXISTS order_items (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id         INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id       TEXT NOT NULL,
  variant_id       INTEGER NOT NULL,
  product_name     TEXT NOT NULL,
  variant_label    TEXT NOT NULL,
  image_path       TEXT,
  unit_price_paise INTEGER NOT NULL,
  quantity         INTEGER NOT NULL DEFAULT 1
);

-- Coupons
CREATE TABLE IF NOT EXISTS coupons (
  code              TEXT PRIMARY KEY,
  type              TEXT NOT NULL CHECK(type IN ('percent','fixed')),
  value             INTEGER NOT NULL,         -- percent or paise
  min_order_paise   INTEGER DEFAULT 0,
  max_discount_paise INTEGER,
  starts_at         TEXT,
  expires_at        TEXT,
  usage_limit       INTEGER,
  used_count        INTEGER DEFAULT 0,
  is_active         INTEGER DEFAULT 1
);

-- Webhook idempotency
CREATE TABLE IF NOT EXISTS webhook_events (
  event_id    TEXT PRIMARY KEY,
  type        TEXT NOT NULL,
  received_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Site settings (key-value)
CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Newsletter subscribers
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  email      TEXT PRIMARY KEY,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Contact messages
CREATE TABLE IF NOT EXISTS contact_messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  email      TEXT NOT NULL,
  phone      TEXT,
  subject    TEXT,
  message    TEXT NOT NULL,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- Wishlist (logged-in users)
CREATE TABLE IF NOT EXISTS wishlist_items (
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
  PRIMARY KEY (user_id, product_id)
);

-- Password reset tokens
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  used       INTEGER DEFAULT 0
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(is_featured);
CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_media_product ON product_media(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_rzp ON orders(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- Default settings
INSERT OR IGNORE INTO settings (key, value) VALUES
  ('announcement_text', 'Free shipping on orders above ₹999 | COD available'),
  ('announcement_active', '1'),
  ('free_shipping_threshold_paise', '99900'),
  ('flat_shipping_paise', '8900'),
  ('cod_enabled', '1'),
  ('cod_limit_paise', '300000'),
  ('cod_advance_percent', '30'),
  ('store_name', '[BRAND NAME]'),
  ('store_whatsapp', '[WHATSAPP NUMBER]'),
  ('meta_pixel_id', ''),
  ('ga4_id', ''),
  ('hero_slides', '[{"headline":"Crafted With Soul","subline":"Handcrafted 3D wooden wall art, designer lamps & artisan clocks","cta_text":"Shop Now","cta_url":"/collections/all","image":""},{"headline":"MATRA HAUS Collection","subline":"Architectural lighting that transforms any space","cta_text":"Explore","cta_url":"/collections/matra-haus","image":""},{"headline":"For Every Space","subline":"Wall art for your living room, bedroom, office & pooja room","cta_text":"Shop by Space","cta_url":"/collections/all","image":""}]');
