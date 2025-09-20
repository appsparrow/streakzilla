-- Create sz_streaks table (equivalent to groups in existing schema)
CREATE TABLE public.sz_streaks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  mode TEXT NOT NULL, -- '75_hard', '75_hard_plus', '75_custom', 'custom'
  start_date DATE NOT NULL,
  duration_days INTEGER NOT NULL DEFAULT 75,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  is_active BOOLEAN DEFAULT true
);

-- Create sz_streak_members table
CREATE TABLE public.sz_streak_members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  streak_id UUID NOT NULL,
  user_id UUID NOT NULL,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  current_streak INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  lives_remaining INTEGER DEFAULT 3,
  is_out BOOLEAN DEFAULT false,
  UNIQUE(streak_id, user_id)
);

-- Create sz_habits table (powers/tasks)
CREATE TABLE public.sz_habits (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  points INTEGER DEFAULT 1,
  frequency TEXT DEFAULT 'daily',
  template_set TEXT, -- '75_hard', '75_hard_plus', '75_custom', 'custom'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create sz_user_habits table (which habits user selected for a streak)
CREATE TABLE public.sz_user_habits (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  streak_id UUID NOT NULL,
  user_id UUID NOT NULL,
  habit_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(streak_id, user_id, habit_id)
);

-- Create sz_checkins table
CREATE TABLE public.sz_checkins (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  streak_id UUID NOT NULL,
  user_id UUID NOT NULL,
  day_number INTEGER NOT NULL,
  completed_habit_ids UUID[] DEFAULT '{}',
  points_earned INTEGER DEFAULT 0,
  note TEXT,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create sz_posts table for daily photos
CREATE TABLE public.sz_posts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  streak_id UUID NOT NULL,
  user_id UUID NOT NULL,
  day_number INTEGER NOT NULL,
  photo_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.sz_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_streak_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_user_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sz_posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for sz_streaks
CREATE POLICY "Anyone can view active streaks" ON public.sz_streaks
  FOR SELECT USING (is_active = true);

CREATE POLICY "Users can create streaks" ON public.sz_streaks
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creators can update their streaks" ON public.sz_streaks
  FOR UPDATE USING (auth.uid() = created_by);

-- RLS Policies for sz_streak_members
CREATE POLICY "Users can view their memberships" ON public.sz_streak_members
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Streak members can view other members" ON public.sz_streak_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_streak_members.streak_id AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join streaks" ON public.sz_streak_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own membership" ON public.sz_streak_members
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for sz_habits
CREATE POLICY "Anyone can view habits" ON public.sz_habits
  FOR SELECT USING (true);

-- RLS Policies for sz_user_habits
CREATE POLICY "Users can manage their own habits" ON public.sz_user_habits
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Streak members can view habits" ON public.sz_user_habits
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_user_habits.streak_id AND sm.user_id = auth.uid()
    )
  );

-- RLS Policies for sz_checkins
CREATE POLICY "Users can manage their own checkins" ON public.sz_checkins
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Streak members can view checkins" ON public.sz_checkins
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_checkins.streak_id AND sm.user_id = auth.uid()
    )
  );

-- RLS Policies for sz_posts
CREATE POLICY "Users can manage their own posts" ON public.sz_posts
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Streak members can view posts" ON public.sz_posts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.sz_streak_members sm
      WHERE sm.streak_id = sz_posts.streak_id AND sm.user_id = auth.uid()
    )
  );

-- Insert default habits for 75 Hard template
INSERT INTO public.sz_habits (title, description, category, points, template_set) VALUES
('Workout (45 min)', 'Complete a 45-minute workout', 'fitness', 2, '75_hard'),
('Diet', 'Follow your chosen diet with no cheat meals', 'nutrition', 2, '75_hard'),
('Water (1 gallon)', 'Drink 1 gallon of water', 'health', 1, '75_hard'),
('Read (10 pages)', 'Read 10 pages of non-fiction', 'personal_development', 1, '75_hard'),
('Progress Photo', 'Take a daily progress photo', 'accountability', 1, '75_hard');

-- Insert habits for 75 Hard Plus template
INSERT INTO public.sz_habits (title, description, category, points, template_set) VALUES
('Workout (45 min)', 'Complete a 45-minute workout', 'fitness', 2, '75_hard_plus'),
('Diet', 'Follow your chosen diet with no cheat meals', 'nutrition', 2, '75_hard_plus'),
('Water (1 gallon)', 'Drink 1 gallon of water', 'health', 1, '75_hard_plus'),
('Read (10 pages)', 'Read 10 pages of non-fiction', 'personal_development', 1, '75_hard_plus'),
('Progress Photo', 'Take a daily progress photo', 'accountability', 1, '75_hard_plus'),
('Cold Shower (5 min)', 'Take a 5-minute cold shower', 'discipline', 1, '75_hard_plus'),
('Meditation (10 min)', 'Complete 10 minutes of meditation', 'mindfulness', 1, '75_hard_plus');

-- Insert habits for 75 Custom template
INSERT INTO public.sz_habits (title, description, category, points, template_set) VALUES
('Morning Routine', 'Complete your morning routine', 'lifestyle', 1, '75_custom'),
('Exercise', 'Complete any form of exercise', 'fitness', 2, '75_custom'),
('Healthy Eating', 'Eat according to your nutrition goals', 'nutrition', 2, '75_custom'),
('Learning', 'Spend time learning something new', 'personal_development', 1, '75_custom'),
('Gratitude', 'Write down 3 things you are grateful for', 'mindfulness', 1, '75_custom');

-- Create function to generate unique streak codes
CREATE OR REPLACE FUNCTION public.sz_generate_streak_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    code TEXT;
    exists_check INTEGER;
BEGIN
    LOOP
        -- Generate a 6-character alphanumeric code
        code := UPPER(
            SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 3) || 
            LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0')
        );
        
        -- Check if this code already exists
        SELECT COUNT(*) INTO exists_check 
        FROM sz_streaks 
        WHERE code = code;
        
        -- If code doesn't exist, we can use it
        IF exists_check = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$;

-- Create function to create a streak
CREATE OR REPLACE FUNCTION public.sz_create_streak(
    p_name TEXT,
    p_mode TEXT,
    p_start_date DATE,
    p_duration_days INTEGER DEFAULT 75
)
RETURNS TABLE(streak_id UUID, streak_code TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_streak_id UUID;
    v_streak_code TEXT;
    v_user_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Generate streak ID and code
    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    -- Create the streak
    INSERT INTO public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by)
    VALUES (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id);

    -- Add creator as admin member
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    VALUES (v_streak_id, v_user_id, 'admin', 3);

    -- Auto-assign template habits if it's a template mode
    IF p_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = p_mode;
    END IF;

    -- Return the created streak
    RETURN QUERY
    SELECT v_streak_id as streak_id, v_streak_code as streak_code;
END;
$$;

-- Create function to join a streak
CREATE OR REPLACE FUNCTION public.sz_join_streak(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_streak_id UUID;
    v_user_id UUID;
    v_mode TEXT;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Get streak ID and mode
    SELECT id, mode INTO v_streak_id, v_mode
    FROM public.sz_streaks 
    WHERE code = p_code AND is_active = true;
    
    IF v_streak_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or inactive streak code';
    END IF;
    
    -- Check if already a member
    IF EXISTS(
        SELECT 1 FROM public.sz_streak_members 
        WHERE streak_id = v_streak_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is already a member of this streak';
    END IF;
    
    -- Add user to streak
    INSERT INTO public.sz_streak_members (streak_id, user_id, role, lives_remaining) 
    VALUES (v_streak_id, v_user_id, 'member', 3);
    
    -- Auto-assign template habits if it's a template mode
    IF v_mode IN ('75_hard', '75_hard_plus', '75_custom') THEN
        INSERT INTO public.sz_user_habits (streak_id, user_id, habit_id)
        SELECT v_streak_id, v_user_id, h.id
        FROM public.sz_habits h
        WHERE h.template_set = v_mode;
    END IF;
    
    RETURN v_streak_id;
END;
$$;

-- Create function for daily check-in
CREATE OR REPLACE FUNCTION public.sz_checkin(
    p_streak_id UUID,
    p_day_number INTEGER,
    p_completed_habit_ids UUID[],
    p_note TEXT DEFAULT NULL,
    p_photo_url TEXT DEFAULT NULL
)
RETURNS TABLE(points_earned INTEGER, current_streak INTEGER, total_points INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    -- Create checkin record
    INSERT INTO sz_checkins (
        streak_id,
        user_id,
        day_number,
        completed_habit_ids,
        points_earned,
        note,
        photo_url
    ) VALUES (
        p_streak_id,
        v_user_id,
        p_day_number,
        p_completed_habit_ids,
        v_points,
        p_note,
        p_photo_url
    );

    -- Update user's points and streak
    UPDATE sz_streak_members
    SET 
        total_points = total_points + v_points,
        current_streak = current_streak + 1
    WHERE streak_id = p_streak_id AND user_id = v_user_id
    RETURNING current_streak, total_points INTO v_current_streak, v_total_points;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points;
END;
$$;