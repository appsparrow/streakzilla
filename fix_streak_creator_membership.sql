-- Fix streak creator membership issue
-- This ensures that the creator of a streak is automatically a member

-- Function to ensure streak creator is a member
CREATE OR REPLACE FUNCTION ensure_streak_creator_is_member(p_streak_id UUID)
RETURNS TEXT AS $$
DECLARE
    creator_id UUID;
    result TEXT;
BEGIN
    -- Get the creator of the streak
    SELECT created_by INTO creator_id
    FROM sz_streaks
    WHERE id = p_streak_id;
    
    IF creator_id IS NULL THEN
        RETURN 'Streak not found';
    END IF;
    
    -- Check if creator is already a member
    IF EXISTS (
        SELECT 1 FROM sz_streak_members 
        WHERE streak_id = p_streak_id AND user_id = creator_id
    ) THEN
        RETURN 'Creator is already a member';
    END IF;
    
    -- Add creator as admin member
    INSERT INTO sz_streak_members (
        streak_id, user_id, role, status, joined_at, 
        current_streak, total_points, hearts_available, hearts_earned, hearts_used
    ) VALUES (
        p_streak_id, creator_id, 'admin', 'active', NOW(), 
        0, 0, 0, 0, 0
    );
    
    RETURN 'Creator added as member successfully';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the fix to the specific streak
SELECT ensure_streak_creator_is_member('8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid);

-- Also apply to the other streak we've been working with
SELECT ensure_streak_creator_is_member('444efc20-0db3-46a5-86a0-265597be8acd'::uuid);

-- Check the results
SELECT 
    'FIXED STREAKS' as check_type,
    s.id,
    s.name,
    s.created_by,
    p.email as creator_email,
    COUNT(sm.user_id) as member_count
FROM sz_streaks s
LEFT JOIN profiles p ON s.created_by = p.id
LEFT JOIN sz_streak_members sm ON s.id = sm.streak_id
WHERE s.id IN (
    '8d249ba2-55bc-4369-8fad-13b171d165a2'::uuid,
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
)
GROUP BY s.id, s.name, s.created_by, p.email;
