// src/pages/api/auth/register.ts
// Member registration with PBKDF2 password hashing
import type { APIRoute } from 'astro';
import { getDB, run, one } from '../../../lib/db';
import { hashPassword, createSession, buildSessionCookie } from '../../../lib/auth';
import { isValidEmail, isValidIndianPhone } from '../../../lib/validate';

export const POST: APIRoute = async ({ request, cookies, locals }) => {
  try {
    const body = await request.json();
    const firstName = body?.first_name?.trim();
    const lastName = body?.last_name?.trim();
    const email = body?.email?.trim().toLowerCase();
    const phone = body?.phone?.trim();
    const password = body?.password;

    if (!firstName || !lastName) {
      return new Response(JSON.stringify({ error: 'First name and last name are required.' }), { status: 400 });
    }
    if (!email || !isValidEmail(email)) {
      return new Response(JSON.stringify({ error: 'Please enter a valid email address.' }), { status: 400 });
    }
    if (!password || password.length < 8) {
      return new Response(JSON.stringify({ error: 'Password must be at least 8 characters in length.' }), { status: 400 });
    }
    if (phone && !isValidIndianPhone(phone)) {
      return new Response(JSON.stringify({ error: 'Please enter a valid 10-digit Indian phone number.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service is unavailable.' }), { status: 503 });
    }

    const db = getDB(env);

    // Check if email already registered
    const existing = await one<{ id: number }>(db, `SELECT id FROM users WHERE email = ?`, [email]);
    if (existing) {
      return new Response(JSON.stringify({ error: 'An account with this email address already exists. Please log in.' }), { status: 409 });
    }

    // Hash password with PBKDF2-SHA256 and unique salt
    const { hash, salt } = await hashPassword(password);

    const insertResult = await run(
      db,
      `INSERT INTO users (first_name, last_name, email, phone, password_hash, password_salt, role)
       VALUES (?, ?, ?, ?, ?, ?, 'member')`,
      [firstName, lastName, email, phone || null, hash, salt]
    );

    const newUserId = insertResult.meta.last_row_id;

    // Create session and set cookie
    const token = await createSession(db, newUserId, cookies);

    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const cookieHeader = buildSessionCookie(token, expiresAt, false);

    const headers = new Headers();
    headers.set('Content-Type', 'application/json');
    headers.append('Set-Cookie', cookieHeader);

    const customRedirect = body?.redirect;
    let redirectUrl = '/account';
    if (customRedirect && typeof customRedirect === 'string' && customRedirect.startsWith('/') && !customRedirect.startsWith('//')) {
      redirectUrl = customRedirect;
    }

    return new Response(JSON.stringify({
      success: true,
      redirect: redirectUrl,
      user: {
        id: newUserId,
        first_name: firstName,
        last_name: lastName,
        email,
        role: 'member',
      },
    }), {
      status: 201,
      headers,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Registration failed.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
