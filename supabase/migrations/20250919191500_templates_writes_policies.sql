-- Allow authenticated users to manage templates and template-habits

alter table public.sz_templates enable row level security;
alter table public.sz_template_habits enable row level security;

drop policy if exists "Templates: insert by authenticated" on public.sz_templates;
create policy "Templates: insert by authenticated" on public.sz_templates
for insert to authenticated
with check (true);

drop policy if exists "Templates: update by authenticated" on public.sz_templates;
create policy "Templates: update by authenticated" on public.sz_templates
for update to authenticated
using (true)
with check (true);

drop policy if exists "Templates: delete by authenticated" on public.sz_templates;
create policy "Templates: delete by authenticated" on public.sz_templates
for delete to authenticated
using (true);

drop policy if exists "TemplateHabits: insert by authenticated" on public.sz_template_habits;
create policy "TemplateHabits: insert by authenticated" on public.sz_template_habits
for insert to authenticated
with check (true);

drop policy if exists "TemplateHabits: update by authenticated" on public.sz_template_habits;
create policy "TemplateHabits: update by authenticated" on public.sz_template_habits
for update to authenticated
using (true)
with check (true);

drop policy if exists "TemplateHabits: delete by authenticated" on public.sz_template_habits;
create policy "TemplateHabits: delete by authenticated" on public.sz_template_habits
for delete to authenticated
using (true);


