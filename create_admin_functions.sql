-- Create admin functions that bypass RLS for super admins
-- These functions will be called from the frontend and handle the database operations

-- Function to add user to streak (bypasses RLS)
CREATE OR REPLACE FUNCTION admin_add_user_to_streak(
    p_streak_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
) RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Check if the current user is a super admin
    IF NOT EXISTS (
        SELECT 1 FROM sz_user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'super_admin' 
        AND is_active = true
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Access denied. Super admin privileges required.');
    END IF;

    -- Check if user already exists in streak
    IF EXISTS (SELECT 1 FROM sz_streak_members WHERE streak_id = p_streak_id AND user_id = p_user_id) THEN
        -- Update existing user
        UPDATE sz_streak_members 
        SET role = p_role,
            status = 'active'
        WHERE streak_id = p_streak_id AND user_id = p_user_id;
        
        RETURN json_build_object('success', true, 'message', 'User already in streak, role updated successfully');
    ELSE
        -- Insert new user
        INSERT INTO sz_streak_members (
            streak_id, user_id, role, status, joined_at, 
            current_streak, total_points, hearts_available, hearts_earned, hearts_used
        ) VALUES (
            p_streak_id, p_user_id, p_role, 'active', NOW(), 
            0, 0, 0, 0, 0
        );
        
        RETURN json_build_object('success', true, 'message', 'User added to streak successfully');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign habits to user (bypasses RLS)
CREATE OR REPLACE FUNCTION admin_assign_habits_to_user(
    p_streak_id UUID,
    p_user_id UUID,
    p_habit_ids UUID[]
) RETURNS JSON AS $$
DECLARE
    result JSON;
    habit_id UUID;
BEGIN
    -- Check if the current user is a super admin
    IF NOT EXISTS (
        SELECT 1 FROM sz_user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'super_admin' 
        AND is_active = true
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Access denied. Super admin privileges required.');
    END IF;

    -- Insert habits for the user
    FOREACH habit_id IN ARRAY p_habit_ids
    LOOP
        INSERT INTO sz_user_habits (
            streak_id, user_id, habit_id, points_override
        ) VALUES (
            p_streak_id, 
            p_user_id, 
            habit_id,
            (SELECT points FROM sz_habits WHERE id = habit_id)
        ) ON CONFLICT (streak_id, user_id, habit_id) DO UPDATE SET
            points_override = EXCLUDED.points_override;
    END LOOP;

    RETURN json_build_object('success', true, 'message', 'Habits assigned successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark user complete until today (bypasses RLS)
CREATE OR REPLACE FUNCTION admin_mark_user_complete_until_today(
    p_streak_id UUID,
    p_user_id UUID
) RETURNS JSON AS $$
DECLARE
    result JSON;
    streak_start_date DATE;
    today_date DATE := CURRENT_DATE;
    days_completed INTEGER;
    habit_record RECORD;
    day_number INTEGER;
    total_points INTEGER := 0;
    hearts_earned INTEGER;
BEGIN
    -- Check if the current user is a super admin
    IF NOT EXISTS (
        SELECT 1 FROM sz_user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'super_admin' 
        AND is_active = true
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Access denied. Super admin privileges required.');
    END IF;

    -- Get streak start date
    SELECT start_date INTO streak_start_date
    FROM sz_streaks
    WHERE id = p_streak_id;

    IF streak_start_date IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Streak not found');
    END IF;

    -- Calculate days completed
    days_completed := (today_date - streak_start_date) + 1;

    -- Get user's habits and create check-ins
    FOR habit_record IN 
        SELECT uh.habit_id, uh.points_override
        FROM sz_user_habits uh
        WHERE uh.streak_id = p_streak_id 
        AND uh.user_id = p_user_id
    LOOP
        -- Create check-ins for all days
        FOR day_number IN 1..days_completed LOOP
            INSERT INTO sz_checkins (
                streak_id, user_id, habit_id, day_number,
                completed_at, points_earned, notes
            ) VALUES (
                p_streak_id, p_user_id, habit_record.habit_id, day_number,
                streak_start_date + (day_number - 1) * INTERVAL '1 day' + INTERVAL '18 hours',
                habit_record.points_override,
                'Admin marked complete'
            ) ON CONFLICT DO NOTHING;
            
            total_points := total_points + habit_record.points_override;
        END LOOP;
    END LOOP;

    -- Update user's stats
    hearts_earned := FLOOR(total_points / 100);
    UPDATE sz_streak_members 
    SET current_streak = days_completed,
        total_points = total_points,
        hearts_earned = hearts_earned,
        hearts_available = hearts_earned
    WHERE streak_id = p_streak_id 
    AND user_id = p_user_id;

    -- Update streak bonus points
    UPDATE sz_streaks 
    SET bonus_points = (
        SELECT COALESCE(SUM(sm.total_points), 0)
        FROM sz_streak_members sm
        WHERE sm.streak_id = p_streak_id
    )
    WHERE id = p_streak_id;

    RETURN json_build_object(
        'success', true, 
        'message', 'User marked complete successfully',
        'days_completed', days_completed,
        'total_points', total_points,
        'hearts_earned', hearts_earned
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION admin_add_user_to_streak(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_assign_habits_to_user(UUID, UUID, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_mark_user_complete_until_today(UUID, UUID) TO authenticated;
