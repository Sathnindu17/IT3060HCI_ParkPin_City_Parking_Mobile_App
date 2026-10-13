-- ParkPin – live driver data in the operator screens.
-- 1. When a driver reserves a bay, every operator linked to that car park gets
--    a "New booking" notification, linked to the booking (O09).
-- 2. Payments are added to Supabase Realtime, so O02 "collected today" and
--    O07 Payments update the moment a driver pays.
-- Safe to run again.

begin;

create or replace function public.operator_notify_new_booking()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  bay_label_value text;
begin
  select b.label
  into bay_label_value
  from public.bays b
  where b.id = new.bay_id;

  insert into public.notifications (user_id, booking_id, title, message, type, is_read)
  select
    p.id,
    new.id,
    'New booking — ' || coalesce('Bay ' || bay_label_value, 'no bay yet'),
    format(
      '%s · %s · arrives %s',
      new.booking_code,
      coalesce(nullif(btrim(new.vehicle_number), ''), 'vehicle not given'),
      to_char(new.start_time at time zone 'Asia/Colombo', 'DD Mon, HH12:MI AM')
    ),
    'booking',
    false
  from public.profiles p
  where p.role = 'operator'
    and p.facility_id = new.facility_id;

  return new;
end;
$$;

revoke all on function public.operator_notify_new_booking()
from public, anon, authenticated;

drop trigger if exists operator_new_booking_notification
on public.bookings;

create trigger operator_new_booking_notification
after insert
on public.bookings
for each row
execute function public.operator_notify_new_booking();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'payments'
  ) then
    alter publication supabase_realtime add table public.payments;
  end if;
end;
$$;

commit;
