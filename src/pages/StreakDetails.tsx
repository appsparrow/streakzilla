import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/page-header";
import { StreakCircle } from "@/components/ui/streak-circle";
import { Progress } from "@/components/ui/progress";
import { ArrowLeft, Users, Calendar, Crown, Target, Heart, Camera, Share2, Trash2, LogOut, UserX, X, Settings } from "lucide-react";
import { StreakmateHabitsModal } from "@/components/streakmate-habits-modal";
import { Progress75Circles } from "@/components/progress-75-circles";
import { InspireSection } from "@/components/inspire-section";
import { useStreak } from "@/hooks/useStreak";
import { useAuth } from "@/hooks/useAuth";
import { CheckInModal } from "@/components/check-in-modal";
import { toast } from "sonner";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { supabase } from "@/integrations/supabase/client";
import { HabitCountdown } from "@/components/habit-countdown";
import { ProgressCirclesCompact } from "@/components/progress-circles";
// Swipe navigation removed for now - keeping it simple
// Removed HeartSharing component - keeping it simple
// Removed StreakSettings - can only be edited during streak creation

export default function StreakDetails() {
  const { id: streakId } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { streak, habits, members, todayCheckin, missedYesterday, loading, getCurrentDayNumber, calculateExtraHearts, refetch } = useStreak(streakId!);
  
  const [isCheckInDialogOpen, setIsCheckInDialogOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isLeaving, setIsLeaving] = useState(false);
  const [isHabitsExpanded, setIsHabitsExpanded] = useState(false);
  const [selectedMember, setSelectedMember] = useState<typeof members[0] | null>(null);
  
  const currentUserMember = members.find(m => m.user_id === user?.id);
  const isAdmin = currentUserMember?.role === 'admin';

  if (!user || !streakId) {
    navigate("/auth");
    return null;
  }

  if (loading) {
    return (
      <div className="container mx-auto p-6 max-w-6xl">
        <div className="text-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-4" />
          <p className="text-muted-foreground">Loading streak details...</p>
        </div>
      </div>
    );
  }

  if (!streak) {
    return (
      <div className="container mx-auto p-6 max-w-6xl">
        <div className="text-center py-12">
          <h3 className="text-lg font-semibold mb-2">Streak not found</h3>
          <p className="text-muted-foreground mb-4">This streak doesn't exist or you don't have access to it.</p>
          <Button onClick={() => navigate("/")} variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Home
          </Button>
        </div>
      </div>
    );
  }

  const currentDay = getCurrentDayNumber();
  const progressPercentage = (currentDay / streak.duration_days) * 100;
  const extraHearts = calculateExtraHearts(streak.bonus_points, streak.mode);
  
  const handleCheckInComplete = () => {
    refetch();
  };

  // Hearts are now automatically used when checking in - no manual intervention needed

  const handleDeleteStreak = async () => {
    if (!isAdmin) return;
    
    setIsDeleting(true);
    try {
      const { error } = await supabase
        .from('sz_streaks')
        .delete()
        .eq('id', streakId);

      if (error) throw error;

      toast.success("Streak deleted successfully");
      navigate("/");
    } catch (error: any) {
      console.error('Error deleting streak:', error);
      toast.error(error.message || "Failed to delete streak");
    } finally {
      setIsDeleting(false);
    }
  };

  const handleLeaveStreak = async () => {
    setIsLeaving(true);
    try {
      const { error } = await supabase.rpc('sz_leave_streak', {
        p_streak_id: streakId
      });

      if (error) throw error;

      toast.success("We are sad you plan to leave but we are glad you were here to try. See you next time!");
      navigate("/");
    } catch (error: any) {
      console.error('Error leaving streak:', error);
      toast.error(error.message || "Failed to leave streak");
    } finally {
      setIsLeaving(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl">
      <PageHeader
        title={streak.name}
        subtitle={`${streak.mode} • Started ${new Date(streak.start_date).toLocaleDateString()}`}
        showBackButton={true}
        backTo="/"
        showLogo={true}
      >
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => {
              navigator.clipboard.writeText(streak.code);
              toast.success("Streak code copied to clipboard!");
            }}
            className="text-xs sm:text-sm"
          >
            <Share2 className="w-4 h-4 mr-2" />
            <span className="hidden sm:inline">Share Code: </span>{streak.code}
          </Button>
        </div>
      </PageHeader>

      <div className="grid gap-4 lg:gap-6 lg:grid-cols-3">
        {/* Main Stats */}
        <div className="lg:col-span-2 space-y-4 lg:space-y-6 order-2 lg:order-1">
          {/* Missed Yesterday Alert */}
          {missedYesterday && (
            <Card className="border-red-200 bg-red-50">
              <CardContent className="p-4">
                <div className="flex items-center gap-3 text-red-700">
                  <Heart className="w-5 h-5 text-red-500" />
                  <div>
                    <p className="font-medium">Oh no! You broke your streak yesterday 💔</p>
                    {streak.hearts_available > 0 ? (
                      <p className="text-sm text-red-600">A heart ❤️ will automatically protect your streak when you check in!</p>
                    ) : (
                      <p className="text-sm text-red-600">No hearts available to protect your streak. Keep going strong!</p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Extra Hearts Earned Alert */}
          {extraHearts > 0 && (
            <Card className="border-pink-200 bg-pink-50">
              <CardContent className="p-4">
                <div className="flex items-center gap-3 text-pink-700">
                  <Heart className="w-5 h-5 text-pink-500 animate-pulse" />
                  <div>
                    <p className="font-medium">Amazing! You've earned {extraHearts} extra heart{extraHearts > 1 ? 's' : ''}! 💖</p>
                    <p className="text-sm text-pink-600">Keep pushing beyond the basics for more rewards!</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Progress Overview */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                Day {currentDay} of {streak.duration_days}
              </CardTitle>
              <CardDescription>
                Your current progress in the streak challenge
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* 75 Circles Progress */}
              <Progress75Circles 
                currentDay={currentDay}
                totalDays={streak.duration_days}
                missedDays={[]} // TODO: Get from streak data
                heartsUsed={[]} // TODO: Get from streak data
              />

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{streak.current_streak}</div>
                  <div className="text-sm text-muted-foreground">Current Streak</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{streak.total_points}</div>
                  <div className="text-sm text-muted-foreground">Total Points</div>
                </div>
                <div className="text-center flex flex-col items-center">
                  <div className="flex items-center gap-1 text-2xl font-bold text-red-500">
                    <div className="group relative">
                      <Heart className="w-6 h-6 cursor-help" />
                      <div className="hidden group-hover:block absolute z-10 left-1/2 -translate-x-1/2 mt-2 w-64 bg-white border rounded-md shadow-md p-3 text-sm">
                        <div className="font-medium mb-1">Heart System</div>
                        <div className="text-gray-600 mb-2">
                          {streak.points_to_hearts_enabled 
                            ? 'Earn 1 heart per 100 points. Use hearts to protect your streak if you miss a day.' 
                            : 'Lives system enabled. Miss a day to lose a life.'}
                        </div>
                        {streak.points_to_hearts_enabled && (
                          <div className="text-xs text-pink-600">
                            {100 - (streak.total_points % 100)} points to next heart
                          </div>
                        )}
                      </div>
                    </div>
                    {streak.points_to_hearts_enabled ? streak.hearts_available : streak.lives_remaining}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {streak.points_to_hearts_enabled 
                      ? `Hearts Available` 
                      : `Lives Left`
                    }
                  </div>
                </div>
              </div>

              <Button 
                className="w-full gradient-primary text-primary-foreground border-0"
                size="lg"
                onClick={() => setIsCheckInDialogOpen(true)}
              >
                <Target className="w-4 h-4 mr-2" />
                {todayCheckin ? `Add Bonus Points for Day ${currentDay}` : `Check In for Day ${currentDay}`}
              </Button>
            </CardContent>
          </Card>

          {/* Progress Circles */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                Daily Progress
              </CardTitle>
              <CardDescription>
                Visual representation of your streak progress
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Simple Progress Bar */}
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm font-medium text-gray-700">Progress</span>
                  <span className="text-sm text-gray-500">{currentDay}/{streak.duration_days} days</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-purple-600 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${(currentDay / streak.duration_days) * 100}%` }}
                  />
                </div>
                <div className="text-sm text-gray-500">
                  {streak.duration_days - currentDay} days remaining
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Habits */}
          <Card className="border-card-border overflow-hidden">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <span>Your Habits</span>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-6 px-2 text-xs"
                    onClick={() => setIsHabitsExpanded(!isHabitsExpanded)}
                  >
                    {isHabitsExpanded ? 'Collapse' : 'Expand'}
                  </Button>
                </CardTitle>
                <CardDescription>
                  Complete these daily to earn points and maintain your streak
                </CardDescription>
              </div>
              {(streak.mode.includes('75_hard') || streak.mode === 'custom') && (
                <div className="flex flex-col sm:flex-row gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => navigate(`/streak/${streakId}/habits`)}
                  >
                    <Target className="w-4 h-4 mr-2" />
                    Manage Habits
                  </Button>
                  <HabitCountdown streakStartDate={streak.start_date} />
                </div>
              )}
            </CardHeader>
            <CardContent className={`transition-all duration-300 ${isHabitsExpanded ? 'pt-4' : 'pt-0'}`}>
              <div className={`space-y-3 relative ${isHabitsExpanded ? '' : 'max-h-[120px] overflow-hidden'}`}>
                {habits.map((habit) => (
                  <div key={habit.id} className="flex flex-col sm:flex-row sm:items-center justify-between p-3 border rounded-lg border-card-border space-y-2 sm:space-y-0">
                    <div className="flex-1">
                      <h4 className="font-medium">{habit.title}</h4>
                      <p className="text-sm text-muted-foreground">{habit.description}</p>
                    </div>
                    <div className="flex items-center gap-2 self-start sm:self-auto">
                      <span className="text-sm font-medium">{habit.points} pts</span>
                      <Badge variant="secondary">{habit.category}</Badge>
                    </div>
                  </div>
                ))}
                {!isHabitsExpanded && habits.length > 2 && (
                  <div className="absolute bottom-0 left-0 right-0 h-12 bg-gradient-to-t from-background to-transparent pointer-events-none" />
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-4 lg:space-y-6 order-1 lg:order-last">
          {/* Streak Circle */}
          <Card className="border-card-border">
            <CardContent className="p-4 lg:p-6">
              <div className="flex flex-col items-center space-y-4">
                <StreakCircle 
                  day={currentDay} 
                  state={currentDay <= streak.duration_days ? "current" : "complete"}
                  className="text-3xl lg:text-4xl w-24 h-24 lg:w-32 lg:h-32"
                />
                <div className="text-center">
                  <div className="text-lg font-semibold">
                    Day {currentDay}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {Math.round(progressPercentage)}% Complete
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Daily Inspiration */}
          <InspireSection currentDay={currentDay} />
        </div>
      </div>

      {/* Streakmates Section - Moved to bottom for mobile */}
      <Card className="border-card-border mt-8">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5 text-primary" />
            Streakmates ({members.length})
          </CardTitle>
          <CardDescription>
            Your fellow challenge participants
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {members.map((member) => {
              const isLeft = member.status === 'left';
              const isEliminated = member.status === 'eliminated';
              const isInactive = isLeft || isEliminated;
              
              return (
                <div key={member.user_id} className={`flex items-center justify-between p-3 rounded-lg cursor-pointer ${
                  isInactive ? 'bg-muted/30 opacity-60' : 'bg-muted/50'
                }`} onClick={() => setSelectedMember(member)}>
                  <div className="flex items-center gap-3 min-w-0 flex-1">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                      isInactive 
                        ? 'bg-muted border-2 border-dashed border-muted-foreground/30' 
                        : 'bg-gradient-to-r from-primary/20 to-primary/40'
                    }`}>
                      {isLeft ? (
                        <LogOut className="w-4 h-4 text-muted-foreground" />
                      ) : isEliminated ? (
                        <X className="w-4 h-4 text-red-500" />
                      ) : (
                        <span className="font-medium text-primary">
                          {member.display_name?.charAt(0) || "U"}
                        </span>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className={`font-medium truncate ${isInactive ? 'text-muted-foreground' : ''}`}>
                          {member.display_name || "Anonymous"}
                        </h4>
                        {isLeft && (
                          <Badge variant="secondary" className="text-xs">
                            <LogOut className="w-3 h-3 mr-1" />
                            Left
                          </Badge>
                        )}
                        {isEliminated && (
                          <Badge variant="destructive" className="text-xs">
                            <X className="w-3 h-3 mr-1" />
                            Eliminated
                          </Badge>
                        )}
                      </div>
                      <p className={`text-sm ${isInactive ? 'text-muted-foreground/70' : 'text-muted-foreground'}`}>
                        {member.total_points} pts • {isInactive ? 'Final: ' : ''}Day {member.current_streak}
                        {isLeft && member.left_at && (
                          <span className="ml-2 text-xs">
                            Left {new Date(member.left_at).toLocaleDateString()}
                          </span>
                        )}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {member.role === "admin" && !isInactive && (
                      <Badge variant="outline" className="text-xs hidden sm:flex">
                        <Crown className="w-3 h-3 mr-1" />
                        Admin
                      </Badge>
                    )}
                    {!isInactive && (
                      <div className="text-right text-sm">
                        <div className="flex items-center gap-1">
                          <Heart className="w-3 h-3 text-red-500" />
                          <span>{streak.points_to_hearts_enabled ? member.hearts_available : member.lives_remaining}</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Admin Settings - Hidden at bottom */}
      {isAdmin && (
        <div className="mt-8 pt-6 border-t border-gray-200">
          <Card className="border-gray-200 bg-gray-50">
            <CardHeader>
              <CardTitle className="text-sm text-gray-600 flex items-center gap-2">
                <Settings className="w-4 h-4" />
                Admin Settings
              </CardTitle>
              <CardDescription className="text-xs text-gray-500">
                Manage streak settings and members
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap gap-3">
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50">
                      <Trash2 className="w-4 h-4 mr-2" />
                      Delete Streak
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Delete Streak</AlertDialogTitle>
                      <AlertDialogDescription>
                        Are you sure you want to delete this streak? This action cannot be undone and will remove all data for all members.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction
                        onClick={handleDeleteStreak}
                        disabled={isDeleting}
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                      >
                        {isDeleting ? "Deleting..." : "Delete Streak"}
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
                
                <Button variant="outline" size="sm">
                  <Users className="w-4 h-4 mr-2" />
                  Manage Members
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      <CheckInModal
        open={isCheckInDialogOpen}
        onOpenChange={setIsCheckInDialogOpen}
        streakId={streakId}
        dayNumber={getCurrentDayNumber()}
        habits={habits}
        todayCheckin={todayCheckin}
        mode={streak.mode}
        onCheckInComplete={handleCheckInComplete}
      />

      <StreakmateHabitsModal
        open={!!selectedMember}
        onOpenChange={(open) => !open && setSelectedMember(null)}
        member={{
          ...selectedMember!,
          habits: selectedMember ? habits.map(h => ({
            id: h.id,
            title: h.title,
            description: h.description,
            points: h.points,
            category: h.category
          })) : []
        }}
      />
    </div>
  );
}