import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { useSuperAdmin } from '@/hooks/useSuperAdmin';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { PageHeader } from '@/components/layout/page-header';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  Shield, 
  Users, 
  Settings, 
  BarChart3, 
  Database,
  ArrowLeft,
  UserCheck,
  FileText,
  Cog,
  User,
  LogOut
} from 'lucide-react';

interface AdminStats {
  totalUsers: number;
  totalStreaks: number;
  activeStreaks: number;
  totalCheckins: number;
}

export default function AdminDashboard() {
  const navigate = useNavigate();
  const { user: currentUser } = useAuth();
  const { isSuperAdmin, loading: superAdminLoading } = useSuperAdmin();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<AdminStats>({
    totalUsers: 0,
    totalStreaks: 0,
    activeStreaks: 0,
    totalCheckins: 0
  });

  useEffect(() => {
    if (!superAdminLoading) {
      if (!isSuperAdmin) {
        toast.error("Access denied. Super admin privileges required.");
        navigate("/app");
      }
      setLoading(false);
    }
  }, [isSuperAdmin, superAdminLoading, navigate]);

  useEffect(() => {
    if (isSuperAdmin) {
      loadAdminStats();
    }
  }, [isSuperAdmin]);

  const loadAdminStats = async () => {
    try {
      // Get total users
      const { count: userCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true });

      // Get total streaks
      const { count: streakCount } = await supabase
        .from('sz_streaks')
        .select('*', { count: 'exact', head: true });

      // Get active streaks
      const { count: activeStreakCount } = await supabase
        .from('sz_streaks')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      // Get total check-ins
      const { count: checkinCount } = await supabase
        .from('sz_checkins')
        .select('*', { count: 'exact', head: true });

      setStats({
        totalUsers: userCount || 0,
        totalStreaks: streakCount || 0,
        activeStreaks: activeStreakCount || 0,
        totalCheckins: checkinCount || 0
      });
    } catch (error) {
      console.error('Error loading admin stats:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Loading admin dashboard...</p>
        </div>
      </div>
    );
  }

  if (!isSuperAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Shield className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h2 className="text-2xl font-bold mb-2">Access Denied</h2>
          <p className="text-muted-foreground">Super admin privileges required</p>
          <Button 
            variant="outline" 
            onClick={() => navigate("/app")}
            className="mt-4"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to App
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-6 max-w-7xl">
      <PageHeader
        title="Admin Dashboard"
        subtitle="Super admin control panel"
        showBackButton={true}
        backTo="/app"
        showLogo={true}
      >
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
              <User className="w-4 h-4 text-white" />
            </div>
            <div className="text-sm">
              <p className="font-medium text-gray-900">
                {currentUser?.user_metadata?.first_name || currentUser?.email?.split('@')[0]} 
                {currentUser?.user_metadata?.last_name && ` ${currentUser.user_metadata.last_name}`}
              </p>
              <p className="text-xs text-gray-500">{currentUser?.email}</p>
            </div>
          </div>
          <Badge variant="secondary" className="bg-purple-100 text-purple-800">
            <Shield className="w-3 h-3 mr-1" />
            Super Admin
          </Badge>
          <Button 
            variant="outline" 
            size="sm"
            onClick={async () => {
              await supabase.auth.signOut();
              navigate('/auth');
            }}
            className="text-red-600 border-red-200 hover:bg-red-50"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Logout
          </Button>
        </div>
      </PageHeader>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalUsers}</div>
            <p className="text-xs text-muted-foreground">
              Registered users
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Streaks</CardTitle>
            <BarChart3 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalStreaks}</div>
            <p className="text-xs text-muted-foreground">
              All time streaks
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Streaks</CardTitle>
            <UserCheck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeStreaks}</div>
            <p className="text-xs text-muted-foreground">
              Currently running
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Check-ins</CardTitle>
            <Database className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalCheckins}</div>
            <p className="text-xs text-muted-foreground">
              All time check-ins
            </p>
          </CardContent>
        </Card>
        </div>

      {/* Admin Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* User Management */}
        <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => navigate('/admin/users')}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-blue-600" />
              User Management
            </CardTitle>
            <CardDescription>
              Manage users, roles, and permissions
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Badge variant="secondary">Users</Badge>
                <Badge variant="secondary">Roles</Badge>
                <Badge variant="secondary">Permissions</Badge>
              </div>
              <Button className="w-full" variant="outline">
                Manage Users
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Streak Management */}
        <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => navigate('/admin/streaks')}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="w-5 h-5 text-green-600" />
              Streak Management
            </CardTitle>
            <CardDescription>
              Manage streaks, users, and mark completions
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Badge variant="secondary">Streaks</Badge>
                <Badge variant="secondary">Users</Badge>
                <Badge variant="secondary">Habits</Badge>
                <Badge variant="secondary">Completion</Badge>
              </div>
              <Button className="w-full" variant="outline">
                Manage Streaks
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Admin Profile */}
        <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => navigate('/profile')}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="w-5 h-5 text-purple-600" />
              Admin Profile
            </CardTitle>
            <CardDescription>
              View and manage your admin profile
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Badge variant="secondary">Profile</Badge>
                <Badge variant="secondary">Settings</Badge>
                <Badge variant="secondary">Account</Badge>
              </div>
              <Button className="w-full" variant="outline">
                View Profile
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Template Management */}
        <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => navigate('/admin/templates')}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5 text-green-600" />
              Template Management
            </CardTitle>
            <CardDescription>
              Manage habit templates and configurations
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Badge variant="secondary">Templates</Badge>
                <Badge variant="secondary">Habits</Badge>
                <Badge variant="secondary">Points</Badge>
              </div>
              <Button className="w-full" variant="outline">
                Manage Templates
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* System Settings */}
        <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={() => navigate('/admin/settings')}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5 text-purple-600" />
              System Settings
            </CardTitle>
            <CardDescription>
              Configure system-wide settings and preferences
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Badge variant="secondary">Config</Badge>
                <Badge variant="secondary">Features</Badge>
                <Badge variant="secondary">Maintenance</Badge>
              </div>
              <Button className="w-full" variant="outline">
                System Settings
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card className="mt-8">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Cog className="w-5 h-5" />
            Quick Actions
          </CardTitle>
          <CardDescription>
            Common admin tasks and maintenance
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Button variant="outline" onClick={() => navigate('/admin/users')}>
              <Users className="w-4 h-4 mr-2" />
              View All Users
            </Button>
            <Button variant="outline" onClick={() => navigate('/admin/templates')}>
              <FileText className="w-4 h-4 mr-2" />
              Manage Templates
            </Button>
            <Button variant="outline" onClick={() => navigate('/admin/settings')}>
              <Settings className="w-4 h-4 mr-2" />
              System Settings
            </Button>
            <Button variant="outline" onClick={loadAdminStats}>
              <BarChart3 className="w-4 h-4 mr-2" />
              Refresh Stats
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
