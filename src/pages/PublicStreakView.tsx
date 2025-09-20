import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/layout/page-header";
import { Progress75Circles } from "@/components/progress-75-circles";
import { Heart, Users, Calendar, Target, Share2, ExternalLink } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface PublicStreakData {
  id: string;
  name: string;
  description: string;
  mode: string;
  duration_days: number;
  start_date: string;
  end_date: string;
  status: string;
  points_to_hearts_enabled: boolean;
  hearts_per_100_points: number;
  members: Array<{
    user_id: string;
    display_name: string;
    current_streak: number;
    total_points: number;
    hearts_available: number;
    hearts_earned: number;
    hearts_used: number;
    lives_remaining: number;
    joined_at: string;
    is_admin: boolean;
  }>;
  habits: Array<{
    id: string;
    title: string;
    description: string;
    points: number;
    category: string;
  }>;
}

export function PublicStreakView() {
  const { streakId } = useParams<{ streakId: string }>();
  const [streak, setStreak] = useState<PublicStreakData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (streakId) {
      fetchPublicStreakData(streakId);
    }
  }, [streakId]);

  const fetchPublicStreakData = async (id: string) => {
    try {
      setLoading(true);
      setError(null);

      // Fetch streak basic info
      const { data: streakData, error: streakError } = await supabase
        .from('sz_streaks')
        .select(`
          id,
          name,
          description,
          mode,
          duration_days,
          start_date,
          end_date,
          status,
          points_to_hearts_enabled,
          hearts_per_100_points
        `)
        .eq('id', id)
        .eq('status', 'active')
        .single();

      if (streakError) {
        throw new Error('Streak not found or inactive');
      }

      // Fetch members
      const { data: membersData, error: membersError } = await supabase
        .from('sz_streak_members')
        .select(`
          user_id,
          display_name,
          current_streak,
          total_points,
          hearts_available,
          hearts_earned,
          hearts_used,
          lives_remaining,
          joined_at,
          is_admin
        `)
        .eq('streak_id', id);

      if (membersError) {
        throw new Error('Failed to fetch members');
      }

      // Fetch habits
      const { data: habitsData, error: habitsError } = await supabase
        .from('sz_streak_habits')
        .select(`
          habit_id,
          sz_habits!inner(
            id,
            title,
            description,
            points,
            category
          )
        `)
        .eq('streak_id', id);

      if (habitsError) {
        throw new Error('Failed to fetch habits');
      }

      const habits = habitsData.map(item => ({
        id: item.sz_habits.id,
        title: item.sz_habits.title,
        description: item.sz_habits.description,
        points: item.sz_habits.points,
        category: item.sz_habits.category
      }));

      setStreak({
        ...streakData,
        members: membersData || [],
        habits: habits
      });

    } catch (err) {
      console.error('Error fetching public streak data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load streak data');
    } finally {
      setLoading(false);
    }
  };

  const handleShareLink = () => {
    const url = window.location.href;
    navigator.clipboard.writeText(url);
    toast.success("Public link copied to clipboard!");
  };

  const calculateCurrentDay = () => {
    if (!streak) return 1;
    const startDate = new Date(streak.start_date);
    const today = new Date();
    const diffTime = today.getTime() - startDate.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return Math.max(1, Math.min(diffDays, streak.duration_days));
  };

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-6 max-w-6xl">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-muted-foreground">Loading streak data...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error || !streak) {
    return (
      <div className="container mx-auto px-4 py-6 max-w-6xl">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Target className="w-8 h-8 text-red-500" />
            </div>
            <h2 className="text-xl font-semibold mb-2">Streak Not Found</h2>
            <p className="text-muted-foreground mb-4">
              {error || "This streak doesn't exist or is no longer active."}
            </p>
            <Button onClick={() => window.location.href = '/'}>
              Go to Home
            </Button>
          </div>
        </div>
      </div>
    );
  }

  const currentDay = calculateCurrentDay();
  const progressPercentage = (currentDay / streak.duration_days) * 100;

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl">
      <PageHeader
        title={streak.name}
        subtitle={`${streak.mode} • Started ${new Date(streak.start_date).toLocaleDateString()}`}
        showLogo={true}
      >
        <Button
          variant="outline"
          onClick={handleShareLink}
          className="text-xs sm:text-sm"
        >
          <Share2 className="w-4 h-4 mr-2" />
          Share Link
        </Button>
      </PageHeader>

      <div className="grid gap-4 lg:gap-6 lg:grid-cols-3 mt-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-4 lg:space-y-6">
          {/* Streak Overview */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                Public Streak View
              </CardTitle>
              <CardDescription>
                View-only access to this streak's progress and statistics
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* 75 Circles Progress */}
              <Progress75Circles 
                currentDay={currentDay}
                totalDays={streak.duration_days}
                missedDays={[]} // TODO: Get from actual data
                heartsUsed={[]} // TODO: Get from actual data
              />

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{streak.duration_days}</div>
                  <div className="text-sm text-muted-foreground">Total Days</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{currentDay}</div>
                  <div className="text-sm text-muted-foreground">Current Day</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{streak.members.length}</div>
                  <div className="text-sm text-muted-foreground">Participants</div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Habits */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                Streak Habits
              </CardTitle>
              <CardDescription>
                Habits that participants are tracking in this streak
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3">
                {streak.habits.map((habit) => (
                  <div key={habit.id} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex-1">
                      <h4 className="font-medium">{habit.title}</h4>
                      <p className="text-sm text-muted-foreground">{habit.description}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium">{habit.points} pts</span>
                      <Badge variant="secondary">{habit.category}</Badge>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-4 lg:space-y-6">
          {/* Streak Info */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="w-5 h-5 text-primary" />
                Streak Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Mode</span>
                <Badge variant="outline">{streak.mode}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Duration</span>
                <span className="text-sm font-medium">{streak.duration_days} days</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Started</span>
                <span className="text-sm font-medium">
                  {new Date(streak.start_date).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Ends</span>
                <span className="text-sm font-medium">
                  {new Date(streak.end_date).toLocaleDateString()}
                </span>
              </div>
              {streak.points_to_hearts_enabled && (
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Heart System</span>
                  <span className="text-sm font-medium">Enabled</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Participants */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="w-5 h-5 text-primary" />
                Participants ({streak.members.length})
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {streak.members.map((member) => (
                  <div key={member.user_id} className="flex items-center justify-between p-2 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded-full bg-gradient-to-r from-primary/20 to-primary/40 flex items-center justify-center">
                        <span className="text-xs font-medium text-primary">
                          {member.display_name?.charAt(0) || "U"}
                        </span>
                      </div>
                      <div>
                        <div className="text-sm font-medium">{member.display_name}</div>
                        <div className="text-xs text-muted-foreground">
                          {member.current_streak} day streak
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium">{member.total_points} pts</div>
                      {streak.points_to_hearts_enabled && (
                        <div className="text-xs text-muted-foreground flex items-center gap-1">
                          <Heart className="w-3 h-3" />
                          {member.hearts_available}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Join Streak */}
          <Card className="border-card-border bg-gradient-to-r from-primary/5 to-primary/10">
            <CardContent className="p-4 text-center">
              <h3 className="font-semibold mb-2">Want to join this streak?</h3>
              <p className="text-sm text-muted-foreground mb-4">
                Create an account to participate and track your progress
              </p>
              <Button 
                className="w-full gradient-primary text-primary-foreground border-0"
                onClick={() => window.location.href = '/auth'}
              >
                <ExternalLink className="w-4 h-4 mr-2" />
                Join Streak
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
