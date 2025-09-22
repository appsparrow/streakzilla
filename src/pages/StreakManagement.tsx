import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { useSuperAdmin } from '@/hooks/useSuperAdmin';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { PageHeader } from '@/components/layout/page-header';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  ArrowLeft, 
  Users, 
  Target, 
  CheckCircle, 
  Search, 
  Plus,
  User,
  Calendar,
  Heart,
  Zap
} from 'lucide-react';

interface Streak {
  id: string;
  name: string;
  mode: string;
  start_date: string;
  duration_days: number;
  is_active: boolean;
}

interface User {
  id: string;
  email: string;
  first_name?: string;
  last_name?: string;
}

interface Habit {
  id: string;
  description: string;
  points: number;
  category: string;
}

interface StreakMember {
  user_id: string;
  role: string;
  status: string;
  current_streak: number;
  total_points: number;
  hearts_available: number;
  hearts_earned: number;
  hearts_used: number;
  profiles: {
    email: string;
  };
}

export default function StreakManagement() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { isSuperAdmin, loading: superAdminLoading } = useSuperAdmin();
  
  // State management
  const [streaks, setStreaks] = useState<Streak[]>([]);
  const [selectedStreak, setSelectedStreak] = useState<string>('');
  const [streakMembers, setStreakMembers] = useState<StreakMember[]>([]);
  const [availableHabits, setAvailableHabits] = useState<Habit[]>([]);
  const [selectedHabits, setSelectedHabits] = useState<string[]>([]);
  const [userHabits, setUserHabits] = useState<Record<string, string[]>>({});
  const [userSearchId, setUserSearchId] = useState('');
  const [foundUser, setFoundUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('users');

  // Redirect if not super admin
  useEffect(() => {
    if (!superAdminLoading && !isSuperAdmin) {
      toast.error("Access denied. Super admin privileges required.");
      navigate("/app");
    }
  }, [isSuperAdmin, superAdminLoading, navigate]);

  // Load streaks on component mount
  useEffect(() => {
    loadStreaks();
  }, []);

  // Load streak members and habits when streak is selected
  useEffect(() => {
    if (selectedStreak) {
      loadStreakMembers();
      loadAvailableHabits();
    }
  }, [selectedStreak]);

  const loadStreaks = async () => {
    try {
      const { data, error } = await supabase
        .from('sz_streaks')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setStreaks(data || []);
    } catch (error) {
      console.error('Error loading streaks:', error);
      toast.error('Failed to load streaks');
    }
  };

  const loadStreakMembers = async () => {
    if (!selectedStreak) return;

    try {
      console.log('Loading members for streak:', selectedStreak);
      
      // First, get streak members
      const { data: membersData, error: membersError } = await supabase
        .from('sz_streak_members')
        .select(`
          user_id,
          role,
          status,
          current_streak,
          total_points,
          hearts_available,
          hearts_earned,
          hearts_used
        `)
        .eq('streak_id', selectedStreak);

      if (membersError) {
        console.error('Members error:', membersError);
        throw membersError;
      }

      console.log('Members data:', membersData);

      if (!membersData || membersData.length === 0) {
        console.log('No members found');
        setStreakMembers([]);
        return;
      }

      // Then, get user profiles for these members
      const userIds = membersData.map(member => member.user_id);
      console.log('User IDs to fetch:', userIds);
      
      const { data: profilesData, error: profilesError } = await supabase
        .from('profiles')
        .select('id, email')
        .in('id', userIds);

      if (profilesError) {
        console.error('Profiles error:', profilesError);
        throw profilesError;
      }

      console.log('Profiles data:', profilesData);

      // Combine the data
      const combinedData = membersData.map(member => ({
        ...member,
        profiles: profilesData?.find(profile => profile.id === member.user_id) || { email: 'Unknown' }
      }));

      console.log('Combined data:', combinedData);
      setStreakMembers(combinedData);
    } catch (error) {
      console.error('Error loading streak members:', error);
      toast.error('Failed to load streak members');
    }
  };

  const loadAvailableHabits = async () => {
    try {
      const { data, error } = await supabase
        .from('sz_habits')
        .select('*')
        .order('category', { ascending: true });

      if (error) throw error;
      setAvailableHabits(data || []);
    } catch (error) {
      console.error('Error loading habits:', error);
      toast.error('Failed to load habits');
    }
  };

  const searchUser = async () => {
    if (!userSearchId.trim()) {
      toast.error('Please enter a user ID');
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, email')
        .eq('id', userSearchId.trim())
        .single();

      if (error) throw error;
      setFoundUser(data);
      toast.success('User found!');
    } catch (error) {
      console.error('Error searching user:', error);
      toast.error('User not found');
      setFoundUser(null);
    } finally {
      setLoading(false);
    }
  };

  const addUserToStreak = async () => {
    if (!selectedStreak || !foundUser) {
      toast.error('Please select a streak and find a user');
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('admin_add_user_to_streak', {
        p_streak_id: selectedStreak,
        p_user_id: foundUser.id,
        p_role: 'member'
      });

      if (error) throw error;
      
      if (data.success) {
        toast.success(data.message);
        setFoundUser(null);
        setUserSearchId('');
        loadStreakMembers();
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('Error adding user to streak:', error);
      toast.error(error.message || 'Failed to add user to streak');
    } finally {
      setLoading(false);
    }
  };

  const assignHabitsToUser = async (userId: string) => {
    if (selectedHabits.length === 0) {
      toast.error('Please select habits to assign');
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('admin_assign_habits_to_user', {
        p_streak_id: selectedStreak,
        p_user_id: userId,
        p_habit_ids: selectedHabits
      });

      if (error) throw error;
      
      if (data.success) {
        toast.success(data.message);
        setSelectedHabits([]);
        loadStreakMembers();
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('Error assigning habits:', error);
      toast.error(error.message || 'Failed to assign habits');
    } finally {
      setLoading(false);
    }
  };

  const markUserCompleteUntilToday = async (userId: string) => {
    if (!selectedStreak) {
      toast.error('Please select a streak');
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('admin_mark_user_complete_until_today', {
        p_streak_id: selectedStreak,
        p_user_id: userId
      });

      if (error) throw error;
      
      if (data.success) {
        toast.success(`${data.message}! Earned ${data.total_points} points and ${data.hearts_earned} hearts for ${data.days_completed} days.`);
        loadStreakMembers();
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('Error marking user complete:', error);
      toast.error(error.message || 'Failed to mark user complete');
    } finally {
      setLoading(false);
    }
  };

  const handleHabitToggle = (habitId: string) => {
    setSelectedHabits(prev => 
      prev.includes(habitId) 
        ? prev.filter(id => id !== habitId)
        : [...prev, habitId]
    );
  };

  const handleUserHabitToggle = (userId: string, habitId: string) => {
    setUserHabits(prev => {
      const currentHabits = prev[userId] || [];
      const newHabits = currentHabits.includes(habitId)
        ? currentHabits.filter(id => id !== habitId)
        : [...currentHabits, habitId];
      
      return {
        ...prev,
        [userId]: newHabits
      };
    });
  };

  const assignHabitsToSpecificUser = async (userId: string) => {
    const userSelectedHabits = userHabits[userId] || [];
    
    if (userSelectedHabits.length === 0) {
      toast.error('Please select habits for this user');
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('admin_assign_habits_to_user', {
        p_streak_id: selectedStreak,
        p_user_id: userId,
        p_habit_ids: userSelectedHabits
      });

      if (error) throw error;
      
      if (data.success) {
        toast.success(data.message);
        // Clear this user's selected habits
        setUserHabits(prev => {
          const updated = { ...prev };
          delete updated[userId];
          return updated;
        });
        loadStreakMembers();
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      console.error('Error assigning habits:', error);
      toast.error(error.message || 'Failed to assign habits');
    } finally {
      setLoading(false);
    }
  };

  if (superAdminLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!isSuperAdmin) {
    return null;
  }

  return (
    <div className="container mx-auto p-4 max-w-6xl">
      <PageHeader
        title="Streak Management"
        subtitle="Manage users, habits, and mark completions"
      >
        <Button variant="ghost" onClick={() => navigate("/admin")}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Admin
        </Button>
      </PageHeader>

      <div className="grid gap-6">
        {/* Streak Selection */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="w-5 h-5" />
              Select Streak
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex gap-4 items-end">
              <div className="flex-1">
                <Label htmlFor="streak-select">Streak</Label>
                <Select value={selectedStreak} onValueChange={setSelectedStreak}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a streak" />
                  </SelectTrigger>
                  <SelectContent>
                    {streaks.map((streak) => (
                      <SelectItem key={streak.id} value={streak.id}>
                        {streak.name} ({streak.mode}) - {new Date(streak.start_date).toLocaleDateString()}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              {selectedStreak && (
                <Badge variant="outline" className="mb-2">
                  {streakMembers.length} members
                </Badge>
              )}
            </div>
          </CardContent>
        </Card>

        {selectedStreak && (
          <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="users">Users</TabsTrigger>
              <TabsTrigger value="habits">Habits</TabsTrigger>
              <TabsTrigger value="complete">Mark Complete</TabsTrigger>
            </TabsList>

            {/* Users Tab */}
            <TabsContent value="users" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Users className="w-5 h-5" />
                    Add Users to Streak
                  </CardTitle>
                  <CardDescription>
                    Search for users by ID and add them to the selected streak
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex gap-4">
                    <div className="flex-1">
                      <Label htmlFor="user-search">User ID</Label>
                      <Input
                        id="user-search"
                        placeholder="Enter user ID (UUID)"
                        value={userSearchId}
                        onChange={(e) => setUserSearchId(e.target.value)}
                      />
                    </div>
                    <Button onClick={searchUser} disabled={loading} className="self-end">
                      <Search className="w-4 h-4 mr-2" />
                      Search
                    </Button>
                  </div>

                  {foundUser && (
                    <div className="p-4 border rounded-lg bg-green-50">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium">{foundUser.email}</p>
                          <p className="text-sm text-muted-foreground">ID: {foundUser.id}</p>
                        </div>
                        <Button onClick={addUserToStreak} disabled={loading}>
                          <Plus className="w-4 h-4 mr-2" />
                          Add to Streak
                        </Button>
                      </div>
                    </div>
                  )}

                  {/* Current Members */}
                  <div className="mt-6">
                    <h3 className="font-medium mb-3">Current Members</h3>
                    <div className="space-y-2">
                      {streakMembers.map((member) => (
                        <div key={member.user_id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex items-center gap-3">
                            <User className="w-4 h-4 text-muted-foreground" />
                            <div>
                              <p className="font-medium">{member.profiles.email}</p>
                              <p className="text-sm text-muted-foreground">ID: {member.user_id}</p>
                              <div className="flex gap-4 text-sm text-muted-foreground">
                                <span>Role: {member.role}</span>
                                <span>Streak: {member.current_streak}</span>
                                <span>Points: {member.total_points}</span>
                                <span className="flex items-center gap-1">
                                  <Heart className="w-3 h-3" />
                                  {member.hearts_available}
                                </span>
                              </div>
                            </div>
                          </div>
                          <Badge variant={member.status === 'active' ? 'default' : 'secondary'}>
                            {member.status}
                          </Badge>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Habits Tab */}
            <TabsContent value="habits" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Target className="w-5 h-5" />
                    Assign Habits to Individual Users
                  </CardTitle>
                  <CardDescription>
                    Select specific habits for each user individually
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {streakMembers.length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <Users className="w-12 h-12 mx-auto mb-4 opacity-50" />
                      <p>No users in this streak yet. Add users first.</p>
                    </div>
                  ) : (
                    streakMembers.map((member) => (
                      <div key={member.user_id} className="border rounded-lg p-4">
                        <div className="flex items-center justify-between mb-4">
                          <div>
                            <h3 className="font-medium">{member.profiles.email}</h3>
                            <p className="text-sm text-muted-foreground">ID: {member.user_id}</p>
                          </div>
                          <div className="flex gap-2">
                            <Badge variant="outline">
                              {userHabits[member.user_id]?.length || 0} habits selected
                            </Badge>
                            <Button
                              size="sm"
                              onClick={() => assignHabitsToSpecificUser(member.user_id)}
                              disabled={loading || !userHabits[member.user_id]?.length}
                            >
                              Assign Habits
                            </Button>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                          {availableHabits.map((habit) => (
                            <div key={`${member.user_id}-${habit.id}`} className="flex items-center space-x-2 p-2 border rounded">
                              <Checkbox
                                id={`${member.user_id}-${habit.id}`}
                                checked={userHabits[member.user_id]?.includes(habit.id) || false}
                                onCheckedChange={() => handleUserHabitToggle(member.user_id, habit.id)}
                              />
                              <div className="flex-1">
                                <Label htmlFor={`${member.user_id}-${habit.id}`} className="text-sm font-medium cursor-pointer">
                                  {habit.description}
                                </Label>
                                <div className="flex gap-2 text-xs text-muted-foreground">
                                  <Badge variant="outline" className="text-xs">{habit.category}</Badge>
                                  <span>{habit.points} pts</span>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            {/* Mark Complete Tab */}
            <TabsContent value="complete" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <CheckCircle className="w-5 h-5" />
                    Mark Users Complete Until Today
                  </CardTitle>
                  <CardDescription>
                    Mark users as complete for all days from streak start to today
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {streakMembers.map((member) => (
                      <div key={member.user_id} className="flex items-center justify-between p-4 border rounded-lg">
                        <div className="flex items-center gap-4">
                          <User className="w-5 h-5 text-muted-foreground" />
                          <div>
                            <p className="font-medium">{member.profiles.email}</p>
                            <p className="text-sm text-muted-foreground">ID: {member.user_id}</p>
                            <div className="flex gap-4 text-sm text-muted-foreground">
                              <span className="flex items-center gap-1">
                                <Calendar className="w-3 h-3" />
                                Current: {member.current_streak} days
                              </span>
                              <span className="flex items-center gap-1">
                                <Zap className="w-3 h-3" />
                                {member.total_points} points
                              </span>
                              <span className="flex items-center gap-1">
                                <Heart className="w-3 h-3" />
                                {member.hearts_available} hearts
                              </span>
                            </div>
                          </div>
                        </div>
                        <Button
                          onClick={() => markUserCompleteUntilToday(member.user_id)}
                          disabled={loading}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="w-4 h-4 mr-2" />
                          Mark Complete
                        </Button>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        )}
      </div>
    </div>
  );
}
