import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { PageHeader } from "@/components/layout/page-header";
import { useAuth } from "@/hooks/useAuth";
import { useStreaks } from "@/hooks/useStreaks";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { User, Settings, Crown, Zap, ArrowLeft, Camera, Trash2, Shield, Users } from "lucide-react";
import { useNavigate } from "react-router-dom";

export default function Profile() {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  const { streaks, loading } = useStreaks();
  const [profile, setProfile] = useState({
    display_name: user?.user_metadata?.display_name || "",
    full_name: user?.user_metadata?.full_name || "",
    bio: ""
  });
  const [isUpdating, setIsUpdating] = useState(false);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);

  const isPremium = user?.user_metadata?.subscription_status === 'premium';
  const myStreaks = streaks.filter(s => s.role === 'admin');
  const joinedStreaks = streaks.filter(s => s.role === 'member');
  
  // Check if user is super admin
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  
  useEffect(() => {
    checkSuperAdminStatus();
  }, [user]);
  
  const checkSuperAdminStatus = async () => {
    if (!user) return;
    
    const { data, error } = await supabase
      .from("sz_user_roles")
      .select("*")
      .eq("user_id", user.id)
      .eq("role", "super_admin")
      .eq("is_active", true)
      .single();
    
    setIsSuperAdmin(!!data);
  };

  const handleProfileUpdate = async () => {
    if (!user) return;
    
    setIsUpdating(true);
    try {
      let avatar_url = user.user_metadata?.avatar_url;
      
      // Upload avatar if selected
      if (avatarFile) {
        const fileExt = avatarFile.name.split('.').pop();
        const fileName = `${user.id}/avatar.${fileExt}`;
        
        const { error: uploadError } = await supabase.storage
          .from('streak-photos')
          .upload(fileName, avatarFile, { upsert: true });
        
        if (uploadError) throw uploadError;
        
        const { data } = supabase.storage
          .from('streak-photos')
          .getPublicUrl(fileName);
        
        avatar_url = data.publicUrl;
      }

      // Update auth metadata
      const { error: authError } = await supabase.auth.updateUser({
        data: {
          display_name: profile.display_name,
          full_name: profile.full_name,
          avatar_url
        }
      });

      if (authError) throw authError;

      // Update profile table
      const { error: profileError } = await supabase
        .from('profiles')
        .upsert({
          id: user.id,
          display_name: profile.display_name,
          full_name: profile.full_name,
          bio: profile.bio,
          avatar_url
        });

      if (profileError) throw profileError;

      toast.success("Profile updated successfully!");
      setAvatarFile(null);
      setAvatarPreview(null);
    } catch (error: any) {
      console.error('Error updating profile:', error);
      toast.error(error.message || "Failed to update profile");
    } finally {
      setIsUpdating(false);
    }
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        toast.error("Avatar must be less than 5MB");
        return;
      }
      
      setAvatarFile(file);
      const reader = new FileReader();
      reader.onload = () => setAvatarPreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/');
    } catch (error) {
      console.error('Sign out error:', error);
      toast.error("Failed to sign out");
    }
  };

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl">
      <PageHeader
        title="Profile"
        subtitle="Manage your account settings and view your streaks"
        showBackButton={true}
        backTo="/app"
        showLogo={true}
      />

      <div className="grid gap-6 md:grid-cols-3">
        {/* Profile Summary Card */}
        <Card className="md:col-span-1 border-card-border">
          <CardHeader className="text-center">
            <div className="relative mx-auto w-24 h-24 mb-4">
              <Avatar className="w-24 h-24">
                <AvatarImage 
                  src={avatarPreview || user?.user_metadata?.avatar_url} 
                  alt="Profile" 
                />
                <AvatarFallback className="text-2xl">
                  {user?.user_metadata?.display_name?.charAt(0) || user?.email?.charAt(0) || "U"}
                </AvatarFallback>
              </Avatar>
              <label className="absolute -bottom-1 -right-1 p-2 bg-primary rounded-full cursor-pointer hover:bg-primary/90 transition-colors">
                <Camera className="w-3 h-3 text-primary-foreground" />
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleAvatarChange}
                  className="hidden"
                />
              </label>
            </div>
            <CardTitle className="flex items-center justify-center gap-2">
              {profile.display_name || "Anonymous"}
              {isPremium && <Crown className="w-4 h-4 text-yellow-500" />}
            </CardTitle>
            <CardDescription>
              {user?.email}
            </CardDescription>
            <Badge variant={isPremium ? "default" : "secondary"} className="mx-auto">
              {isPremium ? "Premium" : "Free"}
            </Badge>
          </CardHeader>
          <CardContent className="text-center">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <div className="font-semibold text-primary">{myStreaks.length}</div>
                  <div className="text-muted-foreground">Created</div>
                </div>
                <div>
                  <div className="font-semibold text-primary">{joinedStreaks.length}</div>
                  <div className="text-muted-foreground">Joined</div>
                </div>
              </div>
              
              {!isPremium && (
                <Button className="w-full gradient-primary text-primary-foreground border-0" size="sm">
                  <Crown className="w-4 h-4 mr-2" />
                  Upgrade to Premium
                </Button>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Admin Section */}
        {isSuperAdmin && (
          <Card className="md:col-span-1 border-green-200 bg-green-50/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-green-700">
                <Shield className="w-5 h-5" />
                Admin Panel
              </CardTitle>
              <CardDescription>
                Super admin controls and tools
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={() => navigate('/templates')}
              >
                <Settings className="w-4 h-4 mr-2" />
                Template Manager
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start" 
                onClick={() => navigate('/users')}
              >
                <Users className="w-4 h-4 mr-2" />
                User Management
              </Button>
            </CardContent>
          </Card>
        )}

        {/* Main Content */}
        <Card className="md:col-span-2 border-card-border">
          <CardHeader>
            <Tabs defaultValue="settings" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="settings">
                  <Settings className="w-4 h-4 mr-2" />
                  Settings
                </TabsTrigger>
                <TabsTrigger value="my-streaks">My Streaks</TabsTrigger>
                <TabsTrigger value="subscription">
                  <Crown className="w-4 h-4 mr-2" />
                  Premium
                </TabsTrigger>
              </TabsList>
            </Tabs>
          </CardHeader>

          <CardContent>
            <Tabs defaultValue="settings" className="w-full">
              <TabsContent value="settings" className="space-y-6 mt-0">
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="display-name">Display Name</Label>
                    <Input
                      id="display-name"
                      value={profile.display_name}
                      onChange={(e) => setProfile({...profile, display_name: e.target.value})}
                      placeholder="How others see you"
                      className="border-input"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="full-name">Full Name</Label>
                    <Input
                      id="full-name"
                      value={profile.full_name}
                      onChange={(e) => setProfile({...profile, full_name: e.target.value})}
                      placeholder="Your full name"
                      className="border-input"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="bio">Bio</Label>
                    <Input
                      id="bio"
                      value={profile.bio}
                      onChange={(e) => setProfile({...profile, bio: e.target.value})}
                      placeholder="Tell us about yourself"
                      className="border-input"
                    />
                  </div>

                  {avatarPreview && (
                    <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
                      <img src={avatarPreview} alt="Preview" className="w-12 h-12 rounded-full object-cover" />
                      <span className="text-sm text-muted-foreground flex-1">New avatar ready to upload</span>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setAvatarFile(null);
                          setAvatarPreview(null);
                        }}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  )}

                  <div className="flex gap-3">
                    <Button
                      onClick={handleProfileUpdate}
                      disabled={isUpdating}
                      className="gradient-primary text-primary-foreground border-0"
                    >
                      {isUpdating ? "Updating..." : "Save Changes"}
                    </Button>
                    
                    <Button
                      variant="destructive"
                      onClick={handleSignOut}
                    >
                      Sign Out
                    </Button>
                  </div>
                </div>
              </TabsContent>

              <TabsContent value="my-streaks" className="space-y-4 mt-0">
                {loading ? (
                  <div className="text-center py-8">Loading your streaks...</div>
                ) : (
                  <>
                    {myStreaks.length > 0 ? (
                      <div className="space-y-3">
                        {myStreaks.map((streak) => (
                          <Card key={streak.id} className="border-card-border">
                            <CardContent className="p-4">
                              <div className="flex items-center justify-between">
                                <div>
                                  <h4 className="font-medium">{streak.name}</h4>
                                  <p className="text-sm text-muted-foreground">
                                    Day {streak.current_streak} • {streak.total_points} points
                                  </p>
                                </div>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => navigate(`/streak/${streak.id}`)}
                                >
                                  View
                                </Button>
                              </div>
                            </CardContent>
                          </Card>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-8">
                        <p className="text-muted-foreground mb-4">You haven't created any streaks yet</p>
                        <Button onClick={() => navigate('/create')}>
                          Create Your First Streak
                        </Button>
                      </div>
                    )}
                    
                    {joinedStreaks.length > 0 && (
                      <>
                        <h4 className="font-medium mt-6 mb-3">Joined Streaks</h4>
                        <div className="space-y-3">
                          {joinedStreaks.map((streak) => (
                            <Card key={streak.id} className="border-card-border">
                              <CardContent className="p-4">
                                <div className="flex items-center justify-between">
                                  <div>
                                    <h4 className="font-medium">{streak.name}</h4>
                                    <p className="text-sm text-muted-foreground">
                                      Day {streak.current_streak} • {streak.total_points} points
                                    </p>
                                  </div>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => navigate(`/streak/${streak.id}`)}
                                  >
                                    View
                                  </Button>
                                </div>
                              </CardContent>
                            </Card>
                          ))}
                        </div>
                      </>
                    )}
                  </>
                )}
              </TabsContent>

              <TabsContent value="subscription" className="space-y-6 mt-0">
                <div className="space-y-6">
                  {/* Current Plan */}
                  <Card className={`border-2 ${isPremium ? 'border-yellow-500 bg-yellow-50/50' : 'border-border'}`}>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        {isPremium ? <Crown className="w-5 h-5 text-yellow-500" /> : <User className="w-5 h-5" />}
                        {isPremium ? 'Premium Plan' : 'Free Plan'}
                      </CardTitle>
                      <CardDescription>
                        {isPremium ? 'You have access to all premium features' : 'Limited features available'}
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3">
                        {isPremium ? (
                          <>
                            <div className="flex items-center gap-2 text-sm">
                              <Zap className="w-4 h-4 text-green-500" />
                              Unlimited streaks
                            </div>
                            <div className="flex items-center gap-2 text-sm">
                              <Zap className="w-4 h-4 text-green-500" />
                              Custom templates and habits
                            </div>
                            <div className="flex items-center gap-2 text-sm">
                              <Zap className="w-4 h-4 text-green-500" />
                              Daily photo uploads
                            </div>
                            <div className="flex items-center gap-2 text-sm">
                              <Zap className="w-4 h-4 text-green-500" />
                              Priority support
                            </div>
                          </>
                        ) : (
                          <>
                            <div className="text-sm text-muted-foreground">
                              • 1 streak maximum
                            </div>
                            <div className="text-sm text-muted-foreground">
                              • Basic templates only
                            </div>
                            <div className="text-sm text-muted-foreground">
                              • Limited photo uploads
                            </div>
                          </>
                        )}
                      </div>
                    </CardContent>
                  </Card>

                  {/* Upgrade Section */}
                  {!isPremium && (
                    <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-primary/10">
                      <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                          <Crown className="w-5 h-5 text-yellow-500" />
                          Upgrade to Premium
                        </CardTitle>
                        <CardDescription>
                          Unlock unlimited streaks and advanced features
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <div className="space-y-4">
                          <div className="text-3xl font-bold">
                            $9.99<span className="text-lg font-normal text-muted-foreground">/month</span>
                          </div>
                          <Button className="w-full gradient-primary text-primary-foreground border-0" size="lg">
                            <Crown className="w-4 h-4 mr-2" />
                            Upgrade Now
                          </Button>
                          <p className="text-xs text-muted-foreground text-center">
                            Cancel anytime • 7-day free trial
                          </p>
                        </div>
                      </CardContent>
                    </Card>
                  )}
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}