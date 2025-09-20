import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Target, Users, Heart, Zap, Calendar, Crown } from "lucide-react";
import { useNavigate } from "react-router-dom";

export default function Landing() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-12 sm:py-20">
        <div className="text-center max-w-3xl mx-auto">
          <img 
            src="/logo-streakzilla-bh.png" 
            alt="Streakzilla" 
            className="h-12 w-auto mx-auto mb-8"
          />
          <h1 className="text-4xl sm:text-5xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-primary to-pink-600">
            Build Better Habits Together
          </h1>
          <p className="text-lg sm:text-xl text-muted-foreground mb-8">
            From daily cold showers to 75 Hard challenges, track your streaks and achieve your goals with friends.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button 
              size="lg" 
              className="gradient-primary text-primary-foreground border-0"
              onClick={() => navigate("/create")}
            >
              Start Your Streak
            </Button>
            <Button 
              variant="outline" 
              size="lg"
              onClick={() => navigate("/join")}
            >
              Join a Challenge
            </Button>
          </div>
        </div>
      </div>

      {/* Features Grid */}
      <div className="container mx-auto px-4 py-16">
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          <Card className="border-card-border">
            <CardContent className="p-6">
              <Target className="w-10 h-10 text-primary mb-4" />
              <h3 className="text-xl font-semibold mb-2">Simple Habits</h3>
              <p className="text-muted-foreground">
                Start with daily doodles or cold showers. Build consistency with easy-to-track habits.
              </p>
            </CardContent>
          </Card>

          <Card className="border-card-border">
            <CardContent className="p-6">
              <Users className="w-10 h-10 text-primary mb-4" />
              <h3 className="text-xl font-semibold mb-2">Group Challenges</h3>
              <p className="text-muted-foreground">
                Join friends in 75 Hard or create custom challenges. Stay motivated together.
              </p>
            </CardContent>
          </Card>

          <Card className="border-card-border">
            <CardContent className="p-6">
              <Heart className="w-10 h-10 text-pink-500 mb-4" />
              <h3 className="text-xl font-semibold mb-2">Heart System</h3>
              <p className="text-muted-foreground">
                Earn hearts by completing habits. Use them as extra lives to protect your streak.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Use Cases */}
      <div className="container mx-auto px-4 py-16 text-center">
        <h2 className="text-3xl font-bold mb-12">Perfect For Everyone</h2>
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          <div>
            <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
              <Zap className="w-8 h-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Personal Growth</h3>
            <p className="text-muted-foreground">
              Daily meditation, reading, or exercise. Build habits that stick.
            </p>
          </div>

          <div>
            <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
              <Calendar className="w-8 h-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Creative Projects</h3>
            <p className="text-muted-foreground">
              Daily writing, sketching, or coding. Keep your creativity flowing.
            </p>
          </div>

          <div>
            <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
              <Crown className="w-8 h-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Fitness Goals</h3>
            <p className="text-muted-foreground">
              75 Hard, workout streaks, or nutrition tracking. Transform together.
            </p>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="container mx-auto px-4 py-16 text-center">
        <div className="max-w-2xl mx-auto">
          <h2 className="text-3xl font-bold mb-4">Ready to Start Your Streak?</h2>
          <p className="text-lg text-muted-foreground mb-8">
            Join thousands building better habits and achieving their goals together.
          </p>
          <Button 
            size="lg" 
            className="gradient-primary text-primary-foreground border-0"
            onClick={() => navigate("/create")}
          >
            Create Your First Streak
          </Button>
        </div>
      </div>
    </div>
  );
}
