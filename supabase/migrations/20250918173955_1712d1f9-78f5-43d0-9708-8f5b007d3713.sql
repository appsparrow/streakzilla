-- Fix 75 Hard Plus habit categorization and points
-- Core habits should have 0 points, bonus habits should have points

-- Update core 75 Hard habits to have 0 points and mark them as core
UPDATE sz_habits 
SET points = 0, category = 'core'
WHERE template_set = '75_hard_plus' AND title IN (
  'Drink 1 gallon of water',
  'Two 45-minute workouts', 
  'Read 10 pages of non-fiction',
  'Follow a diet',
  'Take a progress photo'
);

-- Update bonus habits to keep their points and mark them as bonus
UPDATE sz_habits 
SET category = 'bonus'
WHERE template_set = '75_hard_plus' AND title IN (
  'Cold shower/ice bath',
  '10 minutes of meditation'
);

-- Fix RLS policy for streak deletion - allow admins to update is_active to false
DROP POLICY IF EXISTS "Creators and admins can update streaks" ON sz_streaks;
CREATE POLICY "Creators and admins can update streaks" ON sz_streaks
FOR UPDATE USING (
  (auth.uid() = created_by) OR 
  (EXISTS (
    SELECT 1 FROM sz_streak_members sm
    WHERE sm.streak_id = sz_streaks.id 
    AND sm.user_id = auth.uid() 
    AND sm.role = 'admin'
  ))
);