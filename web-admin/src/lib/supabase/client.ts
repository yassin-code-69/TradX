import { createClient } from "@supabase/supabase-js";

const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  "https://hvitriqfkaljlqxygaxp.supabase.co";

const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2aXRyaXFma2FsamxxeHlnYXhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTM0MzIsImV4cCI6MjEwMzE2OTQzMn0.IbAeuC_rdcAjgdL5-0WlfuBEPKzK6bRmP4peh9JMp8A";

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== "undefined" ? window.localStorage : undefined,
  },
});

export default supabase;
