// src/pages/api/admin/settings.ts
import type { APIRoute } from 'astro';
import { getDB, run, all } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify({}), { headers: { 'Content-Type': 'application/json' } });
  const db = getDB(env);
  const rows = await all<{ key: string; value: string }>(db, `SELECT key, value FROM settings`);
  const settingsObj: Record<string, string> = {};
  for (const r of rows) settingsObj[r.key] = r.value;
  return new Response(JSON.stringify(settingsObj), { status: 200, headers: { 'Content-Type': 'application/json' } });
};

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    for (const [key, value] of Object.entries(body)) {
      if (typeof value === 'string' || typeof value === 'number') {
        await run(
          db,
          `INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
          [key, String(value)]
        );
      }
    }

    return new Response(JSON.stringify({ success: true, message: 'Settings saved successfully.' }), { status: 200 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Settings update failed.' }), { status: 500 });
  }
};
