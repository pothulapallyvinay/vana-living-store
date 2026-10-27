// src/pages/api/auth/login.ts
// User sign-in with PBKDF2 verification and secure session cookies
import type { APIRoute } from 'astro';
import { getDB, one } from '../../../lib/db';
import { verifyPassword, createSession, buildSessionCookie } from '../../../lib/auth';
import { isValidEmail } from '../../../lib/validate';

export const POST: APIRoute = async ({ request, cookies, locals }) => {
  try {
    const body = await request.json();
    const email = body?.email?.trim().toLowerCase();
    const password = body?.password;

    if (!email || !isValidEmail(email)) {
      return new Response(JSON.stringify({ error: 'Please enter a valid email address.' }), { status: 400 });
    }
    if (!password) {
      return new Response(JSON.stringify({ error: 'Password is required.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    if (!env?.DB) {
      return new Response(JSON.stringify({ error: 'Database service is unavailable.' }), { status: 503 });
    }

    const db = getDB(env);
    const user = await one<{
      id: number;
      first_name: string;
      last_name: string;
      email: string;
      password_hash: string;
      password_salt: string;
      role: string;
      force_pw_change: number;
    }>(db, `SELECT * FROM users WHERE email = ?`, [email]);

    if (!user) {
      return new Response(JSON.stringify({ error: 'Invalid email or password.' }), { status: 401 });
    }

    const passwordOk = await verifyPassword(password, user.password_hash, user.password_salt);
    if (!passwordOk) {
      return new Response(JSON.stringify({ error: 'Invalid email or password.' }), { status: 401 });
    }

    // Create session and set HttpOnly session cookie
    const token = await createSession(db, user.id, cookies);

    // Determine redirect destination
    const customRedirect = body?.redirect;
    let redirectUrl = user.role === 'admin' || user.role === 'super_admin' ? '/admin' : '/account';
    if (customRedirect && typeof customRedirect === 'string' && customRedirect.startsWith('/') && !customRedirect.startsWith('//')) {
      if (user.role === 'admin' || user.role === 'super_admin') {
        redirectUrl = customRedirect.startsWith('/admin') ? customRedirect : '/admin';
      } else {
        redirectUrl = customRedirect;
      }
    }

    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const cookieHeader = buildSessionCookie(token, expiresAt, false);

    const headers = new Headers();
    headers.set('Content-Type', 'application/json');
    headers.append('Set-Cookie', cookieHeader);

    return new Response(JSON.stringify({
      success: true,
      redirect: redirectUrl,
      force_pw_change: user.force_pw_change === 1,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        role: user.role,
      },
    }), {
      status: 200,
      headers,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Authentication error.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
