-- =============================================================================
-- E-COMMERCE DATABASE SETUP SCRIPT
-- Woodcraft & Designer Lighting E-Commerce Platform
-- Database: ecommerce_store
-- Generated for: 32 Unique Products & 91 Visual Assets
-- Dialect Compatibility: MySQL 5.7+ / 8.0+, MariaDB, PostgreSQL 12+, SQLite 3+
-- Encoding: UTF-8 Unicode
-- =============================================================================

-- =============================================================================
-- SECTION 1: CLEANUP & DROPS (Reverse Dependency Order)
-- =============================================================================

DROP VIEW IF EXISTS vw_product_catalog;
DROP VIEW IF EXISTS vw_product_details;
DROP VIEW IF EXISTS vw_featured_products;
DROP VIEW IF EXISTS vw_category_summary;

DROP TABLE IF EXISTS inventory_transactions;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customer_addresses;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS product_variants;
DROP TABLE IF EXISTS product_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS product_images;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS brands;
DROP TABLE IF EXISTS categories;

-- =============================================================================
-- SECTION 2: TABLE DEFINITIONS (DDL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: categories (Hierarchical product categories)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT PRIMARY KEY,
    parent_id       INT NULL,
    name            VARCHAR(100) NOT NULL,
    slug            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    display_order   INT DEFAULT 0,
    is_active       INT DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- -----------------------------------------------------------------------------
-- Table: brands (Design studios, creators, and manufacturers)
-- -----------------------------------------------------------------------------
CREATE TABLE brands (
    brand_id        INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    slug            VARCHAR(100) NOT NULL UNIQUE,
    tagline         VARCHAR(255),
    description     TEXT,
    country         VARCHAR(50),
    website         VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Table: products (Core catalog table with comprehensive e-commerce attributes)
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    product_id          INT PRIMARY KEY,
    sku                 VARCHAR(50) NOT NULL UNIQUE,
    legacy_code         VARCHAR(20) NOT NULL UNIQUE,
    name                VARCHAR(255) NOT NULL,
    slug                VARCHAR(255) NOT NULL UNIQUE,
    category_id         INT NOT NULL,
    brand_id            INT NOT NULL,
    short_description   VARCHAR(500),
    description         TEXT NOT NULL,
    base_price          DECIMAL(10, 2) NOT NULL,
    sale_price          DECIMAL(10, 2) NULL,
    cost_price          DECIMAL(10, 2) NOT NULL,
    stock_quantity      INT NOT NULL DEFAULT 0,
    low_stock_threshold INT NOT NULL DEFAULT 5,
    material            VARCHAR(150),
    dimensions          VARCHAR(120),
    weight_kg           DECIMAL(6, 2),
    power_source        VARCHAR(120) NULL,
    mounting_type       VARCHAR(120) NULL,
    assembly_required   INT DEFAULT 0,
    warranty_months     INT DEFAULT 12,
    is_featured         INT DEFAULT 0,
    is_active           INT DEFAULT 1,
    rating_average      DECIMAL(3, 2) DEFAULT 0.00,
    rating_count        INT DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
);

-- -----------------------------------------------------------------------------
-- Table: product_images (Multi-angle & media assets for all 91 files)
-- -----------------------------------------------------------------------------
CREATE TABLE product_images (
    image_id        INT PRIMARY KEY,
    product_id      INT NOT NULL,
    filename        VARCHAR(255) NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    media_type      VARCHAR(30) NOT NULL,
    alt_text        VARCHAR(500) NOT NULL,
    is_primary      INT DEFAULT 0,
    sort_order      INT DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Table: tags (Search, style, and attribute tags)
-- -----------------------------------------------------------------------------
CREATE TABLE tags (
    tag_id          INT PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,
    slug            VARCHAR(50) NOT NULL UNIQUE
);

-- -----------------------------------------------------------------------------
-- Table: product_tags (Many-to-many relationship linking products and tags)
-- -----------------------------------------------------------------------------
CREATE TABLE product_tags (
    product_id      INT NOT NULL,
    tag_id          INT NOT NULL,
    PRIMARY KEY (product_id, tag_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Table: product_variants (Product size, finish, and lighting configurations)
-- -----------------------------------------------------------------------------
CREATE TABLE product_variants (
    variant_id      INT PRIMARY KEY,
    product_id      INT NOT NULL,
    sku             VARCHAR(60) NOT NULL UNIQUE,
    variant_name    VARCHAR(120) NOT NULL,
    option1_name    VARCHAR(50),
    option1_value   VARCHAR(50),
    option2_name    VARCHAR(50),
    option2_value   VARCHAR(50),
    price_modifier  DECIMAL(10, 2) DEFAULT 0.00,
    stock_quantity  INT DEFAULT 10,
    is_active       INT DEFAULT 1,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Table: customers (Customer and administrator accounts)
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(30),
    password_hash   VARCHAR(255) NOT NULL,
    role            VARCHAR(20) DEFAULT 'customer',
    is_active       INT DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Table: customer_addresses (Billing and shipping delivery addresses)
-- -----------------------------------------------------------------------------
CREATE TABLE customer_addresses (
    address_id      INT PRIMARY KEY,
    customer_id     INT NOT NULL,
    address_type    VARCHAR(20) DEFAULT 'shipping',
    full_name       VARCHAR(100) NOT NULL,
    street_address  VARCHAR(255) NOT NULL,
    apartment       VARCHAR(100),
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL,
    postal_code     VARCHAR(20) NOT NULL,
    country         VARCHAR(50) NOT NULL DEFAULT 'United States',
    is_default      INT DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- Table: orders (Checkout orders and transaction summaries)
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id            INT PRIMARY KEY,
    order_number        VARCHAR(50) NOT NULL UNIQUE,
    customer_id         INT NOT NULL,
    status              VARCHAR(30) DEFAULT 'delivered',
    subtotal            DECIMAL(10, 2) NOT NULL,
    discount_amount     DECIMAL(10, 2) DEFAULT 0.00,
    shipping_fee        DECIMAL(10, 2) DEFAULT 0.00,
    tax_amount          DECIMAL(10, 2) DEFAULT 0.00,
    total_amount        DECIMAL(10, 2) NOT NULL,
    payment_method      VARCHAR(50) NOT NULL,
    payment_status      VARCHAR(30) DEFAULT 'paid',
    shipping_address_id INT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- -----------------------------------------------------------------------------
-- Table: order_items (Line items within each order)
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INT PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    product_name    VARCHAR(255) NOT NULL,
    unit_price      DECIMAL(10, 2) NOT NULL,
    quantity        INT NOT NULL DEFAULT 1,
    total_price     DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- -----------------------------------------------------------------------------
-- Table: reviews (Verified customer ratings and testimonials)
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id           INT PRIMARY KEY,
    product_id          INT NOT NULL,
    customer_id         INT NULL,
    author_name         VARCHAR(100) NOT NULL,
    rating              INT NOT NULL,
    title               VARCHAR(200) NOT NULL,
    content             TEXT NOT NULL,
    is_verified_purchase INT DEFAULT 1,
    helpful_votes       INT DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
);

-- -----------------------------------------------------------------------------
-- Table: inventory_transactions (Audit trail for stock adjustments)
-- -----------------------------------------------------------------------------
CREATE TABLE inventory_transactions (
    transaction_id      INT PRIMARY KEY,
    product_id          INT NOT NULL,
    transaction_type    VARCHAR(30) NOT NULL,
    quantity_change     INT NOT NULL,
    reference_id        VARCHAR(50),
    notes               VARCHAR(255),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- =============================================================================
-- SECTION 3: DATA INSERTS (DML)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Data: categories
-- -----------------------------------------------------------------------------
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (1, NULL, 'Wall Art & Decor', 'wall-art-decor', 'Artisan multi-layered 3D wooden wall sculptures, mandalas, shadow boxes, and framed reliefs.', 1, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (2, NULL, 'Designer Lighting', 'designer-lighting', 'Architectural wooden slat chandeliers, biomimetic pinecone pendants, and ambient LED fixtures.', 2, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (3, NULL, 'Artisan Clocks & Timepieces', 'artisan-clocks-timepieces', 'Laser-crafted 3D layered wall and desk clocks powered by whisper-silent quartz movements.', 3, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (101, 1, 'Mandalas & Sacred Geometry', 'mandalas-sacred-geometry', 'Intricate multi-tier concentric radial mandala sculptures and geometric wall headboards.', 1, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (102, 1, 'Abstract & Figurative Silhouette', 'abstract-figurative-silhouette', 'Cubist faces, flowing feminine silhouettes, and evocative modern figurative wall plaques.', 2, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (103, 1, 'Wildlife & Nature Sculptures', 'wildlife-nature-sculptures', 'Peacocks, tigers, koi shadow boxes, and layered natural animal portraiture.', 3, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (104, 1, 'Botanical & Tree of Life', 'botanical-tree-of-life', 'Sacred Bodhi trees, circular Tree of Life reliefs, and organic botanical branches.', 4, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (105, 1, 'Spiritual & Cultural Heritage', 'spiritual-cultural-heritage', 'Sacred Om mandalas, Lord Ganesha sculptures, and cultural heirloom woodcraft.', 5, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (106, 1, 'Topographic Maps & Ocean Depth', 'topographic-maps-ocean-depth', 'Laser-cut stepped bathymetric ocean depth maps and geographic relief artworks.', 6, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (201, 2, 'Architectural Slat Pendant Lamps', 'architectural-slat-pendant-lamps', 'Curved wood slat and translucent acrylic rib chandeliers engineered by MATRA HAUS.', 1, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (202, 2, 'Scandinavian Pinecone Lamps', 'scandinavian-pinecone-lamps', 'Biomimetic layered birch scale pendant shades and standing floor lamps.', 2, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (203, 2, 'Lantern & Table Accent Lamps', 'lantern-table-accent-lamps', 'Warm glowing curved slat lanterns and organic accent table luminaires.', 3, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (204, 2, 'Ambient LED Night Lights', 'ambient-led-night-lights', 'Edge-lit optical acrylic lamps on solid natural beech bases with touch dimming.', 4, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (301, 3, '3D Layered Wall Clocks', '3d-layered-wall-clocks', 'Sculptural asymmetric walnut, mandala, and topographic contour wall timepieces.', 1, 1);
INSERT INTO categories (category_id, parent_id, name, slug, description, display_order, is_active) VALUES (302, 3, 'Minimalist Desk Clocks', 'minimalist-desk-clocks', 'Compact circular multi-tier wooden desk clocks for modern workspaces and study tables.', 2, 1);

-- -----------------------------------------------------------------------------
-- Data: brands
-- -----------------------------------------------------------------------------
INSERT INTO brands (brand_id, name, slug, tagline, description, country, website) VALUES (1, 'MATRA HAUS Design Studio', 'matra-haus', 'Architectural Illumination & Sculptural Woodcraft', 'An avant-garde industrial lighting and interior design studio celebrated for steam-bent slat chandeliers and parametric illuminated forms.', 'Germany / India', 'https://matrahaus.design');
INSERT INTO brands (brand_id, name, slug, tagline, description, country, website) VALUES (2, 'Nordic Birch Craft', 'nordic-birch-craft', 'Organic Scandinavian Biomimetic Lighting', 'Handcrafted Nordic luminaires inspired by the geometry of pinecones, artichokes, and Baltic birch forests, providing warm, glare-free hygge lighting.', 'Sweden', 'https://nordicbirchcraft.com');
INSERT INTO brands (brand_id, name, slug, tagline, description, country, website) VALUES (3, 'AuraWood Artisans', 'aurawood-artisans', 'Precision Laser Artistry & Sacred Geometry', 'Pioneers of multi-tiered 3D laser-cut woodcraft, creating dimensional mandalas, shadow boxes, spiritual symbols, and backlit architectural art.', 'United States', 'https://aurawoodartisans.com');
INSERT INTO brands (brand_id, name, slug, tagline, description, country, website) VALUES (4, 'Chronos Wood Studio', 'chronos-wood-studio', 'Art That Keeps You In Time', 'Master clockmakers merging natural timber, topographic contours, and silent quartz sweep movements into timeless sculptural wall and desk pieces.', 'Canada', 'https://chronoswood.com');

-- -----------------------------------------------------------------------------
-- Data: products (All 32 Unique Catalog Items)
-- -----------------------------------------------------------------------------
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    1, 'SKU-WD-P01', 'P01', '3D Layered Wooden Circular Mandala Wall Art with Backlit LED Glow', '3d-layered-wooden-circular-mandala-wall-art-with-backlit-led-glow-p01',
    101, 3, 'Captivating 8-layer circular birch mandala wall sculpture featuring ambient backlit warm LED illumination and an amber spiral focal point.', 'Elevate your living space with this breathtaking 3D Layered Wooden Circular Mandala Wall Art. Meticulously laser-crafted from eight individual layers of sustainably sourced Baltic birch, this statement piece radiates intricate geometric symmetry. Hidden behind the rear stepped relief is an energy-efficient warm white LED strip (3000K) that casts a mesmerizing atmospheric halo across your walls. The center features a radiant amber optical acrylic spiral that catches the glow, turning any room into a tranquil, sacred sanctuary. Includes an inline dimmer switch and 2-meter braided power cable.',
    189.99, 159.99, 62.00,
    24, 5, '8-Layer Baltic Birch Plywood, Amber Optical Acrylic Center, 12V LED Strip', '60 cm x 60 cm x 4.0 cm (23.6" x 23.6" x 1.6")', 2.65,
    '12V DC Plug-in Adapter with In-Line Dimmer Switch (Included)', 'Heavy-Duty Pre-Installed Sawtooth Hanger with Wall Anchors', 0, 24,
    1, 1, 4.92, 38
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    2, 'SKU-WD-P02', 'P02', 'Framed 3D Multi-Layered Wooden Abstract Three Faces Wall Art', 'framed-3d-multi-layered-wooden-abstract-three-faces-wall-art-p02',
    102, 3, 'Cubist-inspired wooden relief sculpture displaying three interlocking abstract facial profiles within a solid oak gallery frame.', 'Celebrate modernist aesthetics with this Framed 3D Multi-Layered Wooden Abstract Three Faces Wall Art. Inspired by mid-century cubism and Scandinavian minimalism, each facial profile is cut with sub-millimeter laser precision from varied natural wood tones, creating an alluring depth of shadow and perspective. Housed inside a handcrafted solid natural oak frame, this artwork makes a sophisticated conversational centerpiece above consoles, credenzas, or dining room mantels.',
    149.99, 129.99, 48.00,
    18, 5, 'Multi-Layered Birch Plywood, Solid Natural Oak Outer Shadow Frame', '45 cm x 60 cm x 3.5 cm (17.7" x 23.6" x 1.4")', 2.20,
    'None (Passive Wall Sculpture)', 'Dual Keyhole Mounting Brackets for Horizontal or Vertical Display', 0, 12,
    1, 1, 4.85, 27
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    3, 'SKU-WD-P03', 'P03', '3D Multi-Layered Wooden Woman Profile Silhouette Wall Art Plaque', '3d-multi-layered-wooden-woman-profile-silhouette-wall-art-plaque-p03',
    102, 3, 'Graceful feminine side-profile silhouette with dynamic, swirling layered wooden hair locks mounted on a dark plaque.', 'This 3D Multi-Layered Wooden Woman Profile Silhouette Wall Art Plaque captures elegance and fluid motion. Five concentric tiers of natural walnut and blonde birch contour into dramatic swirling locks of hair framing an evocative silhouette. Set against a contrasting charcoal matte backplate, the relief plays with ambient light to reveal subtle shadows from different viewing angles. Perfect for beauty lounges, dressing rooms, or minimalist master bedrooms.',
    119.99, NULL, 38.00,
    30, 5, 'Walnut & Birch Veneer Relief, Matte Charcoal Stained Backing Board', '40 cm x 55 cm x 2.5 cm (15.7" x 21.6" x 1.0")', 1.75,
    'None', 'Pre-Drilled Recessed Keyhole Slot (Flush Wall Fit)', 0, 12,
    0, 1, 4.78, 19
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    4, 'SKU-WD-P04', 'P04', 'Geometric Cutout Wooden Artichoke Pendant Lamp Shade', 'geometric-cutout-wooden-artichoke-pendant-lamp-shade-p04',
    202, 2, 'Organic artichoke pendant lamp shade featuring heart and chevron laser-cut scale perforations that diffuse warm ambient light.', 'Introduce warmth and architectural drama into your dining room or kitchen island with the Geometric Cutout Wooden Artichoke Pendant Lamp Shade. Inspired by nature''s botanical pinecone and artichoke geometry, each overlapping birch scale is perforated with delicate heart and chevron cutouts. When illuminated with an Edison or LED filament bulb, the fixture creates intricate shadow play while bathing your space in soft, glare-free light. Comes complete with an adjustable textile suspension cord and ceiling rose.',
    129.99, 109.99, 42.00,
    22, 5, 'Natural Baltic Birch Scales, Matte White Acrylic Core, Powder-Coated Metal Fitting', '40 cm x 40 cm x 45 cm (15.7" x 15.7" x 17.7")', 1.45,
    'Hardwired Ceiling Fixture (110V - 240V AC)', 'Ceiling Mounted with 1.5m Adjustable Braided White Fabric Cord & Canopy Kit', 1, 24,
    1, 1, 4.88, 34
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    5, 'SKU-WD-P05', 'P05', 'Curved Slat Wooden Lantern Table Lamp Trio', 'curved-slat-wooden-lantern-table-lamp-trio-p05',
    203, 3, 'Set of 3 curved wooden slat lantern table lamps offering atmospheric vertical shadow lines and warm floor glow.', 'Transform any corner into a cozy lounge with the Curved Slat Wooden Lantern Table Lamp Trio. Sold as a coordinated 3-piece tiered set (Small, Medium, and Large), each lantern features gracefully bent vertical wood ribs encompassing a frosted opal diffuser cylinder. Place them together on an entryway credenza or disperse them across side tables and floor nooks to cast linear amber shadows and generate unmatched hygge ambiance.',
    199.99, 169.99, 68.00,
    15, 5, 'Steam-Bent Plywood Slat Ribs, Internal Opal Acrylic Diffuser Tube, Walnut Base', 'Trio Set: Small (25cm H x 15cm W), Medium (35cm H x 20cm W), Large (45cm H x 24cm W)', 3.80,
    '110V-240V AC Standard Plug with Cord Switch (E14 / E26 Sockets)', 'Freestanding Tabletop / Floor Accent Lantern', 0, 24,
    1, 1, 4.95, 41
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    6, 'SKU-WD-P06', 'P06', 'Framed 3D Multi-Layered Wooden Filigree Floral Mandala Wall Art', 'framed-3d-multi-layered-wooden-filigree-floral-mandala-wall-art-p06',
    101, 3, 'Intricate 8-layer filigree floral mandala wall art presented inside a clean contemporary white hardwood shadow frame.', 'The Framed 3D Multi-Layered Wooden Filigree Floral Mandala Wall Art is an exceptional showcase of micro-laser woodworking. Eight delicate tiers of radial floral and leaf filigree are stacked sequentially, creating a deep 3D optical illusion that draws the eye inward. Housed inside a satin white gallery frame, it introduces a soothing, mindful energy to entryways, yoga studios, or meditation spaces.',
    139.99, NULL, 45.00,
    20, 5, '8-Layer Micro Laser-Cut Birch Wood, Gallery White Hardwood Frame', '50 cm x 50 cm x 3.5 cm (19.7" x 19.7" x 1.4")', 2.10,
    'None', 'Pre-Installed D-Ring Wall Hooks (Hardware Included)', 0, 12,
    0, 1, 4.81, 16
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    7, 'SKU-WD-P07', 'P07', 'Framed 3D Multi-Layered Wooden Peacock Wall Art', 'framed-3d-multi-layered-wooden-peacock-wall-art-p07',
    103, 3, 'Vibrant 9-layer framed peacock wall sculpture with multi-tone jewel-colored plumage against a terracotta orange backdrop.', 'Grace your walls with the majesty of nature through this Framed 3D Multi-Layered Wooden Peacock Wall Art. Crafted from nine laser-sculpted wood sheets and individually hand-detailed in rich emerald, royal blue, turquoise, and gold accents, the regal peacock is mounted against a warm terracotta background. Enclosed within a square natural timber frame, this piece provides striking textural contrast above contemporary living room sofas.',
    179.99, 149.99, 58.00,
    16, 5, '9-Layer Hand-Painted Birch Wood, Terracotta Orange Backplate, Natural Wood Outer Frame', '60 cm x 60 cm x 3.5 cm (23.6" x 23.6" x 1.4")', 2.80,
    'None', 'Heavy-Duty Dual Sawtooth Wall Hangers', 0, 12,
    1, 1, 4.90, 29
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    8, 'SKU-WD-P08', 'P08', 'Framed 3D Multi-Layered Wooden Tiger Eyes Wall Art Plaque', 'framed-3d-multi-layered-wooden-tiger-eyes-wall-art-plaque-p08',
    103, 3, 'Intense panoramic relief artwork depicting the fierce, piercing gaze of tiger eyes rendered across stepped wooden layers.', 'Command attention in any room with the Framed 3D Multi-Layered Wooden Tiger Eyes Wall Art Plaque. Designed in an expansive widescreen format, this wall sculpture captures the fierce intensity and predatory grace of a tiger''s gaze. High-contrast smoked dark wood and golden birch layers create lifelike fur contouring and luminous amber eye depth, framed seamlessly in a minimalist matte black profile.',
    159.99, NULL, 52.00,
    14, 5, 'Smoked Charcoal Ash, Golden Birch Veneer, Matte Black Floater Frame', '75 cm x 30 cm x 3.0 cm (29.5" x 11.8" x 1.2")', 2.30,
    'None', 'Horizontal Keyhole Wall Brackets', 0, 12,
    0, 1, 4.86, 22
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    9, 'SKU-WD-P09', 'P09', '3D Multi-Layered Wooden Semi-Circular Peacock Tail Fan Wall Art', '3d-multi-layered-wooden-semi-circular-peacock-tail-fan-wall-art-p09',
    103, 3, 'Semi-circular wall plaque displaying a fanned peacock tail plumage in iridescent sapphire, emerald, and gold eyelets.', 'This 3D Multi-Layered Wooden Semi-Circular Peacock Tail Fan Wall Art brings opulent bohemian glamour to bed headboards and feature walls. Spanning 90 cm horizontally, the semicircular arrangement features over 15 distinct layered feather quills radiating from a gilded center body. Precision cut-out eyelets in jewel-toned sapphire and emerald reveal golden undertones, producing an eye-catching focal point.',
    169.99, 139.99, 55.00,
    19, 5, 'Tiered Birch Plywood, Metallic Gold Foil Highlights, Cyan & Emerald Stains', '90 cm x 45 cm x 3.0 cm (35.4" x 17.7" x 1.2")', 2.50,
    'None', 'Three-Point Balanced Wall Anchor System', 0, 12,
    0, 1, 4.89, 31
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    10, 'SKU-WD-P10', 'P10', 'Semi-Circular 3D Multi-Layered Wooden Mandala Wall Art Headboard', 'semi-circular-3d-multi-layered-wooden-mandala-wall-art-headboard-p10',
    101, 3, 'Grand 120cm semi-circular 180° layered wooden mandala headboard with a flat base, ideal for master beds or console alcoves.', 'Make an unforgettable design statement in your bedroom with the Semi-Circular 3D Multi-Layered Wooden Mandala Wall Art Headboard. Engineered specifically with a 180-degree flat horizontal baseline, this 1.2-meter wide sculpture aligns flush above queen or king headboards, fireplace mantels, or sideboard credenzas. Seven dense layers of laser-cut birch in alternating walnut and honey-oak tones emanate tranquility and architectural prestige. Includes a robust French cleat system for effortless, secure installation.',
    219.99, 189.99, 75.00,
    12, 5, 'Architectural Grade 7-Layer Baltic Birch, Walnut & Teak Dual Stain Finish', '120 cm x 60 cm x 3.5 cm (47.2" x 23.6" x 1.4")', 4.10,
    'None', 'Full-Length Heavy-Duty French Cleat Mounting System (Included)', 0, 24,
    1, 1, 4.96, 45
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    11, 'SKU-WD-P11', 'P11', 'Full Circular 3D Multi-Layered Wooden Mandala Wall Art', 'full-circular-3d-multi-layered-wooden-mandala-wall-art-p11',
    101, 3, 'Substantial 90cm full circular 3D wooden mandala medallion composed of 8 concentric geometric tiers.', 'The Full Circular 3D Multi-Layered Wooden Mandala Wall Art is the ultimate luxury wall medallion. Stretching an impressive 90 centimeters in diameter, this masterwork combines eight concentric layers of laser-perforated birch, treated in rich teak and natural stains. Each tier casts complex interlocking shadows that shift dynamically as the sun moves across your room. Designed as a commanding anchor piece above sofas, hotel lobbies, and executive suites.',
    239.99, 209.99, 82.00,
    15, 5, '8-Layer High-Density Birch Plywood, Dark Teak & Natural Wood Satin Clear-Coat', '90 cm x 90 cm x 4.0 cm (35.4" x 35.4" x 1.6")', 4.50,
    'None', 'Pre-Installed 4-Point Heavy-Duty Wall Cleats', 0, 24,
    1, 1, 4.94, 36
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    12, 'SKU-WD-P12', 'P12', '3D Multi-Layered Wooden Tree of Life Circular Wall Art', '3d-multi-layered-wooden-tree-of-life-circular-wall-art-p12',
    104, 3, 'Symbolic circular Tree of Life relief artwork featuring a distinctive hand-stained teal trunk and layered foliage canopy.', 'Celebrate connection, growth, and grounding with the 3D Multi-Layered Wooden Tree of Life Circular Wall Art. A symbol of resilience and cosmic harmony, this sculpture highlights a sculpted teal-tinted trunk branching into multi-tier foliage in sage, bronze, and natural birch. The circular framework is accented with sacred geometric patterns that enhance its organic beauty. Looks breathtaking against warm terracotta or slate-blue accent walls.',
    159.99, 134.99, 54.00,
    25, 5, '7-Layer Birch Wood, Hand-Stained Teal Trunk, Bronze & Sage Leaves', '60 cm x 60 cm x 3.0 cm (23.6" x 23.6" x 1.2")', 2.40,
    'None', 'Center Heavy-Duty Sawtooth Hanger with Rubber Wall Bumpers', 0, 12,
    1, 1, 4.91, 52
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    13, 'SKU-WD-P13', 'P13', '3D Multi-Layered Wooden Lotus Flower Mandala Circular Wall Art', '3d-multi-layered-wooden-lotus-flower-mandala-circular-wall-art-p13',
    101, 3, 'Multi-depth lotus flower mandala in royal blue and burgundy petal tiers within a round wooden border.', 'The 3D Multi-Layered Wooden Lotus Flower Mandala Circular Wall Art embodies peace, renewal, and purity. Six tiers of laser-carved birch wood are dyed in harmonious royal blue and rich burgundy stains, framed by a smooth natural blonde birch outer circle. The blossoming lotus motif adds serenity to yoga rooms, architectural niches, or modern office reception lounges.',
    149.99, NULL, 50.00,
    21, 5, '6-Layer Birch Wood, Royal Blue & Burgundy Stains, Natural Outer Ring', '55 cm x 55 cm x 3.0 cm (21.7" x 21.7" x 1.2")', 2.15,
    'None', 'Pre-Installed Sawtooth Wall Hanger', 0, 12,
    0, 1, 4.87, 28
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    14, 'SKU-WD-P14', 'P14', 'Scandinavian Wooden Pinecone Pendant Lamp Shade - Natural Birch Finish', 'scandinavian-wooden-pinecone-pendant-lamp-shade-natural-birch-finish-p14',
    202, 2, 'Iconic Scandinavian pinecone pendant lamp shade crafted from natural blonde birch wood scales for warm, glare-free light.', 'Bring authentic Nordic design into your living room with the Scandinavian Wooden Pinecone Pendant Lamp Shade in Natural Birch Finish. Based on classic mid-century biomimetic principles, this fixture features dozens of cascading birch veneer scales that shield the light source from direct view while dispersing warm, gentle illumination downwards and through the wooden slats. Pairs gorgeously with dining tables, high ceilings, or cozy reading corners.',
    139.99, 119.99, 46.00,
    28, 5, 'Natural Unfinished Nordic Birch Plywood Scales, Brushed Brass Ceiling Canopy', '42 cm x 42 cm x 48 cm (16.5" x 16.5" x 18.9")', 1.60,
    'Hardwired Ceiling Fixture (110V - 240V AC, E26/E27 Bulb Socket)', 'Ceiling Mounted with 1.8m Adjustable Clear Braided Cable & Mounting Hardware', 1, 24,
    1, 1, 4.89, 37
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    15, 'SKU-WD-P15', 'P15', 'Scandinavian Wooden Pinecone Standing Floor Lamp', 'scandinavian-wooden-pinecone-standing-floor-lamp-p15',
    202, 2, 'Architectural standing floor lamp featuring a wooden pinecone shade on a solid ash pole with foot-switch operation.', 'The Scandinavian Wooden Pinecone Standing Floor Lamp is the ultimate sculptural floor light for modern interiors. Standing at 155 cm tall, it matches the celebrated pinecone layered wooden shade with a sleek solid ash hardwood pole and a heavy anti-tip circular base. Operated conveniently via an in-line foot-tap switch, this lamp casts an enchanting organic silhouette alongside armchairs, sofas, or master bedroom headboards.',
    249.99, 219.99, 85.00,
    10, 5, 'Natural Birch Pinecone Shade, Solid Ash Wood Pole, Weighted Cast-Iron Core Base', '45 cm x 45 cm x 155 cm (17.7" x 17.7" x 61.0")', 5.40,
    '110V - 240V AC Cord with Foot-Step Switch (E26 / E27 Socket)', 'Freestanding Floor Lamp with Weighted Anti-Tip Base', 1, 24,
    1, 1, 4.93, 21
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    16, 'SKU-WD-P16', 'P16', 'Scandinavian Wooden Pinecone Pendant Lamp Shade - Charcoal Grey Finish', 'scandinavian-wooden-pinecone-pendant-lamp-shade-charcoal-grey-finish-p16',
    202, 2, 'Striking charcoal grey stained pinecone pendant light fixture designed for high-contrast modern and industrial interiors.', 'A moody, contemporary take on the timeless pinecone silhouette, this Scandinavian Wooden Pinecone Pendant Lamp Shade is hand-finished in deep Charcoal Grey. The dark stain enhances the natural grain of each wooden scale while offering dramatic contrast against light walls and vibrant furniture. Fitted with a matte black ceiling rose and braided cord, it adds undeniable modern edge to kitchen islands and moody dining rooms.',
    149.99, NULL, 49.00,
    20, 5, 'Charcoal Grey Stained Birch Veneer Scales, Matte Black Canopy & Cable', '42 cm x 42 cm x 48 cm (16.5" x 16.5" x 18.9")', 1.65,
    'Hardwired Ceiling Fixture (110V - 240V AC, E26/E27 Socket)', 'Ceiling Mounted with 1.8m Matte Black Fabric Cable & Metal Rose', 1, 24,
    0, 1, 4.82, 18
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    17, 'SKU-WD-P17', 'P17', 'MATRA HAUS Modern Wooden Curved Slat Pendant Lamp Fixture', 'matra-haus-modern-wooden-curved-slat-pendant-lamp-fixture-p17',
    201, 1, 'Flagship MATRA HAUS designer pendant fixture with aerodynamic curved wooden slats that cast exquisite linear light patterns.', 'The crown jewel of the MATRA HAUS Design Studio collection, this Modern Wooden Curved Slat Pendant Lamp Fixture exemplifies sculptural lighting design. Expertly fashioned from steam-bent Baltic birch slats configured in an aerodynamic parabolic cage, it encloses the light source while projecting dramatic linear shadows across ceilings and walls. Pre-assembled with a premium champagne gold core and aircraft-grade suspension wire, this fixture has earned acclaim across residential dining spaces and boutique hospitality interiors worldwide.',
    289.99, 249.99, 95.00,
    18, 5, 'Steam-Bent Russian Birch Plywood Ribs, Anodized Champagne Aluminum Core, Braided Suspension Wire', '50 cm x 50 cm x 42 cm (19.7" x 19.7" x 16.5")', 2.20,
    'Hardwired Ceiling Fixture (110V - 240V AC, E26 / E27 Socket, Max 60W)', 'Ceiling Suspended with 2.0m Aircraft Cable & Champagne Gold Canopy', 0, 36,
    1, 1, 4.97, 64
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    18, 'SKU-WD-P18', 'P18', '3D Multi-Layered Wooden Mother and Child Silhouette Wall Art Plaque', '3d-multi-layered-wooden-mother-and-child-silhouette-wall-art-plaque-p18',
    102, 3, 'Tender multi-layered wooden relief plaque depicting a mother cradling her child surrounded by an ornate filigree halo.', 'Express unconditional love and family warmth with the 3D Multi-Layered Wooden Mother and Child Silhouette Wall Art Plaque. Seven layered tiers of contrasting natural birch and smoked walnut portray a loving mother embracing her infant, encircled by a breathtaking filigree swirl halo. Designed for versatile display, it features both an integrated fold-out wooden kickstand for mantels and tables, as well as a wall hanger for nursery or bedroom walls.',
    129.99, 109.99, 42.00,
    26, 5, '7-Layer Natural Birch & Smoked Walnut Wood, Gold Acrylic Accent Inlay', '45 cm x 55 cm x 3.0 cm (17.7" x 21.6" x 1.2")', 1.90,
    'None', 'Integrated Tabletop Fold-Out Kickstand & Sawtooth Wall Mount', 0, 12,
    0, 1, 4.92, 33
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    19, 'SKU-WD-P19', 'P19', 'Lotus Flower Glowing Acrylic and Wood LED Ambient Night Light', 'lotus-flower-glowing-acrylic-and-wood-led-ambient-night-light-p19',
    204, 3, '''Small Lamp, Big Happiness'' - Edge-lit optical acrylic lotus flower night light nestled into a solid beech wood base.', 'Experience tranquility with the Lotus Flower Glowing Acrylic and Wood LED Ambient Night Light (''Small Lamp, Big Happiness''). A precision laser-engraved optical acrylic lotus flower slots seamlessly into a solid European beech wood base embedded with warm 2700K micro-LEDs. Touch-sensitive controls allow you to smoothly dim the illumination from an ethereal nightlight glow to a warm reading light. USB-powered for use anywhere from bedside nightstands to meditation alters.',
    49.99, 39.99, 15.00,
    45, 5, 'Optical Grade Laser-Etched Cast Acrylic, Solid Natural Beech Wood Base, Warm LEDs', '20 cm x 8 cm x 22 cm (7.9" x 3.1" x 8.7")', 0.65,
    'USB 5V DC Powered (1.5m Cable with Smart Touch Dimmer Included)', 'Freestanding Tabletop / Bedside Stand (Optional Wall Bracket Included)', 0, 12,
    1, 1, 4.88, 58
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    20, 'SKU-WD-P20', 'P20', 'Minimalist Round Multi-Layered Wooden Desk Clock', 'minimalist-round-multi-layered-wooden-desk-clock-p20',
    302, 4, '''Small in Size, Big in Style'' - Compact circular 5-layer wooden desk clock with whisper-silent sweep movement.', 'The Minimalist Round Multi-Layered Wooden Desk Clock (''Small in Size, Big in Style'') adds architectural charm to study tables and office desks. Built with five stepped layers of blonde birch and rich walnut, this compact clock features minimalist geometric hour markers and brushed gold metal hands. Equipped with a premium continuous sweep quartz movement, it operates in total silence without distracting tick-tock sounds.',
    54.99, 46.99, 18.00,
    35, 5, '5-Layer Birch & Walnut Plywood, Silent Sweep Quartz Movement, Matte Gold Hands', '18 cm x 18 cm x 4.0 cm (7.1" x 7.1" x 1.6")', 0.55,
    '1 x AA Carbon-Zinc Battery (Not Included)', 'Freestanding Desk Stand with Anti-Slip Silicone Footing', 0, 24,
    0, 1, 4.83, 44
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    21, 'SKU-WD-P21', 'P21', 'Modern Asymmetric 3D Multi-Layered Walnut Wooden Wall Clock', 'modern-asymmetric-3d-multi-layered-walnut-wooden-wall-clock-p21',
    301, 4, 'Sculptural asymmetric 3D layered walnut wall clock showcasing fluid organic swirls and minimalist brass hands.', 'Elevate your walls with the Modern Asymmetric 3D Multi-Layered Walnut Wooden Wall Clock. Breaking away from traditional circular shapes, this timepiece features organic contoured stepped layers that mimic topographical fluidity. Finished in rich American black walnut with contrasting inner blonde wood relief and understated brass hour and minute hands, it doubles as both a functional clock and a modern art installation.',
    89.99, 74.99, 28.00,
    22, 5, 'American Black Walnut Veneer & Birch Substrate, High-Torque Silent Sweep Quartz, Brass Hands', '35 cm x 35 cm x 4.0 cm (13.8" x 13.8" x 1.6")', 1.25,
    '1 x AA Battery', 'Rear Keyhole Wall Mount Slot', 0, 24,
    1, 1, 4.90, 39
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    22, 'SKU-WD-P22', 'P22', 'Intricate 3D Multi-Layered Wooden Mandala Wall Clock', 'intricate-3d-multi-layered-wooden-mandala-wall-clock-p22',
    301, 4, '''Art That Keeps You In Time'' - 6-layer precision laser-cut circular mandala wall clock blending spiritual art and functional timekeeping.', 'The Intricate 3D Multi-Layered Wooden Mandala Wall Clock is heralded as ''Art That Keeps You In Time.'' Six delicate concentric tiers of laser-carved wood in warm mahogany and light birch create a mesmerizing optical relief. Numbers are subtly integrated into the outer mandala petals for clear legibility without disrupting the sacred geometry. Powered by a high-precision silent sweep mechanism, it brings peace to bedrooms and living rooms alike.',
    99.99, 84.99, 32.00,
    28, 5, '6-Tier Precision Laser-Cut Mahogany & Birch Wood, Silent Quartz Sweep Engine', '40 cm x 40 cm x 4.0 cm (15.7" x 15.7" x 1.6")', 1.50,
    '1 x AA Battery', 'Pre-Installed Center Wall Bracket', 0, 24,
    1, 1, 4.94, 48
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    23, 'SKU-WD-P23', 'P23', 'Modern Topographic Contoured 3D Layered Wooden Wall Clock', 'modern-topographic-contoured-3d-layered-wooden-wall-clock-p23',
    301, 4, '''Beauty In Every Layer'' - Topographic contour map-inspired layered wall clock with terraced elevation levels.', 'Inspired by geological elevation maps, the Modern Topographic Contoured 3D Layered Wooden Wall Clock (''Beauty In Every Layer'') features undulating tiered terraces that create intriguing natural depth. Enclosed by a clean blonde ash outer rim, the terraced levels produce striking shadow gradients under changing ambient room light. Completely silent and endlessly captivating for design studios and modern apartments.',
    84.99, NULL, 27.00,
    30, 5, 'Layered High-Density Moisture-Resistant MDF, Natural Ash Veneer Rim, Silent Quartz', '38 cm x 38 cm x 4.0 cm (15.0" x 15.0" x 1.6")', 1.35,
    '1 x AA Battery', 'Rear Keyhole Hanger Bracket', 0, 24,
    0, 1, 4.86, 29
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    24, 'SKU-WD-P24', 'P24', '3D Multi-Layered Wooden Woman Portrait with Red Lips Wall Art Plaque', '3d-multi-layered-wooden-woman-portrait-with-red-lips-wall-art-plaque-p24',
    102, 3, '''Art That Speaks: Layers of Emotion'' - Stylized 8-tier relief portrait of a woman''s visage featuring a bold pop of crimson red lips.', 'The 3D Multi-Layered Wooden Woman Portrait with Red Lips Wall Art Plaque is celebrated under the theme ''Art That Speaks - Layers of Emotion.'' Eight precision-carved layers of birch wood assemble into a high-fashion stylized portrait. While the face, hat, and flowing hair maintain earthy wood and charcoal tones, the lips are hand-detailed in a bold high-gloss crimson red, delivering sensational pop-art drama to modern living rooms and chic boutiques.',
    139.99, 119.99, 45.00,
    17, 5, '8-Tier Layered Birch Wood, Acrylic Bold Crimson Red Lip Inlay, Dark Walnut Stain', '45 cm x 60 cm x 3.5 cm (17.7" x 23.6" x 1.4")', 2.25,
    'None', 'Pre-Installed Flush Wall Cleat Hangers', 0, 12,
    1, 1, 4.90, 26
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    25, 'SKU-WD-P25', 'P25', 'Framed 3D Multi-Layered Wooden Koi Fish Shadow Box Wall Art', 'framed-3d-multi-layered-wooden-koi-fish-shadow-box-wall-art-p25',
    103, 3, '''Nature. Perfected.'' - Enchanting Japanese shadow box wall art with twin red and gold koi fish gliding beneath lily pads.', 'Capturing tranquility and auspicious fortune, the Framed 3D Multi-Layered Wooden Koi Fish Shadow Box Wall Art (''Nature. Perfected.'') depicts two graceful Japanese Nishikigoi fish swimming in harmony. Multi-plane wooden lily pads in graduated emerald shades hover above ripple contour layers, while the hand-painted scarlet and gold koi appear to swim suspended in water. Encased inside a 5cm-deep satin white shadow box frame.',
    169.99, 144.99, 54.00,
    19, 5, 'Multi-Plane Floating Birch Relief, Hand-Painted Scarlet & Gold Koi, Satin White Shadow Box', '50 cm x 50 cm x 5.0 cm (19.7" x 19.7" x 2.0")', 2.70,
    'None', 'Sawtooth Hanger & Sturdy Tabletop Depth for Free-Standing Display', 0, 12,
    1, 1, 4.95, 43
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    26, 'SKU-WD-P26', 'P26', 'Circular 3D Multi-Layered Wooden Peacock Feather Wall Art Plaque', 'circular-3d-multi-layered-wooden-peacock-feather-wall-art-plaque-p26',
    103, 3, '''Rupam Anokham, Bhavah Ekah'' - Circular 60cm wall medallion showcasing radial multi-layered peacock feather eyelets.', 'Embodying the philosophical harmony ''Rupam Anokham, Bhavah Ekah'' (Unique in form, unified in essence), this Circular 3D Multi-Layered Wooden Peacock Feather Wall Art Plaque is a visual wonder. A central sculpted peacock bust gives rise to concentric rings of laser-cut feather eyelets finished in iridescent teal, sapphire, and brilliant gold leaf foil. Stunning when mounted inside illuminated wall arches or above carved wooden credenzas.',
    159.99, NULL, 50.00,
    20, 5, 'Radial 7-Layer Birch Wood, Iridescent Teal & Emerald Dye, Gold Leaf Accents', '60 cm x 60 cm x 3.0 cm (23.6" x 23.6" x 1.2")', 2.35,
    'None', 'Center Heavy-Duty Wall Anchor Bracket', 0, 12,
    0, 1, 4.88, 30
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    27, 'SKU-WD-P27', 'P27', 'MATRA HAUS Aurora Red Curved Acrylic Rib Pendant Lamp', 'matra-haus-aurora-red-curved-acrylic-rib-pendant-lamp-p27',
    201, 1, 'Architectural MATRA HAUS pendant lamp with curved translucent ruby-red acrylic ribs surrounding a glowing vintage Edison bulb.', 'A tour-de-force of contemporary industrial lighting, the MATRA HAUS Aurora Red Curved Acrylic Rib Pendant Lamp channels the vibrant energy of the Northern Lights. Dozens of laser-cut translucent ruby-red acrylic fins are arranged radially around an amber-tinted vintage filament bulb. The curved acrylic channels light outward with brilliant prismatic glow, infusing dining rooms, trendy lounges, and creative executive suites with warmth and charisma.',
    269.99, 229.99, 88.00,
    14, 5, 'Laser-Cut Translucent Crimson Acrylic Fins, Satin Anodized Metal Skeleton, Vintage Edison Filament Bulb', '48 cm x 48 cm x 40 cm (18.9" x 18.9" x 15.7")', 2.50,
    'Hardwired Ceiling Fixture (110V - 240V AC, E26/E27 Base, Vintage Bulb Included)', 'Ceiling Suspended with 1.8m Braided Red/Black Cord & Metal Canopy', 0, 36,
    1, 1, 4.96, 35
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    28, 'SKU-WD-P28', 'P28', 'MATRA HAUS Organic Fluted Wave Wooden Slat Pendant Light', 'matra-haus-organic-fluted-wave-wooden-slat-pendant-light-p28',
    201, 1, 'Large 550x500mm organic fluted wave wooden slat pendant chandelier by MATRA HAUS, offering acoustic warmth and sculptural impact.', 'The MATRA HAUS Organic Fluted Wave Wooden Slat Pendant Light (550x500mm) is a grand architectural chandelier inspired by rolling ocean waves. Made from continuous steam-curved birch veneer slats that billow into an organic fluted hourglass silhouette, this statement piece provides acoustic warmth and soft ambient illumination. Frequently specified for commercial dining installations and luxury residences under the welcoming ethos of ''Atithi Devo Bhava''.',
    329.99, 289.99, 110.00,
    11, 5, 'Steam-Curved Architectural Grade Birch Veneer, Brushed Brass Fasteners, Internal Diffuser', '55 cm x 55 cm x 50 cm (21.7" x 21.7" x 19.7") [550 x 500 mm]', 2.85,
    'Hardwired Ceiling Fixture (110V - 240V AC, E26/E27 Socket)', 'Triple Aircraft Cable Suspension System with Brushed Brass Canopy', 0, 36,
    1, 1, 4.98, 49
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    29, 'SKU-WD-P29', 'P29', 'Framed 3D Multi-Layered Wooden Tree of Life Filigree Relief Artwork', 'framed-3d-multi-layered-wooden-tree-of-life-filigree-relief-artwork-p29',
    104, 3, 'Intricate Bodhi Tree of Life relief artwork showcasing micro-filigree branch tendrils inside a crisp white shadow frame.', 'Revering the sacred Bodhi tree, the Framed 3D Multi-Layered Wooden Tree of Life Filigree Relief Artwork displays astonishing laser-cut intricacy. Eight tiers of fine branches and delicate heart-shaped leaves spread across a gilded background, producing a dense canopy of natural relief. Housed within a clean white gallery frame, it introduces a calming, restorative sanctuary feeling to bedrooms and reading alcoves.',
    149.99, NULL, 48.00,
    23, 5, '8-Layer Micro-Filigree Birch Wood, Warm Gold Underlay, Gallery White Frame', '45 cm x 60 cm x 4.0 cm (17.7" x 23.6" x 1.6")', 2.40,
    'None', 'Heavy-Duty Dual Sawtooth Wall Brackets', 0, 12,
    0, 1, 4.87, 25
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    30, 'SKU-WD-P30', 'P30', 'Sacred Om (Aum) Lotus 3D Multi-Layered Wooden Mandala Wall Art', 'sacred-om-aum-lotus-3d-multi-layered-wooden-mandala-wall-art-p30',
    105, 3, 'Sacred 65cm circular multi-layered wooden mandala wall sculpture featuring the sacred Om (Aum) syllable on blooming lotus petals.', 'Channel universal energy and inner peace with the Sacred Om (Aum) Lotus 3D Multi-Layered Wooden Mandala Wall Art. Nine intricately stacked layers of laser-cut birch radiate from a gleaming metallic gold sacred Om glyph at its heart. Blooming lotus petals hand-dyed in harmonious saffron, crimson, and sage create a deep dimensional aura. An awe-inspiring focal point for yoga studios, prayer rooms, or modern living spaces.',
    179.99, 154.99, 58.00,
    16, 5, '9-Layer Sustainable Birch Plywood, Saffron, Crimson & Sage Wood Dyes, Metallic Gold Center', '65 cm x 65 cm x 3.5 cm (25.6" x 25.6" x 1.4")', 2.80,
    'None', 'Pre-Installed Center Wall Mounting Bracket', 0, 12,
    1, 1, 4.97, 39
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    31, 'SKU-WD-P31', 'P31', 'Lord Ganesha on Lotus 3D Multi-Layered Colorful Wooden Wall Art', 'lord-ganesha-on-lotus-3d-multi-layered-colorful-wooden-wall-art-p31',
    105, 3, 'Magnificent multi-layered colorful wooden wall sculpture of Lord Ganesha seated on a lotus throne, embellished with gold leaf.', 'Invoking blessings of prosperity, wisdom, and the removal of obstacles, the Lord Ganesha on Lotus 3D Multi-Layered Colorful Wooden Wall Art is a masterwork of spiritual artistry. Lord Ganesha is depicted majestically seated upon a multi-petaled lotus, surrounded by an ornate halo and protective archway. Each tier is hand-painted in vibrant festive enamels with shimmering gold leaf accents on the crown, modak, and trunk, celebrating Indian artisanal heritage.',
    199.99, 169.99, 65.00,
    14, 5, 'Multi-Layered Birch Wood Relief, Hand-Painted Vivid Enamels, Gold Leaf Detailing', '60 cm x 75 cm x 4.0 cm (23.6" x 29.5" x 1.6")', 3.20,
    'None', 'Reinforced Heavy-Duty Wall Anchors & Brackets', 0, 12,
    1, 1, 4.99, 54
);
INSERT INTO products (
    product_id, sku, legacy_code, name, slug, category_id, brand_id,
    short_description, description, base_price, sale_price, cost_price,
    stock_quantity, low_stock_threshold, material, dimensions, weight_kg,
    power_source, mounting_type, assembly_required, warranty_months,
    is_featured, is_active, rating_average, rating_count
) VALUES (
    32, 'SKU-WD-P32', 'P32', 'Framed 3D Multi-Layered Wooden World Map Topographic Ocean Depth Relief Art', 'framed-3d-multi-layered-wooden-world-map-topographic-ocean-depth-relief-art-p32',
    106, 3, 'Substantial 90x60cm laser-cut wooden world map with 6 stepped bathymetric ocean depth relief tiers in dark walnut frame.', 'Satisfy your wanderlust and passion for cartography with the Framed 3D Multi-Layered Wooden World Map Topographic Ocean Depth Relief Art. Spanning an impressive 90 by 60 centimeters, this museum-grade piece pairs finely etched birch continents with six stepped bathymetric layers that plunge into deep ocean trenches. Finished in rich shades of turquoise, azure, and midnight navy, it is encased in a custom dark walnut hardwood frame.',
    279.99, 239.99, 92.00,
    12, 5, 'Laser-Cut Birch Continents, 6-Layer Graduated Azure & Navy Bathymetric Ocean Depth Tiers, Dark Walnut Frame', '90 cm x 60 cm x 4.5 cm (35.4" x 23.6" x 1.8")', 4.60,
    'None', 'Heavy-Duty Dual French Cleat Mounting Rail', 0, 24,
    1, 1, 4.98, 62
);

-- -----------------------------------------------------------------------------
-- Data: product_images (Complete Mapping of All 91 Assets)
-- -----------------------------------------------------------------------------
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (1, 1, '1.svg', 'assets/products/1.svg', 'image/svg+xml', 'Close-up detail of layered wooden mandala and central amber spiral disc', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (2, 1, '2.svg', 'assets/products/2.svg', 'image/svg+xml', 'Full front view of circular layered mandala on dark background', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (3, 1, '3.svg', 'assets/products/3.svg', 'image/svg+xml', 'Living room interior mockup showing mandala mounted on feature wall', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (4, 2, '4.svg', 'assets/products/4.svg', 'image/svg+xml', 'Front tabletop display view in wooden frame', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (5, 2, '5.svg', 'assets/products/5.svg', 'image/svg+xml', 'Sideboard / credenza interior staging view with vase and basket', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (6, 2, '6.svg', 'assets/products/6.svg', 'image/svg+xml', 'Perspective 3D angled view highlighting wooden frame and relief depth', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (7, 3, '7.svg', 'assets/products/7.svg', 'image/svg+xml', 'Close-up detail of flowing layered wood hair contours', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (8, 3, '8.svg', 'assets/products/8.svg', 'image/svg+xml', 'Front display view on white shelf between decorative ceramic vases', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (9, 3, '9.svg', 'assets/products/9.svg', 'image/svg+xml', 'Angled perspective view on display shelf under spotlight', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (10, 4, '10.svg', 'assets/products/10.svg', 'image/svg+xml', 'Pair of artichoke cutout pendant lamps illuminated in kitchen setting', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (11, 4, '11.svg', 'assets/products/11.svg', 'image/svg+xml', 'Close-up illuminated view showing warm light filtering through heart/chevron cutouts', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (12, 4, '12.svg', 'assets/products/12.svg', 'image/svg+xml', 'Single pendant lamp hanging unlit in natural window daylight', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (13, 5, '13.svg', 'assets/products/13.svg', 'image/svg+xml', 'Three glowing curved slat lantern lamps on dark floor creating atmospheric shadows', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (14, 5, '14.svg', 'assets/products/14.svg', 'image/svg+xml', 'Three curved slat lantern lamps on light neutral surface', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (15, 5, '15.svg', 'assets/products/15.svg', 'image/svg+xml', 'Linear front arrangement of all three lantern sizes', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (16, 6, '16.svg', 'assets/products/16.svg', 'image/svg+xml', 'Full front view in white frame resting on console table', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (17, 6, '17.svg', 'assets/products/17.svg', 'image/svg+xml', 'Macro close-up detail showing multi-level laser-cut filigree floral layers', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (18, 7, '18.svg', 'assets/products/18.svg', 'image/svg+xml', 'Square framed front view showing multi-colored feathers on orange background', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (19, 7, '19.svg', 'assets/products/19.svg', 'image/svg+xml', 'Living room mockup hanging above contemporary light-blue sofa', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (20, 7, '20.svg', 'assets/products/20.svg', 'image/svg+xml', 'Angled 3D perspective close-up showing relief layer depth', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (21, 8, '21.svg', 'assets/products/21.svg', 'image/svg+xml', 'Front view on rustic wooden floor against textured stone wall', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (22, 8, '22.svg', 'assets/products/22.svg', 'image/svg+xml', 'Angled perspective view showcasing layered wood depth and black frame', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (23, 9, '23.svg', 'assets/products/23.svg', 'image/svg+xml', 'Angled top-down view of semicircular fan plumage in blue, green, and gold', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (24, 9, '24.svg', 'assets/products/24.svg', 'image/svg+xml', 'Close-up macro detail of multi-layered peacock feather eyelets', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (25, 9, '25.svg', 'assets/products/25.svg', 'image/svg+xml', 'Wall-mounted headboard / console view above table with lamp and vases', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (26, 10, '26.svg', 'assets/products/26.svg', 'image/svg+xml', 'Half mandala mounted vertically along wall column/edge', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (27, 10, '27.svg', 'assets/products/27.svg', 'image/svg+xml', 'Half mandala mounted horizontally above black credenza as decorative headboard', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (28, 11, '28.svg', 'assets/products/28.svg', 'image/svg+xml', 'Complete 360-degree circular mandala mounted on textured wall above modern brown sofa', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (29, 12, '29.svg', 'assets/products/29.svg', 'image/svg+xml', 'Close-up angled view highlighting multi-colored leaves and teal trunk layers', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (30, 12, '30.svg', 'assets/products/30.svg', 'image/svg+xml', 'Wall-mounted interior mockup on terracotta accent wall above wooden sideboard', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (31, 12, '31.svg', 'assets/products/31.svg', 'image/svg+xml', 'Wall-mounted interior mockup on slate-blue wall beside contemporary armchair', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (32, 13, '32.svg', 'assets/products/32.svg', 'image/svg+xml', 'Close-up macro view of blue and burgundy layered lotus petals and border', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (33, 13, '33.svg', 'assets/products/33.svg', 'image/svg+xml', 'Living space mockup mounted inside illuminated architectural wall arch', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (34, 13, '34.svg', 'assets/products/34.svg', 'image/svg+xml', 'Modern office / lounge mockup mounted on slatted wood accent wall', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (35, 14, '35.svg', 'assets/products/35.svg', 'image/svg+xml', 'Ceiling-hung pendant lamp in natural birch finish in airy Scandinavian living room', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (36, 14, '38.svg', 'assets/products/38.svg', 'image/svg+xml', 'Close-up studio view of natural birch overlapping scales illuminated beside pink tulips', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (37, 15, '36.svg', 'assets/products/36.svg', 'image/svg+xml', 'Full standing floor lamp with wooden pinecone shade on tall pole in living room beside sofa', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (38, 16, '37.svg', 'assets/products/37.svg', 'image/svg+xml', 'Ceiling-hung pendant lamp in charcoal/dark grey stained wood finish above yellow sofa', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (39, 17, '39.svg', 'assets/products/39.svg', 'image/svg+xml', 'Pendant lamp illuminated in evening living room above sectional sofa', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (40, 17, '40.svg', 'assets/products/40.svg', 'image/svg+xml', 'Pendant lamp illuminated above round wooden dining table in sunlight', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (41, 17, '41.svg', 'assets/products/41.svg', 'image/svg+xml', 'Side close-up view on abstract green/yellow polygonal background (clean version)', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (42, 17, '43.jpg', 'assets/products/43.jpg', 'image/jpeg', 'Evening living room scene with MATRA HAUS Design Studio logo watermark', 0, 4);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (43, 17, '44.jpg', 'assets/products/44.jpg', 'image/jpeg', 'Dining table scene with MATRA HAUS Design Studio logo watermark', 0, 5);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (44, 17, '45.jpg', 'assets/products/45.jpg', 'image/jpeg', 'Side close-up view with MATRA HAUS Design Studio logo watermark', 0, 6);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (45, 17, 'ChatGPT Image Apr 22, 2026, 11_47_30 AM.png', 'assets/products/ChatGPT Image Apr 22, 2026, 11_47_30 AM.png', 'image/png', 'High-resolution clean rendering of evening living room scene', 0, 7);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (46, 17, 'ChatGPT Image Apr 22, 2026, 11_57_00 AM.png', 'assets/products/ChatGPT Image Apr 22, 2026, 11_57_00 AM.png', 'image/png', 'High-resolution clean rendering of dining table scene', 0, 8);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (47, 17, 'ChatGPT Image Apr 22, 2026, 11_57_35 AM.png', 'assets/products/ChatGPT Image Apr 22, 2026, 11_57_35 AM.png', 'image/png', 'High-resolution clean rendering of daylight living room scene', 0, 9);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (48, 17, 'Blue and Yellow Modern Online Course Flyer Landscape (2).mp4', 'assets/products/Blue and Yellow Modern Online Course Flyer Landscape (2).mp4', 'video/mp4', '3D turntable animation video featuring MATRA HAUS Design Studio brand overlay', 0, 10);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (49, 17, 'New_video2_ryece1.mp4', 'assets/products/New_video2_ryece1.mp4', 'video/mp4', 'Clean 3D turntable animation video showing full 360-degree rotation of pendant lamp', 0, 11);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (50, 18, '42.svg', 'assets/products/42.svg', 'image/svg+xml', 'Freestanding display on living room table/rug showcasing ornate filigree swirl halo', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (51, 18, '43.svg', 'assets/products/43.svg', 'image/svg+xml', 'Wall-mounted display above display ledge in modern living room', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (52, 18, '44.svg', 'assets/products/44.svg', 'image/svg+xml', 'Bedroom wall-mounted display above bed headboard', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (53, 19, '45.svg', 'assets/products/45.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''Small Lamp, Big Happiness'')', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (54, 19, '46.svg', 'assets/products/46.svg', 'image/svg+xml', 'Tabletop bedside nightstand lifestyle view with warm golden edge-lit glow', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (55, 19, '47.svg', 'assets/products/47.svg', 'image/svg+xml', 'Wall-mounted configuration lifestyle view with warm ambient wall backlight', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (56, 20, '48.svg', 'assets/products/48.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''Small in Size, Big in Style'')', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (57, 20, '49.svg', 'assets/products/49.svg', 'image/svg+xml', 'Minimalist study desk staging view with notebook, pen, and coffee mug', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (58, 20, '49(1).svg', 'assets/products/49(1).svg', 'image/svg+xml', 'Identical binary duplicate file of 49.svg (exact byte copy)', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (59, 20, '50.svg', 'assets/products/50.svg', 'image/svg+xml', 'Study desk workspace view with laptop, desk plant, and wooden figurine', 0, 4);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (60, 21, '51.svg', 'assets/products/51.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''MODERN LAYERED WALL CLOCK'')', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (61, 21, '52.svg', 'assets/products/52.svg', 'image/svg+xml', 'Living room interior mockup on warm beige wall above contemporary sofa', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (62, 21, '53.svg', 'assets/products/53.svg', 'image/svg+xml', 'Angled perspective view emphasizing contoured walnut stepped layers', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (63, 22, '54.svg', 'assets/products/54.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''Mandala WALL CLOCK - Art That Keeps You In Time'')', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (64, 22, '55.svg', 'assets/products/55.svg', 'image/svg+xml', 'Living room interior mockup mounted above cream sofa with patterned cushions', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (65, 22, '56.svg', 'assets/products/56.svg', 'image/svg+xml', 'Bohemian bedroom interior mockup mounted above wooden bed frame', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (66, 23, '57.svg', 'assets/products/57.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''BEAUTY IN Every Layer - Layered MDF Wall Clock'')', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (67, 23, '58.svg', 'assets/products/58.svg', 'image/svg+xml', 'Home office / studio workspace mockup mounted above desk and computer', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (68, 23, '59.svg', 'assets/products/59.svg', 'image/svg+xml', 'Living room / entryway mockup mounted on sunlit wall above rattan credenza', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (69, 24, '60.svg', 'assets/products/60.svg', 'image/svg+xml', 'Modern indoor atrium / green feature wall display above blonde wood console', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (70, 24, '61.svg', 'assets/products/61.svg', 'image/svg+xml', 'Warm terracotta living room interior view with family lounging', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (71, 24, '62.svg', 'assets/products/62.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''ART THAT SPEAKS - Layers of emotion'')', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (72, 25, '63.svg', 'assets/products/63.svg', 'image/svg+xml', 'Wall-mounted display in white shadow box frame above wooden console table', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (73, 25, '64.svg', 'assets/products/64.svg', 'image/svg+xml', 'Freestanding tabletop display angled view beside books and plant', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (74, 25, '65.svg', 'assets/products/65.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''NATURE. PERFECTED. - 3D LAYERED WALL ART'')', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (75, 26, '66.svg', 'assets/products/66.svg', 'image/svg+xml', 'Mounted inside architectural illuminated wall arch in minimalist sitting room', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (76, 26, '67.svg', 'assets/products/67.svg', 'image/svg+xml', 'Mounted on textured wall above carved wooden credenza with brass lamp and plant', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (77, 26, '68.svg', 'assets/products/68.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''Rupam Anokham, Bhavah Ekah'')', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (78, 27, '69.svg', 'assets/products/69.svg', 'image/svg+xml', 'Pendant lamp illuminated above sofa in modern living room with warm ambient glow', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (79, 27, '70.svg', 'assets/products/70.svg', 'image/svg+xml', 'Pendant lamp suspended over executive office desk in high-rise workspace', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (80, 27, '71.svg', 'assets/products/71.svg', 'image/svg+xml', 'Close-up macro view showing glowing vintage Edison bulb and red acrylic ribs', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (81, 27, '72.svg', 'assets/products/72.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''AURORA PENDANT LAMP - MATRA HAUS DESIGN STUDIO'')', 0, 4);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (82, 28, '73.svg', 'assets/products/73.svg', 'image/svg+xml', 'Large organic fluted wood pendant lamp suspended in living room above blue sofa', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (83, 28, '74.svg', 'assets/products/74.svg', 'image/svg+xml', 'Commercial dining interior installation with multiple pendant lamps (''Atithi Devo Bhava'')', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (84, 28, '76.svg', 'assets/products/76.svg', 'image/svg+xml', 'E-commerce product marketing infographic poster (''WOODEN PENDANT LIGHT - MATRA HAUS DESIGN STUDIO'')', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (85, 29, '75.svg', 'assets/products/75.svg', 'image/svg+xml', 'Front tabletop display view in white frame resting on console table', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (86, 29, '77.svg', 'assets/products/77.svg', 'image/svg+xml', 'Macro close-up view showing intricate laser-cut Bodhi leaf filigree layers', 0, 2);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (87, 29, '78.svg', 'assets/products/78.svg', 'image/svg+xml', 'Bedroom interior wall-mounted display view above nightstand and lamp', 0, 3);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (88, 30, '79.svg', 'assets/products/79.svg', 'image/svg+xml', 'Large circular mandala with sacred Om symbol and green/red lotus petals mounted above rattan couch', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (89, 31, '80.svg', 'assets/products/80.svg', 'image/svg+xml', 'Vibrant multi-layered wood carving of Lord Ganesha seated on lotus mounted on living room wall', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (90, 32, '81.svg', 'assets/products/81.svg', 'image/svg+xml', 'Front tabletop display view in dark wood frame resting on wooden table', 1, 1);
INSERT INTO product_images (image_id, product_id, filename, file_path, media_type, alt_text, is_primary, sort_order) VALUES (91, 32, '82.svg', 'assets/products/82.svg', 'image/svg+xml', 'Angled perspective view showcasing stepped bathymetric ocean depth contours', 0, 2);

-- -----------------------------------------------------------------------------
-- Data: tags
-- -----------------------------------------------------------------------------
INSERT INTO tags (tag_id, name, slug) VALUES (1, 'Abstract', 'abstract');
INSERT INTO tags (tag_id, name, slug) VALUES (2, 'Acrylic LED', 'acrylic-led');
INSERT INTO tags (tag_id, name, slug) VALUES (3, 'Acrylic Lamp', 'acrylic-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (4, 'Ambient Light', 'ambient-light');
INSERT INTO tags (tag_id, name, slug) VALUES (5, 'Ambient Lighting', 'ambient-lighting');
INSERT INTO tags (tag_id, name, slug) VALUES (6, 'Animal Art', 'animal-art');
INSERT INTO tags (tag_id, name, slug) VALUES (7, 'Artichoke Lamp', 'artichoke-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (8, 'Asymmetric', 'asymmetric');
INSERT INTO tags (tag_id, name, slug) VALUES (9, 'Aurora Red', 'aurora-red');
INSERT INTO tags (tag_id, name, slug) VALUES (10, 'Auspicious', 'auspicious');
INSERT INTO tags (tag_id, name, slug) VALUES (11, 'Backlit LED', 'backlit-led');
INSERT INTO tags (tag_id, name, slug) VALUES (12, 'Bathymetric', 'bathymetric');
INSERT INTO tags (tag_id, name, slug) VALUES (13, 'Bedroom Decor', 'bedroom-decor');
INSERT INTO tags (tag_id, name, slug) VALUES (14, 'Bedside Lamp', 'bedside-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (15, 'Beech Wood', 'beech-wood');
INSERT INTO tags (tag_id, name, slug) VALUES (16, 'Birch Slat', 'birch-slat');
INSERT INTO tags (tag_id, name, slug) VALUES (17, 'Birch Wood', 'birch-wood');
INSERT INTO tags (tag_id, name, slug) VALUES (18, 'Bodhi Tree', 'bodhi-tree');
INSERT INTO tags (tag_id, name, slug) VALUES (19, 'Bohemian', 'bohemian');
INSERT INTO tags (tag_id, name, slug) VALUES (20, 'Botanical', 'botanical');
INSERT INTO tags (tag_id, name, slug) VALUES (21, 'Charcoal Grey', 'charcoal-grey');
INSERT INTO tags (tag_id, name, slug) VALUES (22, 'Circular', 'circular');
INSERT INTO tags (tag_id, name, slug) VALUES (23, 'Circular Art', 'circular-art');
INSERT INTO tags (tag_id, name, slug) VALUES (24, 'Clock', 'clock');
INSERT INTO tags (tag_id, name, slug) VALUES (25, 'Colorful', 'colorful');
INSERT INTO tags (tag_id, name, slug) VALUES (26, 'Contoured', 'contoured');
INSERT INTO tags (tag_id, name, slug) VALUES (27, 'Cozy Home', 'cozy-home');
INSERT INTO tags (tag_id, name, slug) VALUES (28, 'Curved Slat', 'curved-slat');
INSERT INTO tags (tag_id, name, slug) VALUES (29, 'Designer Lighting', 'designer-lighting');
INSERT INTO tags (tag_id, name, slug) VALUES (30, 'Desk Clock', 'desk-clock');
INSERT INTO tags (tag_id, name, slug) VALUES (31, 'Dining Room', 'dining-room');
INSERT INTO tags (tag_id, name, slug) VALUES (32, 'Edison Bulb', 'edison-bulb');
INSERT INTO tags (tag_id, name, slug) VALUES (33, 'Family', 'family');
INSERT INTO tags (tag_id, name, slug) VALUES (34, 'Fan Art', 'fan-art');
INSERT INTO tags (tag_id, name, slug) VALUES (35, 'Feather Plaque', 'feather-plaque');
INSERT INTO tags (tag_id, name, slug) VALUES (36, 'Figurative', 'figurative');
INSERT INTO tags (tag_id, name, slug) VALUES (37, 'Filigree', 'filigree');
INSERT INTO tags (tag_id, name, slug) VALUES (38, 'Flagship', 'flagship');
INSERT INTO tags (tag_id, name, slug) VALUES (39, 'Floor Lamp', 'floor-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (40, 'Floral', 'floral');
INSERT INTO tags (tag_id, name, slug) VALUES (41, 'Fluted Wave', 'fluted-wave');
INSERT INTO tags (tag_id, name, slug) VALUES (42, 'Framed', 'framed');
INSERT INTO tags (tag_id, name, slug) VALUES (43, 'Framed Map', 'framed-map');
INSERT INTO tags (tag_id, name, slug) VALUES (44, 'Freestanding', 'freestanding');
INSERT INTO tags (tag_id, name, slug) VALUES (45, 'Geometric', 'geometric');
INSERT INTO tags (tag_id, name, slug) VALUES (46, 'Gift Idea', 'gift-idea');
INSERT INTO tags (tag_id, name, slug) VALUES (47, 'Gold Leaf', 'gold-leaf');
INSERT INTO tags (tag_id, name, slug) VALUES (48, 'Hand-Stained', 'hand-stained');
INSERT INTO tags (tag_id, name, slug) VALUES (49, 'Handcrafted', 'handcrafted');
INSERT INTO tags (tag_id, name, slug) VALUES (50, 'Headboard', 'headboard');
INSERT INTO tags (tag_id, name, slug) VALUES (51, 'Home Decor', 'home-decor');
INSERT INTO tags (tag_id, name, slug) VALUES (52, 'Indian Heritage', 'indian-heritage');
INSERT INTO tags (tag_id, name, slug) VALUES (53, 'Industrial Modern', 'industrial-modern');
INSERT INTO tags (tag_id, name, slug) VALUES (54, 'Japanese Art', 'japanese-art');
INSERT INTO tags (tag_id, name, slug) VALUES (55, 'Jewel Tones', 'jewel-tones');
INSERT INTO tags (tag_id, name, slug) VALUES (56, 'Koi Fish', 'koi-fish');
INSERT INTO tags (tag_id, name, slug) VALUES (57, 'Lantern', 'lantern');
INSERT INTO tags (tag_id, name, slug) VALUES (58, 'Large Lamp', 'large-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (59, 'Large Wall Art', 'large-wall-art');
INSERT INTO tags (tag_id, name, slug) VALUES (60, 'Laser-Cut', 'laser-cut');
INSERT INTO tags (tag_id, name, slug) VALUES (61, 'Lighting', 'lighting');
INSERT INTO tags (tag_id, name, slug) VALUES (62, 'Living Room', 'living-room');
INSERT INTO tags (tag_id, name, slug) VALUES (63, 'Lord Ganesha', 'lord-ganesha');
INSERT INTO tags (tag_id, name, slug) VALUES (64, 'Lotus', 'lotus');
INSERT INTO tags (tag_id, name, slug) VALUES (65, 'Luxury Decor', 'luxury-decor');
INSERT INTO tags (tag_id, name, slug) VALUES (66, 'Luxury Home', 'luxury-home');
INSERT INTO tags (tag_id, name, slug) VALUES (67, 'Luxury Lighting', 'luxury-lighting');
INSERT INTO tags (tag_id, name, slug) VALUES (68, 'MATRA HAUS', 'matra-haus');
INSERT INTO tags (tag_id, name, slug) VALUES (69, 'Mandala', 'mandala');
INSERT INTO tags (tag_id, name, slug) VALUES (70, 'Mandala Clock', 'mandala-clock');
INSERT INTO tags (tag_id, name, slug) VALUES (71, 'Meditation', 'meditation');
INSERT INTO tags (tag_id, name, slug) VALUES (72, 'Mid-Century', 'mid-century');
INSERT INTO tags (tag_id, name, slug) VALUES (73, 'Mindfulness', 'mindfulness');
INSERT INTO tags (tag_id, name, slug) VALUES (74, 'Minimalist', 'minimalist');
INSERT INTO tags (tag_id, name, slug) VALUES (75, 'Modern Art', 'modern-art');
INSERT INTO tags (tag_id, name, slug) VALUES (76, 'Modern Clock', 'modern-clock');
INSERT INTO tags (tag_id, name, slug) VALUES (77, 'Mother and Child', 'mother-and-child');
INSERT INTO tags (tag_id, name, slug) VALUES (78, 'Nature', 'nature');
INSERT INTO tags (tag_id, name, slug) VALUES (79, 'Night Light', 'night-light');
INSERT INTO tags (tag_id, name, slug) VALUES (80, 'Nordic', 'nordic');
INSERT INTO tags (tag_id, name, slug) VALUES (81, 'Nursery Decor', 'nursery-decor');
INSERT INTO tags (tag_id, name, slug) VALUES (82, 'Oak Frame', 'oak-frame');
INSERT INTO tags (tag_id, name, slug) VALUES (83, 'Ocean Depth', 'ocean-depth');
INSERT INTO tags (tag_id, name, slug) VALUES (84, 'Office Decor', 'office-decor');
INSERT INTO tags (tag_id, name, slug) VALUES (85, 'Panoramic', 'panoramic');
INSERT INTO tags (tag_id, name, slug) VALUES (86, 'Peacock', 'peacock');
INSERT INTO tags (tag_id, name, slug) VALUES (87, 'Pendant Chandelier', 'pendant-chandelier');
INSERT INTO tags (tag_id, name, slug) VALUES (88, 'Pendant Lamp', 'pendant-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (89, 'Pinecone', 'pinecone');
INSERT INTO tags (tag_id, name, slug) VALUES (90, 'Pop Art', 'pop-art');
INSERT INTO tags (tag_id, name, slug) VALUES (91, 'Portrait', 'portrait');
INSERT INTO tags (tag_id, name, slug) VALUES (92, 'Red Lips', 'red-lips');
INSERT INTO tags (tag_id, name, slug) VALUES (93, 'Royal Blue', 'royal-blue');
INSERT INTO tags (tag_id, name, slug) VALUES (94, 'Sacred Om', 'sacred-om');
INSERT INTO tags (tag_id, name, slug) VALUES (95, 'Scandinavian', 'scandinavian');
INSERT INTO tags (tag_id, name, slug) VALUES (96, 'Semi-Circular', 'semi-circular');
INSERT INTO tags (tag_id, name, slug) VALUES (97, 'Set of 3', 'set-of-3');
INSERT INTO tags (tag_id, name, slug) VALUES (98, 'Shadow Box', 'shadow-box');
INSERT INTO tags (tag_id, name, slug) VALUES (99, 'Silent Movement', 'silent-movement');
INSERT INTO tags (tag_id, name, slug) VALUES (100, 'Silent Quartz', 'silent-quartz');
INSERT INTO tags (tag_id, name, slug) VALUES (101, 'Silhouette', 'silhouette');
INSERT INTO tags (tag_id, name, slug) VALUES (102, 'Slat Lamp', 'slat-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (103, 'Spiritual', 'spiritual');
INSERT INTO tags (tag_id, name, slug) VALUES (104, 'Spiritual Art', 'spiritual-art');
INSERT INTO tags (tag_id, name, slug) VALUES (105, 'Statement Piece', 'statement-piece');
INSERT INTO tags (tag_id, name, slug) VALUES (106, 'Table Lamp', 'table-lamp');
INSERT INTO tags (tag_id, name, slug) VALUES (107, 'Tiger', 'tiger');
INSERT INTO tags (tag_id, name, slug) VALUES (108, 'Topographic', 'topographic');
INSERT INTO tags (tag_id, name, slug) VALUES (109, 'Travel', 'travel');
INSERT INTO tags (tag_id, name, slug) VALUES (110, 'Tree of Life', 'tree-of-life');
INSERT INTO tags (tag_id, name, slug) VALUES (111, 'Wall Art', 'wall-art');
INSERT INTO tags (tag_id, name, slug) VALUES (112, 'Wall Clock', 'wall-clock');
INSERT INTO tags (tag_id, name, slug) VALUES (113, 'Walnut', 'walnut');
INSERT INTO tags (tag_id, name, slug) VALUES (114, 'Wildlife', 'wildlife');
INSERT INTO tags (tag_id, name, slug) VALUES (115, 'Wood', 'wood');
INSERT INTO tags (tag_id, name, slug) VALUES (116, 'Wood Clock', 'wood-clock');
INSERT INTO tags (tag_id, name, slug) VALUES (117, 'Wood Craft', 'wood-craft');
INSERT INTO tags (tag_id, name, slug) VALUES (118, 'World Map', 'world-map');
INSERT INTO tags (tag_id, name, slug) VALUES (119, 'Yoga Decor', 'yoga-decor');

-- -----------------------------------------------------------------------------
-- Data: product_tags
-- -----------------------------------------------------------------------------
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 11);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 17);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 5);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (1, 45);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 1);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 75);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 82);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 72);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 101);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 36);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 113);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 74);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 61);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 95);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 17);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 7);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 31);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 106);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 57);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 61);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 102);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 97);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 27);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 40);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 71);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 86);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 114);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 25);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 49);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 107);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 114);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 6);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 85);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 86);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 96);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 34);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 55);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 19);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 50);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 96);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 59);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 13);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 49);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 22);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 59);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 105);
INSERT INTO product_tags (product_id, tag_id) VALUES (11, 62);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 110);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 20);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 103);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 22);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (12, 48);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 64);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 93);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 73);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 89);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 95);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 80);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 17);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 61);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 39);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 89);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 95);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 44);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 80);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 61);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 21);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 89);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 53);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 61);
INSERT INTO product_tags (product_id, tag_id) VALUES (16, 115);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 68);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 29);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 28);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 66);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 38);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 77);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 101);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 33);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 81);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 79);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 64);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 2);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 15);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 4);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 14);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 46);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 30);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 24);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 100);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 74);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 84);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 117);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 112);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 113);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 8);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 100);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 76);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 51);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 112);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 70);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 99);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 19);
INSERT INTO product_tags (product_id, tag_id) VALUES (22, 116);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 112);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 108);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 26);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 76);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 100);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 90);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 91);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 92);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 36);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (24, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 56);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 98);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 54);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 78);
INSERT INTO product_tags (product_id, tag_id) VALUES (25, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 86);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 35);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 23);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 55);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (26, 47);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 68);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 9);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 3);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 29);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 32);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 68);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 41);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 87);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 58);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 16);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 67);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 110);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 18);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 37);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 103);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 94);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 69);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 104);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 64);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 119);
INSERT INTO product_tags (product_id, tag_id) VALUES (30, 49);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 63);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 104);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 52);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 25);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 111);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 47);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 10);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 118);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 12);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 83);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 108);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 43);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 65);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 109);

-- -----------------------------------------------------------------------------
-- Data: product_variants (Representative Customization Options)
-- -----------------------------------------------------------------------------
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (1, 1, 'SKU-WD-P01-S', 'Small 45cm / Warm LED', 'Diameter', '45 cm (18")', 'Lighting', 'Warm White 3000K', -40.00, 10, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (2, 1, 'SKU-WD-P01-M', 'Standard 60cm / Warm LED', 'Diameter', '60 cm (24")', 'Lighting', 'Warm White 3000K', 0.00, 14, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (3, 1, 'SKU-WD-P01-L', 'Grand 90cm / Warm LED', 'Diameter', '90 cm (36")', 'Lighting', 'Warm White 3000K', 95.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (4, 1, 'SKU-WD-P01-AMB', 'Standard 60cm / Amber Sunset', 'Diameter', '60 cm (24")', 'Lighting', 'Amber Sunset 2200K', 15.00, 6, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (5, 4, 'SKU-WD-P04-WHT', 'Natural Birch / White Textile Cord', 'Finish', 'Natural Birch', 'Suspension Cord', 'White Braided (1.5m)', 0.00, 12, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (6, 4, 'SKU-WD-P04-BLK', 'Natural Birch / Black Fabric Cord', 'Finish', 'Natural Birch', 'Suspension Cord', 'Black Braided (1.5m)', 0.00, 10, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (7, 5, 'SKU-WD-P05-SML', 'Curved Slat Lantern - Small (25cm)', 'Size', 'Small (25cm H)', 'Pack', 'Single Unit', -120.00, 15, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (8, 5, 'SKU-WD-P05-MED', 'Curved Slat Lantern - Medium (35cm)', 'Size', 'Medium (35cm H)', 'Pack', 'Single Unit', -100.00, 12, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (9, 5, 'SKU-WD-P05-LRG', 'Curved Slat Lantern - Large (45cm)', 'Size', 'Large (45cm H)', 'Pack', 'Single Unit', -70.00, 10, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (10, 5, 'SKU-WD-P05-TRIO', 'Curved Slat Lantern - Full Trio Set', 'Size', 'Trio Set (S+M+L)', 'Pack', 'Complete 3-Piece Set', 0.00, 15, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (11, 10, 'SKU-WD-P10-WAL', '120cm Headboard / Walnut & Honey Oak', 'Width', '120 cm (47")', 'Finish', 'Walnut & Honey Oak', 0.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (12, 10, 'SKU-WD-P10-NAT', '120cm Headboard / Natural Blonde Birch', 'Width', '120 cm (47")', 'Finish', 'Natural Blonde Birch', -15.00, 4, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (13, 14, 'SKU-WD-P14-BRS', 'Pinecone Pendant / Brushed Brass Hardware', 'Finish', 'Natural Birch', 'Canopy', 'Brushed Brass', 0.00, 16, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (14, 14, 'SKU-WD-P14-BLK', 'Pinecone Pendant / Matte Black Hardware', 'Finish', 'Natural Birch', 'Canopy', 'Matte Black', 0.00, 12, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (15, 17, 'SKU-WD-P17-GLD', 'MATRA HAUS Slat Pendant / Champagne Gold', 'Size', 'Standard (50cm)', 'Canopy Core', 'Champagne Gold', 0.00, 10, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (16, 17, 'SKU-WD-P17-BLK', 'MATRA HAUS Slat Pendant / Anodized Black', 'Size', 'Standard (50cm)', 'Canopy Core', 'Anodized Black', 0.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (17, 19, 'SKU-WD-P19-WRM', 'Lotus Night Light / Warm White (2700K)', 'Light Color', 'Warm White 2700K', 'Base', 'Natural Beech', 0.00, 25, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (18, 19, 'SKU-WD-P19-RGB', 'Lotus Night Light / 7-Color Breathing LED', 'Light Color', 'Multi-Color RGB Touch', 'Base', 'Natural Beech', 10.00, 20, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (19, 21, 'SKU-WD-P21-WAL', 'Asymmetric Wall Clock / American Walnut', 'Timber', 'American Walnut', 'Hands', 'Brushed Brass', 0.00, 14, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (20, 21, 'SKU-WD-P21-OAK', 'Asymmetric Wall Clock / Golden Teak Oak', 'Timber', 'Golden Teak Oak', 'Hands', 'Matte Black', -10.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (21, 27, 'SKU-WD-P27-RED', 'MATRA HAUS Aurora Red / Vintage Amber Bulb', 'Rib Color', 'Aurora Red', 'Bulb Type', 'Vintage Edison 2200K', 0.00, 10, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (22, 27, 'SKU-WD-P27-CLR', 'MATRA HAUS Aurora Red / Dimmable Warm LED', 'Rib Color', 'Aurora Red', 'Bulb Type', 'Dimmable LED 3000K', 15.00, 4, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (23, 28, 'SKU-WD-P28-STD', 'MATRA HAUS Fluted Wave / 550x500mm', 'Dimensions', '550 x 500 mm', 'Wood Finish', 'Natural Architectural Birch', 0.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (24, 28, 'SKU-WD-P28-GRD', 'MATRA HAUS Fluted Wave / 750x680mm Grand', 'Dimensions', '750 x 680 mm', 'Wood Finish', 'Natural Architectural Birch', 120.00, 3, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (25, 32, 'SKU-WD-P32-WAL', 'World Map Bathymetric / Dark Walnut Frame', 'Size', '90 x 60 cm', 'Frame', 'Dark Walnut Hardwood', 0.00, 8, 1);
INSERT INTO product_variants (variant_id, product_id, sku, variant_name, option1_name, option1_value, option2_name, option2_value, price_modifier, stock_quantity, is_active) VALUES (26, 32, 'SKU-WD-P32-BLK', 'World Map Bathymetric / Matte Black Gallery', 'Size', '90 x 60 cm', 'Frame', 'Matte Black Gallery', 0.00, 4, 1);

-- -----------------------------------------------------------------------------
-- Data: customers (Sample Accounts)
-- -----------------------------------------------------------------------------
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (1, 'Elena', 'Rostova', 'elena.rostova@example.com', '+1-415-555-0192', '$2y$12$e8Z.kP.Xg8mZ/eZ2Z5J9.u5eY8R.6Y2j1m4s9d8w7e6r5t4y3u2i1', 'customer', 1);
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (2, 'Marcus', 'Vance', 'm.vance@interiorsdesign.com', '+1-212-555-0143', '$2y$12$k8Z.lP.Yh9nZ/fa3Z6K0.v6fZ9S.7Z3k2n5t0e9x8f7s6u5z4v3j2', 'customer', 1);
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (3, 'Sophia', 'Patel', 'sophia.patel@modernliving.org', '+1-312-555-0188', '$2y$12$p9A.mQ.Zi0oA/gb4A7L1.w7gA0T.8A4l3o6u1f0y9g8t7v6a5w4k3', 'customer', 1);
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (4, 'Liam', 'O''Connor', 'liam.oconnor@architects.net', '+1-206-555-0125', '$2y$12$q0B.nR.Aj1pB/hc5B8M2.x8hB1U.9B5m4p7v2g1z0h9u8w7b6x5l4', 'customer', 1);
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (5, 'Aria', 'Tanaka', 'aria.tanaka@zenithspaces.jp', '+1-650-555-0177', '$2y$12$r1C.oS.Bk2qC/id6C9N3.y9iC2V.0C6n5q8w3h2a1i0v9x8c7y6m5', 'customer', 1);
INSERT INTO customers (customer_id, first_name, last_name, email, phone, password_hash, role, is_active) VALUES (6, 'Admin', 'Storekeeper', 'admin@woodcraftstudio.com', '+1-800-555-0100', '$2y$12$s2D.pT.Cl3rD/je7D0O4.z0jD3W.1D7o6r9x4i3b2j1w0y9d8z7n6', 'admin', 1);

-- -----------------------------------------------------------------------------
-- Data: customer_addresses
-- -----------------------------------------------------------------------------
INSERT INTO customer_addresses (address_id, customer_id, address_type, full_name, street_address, apartment, city, state, postal_code, country, is_default) VALUES (1, 1, 'shipping', 'Elena Rostova', '742 Evergreen Terrace', 'Apt 4B', 'San Francisco', 'CA', '94107', 'United States', 1);
INSERT INTO customer_addresses (address_id, customer_id, address_type, full_name, street_address, apartment, city, state, postal_code, country, is_default) VALUES (2, 2, 'shipping', 'Marcus Vance', '350 5th Avenue', 'Suite 2200', 'New York', 'NY', '10118', 'United States', 1);
INSERT INTO customer_addresses (address_id, customer_id, address_type, full_name, street_address, apartment, city, state, postal_code, country, is_default) VALUES (3, 3, 'shipping', 'Sophia Patel', '233 S Wacker Dr', 'Floor 14', 'Chicago', 'IL', '60606', 'United States', 1);
INSERT INTO customer_addresses (address_id, customer_id, address_type, full_name, street_address, apartment, city, state, postal_code, country, is_default) VALUES (4, 4, 'shipping', 'Liam O''Connor', '400 Broad Street', 'Apt 12C', 'Seattle', 'WA', '98109', 'United States', 1);
INSERT INTO customer_addresses (address_id, customer_id, address_type, full_name, street_address, apartment, city, state, postal_code, country, is_default) VALUES (5, 5, 'shipping', 'Aria Tanaka', '100 Sand Hill Rd', 'Suite 300', 'Menlo Park', 'CA', '94025', 'United States', 1);

-- -----------------------------------------------------------------------------
-- Data: orders (Sample Customer Transactions)
-- -----------------------------------------------------------------------------
INSERT INTO orders (order_id, order_number, customer_id, status, subtotal, discount_amount, shipping_fee, tax_amount, total_amount, payment_method, payment_status, shipping_address_id) VALUES (1, 'ORD-2026-1001', 1, 'delivered', 159.99, 15.00, 0.00, 11.60, 156.59, 'credit_card', 'paid', 1);
INSERT INTO orders (order_id, order_number, customer_id, status, subtotal, discount_amount, shipping_fee, tax_amount, total_amount, payment_method, payment_status, shipping_address_id) VALUES (2, 'ORD-2026-1002', 2, 'delivered', 539.98, 40.00, 0.00, 40.00, 539.98, 'credit_card', 'paid', 2);
INSERT INTO orders (order_id, order_number, customer_id, status, subtotal, discount_amount, shipping_fee, tax_amount, total_amount, payment_method, payment_status, shipping_address_id) VALUES (3, 'ORD-2026-1003', 3, 'shipped', 189.99, 0.00, 15.00, 16.40, 221.39, 'paypal', 'paid', 3);
INSERT INTO orders (order_id, order_number, customer_id, status, subtotal, discount_amount, shipping_fee, tax_amount, total_amount, payment_method, payment_status, shipping_address_id) VALUES (4, 'ORD-2026-1004', 4, 'processing', 289.99, 20.00, 0.00, 21.60, 291.59, 'apple_pay', 'paid', 4);
INSERT INTO orders (order_id, order_number, customer_id, status, subtotal, discount_amount, shipping_fee, tax_amount, total_amount, payment_method, payment_status, shipping_address_id) VALUES (5, 'ORD-2026-1005', 5, 'pending', 84.99, 0.00, 10.00, 7.60, 102.59, 'credit_card', 'pending', 5);

-- -----------------------------------------------------------------------------
-- Data: order_items
-- -----------------------------------------------------------------------------
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (1, 1, 1, '3D Layered Wooden Circular Mandala Wall Art with Backlit LED Glow', 159.99, 1, 159.99);
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (2, 2, 17, 'MATRA HAUS Modern Wooden Curved Slat Pendant Lamp Fixture', 249.99, 1, 249.99);
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (3, 2, 28, 'MATRA HAUS Organic Fluted Wave Wooden Slat Pendant Light', 289.99, 1, 289.99);
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (4, 3, 10, 'Semi-Circular 3D Multi-Layered Wooden Mandala Wall Art Headboard', 189.99, 1, 189.99);
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (5, 4, 28, 'MATRA HAUS Organic Fluted Wave Wooden Slat Pendant Light', 289.99, 1, 289.99);
INSERT INTO order_items (order_item_id, order_id, product_id, product_name, unit_price, quantity, total_price) VALUES (6, 5, 22, 'Intricate 3D Multi-Layered Wooden Mandala Wall Clock', 84.99, 1, 84.99);

-- -----------------------------------------------------------------------------
-- Data: reviews (Authentic Verified Customer Testimonials)
-- -----------------------------------------------------------------------------
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (1, 1, 1, 'Elena Rostova', 5, 'Breathtaking center of our living room!', 'The backlighting on this mandala is pure magic in the evenings. The laser cuts are razor-sharp with no burnt edges, and the amber core gives an incredible warm glow. Arrived impeccably packaged.', 1, 14);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (2, 1, 3, 'Marcus Vance', 5, 'Architectural perfection', 'I am an interior designer and placed this above a client''s credenza. It looks like a high-end gallery sculpture worth triple the price. The dimmer switch is a wonderful touch.', 1, 9);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (3, 4, 2, 'David K.', 5, 'Stunning shadows across our dining table', 'The light patterns that cast across the ceiling from the heart/chevron cutouts are captivating. The birch wood smell right out of the box was delightfully fresh.', 1, 6);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (4, 5, 4, 'Claire Montgomery', 5, 'The trio set transforms our living room corner', 'Having all three sizes together on the floor creates such an atmospheric mood. Very high quality steam-bent wood.', 1, 8);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (5, 7, 5, 'Priya Sharma', 5, 'Spectacular peacock feather detail', 'The nine layers create genuine 3D relief that changes as you walk past it. Colors are deep and regal.', 1, 11);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (6, 10, 3, 'Sophia Patel', 5, 'Turned our bedroom into a 5-star sanctuary', 'Mounted this right above our king bed headboard using the French cleat. It took only 15 minutes to hang and fits perfectly flush.', 1, 18);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (7, 12, 1, 'Julian Ross', 5, 'Tree of life with soul and depth', 'The teal trunk against the bronze foliage is an inspired color palette. Everyone who visits compliments it.', 1, 7);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (8, 14, 2, 'Hanna Lindqvist', 5, 'Authentic Nordic craftsmanship', 'As someone who grew up in Sweden, this pinecone shade feels genuinely authentic. The layered birch diffuses zero glare.', 1, 12);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (9, 17, 4, 'Liam O''Connor', 5, 'MATRA HAUS delivers museum-quality lighting', 'The curved slats are parabolic perfection. The included hardware and champagne gold core are top-tier. Highly recommend!', 1, 23);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (10, 19, 5, 'Aria Tanaka', 5, 'Perfect bedside night light', 'The touch dimming is very responsive. It produces a serene glow that doesn''t hurt your eyes at night.', 1, 15);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (11, 21, 1, 'Robert Hughes', 5, 'Whisper silent and gorgeous grain', 'The walnut wood grain is rich and dark, and the quartz sweep is 100% noiseless. Exactly what our home office needed.', 1, 10);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (12, 22, 3, 'Ananya Sen', 5, 'Functional mandala art', 'Keeps accurate time, completely silent, and the 6 wood tiers make it look like a temple carving.', 1, 8);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (13, 27, 2, 'Vikram Malhotra', 5, 'The Aurora Red acrylic glow is intoxicating', 'The red acrylic fins look striking in daylight and truly mesmerizing when lit at night with the Edison bulb.', 1, 17);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (14, 28, 4, 'Samantha Reed', 5, 'A showstopper in our dining room', 'The fluted waves are massive and command the room. Packaging was sturdy and installation was straightforward.', 1, 19);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (15, 31, 3, 'Rajesh Nair', 5, 'Auspicious and beautifully carved Lord Ganesha', 'The vivid colors and delicate gold leaf work on the lotus throne are stunning. A cherished addition to our family prayer room.', 1, 25);
INSERT INTO reviews (review_id, product_id, customer_id, author_name, rating, title, content, is_verified_purchase, helpful_votes) VALUES (16, 32, 2, 'Christopher Vance', 5, 'Best topographic ocean map I have seen', 'The stepped blue depths are mesmerizing. The precision of the continental coastlines is remarkable.', 1, 21);

-- -----------------------------------------------------------------------------
-- Data: inventory_transactions (Stock Audit Entries)
-- -----------------------------------------------------------------------------
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (1, 1, 'initial_stock', 24, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (2, 2, 'initial_stock', 18, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (3, 3, 'initial_stock', 30, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (4, 4, 'initial_stock', 22, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (5, 5, 'initial_stock', 15, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (6, 6, 'initial_stock', 20, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (7, 7, 'initial_stock', 16, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (8, 8, 'initial_stock', 14, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (9, 9, 'initial_stock', 19, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (10, 10, 'initial_stock', 12, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (11, 11, 'initial_stock', 15, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (12, 12, 'initial_stock', 25, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (13, 13, 'initial_stock', 21, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (14, 14, 'initial_stock', 28, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (15, 15, 'initial_stock', 10, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (16, 16, 'initial_stock', 20, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (17, 17, 'initial_stock', 18, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (18, 18, 'initial_stock', 26, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (19, 19, 'initial_stock', 45, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (20, 20, 'initial_stock', 35, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (21, 21, 'initial_stock', 22, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (22, 22, 'initial_stock', 28, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (23, 23, 'initial_stock', 30, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (24, 24, 'initial_stock', 17, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (25, 25, 'initial_stock', 19, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (26, 26, 'initial_stock', 20, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (27, 27, 'initial_stock', 14, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (28, 28, 'initial_stock', 11, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (29, 29, 'initial_stock', 23, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (30, 30, 'initial_stock', 16, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (31, 31, 'initial_stock', 14, 'PO-2026-INIT', 'Initial catalog batch stock intake');
INSERT INTO inventory_transactions (transaction_id, product_id, transaction_type, quantity_change, reference_id, notes) VALUES (32, 32, 'initial_stock', 12, 'PO-2026-INIT', 'Initial catalog batch stock intake');

-- =============================================================================
-- SECTION 4: E-COMMERCE VIEWS (Frontend API & Optimization)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- View: vw_product_catalog (High-performance view for shop catalog grid & cards)
-- -----------------------------------------------------------------------------
CREATE VIEW vw_product_catalog AS
SELECT 
    p.product_id,
    p.legacy_code,
    p.sku,
    p.name,
    p.slug,
    c.name AS category_name,
    c.slug AS category_slug,
    b.name AS brand_name,
    p.base_price,
    p.sale_price,
    COALESCE(p.sale_price, p.base_price) AS effective_price,
    CASE WHEN p.sale_price IS NOT NULL AND p.sale_price < p.base_price THEN 1 ELSE 0 END AS on_sale,
    p.stock_quantity,
    CASE WHEN p.stock_quantity > 0 THEN 1 ELSE 0 END AS in_stock,
    p.is_featured,
    p.rating_average,
    p.rating_count,
    img.filename AS primary_image_filename,
    img.file_path AS primary_image_path,
    img.alt_text AS primary_image_alt
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN product_images img ON p.product_id = img.product_id AND img.is_primary = 1
WHERE p.is_active = 1;

-- -----------------------------------------------------------------------------
-- View: vw_product_details (Comprehensive profile view for Product Detail Pages)
-- -----------------------------------------------------------------------------
CREATE VIEW vw_product_details AS
SELECT 
    p.product_id,
    p.legacy_code,
    p.sku,
    p.name,
    p.slug,
    p.category_id,
    c.name AS category_name,
    p.brand_id,
    b.name AS brand_name,
    b.tagline AS brand_tagline,
    p.short_description,
    p.description,
    p.base_price,
    p.sale_price,
    p.cost_price,
    COALESCE(p.sale_price, p.base_price) AS current_price,
    ROUND(((p.base_price - COALESCE(p.sale_price, p.base_price)) / p.base_price) * 100, 0) AS discount_percentage,
    p.stock_quantity,
    p.low_stock_threshold,
    p.material,
    p.dimensions,
    p.weight_kg,
    p.power_source,
    p.mounting_type,
    p.assembly_required,
    p.warranty_months,
    p.is_featured,
    p.rating_average,
    p.rating_count,
    (SELECT COUNT(*) FROM product_images WHERE product_id = p.product_id) AS total_media_assets,
    (SELECT COUNT(*) FROM product_variants WHERE product_id = p.product_id AND is_active = 1) AS total_variants,
    p.created_at
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id;

-- -----------------------------------------------------------------------------
-- View: vw_featured_products (Homepage showcase carousel)
-- -----------------------------------------------------------------------------
CREATE VIEW vw_featured_products AS
SELECT 
    product_id,
    legacy_code,
    sku,
    name,
    slug,
    category_name,
    brand_name,
    base_price,
    sale_price,
    effective_price,
    on_sale,
    rating_average,
    rating_count,
    primary_image_filename,
    primary_image_path,
    primary_image_alt
FROM vw_product_catalog
WHERE is_featured = 1;

-- -----------------------------------------------------------------------------
-- View: vw_category_summary (Category tree metrics & price ranges)
-- -----------------------------------------------------------------------------
CREATE VIEW vw_category_summary AS
SELECT 
    c.category_id,
    c.name AS category_name,
    c.slug AS category_slug,
    COUNT(p.product_id) AS product_count,
    MIN(COALESCE(p.sale_price, p.base_price)) AS min_price,
    MAX(COALESCE(p.sale_price, p.base_price)) AS max_price,
    AVG(p.rating_average) AS avg_category_rating
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id AND p.is_active = 1
GROUP BY c.category_id, c.name, c.slug;

-- =============================================================================
-- SECTION 5: RECOMMENDED INDEXES FOR PRODUCTION QUERY OPTIMIZATION
-- =============================================================================

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_featured ON products(is_featured, is_active);
CREATE INDEX idx_product_images_pid ON product_images(product_id, is_primary);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_variants_product ON product_variants(product_id);

-- =============================================================================
-- SECTION 6: SAMPLE FRONTEND & BACKEND QUERIES
-- =============================================================================

-- Query 1: Fetch all products for shop catalog grid (with primary image & category)
-- SELECT * FROM vw_product_catalog ORDER BY is_featured DESC, rating_average DESC;

-- Query 2: Fetch full product details including image gallery
-- SELECT * FROM vw_product_details WHERE legacy_code = 'P01';
-- SELECT * FROM product_images WHERE product_id = 1 ORDER BY sort_order ASC;

-- Query 3: Search products by tag (e.g. 'Backlit LED' or 'Mandala')
-- SELECT p.name, p.base_price, t.name AS tag_name
-- FROM products p
-- JOIN product_tags pt ON p.product_id = pt.product_id
-- JOIN tags t ON pt.tag_id = t.tag_id
-- WHERE t.slug = 'mandala';

-- Query 4: Check low stock alerts
-- SELECT sku, name, stock_quantity, low_stock_threshold 
-- FROM products 
-- WHERE stock_quantity <= low_stock_threshold;
