import { cn } from "@/lib/utils";

export type StreakCircleState = "pending" | "current" | "complete" | "missed" | "life";

interface StreakCircleProps {
  day: number;
  state: StreakCircleState;
  onClick?: () => void;
  className?: string;
}

export function StreakCircle({ day, state, onClick, className }: StreakCircleProps) {
  const isClickable = state === "current" || state === "missed";
  
  return (
    <button
      onClick={onClick}
      disabled={!isClickable}
      className={cn(
        "streak-circle",
        {
          "streak-circle-pending": state === "pending",
          "streak-circle-current": state === "current",
          "streak-circle-complete": state === "complete", 
          "streak-circle-missed": state === "missed",
          "streak-circle-life": state === "life",
          "cursor-pointer hover:scale-110": isClickable,
          "cursor-default": !isClickable,
        },
        className
      )}
    >
      {day}
    </button>
  );
}