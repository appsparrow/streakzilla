import { Heart } from "lucide-react";

interface Progress75CirclesProps {
  currentDay: number;
  totalDays: number;
  missedDays?: number[];
  heartsUsed?: number[];
  className?: string;
}

export function Progress75Circles({ 
  currentDay, 
  totalDays, 
  missedDays = [], 
  heartsUsed = [],
  className = "" 
}: Progress75CirclesProps) {
  const getDayStatus = (day: number) => {
    if (heartsUsed.includes(day)) {
      return 'heart-used';
    }
    if (missedDays.includes(day)) {
      return 'missed';
    }
    if (day < currentDay) {
      return 'completed';
    }
    if (day === currentDay) {
      return 'current';
    }
    return 'future';
  };

  const getStatusClasses = (status: string) => {
    switch (status) {
      case 'completed':
        return 'fill-green-500 text-green-500';
      case 'current':
        return 'fill-orange-500 text-orange-500 animate-pulse';
      case 'missed':
        return 'fill-red-500 text-red-500';
      case 'heart-used':
        return 'fill-pink-500 text-pink-500';
      default:
        return 'fill-gray-300 text-gray-300';
    }
  };

  const renderDayIcon = (day: number, status: string) => {
    if (status === 'heart-used') {
      // Use custom heart icon when a heart protected the day
      return <img src="/icon-streakheart.svg" alt="Heart Used" className="w-4 h-4" />;
    }
    
    return (
      <svg width="16" height="16" viewBox="0 0 520 520" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path 
          d="M281.658 6.39175C290.778 -6.84085 303.778 12.5186 296.751 28.8694L237.468 166.83C232.734 177.845 237.354 193.027 245.423 193.499L245.81 193.51L438.448 193.51C447.723 193.51 452.212 212.261 445.445 222.738L256.741 514.912L256.541 515.215C248.055 527.785 235.238 511.214 240.764 494.487L285.164 360.11C288.826 349.025 284.102 335.543 276.545 335.125L276.184 335.115L276.184 292.868C293.935 292.868 322.228 292.868 351.851 292.868C368.555 292.868 382.097 279.326 382.097 262.622V262.622C382.097 245.919 368.556 232.377 351.852 232.377L241.207 232.377L193.648 232.377C177.43 232.377 164.099 245.168 163.428 261.371V261.371C162.717 278.551 176.444 292.868 193.638 292.868C217.721 292.868 250.957 292.868 276.184 292.868L276.184 335.115L82.2507 335.115L82.0309 335.111C72.7461 334.814 68.4649 315.727 75.4995 305.52L281.658 6.39175Z" 
          className={getStatusClasses(status)}
        />
      </svg>
    );
  };

  return (
    <div className={`space-y-3 ${className}`}>
      <div className="flex justify-between items-center">
        <h3 className="text-sm font-medium">Daily Progress</h3>
        <span className="text-xs text-muted-foreground">
          {currentDay}/{totalDays} days
        </span>
      </div>
      
      <div className="grid grid-cols-10 gap-1">
        {Array.from({ length: totalDays }, (_, index) => {
          const day = index + 1;
          const status = getDayStatus(day);
          
          return (
            <div 
              key={day}
              className={`
                w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium
                ${status === 'future' ? 'bg-gray-100' : ''}
                ${status === 'completed' ? 'bg-green-100' : ''}
                ${status === 'current' ? 'bg-orange-100' : ''}
                ${status === 'missed' ? 'bg-red-100' : ''}
                ${status === 'heart-used' ? 'bg-pink-100' : ''}
              `}
              title={`Day ${day}${status === 'heart-used' ? ' (Heart Used)' : status === 'missed' ? ' (Missed)' : status === 'completed' ? ' (Completed)' : status === 'current' ? ' (Current)' : ' (Future)'}`}
            >
              {renderDayIcon(day, status)}
            </div>
          );
        })}
      </div>
      
      <div className="flex flex-wrap gap-4 text-xs text-muted-foreground">
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded-full bg-green-100 flex items-center justify-center">
            <svg width="12" height="12" viewBox="0 0 520 520" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M281.658 6.39175C290.778 -6.84085 303.778 12.5186 296.751 28.8694L237.468 166.83C232.734 177.845 237.354 193.027 245.423 193.499L245.81 193.51L438.448 193.51C447.723 193.51 452.212 212.261 445.445 222.738L256.741 514.912L256.541 515.215C248.055 527.785 235.238 511.214 240.764 494.487L285.164 360.11C288.826 349.025 284.102 335.543 276.545 335.125L276.184 335.115L276.184 292.868C293.935 292.868 322.228 292.868 351.851 292.868C368.555 292.868 382.097 279.326 382.097 262.622V262.622C382.097 245.919 368.556 232.377 351.852 232.377L241.207 232.377L193.648 232.377C177.43 232.377 164.099 245.168 163.428 261.371V261.371C162.717 278.551 176.444 292.868 193.638 292.868C217.721 292.868 250.957 292.868 276.184 292.868L276.184 335.115L82.2507 335.115L82.0309 335.111C72.7461 334.814 68.4649 315.727 75.4995 305.52L281.658 6.39175Z" className="fill-green-500" />
            </svg>
          </div>
          <span>Completed</span>
        </div>
        
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded-full bg-orange-100 flex items-center justify-center">
            <svg width="12" height="12" viewBox="0 0 520 520" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M281.658 6.39175C290.778 -6.84085 303.778 12.5186 296.751 28.8694L237.468 166.83C232.734 177.845 237.354 193.027 245.423 193.499L245.81 193.51L438.448 193.51C447.723 193.51 452.212 212.261 445.445 222.738L256.741 514.912L256.541 515.215C248.055 527.785 235.238 511.214 240.764 494.487L285.164 360.11C288.826 349.025 284.102 335.543 276.545 335.125L276.184 335.115L276.184 292.868C293.935 292.868 322.228 292.868 351.851 292.868C368.555 292.868 382.097 279.326 382.097 262.622V262.622C382.097 245.919 368.556 232.377 351.852 232.377L241.207 232.377L193.648 232.377C177.43 232.377 164.099 245.168 163.428 261.371V261.371C162.717 278.551 176.444 292.868 193.638 292.868C217.721 292.868 250.957 292.868 276.184 292.868L276.184 335.115L82.2507 335.115L82.0309 335.111C72.7461 334.814 68.4649 315.727 75.4995 305.52L281.658 6.39175Z" className="fill-orange-500" />
            </svg>
          </div>
          <span>Current</span>
        </div>
        
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded-full bg-red-100 flex items-center justify-center">
            <svg width="12" height="12" viewBox="0 0 520 520" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M281.658 6.39175C290.778 -6.84085 303.778 12.5186 296.751 28.8694L237.468 166.83C232.734 177.845 237.354 193.027 245.423 193.499L245.81 193.51L438.448 193.51C447.723 193.51 452.212 212.261 445.445 222.738L256.741 514.912L256.541 515.215C248.055 527.785 235.238 511.214 240.764 494.487L285.164 360.11C288.826 349.025 284.102 335.543 276.545 335.125L276.184 335.115L276.184 292.868C293.935 292.868 322.228 292.868 351.851 292.868C368.555 292.868 382.097 279.326 382.097 262.622V262.622C382.097 245.919 368.556 232.377 351.852 232.377L241.207 232.377L193.648 232.377C177.43 232.377 164.099 245.168 163.428 261.371V261.371C162.717 278.551 176.444 292.868 193.638 292.868C217.721 292.868 250.957 292.868 276.184 292.868L276.184 335.115L82.2507 335.115L82.0309 335.111C72.7461 334.814 68.4649 315.727 75.4995 305.52L281.658 6.39175Z" className="fill-red-500" />
            </svg>
          </div>
          <span>Missed</span>
        </div>
        
        <div className="flex items-center gap-1">
          <div className="w-3 h-3 rounded-full bg-pink-100 flex items-center justify-center">
            <Heart className="w-3 h-3 text-pink-500" />
          </div>
          <span>Heart Used</span>
        </div>
      </div>
    </div>
  );
}
