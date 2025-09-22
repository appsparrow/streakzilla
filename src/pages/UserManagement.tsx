import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageHeader } from "@/components/layout/page-header";
import { Users, UserPlus, Shield, Search, Mail, Calendar, Award } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { toast } from "sonner";

interface User {
  id: string;
  email: string;
  created_at: string;
  last_sign_in_at: string | null;
  email_confirmed_at: string | null;
  raw_user_meta_data: any;
  roles: string[];
  streak_count: number;
  total_points: number;
}

interface UserRole {
  id: string;
  user_id: string;
  role: string;
  granted_by: string | null;
  granted_at: string;
  is_active: boolean;
}

export default function UserManagement() {
  const navigate = useNavigate();
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [userRoles, setUserRoles] = useState<UserRole[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);

  useEffect(() => {
    checkSuperAdminStatus();
    loadUsers();
  }, []);

  const checkSuperAdminStatus = async () => {
    if (!currentUser) return;
    
    const { data, error } = await supabase
      .from("sz_user_roles")
      .select("*")
      .eq("user_id", currentUser.id)
      .eq("role", "super_admin")
      .eq("is_active", true)
      .single();
    
    setIsSuperAdmin(!!data);
    
    if (!data) {
      toast.error("Access denied. Super admin privileges required.");
      navigate("/app");
    }
  };

  const loadUsers = async () => {
    try {
      setLoading(true);
      
      // Get users from our custom tables instead of admin API
      const { data: streakMembers, error: membersError } = await supabase
        .from("sz_streak_members")
        .select(`
          user_id,
          joined_at,
          current_streak,
          total_points
        `)
        .order('joined_at', { ascending: false });

      if (membersError) {
        console.error('Error loading streak members:', membersError);
        toast.error("Failed to load users");
        return;
      }

      // Get unique user IDs
      const userIds = [...new Set(streakMembers?.map(m => m.user_id) || [])];

      // Get user details from profiles table
      const { data: usersData, error: usersError } = await supabase
        .from("profiles")
        .select("id, full_name, email, created_at")
        .in('id', userIds);

      if (usersError) {
        console.error('Error loading users:', usersError);
        toast.error("Failed to load user details");
        return;
      }

      // Load user roles
      const { data: rolesData, error: rolesError } = await supabase
        .from("sz_user_roles")
        .select("*");
      
      if (rolesError) {
        toast.error("Failed to load user roles");
        return;
      }

      setUserRoles(rolesData || []);

      // Combine user data with roles and stats
      const usersWithRoles = (usersData || []).map(user => {
        const userRoles = rolesData?.filter(role => role.user_id === user.id) || [];
        const memberData = streakMembers?.find(m => m.user_id === user.id);
        
        // Get user's streak count
        const userStreaks = streakMembers?.filter(m => m.user_id === user.id) || [];
        const streakCount = userStreaks.length;
        const totalPoints = userStreaks.reduce((sum, s) => sum + (s.total_points || 0), 0);
        
        return {
          id: user.id,
          email: user.email || '',
          created_at: user.created_at || '',
          last_sign_in_at: null, // Not available in our custom tables
          email_confirmed_at: null, // Not available in our custom tables
          raw_user_meta_data: {
            full_name: user.full_name || '',
            display_name: user.full_name || user.email?.split('@')[0] || ''
          },
          roles: userRoles.map(role => role.role),
          streak_count: streakCount,
          total_points: totalPoints
        };
      });

      setUsers(usersWithRoles);
    } catch (error) {
      console.error("Error loading users:", error);
      toast.error("Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  const grantRole = async (userId: string, role: string) => {
    try {
      const { error } = await supabase
        .from("sz_user_roles")
        .insert({
          user_id: userId,
          role: role,
          granted_by: currentUser?.id,
          is_active: true
        });

      if (error) {
        toast.error(`Failed to grant ${role} role`);
        return;
      }

      toast.success(`${role} role granted successfully`);
      loadUsers();
    } catch (error) {
      console.error("Error granting role:", error);
      toast.error("Failed to grant role");
    }
  };

  const revokeRole = async (userId: string, role: string) => {
    try {
      const { error } = await supabase
        .from("sz_user_roles")
        .update({ is_active: false })
        .eq("user_id", userId)
        .eq("role", role);

      if (error) {
        toast.error(`Failed to revoke ${role} role`);
        return;
      }

      toast.success(`${role} role revoked successfully`);
      loadUsers();
    } catch (error) {
      console.error("Error revoking role:", error);
      toast.error("Failed to revoke role");
    }
  };

  const filteredUsers = users.filter(user =>
    user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.raw_user_meta_data?.display_name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Loading users...</p>
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
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-6 max-w-7xl">
      <PageHeader
        title="User Management"
        subtitle="Manage user roles and permissions"
        showBackButton={true}
        backTo="/admin"
        showLogo={true}
      />

      {/* Search */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input
            placeholder="Search users by email or name..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-primary" />
              <div className="ml-4">
                <p className="text-sm font-medium text-muted-foreground">Total Users</p>
                <p className="text-2xl font-bold">{users.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Shield className="h-8 w-8 text-green-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-muted-foreground">Super Admins</p>
                <p className="text-2xl font-bold">
                  {users.filter(u => u.roles.includes('super_admin')).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Award className="h-8 w-8 text-blue-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-muted-foreground">Template Creators</p>
                <p className="text-2xl font-bold">
                  {users.filter(u => u.roles.includes('template_creator')).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Calendar className="h-8 w-8 text-purple-600" />
              <div className="ml-4">
                <p className="text-sm font-medium text-muted-foreground">Active Users</p>
                <p className="text-2xl font-bold">
                  {users.filter(u => u.last_sign_in_at && 
                    new Date(u.last_sign_in_at) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
                  ).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Users List */}
      <div className="grid gap-4">
        {filteredUsers.map((user) => (
          <Card key={user.id}>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                    <span className="text-lg font-semibold text-primary">
                      {user.raw_user_meta_data?.display_name?.charAt(0) || user.email.charAt(0).toUpperCase()}
                    </span>
                  </div>
                  
                  <div>
                    <h3 className="font-semibold">
                      {user.raw_user_meta_data?.display_name || 'No name'}
                    </h3>
                    <p className="text-sm text-muted-foreground flex items-center">
                      <Mail className="h-3 w-3 mr-1" />
                      {user.email}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Joined: {new Date(user.created_at).toLocaleDateString()}
                      {user.last_sign_in_at && (
                        <> • Last active: {new Date(user.last_sign_in_at).toLocaleDateString()}</>
                      )}
                    </p>
                  </div>
                </div>
                
                <div className="flex items-center space-x-4">
                  {/* User Stats */}
                  <div className="text-right">
                    <p className="text-sm font-medium">{user.streak_count} streaks</p>
                    <p className="text-sm text-muted-foreground">{user.total_points} points</p>
                  </div>
                  
                  {/* Roles */}
                  <div className="flex flex-wrap gap-2">
                    {user.roles.map((role) => (
                      <Badge key={role} variant={role === 'super_admin' ? 'default' : 'secondary'}>
                        {role}
                      </Badge>
                    ))}
                    {user.roles.length === 0 && (
                      <Badge variant="outline">user</Badge>
                    )}
                  </div>
                  
                  {/* Actions */}
                  <div className="flex space-x-2">
                    {!user.roles.includes('super_admin') && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => grantRole(user.id, 'super_admin')}
                      >
                        <Shield className="h-3 w-3 mr-1" />
                        Grant Admin
                      </Button>
                    )}
                    
                    {user.roles.includes('super_admin') && user.id !== currentUser?.id && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => revokeRole(user.id, 'super_admin')}
                      >
                        <Shield className="h-3 w-3 mr-1" />
                        Revoke Admin
                      </Button>
                    )}
                    
                    {!user.roles.includes('template_creator') && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => grantRole(user.id, 'template_creator')}
                      >
                        <UserPlus className="h-3 w-3 mr-1" />
                        Grant Creator
                      </Button>
                    )}
                    
                    {user.roles.includes('template_creator') && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => revokeRole(user.id, 'template_creator')}
                      >
                        <UserPlus className="h-3 w-3 mr-1" />
                        Revoke Creator
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredUsers.length === 0 && (
        <div className="text-center py-12">
          <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">No users found</h3>
          <p className="text-muted-foreground">
            {searchTerm ? 'Try adjusting your search terms' : 'No users in the system'}
          </p>
        </div>
      )}
    </div>
  );
}
