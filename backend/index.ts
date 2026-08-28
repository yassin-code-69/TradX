import { app } from './src/app.ts';
import { config } from './src/config/index.ts';
import { initDb } from './src/db/client.ts';

// Initialize DB schema on startup (if database is connected)
initDb().catch((err: any) => {
  console.warn('Initial DB sync failed, continuing server startup:', err?.message || err);
});

console.log(`🚀 TRADEX Backend Financial API running on port ${config.port} (${config.nodeEnv})`);

export default {
  port: config.port,
  fetch: app.fetch,
};
