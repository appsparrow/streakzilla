import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './useAuth';

export const useSuperAdmin = () => {
  const { user } = useAuth();
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkSuperAdminStatus();
  }, [user]);

  const checkSuperAdminStatus = async () => {
    if (!user) {
      setIsSuperAdmin(false);
      setLoading(false);
      return;
    }
    
    try {
      const { data, error } = await supabase
        .from("sz_user_roles")
        .select("*")
        .eq("user_id", user.id)
        .eq("role", "super_admin")
        .eq("is_active", true)
        .single();
      
      if (error) {
        console.error('Error checking super admin status:', error);
        // If table doesn't exist or other error, assume not super admin
        setIsSuperAdmin(false);
      } else {
        setIsSuperAdmin(!!data);
      }
    } catch (error) {
      console.error('Error checking super admin status:', error);
      setIsSuperAdmin(false);
    } finally {
      setLoading(false);
    }
  };

  return { isSuperAdmin, loading: loading };
};
