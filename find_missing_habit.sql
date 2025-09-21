-- Find the missing habit ID that's not being mapped
-- We have 9 IDs but only 8 habits mapped, so one is missing

SELECT 
    h.id,
    h.title,
    h.category,
    h.points
FROM public.sz_habits h
WHERE h.id IN (
    '1fca8739-e678-4c9e-b251-e05b86d5b90e',
    '29fc3f19-83c9-4090-a2a7-57b036c0b5de', 
    '41c02541-c1ea-416e-8029-453f2a3fd17e',
    '71783c42-4ffb-4211-a7ec-1b138fc04778',
    '8f64c2b0-3d4d-4bb2-97b8-61ea74e6ad91',
    '9e123f4c-1bcd-42f6-83a2-72aa0cce8881',
    'aaf10bd6-c648-4040-aa79-bdb8e0d457fd',
    'c4dc94a9-b5df-4c73-bcdb-4045b200d08e',
    'd3635f7a-02e2-4d59-82d3-a782766d691c'
)
ORDER BY h.title;
