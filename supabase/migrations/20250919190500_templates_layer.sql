-- Templates layer: templates, template_habits, streak.template_id

-- 1) Templates table
create table if not exists public.sz_templates (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  description text null,
  allow_custom_habits boolean not null default false,
  created_at timestamptz default now()
);

-- 2) Template ↔ Habit mapping
create table if not exists public.sz_template_habits (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.sz_templates(id) on delete cascade,
  habit_id uuid not null references public.sz_habits(id) on delete cascade,
  is_core boolean not null default true,
  points_override integer null,
  sort_order integer null,
  constraint sz_template_habits_unique unique (template_id, habit_id)
);

-- 3) Add template_id to streaks
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'sz_streaks' and column_name = 'template_id'
  ) then
    alter table public.sz_streaks
      add column template_id uuid null references public.sz_templates(id) on delete set null;
  end if;
end $$;

-- RLS policies: allow read-only for anon/auth
alter table public.sz_templates enable row level security;
alter table public.sz_template_habits enable row level security;

drop policy if exists "Everyone can read templates" on public.sz_templates;
create policy "Everyone can read templates" on public.sz_templates
for select using (true);

drop policy if exists "Everyone can read template_habits" on public.sz_template_habits;
create policy "Everyone can read template_habits" on public.sz_template_habits
for select using (true);

-- Seed basic templates (idempotent)
insert into public.sz_templates (key, name, allow_custom_habits)
values
  ('75_hard', '75 Hard', false),
  ('75_hard_plus', '75 Hard Plus', true),
  ('custom', 'Custom', true)
on conflict (key) do nothing;

-- Map 75 Hard core habits
insert into public.sz_template_habits (template_id, habit_id, is_core, sort_order)
select t.id, h.id, true, row_number() over ()
from public.sz_templates t
join public.sz_habits h on h.template_set = '75_hard'
where t.key = '75_hard'
on conflict (template_id, habit_id) do nothing;

-- Map 75 Hard Plus to the same core set as 75 Hard
insert into public.sz_template_habits (template_id, habit_id, is_core, sort_order)
select t_plus.id, th_source.habit_id, true, th_source.sort_order
from public.sz_templates t_plus
join public.sz_templates t_hard on t_hard.key = '75_hard'
join public.sz_template_habits th_source on th_source.template_id = t_hard.id and th_source.is_core = true
where t_plus.key = '75_hard_plus'
on conflict (template_id, habit_id) do nothing;

-- Backfill streak.template_id from existing mode field
update public.sz_streaks s
set template_id = t.id
from public.sz_templates t
where s.template_id is null and (
  lower(s.mode) = lower(t.key) or lower(replace(s.mode, ' ', '_')) = lower(t.key)
);

-- Update sz_create_streak to use templates if available
create or replace function public.sz_create_streak(p_name text, p_mode text, p_start_date date, p_duration_days integer default 75)
returns table(streak_id uuid, streak_code text)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
    v_streak_id uuid;
    v_streak_code text;
    v_user_id uuid;
    v_initial_lives integer;
    v_template_id uuid;
    v_template_key text;
begin
    v_user_id := auth.uid();
    if v_user_id is null then
        raise exception 'User not authenticated';
    end if;

    if p_mode like '%_plus' then
        v_initial_lives := 0;
    else
        v_initial_lives := 3;
    end if;

    -- Resolve template by key (mode may be '75 hard' or '75_hard')
    v_template_key := lower(replace(p_mode, ' ', '_'));
    select id into v_template_id from public.sz_templates where key = v_template_key;

    v_streak_id := gen_random_uuid();
    v_streak_code := public.sz_generate_streak_code();

    insert into public.sz_streaks (id, name, code, mode, start_date, duration_days, created_by, template_id)
    values (v_streak_id, p_name, v_streak_code, p_mode, p_start_date, p_duration_days, v_user_id, v_template_id);

    insert into public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    values (v_streak_id, v_user_id, 'admin', v_initial_lives);

    -- Assign core habits from template if present, else fallback to legacy behavior
    if v_template_id is not null then
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, th.habit_id
        from public.sz_template_habits th
        where th.template_id = v_template_id and th.is_core = true;
    else
        -- Fallback: legacy template_set
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, h.id
        from public.sz_habits h
        where h.template_set = case when p_mode = '75_hard_plus' then '75_hard' else p_mode end;
    end if;

    return query select v_streak_id, v_streak_code;
end;
$function$;

-- Update sz_join_streak to use templates if available
create or replace function public.sz_join_streak(p_code text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
    v_streak_id uuid;
    v_user_id uuid;
    v_mode text;
    v_initial_lives integer;
    v_template_id uuid;
begin
    v_user_id := auth.uid();
    if v_user_id is null then
        raise exception 'User not authenticated';
    end if;

    select id, mode, template_id into v_streak_id, v_mode, v_template_id
    from public.sz_streaks 
    where code = p_code and is_active = true;

    if v_streak_id is null then
        raise exception 'Invalid or inactive streak code';
    end if;

    if exists(select 1 from public.sz_streak_members where streak_id = v_streak_id and user_id = v_user_id) then
        raise exception 'User is already a member of this streak';
    end if;

    if v_mode like '%_plus' then
        v_initial_lives := 0;
    else
        v_initial_lives := 3;
    end if;

    insert into public.sz_streak_members (streak_id, user_id, role, lives_remaining)
    values (v_streak_id, v_user_id, 'member', v_initial_lives);

    if v_template_id is not null then
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, th.habit_id
        from public.sz_template_habits th
        where th.template_id = v_template_id and th.is_core = true;
    else
        insert into public.sz_user_habits (streak_id, user_id, habit_id)
        select v_streak_id, v_user_id, h.id
        from public.sz_habits h
        where h.template_set = case when v_mode = '75_hard_plus' then '75_hard' else v_mode end;
    end if;

    return v_streak_id;
end;
$function$;


