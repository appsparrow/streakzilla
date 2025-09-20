-- Heart System Implementation
-- This migration adds the heart feature system to the streak tracking app

-- 1. Add heart-related columns to sz_streak_members
ALTER TABLE public.sz_streak_members 
ADD COLUMN IF NOT EXISTS hearts_earned INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS hearts_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS hearts_available INTEGER DEFAULT 0;

-- 2. Add heart sharing settings to sz_streaks
ALTER TABLE public.sz_streaks
ADD COLUMN IF NOT EXISTS heart_sharing_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS points_to_hearts_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS hearts_per_100_points INTEGER DEFAULT 1;

-- 3. Create hearts transactions table for sharing/gifting
CREATE TABLE IF NOT EXISTS public.sz_hearts_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  streak_id UUID NOT NULL REFERENCES public.sz_streaks(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hearts_amount INTEGER NOT NULL DEFAULT 1,
  transaction_type TEXT NOT NULL DEFAULT 'gift', -- 'gift', 'auto_use', 'earned'
  day_number INTEGER NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT sz_hearts_transactions_positive CHECK (hearts_amount > 0),
  CONSTRAINT sz_hearts_transactions_valid_type CHECK (transaction_type IN ('gift', 'auto_use', 'earned'))
);

-- 4. Create super-admin roles table
CREATE TABLE IF NOT EXISTS public.sz_user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user', -- 'user', 'super_admin', 'template_creator'
  granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, role)
);

-- 5. Update sz_habits to support global habit pool
ALTER TABLE public.sz_habits
ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Enable RLS on new tables
ALTER TABLE public.sz_hearts_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_user_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for sz_hearts_transactions
CREATE POLICY "Users can view their heart transactions" ON public.sz_hearts_transactions
  FOR SELECT USING (
    auth.uid() = from_user_id OR auth.uid() = to_user_id OR
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_hearts_transactions.streak_id 
      AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create heart transactions" ON public.sz_hearts_transactions
  FOR INSERT WITH CHECK (
    auth.uid() = from_user_id AND
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_hearts_transactions.streak_id 
      AND sm.user_id = auth.uid()
    )
  );

-- RLS Policies for sz_user_roles
CREATE POLICY "Users can view their own roles" ON public.sz_user_roles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Super admins can manage all roles" ON public.sz_user_roles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.sz_user_roles ur
      WHERE ur.user_id = auth.uid() 
      AND ur.role = 'super_admin' 
      AND ur.is_active = true
    )
  );

-- Function to calculate hearts from points
CREATE OR REPLACE FUNCTION public.sz_calculate_hearts_from_points(
  p_points INTEGER,
  p_hearts_per_100_points INTEGER DEFAULT 1
) RETURNS INTEGER AS $$
BEGIN
  RETURN (p_points / 100) * p_hearts_per_100_points;
END;
$$ LANGUAGE plpgsql;

-- Function to update hearts when points change
CREATE OR REPLACE FUNCTION public.sz_update_hearts_from_points()
RETURNS TRIGGER AS $$
DECLARE
  v_hearts_per_100 INTEGER;
  v_new_hearts_earned INTEGER;
BEGIN
  -- Get hearts per 100 points setting for this streak
  SELECT hearts_per_100_points INTO v_hearts_per_100
  FROM sz_streaks 
  WHERE id = NEW.streak_id;
  
  -- Calculate new hearts earned
  v_new_hearts_earned := public.sz_calculate_hearts_from_points(NEW.total_points, v_hearts_per_100);
  
  -- Update hearts_earned and hearts_available
  NEW.hearts_earned := v_new_hearts_earned;
  NEW.hearts_available := GREATEST(0, v_new_hearts_earned - NEW.hearts_used);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update hearts when points change
DROP TRIGGER IF EXISTS sz_update_hearts_trigger ON public.sz_streak_members;
CREATE TRIGGER sz_update_hearts_trigger
  BEFORE UPDATE ON public.sz_streak_members
  FOR EACH ROW
  WHEN (OLD.total_points IS DISTINCT FROM NEW.total_points)
  EXECUTE FUNCTION public.sz_update_hearts_from_points();

-- Function to automatically use hearts when streak is missed
CREATE OR REPLACE FUNCTION public.sz_auto_use_heart_on_miss(
  p_streak_id UUID,
  p_user_id UUID,
  p_day_number INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_hearts_available INTEGER;
  v_points_to_hearts_enabled BOOLEAN;
BEGIN
  -- Check if points-to-hearts is enabled for this streak
  SELECT points_to_hearts_enabled INTO v_points_to_hearts_enabled
  FROM sz_streaks 
  WHERE id = p_streak_id;
  
  IF NOT v_points_to_hearts_enabled THEN
    RETURN FALSE;
  END IF;
  
  -- Get current hearts available
  SELECT hearts_available INTO v_hearts_available
  FROM sz_streak_members
  WHERE streak_id = p_streak_id AND user_id = p_user_id;
  
  -- If no hearts available, return false
  IF v_hearts_available <= 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Use one heart
  UPDATE sz_streak_members
  SET 
    hearts_used = hearts_used + 1,
    hearts_available = hearts_available - 1
  WHERE streak_id = p_streak_id AND user_id = p_user_id;
  
  -- Record the transaction
  INSERT INTO sz_hearts_transactions (
    streak_id, from_user_id, to_user_id, hearts_amount, 
    transaction_type, day_number, note
  ) VALUES (
    p_streak_id, p_user_id, p_user_id, 1,
    'auto_use', p_day_number, 'Automatically used heart to protect streak'
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to gift hearts between users
CREATE OR REPLACE FUNCTION public.sz_gift_heart(
  p_streak_id UUID,
  p_to_user_id UUID,
  p_hearts_amount INTEGER DEFAULT 1,
  p_note TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_from_user_id UUID;
  v_hearts_available INTEGER;
  v_heart_sharing_enabled BOOLEAN;
  v_day_number INTEGER;
BEGIN
  v_from_user_id := auth.uid();
  
  -- Check if heart sharing is enabled for this streak
  SELECT heart_sharing_enabled INTO v_heart_sharing_enabled
  FROM sz_streaks 
  WHERE id = p_streak_id;
  
  IF NOT v_heart_sharing_enabled THEN
    RAISE EXCEPTION 'Heart sharing is not enabled for this streak';
  END IF;
  
  -- Check if both users are members of the streak
  IF NOT EXISTS (
    SELECT 1 FROM sz_streak_members 
    WHERE streak_id = p_streak_id AND user_id = v_from_user_id
  ) OR NOT EXISTS (
    SELECT 1 FROM sz_streak_members 
    WHERE streak_id = p_streak_id AND user_id = p_to_user_id
  ) THEN
    RAISE EXCEPTION 'Both users must be members of the streak';
  END IF;
  
  -- Get current hearts available for sender
  SELECT hearts_available INTO v_hearts_available
  FROM sz_streak_members
  WHERE streak_id = p_streak_id AND user_id = v_from_user_id;
  
  -- Check if sender has enough hearts
  IF v_hearts_available < p_hearts_amount THEN
    RAISE EXCEPTION 'Not enough hearts available to gift';
  END IF;
  
  -- Calculate current day number
  SELECT EXTRACT(DAY FROM (CURRENT_DATE - start_date)) + 1 INTO v_day_number
  FROM sz_streaks WHERE id = p_streak_id;
  
  -- Transfer hearts
  UPDATE sz_streak_members
  SET 
    hearts_used = hearts_used + p_hearts_amount,
    hearts_available = hearts_available - p_hearts_amount
  WHERE streak_id = p_streak_id AND user_id = v_from_user_id;
  
  UPDATE sz_streak_members
  SET 
    hearts_available = hearts_available + p_hearts_amount
  WHERE streak_id = p_streak_id AND user_id = p_to_user_id;
  
  -- Record the transaction
  INSERT INTO sz_hearts_transactions (
    streak_id, from_user_id, to_user_id, hearts_amount, 
    transaction_type, day_number, note
  ) VALUES (
    p_streak_id, v_from_user_id, p_to_user_id, p_hearts_amount,
    'gift', v_day_number, p_note
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing streak members to have initial hearts calculated
UPDATE public.sz_streak_members
SET 
  hearts_earned = public.sz_calculate_hearts_from_points(total_points, 1),
  hearts_available = GREATEST(0, public.sz_calculate_hearts_from_points(total_points, 1) - COALESCE(hearts_used, 0))
WHERE hearts_earned IS NULL OR hearts_earned = 0;
