// scripts/create-admin.ts
// Creates initial super_admin user in Cloudflare D1
// Run with: ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=Secret123 npx tsx scripts/create-admin.ts

import { webcrypto } from 'crypto';

const PBKDF2_ITERATIONS = 100_000;
const SALT_BYTES = 32;
const KEY_LENGTH = 32;

function bufferToHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

async function hashPassword(password: string): Promise<{ hash: string; salt: string }> {
  const saltBytes = new Uint8Array(SALT_BYTES);
  webcrypto.getRandomValues(saltBytes);
  const saltHex = bufferToHex(saltBytes.buffer);

  const keyMaterial = await webcrypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );

  const derivedBits = await webcrypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: new TextEncoder().encode(saltHex),
      iterations: PBKDF2_ITERATIONS,
      hash: 'SHA-256',
    },
    keyMaterial,
    KEY_LENGTH * 8
  );

  return {
    hash: bufferToHex(derivedBits),
    salt: saltHex,
  };
}

async function main() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    console.error('Error: Please provide ADMIN_EMAIL and ADMIN_PASSWORD environment variables.');
    console.error('Example: ADMIN_EMAIL=admin@store.com ADMIN_PASSWORD=SuperSecret123 npx tsx scripts/create-admin.ts');
    process.exit(1);
  }

  if (password.length < 8) {
    console.error('Error: ADMIN_PASSWORD must be at least 8 characters.');
    process.exit(1);
  }

  const { hash, salt } = await hashPassword(password);

  console.log('\n--- Admin SQL Migration Statement ---');
  console.log(`INSERT INTO users (first_name, last_name, email, password_hash, password_salt, role, force_pw_change)`);
  console.log(`VALUES ('Admin', 'Owner', '${email.toLowerCase().trim()}', '${hash}', '${salt}', 'super_admin', 1);`);
  console.log('-------------------------------------\n');
  console.log('Run this via wrangler:');
  console.log(`wrangler d1 execute homedecor-db --command="INSERT INTO users (first_name, last_name, email, password_hash, password_salt, role, force_pw_change) VALUES ('Admin', 'Owner', '${email.toLowerCase().trim()}', '${hash}', '${salt}', 'super_admin', 1);" --local`);
}

main().catch(console.error);
