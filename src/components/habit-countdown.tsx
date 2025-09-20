import { Badge } from "@/components/ui/badge";
import { Clock } from "lucide-react";

interface HabitCountdownProps {
  streakStartDate: string;
}

export function HabitCountdown({ streakStartDate }: HabitCountdownProps) {
  // Calculate days since start
  const startDate = new Date(streakStartDate);
  const today = new Date();
  const diffTime = today.getTime() - startDate.getTime();
  const daysSinceStart = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  // Check if modifications are still allowed (first 3 days)
  const canModify = daysSinceStart <= 3;
  const daysRemaining = Math.max(0, 4 - daysSinceStart);
  
  if (!canModify) {
    return (
      <Badge variant="destructive" className="text-xs">
        <Clock className="w-3 h-3 mr-1" />
        Habits Frozen
      </Badge>
    );
  }
  
  if (daysRemaining === 0) {
    return (
      <Badge variant="secondary" className="text-xs border-yellow-300 text-yellow-700 bg-yellow-50">
        <Clock className="w-3 h-3 mr-1" />
        Last Day to Modify
      </Badge>
    );
  }
  
  return (
    <Badge variant="secondary" className="text-xs border-blue-300 text-blue-700 bg-blue-50">
      <Clock className="w-3 h-3 mr-1" />
      {daysRemaining} {daysRemaining === 1 ? 'day' : 'days'} left
    </Badge>
  );
}