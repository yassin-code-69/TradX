import { query } from './index.ts';
import fs from 'fs';
import path from 'path';

export async function initDatabase() {
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const sql = fs.readFileSync(schemaPath, 'utf8');
      await query(sql);
      console.log('✅ Database schema initialized successfully');
    }
  } catch (err: any) {
    console.warn('⚠️ Note on database schema init (or already initialized):', err?.message);
  }
}
