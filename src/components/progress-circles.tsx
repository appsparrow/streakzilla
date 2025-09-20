import React, { useState } from 'react';
import { Heart, Eye, EyeOff, Target } from 'lucide-react';
import { cn } from "@/lib/utils";

interface ProgressCirclesProps {
  currentDay: number;
  totalDays: number;
  completedDays?: number[];
  missedDays?: number[];
  heartsUsed?: number[];
  className?: string;
}

export function ProgressCircles({ 
  currentDay, 
  totalDays, 
  completedDays = [], 
  missedDays = [],
  heartsUsed = [],
  className
}: ProgressCirclesProps) {
  const [showDetails, setShowDetails] = useState(false);

  const getDayStatus = (day: number) => {
    if (completedDays.includes(day)) return 'completed';
    if (missedDays.includes(day)) return 'missed';
    if (day === currentDay) return 'current';
    return 'upcoming';
  };

  return (
    <div className={cn("space-y-3", className)}>
      {/* Toggle Button */}
      <div className="flex items-center gap-2">
        <button
          onClick={() => setShowDetails(!showDetails)}
          className="flex items-center gap-1 text-xs text-gray-600 hover:text-gray-800 transition-colors"
        >
          {showDetails ? <EyeOff className="w-3 h-3" /> : <Eye className="w-3 h-3" />}
          {showDetails ? 'Hide Details' : 'Show Details'}
        </button>
      </div>

      {/* Multi-line Progress Grid */}
      <div className="flex flex-wrap gap-0.5 max-w-full">
        {Array.from({ length: totalDays }, (_, index) => {
          const day = index + 1;
          const status = getDayStatus(day);
          const hasHeart = heartsUsed.includes(day);
          
          return (
            <div
              key={day}
              className={cn(
                "w-3 h-3 rounded-sm flex items-center justify-center text-xs font-medium cursor-pointer transition-all hover:scale-110",
                {
                  'bg-green-500': status === 'completed',
                  'bg-red-500': status === 'missed',
                  'bg-orange-500 animate-pulse': status === 'current',
                  'bg-gray-200': status === 'upcoming'
                }
              )}
              title={`Day ${day}${hasHeart ? ' (Heart used)' : ''} - ${status}`}
            >
              {hasHeart ? (
                <Heart className="w-2 h-2 text-pink-500" />
              ) : showDetails ? (
                <span className="text-xs text-white font-bold">{day}</span>
              ) : null}
            </div>
          );
        })}
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-xs text-gray-600 flex-wrap">
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 bg-green-500 rounded-sm"></div>
          <span>Completed</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 bg-red-500 rounded-sm"></div>
          <span>Missed</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 bg-orange-500 rounded-sm"></div>
          <span>Today</span>
        </div>
        <div className="flex items-center gap-1">
          <Heart className="w-2 h-2 text-pink-500" />
          <span>Heart Used</span>
        </div>
      </div>
    </div>
  );
}

interface ProgressCirclesCompactProps {
  currentDay: number;
  totalDays: number;
  completedDays?: number[];
  missedDays?: number[];
  heartsUsed?: number[];
  className?: string;
}

export function ProgressCirclesCompact({ 
  currentDay, 
  totalDays, 
  completedDays = [], 
  missedDays = [],
  heartsUsed = [],
  className
}: ProgressCirclesCompactProps) {
  const getDayStatus = (day: number) => {
    if (completedDays.includes(day)) return 'completed';
    if (missedDays.includes(day)) return 'missed';
    if (day === currentDay) return 'current';
    return 'upcoming';
  };

  return (
    <div className={cn("flex flex-wrap gap-0.5 max-w-full", className)}>
      {Array.from({ length: totalDays }, (_, index) => {
        const day = index + 1;
        const status = getDayStatus(day);
        const hasHeart = heartsUsed.includes(day);
        
        return (
          <div
            key={day}
            className={cn(
              "w-2 h-2 rounded-sm flex items-center justify-center cursor-pointer transition-all hover:scale-125",
              {
                'bg-green-500': status === 'completed',
                'bg-red-500': status === 'missed',
                'bg-orange-500 animate-pulse': status === 'current',
                'bg-gray-200': status === 'upcoming'
              }
            )}
            title={`Day ${day}${hasHeart ? ' (Heart used)' : ''} - ${status}`}
          >
            {hasHeart && (
              <Heart className="w-1.5 h-1.5 text-pink-500" />
            )}
          </div>
        );
      })}
    </div>
  );
}

interface CircularProgressProps {
  currentDay: number;
  totalDays: number;
  completedDays?: number[];
  missedDays?: number[];
  heartsUsed?: number[];
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function CircularProgress({ 
  currentDay, 
  totalDays, 
  completedDays = [], 
  missedDays = [],
  heartsUsed = [],
  className,
  size = 'md'
}: CircularProgressProps) {
  const sizeClasses = {
    sm: 'w-16 h-16',
    md: 'w-24 h-24',
    lg: 'w-32 h-32'
  };

  const strokeWidth = size === 'sm' ? 2 : size === 'md' ? 3 : 4;
  const radius = size === 'sm' ? 28 : size === 'md' ? 42 : size === 'lg' ? 56 : 42;
  const circumference = 2 * Math.PI * radius;
  
  const completedCount = completedDays.length;
  const missedCount = missedDays.length;
  const heartsCount = heartsUsed.length;
  
  const completedPercentage = (completedCount / totalDays) * 100;
  const missedPercentage = (missedCount / totalDays) * 100;
  const heartsPercentage = (heartsCount / totalDays) * 100;
  
  const completedStrokeDasharray = `${(completedPercentage / 100) * circumference} ${circumference}`;
  const missedStrokeDasharray = `${(missedPercentage / 100) * circumference} ${circumference}`;
  const heartsStrokeDasharray = `${(heartsPercentage / 100) * circumference} ${circumference}`;

  return (
    <div className={cn("relative flex items-center justify-center", className)}>
      <svg className={cn("transform -rotate-90", sizeClasses[size])}>
        {/* Background circle */}
        <circle
          cx={radius + strokeWidth}
          cy={radius + strokeWidth}
          r={radius}
          fill="none"
          stroke="#e5e7eb"
          strokeWidth={strokeWidth}
        />
        
        {/* Completed days (green) */}
        <circle
          cx={radius + strokeWidth}
          cy={radius + strokeWidth}
          r={radius}
          fill="none"
          stroke="#10b981"
          strokeWidth={strokeWidth}
          strokeDasharray={completedStrokeDasharray}
          strokeLinecap="round"
          className="transition-all duration-500"
        />
        
        {/* Missed days (red) */}
        {missedCount > 0 && (
          <circle
            cx={radius + strokeWidth}
            cy={radius + strokeWidth}
            r={radius}
            fill="none"
            stroke="#ef4444"
            strokeWidth={strokeWidth}
            strokeDasharray={missedStrokeDasharray}
            strokeDashoffset={-((completedPercentage / 100) * circumference)}
            strokeLinecap="round"
            className="transition-all duration-500"
          />
        )}
        
        {/* Hearts used (pink) */}
        {heartsCount > 0 && (
          <circle
            cx={radius + strokeWidth}
            cy={radius + strokeWidth}
            r={radius}
            fill="none"
            stroke="#ec4899"
            strokeWidth={strokeWidth}
            strokeDasharray={heartsStrokeDasharray}
            strokeDashoffset={-(((completedPercentage + missedPercentage) / 100) * circumference)}
            strokeLinecap="round"
            className="transition-all duration-500"
          />
        )}
      </svg>
      
      {/* Center content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <Target className={cn("text-gray-600", size === 'sm' ? 'w-4 h-4' : size === 'md' ? 'w-6 h-6' : 'w-8 h-8')} />
        <span className={cn("font-bold text-gray-800", size === 'sm' ? 'text-xs' : size === 'md' ? 'text-sm' : 'text-base')}>
          {currentDay}
        </span>
        <span className={cn("text-gray-500", size === 'sm' ? 'text-xs' : 'text-xs')}>
          /{totalDays}
        </span>
      </div>
      
      {/* Legend */}
      <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 flex gap-2 text-xs">
        <div className="flex items-center gap-1">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span className="text-gray-600">{completedCount}</span>
        </div>
        {missedCount > 0 && (
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 bg-red-500 rounded-full"></div>
            <span className="text-gray-600">{missedCount}</span>
          </div>
        )}
        {heartsCount > 0 && (
          <div className="flex items-center gap-1">
            <Heart className="w-2 h-2 text-pink-500" />
            <span className="text-gray-600">{heartsCount}</span>
          </div>
        )}
      </div>
    </div>
  );
}