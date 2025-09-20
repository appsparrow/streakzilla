import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { User } from "lucide-react";

interface StreakmateHabitsModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  member: {
    user_id: string;
    display_name: string;
    habits: Array<{
      id: string;
      title: string;
      description: string;
      points: number;
      category: string;
    }>;
  };
}

export function StreakmateHabitsModal({ open, onOpenChange, member }: StreakmateHabitsModalProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
        <DialogHeader className="flex-shrink-0">
          <DialogTitle className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-gradient-to-r from-primary/20 to-primary/40 flex items-center justify-center">
              <span className="font-medium text-primary">
                {member.display_name?.charAt(0) || "U"}
              </span>
            </div>
            <span>{member.display_name}'s Habits</span>
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-3 mt-2 overflow-y-auto flex-1 pr-2">
          {member.habits.map((habit) => (
            <Card key={habit.id} className="border-card-border">
              <CardContent className="p-3">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex-1">
                    <h4 className="font-medium">{habit.title}</h4>
                    <p className="text-sm text-muted-foreground">{habit.description}</p>
                  </div>
                  <div className="flex items-center gap-2 self-start sm:self-auto">
                    <span className="text-sm font-medium">{habit.points} pts</span>
                    <Badge variant="secondary">{habit.category}</Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
