// src/middleware.ts
// Security headers, session authentication, admin route protection, and CSRF Origin check

import { defineMiddleware } from 'astro:middleware';
import { getSessionUser } from './lib/auth';
import { getDB } from './lib/db';

export const onRequest = defineMiddleware(async (context, next) => {
  const { url, request, cookies, locals } = context;

  // 1. Establish Database & User Session in locals
  try {
    const env = (locals as any).runtime?.env || (process.env as any);
    if (env?.DB) {
      const db = getDB(env);
      const user = (await getSessionUser(db, cookies)) || (await getSessionUser(db, request));
      (locals as any).user = user;
    } else {
      (locals as any).user = null;
    }
  } catch (err) {
    (locals as any).user = null;
  }

  const currentUser = (locals as any).user;

  // 2. Admin Route Guard
  if (url.pathname.startsWith('/admin') || url.pathname.startsWith('/api/admin')) {
    if (!currentUser || (currentUser.role !== 'admin' && currentUser.role !== 'super_admin')) {
      if (url.pathname.startsWith('/api/admin')) {
        return new Response(JSON.stringify({ error: 'Unauthorized. Admin credentials required.' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      return context.redirect(`/login?redirect=${encodeURIComponent(url.pathname)}`);
    }
  }

  // 3. Account Route Guard
  if (url.pathname.startsWith('/account')) {
    if (!currentUser) {
      return context.redirect(`/login?redirect=${encodeURIComponent(url.pathname)}`);
    }
  }

  // 4. CSRF / Origin Check for State-Changing POST/PUT/DELETE Requests
  // Webhooks are excluded since they are machine-to-machine with their own cryptographic HMAC signatures
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(request.method) && !url.pathname.startsWith('/api/webhooks')) {
    const origin = request.headers.get('Origin');
    const host = request.headers.get('Host');
    if (origin && host) {
      try {
        const originUrl = new URL(origin);
        if (originUrl.host !== host && !host.includes('localhost') && !host.includes('127.0.0.1')) {
          return new Response(JSON.stringify({ error: 'CSRF validation failed: Origin mismatch' }), {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
          });
        }
      } catch {}
    }
  }

  // Execute request
  const response = await next();

  // 5. Append Strict Security Headers
  const headers = response.headers;
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  headers.set('X-XSS-Protection', '1; mode=block');

  // CSP allowing Google Fonts, Cloudflare Turnstile, and Razorpay
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://checkout.razorpay.com https://challenges.cloudflare.com https://static.cloudflareinsights.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com data:",
    "img-src 'self' data: https: blob:",
    "media-src 'self' https: blob: data:",
    "frame-src 'self' https://api.razorpay.com https://checkout.razorpay.com https://challenges.cloudflare.com",
    "connect-src 'self' https://api.razorpay.com https://lumberjack.razorpay.com https://cloudflareinsights.com",
  ].join('; ');

  headers.set('Content-Security-Policy', csp);

  return response;
});
