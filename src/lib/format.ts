// src/lib/format.ts
// Money and display formatting utilities

/** Format paise as INR string, e.g. 189900 → "₹1,899" */
export function formatPrice(paise: number): string {
  const rupees = Math.floor(paise / 100);
  return `₹${rupees.toLocaleString('en-IN')}`;
}

/** Format paise as decimal string, e.g. 189900 → "₹1,899.00" */
export function formatPriceDecimal(paise: number): string {
  const rupees = paise / 100;
  return `₹${rupees.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/** Convert rupees string/number to paise integer */
export function rupeesToPaise(rupees: number | string): number {
  return Math.round(Number(rupees) * 100);
}

/** Percent discount between two paise amounts */
export function discountPercent(original: number, sale: number): number {
  if (!original || original <= sale) return 0;
  return Math.round(((original - sale) / original) * 100);
}

/** Truncate text to maxLength with ellipsis */
export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return str.slice(0, maxLength - 1) + '…';
}

/** Format date string to readable form */
export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

/** Pad number to 2 digits */
export function pad2(n: number): string {
  return String(n).padStart(2, '0');
}
