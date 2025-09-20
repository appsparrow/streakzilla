import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  Target, 
  Users, 
  Heart, 
  Zap, 
  Calendar, 
  Crown,
  CheckCircle,
  ArrowRight,
  Star,
  TrendingUp,
  Shield,
  Smartphone,
  Globe
} from "lucide-react";
import { useNavigate } from "react-router-dom";

export default function MarketingLanding() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      {/* Navigation */}
      <nav className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img 
              src="/logo-streakzilla-bh.png" 
              alt="Streakzilla" 
              className="h-8 w-auto"
            />
          </div>
          <div className="hidden md:flex items-center gap-6">
            <a href="#features" className="text-sm hover:text-primary transition-colors">Features</a>
            <a href="#pricing" className="text-sm hover:text-primary transition-colors">Pricing</a>
            <a href="#testimonials" className="text-sm hover:text-primary transition-colors">Reviews</a>
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => navigate("/auth")}
            >
              Sign In
            </Button>
            <Button 
              size="sm"
              className="gradient-primary text-primary-foreground border-0"
              onClick={() => navigate("/auth")}
            >
              Get Started
            </Button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <div className="max-w-4xl mx-auto">
          <Badge variant="secondary" className="mb-6">
            🎯 Social Habit Building Platform
          </Badge>
          
          <h1 className="text-5xl sm:text-6xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-primary to-pink-600">
            Build Unbreakable Habits with Friends
          </h1>
          
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Join groups, track progress, and stay motivated with your community. 
            Build good habits and create social groups to encourage and motivate each other.
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
            <Button 
              size="lg" 
              className="gradient-primary text-primary-foreground border-0 text-lg px-8 py-6"
              onClick={() => navigate("/auth")}
            >
              Start Your Streak
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
          
          </div>

          {/* Social Proof */}
          <div className="flex items-center justify-center gap-8 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <div className="flex -space-x-2">
                {[1,2,3,4,5].map((i) => (
                  <div key={i} className="w-8 h-8 rounded-full bg-primary/20 border-2 border-background" />
                ))}
              </div>
              <span>10,000+ active users</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
              <span>4.8/5 rating</span>
            </div>
            <div className="flex items-center gap-2">
              <TrendingUp className="h-4 w-4" />
              <span>95% completion rate</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            Why Choose Streakzilla?
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Our community-focused approach makes habit building fun, social, and sustainable.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Target className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Multiple Habit Categories</CardTitle>
              <CardDescription>
                Choose from various habit categories including fitness, nutrition, 
                learning, and lifestyle habits for every goal.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Users className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Community Support</CardTitle>
              <CardDescription>
                Join groups, share progress, and stay motivated with 
                your community through our social features.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Heart className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Motivation System</CardTitle>
              <CardDescription>
                Earn and share encouragement with your community. Send support 
                and receive motivation when you need it most.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Zap className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Gamified Experience</CardTitle>
              <CardDescription>
                Turn habit building into a game with points, badges, 
                leaderboards, and achievement systems.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Smartphone className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Cross-Platform</CardTitle>
              <CardDescription>
                Access your streaks anywhere with our iOS, Android, 
                and web apps. Sync seamlessly across all devices.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-card-border hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Shield className="h-6 w-6 text-primary" />
              </div>
              <CardTitle>Privacy First</CardTitle>
              <CardDescription>
                Your data is secure with end-to-end encryption. 
                Control your privacy with granular settings.
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* How It Works */}
      <section className="bg-muted/50 py-20">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              How It Works
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Get started in minutes and begin your transformation journey today.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                1
              </div>
              <h3 className="text-xl font-semibold mb-4">Choose Your Challenge</h3>
              <p className="text-muted-foreground">
                Pick from 75 Hard, 75 Hard Plus, or create a custom challenge 
                with habits that matter to you.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                2
              </div>
              <h3 className="text-xl font-semibold mb-4">Join or Create a Group</h3>
              <p className="text-muted-foreground">
                Find your tribe or invite friends to join your streak. 
                Community support makes all the difference.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-2xl font-bold mx-auto mb-6">
                3
              </div>
              <h3 className="text-xl font-semibold mb-4">Track & Celebrate</h3>
              <p className="text-muted-foreground">
                Check in daily, share your progress, and celebrate milestones 
                with your streakmates.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            What Our Users Say
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Join thousands of users who have transformed their lives with Streakzilla.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          <Card className="border-card-border">
            <CardContent className="p-6">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map((i) => (
                  <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                ))}
              </div>
              <p className="text-muted-foreground mb-4">
                "Streakzilla made habit building fun! The community support and 
                gamification kept me motivated through my 75 Hard challenge."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/20" />
                <div>
                  <p className="font-semibold">Sarah M.</p>
                  <p className="text-sm text-muted-foreground">Fitness Enthusiast</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-card-border">
            <CardContent className="p-6">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map((i) => (
                  <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                ))}
              </div>
              <p className="text-muted-foreground mb-4">
                "The heart system and social features are amazing. I love 
                encouraging others and receiving support when I need it."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/20" />
                <div>
                  <p className="font-semibold">Michael R.</p>
                  <p className="text-sm text-muted-foreground">Software Developer</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-card-border">
            <CardContent className="p-6">
              <div className="flex items-center gap-1 mb-4">
                {[1,2,3,4,5].map((i) => (
                  <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                ))}
              </div>
              <p className="text-muted-foreground mb-4">
                "Finally, a habit tracker that's actually fun to use! The 
                progress photos and streak visualization are motivating."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/20" />
                <div>
                  <p className="font-semibold">Jessica L.</p>
                  <p className="text-sm text-muted-foreground">Student</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-r from-primary to-pink-600 py-20">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Ready to Transform Your Life?
          </h2>
          <p className="text-xl text-white/90 mb-8 max-w-2xl mx-auto">
            Join thousands of users who have built unbreakable habits with Streakzilla. 
            Start your journey today!
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button 
              size="lg" 
              variant="secondary"
              className="text-lg px-8 py-6"
              onClick={() => navigate("/auth")}
            >
              Get Started Free
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
            
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-background py-12">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <img 
                  src="/logo-streakzilla-bh.png" 
                  alt="Streakzilla" 
                  className="h-8 w-auto"
                />
              </div>
              <p className="text-muted-foreground">
                Community-focused habit building for individuals and groups who want to build good habits and create social groups for encouragement and motivation.
              </p>
            </div>

            <div>
              <h3 className="font-semibold mb-4">Product</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#features" className="hover:text-primary transition-colors">Features</a></li>
                <li><a href="#pricing" className="hover:text-primary transition-colors">Pricing</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Challenges</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Templates</a></li>
              </ul>
            </div>

            <div>
              <h3 className="font-semibold mb-4">Support</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-primary transition-colors">Help Center</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Community</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Contact</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Status</a></li>
              </ul>
            </div>

            <div>
              <h3 className="font-semibold mb-4">Legal</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="/privacy" className="hover:text-primary transition-colors">Privacy Policy</a></li>
                <li><a href="/terms" className="hover:text-primary transition-colors">Terms of Service</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Cookie Policy</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Disclaimer</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t mt-8 pt-8 text-center text-sm text-muted-foreground">
            <p>
              © 2024 Streakzilla. All rights reserved. | 
              <span className="ml-2 font-medium text-blue-600">
                Community habit building platform - Build better habits together
              </span>
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}