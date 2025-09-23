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
import { useSuperAdmin } from "@/hooks/useSuperAdmin";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { User, Settings, Crown, ArrowLeft, Camera, Trash2, Shield, Users } from "lucide-react";
import { useNavigate } from "react-router-dom";

export default function Profile() {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  const { isSuperAdmin } = useSuperAdmin();
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
        backTo={isSuperAdmin ? "/admin" : "/app"}
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
                onClick={() => navigate('/admin')}
              >
                <Shield className="w-4 h-4 mr-2" />
                Admin Dashboard
              </Button>
            </CardContent>
          </Card>
        )}

        {/* Main Content */}
        <Card className="md:col-span-2 border-card-border">
          <CardHeader>
            <Tabs defaultValue="settings" className="w-full">
              <TabsList className="grid w-full grid-cols-1">
                <TabsTrigger value="settings">
                  <Settings className="w-4 h-4 mr-2" />
                  Settings
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

              {/* Removed My Streaks and Premium tabs for now */}
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}