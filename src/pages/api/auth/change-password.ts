// src/pages/api/auth/change-password.ts
import type { APIRoute } from 'astro';
import { getDB, run, one } from '../../../lib/db';
import { verifyPassword, hashPassword } from '../../../lib/auth';

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const user = (locals as any).user;
    if (!user) {
      return new Response(JSON.stringify({ error: 'Authentication required.' }), { status: 401 });
    }

    const body = await request.json();
    const currentPassword = body?.current_password;
    const newPassword = body?.new_password;

    if (!currentPassword || !newPassword) {
      return new Response(JSON.stringify({ error: 'Current password and new password are required.' }), { status: 400 });
    }
    if (newPassword.length < 8) {
      return new Response(JSON.stringify({ error: 'New password must be at least 8 characters in length.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    const dbUser = await one<{ password_hash: string; password_salt: string }>(
      db,
      `SELECT password_hash, password_salt FROM users WHERE id = ?`,
      [user.id]
    );

    if (!dbUser) {
      return new Response(JSON.stringify({ error: 'User not found.' }), { status: 404 });
    }

    const valid = await verifyPassword(currentPassword, dbUser.password_hash, dbUser.password_salt);
    if (!valid) {
      return new Response(JSON.stringify({ error: 'Incorrect current password.' }), { status: 400 });
    }

    const { hash, salt } = await hashPassword(newPassword);

    await run(
      db,
      `UPDATE users SET password_hash = ?, password_salt = ?, force_pw_change = 0 WHERE id = ?`,
      [hash, salt, user.id]
    );

    return new Response(JSON.stringify({ success: true, message: 'Password updated successfully.' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Password update failed.' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
