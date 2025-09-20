-- Comprehensive fix for template mapping issues
-- This addresses the root cause: habits need to be properly mapped in sz_template_habits

-- Step 1: First, let's ensure we have the right habits in sz_habits
-- Add missing habits if they don't exist
INSERT INTO sz_habits (
    id,
    title,
    description,
    category,
    points,
    frequency,
    template_set,
    created_at
) VALUES 
(
    '9e123f4c-1bcd-42f6-83a2-72aa0cce8881',
    'No Alcohol',
    'Avoid consuming any alcoholic beverages',
    'Nutrition',
    12,
    'daily',
    'custom',
    '2025-09-18 18:40:00+00'
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Find the habit IDs for the habits that should be core
-- We need to find habits by title since they might have different IDs
DO $$
DECLARE
    v_no_alcohol_id UUID;
    v_progress_photo_id UUID;
    v_75_hard_template_id UUID;
    v_75_hard_plus_template_id UUID;
    v_max_sort_order INTEGER;
BEGIN
    -- Get template IDs
    SELECT id INTO v_75_hard_template_id FROM sz_templates WHERE key = '75_hard';
    SELECT id INTO v_75_hard_plus_template_id FROM sz_templates WHERE key = '75_hard_plus';
    
    -- Find habit IDs by title (handle case where multiple habits might exist)
    SELECT id INTO v_no_alcohol_id FROM sz_habits 
    WHERE title = 'No Alcohol' 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    SELECT id INTO v_progress_photo_id FROM sz_habits 
    WHERE title = 'Take a progress photo' 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    -- Get current max sort order for each template
    SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_max_sort_order 
    FROM sz_template_habits 
    WHERE template_id = v_75_hard_template_id;
    
    -- Add "No Alcohol" as CORE to 75 Hard
    IF v_no_alcohol_id IS NOT NULL THEN
        INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
        VALUES (v_75_hard_template_id, v_no_alcohol_id, true, v_max_sort_order, 0)
        ON CONFLICT (template_id, habit_id) DO UPDATE SET
            is_core = EXCLUDED.is_core,
            points_override = EXCLUDED.points_override;
        
        v_max_sort_order := v_max_sort_order + 1;
    END IF;
    
    -- Add "Take a progress photo" as CORE to 75 Hard (if not already there)
    IF v_progress_photo_id IS NOT NULL THEN
        INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
        VALUES (v_75_hard_template_id, v_progress_photo_id, true, v_max_sort_order, 0)
        ON CONFLICT (template_id, habit_id) DO UPDATE SET
            is_core = EXCLUDED.is_core,
            points_override = EXCLUDED.points_override;
    END IF;
    
    -- Get max sort order for 75 Hard Plus
    SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_max_sort_order 
    FROM sz_template_habits 
    WHERE template_id = v_75_hard_plus_template_id;
    
    -- Add "No Alcohol" as CORE to 75 Hard Plus
    IF v_no_alcohol_id IS NOT NULL THEN
        INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
        VALUES (v_75_hard_plus_template_id, v_no_alcohol_id, true, v_max_sort_order, 0)
        ON CONFLICT (template_id, habit_id) DO UPDATE SET
            is_core = EXCLUDED.is_core,
            points_override = EXCLUDED.points_override;
        
        v_max_sort_order := v_max_sort_order + 1;
    END IF;
    
    -- Add "Take a progress photo" as CORE to 75 Hard Plus (if not already there)
    IF v_progress_photo_id IS NOT NULL THEN
        INSERT INTO sz_template_habits (template_id, habit_id, is_core, sort_order, points_override)
        VALUES (v_75_hard_plus_template_id, v_progress_photo_id, true, v_max_sort_order, 0)
        ON CONFLICT (template_id, habit_id) DO UPDATE SET
            is_core = EXCLUDED.is_core,
            points_override = EXCLUDED.points_override;
    END IF;
END $$;

-- Step 3: Ensure all existing core habits are properly marked as CORE
UPDATE sz_template_habits 
SET is_core = true, points_override = 0
WHERE template_id IN (
    SELECT id FROM sz_templates WHERE key IN ('75_hard', '75_hard_plus')
)
AND habit_id IN (
    SELECT id FROM sz_habits 
    WHERE title IN (
        'Drink 1 gallon of water',
        'Follow a diet',
        'Read 10 pages of non-fiction',
        'Take a progress photo',
        'Two 45-minute workouts',
        'No Alcohol'
    )
);

-- Step 4: Show the final results
SELECT 
    'FINAL_RESULTS' as section,
    t.name as template_name,
    h.title as habit_title,
    CASE WHEN th.is_core THEN 'CORE' ELSE 'BONUS' END as habit_type,
    th.points_override as points,
    th.sort_order
FROM sz_template_habits th
JOIN sz_templates t ON t.id = th.template_id
JOIN sz_habits h ON h.id = th.habit_id
WHERE t.key IN ('75_hard', '75_hard_plus')
ORDER BY t.key, th.sort_order, h.title;
