"""
Comprehensive fix script for the homedecor-store:
1. Update all product_media paths to include /media/ prefix
2. Add medium-level pricing (in paise) to all product_variants
3. Add short_description & description to all products
"""
import sqlite3
import glob
import os

DB_FILES = glob.glob(r'.wrangler\state\v3\d1\**\*.sqlite', recursive=True)
if not DB_FILES:
    print("ERROR: No local D1 SQLite file found. Run 'npx wrangler d1 migrations apply DB --local' first.")
    exit(1)

db_path = DB_FILES[0]
print(f"Using database: {db_path}")

con = sqlite3.connect(db_path)
cur = con.cursor()

# ─────────────────────────────────────────
# 1. Fix media paths: ensure they start with /media/
# ─────────────────────────────────────────
print("\n=== Fixing product_media paths ===")
cur.execute("SELECT id, path FROM product_media")
rows = cur.fetchall()
fixed_media = 0
for row in rows:
    mid, path = row
    if not path.startswith('/media/'):
        new_path = f'/media/{path}' if not path.startswith('/') else f'/media{path}'
        cur.execute("UPDATE product_media SET path = ? WHERE id = ?", (new_path, mid))
        fixed_media += 1
print(f"  Fixed {fixed_media} media paths (out of {len(rows)} total)")

# ─────────────────────────────────────────
# 2. Add pricing to all product_variants
# ─────────────────────────────────────────
print("\n=== Adding demo pricing ===")

# Medium-tier pricing per product (in INR rupees), will be stored as paise
PRODUCT_PRICES = {
    'P01': {'price': 4999, 'compare': 5999, 'size': '60cm × 60cm'},
    'P02': {'price': 3499, 'compare': 4499, 'size': '45cm × 45cm'},
    'P03': {'price': 2999, 'compare': 3799, 'size': '40cm × 40cm'},
    'P04': {'price': 6499, 'compare': 7999, 'size': '45cm dia × 55cm H'},
    'P05': {'price': 4499, 'compare': 5499, 'size': 'Set of 3 – 25cm H each'},
    'P06': {'price': 3999, 'compare': 4999, 'size': '50cm × 50cm'},
    'P07': {'price': 5499, 'compare': 6999, 'size': '55cm × 45cm'},
    'P08': {'price': 4299, 'compare': 5299, 'size': '45cm × 35cm'},
    'P09': {'price': 5999, 'compare': 7499, 'size': '75cm × 38cm'},
    'P10': {'price': 7999, 'compare': 9999, 'size': '120cm × 60cm'},
    'P11': {'price': 4499, 'compare': 5499, 'size': '60cm dia'},
    'P12': {'price': 4799, 'compare': 5999, 'size': '55cm dia'},
    'P13': {'price': 3999, 'compare': 4999, 'size': '50cm dia'},
    'P14': {'price': 5999, 'compare': 7499, 'size': '40cm dia × 50cm H'},
    'P15': {'price': 8999, 'compare': 10999, 'size': '40cm dia × 150cm H'},
    'P16': {'price': 5999, 'compare': 7499, 'size': '40cm dia × 50cm H'},
    'P17': {'price': 7499, 'compare': 8999, 'size': '50cm dia × 30cm H'},
    'P18': {'price': 3499, 'compare': 4499, 'size': '40cm × 50cm'},
    'P19': {'price': 1999, 'compare': 2499, 'size': '20cm × 15cm × 12cm'},
    'P20': {'price': 2499, 'compare': 2999, 'size': '15cm dia × 8cm'},
    'P21': {'price': 3299, 'compare': 3999, 'size': '40cm × 35cm'},
    'P22': {'price': 3999, 'compare': 4799, 'size': '45cm dia'},
    'P23': {'price': 3499, 'compare': 4299, 'size': '40cm dia'},
    'P24': {'price': 3299, 'compare': 3999, 'size': '40cm × 50cm'},
    'P25': {'price': 5999, 'compare': 7499, 'size': '55cm × 45cm'},
    'P26': {'price': 3999, 'compare': 4999, 'size': '50cm dia'},
    'P27': {'price': 8499, 'compare': 9999, 'size': '45cm dia × 35cm H'},
    'P28': {'price': 7999, 'compare': 9499, 'size': '50cm dia × 28cm H'},
    'P29': {'price': 4499, 'compare': 5499, 'size': '50cm × 40cm'},
    'P30': {'price': 3999, 'compare': 4999, 'size': '55cm dia'},
    'P31': {'price': 4999, 'compare': 6499, 'size': '55cm × 55cm'},
    'P32': {'price': 8999, 'compare': 10999, 'size': '90cm × 60cm'},
}

updated_prices = 0
for pid, info in PRODUCT_PRICES.items():
    price_paise = info['price'] * 100
    compare_paise = info['compare'] * 100
    size_label = info['size']
    cur.execute(
        "UPDATE product_variants SET price_paise = ?, compare_at_paise = ?, size_label = ? WHERE product_id = ?",
        (price_paise, compare_paise, size_label, pid)
    )
    updated_prices += cur.rowcount

print(f"  Updated pricing for {updated_prices} variants")

# ─────────────────────────────────────────
# 3. Add descriptions to all products
# ─────────────────────────────────────────
print("\n=== Adding product descriptions ===")

DESCRIPTIONS = {
    'P01': {
        'short': 'Handcrafted 3D multi-layered birch mandala wall sculpture with warm backlit LED illumination.',
        'desc': 'Stacking up to 9 distinct architectural wood tiers, each concentric circle is precision laser-cut from high-grade natural birch ply. Hand-glued, finished with organic botanical oils, and illuminated by a hidden warm white 3000K LED glow. A mesmerising centrepiece for living rooms, bedrooms and meditation spaces.',
    },
    'P02': {
        'short': 'Three abstract cubist faces layered in natural birch tones with a sleek framed border.',
        'desc': 'This abstract three-faces relief artwork draws on cubist traditions, featuring overlapping profiles laser-cut from premium Baltic birch plywood. Each face is individually layered and hand-finished with tinted botanical oils, creating subtle depth and shadow play. Presented in a precision-cut wooden frame.',
    },
    'P03': {
        'short': 'Elegant feminine profile silhouette in multi-layered natural birch with fine botanical detail.',
        'desc': 'A striking feminine profile with flowing botanical hair elements, precision laser-cut across multiple birch plywood layers. The dimensional relief creates captivating shadow interplay under ambient lighting. Finished with hand-applied natural oils for a warm, organic lustre.',
    },
    'P04': {
        'short': 'Geometric artichoke-inspired pendant lamp shade crafted from interlocking wooden leaf petals.',
        'desc': 'Inspired by Scandinavian design philosophy, this architectural pendant lamp features dozens of precision-cut wooden leaf petals arranged in an artichoke formation. When illuminated, it casts stunning geometric shadow patterns across walls and ceilings. Compatible with standard E27/B22 bulb holders.',
    },
    'P05': {
        'short': 'Set of three curved wooden slat lantern-style table lamps with warm ambient glow.',
        'desc': 'A trio of elegantly curved wooden slat lanterns in three graduated heights. Each lamp features meticulously bent birch slats that filter warm light through organic gaps, creating a campfire-like ambience. Perfect for bedside tables, console tables, and living room corners.',
    },
    'P06': {
        'short': 'Intricate filigree floral mandala wall art framed in natural birch with botanical lace patterns.',
        'desc': 'This exquisite floral mandala features ultra-fine laser-cut filigree patterns reminiscent of vintage botanical lace. Multiple layers of natural birch plywood create extraordinary depth and shadow detail. Presented in a precision-cut matching frame for a gallery-ready presentation.',
    },
    'P07': {
        'short': 'Majestic peacock with fanned tail feathers in multi-layered coloured wooden relief art.',
        'desc': 'A regal Indian peacock brought to life through 7+ precision-cut layers of birch plywood. Each feather is individually shaped and hand-painted with botanical dyes in vibrant jewel tones. The dimensional layering creates mesmerising depth that changes with ambient light angles.',
    },
    'P08': {
        'short': 'Intense tiger eyes portrait in layered natural birch with dramatic depth and shadow play.',
        'desc': 'This powerful tiger portrait captures the intensity of the Bengal tiger through multi-layered precision-cut birch relief. The dimensional layering around the eyes creates dramatic shadow depth, bringing the portrait to life under changing light conditions. Finished with natural oils.',
    },
    'P09': {
        'short': 'Semi-circular peacock tail fan wall art with intricate feather layers in natural birch.',
        'desc': 'An elegant half-moon peacock tail fan featuring dozens of individually cut feather elements arranged in a dramatic fan formation. Each tier is precision laser-cut from natural birch plywood, creating extraordinary dimensional depth. A stunning statement piece for above sofas or mantlepieces.',
    },
    'P10': {
        'short': 'Grand semi-circular mandala headboard art with intricate concentric patterns in natural birch.',
        'desc': 'A majestic architectural headboard piece featuring an elaborate semi-circular mandala spanning 120cm. Multiple concentric birch layers create extraordinary depth and shadow interplay. Designed to mount behind beds as a statement headboard alternative, transforming any bedroom into a sanctuary.',
    },
    'P11': {
        'short': 'Full circular mandala wall art with precision-cut concentric geometric patterns.',
        'desc': 'A perfectly balanced full-circle mandala featuring intricate concentric geometric patterns laser-cut from premium Baltic birch plywood. Each of the 8 distinct layers creates progressive depth, casting mesmerising shadows that evolve throughout the day with natural light changes.',
    },
    'P12': {
        'short': 'Sacred Tree of Life circular wall art with intertwining branches in dimensional birch layers.',
        'desc': 'The universal symbol of growth and interconnectedness, realised through precision laser-cut birch plywood layers. Intertwining branches extend from a central trunk, with delicate leaf details on the outermost tier. A meaningful piece that adds natural warmth and philosophical depth to any room.',
    },
    'P13': {
        'short': 'Lotus flower mandala wall art with petal layers radiating from a sacred geometric centre.',
        'desc': 'This sacred lotus mandala combines floral petal forms with geometric sacred geometry patterns. Multiple birch plywood layers create a blooming three-dimensional effect, with each petal tier casting progressive shadows. Ideal for meditation rooms, pooja spaces, and yoga studios.',
    },
    'P14': {
        'short': 'Scandinavian wooden pinecone pendant lamp in natural birch finish with warm light diffusion.',
        'desc': 'A classic Scandinavian design icon, this pinecone pendant lamp features overlapping wooden scales arranged in a natural pinecone formation. The natural birch finish catches warm light beautifully, creating a cosy Nordic ambience. Includes ceiling rose, adjustable cord, and E27 bulb holder.',
    },
    'P15': {
        'short': 'Freestanding pinecone floor lamp in natural birch with industrial tripod base.',
        'desc': 'A commanding floor-standing version of the iconic Scandinavian pinecone design. Standing 150cm tall on a sleek industrial black tripod base, this lamp makes a bold statement in living rooms and reading nooks. The wooden pinecone shade diffuses warm light through organic gaps.',
    },
    'P16': {
        'short': 'Scandinavian pinecone pendant lamp in sophisticated charcoal grey with matte finish.',
        'desc': 'The iconic pinecone pendant reimagined in a contemporary charcoal grey matte finish. Each wooden scale is individually stained and sealed, creating a modern moody aesthetic that pairs beautifully with dark accent walls and industrial-chic interiors.',
    },
    'P17': {
        'short': 'MATRA HAUS signature curved birch slat pendant lamp with organic flowing form.',
        'desc': 'From the MATRA HAUS design studio, this signature pendant features dozens of precision-bent birch slats arranged in a fluid, organic dome formation. The rhythmic gaps between slats create stunning linear shadow patterns across ceilings. A contemporary architectural lighting sculpture.',
    },
    'P18': {
        'short': 'Tender mother and child silhouette in multi-layered natural birch wall art plaque.',
        'desc': 'A deeply emotive portrayal of maternal love through precision-cut birch plywood layers. The intertwined silhouettes of mother and child create gentle dimensional depth, with soft shadow interplay that evokes warmth and tenderness. A meaningful gift and nursery accent piece.',
    },
    'P19': {
        'short': 'Delicate lotus flower LED night light in edge-lit acrylic with natural wood base.',
        'desc': 'A serene lotus bloom laser-engraved into premium clear acrylic, mounted on a hand-finished natural wood base with integrated warm white LED illumination. The edge-lit technique creates a magical floating glow effect. Touch-activated with 3 brightness levels. USB-C powered.',
    },
    'P20': {
        'short': 'Minimalist round desk clock with concentric layered birch face and silent quartz movement.',
        'desc': 'A compact circular desk timepiece featuring concentric birch plywood layers creating subtle topographic depth on the clock face. Fitted with a premium German silent-sweep quartz movement for zero ticking noise. Includes a natural wood easel stand. Battery-powered (1× AA).',
    },
    'P21': {
        'short': 'Bold asymmetric wall clock in natural walnut with multi-layered 3D geometric design.',
        'desc': 'This striking asymmetric timepiece breaks from traditional circular clock forms. Featuring overlapping geometric walnut plywood layers at dynamic angles, it functions as both a reliable wall clock and a sculptural art piece. Premium German silent-sweep quartz movement included.',
    },
    'P22': {
        'short': 'Ornate mandala wall clock with intricate concentric patterns in natural birch and walnut.',
        'desc': 'Where sacred geometry meets functional timekeeping. This mandala wall clock features multiple concentric layers of laser-cut filigree patterns in contrasting birch and walnut tones. The German silent-sweep quartz movement ensures peaceful silence. A stunning fusion of art and utility.',
    },
    'P23': {
        'short': 'Modern topographic contour wall clock with 3D layered terrain effect in natural birch.',
        'desc': 'Inspired by cartographic contour maps, this contemporary wall clock features stacked birch plywood layers cut to varying elevation contours. The result is a mesmerising three-dimensional terrain effect with dramatic shadow depth. German silent-sweep quartz movement. Battery-powered.',
    },
    'P24': {
        'short': 'Pop-art inspired woman portrait with bold red lips in multi-layered coloured birch.',
        'desc': 'A vibrant pop-art portrait featuring a striking feminine face with bold crimson lips, realised through precision-cut coloured birch plywood layers. The contrast between natural wood tones and vivid colour creates a contemporary gallery statement. Hand-finished with archival sealant.',
    },
    'P25': {
        'short': 'Japanese koi fish shadow box wall art with layered underwater scene in natural birch.',
        'desc': 'Two majestic koi fish swim through layered waves in this stunning shadow box composition. Multiple tiers of precision-cut birch plywood create extraordinary three-dimensional depth within a sleek black frame. Inspired by traditional Japanese art, reimagined in contemporary dimensional wood craft.',
    },
    'P26': {
        'short': 'Circular peacock feather wall art plaque with iridescent-inspired layered birch detail.',
        'desc': 'A single magnificent peacock feather rendered in extraordinary multi-layered birch detail within a circular frame. Each barb and barbule is individually cut and hand-finished with tinted botanical oils that evoke the natural iridescence of peacock plumage. A compact yet dramatic wall accent.',
    },
    'P27': {
        'short': 'MATRA HAUS Aurora pendant lamp with flowing red acrylic ribs and warm ambient diffusion.',
        'desc': 'From the MATRA HAUS studio, the Aurora pendant features gracefully curved translucent red acrylic ribs arranged in a flowing organic dome. When illuminated, the lamp bathes rooms in a warm, sunset-like ambient glow while casting dramatic linear shadows. A bold architectural statement.',
    },
    'P28': {
        'short': 'MATRA HAUS organic fluted wave pendant light in natural birch with rhythmic slat pattern.',
        'desc': 'The Fluted Wave pendant from MATRA HAUS features precisely steam-bent birch slats arranged in an undulating wave formation. The organic gaps between slats create mesmerising parallel shadow lines across ceilings and walls. Includes adjustable cord and E27/B22 bulb holder.',
    },
    'P29': {
        'short': 'Tree of Life filigree relief artwork framed in natural birch with ultra-fine laser detail.',
        'desc': 'An extraordinarily detailed Tree of Life rendered in ultra-fine laser-cut filigree across multiple birch plywood layers. Every branch, leaf, and root is individually articulated with watchmaker-level precision. Presented in a matching birch frame for gallery-quality wall display.',
    },
    'P30': {
        'short': 'Sacred Om (Aum) symbol with lotus petals in multi-layered devotional mandala wall art.',
        'desc': 'The sacred Om (Aum) symbol at the heart of a blooming lotus mandala, crafted from multiple precision-cut birch plywood layers. Each petal and sacred geometry element creates progressive dimensional depth. Designed for pooja rooms, meditation spaces, and spiritual corners of the home.',
    },
    'P31': {
        'short': 'Lord Ganesha seated on a lotus throne in vibrant multi-layered coloured wooden wall art.',
        'desc': 'Lord Ganesha, the remover of obstacles, depicted seated on an ornate lotus throne. This devotional wall art features 8+ precision-cut layers of birch plywood, each hand-painted in vibrant traditional colours. Ideal for pooja rooms, entrances, and as an auspicious housewarming gift.',
    },
    'P32': {
        'short': 'World map with topographic ocean depth relief in multi-layered birch and blue tones.',
        'desc': 'A stunning bathymetric world map featuring continental landmasses in natural walnut against ocean depths rendered in graduated blue-tinted birch layers. Each oceanic depth contour is individually cut and stacked, creating a mesmerising three-dimensional relief. Framed in precision-cut black birch.',
    },
}

updated_desc = 0
for pid, info in DESCRIPTIONS.items():
    cur.execute(
        "UPDATE products SET short_description = ?, description = ? WHERE id = ?",
        (info['short'], info['desc'], pid)
    )
    updated_desc += cur.rowcount

print(f"  Updated descriptions for {updated_desc} products")

# ─────────────────────────────────────────
# 4. Verify final state
# ─────────────────────────────────────────
con.commit()

cur.execute("SELECT COUNT(*) FROM product_media WHERE path LIKE '/media/%'")
media_ok = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM product_media")
media_total = cur.fetchone()[0]
print(f"\n=== Verification ===")
print(f"  Media paths with /media/ prefix: {media_ok}/{media_total}")

cur.execute("SELECT COUNT(*) FROM product_variants WHERE price_paise IS NOT NULL AND price_paise > 0")
priced = cur.fetchone()[0]
cur.execute("SELECT COUNT(*) FROM product_variants")
total_v = cur.fetchone()[0]
print(f"  Priced variants: {priced}/{total_v}")

cur.execute("SELECT COUNT(*) FROM products WHERE short_description IS NOT NULL AND short_description != ''")
described = cur.fetchone()[0]
print(f"  Products with descriptions: {described}/32")

# Show a sample
cur.execute("""
    SELECT p.id, p.name, v.price_paise, v.compare_at_paise, v.size_label, m.path
    FROM products p
    LEFT JOIN product_variants v ON v.product_id = p.id AND v.is_default = 1
    LEFT JOIN product_media m ON m.product_id = p.id AND m.is_primary = 1
    LIMIT 5
""")
print(f"\n=== Sample Output ===")
for row in cur.fetchall():
    price_inr = f"₹{row[2]//100:,}" if row[2] else "N/A"
    compare_inr = f"₹{row[3]//100:,}" if row[3] else ""
    print(f"  {row[0]}: {row[1][:50]}... | {price_inr} (was {compare_inr}) | Size: {row[4]} | Img: {row[5]}")

con.close()
print("\n✅ All fixes applied successfully!")
