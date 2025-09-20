-- Fix the habit categorization for 75 Hard Plus mode
-- Update existing habits to proper categories and points
UPDATE sz_habits 
SET category = 'core', points = 0
WHERE template_set = '75_hard_plus' AND title IN (
  'Drink 1 gallon of water',
  'Two 45-minute workouts', 
  'Read 10 pages of non-fiction',
  'Follow a diet',
  'Take a progress photo'
);

UPDATE sz_habits 
SET category = 'bonus'
WHERE template_set = '75_hard_plus' AND title IN (
  'Cold shower/ice bath',
  '10 minutes of meditation'
);

-- Add progress photo points system - create a habit for automatic progress photo points
INSERT INTO sz_habits (title, description, points, category, template_set, frequency)
VALUES ('Progress Photo Points', 'Automatic points for uploading progress photo', 5, 'auto', 'system', 'daily')
ON CONFLICT DO NOTHING;

-- Fix RLS policy for streak deletion (set is_active to false instead of actual delete)
DROP POLICY IF EXISTS "Creators and admins can delete streaks" ON sz_streaks;
CREATE POLICY "Creators and admins can delete streaks" ON sz_streaks
FOR DELETE USING (
  (auth.uid() = created_by) OR 
  (EXISTS (
    SELECT 1 FROM sz_streak_members sm
    WHERE sm.streak_id = sz_streaks.id 
    AND sm.user_id = auth.uid() 
    AND sm.role = 'admin'
  ))
);