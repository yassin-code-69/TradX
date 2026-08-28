import { app } from './app.ts';
import { initDatabase } from './db/init.ts';

const PORT = parseInt(process.env.PORT || '3000', 10);

// Initialize DB schema on boot if available
initDatabase().catch(console.error);

console.log(`🚀 TRADEX Lottery & Draws Backend running on port ${PORT}`);

export default {
  port: PORT,
  fetch: app.fetch,
};
