import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Lightbulb, Quote, HelpCircle, Smile } from "lucide-react";
import inspireContent from "@/data/inspire-content.json";

interface InspireItem {
  type: "quote" | "trivia" | "joke";
  text?: string;
  question?: string;
  answer?: string;
}

interface InspireSectionProps {
  currentDay: number;
  className?: string;
}

export function InspireSection({ currentDay, className = "" }: InspireSectionProps) {
  const [showAnswer, setShowAnswer] = useState(false);
  const [currentItem, setCurrentItem] = useState<InspireItem | null>(null);

  // Get the inspire item for the current day (cycles through the array)
  useEffect(() => {
    const itemIndex = (currentDay - 1) % inspireContent.length;
    setCurrentItem(inspireContent[itemIndex] as InspireItem);
    setShowAnswer(false);
  }, [currentDay]);

  const handleShowAnswer = () => {
    setShowAnswer(true);
  };

  const getIcon = () => {
    if (!currentItem) return <Lightbulb className="w-5 h-5" />;
    
    switch (currentItem.type) {
      case "quote":
        return <Quote className="w-5 h-5" />;
      case "trivia":
        return <HelpCircle className="w-5 h-5" />;
      case "joke":
        return <Smile className="w-5 h-5" />;
      default:
        return <Lightbulb className="w-5 h-5" />;
    }
  };

  const getTitle = () => {
    if (!currentItem) return "Daily Inspiration";
    
    switch (currentItem.type) {
      case "quote":
        return "Daily Quote";
      case "trivia":
        return "Daily Trivia";
      case "joke":
        return "Daily Joke";
      default:
        return "Daily Inspiration";
    }
  };

  const getBackgroundColor = () => {
    if (!currentItem) return "bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200";
    
    switch (currentItem.type) {
      case "quote":
        return "bg-gradient-to-r from-purple-50 to-pink-50 border-purple-200";
      case "trivia":
        return "bg-gradient-to-r from-green-50 to-emerald-50 border-green-200";
      case "joke":
        return "bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200";
      default:
        return "bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200";
    }
  };

  const getTextColor = () => {
    if (!currentItem) return "text-blue-700";
    
    switch (currentItem.type) {
      case "quote":
        return "text-purple-700";
      case "trivia":
        return "text-green-700";
      case "joke":
        return "text-yellow-700";
      default:
        return "text-blue-700";
    }
  };

  if (!currentItem) {
    return null;
  }

  return (
    <Card className={`border-card-border ${className}`}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {getIcon()}
          {getTitle()}
          <span className="text-sm font-normal text-muted-foreground">
            Day {currentDay}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className={`${getBackgroundColor()} rounded-lg p-4`}>
        {currentItem.type === "quote" && (
          <div className="text-center">
            <blockquote className={`text-lg font-medium ${getTextColor()} italic`}>
              "{currentItem.text}"
            </blockquote>
          </div>
        )}

        {currentItem.type === "joke" && (
          <div className="text-center">
            <p className={`text-lg font-medium ${getTextColor()}`}>
              {currentItem.text}
            </p>
          </div>
        )}

        {currentItem.type === "trivia" && (
          <div className="space-y-4">
            <div className="text-center">
              <p className={`text-lg font-medium ${getTextColor()} mb-4`}>
                {currentItem.question}
              </p>
              
              {!showAnswer ? (
                <Button
                  onClick={handleShowAnswer}
                  variant="outline"
                  className="bg-white hover:bg-gray-50"
                >
                  Show Answer
                </Button>
              ) : (
                <div className="bg-white rounded-lg p-4 border-2 border-green-300">
                  <p className="text-lg font-semibold text-green-700">
                    {currentItem.answer}
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
