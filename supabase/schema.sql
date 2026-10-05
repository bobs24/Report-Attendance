-- Attendance — ONE clean table. Paste into Supabase → SQL Editor → Run.
-- One row per person per date, complete days only. The raw file is never uploaded.
create table if not exists attendance_records (
  pin               text not null,          -- machine id of the person
  work_date         date not null,
  name              text,
  dept              text,
  day_type          text,                   -- WORK / OFF / LEAVE / SICK / ABSENT
  schedule          text,                   -- e.g. "Regular + Shift 1"
  time_in           text,                   -- first in of the day
  time_out          text,                   -- last out of the day
  in_out            text,                   -- every pair, e.g. "09:00-12:00; 13:00-16:05"
  working_minutes   integer not null default 0,   -- total time, overtime included
  overtime_minutes  integer not null default 0,   -- part of the total
  overtime_allowed  boolean,
  edited            boolean,                -- fixed by hand in the app
  note              text,
  saved_at          timestamptz default now(),
  primary key (pin, work_date)              -- saving again updates, never duplicates
);
alter table attendance_records enable row level security;

-- The app only needs to read, add and update. No delete policy = nobody can delete rows with the public key.
drop policy if exists p_records on attendance_records;
drop policy if exists p_select on attendance_records;
drop policy if exists p_insert on attendance_records;
drop policy if exists p_update on attendance_records;
create policy p_select on attendance_records for select to anon using (true);
create policy p_insert on attendance_records for insert to anon with check (true);
create policy p_update on attendance_records for update to anon using (true) with check (true);

-- Monthly totals for reports / Power BI
create or replace view v_monthly as
select to_char(work_date, 'YYYY-MM') as month, pin, name, dept,
       round(sum(working_minutes) / 60.0, 2)  as working_hours,
       round(sum(overtime_minutes) / 60.0, 2) as overtime_hours,
       count(*) as days
from attendance_records group by 1, 2, 3, 4;
