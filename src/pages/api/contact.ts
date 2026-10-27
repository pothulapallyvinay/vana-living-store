// src/pages/api/contact.ts
import type { APIRoute } from 'astro';
import { getDB, run } from '../../lib/db';
import { isValidEmail, isValidIndianPhone } from '../../lib/validate';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const name = body?.name?.trim();
    const email = body?.email?.trim().toLowerCase();
    const phone = body?.phone?.trim();
    const subject = body?.subject?.trim() || 'General Enquiry';
    const message = body?.message?.trim();

    if (!name || !message) {
      return new Response(JSON.stringify({ error: 'Name and message are required.' }), { status: 400 });
    }
    if (!email || !isValidEmail(email)) {
      return new Response(JSON.stringify({ error: 'A valid email address is required.' }), { status: 400 });
    }
    if (phone && !isValidIndianPhone(phone)) {
      return new Response(JSON.stringify({ error: 'Please enter a valid 10-digit Indian phone number.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    if (env?.DB) {
      const db = getDB(env);
      await run(
        db,
        `INSERT INTO contact_messages (name, email, phone, subject, message)
         VALUES (?, ?, ?, ?, ?)`,
        [name, email, phone || null, subject, message]
      );
    }

    return new Response(JSON.stringify({
      success: true,
      message: 'Thank you for reaching out. Our artisan team will reply within 24 business hours.'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: 'Failed to record message.' }), { status: 500 });
  }
};
