// src/lib/db.ts
// Thin wrapper around Cloudflare D1 with type-safe helpers

import type { D1Database } from '@cloudflare/workers-types';

export type DB = D1Database;

export function getDB(env: App.Locals['runtime']['env']): DB {
  return env.DB;
}

function cleanBindings(bindings: unknown[] = []): unknown[] {
  return bindings.map(b => (b === undefined ? null : b));
}

export async function one<T = Record<string, unknown>>(
  db: DB,
  sql: string,
  bindings: unknown[] = []
): Promise<T | null> {
  const clean = cleanBindings(bindings);
  const stmt = db.prepare(sql);
  const bound = clean.length ? stmt.bind(...clean) : stmt;
  const result = await bound.first<T>();
  return result ?? null;
}

export async function all<T = Record<string, unknown>>(
  db: DB,
  sql: string,
  bindings: unknown[] = []
): Promise<T[]> {
  const clean = cleanBindings(bindings);
  const stmt = db.prepare(sql);
  const bound = clean.length ? stmt.bind(...clean) : stmt;
  const { results } = await bound.all<T>();
  return results;
}

export async function run(
  db: DB,
  sql: string,
  bindings: unknown[] = []
): Promise<D1Result> {
  const clean = cleanBindings(bindings);
  const stmt = db.prepare(sql);
  const bound = clean.length ? stmt.bind(...clean) : stmt;
  return bound.run();
}

export async function batch(
  db: DB,
  statements: { sql: string; bindings?: unknown[] }[]
): Promise<D1Result[]> {
  const prepared = statements.map(({ sql, bindings = [] }) => {
    const clean = cleanBindings(bindings);
    const stmt = db.prepare(sql);
    return clean.length ? stmt.bind(...clean) : stmt;
  });
  return db.batch(prepared);
}

export type D1Result = Awaited<ReturnType<D1PreparedStatement['run']>>;
