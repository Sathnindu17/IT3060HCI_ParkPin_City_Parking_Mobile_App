begin;

-- Link a notification to its booking when relevant.
alter table public.notifications
  add column if not exists booking_id uuid
  references public.bookings(id) on delete set null;

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

-- Generate notifications from successful booking changes.
-- The existing notification RLS policies continue to control access.
create or replace function public.driver_notify_booking_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  facility_name_value text;
  bay_label_value text;
  title_value text;
  message_value text;
  type_value text;
  extra_minutes integer;
begin
  select f.name
  into facility_name_value
  from public.parking_facilities f
  where f.id = new.facility_id;

  select b.label
  into bay_label_value
  from public.bays b
  where b.id = new.bay_id;

  facility_name_value :=
    coalesce(facility_name_value, 'Parking facility');

  bay_label_value :=
    coalesce(bay_label_value, 'Not assigned');

  if new.status = 'active'
     and old.status is distinct from new.status then

    title_value := 'Parking started';

    message_value := format(
      '%s · Bay %s. Your parking session is active.',
      facility_name_value,
      bay_label_value
    );

    type_value := 'booking';

  elsif new.status = 'completed'
        and old.status is distinct from new.status then

    title_value := 'Parking completed';

    message_value := format(
      '%s · Bay %s. Open Booking History to view your receipt.',
      facility_name_value,
      bay_label_value
    );

    type_value := 'booking';

  elsif new.status = 'active'
        and old.status = 'active'
        and new.end_time > old.end_time then

    extra_minutes := round(
      extract(epoch from (new.end_time - old.end_time)) / 60
    )::integer;

    title_value := 'Parking extended';

    message_value := format(
      '%s · Bay %s. Added %s minutes. Your new end time is %s.',
      facility_name_value,
      bay_label_value,
      extra_minutes,
      to_char(
        new.end_time at time zone 'Asia/Colombo',
        'DD Mon YYYY, HH12:MI AM'
      )
    );

    type_value := 'booking';

  else
    return new;
  end if;

  insert into public.notifications (
    user_id,
    booking_id,
    title,
    message,
    type,
    is_read
  )
  values (
    new.driver_id,
    new.id,
    title_value,
    message_value,
    type_value,
    false
  );

  return new;
end;
$$;

revoke all on function public.driver_notify_booking_changes()
from public, anon, authenticated;

drop trigger if exists driver_booking_change_notification
on public.bookings;

create trigger driver_booking_change_notification
after update of status, end_time
on public.bookings
for each row
execute function public.driver_notify_booking_changes();

-- Enable live notification updates if not already enabled.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime
      add table public.notifications;
  end if;
end;
$$;

commit;