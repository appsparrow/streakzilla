import { useState, useRef, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Camera, Upload, X, Zap, Target } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

interface Habit {
  id: string;
  title: string;
  description: string;
  points: number;
  category: string;
  template_set?: string;
  is_core?: boolean;
  points_override?: number;
}

interface CheckInModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  streakId: string;
  dayNumber: number;
  habits: Habit[];
  todayCheckin?: { completed_habit_ids: string[]; points_earned: number } | null;
  mode: string;
  onCheckInComplete: () => void;
}

export function CheckInModal({ 
  open, 
  onOpenChange, 
  streakId, 
  dayNumber, 
  habits, 
  todayCheckin,
  mode,
  onCheckInComplete 
}: CheckInModalProps) {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedHabits, setSelectedHabits] = useState<string[]>([]);
  const [note, setNote] = useState("");
  const [photo, setPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [additionalHabits, setAdditionalHabits] = useState<Habit[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [showAddHabits, setShowAddHabits] = useState(false);

  const isHardPlus = mode === '75_hard_plus';
  const alreadyCheckedIn = todayCheckin && todayCheckin.completed_habit_ids.length > 0;
  const checkedInHabits = todayCheckin?.completed_habit_ids || [];
  
  // Initialize selected habits from today's checkin when modal opens
  useEffect(() => {
    if (open && todayCheckin?.completed_habit_ids) {
      setSelectedHabits([]); // Don't auto-select already completed habits, they'll show as completed
    } else if (open) {
      setSelectedHabits([]);
    }
  }, [open, todayCheckin]);

  // Initialize note and photo from today's checkin when modal opens  
  useEffect(() => {
    if (open && todayCheckin) {
      // Note: todayCheckin interface needs to be updated to include note property
      setNote("");
    } else if (open) {
      setNote("");
      setPhoto(null);
      setPhotoPreview(null);
    }
  }, [open, todayCheckin]);
  
  // Get available additional habits for hard_plus mode
  useEffect(() => {
    if (isHardPlus && showAddHabits) {
      fetchAdditionalHabits();
    }
  }, [isHardPlus, showAddHabits, searchTerm]);

  const fetchAdditionalHabits = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      let query = supabase
        .from('sz_habits')
        .select('*')
        .not('template_set', 'in', '("75_hard","75_hard_plus")')
        .or(`template_set.eq.custom,template_set.eq.custom_${user?.id || ''}`); // Only user-specific custom habits
      
      if (searchTerm) {
        query = query.or(`title.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%,category.ilike.%${searchTerm}%`);
      }
      
      const { data, error } = await query.limit(10);
      
      if (error) throw error;
      setAdditionalHabits(data || []);
    } catch (error) {
      console.error('Error fetching additional habits:', error);
    }
  };

  // Core habit detection (template mapping first, legacy fallback)
  function isCore(h: Habit): boolean {
    if (h.is_core !== undefined) {
      return !!h.is_core;
    }
    return h.template_set === '75_hard' || h.category === 'core' || h.points === 0;
  }

  // Calculate points - only count bonus habits for Hard Plus modes
  const totalPoints = selectedHabits.reduce((sum, habitId) => {
    const habit = [...habits, ...additionalHabits].find(h => h.id === habitId);
    if (!habit) return sum;
    
    // In Hard Plus mode, core habits don't earn points (they're required)
    // Only bonus habits earn points toward hearts
    if (isHardPlus && isCore(habit)) {
      return sum; // Core habit - no points
    }
    
    // Use points_override if available, otherwise use default points
    // Add proper null/undefined checks to prevent NaN
    const points = habit.points_override !== null && habit.points_override !== undefined 
      ? habit.points_override 
      : (habit.points || 0);
    
    // Ensure points is a valid number
    const validPoints = typeof points === 'number' && !isNaN(points) ? points : 0;
    return sum + validPoints;
  }, 0);

  // Add progress photo points (5 points if a photo is selected and mode supports it)
  const progressPhotoPoints = photo && isHardPlus ? 5 : 0;

  const todaysPoints = (todayCheckin?.points_earned || 0) + totalPoints + progressPhotoPoints;

  const handleHabitToggle = (habitId: string) => {
    // Don't allow unchecking already completed habits
    if (checkedInHabits.includes(habitId)) {
      return;
    }
    
    setSelectedHabits(prev => 
      prev.includes(habitId) 
        ? prev.filter(id => id !== habitId)
        : [...prev, habitId]
    );
  };

  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        toast.error("Photo must be less than 10MB");
        return;
      }
      
      setPhoto(file);
      const reader = new FileReader();
      reader.onload = () => setPhotoPreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const uploadPhoto = async (file: File): Promise<string | null> => {
    if (!user) return null;

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('userId', user.id);
      formData.append('streakId', streakId);
      formData.append('dayNumber', dayNumber.toString());

      const { data, error } = await supabase.functions.invoke('upload-to-r2', {
        body: formData,
      });

      if (error) throw error;

      return data.url;
    } catch (error) {
      console.error('Error uploading photo:', error);
      // Fallback to Supabase storage
      try {
        const fileExt = file.name.split('.').pop();
        const fileName = `${user.id}/${streakId}/day-${dayNumber}-${Date.now()}.${fileExt}`;
        
        const { error } = await supabase.storage
          .from('streak-photos')
          .upload(fileName, file);

        if (error) throw error;

        const { data } = supabase.storage
          .from('streak-photos')
          .getPublicUrl(fileName);

        return data.publicUrl;
      } catch (fallbackError) {
        console.error('Fallback upload also failed:', fallbackError);
        throw fallbackError;
      }
    }
  };

  const handleSubmit = async () => {
    if (selectedHabits.length === 0 && !photo) {
      toast.error("Please select at least one habit or upload a progress photo");
      return;
    }

    setIsSubmitting(true);
    try {
      let photoUrl: string | null = null;
      
      if (photo) {
        photoUrl = await uploadPhoto(photo);
      }

      // Calculate total points including progress photo
      const finalPoints = totalPoints + progressPhotoPoints;

      const { data, error } = await supabase.rpc('sz_checkin', {
        p_streak_id: streakId,
        p_day_number: dayNumber,
        p_completed_habit_ids: selectedHabits,
        p_note: note || null,
        p_photo_url: photoUrl
      });

      if (error) throw error;

      let successMessage = `Great job! ${isHardPlus ? 
        (finalPoints > 0 ? `You earned ${finalPoints} bonus points!` : 'You completed your core requirements!') :
        `You earned ${finalPoints} points today!`
      } 🎉`;
      
      // Add progress photo points message
      if (progressPhotoPoints > 0) {
        successMessage += `\n📸 Progress photo: +${progressPhotoPoints} points!`;
      }
      
      // Check if hearts were earned (for bonus points in hard modes) 
      if (mode.includes('75_hard') && mode.includes('plus') && finalPoints > 0) {
        // Hearts are based on cumulative bonus points, not daily
        // We'll show a generic message about bonus points contributing to hearts
        successMessage += `\n💖 Bonus points contribute to earning hearts! (1 heart per 100 bonus points)`;
      }
      
      toast.success(successMessage);
      onCheckInComplete();
      onOpenChange(false);
      
      // Reset form
      setSelectedHabits([]);
      setNote("");
      setPhoto(null);
      setPhotoPreview(null);
    } catch (error: any) {
      console.error('Error during check-in:', error);
      toast.error(error.message || "Failed to check in");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleReset = () => {
    setSelectedHabits([]);
    setNote("");
    setPhoto(null);
    setPhotoPreview(null);
  };
 
  
  const coreHabits = isHardPlus 
    ? habits.filter(isCore)
    : habits;
  const bonusHabits = isHardPlus 
    ? [...habits.filter(habit => !isCore(habit)), ...additionalHabits]
    : [];

  // Check if user has no habits selected yet
  const noHabitsSelected = habits.length === 0;
  
  // Group habits by type for Hard Plus mode
  const habitGroups = isHardPlus ? [
    { title: "75 Hard Core Requirements", habits: coreHabits, type: "core" },
    ...(bonusHabits.length > 0 ? [{ title: "Bonus Habits (Extra Points)", habits: bonusHabits, type: "bonus" }] : [])
  ] : [
    { title: "Habits", habits: coreHabits, type: "all" }
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Target className="w-5 h-5 text-primary" />
            Day {dayNumber} Check-In
          </DialogTitle>
          <DialogDescription>
            Track your daily progress and earn points for completed habits
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* No Habits Selected - Show Selection Prompt */}
          {noHabitsSelected && (
            <Card className="border-yellow-200 bg-yellow-50">
              <CardContent className="p-4">
                <div className="text-center">
                  <Target className="w-8 h-8 text-yellow-600 mx-auto mb-2" />
                  <h3 className="font-medium text-yellow-800 mb-2">No Habits Selected</h3>
                  <p className="text-sm text-yellow-700 mb-3">
                    You need to select your habits first before you can check in.
                  </p>
                  <Button
                    variant="outline"
                    onClick={() => {
                      onOpenChange(false);
                      // Navigate to habit selection - this will be handled by parent component
                      window.location.href = `/streak/${streakId}/select-habits`;
                    }}
                    className="border-yellow-300 text-yellow-700 hover:bg-yellow-100"
                  >
                    Select Your Habits
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Points Summary - Only show when habits are selected */}
          {!noHabitsSelected && (
            <Card className="border-primary/20 bg-gradient-to-r from-primary/5 to-primary/10">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Zap className="w-5 h-5 text-yellow-500" />
                    <span className="font-medium">Points Today</span>
                  </div>
                  <div className="text-right">
                    <Badge variant="secondary" className="text-lg font-bold px-3 py-1">
                     {isHardPlus ? 
                        `${(totalPoints + progressPhotoPoints) || 0} bonus points` : 
                        todaysPoints
                       }
                     </Badge>
                    {alreadyCheckedIn && (
                      <p className="text-xs text-muted-foreground mt-1">
                        +{(totalPoints + progressPhotoPoints) || 0} new points
                      </p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Only show check-in interface when habits are selected */}
          {!noHabitsSelected && (
            <>
              {alreadyCheckedIn && (
                <Card className="border-green-200 bg-green-50">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-2 text-green-700">
                      <Target className="w-4 h-4" />
                      <span className="font-medium">Already checked in today!</span>
                    </div>
                    <p className="text-sm text-green-600 mt-1">
                      You can still add bonus habits for extra points
                    </p>
                  </CardContent>
                </Card>
              )}

             
              {/* Habit Search for Hard Plus */}
              {isHardPlus && showAddHabits && (
                <Card className="border-blue-200">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-2 mb-3">
                      <Target className="w-4 h-4 text-blue-600" />
                      <span className="font-medium text-blue-700">Search Bonus Habits</span>
                    </div>
                    <Input
                      type="text"
                      placeholder="Search habits..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="mb-3"
                    />
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setShowAddHabits(false)}
                    >
                      Hide Bonus Habits
                    </Button>
                  </CardContent>
                </Card>
              )}

              {/* Habits Selection - Organized by Core vs Bonus */}
              <div className="space-y-4">
                <Label className="text-base font-medium">
                  {isHardPlus ? "Complete your daily requirements:" : "Select completed habits:"}
                </Label>
            
                {habitGroups.map((group) => (
                  <Card key={`${group.type}-${group.title}`} className={`border-card-border ${
                    group.type === 'core' ? 'border-orange-200 bg-orange-50/50' : 
                    group.type === 'bonus' ? 'border-blue-200 bg-blue-50/50' : ''
                  }`}>
                    <CardContent className="p-4">
                      <div className="flex items-center gap-2 mb-3">
                        {group.type === 'core' && <Target className="w-4 h-4 text-orange-600" />}
                        {group.type === 'bonus' && <Zap className="w-4 h-4 text-blue-600" />}
                        <h4 className={`font-medium text-sm ${
                          group.type === 'core' ? 'text-orange-700' :
                          group.type === 'bonus' ? 'text-blue-700' : 'text-muted-foreground'
                        }`}>
                          {group.title}
                          {group.type === 'core' && ' (Required Daily)'}
                          {group.type === 'bonus' && ' (Optional - Earn Hearts)'}
                        </h4>
                      </div>
                      <div className="space-y-3">
                        {group.habits.map((habit) => {
                          const isCompleted = checkedInHabits.includes(habit.id);
                          const isSelected = selectedHabits.includes(habit.id);
                          
                          return (
                            <div 
                              key={habit.id} 
                              className={`flex items-start space-x-3 p-2 rounded-lg hover:bg-muted/30 transition-colors cursor-pointer ${
                                isCompleted ? 'bg-green-50 border border-green-200' : ''
                              }`}
                              onClick={() => !isCompleted && handleHabitToggle(habit.id)}
                            >
                              <Checkbox
                                id={habit.id}
                                checked={isCompleted || isSelected}
                                onCheckedChange={() => handleHabitToggle(habit.id)}
                                disabled={isCompleted}
                              />
                              <div className="flex-1 min-w-0">
                                <label 
                                  htmlFor={habit.id}
                                  className={`text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer ${
                                    isCompleted ? 'text-green-600' : ''
                                  }`}
                                >
                                  {habit.title}
                                  {isCompleted && ' ✅'}
                                  {isCore(habit) && !isCompleted && !isSelected && ' (Required)'}
                                </label>
                                <p className="text-xs text-muted-foreground mt-1">
                                  {habit.description}
                                </p>
                              </div>
                              <Badge variant={
                                isCore(habit) ? 'destructive' : 
                                isCompleted ? "default" : "outline"
                              } className="ml-2">
                                {isCore(habit) ? 'CORE' : `${(habit.points_override ?? habit.points) || 0} pts`}
                              </Badge>
                            </div>
                          );
                        })}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>

              {/* Photo Upload */}
              <div className="space-y-3">
                <Label className="text-base font-medium">
                  Add a progress photo {isHardPlus ? '(+5 bonus points)' : '(optional)'}:
                </Label>
            
            {photoPreview ? (
              <div className="relative">
                <img 
                  src={photoPreview} 
                  alt="Preview" 
                  className="w-full h-48 object-cover rounded-lg border border-border"
                />
                <Button
                  variant="destructive"
                  size="sm"
                  className="absolute top-2 right-2"
                  onClick={() => {
                    setPhoto(null);
                    setPhotoPreview(null);
                  }}
                >
                  <X className="w-4 h-4" />
                </Button>
              </div>
            ) : (
              <Card className="border-dashed border-2 border-muted-foreground/25 hover:border-muted-foreground/50 transition-colors">
                <CardContent className="p-6">
                  <div className="text-center">
                    <Camera className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-muted-foreground mb-3">
                      Share your progress with a photo
                    </p>
                    <Button
                      variant="outline"
                      onClick={() => fileInputRef.current?.click()}
                    >
                      <Upload className="w-4 h-4 mr-2" />
                      Choose Photo
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}
            
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handlePhotoSelect}
              className="hidden"
            />
          </div>

              {/* Notes */}
              <div className="space-y-2">
                <Label htmlFor="note" className="text-base font-medium">
                  Notes (optional):
                </Label>
                <Textarea
                  id="note"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="How did today go? Any thoughts or insights..."
                  className="min-h-20 border-input"
                />
              </div>

              {/* Actions */}
              <div className="flex gap-3 pt-4">
                <Button
                  onClick={handleSubmit}
                  disabled={isSubmitting || (selectedHabits.length === 0 && !photo)}
                  className="flex-1 gradient-primary text-primary-foreground border-0"
                  size="lg"
                >
                  {isSubmitting ? "Checking in..." : 
                    alreadyCheckedIn ? 
                      (isHardPlus ? `Add Bonus (${(totalPoints + progressPhotoPoints) || 0} pts)` : `Add Bonus (${(totalPoints + progressPhotoPoints) || 0} points)`) :
                      (isHardPlus ? `Complete Requirements${progressPhotoPoints > 0 ? ` (+${progressPhotoPoints} pts)` : ''}` : `Check In (${(totalPoints + progressPhotoPoints) || 0} points)`)
                  }
                </Button>
                
                <Button
                  variant="outline"
                  onClick={handleReset}
                  disabled={isSubmitting}
                >
                  Reset
                </Button>
                
                <Button
                  variant="ghost"
                  onClick={() => onOpenChange(false)}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
              </div>
            </>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}