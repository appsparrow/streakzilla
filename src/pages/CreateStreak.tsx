import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/page-header";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { ArrowLeft, Copy, Share2, CheckCircle2, Heart, Settings } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useStreaks } from "@/hooks/useStreaks";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface TemplateOption { id: string; key: string; name: string; description?: string | null; allow_custom_habits: boolean; }

export default function CreateStreak() {
  const navigate = useNavigate();
  const { createStreak } = useStreaks();
  const [templates, setTemplates] = useState<TemplateOption[]>([]);
  const [formData, setFormData] = useState({
    name: "",
    mode: "",
    duration: "",
    startDate: new Date().toISOString().split('T')[0],
    heartSettings: {
      points_to_hearts_enabled: true
    }
  });
  const [isCreating, setIsCreating] = useState(false);
  const [createdResult, setCreatedResult] = useState<{streak_id: string, streak_code: string} | null>(null);

  useEffect(() => {
    const load = async () => {
      const { data } = await supabase.from('sz_templates').select('id, key, name, description, allow_custom_habits').order('name');
      setTemplates(data || []);
    };
    void load();
  }, []);

  const selectedTemplate = templates.find(t => t.key === formData.mode);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsCreating(true);

    console.log('Creating streak with mode:', formData.mode);
    console.log('Selected template:', templates.find(t => t.key === formData.mode));

    const result = await createStreak({
      name: formData.name,
      mode: formData.mode,
      start_date: formData.startDate,
      duration_days: parseInt(formData.duration),
      points_to_hearts_enabled: formData.heartSettings.points_to_hearts_enabled,
      hearts_per_100_points: 1 // Fixed at 1 heart per 100 points
    });

    setIsCreating(false);
    if (result) {
      setCreatedResult(result);
    }
  };

  const handleCopyCode = () => {
    if (createdResult) {
      navigator.clipboard.writeText(createdResult.streak_code);
      toast.success("Code copied to clipboard!");
    }
  };

  const handleShare = () => {
    if (createdResult) {
      const shareUrl = `${window.location.origin}?join=${createdResult.streak_code}`;
      navigator.clipboard.writeText(shareUrl);
      toast.success("Share link copied to clipboard!");
    }
  };

  if (createdResult) {
    return (
      <div className="container mx-auto p-6 max-w-2xl">
        <div className="text-center mb-8">
          <div className="w-16 h-16 mx-auto mb-4 rounded-full gradient-success flex items-center justify-center">
            <CheckCircle2 className="w-8 h-8 text-success-foreground" />
          </div>
          <h1 className="text-3xl font-bold mb-2">Streak Created! 🎉</h1>
          <p className="text-muted-foreground text-lg">
            Your "{formData.name}" streak is ready to go
          </p>
        </div>

        <Card className="border-card-border mb-6">
          <CardHeader className="text-center">
            <CardTitle>Share Your Streak Code</CardTitle>
            <CardDescription>
              Share this code with friends to invite them to join your streak
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center space-y-6">
            <div className="p-6 bg-muted rounded-lg">
              <div className="text-4xl font-mono font-bold text-primary mb-2">
                {createdResult.streak_code}
              </div>
              <p className="text-sm text-muted-foreground">Join Code</p>
            </div>

            <div className="flex gap-3">
              <Button
                onClick={handleCopyCode}
                variant="outline"
                className="flex-1"
              >
                <Copy className="w-4 h-4 mr-2" />
                Copy Code
              </Button>
              <Button
                onClick={handleShare}
                variant="outline"
                className="flex-1"
              >
                <Share2 className="w-4 h-4 mr-2" />
                Share Link
              </Button>
            </div>

            <Button
              onClick={() => navigate(`/streak/${createdResult.streak_id}`)}
              className="w-full gradient-primary text-primary-foreground border-0"
              size="lg"
            >
              Go to Streak Dashboard
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl">
      <PageHeader
        title="Create New Streak"
        subtitle="Set up a challenge that you and your friends can tackle together"
        showBackButton={true}
        backTo="/"
        showLogo={true}
      />

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Streak Name */}
        <Card className="border-card-border">
          <CardHeader>
            <CardTitle>Streak Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="streak-name">Streak Name</Label>
              <Input
                id="streak-name"
                placeholder="e.g., New Year New Me Challenge"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                required
                className="border-input"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="start-date">Start Date</Label>
              <Input
                id="start-date"
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData({...formData, startDate: e.target.value})}
                required
                className="border-input"
              />
            </div>
          </CardContent>
        </Card>

        {/* Template Selection */}
        <Card className="border-card-border">
          <CardHeader>
            <CardTitle>Choose Template</CardTitle>
            <CardDescription>
              Pick a template or create your own custom challenge
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Select
              value={formData.mode}
              onValueChange={(value) => {
                const template = templates.find(t => t.key === value);
                setFormData({
                  ...formData, 
                  mode: value,
                  duration: template ? '75' : ''
                });
              }}
            >
              <SelectTrigger className="border-input bg-background">
                <SelectValue placeholder="Select a template" />
              </SelectTrigger>
              <SelectContent className="bg-background border border-border">
                {templates.map((template) => (
                  <SelectItem key={template.id} value={template.key} className="bg-background hover:bg-muted">
                    <div className="flex items-center gap-2">
                      <span>{template.name}</span>
                      <Badge variant="secondary" className="text-xs">75 days</Badge>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {selectedTemplate && (
              <div className="p-4 bg-muted/50 rounded-lg space-y-3">
                <div>
                  <h4 className="font-medium mb-1">{selectedTemplate.name}</h4>
                  <p className="text-sm text-muted-foreground">
                    {selectedTemplate.description}
                  </p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Custom Duration */}
        {(formData.mode === "custom" || formData.mode === "75-custom") && (
          <Card className="border-card-border">
            <CardHeader>
              <CardTitle>Custom Settings</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <Label htmlFor="duration">Duration (days)</Label>
                <Input
                  id="duration"
                  type="number"
                  min="1"
                  max="365"
                  placeholder="Enter number of days"
                  value={formData.duration}
                  onChange={(e) => setFormData({...formData, duration: e.target.value})}
                  required
                  className="border-input"
                />
              </div>
            </CardContent>
          </Card>
        )}

        {/* Heart System Settings */}
        <Card className="border-card-border border-pink-200 bg-pink-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-pink-700">
              <Heart className="w-5 h-5" />
              Heart System Settings
            </CardTitle>
            <CardDescription className="text-pink-600">
              Configure how hearts work in your streak challenge
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
                  checked={formData.heartSettings.points_to_hearts_enabled}
                  onCheckedChange={(checked) => 
                    setFormData(prev => ({ 
                      ...prev, 
                      heartSettings: { ...prev.heartSettings, points_to_hearts_enabled: checked }
                    }))
                  }
                />
              </div>
            </div>


            {/* Settings Summary */}
            <div className="p-3 bg-white rounded-lg border border-pink-200">
              <h4 className="font-medium text-sm mb-2 flex items-center gap-2">
                <Settings className="w-4 h-4 text-pink-600" />
                Heart System Preview
              </h4>
              <div className="space-y-1 text-xs text-gray-600">
                <div className="flex items-center gap-2">
                  <Heart className="w-3 h-3" />
                  <span>
                    Points to Hearts: {formData.heartSettings.points_to_hearts_enabled ? 'Enabled (1 per 100 points)' : 'Disabled'}
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Button
          type="submit"
          disabled={isCreating || !formData.name || !formData.mode || !formData.duration}
          className="w-full gradient-primary text-primary-foreground border-0"
          size="lg"
        >
          {isCreating ? "Creating Streak..." : "Create Streak"}
        </Button>
      </form>
    </div>
  );
}