import { createClient } from '@supabase/supabase-js';
import { Database } from './database.types';

const supabaseUrl = 'https://sbxowcfafuwkzxeaspvq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNieG93Y2ZhZnV3a3p4ZWFzcHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5OTU4NTEsImV4cCI6MjA3MzU3MTg1MX0.tMR6wSNdaGM5Epvu5h2HiAY00kodUwbnwEGaqjPKQsA';

export const supabase = createClient<Database>(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});

// Auth helper functions
export const auth = {
  signUp: async (email: string, password: string, metadata?: { first_name?: string; last_name?: string }) => {
    return await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
      },
    });
  },

  signIn: async (email: string, password: string) => {
    return await supabase.auth.signInWithPassword({
      email,
      password,
    });
  },

  signOut: async () => {
    return await supabase.auth.signOut();
  },

  getUser: async () => {
    return await supabase.auth.getUser();
  },

  getSession: async () => {
    return await supabase.auth.getSession();
  },
};
