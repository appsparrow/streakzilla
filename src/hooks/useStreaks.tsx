import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './useAuth';
import { toast } from 'sonner';

interface Streak {
  id: string;
  name: string;
  code: string;
  mode: string;
  start_date: string;
  duration_days: number;
  is_active: boolean;
  current_streak: number;
  total_points: number;
  lives_remaining: number;
  hearts_available: number;
  hearts_earned: number;
  hearts_used: number;
  heart_sharing_enabled: boolean;
  points_to_hearts_enabled: boolean;
  hearts_per_100_points: number;
  role: 'admin' | 'member';
}

interface CreateStreakData {
  name: string;
  mode: string;
  start_date: string;
  duration_days?: number;
  points_to_hearts_enabled?: boolean;
}

export const useStreaks = () => {
  const { user } = useAuth();
  const [streaks, setStreaks] = useState<Streak[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchUserStreaks = async () => {
    if (!user) return;

    try {
      setLoading(true);
      
      // Get user's streak memberships
      const { data: memberships, error: membershipError } = await supabase
        .from('sz_streak_members')
        .select('current_streak, total_points, lives_remaining, role, streak_id')
        .eq('user_id', user.id);

      if (membershipError) throw membershipError;

      if (!memberships || memberships.length === 0) {
        setStreaks([]);
        return;
      }

      // Get streak details for all memberships
      const streakIds = memberships.map(m => m.streak_id);
      const { data: streaksData, error: streaksError } = await supabase
        .from('sz_streaks')
        .select('id, name, code, mode, start_date, duration_days, is_active')
        .in('id', streakIds);

      if (streaksError) throw streaksError;

      // Combine membership and streak data
      const formattedStreaks = memberships.map(membership => {
        const streakData = streaksData?.find(s => s.id === membership.streak_id);
        
        // Calculate hearts from points until migration is applied
        const totalPoints = membership.total_points || 0;
        const heartsFromPoints = Math.floor(totalPoints / 100);
        const heartsUsed = membership.hearts_used || 0;
        const heartsAvailable = Math.max(0, heartsFromPoints - heartsUsed);
        
        return {
          id: streakData?.id || '',
          name: streakData?.name || '',
          code: streakData?.code || '',
          mode: streakData?.mode || '',
          start_date: streakData?.start_date || '',
          duration_days: streakData?.duration_days || 75,
          is_active: streakData?.is_active || false,
          current_streak: membership.current_streak,
          total_points: membership.total_points,
          lives_remaining: membership.lives_remaining,
          hearts_available: membership.hearts_available || heartsAvailable,
          hearts_earned: membership.hearts_earned || heartsFromPoints,
          hearts_used: membership.hearts_used || heartsUsed,
          heart_sharing_enabled: streakData?.heart_sharing_enabled ?? true,
          points_to_hearts_enabled: streakData?.points_to_hearts_enabled ?? true,
          hearts_per_100_points: 1, // Fixed value
          role: membership.role as 'admin' | 'member',
        };
      }).filter(streak => streak.id); // Filter out any invalid streaks

      setStreaks(formattedStreaks);
    } catch (error) {
      console.error('Error fetching streaks:', error);
      toast.error('Failed to load streaks');
    } finally {
      setLoading(false);
    }
  };

  const createStreak = async (data: CreateStreakData) => {
    if (!user) {
      toast.error('You must be logged in to create a streak');
      return null;
    }

    try {
      // First create the streak with basic info
      const { data: result, error } = await supabase.rpc('sz_create_streak', {
        p_name: data.name,
        p_mode: data.mode,
        p_start_date: data.start_date,
        p_duration_days: data.duration_days || 75,
      });

      if (error) throw error;

      const streakId = result[0].streak_id;

      // Update the streak with heart settings if provided (only if columns exist)
      if (data.points_to_hearts_enabled !== undefined) {
        
        try {
          const updateData: any = {};
          if (data.points_to_hearts_enabled !== undefined) updateData.points_to_hearts_enabled = data.points_to_hearts_enabled;
          updateData.hearts_per_100_points = 1; // Always fixed at 1

          const { error: updateError } = await supabase
            .from('sz_streaks')
            .update(updateData)
            .eq('id', streakId);

          if (updateError) {
            console.warn('Failed to update heart settings (columns may not exist yet):', updateError);
            // Don't throw error, streak was created successfully
          }
        } catch (error) {
          console.warn('Heart settings update skipped (migration not applied yet):', error);
        }
      }

      toast.success('Streak created successfully!');
      await fetchUserStreaks(); // Refresh the list
      
      return result[0]; // { streak_id, streak_code }
    } catch (error: any) {
      console.error('Error creating streak:', error);
      toast.error(error.message || 'Failed to create streak');
      return null;
    }
  };

  const joinStreak = async (code: string) => {
    if (!user) {
      toast.error('You must be logged in to join a streak');
      return false;
    }

    try {
      const { error } = await supabase.rpc('sz_join_streak', {
        p_code: code.toUpperCase().trim(),
      });

      if (error) throw error;

      toast.success('Successfully joined streak!');
      await fetchUserStreaks(); // Refresh the list
      return true;
    } catch (error: any) {
      console.error('Error joining streak:', error);
      
      // Handle specific error cases with user-friendly messages
      if (error.code === 'P0001') {
        toast.error('Invalid or inactive streak code. Please check the code and try again.');
      } else if (error.message?.includes('already a member')) {
        toast.error('You are already a member of this streak.');
      } else if (error.message?.includes('not found')) {
        toast.error('Streak not found. Please check the code and try again.');
      } else {
        toast.error(error.message || 'Failed to join streak. Please try again.');
      }
      
      return false;
    }
  };

  useEffect(() => {
    fetchUserStreaks();
  }, [user]);

  return {
    streaks,
    loading,
    createStreak,
    joinStreak,
    refetch: fetchUserStreaks,
  };
};