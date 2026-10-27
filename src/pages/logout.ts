// src/pages/logout.ts
// Direct GET handler for logout links
import type { APIRoute } from 'astro';
import { getDB } from '../lib/db';
import { destroySession } from '../lib/auth';

export const GET: APIRoute = async ({ cookies, locals, redirect }) => {
  try {
    const env = (locals as any).runtime?.env || (process.env as any);
    if (env?.DB) {
      const db = getDB(env);
      await destroySession(db, cookies);
    } else {
      cookies.delete('sid', { path: '/' });
    }
  } catch {
    cookies.delete('sid', { path: '/' });
  }

  return redirect('/login');
};
