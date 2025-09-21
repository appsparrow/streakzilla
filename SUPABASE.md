






create table public.sz_checkins (
  id uuid not null default gen_random_uuid (),
  streak_id uuid not null,
  user_id uuid not null,
  day_number integer not null,
  completed_habit_ids uuid[] null default '{}'::uuid[],
  points_earned integer null default 0,
  note text null,
  photo_url text null,
  created_at timestamp with time zone null default now(),
  constraint sz_checkins_pkey primary key (id),
  constraint fk_checkins_streak_id foreign KEY (streak_id) references sz_streaks (id) on delete CASCADE
) TABLESPACE pg_default;


create table public.sz_habits (
  id uuid not null default gen_random_uuid (),
  title text not null,
  description text null,
  category text null,
  points integer null default 1,
  frequency text null default 'daily'::text,
  template_set text null,
  created_at timestamp with time zone null default now(),
  constraint sz_habits_pkey primary key (id)
) TABLESPACE pg_default;


create table public.sz_hearts_transactions (
  id uuid not null default gen_random_uuid (),
  streak_id uuid not null,
  from_user_id uuid not null,
  to_user_id uuid not null,
  hearts_amount integer not null default 1,
  transaction_type text not null default 'gift'::text,
  day_number integer not null,
  note text null,
  created_at timestamp with time zone null default now(),
  constraint sz_hearts_transactions_pkey primary key (id),
  constraint sz_hearts_transactions_from_user_id_fkey foreign KEY (from_user_id) references auth.users (id) on delete CASCADE,
  constraint sz_hearts_transactions_streak_id_fkey foreign KEY (streak_id) references sz_streaks (id) on delete CASCADE,
  constraint sz_hearts_transactions_to_user_id_fkey foreign KEY (to_user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;


create table public.sz_posts (
  id uuid not null default gen_random_uuid (),
  streak_id uuid not null,
  user_id uuid not null,
  day_number integer not null,
  photo_url text not null,
  caption text null,
  created_at timestamp with time zone null default now(),
  constraint sz_posts_pkey primary key (id),
  constraint fk_posts_streak_id foreign KEY (streak_id) references sz_streaks (id) on delete CASCADE
) TABLESPACE pg_default;



create table public.sz_streak_members (
  id uuid not null default gen_random_uuid (),
  streak_id uuid not null,
  user_id uuid not null,
  role text null default 'member'::text,
  joined_at timestamp with time zone null default now(),
  current_streak integer null default 0,
  total_points integer null default 0,
  lives_remaining integer null default 3,
  is_out boolean null default false,
  status text null default 'active'::text,
  left_at timestamp with time zone null,
  bonus_points integer null default 0,
  hearts_earned integer null default 0,
  hearts_used integer null default 0,
  hearts_available integer null default 0,
  constraint sz_streak_members_pkey primary key (id),
  constraint sz_streak_members_streak_id_user_id_key unique (streak_id, user_id),
  constraint fk_streak_members_streak_id foreign KEY (streak_id) references sz_streaks (id) on delete CASCADE
) TABLESPACE pg_default;



create table public.sz_streaks (
  id uuid not null default gen_random_uuid (),
  name text not null,
  code text not null,
  mode text not null,
  start_date date not null,
  duration_days integer not null default 75,
  created_by uuid not null,
  created_at timestamp with time zone null default now(),
  is_active boolean null default true,
  template_id uuid null,
  heart_sharing_enabled boolean null default true,
  points_to_hearts_enabled boolean null default true,
  hearts_per_100_points integer null default 1,
  constraint sz_streaks_pkey primary key (id),
  constraint sz_streaks_code_key unique (code),
  constraint sz_streaks_template_id_fkey foreign KEY (template_id) references sz_templates (id) on delete set null
) TABLESPACE pg_default;


create table public.sz_template_habits (
  id uuid not null default gen_random_uuid (),
  template_id uuid not null,
  habit_id uuid not null,
  is_core boolean not null default true,
  points_override integer null,
  sort_order integer null,
  constraint sz_template_habits_pkey primary key (id),
  constraint sz_template_habits_unique unique (template_id, habit_id),
  constraint sz_template_habits_habit_id_fkey foreign KEY (habit_id) references sz_habits (id) on delete CASCADE,
  constraint sz_template_habits_template_id_fkey foreign KEY (template_id) references sz_templates (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.sz_templates (
  id uuid not null default gen_random_uuid (),
  key text not null,
  name text not null,
  description text null,
  allow_custom_habits boolean not null default false,
  created_at timestamp with time zone null default now(),
  constraint sz_templates_pkey primary key (id),
  constraint sz_templates_key_key unique (key)
) TABLESPACE pg_default;


create table public.sz_user_habits (
  id uuid not null default gen_random_uuid (),
  streak_id uuid not null,
  user_id uuid not null,
  habit_id uuid not null,
  created_at timestamp with time zone null default now(),
  constraint sz_user_habits_pkey primary key (id),
  constraint sz_user_habits_streak_id_user_id_habit_id_key unique (streak_id, user_id, habit_id),
  constraint fk_user_habits_streak_id foreign KEY (streak_id) references sz_streaks (id) on delete CASCADE
) TABLESPACE pg_default;



create table public.sz_user_roles (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  role text not null default 'user'::text,
  granted_by uuid null,
  granted_at timestamp with time zone null default now(),
  is_active boolean null default true,
  constraint sz_user_roles_pkey primary key (id),
  constraint sz_user_roles_user_id_role_key unique (user_id, role),
  constraint sz_user_roles_granted_by_fkey foreign KEY (granted_by) references auth.users (id) on delete set null,
  constraint sz_user_roles_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;
