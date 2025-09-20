import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { StreakCircle } from "@/components/ui/streak-circle";
import { PageHeader } from "@/components/layout/page-header";
import { 
  Calendar, 
  Users, 
  Heart, 
  Share2, 
  LogOut, 
  Camera,
  TrendingUp,
  Award,
  CheckCircle2
} from "lucide-react";

// Mock data - will be replaced with real data
const mockStreak = {
  id: "1",
  name: "75 Hard Challenge",
  mode: "75 Hard",
  duration: 75,
  currentDay: 23,
  startDate: "2024-01-01",
  livesRemaining: 2,
  totalPoints: 450,
  completedToday: false,
  powers: [
    { id: "1", name: "Drink 1 gallon of water", completed: false },
    { id: "2", name: "Two 45-min workouts", completed: false },
    { id: "3", name: "Read 10 pages", completed: true },
    { id: "4", name: "Follow a diet", completed: false },
    { id: "5", name: "Take a progress photo", completed: false }
  ]
};

const mockStreakmates = [
  {
    id: "1",
    name: "Sarah Chen",
    avatar: "/avatars/sarah.jpg",
    streak: 23,
    points: 520,
    completedToday: true
  },
  {
    id: "2", 
    name: "Mike Johnson",
    avatar: "/avatars/mike.jpg",
    streak: 21,
    points: 480,
    completedToday: false
  },
  {
    id: "3",
    name: "Emma Davis", 
    avatar: "/avatars/emma.jpg",
    streak: 23,
    points: 445,
    completedToday: true
  }
];

const mockWeeklyData = [
  { day: "Mon", points: 85, missed: false },
  { day: "Tue", points: 90, missed: false },
  { day: "Wed", points: 0, missed: true },
  { day: "Thu", points: 80, missed: false },
  { day: "Fri", points: 95, missed: false },
  { day: "Sat", points: 85, missed: false },
  { day: "Sun", points: 90, missed: false }
];

export default function StreakDashboard() {
  const [showCheckInModal, setShowCheckInModal] = useState(false);
  const [selectedPowers, setSelectedPowers] = useState<string[]>([]);

  // Generate streak circles
  const generateStreakCircles = () => {
    const circles = [];
    for (let i = 1; i <= mockStreak.duration; i++) {
      let state: "pending" | "current" | "complete" | "missed" | "life";
      
      if (i < mockStreak.currentDay) {
        // Past days - could be complete, missed, or life used
        state = Math.random() > 0.8 ? "missed" : "complete";
        if (state === "missed" && Math.random() > 0.7) state = "life";
      } else if (i === mockStreak.currentDay) {
        state = "current";
      } else {
        state = "pending";
      }
      
      circles.push(
        <StreakCircle
          key={i}
          day={i}
          state={state}
          onClick={state === "current" ? () => setShowCheckInModal(true) : undefined}
        />
      );
    }
    return circles;
  };

  const maxPoints = Math.max(...mockWeeklyData.map(d => d.points), 100);

  return (
    <div className="container mx-auto p-6 max-w-6xl">
      {/* Motivational Banner */}
      <div className="gradient-primary rounded-2xl p-6 mb-8 text-primary-foreground">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold mb-2">
              {mockStreak.duration - mockStreak.currentDay + 1} Days to Go! 🔥
            </h1>
            <p className="opacity-90 text-lg">
              You're doing amazing! Stay consistent to climb the leaderboard.
            </p>
          </div>
          <div className="text-right">
            <div className="text-3xl font-bold">{mockStreak.currentDay}</div>
            <div className="text-sm opacity-75">Day {mockStreak.currentDay}</div>
          </div>
        </div>
      </div>

      {/* Daily Prompt */}
      <Card className="mb-8 border-card-border bg-gradient-to-r from-accent to-accent/50">
        <CardContent className="p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center">
              <Calendar className="w-6 h-6 text-primary" />
            </div>
            <div className="flex-1">
              <h3 className="text-lg font-semibold mb-1">What did you do today?</h3>
              <p className="text-muted-foreground">
                {new Date().toLocaleDateString('en-US', { 
                  weekday: 'long', 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </p>
            </div>
            <Button 
              onClick={() => setShowCheckInModal(true)}
              className="gradient-progress text-progress-foreground border-0"
              size="lg"
            >
              <CheckCircle2 className="w-5 h-5 mr-2" />
              Check In
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Progress Section */}
        <div className="lg:col-span-2 space-y-6">
          {/* Streak Tracker */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Award className="w-5 h-5 text-primary" />
                {mockStreak.name} Progress
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-10 gap-2 mb-6">
                {generateStreakCircles()}
              </div>
              
              {/* Progress Stats */}
              <div className="grid grid-cols-3 gap-4 p-4 bg-muted/50 rounded-lg">
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary">{mockStreak.currentDay}</div>
                  <div className="text-sm text-muted-foreground">Days Complete</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-success">{mockStreak.totalPoints}</div>
                  <div className="text-sm text-muted-foreground">Total Points</div>
                </div>
                <div className="text-center flex items-center justify-center gap-1">
                  <div className="text-2xl font-bold text-missed">{mockStreak.livesRemaining}</div>
                  <Heart className="w-5 h-5 text-missed fill-current" />
                  <div className="text-sm text-muted-foreground ml-2">Lives Left</div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Weekly Chart */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                Last 7 Days
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-end justify-between gap-2 h-32">
                {mockWeeklyData.map((day, index) => (
                  <div key={index} className="flex-1 flex flex-col items-center">
                    <div 
                      className={`w-full rounded-t transition-all duration-500 ${
                        day.missed ? 'bg-missed' : 'gradient-primary'
                      }`}
                      style={{ 
                        height: `${(day.points / maxPoints) * 100}%`,
                        minHeight: day.points > 0 ? '8px' : '2px'
                      }}
                    />
                    <div className="text-xs text-muted-foreground mt-2">{day.day}</div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Streakmates */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="w-5 h-5 text-primary" />
                Streakmates
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {mockStreakmates.map((mate) => (
                <div key={mate.id} className="flex items-center gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors cursor-pointer">
                  <Avatar className="w-10 h-10">
                    <AvatarImage src={mate.avatar} />
                    <AvatarFallback>{mate.name.split(' ').map(n => n[0]).join('')}</AvatarFallback>
                  </Avatar>
                  <div className="flex-1 min-w-0">
                    <div className="font-medium truncate">{mate.name}</div>
                    <div className="text-sm text-muted-foreground">
                      {mate.points} pts • {mate.streak} days
                    </div>
                  </div>
                  <div className={`w-3 h-3 rounded-full ${
                    mate.completedToday ? 'bg-success' : 'bg-muted'
                  }`} />
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button variant="outline" className="w-full justify-start">
                <Share2 className="w-4 h-4 mr-2" />
                Invite Friends
              </Button>
              <Button variant="outline" className="w-full justify-start">
                <Camera className="w-4 h-4 mr-2" />
                View Photos
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Check-in Modal Placeholder */}
      {showCheckInModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Daily Check-in</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-muted-foreground">Complete your powers for today!</p>
              <div className="space-y-3">
                {mockStreak.powers.map((power) => (
                  <label key={power.id} className="flex items-center gap-3 cursor-pointer">
                    <input 
                      type="checkbox" 
                      checked={selectedPowers.includes(power.id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedPowers([...selectedPowers, power.id]);
                        } else {
                          setSelectedPowers(selectedPowers.filter(id => id !== power.id));
                        }
                      }}
                      className="w-4 h-4"
                    />
                    <span className={power.completed ? 'line-through text-muted-foreground' : ''}>
                      {power.name}
                    </span>
                  </label>
                ))}
              </div>
              <div className="flex gap-3 pt-4">
                <Button 
                  variant="outline" 
                  onClick={() => setShowCheckInModal(false)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button 
                  onClick={() => setShowCheckInModal(false)}
                  className="flex-1 gradient-success text-success-foreground border-0"
                >
                  Complete Check-in
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}