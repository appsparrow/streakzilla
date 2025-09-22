-- Add test users to the streak to see if the issue is with adding or displaying
-- This will help us debug the frontend issue

-- First, let's see what users exist in profiles table
SELECT 
    'AVAILABLE USERS' as check_type,
    p.id,
    p.email
FROM profiles p
LIMIT 10;

-- Add some test users to the streak (using existing user IDs from profiles)
-- Replace these with actual user IDs from your profiles table

-- Example: Add users if they exist
INSERT INTO sz_streak_members (
    streak_id, 
    user_id, 
    role, 
    status, 
    joined_at, 
    current_streak, 
    total_points, 
    hearts_available, 
    hearts_earned, 
    hearts_used
) 
SELECT 
    '444efc20-0db3-46a5-86a0-265597be8acd'::uuid,
    p.id,
    'member',
    'active',
    NOW(),
    0,
    0,
    0,
    0,
    0
FROM profiles p
WHERE p.id IN (
    '521dca54-21ee-4815-baf7-9b4213275779'::uuid,
    '9bdf34ba-751d-4687-80b5-8f7d9549a635'::uuid,
    'afc5adfa-553b-4d56-a583-2491b23ec453'::uuid,
    '8f93d8cb-428f-4f95-a04a-79be2f3e1063'::uuid
)
ON CONFLICT (streak_id, user_id) DO NOTHING;

-- Check what we just added
SELECT 
    'ADDED USERS' as check_type,
    sm.user_id,
    sm.role,
    sm.status,
    p.email
FROM sz_streak_members sm
LEFT JOIN profiles p ON sm.user_id = p.id
WHERE sm.streak_id = '444efc20-0db3-46a5-86a0-265597be8acd'::uuid
ORDER BY sm.joined_at;
