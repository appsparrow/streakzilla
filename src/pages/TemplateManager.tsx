import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { PageHeader } from "@/components/layout/page-header";
import { Plus, Trash2, Save, Search, ArrowLeft, Edit, ListChecks } from "lucide-react";

interface Habit {
  id: string;
  title: string;
  description: string;
  category: string;
  points: number;
  template_set?: string;
}

interface TemplateRow {
  id: string;
  key: string;
  name: string;
  description?: string | null;
  allow_custom_habits: boolean;
}

interface TemplateHabitRow {
  id: string;
  template_id: string;
  habit_id: string;
  is_core: boolean;
  points_override: number | null;
  sort_order: number | null;
}

type EditableMapping = {
  included: boolean;
  is_core: boolean;
  points_override: number | null;
  sort_order: number | null;
};

export default function TemplateManager() {
  const navigate = useNavigate();
  const [habits, setHabits] = useState<Habit[]>([]);
  const [templates, setTemplates] = useState<TemplateRow[]>([]);
  const [selectedTemplateId, setSelectedTemplateId] = useState<string | null>(null);
  const [templateHabits, setTemplateHabits] = useState<TemplateHabitRow[]>([]);
  const [search, setSearch] = useState("");
  const [saving, setSaving] = useState(false);
  const [creating, setCreating] = useState(false);
  const [newTemplate, setNewTemplate] = useState({ key: "", name: "", description: "", allow_custom_habits: false });
  const [editingTemplate, setEditingTemplate] = useState<TemplateRow | null>(null);

  useEffect(() => {
    void loadHabits();
    void loadTemplates();
  }, []);

  useEffect(() => {
    if (selectedTemplateId) void loadTemplateHabits(selectedTemplateId);
  }, [selectedTemplateId]);

  const loadHabits = async () => {
    const { data, error } = await supabase.from("sz_habits").select("id, title, description, category, points, template_set").order("title");
    if (error) return toast.error(error.message);
    setHabits(data || []);
  };

  const loadTemplates = async () => {
    const { data, error } = await supabase.from("sz_templates").select("id, key, name, description, allow_custom_habits").order("name");
    if (error) return toast.error(error.message);
    setTemplates(data || []);
    if (!selectedTemplateId && data && data.length > 0) setSelectedTemplateId(data[0].id);
  };

  const loadTemplateHabits = async (templateId: string) => {
    const { data, error } = await supabase
      .from("sz_template_habits")
      .select("id, template_id, habit_id, is_core, points_override, sort_order")
      .eq("template_id", templateId);
    if (error) return toast.error(error.message);
    setTemplateHabits(data || []);
  };

  // Build a canonical list of habits by grouping on title+description to avoid duplicates
  const canonicalHabits: Habit[] = useMemo(() => {
    // Only dedupe exact matches (same title AND description), otherwise show all habits
    const seen = new Set<string>();
    const canon: Habit[] = [];
    
    for (const h of habits) {
      const key = `${(h.title || '').trim().toLowerCase()}|${(h.description || '').trim().toLowerCase()}`;
      
      if (!seen.has(key)) {
        seen.add(key);
        canon.push(h);
      } else {
        // Only skip if we already have this exact habit
        const existing = canon.find(c => 
          c.title.toLowerCase().trim() === h.title.toLowerCase().trim() &&
          c.description.toLowerCase().trim() === h.description.toLowerCase().trim()
        );
        if (!existing) {
          canon.push(h);
        }
      }
    }
    
    // Sort by title for stable UI
    canon.sort((a, b) => a.title.localeCompare(b.title));
    return canon;
  }, [habits]);

  const mappingByHabitId: Record<string, EditableMapping> = useMemo(() => {
    const map: Record<string, EditableMapping> = {};
    for (const h of canonicalHabits) {
      const row = templateHabits.find(th => th.habit_id === h.id);
      map[h.id] = {
        included: !!row,
        is_core: row?.is_core ?? true,
        points_override: row?.points_override ?? null,
        sort_order: row?.sort_order ?? null,
      };
    }
    return map;
  }, [canonicalHabits, templateHabits]);

  const filteredHabits = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return canonicalHabits;
    return canonicalHabits.filter(h =>
      h.title.toLowerCase().includes(q) ||
      (h.description || "").toLowerCase().includes(q) ||
      (h.category || "").toLowerCase().includes(q)
    );
  }, [canonicalHabits, search]);

  // Summary stats for selected template
  const templateSummary = useMemo(() => {
    if (!selectedTemplateId) return null;
    const coreCount = templateHabits.filter(th => th.is_core).length;
    const bonusCount = templateHabits.filter(th => !th.is_core).length;
    const totalCount = templateHabits.length;
    
    const coreHabits = templateHabits
      .filter(th => th.is_core)
      .map(th => habits.find(h => h.id === th.habit_id))
      .filter(Boolean) as Habit[];
    
    const bonusHabits = templateHabits
      .filter(th => !th.is_core)
      .map(th => habits.find(h => h.id === th.habit_id))
      .filter(Boolean) as Habit[];
    
    return { coreCount, bonusCount, totalCount, coreHabits, bonusHabits };
  }, [selectedTemplateId, templateHabits, habits]);

  const handleSaveMappings = async () => {
    if (!selectedTemplateId) return;
    try {
      setSaving(true);
      const current = new Map(templateHabits.map(th => [th.habit_id, th]));

      const toUpsert: Partial<TemplateHabitRow>[] = [];
      const keepHabitIds: string[] = [];

      for (const h of canonicalHabits) {
        const edited = mappingByHabitId[h.id];
        if (edited.included) {
          keepHabitIds.push(h.id);
          toUpsert.push({
            template_id: selectedTemplateId,
            habit_id: h.id,
            is_core: edited.is_core,
            points_override: edited.points_override,
            sort_order: edited.sort_order,
          } as any);
        }
      }

      // Upsert included mappings
      if (toUpsert.length > 0) {
        const { error: upsertError } = await supabase.from("sz_template_habits").upsert(toUpsert, { onConflict: "template_id,habit_id" });
        if (upsertError) throw upsertError;
      }

      // Delete removed mappings
      const removedIds = templateHabits
        .filter(th => !keepHabitIds.includes(th.habit_id))
        .map(th => th.id);
      if (removedIds.length > 0) {
        const { error: delError } = await supabase.from("sz_template_habits").delete().in("id", removedIds);
        if (delError) throw delError;
      }

      toast.success("Template mappings saved");
      await loadTemplateHabits(selectedTemplateId);
    } catch (e: any) {
      console.error(e);
      toast.error(e.message || "Failed to save template mappings");
    } finally {
      setSaving(false);
    }
  };

  const handleCreateTemplate = async () => {
    if (!newTemplate.key.trim() || !newTemplate.name.trim()) {
      return toast.error("Key and name are required");
    }
    try {
      setCreating(true);
      const payload = {
        key: newTemplate.key.trim().toLowerCase(),
        name: newTemplate.name.trim(),
        description: newTemplate.description?.trim() || null,
        allow_custom_habits: newTemplate.allow_custom_habits,
      };
      const { data, error } = await supabase.from("sz_templates").insert(payload).select().single();
      if (error) throw error;
      setTemplates(prev => [...prev, data]);
      setSelectedTemplateId(data.id);
      setNewTemplate({ key: "", name: "", description: "", allow_custom_habits: false });
      toast.success("Template created");
    } catch (e: any) {
      toast.error(e.message || "Failed to create template");
    } finally {
      setCreating(false);
    }
  };

  const handleUpdateTemplate = async () => {
    if (!editingTemplate) return;
    try {
      const { error } = await supabase
        .from("sz_templates")
        .update({
          key: editingTemplate.key.trim().toLowerCase(),
          name: editingTemplate.name.trim(),
          description: editingTemplate.description || null,
          allow_custom_habits: editingTemplate.allow_custom_habits,
        })
        .eq("id", editingTemplate.id);
      if (error) throw error;
      toast.success("Template updated");
      await loadTemplates();
    } catch (e: any) {
      toast.error(e.message || "Failed to update template");
    }
  };

  const handleDeleteTemplate = async (id: string) => {
    if (!confirm("Delete template? This will remove its mappings.")) return;
    try {
      const { error } = await supabase.from("sz_templates").delete().eq("id", id);
      if (error) throw error;
      toast.success("Template deleted");
      await loadTemplates();
      if (selectedTemplateId === id) setSelectedTemplateId(null);
    } catch (e: any) {
      toast.error(e.message || "Failed to delete template");
    }
  };

  return (
    <div className="container mx-auto p-4 max-w-6xl">
      <PageHeader
        title="Template Management"
        subtitle="Create templates, map habits, and manage core vs bonus"
      >
        <div className="flex gap-2">
          <Button variant="ghost" onClick={() => navigate("/")}> 
            <ArrowLeft className="w-4 h-4 mr-2"/> Back
          </Button>
        </div>
      </PageHeader>

      <div className="grid gap-4 lg:grid-cols-3">
        {/* Templates list */}
        <Card className="lg:col-span-1 border-card-border">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ListChecks className="w-5 h-5 text-primary"/>
              Templates
            </CardTitle>
            <CardDescription>Choose or create a template</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="space-y-2">
              {templates.map(t => (
                <div key={t.id} className={`p-3 rounded border cursor-pointer flex items-center justify-between ${selectedTemplateId===t.id? 'bg-primary/5 border-primary/30':'border-card-border hover:bg-muted/40'}`} onClick={() => setSelectedTemplateId(t.id)}>
                  <div>
                    <div className="font-medium">{t.name}</div>
                    <div className="text-xs text-muted-foreground">{t.key}{t.allow_custom_habits? ' • custom allowed':''}</div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button size="icon" variant="ghost" onClick={(e) => { e.stopPropagation(); setEditingTemplate(t); }}>
                      <Edit className="w-4 h-4"/>
                    </Button>
                    <Button size="icon" variant="ghost" onClick={(e) => { e.stopPropagation(); void handleDeleteTemplate(t.id); }}>
                      <Trash2 className="w-4 h-4 text-red-600"/>
                    </Button>
                  </div>
                </div>
              ))}
              {templates.length === 0 && (
                <div className="text-sm text-muted-foreground">No templates yet</div>
              )}
            </div>

            <Separator/>

            <Dialog>
              <DialogTrigger asChild>
                <Button className="w-full"><Plus className="w-4 h-4 mr-2"/>New Template</Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Create Template</DialogTitle>
                  <DialogDescription>Define a new template key and display name</DialogDescription>
                </DialogHeader>
                <div className="space-y-3">
                  <div className="space-y-1">
                    <Label htmlFor="key">Key</Label>
                    <Input id="key" placeholder="75_hard_plus" value={newTemplate.key} onChange={(e) => setNewTemplate(v => ({...v, key: e.target.value}))}/>
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="name">Name</Label>
                    <Input id="name" placeholder="75 Hard Plus" value={newTemplate.name} onChange={(e) => setNewTemplate(v => ({...v, name: e.target.value}))}/>
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="desc">Description</Label>
                    <Input id="desc" placeholder="Optional" value={newTemplate.description} onChange={(e) => setNewTemplate(v => ({...v, description: e.target.value}))}/>
                  </div>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <Checkbox checked={newTemplate.allow_custom_habits} onCheckedChange={(v) => setNewTemplate(s => ({...s, allow_custom_habits: !!v}))}/>
                    <span className="text-sm">Allow custom habits</span>
                  </label>
                  <div className="flex justify-end">
                    <Button onClick={handleCreateTemplate} disabled={creating}>{creating? 'Creating...':'Create'}</Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>

            {/* Edit template dialog */}
            {editingTemplate && (
              <Dialog open={!!editingTemplate} onOpenChange={(open) => !open && setEditingTemplate(null)}>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Edit Template</DialogTitle>
                  </DialogHeader>
                  <div className="space-y-3">
                    <div className="space-y-1">
                      <Label>Key</Label>
                      <Input value={editingTemplate.key} onChange={(e) => setEditingTemplate({ ...editingTemplate, key: e.target.value })}/>
                    </div>
                    <div className="space-y-1">
                      <Label>Name</Label>
                      <Input value={editingTemplate.name} onChange={(e) => setEditingTemplate({ ...editingTemplate, name: e.target.value })}/>
                    </div>
                    <div className="space-y-1">
                      <Label>Description</Label>
                      <Input value={editingTemplate.description || ''} onChange={(e) => setEditingTemplate({ ...editingTemplate, description: e.target.value })}/>
                    </div>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <Checkbox checked={editingTemplate.allow_custom_habits} onCheckedChange={(v) => setEditingTemplate({ ...editingTemplate, allow_custom_habits: !!v })}/>
                      <span className="text-sm">Allow custom habits</span>
                    </label>
                    <div className="flex justify-end gap-2">
                      <Button variant="outline" onClick={() => setEditingTemplate(null)}>Cancel</Button>
                      <Button onClick={handleUpdateTemplate}>Save</Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            )}
          </CardContent>
        </Card>

        {/* Mapping editor */}
        <Card className="lg:col-span-2 border-card-border">
          <CardHeader className="sticky top-0 bg-background z-10 border-b">
            <CardTitle>Template Habits</CardTitle>
            <CardDescription>
              Include habits in the selected template and mark required vs bonus
            </CardDescription>
          </CardHeader>
          <CardContent>
            {!selectedTemplateId ? (
              <div className="text-sm text-muted-foreground">Select a template to edit mappings</div>
            ) : (
              <div className="space-y-4">
                {/* Template Summary - Sticky */}
                {templateSummary && (
                  <div className="sticky top-16 bg-background z-10 pb-4 border-b">
                    <Card className="border-primary/20 bg-primary/5">
                      <CardContent className="p-4">
                        <div className="flex items-center justify-between mb-3">
                          <div>
                            <h3 className="font-medium text-primary">Selected Template Summary</h3>
                            <div className="text-sm text-muted-foreground">
                              {templateSummary.totalCount} total habits • {templateSummary.coreCount} core • {templateSummary.bonusCount} bonus
                            </div>
                          </div>
                          <div className="flex gap-2">
                            <Badge variant="destructive">{templateSummary.coreCount} CORE</Badge>
                            <Badge variant="secondary">{templateSummary.bonusCount} BONUS</Badge>
                          </div>
                        </div>
                        
                        {templateSummary.coreHabits.length > 0 && (
                          <div className="mb-3">
                            <h4 className="text-sm font-medium text-primary mb-2">Core Habits:</h4>
                            <div className="flex flex-wrap gap-1">
                              {templateSummary.coreHabits.map(h => (
                                <Badge key={h.id} variant="outline" className="text-xs">
                                  {h.title}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        )}
                        
                        {templateSummary.bonusHabits.length > 0 && (
                          <div>
                            <h4 className="text-sm font-medium text-primary mb-2">Bonus Habits:</h4>
                            <div className="flex flex-wrap gap-1">
                              {templateSummary.bonusHabits.map(h => (
                                <Badge key={h.id} variant="outline" className="text-xs">
                                  {h.title}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  </div>
                )}

                <div className="flex items-center gap-2">
                  <Search className="w-4 h-4 text-muted-foreground"/>
                  <Input placeholder="Search habits..." value={search} onChange={(e) => setSearch(e.target.value)} />
                </div>

                <div className="grid gap-3">
                  {filteredHabits.map(h => {
                    const m = mappingByHabitId[h.id];
                    return (
                      <div key={h.id} className={`p-3 border rounded-lg flex flex-col sm:flex-row sm:items-center gap-3 ${m.included? 'border-primary/40 bg-primary/5':'border-card-border'}`}>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <Checkbox checked={m.included} onCheckedChange={(v) => {
                              const exists = templateHabits.find(th => th.habit_id === h.id);
                              if (v && !exists) {
                                setTemplateHabits(prev => [...prev, { id: crypto.randomUUID(), template_id: selectedTemplateId!, habit_id: h.id, is_core: true, points_override: null, sort_order: prev.length + 1 } as any]);
                              } else if (!v && exists) {
                                setTemplateHabits(prev => prev.filter(x => x.habit_id !== h.id));
                              }
                            }}/>
                            <div className="font-medium truncate">{h.title}</div>
                            {m.included && (
                              <Badge variant={m.is_core ? 'destructive' : 'secondary'}>{m.is_core ? 'CORE' : 'BONUS'}</Badge>
                            )}
                          </div>
                          <div className="text-xs text-muted-foreground truncate">{h.description}</div>
                        </div>
                        {m.included && (
                          <div className="flex items-center gap-3 flex-wrap">
                            <label className="flex items-center gap-2 cursor-pointer">
                              <Checkbox checked={m.is_core} onCheckedChange={(v) => {
                                setTemplateHabits(prev => prev.map(th => th.habit_id === h.id ? { ...th, is_core: !!v } : th));
                              }}/>
                              <span className="text-sm">Core</span>
                            </label>
                            <div className="flex items-center gap-2">
                              <Label className="text-xs">Points</Label>
                              <Input className="w-24" type="number" placeholder={String(h.points)} value={m.points_override ?? ''}
                                onChange={(e) => setTemplateHabits(prev => prev.map(th => th.habit_id === h.id ? { ...th, points_override: e.target.value === '' ? null : parseInt(e.target.value) } : th))}/>
                            </div>
                            <div className="flex items-center gap-2">
                              <Label className="text-xs">Order</Label>
                              <Input className="w-20" type="number" value={m.sort_order ?? ''} onChange={(e) => setTemplateHabits(prev => prev.map(th => th.habit_id === h.id ? { ...th, sort_order: e.target.value === '' ? null : parseInt(e.target.value) } : th))}/>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>

                <div className="flex justify-end">
                  <Button onClick={handleSaveMappings} disabled={saving}> 
                    <Save className="w-4 h-4 mr-2"/>
                    {saving? 'Saving...':'Save Mappings'}
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}


