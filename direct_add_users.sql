-- Direct function to add users to streak (bypasses all RLS)
-- This will help us test if the issue is with the admin function or the frontend

CREATE OR REPLACE FUNCTION direct_add_user_to_streak(
    p_streak_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
) RETURNS TEXT AS $$
BEGIN
    -- Direct insert without any checks (for testing)
    INSERT INTO sz_streak_members (
        streak_id, user_id, role, status, joined_at, 
        current_streak, total_points, hearts_available, hearts_earned, hearts_used
    ) VALUES (
        p_streak_id, p_user_id, p_role, 'active', NOW(), 
        0, 0, 0, 0, 0
    ) ON CONFLICT (streak_id, user_id) DO UPDATE SET
        role = EXCLUDED.role,
        status = 'active';
    
    RETURN 'User added successfully';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test adding a user
SELECT direct_add_user_to_streak(
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    '521dca54-21ee-4815-baf7-9b4213275779'::uuid,
    'member'
);

-- Check if it worked
SELECT 
    'TEST RESULT' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    p.email
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY sm.joined_at;
