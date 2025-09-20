import { useParams, useNavigate } from "react-router-dom";
import { PageHeader } from "@/components/layout/page-header";
import { HabitSelection } from "@/components/habit-selection";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { useStreak } from "@/hooks/useStreak";
import { useAuth } from "@/hooks/useAuth";

export default function SelectHabits() {
  const { id: streakId } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { streak, loading } = useStreak(streakId!);

  if (!user || !streakId) {
    navigate("/auth");
    return null;
  }

  if (loading) {
    return (
      <div className="container mx-auto p-4 max-w-4xl">
        <div className="text-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-4" />
          <p className="text-muted-foreground">Loading streak details...</p>
        </div>
      </div>
    );
  }

  if (!streak) {
    navigate(`/streak/${streakId}`);
    return null;
  }

  const handleComplete = () => {
    navigate(`/streak/${streakId}`);
  };

  return (
    <div className="container mx-auto p-4 max-w-4xl">
      <PageHeader
        title="Select Your Habits"
        subtitle={`Choose the habits you'll commit to for your ${streak.mode} challenge`}
      >
        <Button
          variant="ghost"
          onClick={() => navigate(`/streak/${streakId}`)}
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Streak
        </Button>
      </PageHeader>

      <HabitSelection
        streakId={streakId}
        mode={streak.mode}
        onComplete={handleComplete}
      />
    </div>
  );
}