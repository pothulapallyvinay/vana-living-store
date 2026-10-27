// src/pages/api/admin/categories.ts
import type { APIRoute } from 'astro';
import { getDB, run, all } from '../../../lib/db';

export const GET: APIRoute = async ({ locals }) => {
  const env = (locals as any).runtime?.env || (process.env as any);
  if (!env?.DB) return new Response(JSON.stringify([]), { headers: { 'Content-Type': 'application/json' } });
  const db = getDB(env);
  const categories = await all(db, `SELECT * FROM categories ORDER BY sort_order ASC, id ASC`);
  return new Response(JSON.stringify(categories), { status: 200, headers: { 'Content-Type': 'application/json' } });
};

export const POST: APIRoute = async ({ request, locals }) => {
  try {
    const body = await request.json();
    const { id, name, slug, description, sort_order, is_active } = body;

    if (!name || !slug) {
      return new Response(JSON.stringify({ error: 'Category name and slug are required.' }), { status: 400 });
    }

    const env = (locals as any).runtime?.env || (process.env as any);
    const db = getDB(env);

    if (id) {
      await run(
        db,
        `UPDATE categories SET name = ?, slug = ?, description = ?, sort_order = ?, is_active = ? WHERE id = ?`,
        [name, slug, description || null, sort_order || 0, is_active ? 1 : 0, id]
      );
    } else {
      await run(
        db,
        `INSERT INTO categories (name, slug, description, sort_order, is_active) VALUES (?, ?, ?, ?, ?)`,
        [name, slug, description || null, sort_order || 0, is_active ? 1 : 0]
      );
    }

    return new Response(JSON.stringify({ success: true, message: 'Category saved successfully.' }), { status: 200 });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || 'Category update failed.' }), { status: 500 });
  }
};
