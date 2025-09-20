-- Simple Heart System Migration
-- Run this in your Supabase SQL Editor

-- Add heart columns to sz_streak_members
ALTER TABLE public.sz_streak_members 
ADD COLUMN IF NOT EXISTS hearts_earned INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS hearts_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS hearts_available INTEGER DEFAULT 0;

-- Add heart settings to sz_streaks
ALTER TABLE public.sz_streaks
ADD COLUMN IF NOT EXISTS points_to_hearts_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS hearts_per_100_points INTEGER DEFAULT 1;

-- Heart transactions table removed - keeping it simple

-- Function to calculate hearts from points
CREATE OR REPLACE FUNCTION public.sz_calculate_hearts_from_points(
  p_points INTEGER,
  p_hearts_per_100_points INTEGER DEFAULT 1
) RETURNS INTEGER AS $$
BEGIN
  RETURN (p_points / 100) * p_hearts_per_100_points;
END;
$$ LANGUAGE plpgsql;

-- Heart gifting function removed - keeping it simple

-- Update existing members with initial hearts
UPDATE public.sz_streak_members
SET 
  hearts_earned = public.sz_calculate_hearts_from_points(total_points, 1),
  hearts_available = GREATEST(0, public.sz_calculate_hearts_from_points(total_points, 1) - COALESCE(hearts_used, 0))
WHERE hearts_earned IS NULL OR hearts_earned = 0;

SELECT 'Heart system migration completed successfully!' as status;
