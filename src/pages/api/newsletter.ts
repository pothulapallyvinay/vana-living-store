// src/pages/api/newsletter.ts
import type { APIRoute } from 'astro';
import { getDB, run } from '../../lib/db';
import { isValidEmail } from '../../lib/validate';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const email = body?.email?.trim().toLowerCase();

    if (!email || !isValidEmail(email)) {
      return new Response(JSON.stringify({ error: 'Please enter a valid email address.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    if (env?.DB) {
      const db = getDB(env);
      await run(
        db,
        `INSERT OR IGNORE INTO newsletter_subscribers (email) VALUES (?)`,
        [email]
      );
    }

    return new Response(JSON.stringify({ success: true, message: 'Subscribed successfully.' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: 'Subscription failed.' }), { status: 500 });
  }
};
