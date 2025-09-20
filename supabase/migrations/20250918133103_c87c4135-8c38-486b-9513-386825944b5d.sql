-- Create storage bucket for streak photos
INSERT INTO storage.buckets (id, name, public) VALUES ('streak-photos', 'streak-photos', false);

-- Create RLS policies for streak photos
CREATE POLICY "Users can upload their own photos"
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'streak-photos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own photos"
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'streak-photos' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Streak members can view each other's photos"
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'streak-photos' AND 
  EXISTS (
    SELECT 1 FROM public.sz_streak_members sm1, public.sz_streak_members sm2 
    WHERE sm1.user_id = auth.uid() 
    AND sm2.user_id::text = (storage.foldername(name))[1]
    AND sm1.streak_id = sm2.streak_id
  )
);