// src/pages/api/auth/logout.ts
import type { APIRoute } from 'astro';
import { getDB } from '../../../lib/db';
import { destroySession, clearSessionCookie } from '../../../lib/auth';

export const POST: APIRoute = async ({ cookies, locals }) => {
  try {
    const env = (locals as any).runtime?.env || (process.env as any);
    if (env?.DB) {
      const db = getDB(env);
      await destroySession(db, cookies);
    } else {
      cookies.delete('sid', { path: '/' });
    }

    const headers = new Headers();
    headers.set('Content-Type', 'application/json');
    headers.append('Set-Cookie', clearSessionCookie());

    return new Response(JSON.stringify({ success: true, redirect: '/' }), {
      status: 200,
      headers,
    });
  } catch (error: any) {
    cookies.delete('sid', { path: '/' });
    const headers = new Headers();
    headers.set('Content-Type', 'application/json');
    headers.append('Set-Cookie', clearSessionCookie());
    return new Response(JSON.stringify({ success: true, redirect: '/' }), { status: 200, headers });
  }
};
