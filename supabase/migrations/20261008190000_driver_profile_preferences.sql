begin;

-- Separate preferences from the existing shared profile table.
create table if not exists public.driver_preferences (
  user_id uuid primary key
    references public.profiles(id) on delete cascade,
  location_enabled boolean not null default false,
  booking_updates boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.driver_preferences
  enable row level security;

revoke all on public.driver_preferences
from public, anon, authenticated;

grant select, insert on public.driver_preferences
to authenticated;

grant update (location_enabled, booking_updates)
on public.driver_preferences
to authenticated;

drop policy if exists driver_preferences_read_own
on public.driver_preferences;

create policy driver_preferences_read_own
on public.driver_preferences
for select
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists driver_preferences_create_own
on public.driver_preferences;

create policy driver_preferences_create_own
on public.driver_preferences
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists driver_preferences_update_own
on public.driver_preferences;

create policy driver_preferences_update_own
on public.driver_preferences
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Respect the saved booking-notification preference.
-- Existing notifications remain available.
-- System and payment messages are unaffected.
create or replace function public.driver_apply_notification_preferences()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_updates_enabled boolean;
begin
  if new.type <> 'booking' then
    return new;
  end if;

  select p.booking_updates
  into booking_updates_enabled
  from public.driver_preferences p
  where p.user_id = new.user_id;

  -- Accounts without preferences receive booking updates by default.
  if coalesce(booking_updates_enabled, true) = false then
    return null;
  end if;

  return new;
end;
$$;

revoke all on function
  public.driver_apply_notification_preferences()
from public, anon, authenticated;

drop trigger if exists driver_notification_preference_filter
on public.notifications;

create trigger driver_notification_preference_filter
before insert
on public.notifications
for each row
execute function public.driver_apply_notification_preferences();

commit;