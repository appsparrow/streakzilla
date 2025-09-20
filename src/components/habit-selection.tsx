import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Plus, Zap, CheckCircle2, Target } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface Habit {
  id: string;
  title: string;
  description: string;
  category: string;
  points: number;
  template_set?: string;
}

interface HabitSelectionProps {
  streakId: string;
  mode: string;
  onComplete: () => void;
}

export function HabitSelection({ streakId, mode, onComplete }: HabitSelectionProps) {
  const [defaultHabits, setDefaultHabits] = useState<Habit[]>([]);
  const [bonusHabits, setBonusHabits] = useState<Habit[]>([]);
  const [selectedHabits, setSelectedHabits] = useState<string[]>([]);
  const [customHabit, setCustomHabit] = useState({
    title: "",
    description: "",
    category: "Custom",
    points: 5
  });
  const [isAddingCustom, setIsAddingCustom] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [canModifyHabits, setCanModifyHabits] = useState(true);
  const [daysSinceStart, setDaysSinceStart] = useState(0);

  useEffect(() => {
    fetchHabits();
    fetchUserSelectedHabits();
    checkModificationAllowed();
  }, [mode, streakId]);

  const checkModificationAllowed = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase.rpc('sz_can_modify_habits', {
        p_streak_id: streakId,
        p_user_id: user.id
      });

      if (error) throw error;
      setCanModifyHabits(data);

      // Also get the number of days since start for display
      const { data: streakData } = await supabase
        .from('sz_streaks')
        .select('start_date')
        .eq('id', streakId)
        .single();

      if (streakData) {
        const startDate = new Date(streakData.start_date);
        const today = new Date();
        const diffTime = Math.abs(today.getTime() - startDate.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        setDaysSinceStart(diffDays);
      }
    } catch (error) {
      console.error('Error checking modification permissions:', error);
    }
  };

  const fetchUserSelectedHabits = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: userHabits, error } = await supabase
        .from('sz_user_habits')
        .select('habit_id')
        .eq('streak_id', streakId)
        .eq('user_id', user.id);

      if (error) throw error;

      if (userHabits) {
        setSelectedHabits(userHabits.map(uh => uh.habit_id));
      }
    } catch (error) {
      console.error('Error fetching user selected habits:', error);
    }
  };

  const fetchHabits = async () => {
    try {
      setLoading(true);
      
      if (mode === 'custom') {
        // For custom mode, show all available habits as selectable
        const { data: allHabits, error: allError } = await supabase
          .from('sz_habits')
          .select('*')
          .neq('template_set', 'custom') // Exclude user-specific custom habits from main list
          .not('template_set', 'like', 'custom_%'); // Exclude user-specific custom habits
        
        if (allError) throw allError;

        // Get user-specific custom habits
        const { data: { user } } = await supabase.auth.getUser();
        const { data: customData, error: customError } = await supabase
          .from('sz_habits')
          .select('*')
          .or(`template_set.eq.custom,template_set.eq.custom_${user?.id || ''}`);

        if (customError) throw customError;

        // For custom mode, all habits are available for selection
        setDefaultHabits(allHabits || []);
        setBonusHabits(customData || []);
      } else {
        // New behavior: load habits via template mappings for the streak's template
        console.log('Fetching streak template_id for streakId:', streakId);
        const { data: streakRow, error: streakError } = await supabase
          .from('sz_streaks')
          .select('template_id')
          .eq('id', streakId)
          .single();

        console.log('Streak row:', streakRow);
        console.log('Streak error:', streakError);

        if (streakRow?.template_id) {
          console.log('Loading habits for template_id:', streakRow.template_id);
          const { data: mappings, error: mapError } = await supabase
            .from('sz_template_habits')
            .select('habit_id, is_core, sort_order, points_override')
            .eq('template_id', streakRow.template_id)
            .order('sort_order', { ascending: true, nullsFirst: false });
          if (mapError) throw mapError;
          console.log('Template mappings:', mappings);

          const habitIds = (mappings || []).map(m => m.habit_id);
          let details: Habit[] = [];
          if (habitIds.length > 0) {
            const { data: habitsData, error: habitsError } = await supabase
              .from('sz_habits')
              .select('*')
              .in('id', habitIds);
            if (habitsError) throw habitsError;
            details = habitsData || [];
          }

          const byId = new Map(details.map(h => [h.id, h]));
          const core = [] as Habit[];
          const bonusFromTemplate = [] as Habit[];
          for (const m of mappings || []) {
            const h = byId.get(m.habit_id);
            if (!h) continue;
            if (m.is_core) core.push(h); else bonusFromTemplate.push(h);
          }

          // Get user-specific custom habits as bonus pool if allowed (we allow everywhere for now)
          const { data: { user } } = await supabase.auth.getUser();
          const { data: customPool } = await supabase
            .from('sz_habits')
            .select('*')
            .or(`template_set.eq.custom,template_set.eq.custom_${user?.id || ''}`);

          console.log('Core habits found:', core);
          console.log('Bonus habits from template:', bonusFromTemplate);
          setDefaultHabits(core);
          setBonusHabits([...(bonusFromTemplate || []), ...(customPool || [])]);
        } else {
          // Fallback to legacy template_set behavior
          console.log('No template_id found, falling back to legacy behavior for mode:', mode);
          const baseMode = mode === '75_hard_plus' ? '75_hard' : mode;
          const { data: defaultData, error: defaultError } = await supabase
            .from('sz_habits')
            .select('*')
            .eq('template_set', baseMode);
          if (defaultError) throw defaultError;

          const { data: { user } } = await supabase.auth.getUser();
          const { data: bonusData } = await supabase
            .from('sz_habits')
            .select('*')
            .or(`template_set.eq.custom,template_set.eq.custom_${user?.id || ''}`);

          console.log('Legacy default habits:', defaultData);
          setDefaultHabits(defaultData || []);
          setBonusHabits(bonusData || []);
        }
      }

      // Don't auto-select - let fetchUserSelectedHabits handle this
    } catch (error) {
      console.error('Error fetching habits:', error);
      toast.error('Failed to load habits');
    } finally {
      setLoading(false);
    }
  };

  const handleHabitToggle = (habitId: string, isDefault: boolean) => {
    if (!canModifyHabits) {
      toast.error('Habit modifications are frozen after 3 days from streak start');
      return;
    }
    
    if (isDefault && (mode === '75_hard' || mode === '75_hard_plus')) {
      // Can't deselect default habits for 75 Hard modes
      return;
    }

    setSelectedHabits(prev => 
      prev.includes(habitId) 
        ? prev.filter(id => id !== habitId)
        : [...prev, habitId]
    );
  };

  const handleAddCustomHabit = async () => {
    if (!customHabit.title.trim()) {
      toast.error('Please enter a habit title');
      return;
    }

    try {
      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Create a user-specific custom habit with unique title
      const uniqueTitle = `${customHabit.title} (${user.id.slice(0, 8)})`;
      
      const { data, error } = await supabase
        .from('sz_habits')
        .insert({
          title: uniqueTitle,
          description: customHabit.description,
          category: customHabit.category,
          points: customHabit.points,
          template_set: `custom_${user.id}` // Make it user-specific
        })
        .select()
        .single();

      if (error) throw error;

      setBonusHabits(prev => [...prev, data]);
      setSelectedHabits(prev => [...prev, data.id]);
      setCustomHabit({ title: "", description: "", category: "Custom", points: 5 });
      setIsAddingCustom(false);
      toast.success('Custom habit added!');
    } catch (error) {
      console.error('Error adding custom habit:', error);
      toast.error('Failed to add custom habit');
    }
  };

  const handleSaveSelection = async () => {
    if (!canModifyHabits) {
      toast.error('Habit modifications are frozen after 3 days from streak start');
      return;
    }

    try {
      setSaving(true);
      
      // Use the updated database function that handles point recalculation
      const { error } = await supabase.rpc('sz_save_user_habits', {
        p_streak_id: streakId,
        p_habit_ids: selectedHabits
      });

      if (error) throw error;

      toast.success('Habits saved successfully! Points have been recalculated.');
      onComplete();
    } catch (error: any) {
      console.error('Error saving habits:', error);
      if (error.message?.includes('frozen after 3 days')) {
        toast.error('Habit modifications are frozen after 3 days from streak start');
      } else {
        toast.error(error.message || 'Failed to save habits');
      }
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Card className="border-card-border">
        <CardContent className="p-6">
          <div className="text-center">
            <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-4" />
            <p className="text-muted-foreground">Loading habits...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const totalPoints = selectedHabits.reduce((sum, habitId) => {
    const habit = [...defaultHabits, ...bonusHabits].find(h => h.id === habitId);
    return sum + (habit?.points || 0);
  }, 0);

  return (
    <div className="space-y-6">
      {/* Freeze Warning */}
      {!canModifyHabits && (
        <Card className="border-yellow-200 bg-yellow-50">
          <CardContent className="p-4">
            <div className="flex items-center gap-2 mb-2">
              <Target className="w-5 h-5 text-yellow-600" />
              <h3 className="font-medium text-yellow-800">Habit Selection Frozen</h3>
            </div>
            <p className="text-sm text-yellow-700">
              Habit modifications are no longer allowed after 3 days from streak start (Day {daysSinceStart}). 
              Your current habit selection is locked in to maintain consistency.
            </p>
          </CardContent>
        </Card>
      )}
      
      {/* Days Remaining Warning */}
      {canModifyHabits && daysSinceStart > 1 && (
        <Card className="border-blue-200 bg-blue-50">
          <CardContent className="p-4">
            <div className="flex items-center gap-2 mb-2">
              <Target className="w-5 h-5 text-blue-600" />
              <h3 className="font-medium text-blue-800">
                {4 - daysSinceStart} Days Left to Modify Habits
              </h3>
            </div>
            <p className="text-sm text-blue-700">
              You can only modify your habit selection for the first 3 days of the streak. 
              Make your final changes soon!
            </p>
          </CardContent>
        </Card>
      )}

      {/* Header */}
      <Card className="border-card-border">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="w-5 h-5 text-primary" />
            Select Your Habits
          </CardTitle>
          <CardDescription>
            Choose the habits you'll commit to for this {mode.replace('_', ' ')} challenge
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div className="text-sm text-muted-foreground">
              {selectedHabits.length} habits selected • {totalPoints} points per day
            </div>
            <Badge variant="secondary" className="ml-2">
              {totalPoints > 55 && `+${totalPoints - 55} bonus points per day`}
            </Badge>
          </div>
        </CardContent>
      </Card>

      {/* Default Habits */}
      {defaultHabits.length > 0 && (
        <Card className="border-card-border">
          <CardHeader>
            <CardTitle className="text-lg">
              {mode === 'custom' ? 'Available Habits' : `Core ${mode.replace('_', ' ')} Habits`}
            </CardTitle>
            <CardDescription>
              {mode === 'custom' 
                ? 'Choose from all available habits to create your custom challenge' 
                : 'These are the essential habits for your challenge'}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {defaultHabits.map((habit) => (
                <div 
                  key={habit.id} 
                  className={`flex items-start gap-3 p-3 border rounded-lg border-card-border ${
                    mode === 'custom' ? 'bg-muted/30' : 'bg-primary/5'
                  } transition-colors ${
                    canModifyHabits && (mode === 'custom' || !((mode === '75_hard' || mode === '75_hard_plus'))) ? 'cursor-pointer hover:bg-primary/10' : 'opacity-75'
                  }`}
                  onClick={() => canModifyHabits && (mode === 'custom' || !((mode === '75_hard' || mode === '75_hard_plus'))) && handleHabitToggle(habit.id, true)}
                >
                  <Checkbox
                    id={`default-${habit.id}`}
                    checked={selectedHabits.includes(habit.id)}
                    onCheckedChange={() => handleHabitToggle(habit.id, true)}
                    disabled={mode !== 'custom' && (mode === '75_hard' || mode === '75_hard_plus') || !canModifyHabits}
                    className="mt-0.5"
                  />
                  <div className="flex-1 min-w-0">
                    <label
                      htmlFor={`default-${habit.id}`}
                      className="font-medium cursor-pointer"
                    >
                      {habit.title}
                    </label>
                    <p className="text-sm text-muted-foreground">{habit.description}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant="outline" className="text-xs">{habit.category}</Badge>
                      <span className="text-xs text-muted-foreground">{habit.points} points</span>
                    </div>
                  </div>
                  <CheckCircle2 className="w-4 h-4 text-green-600 mt-0.5" />
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Bonus Habits */}
      {bonusHabits.length > 0 && (
        <Card className="border-card-border">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Zap className="w-5 h-5 text-amber-500" />
              Bonus Habits
            </CardTitle>
          <CardDescription>
            Add extra habits to earn more points and unlock hearts (1 heart per 100 bonus points)
          </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-3 sm:grid-cols-2">
              {bonusHabits.map((habit) => (
                <div 
                  key={habit.id} 
                  className={`flex items-start gap-3 p-3 border rounded-lg border-card-border transition-colors ${
                    canModifyHabits ? 'cursor-pointer hover:bg-muted/30' : 'opacity-75'
                  }`}
                  onClick={() => canModifyHabits && handleHabitToggle(habit.id, false)}
                >
                  <Checkbox
                    id={`bonus-${habit.id}`}
                    checked={selectedHabits.includes(habit.id)}
                    onCheckedChange={() => handleHabitToggle(habit.id, false)}
                    disabled={!canModifyHabits}
                    className="mt-0.5"
                  />
                  <div className="flex-1 min-w-0">
                    <label
                      htmlFor={`bonus-${habit.id}`}
                      className="font-medium cursor-pointer"
                    >
                      {habit.title}
                    </label>
                    <p className="text-sm text-muted-foreground">{habit.description}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant="secondary" className="text-xs">{habit.category}</Badge>
                      <span className="text-xs font-medium text-amber-600">{habit.points} points</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add Custom Habit - TEMPORARILY HIDDEN */}
      {/*
      <Card className="border-card-border">
        <CardHeader>
          <CardTitle className="text-lg">Create Custom Habit</CardTitle>
          <CardDescription>
            Add your own habit that's not in our list
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Dialog open={isAddingCustom} onOpenChange={setIsAddingCustom}>
            <DialogTrigger asChild>
              <Button variant="outline" className="w-full" disabled={!canModifyHabits}>
                <Plus className="w-4 h-4 mr-2" />
                {canModifyHabits ? 'Add Custom Habit' : 'Custom Habits Frozen'}
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Create Custom Habit</DialogTitle>
                <DialogDescription>
                  Define a new habit for your challenge
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="habit-title">Habit Name</Label>
                  <Input
                    id="habit-title"
                    placeholder="e.g., Practice piano for 30 minutes"
                    value={customHabit.title}
                    onChange={(e) => setCustomHabit(prev => ({ ...prev, title: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="habit-description">Description</Label>
                  <Input
                    id="habit-description"
                    placeholder="Brief description of the habit"
                    value={customHabit.description}
                    onChange={(e) => setCustomHabit(prev => ({ ...prev, description: e.target.value }))}
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="habit-category">Category</Label>
                    <Input
                      id="habit-category"
                      placeholder="e.g., Music, Learning"
                      value={customHabit.category}
                      onChange={(e) => setCustomHabit(prev => ({ ...prev, category: e.target.value }))}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="habit-points">Points</Label>
                    <Input
                      id="habit-points"
                      type="number"
                      min="1"
                      max="20"
                      value={customHabit.points}
                      onChange={(e) => setCustomHabit(prev => ({ ...prev, points: parseInt(e.target.value) || 5 }))}
                    />
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button onClick={handleAddCustomHabit} className="flex-1">
                    Add Habit
                  </Button>
                  <Button variant="outline" onClick={() => setIsAddingCustom(false)}>
                    Cancel
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </CardContent>
      </Card>
      */}

      {/* Save Button */}
      <div className="flex justify-end">
        <Button 
          onClick={handleSaveSelection}
          disabled={saving || selectedHabits.length === 0 || !canModifyHabits}
          className="gradient-primary text-primary-foreground border-0"
          size="lg"
        >
          {saving ? 'Saving...' : 
           !canModifyHabits ? 'Habits Frozen' :
           `Save ${selectedHabits.length} Habits`}
        </Button>
      </div>
    </div>
  );
}