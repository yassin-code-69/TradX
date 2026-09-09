import { dbPool } from './index.ts';
import fs from 'fs';
import path from 'path';

export async function initDatabase() {
  // Only attempt local schema bootstrap if direct PostgreSQL pool is actively responsive
  try {
    const client = await dbPool.connect();
    try {
      const schemaPath = path.join(__dirname, 'schema.sql');
      if (fs.existsSync(schemaPath)) {
        const sql = fs.readFileSync(schemaPath, 'utf8');
        await client.query(sql);
        console.log('✅ Local PostgreSQL database schema verified');
      }
    } finally {
      client.release();
    }
  } catch {
    // Cloud Supabase mode (tables & triggers already managed in Supabase Cloud)
    console.log('ℹ️ Operating in Supabase Cloud database mode');
  }
}
