import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/page-header";
import { Plus, Users, Calendar, Crown, Target, User } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";
import { useStreaks } from "@/hooks/useStreaks";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
// Removed complex progress components - using simple progress bar

export default function Home() {
  const navigate = useNavigate();
  const { user, loading: authLoading } = useAuth();
  const { streaks, loading, joinStreak } = useStreaks();
  const [activeTab, setActiveTab] = useState<"active" | "my" | "completed">("active");
  const [joinCode, setJoinCode] = useState("");
  const [isJoining, setIsJoining] = useState(false);
  const [streakMemberCounts, setStreakMemberCounts] = useState<Record<string, number>>({});

  // Fetch member counts for all streaks - MUST be before early return
  useEffect(() => {
    const fetchMemberCounts = async () => {
      if (!user || streaks.length === 0) return;
      
      const counts: Record<string, number> = {};
      
      for (const streak of streaks) {
        try {
          const { count } = await supabase
            .from('sz_streak_members')
            .select('*', { count: 'exact', head: true })
            .eq('streak_id', streak.id);
          
          counts[streak.id] = count || 0;
        } catch (error) {
          console.error('Error fetching member count:', error);
          counts[streak.id] = 1; // fallback
        }
      }
      
      setStreakMemberCounts(counts);
    };

    fetchMemberCounts();
  }, [user, streaks]);

  // Redirect to auth if not authenticated
  useEffect(() => {
    if (!user && !authLoading) {
      navigate("/auth");
    }
  }, [user, authLoading, navigate]);

  // Show loading state while checking authentication
  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  // Early return if not authenticated
  if (!user) {
    return null;
  }

  // Categorize streaks
  const activeStreaks = streaks.filter(s => s.is_active && s.current_streak < s.duration_days);
  const myStreaks = streaks.filter(s => s.role === "admin");
  const completedStreaks = streaks.filter(s => s.current_streak >= s.duration_days);
  
  // Get current streaks to display based on active tab
  const getCurrentStreaks = () => {
    switch (activeTab) {
      case "active": return activeStreaks;
      case "my": return myStreaks;
      case "completed": return completedStreaks;
      default: return activeStreaks;
    }
  };

  const handleJoinStreak = async () => {
    if (!joinCode.trim()) return;
    
    setIsJoining(true);
    const success = await joinStreak(joinCode);
    setIsJoining(false);
    
    if (success) {
      setJoinCode("");
    }
  };

  const getCurrentDay = (startDate: string) => {
    const start = new Date(startDate);
    const today = new Date();
    const diffTime = today.getTime() - start.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    return Math.max(1, diffDays + 1);
  };

  const renderStreakCard = (streak: typeof streaks[0]) => {
    const currentDay = getCurrentDay(streak.start_date);
    return (
      <Card 
        key={streak.id} 
        className="hover-lift cursor-pointer group border-card-border bg-card hover:shadow-primary/10"
        onClick={() => navigate(`/streak/${streak.id}`)}
      >
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <CardTitle className="text-xl mb-1 group-hover:text-primary transition-colors">
                {streak.name}
              </CardTitle>
              <div className="flex items-center gap-2">
                <Badge variant="secondary" className="text-xs">
                  {streak.mode}
                </Badge>
                {streak.role === "admin" && (
                  <Badge variant="outline" className="text-xs">
                    <Crown className="w-3 h-3 mr-1" />
                    Admin
                  </Badge>
                )}
              </div>
            </div>
            <div className="flex items-end gap-1">
              <div className="w-3 h-3 rounded-full bg-primary animate-pulse" />
              <div className="text-xs text-muted-foreground">
                ❤️ {streak.hearts_available || streak.lives_remaining}
              </div>
            </div>
          </div>
        </CardHeader>
      
        <CardContent className="pt-0">
          <div className="space-y-4">
            {/* Progress */}
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-muted-foreground">Progress</span>
                <span className="font-medium">
                  Day {currentDay}/{streak.duration_days}
                </span>
              </div>
              <div className="w-full bg-muted h-2 rounded-full overflow-hidden">
                <div 
                  className="h-full gradient-primary transition-all duration-500"
                  style={{ width: `${(currentDay / streak.duration_days) * 100}%` }}
                />
              </div>
            </div>

            {/* Simple Progress Bar */}
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-xs font-medium text-gray-600">Progress</span>
                <span className="text-xs text-gray-500">{currentDay}/{streak.duration_days}</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-1.5">
                <div 
                  className="bg-purple-600 h-1.5 rounded-full transition-all duration-300"
                  style={{ width: `${(currentDay / streak.duration_days) * 100}%` }}
                />
              </div>
            </div>

            {/* Stats - compact */}
            <div className="flex justify-between text-xs sm:text-sm">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1 text-muted-foreground">
                  <Target className="w-4 h-4" />
                  <span>{streak.current_streak} streak</span>
                </div>
                <div className="flex items-center gap-1 text-muted-foreground">
                  <Users className="w-4 h-4" />
                  <span>{streakMemberCounts[streak.id] || 1} members</span>
                </div>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <span className="font-medium">{streak.total_points} pts</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  };

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl">
      <PageHeader
        title="Your Streaks"
        subtitle="Keep the momentum going! Consistency is key to success."
        showLogo={true}
      >
        <Button variant="outline" onClick={() => navigate("/profile")} className="text-xs sm:text-sm">
          <User className="w-4 h-4 mr-1 sm:mr-2" />
          Profile
        </Button>
      </PageHeader>

      {/* Tab Navigation */}
      <div className="flex gap-1 mb-6 p-1 bg-muted rounded-lg w-full sm:w-fit overflow-x-auto">
        <button
          onClick={() => setActiveTab("active")}
          className={`px-3 sm:px-4 py-2 rounded-md text-xs sm:text-sm font-medium transition-all whitespace-nowrap flex-shrink-0 ${
            activeTab === "active"
              ? "bg-primary text-primary-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          Active ({activeStreaks.length})
        </button>
        <button
          onClick={() => setActiveTab("my")}
          className={`px-3 sm:px-4 py-2 rounded-md text-xs sm:text-sm font-medium transition-all whitespace-nowrap flex-shrink-0 ${
            activeTab === "my"
              ? "bg-primary text-primary-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          My Streaks ({myStreaks.length})
        </button>
        <button
          onClick={() => setActiveTab("completed")}
          className={`px-3 sm:px-4 py-2 rounded-md text-xs sm:text-sm font-medium transition-all whitespace-nowrap flex-shrink-0 ${
            activeTab === "completed"
              ? "bg-primary text-primary-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          Completed ({completedStreaks.length})
        </button>
      </div>

      {/* Streak Grid */}
      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-4" />
          <p className="text-muted-foreground">Loading your streaks...</p>
        </div>
      ) : (
        <div className="space-y-6">
          {getCurrentStreaks().length > 0 ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {getCurrentStreaks().map(renderStreakCard)}
              </div>
              
              {/* Action Buttons */}
              <div className="flex gap-3 justify-center pt-4">
                <Button className="gradient-primary text-primary-foreground border-0" onClick={() => navigate("/create")}>
                  <Plus className="w-4 h-4 mr-2" />
                  Create Streak
                </Button>
                <Dialog>
                  <DialogTrigger asChild>
                    <Button variant="outline">
                      <Plus className="w-4 h-4 mr-2" />
                      Join a Streak
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Join a Streak</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div className="space-y-2">
                        <Label>Streak Code</Label>
                        <Input
                          placeholder="Enter 6-character code"
                          value={joinCode}
                          onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                          maxLength={6}
                        />
                      </div>
                      <Button 
                        className="w-full"
                        onClick={handleJoinStreak}
                        disabled={isJoining || joinCode.length !== 6}
                      >
                        {isJoining ? "Joining..." : "Join Streak"}
                      </Button>
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
            </>
          ) : (
            <div className="col-span-full text-center py-12">
              <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
                {activeTab === "active" && <Target className="w-8 h-8 text-muted-foreground" />}
                {activeTab === "my" && <Crown className="w-8 h-8 text-muted-foreground" />}
                {activeTab === "completed" && <Calendar className="w-8 h-8 text-muted-foreground" />}
              </div>
              <h3 className="text-lg font-semibold mb-2">
                {activeTab === "active" && "No active streaks"}
                {activeTab === "my" && "No streaks created yet"}
                {activeTab === "completed" && "No completed streaks"}
              </h3>
              <p className="text-muted-foreground mb-4">
                {activeTab === "active" && "All your streaks are either completed or not started yet."}
                {activeTab === "my" && "Start your journey by creating your first streak challenge!"}
                {activeTab === "completed" && "Complete some streaks to see them here!"}
              </p>
              {activeTab === "my" && (
                <Button className="gradient-primary text-primary-foreground border-0" onClick={() => navigate("/create")}>
                  <Plus className="w-4 h-4 mr-2" />
                  Create Your First Streak
                </Button>
              )}
              {activeTab === "active" && (
                <div className="flex gap-2 justify-center">
                  <Button className="gradient-primary text-primary-foreground border-0" onClick={() => navigate("/create")}>
                    <Plus className="w-4 h-4 mr-2" />
                    Create Streak
                  </Button>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button variant="outline">
                        <Plus className="w-4 h-4 mr-2" />
                        Join a Streak
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Join a Streak</DialogTitle>
                      </DialogHeader>
                      <div className="space-y-4">
                        <div className="space-y-2">
                          <Label>Streak Code</Label>
                          <Input
                            placeholder="Enter 6-character code"
                            value={joinCode}
                            onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                            maxLength={6}
                          />
                        </div>
                        <Button 
                          className="w-full"
                          onClick={handleJoinStreak}
                          disabled={isJoining || joinCode.length !== 6}
                        >
                          {isJoining ? "Joining..." : "Join Streak"}
                        </Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}