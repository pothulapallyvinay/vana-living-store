// Site configuration — replace placeholders before going live
// All secrets (Razorpay keys, webhook secret) live in Cloudflare environment
// variables, NEVER here.

export const site = {
  name: 'Vana Living',
  tagline: 'Artisan Woodcraft & Architectural Lighting',
  domain: 'vanaliving.in',
  url: 'http://localhost:4321',
  mediaBase: '/media',
  whatsapp: '919876543210',
  supportEmail: 'concierge@vanaliving.in',
  gstin: '29ABCDE1234F1Z5',
  instagram: 'https://instagram.com/vanaliving',
  facebook: 'https://facebook.com/vanaliving',
  youtube: 'https://youtube.com/@vanaliving',
  pinterest: 'https://pinterest.com/vanaliving',
};

export const shipping = {
  freeAbovePaise: 99900,        // ₹999 — free shipping threshold
  flatRatePaise: 8900,          // ₹89 flat shipping
  codLimitPaise: 5000000,       // ₹50,000 — full Cash on Delivery threshold
  codWithAdvanceLimitPaise: 10000000, // ₹1,00,000 — COD with advance threshold
  advancePercent: 30,           // % of total paid online for COD+advance
  codEnabled: true,
  estimatedDispatchDays: 3,     // business days to dispatch
  estimatedDeliveryDays: 7,     // business days to deliver
};

export const nav = {
  wallArt: [
    { label: 'Mandala Wall Art', slug: 'mandala-wall-art' },
    { label: 'Nature & Wildlife', slug: 'nature-wildlife' },
    { label: 'Figures & Portraits', slug: 'figures-portraits' },
    { label: 'Spiritual & Devotional', slug: 'spiritual-devotional' },
    { label: 'Maps & Abstract', slug: 'maps-abstract' },
  ],
  lighting: [
    { label: 'Pendant Lamps', slug: 'pendant-lamps' },
    { label: 'Table & Floor Lamps', slug: 'table-floor-lamps' },
    { label: 'Night Lights', slug: 'night-lights' },
  ],
  clocks: [
    { label: 'Wall Clocks', slug: 'wall-clocks' },
    { label: 'Desk Clocks', slug: 'desk-clocks' },
  ],
  spaces: [
    { label: 'Living Room', slug: 'living-room' },
    { label: 'Bedroom', slug: 'bedroom' },
    { label: 'Pooja Room', slug: 'pooja-room' },
    { label: 'Entrance & Hallway', slug: 'entrance-hallway' },
    { label: 'Office', slug: 'office' },
    { label: 'Gifting', slug: 'gifting' },
  ],
  priceBands: [
    { label: 'Under ₹2,000', slug: 'under-2000', max: 200000 },
    { label: '₹2,000 – ₹5,000', slug: '2000-5000', min: 200000, max: 500000 },
    { label: '₹5,000 – ₹10,000', slug: '5000-10000', min: 500000, max: 1000000 },
    { label: 'Above ₹10,000', slug: 'above-10000', min: 1000000 },
  ],
};

export const trustStrip = [
  { icon: '🪵', text: 'Handcrafted in India' },
  { icon: '📦', text: 'Damage-free packaging' },
  { icon: '🚚', text: `Ships in ${shipping.estimatedDispatchDays} days` },
  { icon: '🔒', text: 'Secure payments by Razorpay' },
  { icon: '↩️', text: 'Easy returns' },
];

export const seo = {
  defaultTitle: 'Vana Living | Handcrafted 3D Wooden Wall Art, Lamps & Clocks',
  defaultDescription:
    'Shop premium handcrafted 3D multi-layered wooden wall art, designer lamps and artisan clocks. Made in India. Free shipping above ₹999.',
  twitterHandle: '@vanaliving',
};
