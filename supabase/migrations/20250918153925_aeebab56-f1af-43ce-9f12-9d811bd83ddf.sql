-- Add DELETE policy for sz_streaks table to allow creators and admins to delete their streaks
CREATE POLICY "Creators and admins can delete streaks" ON public.sz_streaks
FOR DELETE USING (
  auth.uid() = created_by OR 
  EXISTS (
    SELECT 1 FROM public.sz_streak_members sm 
    WHERE sm.streak_id = sz_streaks.id 
    AND sm.user_id = auth.uid() 
    AND sm.role = 'admin'
  )
);