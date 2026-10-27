// src/lib/auth.ts
// Session management and authentication helpers

import { one, run, type DB } from './db';
import { sha256, randomHex, hashPassword, verifyPassword } from './crypto';

export { hashPassword, verifyPassword };

export const SESSION_DURATION_DAYS = 30;
export const COOKIE_NAME = 'sid';

export interface SessionUser {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: 'member' | 'admin' | 'super_admin';
  force_pw_change: number;
}

/** Create a new session, return the raw token (to be set in cookie) */
export async function createSession(
  db: DB,
  userId: number,
  cookies?: any
): Promise<string> {
  const token = await randomHex(32);
  const tokenHash = await sha256(token);
  const expiresAt = new Date(
    Date.now() + SESSION_DURATION_DAYS * 24 * 60 * 60 * 1000
  );

  await run(
    db,
    'INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)',
    [tokenHash, userId, expiresAt.toISOString()]
  );

  if (cookies && typeof cookies.set === 'function') {
    cookies.set(COOKIE_NAME, token, {
      path: '/',
      httpOnly: true,
      secure: false,
      sameSite: 'lax',
      expires: expiresAt,
      maxAge: SESSION_DURATION_DAYS * 24 * 60 * 60,
    });
  }

  return token;
}

/** Resolve a session token to a user, returns null if invalid/expired */
export async function getSession(
  db: DB,
  token: string | undefined
): Promise<SessionUser | null> {
  if (!token) return null;
  const tokenHash = await sha256(token);
  const now = new Date().toISOString();
  const row = await one<SessionUser & { expires_at: string }>(
    db,
    `SELECT u.id, u.first_name, u.last_name, u.email, u.role, u.force_pw_change
     FROM sessions s
     JOIN users u ON u.id = s.user_id
     WHERE s.id = ? AND s.expires_at > ?`,
    [tokenHash, now]
  );
  return row;
}

/** Parse the session cookie from a Request */
export function getSessionCookie(request: Request): string | undefined {
  const cookieHeader = request?.headers?.get?.('cookie') ?? '';
  for (const part of cookieHeader.split(';')) {
    const [key, ...rest] = part.trim().split('=');
    if (key.trim() === COOKIE_NAME) return rest.join('=');
  }
  return undefined;
}

/** Get session user from Astro cookies or Request */
export async function getSessionUser(
  db: DB,
  cookiesOrRequest: any
): Promise<SessionUser | null> {
  let token: string | undefined;
  if (typeof cookiesOrRequest?.get === 'function') {
    const c = cookiesOrRequest.get(COOKIE_NAME);
    token = typeof c === 'string' ? c : c?.value;
  }
  if (!token && cookiesOrRequest?.headers?.get) {
    token = getSessionCookie(cookiesOrRequest);
  }
  if (!token && typeof cookiesOrRequest === 'string') {
    token = cookiesOrRequest;
  }
  return getSession(db, token);
}

/** Delete a session */
export async function destroySession(db: DB, tokenOrCookies: any): Promise<void> {
  let token: string | undefined;
  if (typeof tokenOrCookies === 'string') {
    token = tokenOrCookies;
  } else if (typeof tokenOrCookies?.get === 'function') {
    const c = tokenOrCookies.get(COOKIE_NAME);
    token = typeof c === 'string' ? c : c?.value;
    try {
      tokenOrCookies.delete(COOKIE_NAME, { path: '/' });
    } catch {}
  }
  if (token) {
    const tokenHash = await sha256(token);
    await run(db, 'DELETE FROM sessions WHERE id = ?', [tokenHash]);
  }
}

/** Build the Set-Cookie header string */
export function buildSessionCookie(token: string, expires: Date, secure: boolean = false): string {
  const sec = secure ? '; Secure' : '';
  return `${COOKIE_NAME}=${token}; Path=/; HttpOnly${sec}; SameSite=Lax; Expires=${expires.toUTCString()}; Max-Age=${SESSION_DURATION_DAYS * 24 * 60 * 60}`;
}

/** Build the cookie that clears the session */
export function clearSessionCookie(): string {
  return `${COOKIE_NAME}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT`;
}

/** Check if current user has admin access */
export function isAdmin(user: SessionUser | null): boolean {
  return user?.role === 'admin' || user?.role === 'super_admin';
}

/** Check if current user is super_admin */
export function isSuperAdmin(user: SessionUser | null): boolean {
  return user?.role === 'super_admin';
}
