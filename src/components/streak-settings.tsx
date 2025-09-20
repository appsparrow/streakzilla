import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Heart, Settings, Users, Target } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";

interface StreakSettingsProps {
  streakId: string;
  currentSettings: {
    heart_sharing_enabled: boolean;
    points_to_hearts_enabled: boolean;
    hearts_per_100_points: number;
  };
  isAdmin: boolean;
  onSettingsUpdated: () => void;
}

export function StreakSettings({ 
  streakId, 
  currentSettings, 
  isAdmin, 
  onSettingsUpdated 
}: StreakSettingsProps) {
  const [settings, setSettings] = useState(currentSettings);
  const [isUpdating, setIsUpdating] = useState(false);

  const handleUpdateSettings = async () => {
    if (!isAdmin) {
      toast.error("Only admins can update streak settings");
      return;
    }

    setIsUpdating(true);
    try {
      const { error } = await supabase
        .from('sz_streaks')
        .update({
          heart_sharing_enabled: settings.heart_sharing_enabled,
          points_to_hearts_enabled: settings.points_to_hearts_enabled,
          hearts_per_100_points: settings.hearts_per_100_points,
        })
        .eq('id', streakId);

      if (error) throw error;

      toast.success("Streak settings updated successfully!");
      onSettingsUpdated();
    } catch (error: any) {
      console.error('Error updating streak settings:', error);
      toast.error(error.message || "Failed to update streak settings");
    } finally {
      setIsUpdating(false);
    }
  };

  const hasChanges = 
    settings.heart_sharing_enabled !== currentSettings.heart_sharing_enabled ||
    settings.points_to_hearts_enabled !== currentSettings.points_to_hearts_enabled ||
    settings.hearts_per_100_points !== currentSettings.hearts_per_100_points;

  if (!isAdmin) {
    return (
      <Card className="border-gray-200 bg-gray-50">
        <CardContent className="p-4">
          <div className="flex items-center gap-3 text-gray-600">
            <Settings className="w-5 h-5 text-gray-400" />
            <div>
              <p className="font-medium">Streak Settings</p>
              <p className="text-sm text-gray-500">Only admins can modify streak settings</p>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-blue-200 bg-blue-50">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-blue-700">
          <Settings className="w-5 h-5" />
          Streak Settings
        </CardTitle>
        <CardDescription className="text-blue-600">
          Configure heart system and sharing options for this streak
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Points to Hearts System */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="points-to-hearts" className="text-sm font-medium">
                Points to Hearts System
              </Label>
              <p className="text-xs text-gray-600">
                Enable earning hearts from points (100 points = 1 heart)
              </p>
            </div>
            <Switch
              id="points-to-hearts"
              checked={settings.points_to_hearts_enabled}
              onCheckedChange={(checked) => 
                setSettings(prev => ({ ...prev, points_to_hearts_enabled: checked }))
              }
            />
          </div>
        </div>

            {/* Hearts per 100 Points - Fixed at 1 */}
            {settings.points_to_hearts_enabled && (
              <div className="space-y-3">
                <div className="space-y-2">
                  <Label className="text-sm font-medium">
                    Hearts per 100 Points
                  </Label>
                  <div className="flex items-center gap-2 p-2 bg-muted rounded-md">
                    <span className="text-sm font-medium">1 heart per 100 points</span>
                    <Badge variant="secondary" className="text-xs">Fixed</Badge>
                  </div>
                  <p className="text-xs text-gray-500">
                    This is the standard rate and cannot be changed
                  </p>
                </div>
              </div>
            )}

        {/* Heart Sharing - Only available when points-to-hearts is enabled */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="heart-sharing" className="text-sm font-medium">
                Heart Sharing
              </Label>
              <p className="text-xs text-gray-600">
                Allow streakmates to gift hearts to each other
              </p>
              {!settings.points_to_hearts_enabled && (
                <p className="text-xs text-orange-600">
                  Requires points-to-hearts system to be enabled
                </p>
              )}
            </div>
            <Switch
              id="heart-sharing"
              checked={settings.heart_sharing_enabled && settings.points_to_hearts_enabled}
              disabled={!settings.points_to_hearts_enabled}
              onCheckedChange={(checked) => 
                setSettings(prev => ({ ...prev, heart_sharing_enabled: checked }))
              }
            />
          </div>
        </div>

        {/* Settings Summary */}
        <div className="p-3 bg-white rounded-lg border border-blue-200">
          <h4 className="font-medium text-sm mb-2 flex items-center gap-2">
            <Target className="w-4 h-4 text-blue-600" />
            Current Settings
          </h4>
          <div className="space-y-1 text-xs text-gray-600">
                <div className="flex items-center gap-2">
                  <Heart className="w-3 h-3" />
                  <span>
                    Points to Hearts: {settings.points_to_hearts_enabled ? 'Enabled (1 per 100 points)' : 'Disabled'}
                  </span>
                </div>
            <div className="flex items-center gap-2">
              <Users className="w-3 h-3" />
              <span>
                Heart Sharing: {settings.heart_sharing_enabled ? 'Enabled' : 'Disabled'}
              </span>
            </div>
          </div>
        </div>

        {/* Update Button */}
        <Button
          onClick={handleUpdateSettings}
          disabled={!hasChanges || isUpdating}
          className="w-full bg-blue-500 hover:bg-blue-600 text-white border-0"
        >
          {isUpdating ? "Updating..." : "Update Settings"}
        </Button>
      </CardContent>
    </Card>
  );
}
