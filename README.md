# Handcrafted Home Décor & Lighting E-Commerce Platform

A fast, SEO-optimized, production-ready full-stack e-commerce web application engineered for handcrafted 3D multi-layered wooden wall art, designer lamps, and artisan clocks.

Built specifically for **Cloudflare Pages** (Astro SSR), **Cloudflare D1** (SQLite), **Cloudflare R2** (Media Storage), and **Razorpay** payments for the Indian market in **INR (₹)**.

---

## 🌟 Key Features

1. **Artisan Aesthetic Design System:**
   - Bespoke warm artisan palette: Walnut (`#4A2C1D`), Brass (`#B9803A`), Cream (`#FBF7F1`), and Sand (`#F3EBDF`).
   - Cormorant Garamond editorial serif headers & DM Sans modern typography.
   - Smooth micro-interactions, cursor image zoom, interactive gallery with video turntable playback, and slide-in cart drawer.

2. **Strict Financial Security (Never Trust the Browser):**
   - Prices, discounts, coupons, shipping rules, and totals are **always recalculated server-side** in Cloudflare D1.
   - Client sends only variant IDs and quantities.
   - All monetary values stored as **integer paise** (₹1 = 100 paise) to eliminate floating-point arithmetic errors.

3. **Complete Razorpay Indian Payment Pipeline:**
   - **Online Payments:** Unified UPI (Google Pay, PhonePe, Paytm), Credit/Debit Cards, NetBanking, and Wallets via Razorpay Orders API & Checkout.js.
   - **Cash on Delivery (COD):** Plain COD for orders under ₹3,000; COD-with-advance (30% online advance via Razorpay to cover raw timber cutting, 70% at doorstep) for orders exceeding the threshold.
   - **Signature Verification:** Constant-time Web Crypto HMAC-SHA256 signature verification.
   - **Authoritative Webhook (`/api/webhooks/razorpay`):** Verifies raw request body HMAC signatures with idempotent event tracking in `webhook_events`.
   - **Refunds:** Full and partial refunds executed directly from the admin panel via the Razorpay Refunds API.

4. **Curated Catalog (32 Products & 91 Visual Assets):**
   - All 32 unique products imported with exact names, multi-tier categories, space tags, variants, and grouped media.
   - Excludes duplicate `49(1).svg`.
   - Watermarked images (`43.jpg`, `44.jpg`, `45.jpg`) flagged with `is_watermarked = 1` and excluded from public view.
   - AI renders (`render-1.png`, `render-2.png`, `render-3.png`) flagged with `is_render = 1`.
   - P17 3D turntable videos (`video-1.mp4`, `video-2.mp4`) with posters and HTML5 playback.
   - Products without confirmed prices show **"Price on request"** with prefilled **WhatsApp enquiry** buttons.

5. **Comprehensive Admin Control Panel (`/admin`):**
   - Guarded by session middleware (`admin` / `super_admin` role check).
   - Dashboard with today's orders, monthly revenue, pending payments, and low-stock inventory alerts.
   - Products & media manager with inline price/stock edits and **Bulk CSV Import / Export**.
   - Orders manager with status progression (Confirmed -> Processing -> Shipped -> Delivered), courier & AWB tracking inputs, and online refunds.
   - Coupon management (percentage / fixed discount, min order rules, usage limits).
   - Category and store settings management.

6. **SEO & High Performance:**
   - Schema.org JSON-LD structured data: `Product`, `BreadcrumbList`, `FAQPage`, and `Organization`.
   - Dynamic `sitemap.xml` generated from D1.
   - Compliant `robots.txt` blocking admin and checkout paths.
   - Preloaded high-priority hero assets and lazy-loaded gallery images.

---

## 🏗️ Architecture & Directory Structure

```
store/
├── astro.config.mjs             # Astro SSR with @astrojs/cloudflare adapter
├── wrangler.toml                 # D1 database & R2 bucket bindings
├── .dev.vars.example             # Local environment secrets example
├── tsconfig.json                 # TypeScript strict configuration
├── package.json                  # Dependencies & scripts
├── migrations/
│   ├── 0001_init.sql             # Full D1 SQLite schema (16 tables, indexes)
│   └── 0002_seed_catalog.sql     # 32 products, categories, tags, 91 media assets
├── data/
│   └── products.csv              # Source catalog mapping
├── scripts/
│   ├── organize-media.js         # Media pipeline: groups & renames assets
│   ├── import-products.ts        # Seed verification script
│   ├── optimize-media.ts         # SVG raster vs true vector analyzer & size reporter
│   └── create-admin.ts           # Generates initial admin with PBKDF2-SHA256
├── public/
│   ├── favicon.svg               # Brand icon
│   ├── robots.txt                # Search crawler rules
│   ├── placeholder-decor.svg     # Fallback decor SVG
│   └── media/products/           # All 90 product images and videos (P01–P32)
└── src/
    ├── config/site.ts            # Brand name, contact, shipping & COD rules
    ├── middleware.ts             # Session auth, admin guard, CSRF origin check, CSP
    ├── layouts/
    │   ├── Base.astro            # Public layout (Header, Announcement, Cart Drawer, Footer)
    │   └── Admin.astro           # Admin layout with responsive collapsible sidebar
    ├── components/
    │   ├── AnnouncementBar.astro # Dismissible promo ribbon
    │   ├── Header.astro          # Search suggestions, cart badge always in DOM, mobile drawer
    │   ├── MegaMenu.astro        # Shop by Space, Category, Price & MATRA HAUS card
    │   ├── HeroSlider.astro      # 3-slide hero carousel with auto-pause
    │   ├── TrustStrip.astro      # Indian craft & delivery guarantees
    │   ├── ProductCard.astro     # Secondary hover image, badges, WhatsApp enquiry
    │   ├── Gallery.astro         # Zoom on hover, thumbnail strip, video player
    │   ├── PincodeChecker.astro  # 6-digit PIN validation & delivery estimate
    │   └── Footer.astro          # Categories, newsletter, policies, Razorpay badges
    ├── lib/
    │   ├── db.ts                 # Type-safe Cloudflare D1 query helpers
    │   ├── auth.ts               # PBKDF2 password hashing & SHA-256 session management
    │   ├── crypto.ts             # Web Crypto HMAC-SHA256, PBKDF2 & constant-time comparison
    │   ├── pricing.ts            # Authoritative server-side cart re-pricing engine
    │   ├── razorpay.ts           # Razorpay Orders API, refunds & order number generator
    │   ├── validate.ts           # Indian PIN code, phone, email & states list
    │   ├── format.ts             # INR rupee & paise formatting utilities
    │   └── seo.ts                # JSON-LD Product, Breadcrumbs & OpenGraph generators
    ├── styles/
    │   ├── global.css            # Complete artisan design tokens and components
    │   └── admin.css             # Control panel styling and data tables
    └── pages/
        ├── index.astro           # Homepage
        ├── collections/[slug].astro # Sticky filter sidebar, sort, 2/3/4 grid toggle
        ├── products/[slug].astro # Product detail page with gallery and accordions
        ├── cart.astro            # Full cart table, instant sync, free shipping progress
        ├── checkout.astro        # Checkout with Indian states, Razorpay & COD
        ├── order/[number].astro  # Tracking timeline, invoice print, access token check
        ├── account/              # Dashboard, orders, profile, addresses, password
        ├── login.astro           # Sign in
        ├── register.astro        # Register
        ├── logout.ts             # Session destruction endpoint
        ├── about.astro           # Artisan heritage & sustainability story
        ├── contact.astro         # Contact form & WhatsApp concierge
        ├── faq.astro             # FAQ accordion with FAQPage JSON-LD
        ├── bulk-orders.astro     # Corporate gifting quote calculator
        ├── policies/             # Shipping, returns, terms, privacy
        ├── sitemap.xml.ts        # Dynamic XML sitemap
        └── api/                  # Pricing, pincode, checkout, webhooks, auth, admin API
```

---

## 🚀 Local Development Setup

### 1. Prerequisites
- **Node.js** v18+ or v20+
- **npm** (included with Node.js)

### 2. Installation
Navigate into the `store` folder and install dependencies:
```bash
cd store
npm install
```

### 3. Environment Configuration
Copy `.dev.vars.example` to `.dev.vars`:
```bash
cp .dev.vars.example .dev.vars
```
Fill in your test credentials:
```ini
RAZORPAY_KEY_ID=rzp_test_YOUR_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_KEY_SECRET
RAZORPAY_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=SuperSecretPassword123
```

### 4. Initialize Local D1 Database
Apply schema migrations and catalog seed to your local SQLite database:
```bash
npm run db:migrate:local
npm run db:seed:local
```

### 5. Create Initial Admin Account
Run the admin creation script using your environment variables:
```bash
ADMIN_EMAIL=admin@yourdomain.com ADMIN_PASSWORD=SuperSecretPassword123 npm run create-admin
```

### 6. Start the Development Server
```bash
npm run dev
```
Open [http://localhost:4321](http://localhost:4321) in your browser.

---

## 💳 Razorpay Configuration & Webhook Setup

### 1. Test Mode vs Live Mode
- Develop with **Test Keys** (`rzp_test_...`) from your Razorpay Dashboard.
- When ready for production, generate **Live Keys** (`rzp_live_...`) after completing your business KYC.

### 2. Configuring Webhooks in Razorpay Dashboard
1. Go to **Razorpay Dashboard** &rarr; **Settings** &rarr; **Webhooks**.
2. Click **Add New Webhook**.
3. **Webhook URL:** `https://[YOUR_DOMAIN]/api/webhooks/razorpay`
4. **Secret:** Enter a strong random secret and save the same string in `RAZORPAY_WEBHOOK_SECRET` in your Cloudflare environment.
5. **Alert Email:** `support@[YOUR_DOMAIN]`
6. **Active Events:**
   - `order.paid`
   - `payment.captured`
   - `payment.failed`
7. Click **Create Webhook**.

### 3. Testing Razorpay Payments
- Use Razorpay's documented test cards:
  - **Success Card:** `4111 1111 1111 1111`, Expiry: any future date, CVV: `123`, OTP: any 6 digits.
  - **Test UPI ID:** `success@razorpay`

---

## ☁️ Deployment to Cloudflare Pages

### 1. Create Cloudflare D1 Database & R2 Bucket
Using wrangler CLI:
```bash
npx wrangler d1 create homedecor-db
npx wrangler r2 bucket create homedecor-media
```
Update the `database_id` inside `wrangler.toml` with the generated D1 UUID.

### 2. Apply Remote Migrations
```bash
npm run db:migrate:remote
npx wrangler d1 execute homedecor-db --remote --file=migrations/0002_seed_catalog.sql
```

### 3. Deploy via Cloudflare Dashboard or Git
1. Connect your GitHub repository to **Cloudflare Pages**.
2. Set **Framework Preset:** `Astro`
3. Set **Build command:** `npm run build`
4. Set **Build output directory:** `dist`
5. In **Settings &rarr; Functions &rarr; D1 Database Bindings:**
   - Variable name: `DB`
   - D1 Database: `homedecor-db`
6. In **Settings &rarr; Environment variables:**
   - `RAZORPAY_KEY_ID`: `rzp_live_...`
   - `RAZORPAY_KEY_SECRET`: `[SECRET]`
   - `RAZORPAY_WEBHOOK_SECRET`: `[SECRET]`
7. Connect your custom domain and map `media.[YOUR_DOMAIN]` to your R2 bucket.

---

## 📄 License & Attribution
Designed and handcrafted for [BRAND NAME] Home Décor Studio. All rights reserved.
