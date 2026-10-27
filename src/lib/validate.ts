// src/lib/validate.ts
// Input validation helpers

/** Validate Indian 10-digit mobile number */
export function isValidIndianPhone(phone: string): boolean {
  return /^[6-9]\d{9}$/.test(phone.replace(/\s|\+91|-/g, ''));
}

/** Validate email address */
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

/** Validate Indian 6-digit pincode */
export function isValidPincode(pin: string): boolean {
  return /^\d{6}$/.test(pin.trim());
}
export const isValidIndianPincode = isValidPincode;

/** Validate GSTIN format */
export function isValidGSTIN(gstin: string): boolean {
  return /^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$/.test(gstin);
}

/** Sanitize string — trim and remove dangerous HTML */
export function sanitize(str: string): string {
  return str.trim().replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/** Check password strength — min 8 chars */
export function isStrongPassword(pw: string): boolean {
  return pw.length >= 8;
}

/** List of Indian states and UTs */
export const INDIAN_STATES = [
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];
