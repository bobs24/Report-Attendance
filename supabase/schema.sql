-- ============================================================================
-- Attendance v1.3 — paste ALL of this into Supabase → SQL Editor → Run.
-- Safe to run again. Keeps every record you already saved.
-- ============================================================================

-- 1) Who may sign in ---------------------------------------------------------
create table if not exists app_users (
  email  text primary key,
  role   text not null default 'USER' check (role in ('ADMIN','USER')),
  active boolean not null default true
);
insert into app_users (email, role, active) values
  ('bobsebastian1997@gmail.com',   'ADMIN', true),
  -- ('anthony@livingword.id',        'USER',  true),
  -- ('devin@livingword.id',          'USER',  true),
  -- ('mavelynphoebe.work@gmail.com', 'USER',  true),
  -- ('finance@livingword.id',        'USER',  true),
  -- ('finance@livingword.id',        'USER',  true),
on conflict (email) do update set role = excluded.role, active = excluded.active;

-- helper checks (run with owner rights so they can read app_users)
create or replace function public.is_app_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where lower(email) = lower(auth.jwt() ->> 'email') and active)
$$;
create or replace function public.is_app_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where lower(email) = lower(auth.jwt() ->> 'email') and active and role = 'ADMIN')
$$;
-- the login page asks this before "Create your password"
create or replace function public.can_login(p_email text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where lower(email) = lower(trim(p_email)) and active)
$$;
-- the app asks this right after signing in
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select role from app_users where lower(email) = lower(auth.jwt() ->> 'email') and active
$$;
grant execute on function public.can_login(text) to anon, authenticated;
grant execute on function public.my_role()       to authenticated;
grant execute on function public.is_app_user()   to authenticated;
grant execute on function public.is_app_admin()  to authenticated;

alter table app_users enable row level security;
drop policy if exists u_select on app_users;
drop policy if exists u_write  on app_users;
create policy u_select on app_users for select to authenticated using (is_app_admin());
create policy u_write  on app_users for all    to authenticated using (is_app_admin()) with check (is_app_admin());

-- 2) Attendance records (one row per person per date) ------------------------
create table if not exists attendance_records (
  pin text not null, work_date date not null, name text, dept text,
  day_type text,          -- WORK / OFF / LEAVE (Annual leave) / SICK / ABSENT
  schedule text, time_in text, time_out text,
  in_out text,            -- "(-1)22:00-06:30" = in on previous day · "17:00-03:00 (+1)" = out on next day
  working_minutes integer not null default 0,
  overtime_minutes integer not null default 0,
  overtime_allowed boolean, edited boolean, note text,
  saved_at timestamptz default now(),
  primary key (pin, work_date)
);
alter table attendance_records enable row level security;
-- remove the old "anyone with the link" rules
drop policy if exists p_records on attendance_records;
drop policy if exists p_select  on attendance_records;
drop policy if exists p_insert  on attendance_records;
drop policy if exists p_update  on attendance_records;
-- only signed-in, allowed users. No delete for anyone.
create policy p_select on attendance_records for select to authenticated using (is_app_user());
create policy p_insert on attendance_records for insert to authenticated with check (is_app_user());
create policy p_update on attendance_records for update to authenticated using (is_app_user()) with check (is_app_user());

-- 3) Shared settings (schedules + people), one row 'global' ------------------
create table if not exists app_settings (
  id text primary key,
  payload jsonb not null,
  updated_at timestamptz default now(),
  updated_by text
);
alter table app_settings enable row level security;
drop policy if exists s_select on app_settings;
drop policy if exists s_insert on app_settings;
drop policy if exists s_update on app_settings;
create policy s_select on app_settings for select to authenticated using (is_app_user());
create policy s_insert on app_settings for insert to authenticated with check (is_app_user());
create policy s_update on app_settings for update to authenticated using (is_app_user()) with check (is_app_user());

-- 4) History: old version of a record is kept whenever it changes ------------
create table if not exists attendance_history (
  id bigserial primary key, pin text, work_date date, old_row jsonb, changed_at timestamptz default now());
alter table attendance_history enable row level security;
create or replace function log_attendance_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into attendance_history (pin, work_date, old_row) values (old.pin, old.work_date, to_jsonb(old));
  return new;
end $$;
drop trigger if exists trg_attendance_history on attendance_records;
create trigger trg_attendance_history before update on attendance_records for each row
  when ((to_jsonb(old) - 'saved_at') is distinct from (to_jsonb(new) - 'saved_at'))
  execute function log_attendance_change();
