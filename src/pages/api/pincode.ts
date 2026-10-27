// src/pages/api/pincode.ts
// Validates 6-digit Indian PIN code and calculates regional delivery estimate
import type { APIRoute } from 'astro';

// Major Indian Postal Circles lookup by 1st and 2nd digits
const POSTAL_REGIONS: Record<string, { state: string; metroCity: string; days: string }> = {
  '11': { state: 'Delhi', metroCity: 'New Delhi', days: '3-4' },
  '12': { state: 'Haryana', metroCity: 'Gurugram / Faridabad', days: '3-5' },
  '13': { state: 'Haryana', metroCity: 'Ambala / Panipat', days: '4-5' },
  '14': { state: 'Punjab', metroCity: 'Ludhiana / Jalandhar', days: '4-6' },
  '16': { state: 'Chandigarh', metroCity: 'Chandigarh', days: '3-5' },
  '20': { state: 'Uttar Pradesh', metroCity: 'Noida / Ghaziabad', days: '3-4' },
  '22': { state: 'Uttar Pradesh', metroCity: 'Lucknow', days: '4-6' },
  '30': { state: 'Rajasthan', metroCity: 'Jaipur', days: '4-5' },
  '38': { state: 'Gujarat', metroCity: 'Ahmedabad', days: '4-5' },
  '39': { state: 'Gujarat', metroCity: 'Surat / Vadodara', days: '4-5' },
  '40': { state: 'Maharashtra', metroCity: 'Mumbai', days: '3-4' },
  '41': { state: 'Maharashtra', metroCity: 'Pune', days: '3-5' },
  '44': { state: 'Maharashtra', metroCity: 'Nagpur', days: '4-6' },
  '45': { state: 'Madhya Pradesh', metroCity: 'Indore', days: '4-5' },
  '50': { state: 'Telangana', metroCity: 'Hyderabad', days: '3-5' },
  '56': { state: 'Karnataka', metroCity: 'Bengaluru', days: '3-4' },
  '57': { state: 'Karnataka', metroCity: 'Mangalore / Mysore', days: '4-6' },
  '60': { state: 'Tamil Nadu', metroCity: 'Chennai', days: '3-5' },
  '64': { state: 'Tamil Nadu', metroCity: 'Coimbatore', days: '4-6' },
  '68': { state: 'Kerala', metroCity: 'Kochi', days: '4-6' },
  '69': { state: 'Kerala', metroCity: 'Thiruvananthapuram', days: '4-6' },
  '70': { state: 'West Bengal', metroCity: 'Kolkata', days: '4-6' },
  '80': { state: 'Bihar', metroCity: 'Patna', days: '5-7' },
};

export const GET: APIRoute = async ({ url }) => {
  const pin = url.searchParams.get('pin')?.trim();

  if (!pin || !/^[1-9][0-9]{5}$/.test(pin)) {
    return new Response(JSON.stringify({
      serviceable: false,
      message: 'Please provide a valid 6-digit Indian PIN code (digits 1-9 followed by 5 numbers).'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const prefix = pin.substring(0, 2);
  const region = POSTAL_REGIONS[prefix] || { state: 'India', metroCity: 'Direct Delivery Area', days: '5-7' };

  return new Response(JSON.stringify({
    serviceable: true,
    pincode: pin,
    city: region.metroCity,
    state: region.state,
    delivery_days: region.days,
    cod_available: true,
    express_available: true,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
};
