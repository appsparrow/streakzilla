-- Add more variety of habits for hard_plus mode and custom selection
INSERT INTO sz_habits (title, description, category, points, frequency, template_set) VALUES
-- Fitness variants
('Morning Yoga', '20 minutes of yoga or stretching', 'Fitness', 8, 'daily', 'custom'),
('Cold Shower', 'Take a cold shower for at least 2 minutes', 'Health', 5, 'daily', 'custom'),
('10,000 Steps', 'Walk or get 10,000 steps in a day', 'Fitness', 7, 'daily', 'custom'),
('Push-ups', 'Do 50 push-ups (can be broken into sets)', 'Fitness', 6, 'daily', 'custom'),
('Plank Challenge', 'Hold a plank for 3 minutes total', 'Fitness', 5, 'daily', 'custom'),

-- Mental Health & Mindfulness
('Meditation', '10 minutes of mindfulness or meditation', 'Mental Health', 8, 'daily', 'custom'),
('Gratitude Journal', 'Write 3 things you are grateful for', 'Mental Health', 6, 'daily', 'custom'),
('No Social Media', 'Avoid social media for the entire day', 'Mental Health', 10, 'daily', 'custom'),
('Deep Breathing', '5 minutes of focused breathing exercises', 'Mental Health', 4, 'daily', 'custom'),

-- Productivity & Learning
('Learn New Skill', '30 minutes learning something new', 'Education', 10, 'daily', 'custom'),
('Write 500 Words', 'Write at least 500 words (journal, blog, etc.)', 'Education', 8, 'daily', 'custom'),
('Practice Instrument', '20 minutes of musical instrument practice', 'Education', 7, 'daily', 'custom'),
('Language Learning', '15 minutes of foreign language study', 'Education', 6, 'daily', 'custom'),

-- Health & Wellness  
('Vitamins/Supplements', 'Take your daily vitamins or supplements', 'Health', 3, 'daily', 'custom'),
('Skincare Routine', 'Complete morning and evening skincare routine', 'Health', 4, 'daily', 'custom'),
('Healthy Breakfast', 'Eat a nutritious breakfast', 'Nutrition', 5, 'daily', 'custom'),
('No Processed Sugar', 'Avoid all processed sugar for the day', 'Nutrition', 8, 'daily', 'custom'),
('Green Smoothie', 'Drink a green smoothie with vegetables', 'Nutrition', 6, 'daily', 'custom'),

-- Personal Development
('Make Your Bed', 'Make your bed within 30 minutes of waking', 'Personal Development', 3, 'daily', 'custom'),
('Plan Tomorrow', 'Spend 10 minutes planning tomorrow', 'Personal Development', 5, 'daily', 'custom'),
('Connect with Friend', 'Reach out to a friend or family member', 'Personal Development', 6, 'daily', 'custom'),
('Random Act of Kindness', 'Do something nice for someone else', 'Personal Development', 8, 'daily', 'custom'),

-- Challenging Habits (Higher Points)
('Wake Up 5 AM', 'Wake up at 5:00 AM or earlier', 'Personal Development', 12, 'daily', 'custom'),
('No Complaining', 'Go the entire day without complaining', 'Mental Health', 10, 'daily', 'custom'),
('Digital Detox Evening', 'No screens after 8 PM', 'Mental Health', 9, 'daily', 'custom'),
('Intermittent Fasting', 'Complete a 16:8 intermittent fast', 'Health', 10, 'daily', 'custom'),
('Take Stairs Only', 'Only use stairs, never elevators/escalators', 'Fitness', 6, 'daily', 'custom'),

-- Creative & Fun
('Creative Time', '30 minutes of creative work (art, music, writing)', 'Personal Development', 8, 'daily', 'custom'),
('Photo Challenge', 'Take and edit one meaningful photo', 'Personal Development', 5, 'daily', 'custom'),
('Cook from Scratch', 'Prepare one meal completely from scratch', 'Nutrition', 7, 'daily', 'custom');

-- Update the sz_checkin function to handle bonus points and heart earning
CREATE OR REPLACE FUNCTION public.sz_checkin(p_streak_id uuid, p_day_number integer, p_completed_habit_ids uuid[], p_note text DEFAULT NULL::text, p_photo_url text DEFAULT NULL::text)
 RETURNS TABLE(points_earned integer, current_streak integer, total_points integer, hearts_earned integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id UUID;
    v_points INTEGER := 0;
    v_current_streak INTEGER;
    v_total_points INTEGER;
    v_previous_total INTEGER;
    v_hearts_earned INTEGER := 0;
    v_mode TEXT;
    v_existing_checkin BOOLEAN := FALSE;
BEGIN
    v_user_id := auth.uid();
    
    -- Get streak mode to calculate hearts
    SELECT mode INTO v_mode FROM sz_streaks WHERE id = p_streak_id;
    
    -- Get previous total points
    SELECT total_points INTO v_previous_total
    FROM sz_streak_members
    WHERE streak_id = p_streak_id AND user_id = v_user_id;
    
    -- Check if user already checked in today
    SELECT EXISTS(
        SELECT 1 FROM sz_checkins 
        WHERE streak_id = p_streak_id AND user_id = v_user_id AND day_number = p_day_number
    ) INTO v_existing_checkin;
    
    -- Calculate points from completed habits
    SELECT COALESCE(SUM(h.points), 0)
    INTO v_points
    FROM sz_habits h
    WHERE h.id = ANY(p_completed_habit_ids);

    -- Create checkin record (allow multiple per day for bonus habits)
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

    -- Update user's points and streak (only increment streak on first checkin of the day)
    IF v_existing_checkin THEN
        -- Just add points for bonus habits
        UPDATE sz_streak_members
        SET total_points = total_points + v_points
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    ELSE
        -- First checkin of the day - increment streak
        UPDATE sz_streak_members
        SET 
            total_points = total_points + v_points,
            current_streak = current_streak + 1
        WHERE streak_id = p_streak_id AND user_id = v_user_id
        RETURNING current_streak, total_points INTO v_current_streak, v_total_points;
    END IF;

    -- Calculate hearts earned for 75_hard modes
    IF v_mode IN ('75_hard', '75_hard_plus') THEN
        -- Base points per day for 75 hard (55 points for core habits)
        DECLARE
            v_base_points_per_day INTEGER := 55;
            v_expected_base_points INTEGER;
            v_previous_extra_points INTEGER;
            v_current_extra_points INTEGER;
            v_previous_hearts INTEGER;
            v_current_hearts INTEGER;
        BEGIN
            v_expected_base_points := v_base_points_per_day * p_day_number;
            
            -- Calculate extra points before and after this checkin
            v_previous_extra_points := GREATEST(0, v_previous_total - (v_base_points_per_day * (p_day_number - 1)));
            v_current_extra_points := GREATEST(0, v_total_points - v_expected_base_points);
            
            -- Calculate hearts (1 per 500 extra points, max 3)
            v_previous_hearts := LEAST(3, v_previous_extra_points / 500);
            v_current_hearts := LEAST(3, v_current_extra_points / 500);
            
            v_hearts_earned := v_current_hearts - v_previous_hearts;
            
            -- Update lives if hearts were earned
            IF v_hearts_earned > 0 THEN
                UPDATE sz_streak_members
                SET lives_remaining = LEAST(lives_remaining + v_hearts_earned, lives_remaining + 3)
                WHERE streak_id = p_streak_id AND user_id = v_user_id;
            END IF;
        END;
    END IF;

    RETURN QUERY
    SELECT v_points as points_earned, v_current_streak as current_streak, v_total_points as total_points, v_hearts_earned as hearts_earned;
END;
$function$;