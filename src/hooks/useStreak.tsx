import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './useAuth';
import { toast } from 'sonner';

interface Habit {
  id: string;
  title: string;
  description: string;
  category: string;
  points: number;
  template_set?: string;
  is_core?: boolean;
  points_override?: number;
}

interface Member {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  role: string;
  total_points: number;
  current_streak: number;
  lives_remaining: number;
  hearts_available: number;
  hearts_earned: number;
  hearts_used: number;
  is_out: boolean;
  status?: string;
  left_at?: string;
}

interface CheckinData {
  day_number: number;
  completed_habit_ids: string[];
  note?: string;
  photo_url?: string;
}

interface StreakDetails {
  id: string;
  name: string;
  code: string;
  mode: string;
  start_date: string;
  duration_days: number;
  is_active: boolean;
  current_streak: number;
  total_points: number;
  bonus_points: number;
  lives_remaining: number;
  hearts_available: number;
  hearts_earned: number;
  hearts_used: number;
  heart_sharing_enabled: boolean;
  points_to_hearts_enabled: boolean;
  hearts_per_100_points: number;
  role: string;
}

interface TodayCheckin {
  id?: string;
  completed_habit_ids: string[];
  points_earned: number;
  note?: string;
  photo_url?: string;
  created_at?: string;
}

export const useStreak = (streakId: string) => {
  const { user } = useAuth();
  const [streak, setStreak] = useState<StreakDetails | null>(null);
  const [habits, setHabits] = useState<Habit[]>([]);
  const [members, setMembers] = useState<Member[]>([]);
  const [todayCheckin, setTodayCheckin] = useState<TodayCheckin | null>(null);
  const [loading, setLoading] = useState(true);
  const [missedYesterday, setMissedYesterday] = useState(false);
  const [heartsUsedDays, setHeartsUsedDays] = useState<number[]>([]);
  const [missedDays, setMissedDays] = useState<number[]>([]);

  const fetchStreakDetails = async () => {
    if (!user || !streakId) return;

    try {
      setLoading(true);

      // Get streak basic info
      const { data: streakInfo, error: streakInfoError } = await supabase
        .from('sz_streaks')
        .select('*')
        .eq('id', streakId)
        .maybeSingle();

      if (streakInfoError) throw streakInfoError;
      if (!streakInfo) {
        toast.error('Streak not found');
        return;
      }

      // Get user membership info for this streak
      const { data: membershipData, error: membershipError } = await supabase
        .from('sz_streak_members')
        .select('current_streak, total_points, bonus_points, lives_remaining, hearts_available, hearts_earned, hearts_used, role')
        .eq('streak_id', streakId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

      if (membershipError) throw membershipError;
      if (!membershipData) {
        toast.error('You are not a member of this streak');
        return;
      }

      // Calculate hearts from points until migration is applied
      const totalPoints = membershipData.total_points || 0;
      const heartsFromPoints = Math.floor(totalPoints / 100);
      const heartsUsed = membershipData.hearts_used || 0;
      const heartsAvailable = Math.max(0, heartsFromPoints - heartsUsed);

      setStreak({
        id: streakInfo.id,
        name: streakInfo.name,
        code: streakInfo.code,
        mode: streakInfo.mode,
        start_date: streakInfo.start_date,
        duration_days: streakInfo.duration_days,
        is_active: streakInfo.is_active,
        current_streak: membershipData.current_streak,
        total_points: membershipData.total_points,
        bonus_points: membershipData.bonus_points || 0,
        lives_remaining: membershipData.lives_remaining,
        hearts_available: membershipData.hearts_available || heartsAvailable,
        hearts_earned: membershipData.hearts_earned || heartsFromPoints,
        hearts_used: membershipData.hearts_used || heartsUsed,
        heart_sharing_enabled: streakInfo.heart_sharing_enabled ?? true,
        points_to_hearts_enabled: streakInfo.points_to_hearts_enabled ?? true,
        hearts_per_100_points: streakInfo.hearts_per_100_points || 1,
        role: membershipData.role,
      });

      // Get user's selected habits for this streak with template mapping info
      const { data: userHabits, error: userHabitsError } = await supabase
        .from('sz_user_habits')
        .select('habit_id')
        .eq('streak_id', streakId)
        .eq('user_id', user.id);

      if (userHabitsError) throw userHabitsError;

      if (userHabits && userHabits.length > 0) {
        const habitIds = userHabits.map(uh => uh.habit_id);

        // Always fetch the base habits by IDs
        const { data: baseHabits, error: baseErr } = await supabase
          .from('sz_habits')
          .select('*')
          .in('id', habitIds);
        if (baseErr) throw baseErr;

        // Get template mapping information for these habits
        console.log('Fetching template mappings for template_id:', streakInfo.template_id);
        const { data: templateMappings, error: mappingErr } = await supabase
          .from('sz_template_habits')
          .select('habit_id, is_core, points_override')
          .in('habit_id', habitIds)
          .eq('template_id', streakInfo.template_id);

        if (mappingErr) throw mappingErr;
        console.log('Template mappings found:', templateMappings);

        // Merge habit data with template mapping info
        const merged = (baseHabits || []).map(habit => {
          const mapping = templateMappings?.find(m => m.habit_id === habit.id);
          const mergedHabit = {
            ...habit,
            is_core: mapping?.is_core,
            points_override: mapping?.points_override
          };
          console.log(`Habit ${habit.title}: is_core=${mapping?.is_core}, mapping=`, mapping);
          return mergedHabit;
        });

        setHabits(merged);
      } else {
        // If no user habits selected yet, set empty array
        // The CheckInModal will handle showing the habit selection prompt
        setHabits([]);
      }

      // Get streak members - fetch members and profiles separately due to relationship issues
      // Note: heart columns may not exist until migration is applied
      const { data: membersData, error: membersError } = await supabase
        .from('sz_streak_members')
        .select('user_id, role, total_points, current_streak, lives_remaining, is_out, status, left_at')
        .eq('streak_id', streakId)
        .order('total_points', { ascending: false });

      if (membersError) throw membersError;

      // Get profiles for all members
      let formattedMembers = [];
      if (membersData) {
        const userIds = membersData.map(member => member.user_id);
        const { data: profilesData } = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .in('id', userIds);

        formattedMembers = membersData.map((member: any) => {
          const profile = profilesData?.find(p => p.id === member.user_id);
          return {
            user_id: member.user_id,
            display_name: profile?.display_name || 'Unknown User',
            avatar_url: profile?.avatar_url,
            role: member.role,
            total_points: member.total_points,
            current_streak: member.current_streak,
            lives_remaining: member.lives_remaining,
            hearts_available: member.hearts_available || 0, // Default until migration
            hearts_earned: member.hearts_earned || 0, // Default until migration
            hearts_used: member.hearts_used || 0, // Default until migration
            is_out: member.is_out,
            status: member.status,
            left_at: member.left_at,
          };
        });
      }

      setMembers(formattedMembers);

      // Check most recent checkin status (regardless of day)
      const { data: todayCheckinData } = await supabase
        .from('sz_checkins')
        .select('*')
        .eq('streak_id', streakId)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1);

      if (todayCheckinData && todayCheckinData.length > 0) {
        setTodayCheckin(todayCheckinData[0]);
      } else {
        setTodayCheckin(null);
      }

      // Check if missed yesterday (only if not first day)
      const currentDay = getCurrentDayNumber();
      if (currentDay > 1) {
        const { data: yesterdayCheckin } = await supabase
          .from('sz_checkins')
          .select('id')
          .eq('streak_id', streakId)
          .eq('user_id', user.id)
          .eq('day_number', currentDay - 1)
          .limit(1);

        setMissedYesterday(!yesterdayCheckin || yesterdayCheckin.length === 0);
      }

      // Fetch heart transactions to show which days hearts were used
      const { data: heartTransactions, error: heartError } = await supabase
        .from('sz_hearts_transactions')
        .select('day_number, transaction_type')
        .eq('streak_id', streakId)
        .eq('from_user_id', user.id)
        .eq('transaction_type', 'auto_use');

      if (heartError) {
        console.error('Error fetching heart transactions:', heartError);
      } else {
        const heartsUsed = heartTransactions?.map(ht => ht.day_number) || [];
        setHeartsUsedDays(heartsUsed);
      }

      // Calculate missed days (days with no checkin and no heart used)
      const { data: allCheckins, error: checkinsError } = await supabase
        .from('sz_checkins')
        .select('day_number')
        .eq('streak_id', streakId)
        .eq('user_id', user.id);

      if (checkinsError) {
        console.error('Error fetching checkins for missed days:', checkinsError);
      } else {
        const checkedInDays = allCheckins?.map(c => c.day_number) || [];
        const completedDays = [...checkedInDays, ...heartsUsedDays];
        
        // Find missed days (days from 1 to currentDay-1 that are not completed)
        const missed = [];
        for (let day = 1; day < currentDay; day++) {
          if (!completedDays.includes(day)) {
            missed.push(day);
          }
        }
        setMissedDays(missed);
      }
    } catch (error) {
      console.error('Error fetching streak details:', error);
      toast.error('Failed to load streak details');
    } finally {
      setLoading(false);
    }
  };

  const checkin = async (data: CheckinData) => {
    if (!user || !streak) {
      toast.error('Unable to check in');
      return false;
    }

    try {
      const { data: result, error } = await supabase.rpc('sz_checkin', {
        p_streak_id: streak.id,
        p_day_number: data.day_number,
        p_completed_habit_ids: data.completed_habit_ids,
        p_note: data.note || null,
        p_photo_url: data.photo_url || null,
      });

      if (error) throw error;

      // Manually trigger heart application for any missed days
      try {
        await supabase.rpc('sz_manual_apply_hearts', {
          p_streak_id: streak.id,
          p_user_id: user.id
        });
      } catch (heartError) {
        console.error('Error applying hearts:', heartError);
        // Don't fail the checkin if heart application fails
      }

      // Hearts are automatically used by the database function when checking in
      toast.success('Check-in completed! 🎉 Hearts automatically protect your streak! ❤️');

      await fetchStreakDetails(); // Refresh data
      return true;
    } catch (error: any) {
      console.error('Error during checkin:', error);
      toast.error(error.message || 'Failed to check in');
      return false;
    }
  };

  // Hearts are now automatically used when checking in - no manual intervention needed

  const getCurrentDayNumber = () => {
    if (!streak) return 1;
    
    const startDate = new Date(streak.start_date);
    const today = new Date();
    
    // Reset time to compare only dates (not hours/minutes)
    startDate.setHours(0, 0, 0, 0);
    today.setHours(0, 0, 0, 0);
    
    const diffTime = today.getTime() - startDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    return Math.max(1, diffDays + 1);
  };

  const calculateExtraHearts = (bonusPoints: number, mode: string) => {
    if (!mode.includes('75_hard') || !mode.includes('plus')) return 0;
    
    // In Hard Plus mode, only bonus habit points count toward hearts
    // Hearts are earned every 100 bonus points
    return Math.min(3, Math.floor(bonusPoints / 100)); // Max 3 hearts, 1 per 100 bonus points
  };

  useEffect(() => {
    fetchStreakDetails();
  }, [user, streakId]);

  return {
    streak,
    habits,
    members,
    todayCheckin,
    missedYesterday,
    heartsUsedDays,
    missedDays,
    loading,
    checkin,
    getCurrentDayNumber,
    calculateExtraHearts,
    refetch: fetchStreakDetails,
  };
};