begin;

alter table public.bays
  add column if not exists is_out_of_service
  boolean not null default false;

-- Prevent assigning or starting a booking on an unusable bay.
create or replace function public.driver_check_usable_booking_bay()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  blocked boolean;
begin
  if new.bay_id is null
     or new.status not in ('reserved', 'active') then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    -- Existing reservations can remain attached to a blocked bay
    -- until the driver accepts an alternative.
    if new.bay_id is not distinct from old.bay_id
       and new.status is not distinct from old.status then
      return new;
    end if;
  end if;

  select b.is_out_of_service
  into blocked
  from public.bays b
  where b.id = new.bay_id
  for share;

  if coalesce(blocked, false) then
    raise exception
      'This bay is unavailable. Open Reservation Recovery.';
  end if;

  return new;
end;
$$;

revoke all on function
  public.driver_check_usable_booking_bay()
from public, anon, authenticated;

drop trigger if exists driver_check_usable_booking_bay
on public.bookings;

create trigger driver_check_usable_booking_bay
before insert or update of bay_id, status
on public.bookings
for each row
execute function public.driver_check_usable_booking_bay();

-- READ: return the current reservation and matching alternatives.
create or replace function public.driver_recovery_options(
  p_booking_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_record public.bookings%rowtype;
  old_bay public.bays%rowtype;
  facility_name_value text;
  alternatives_value jsonb;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to view your reservation.';
  end if;

  select *
  into booking_record
  from public.bookings
  where id = p_booking_id
    and driver_id = auth.uid();

  if not found then
    raise exception 'Reservation not found.';
  end if;

  if booking_record.status <> 'reserved' then
    raise exception
      'Recovery is available only before parking starts.';
  end if;

  if booking_record.end_time <= now() then
    raise exception 'This reservation has expired.';
  end if;

  select *
  into old_bay
  from public.bays
  where id = booking_record.bay_id;

  if not found then
    raise exception
      'The assigned bay was removed. Please contact the parking operator.';
  end if;

  if not old_bay.is_out_of_service then
    raise exception
      'Your assigned bay is usable. This reservation does not need recovery.';
  end if;

  select name
  into facility_name_value
  from public.parking_facilities
  where id = booking_record.facility_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', candidate.id,
        'label', candidate.label,
        'level', candidate.level
      )
      order by candidate.label, candidate.id
    ),
    '[]'::jsonb
  )
  into alternatives_value
  from public.bays candidate
  where candidate.facility_id = booking_record.facility_id
    and candidate.id <> old_bay.id
    and candidate.level is not distinct from old_bay.level
    and candidate.type = old_bay.type
    and candidate.status = 'available'
    and candidate.is_out_of_service = false
    and not exists (
      select 1
      from public.bookings other_booking
      where other_booking.bay_id = candidate.id
        and other_booking.status in ('reserved', 'active')
    );

  return jsonb_build_object(
    'booking_id', booking_record.id,
    'booking_code', booking_record.booking_code,
    'facility_name', coalesce(facility_name_value, 'Parking facility'),
    'unavailable_bay_id', old_bay.id,
    'unavailable_bay_label', old_bay.label,
    'level', old_bay.level,
    'alternatives', alternatives_value
  );
end;
$$;

revoke all on function public.driver_recovery_options(uuid)
from public, anon, authenticated;

grant execute on function public.driver_recovery_options(uuid)
to authenticated;

-- UPDATE: atomically reassign the existing reservation.
create or replace function public.driver_accept_recovery_bay(
  p_booking_id uuid,
  p_expected_bay_id uuid,
  p_new_bay_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_record public.bookings%rowtype;
  old_bay public.bays%rowtype;
  new_bay public.bays%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to recover your reservation.';
  end if;

  if p_expected_bay_id is null or p_new_bay_id is null then
    raise exception 'Choose an alternative bay.';
  end if;

  select *
  into booking_record
  from public.bookings
  where id = p_booking_id
    and driver_id = auth.uid()
  for update;

  if not found then
    raise exception 'Reservation not found.';
  end if;

  if booking_record.status <> 'reserved' then
    raise exception
      'Recovery is available only before parking starts.';
  end if;

  if booking_record.end_time <= now() then
    raise exception 'This reservation has expired.';
  end if;

  -- A repeated request after successful reassignment is harmless.
  if booking_record.bay_id = p_new_bay_id then
    return booking_record.id;
  end if;

  if booking_record.bay_id is distinct from p_expected_bay_id then
    raise exception
      'Your assigned bay changed. Refresh and try again.';
  end if;

  -- Lock both bays in a consistent order.
  perform b.id
  from public.bays b
  where b.id in (p_expected_bay_id, p_new_bay_id)
  order by b.id
  for update;

  select *
  into old_bay
  from public.bays
  where id = p_expected_bay_id;

  if not found then
    raise exception 'The original bay was not found.';
  end if;

  select *
  into new_bay
  from public.bays
  where id = p_new_bay_id;

  if not found then
    raise exception 'The alternative bay was not found.';
  end if;

  if not old_bay.is_out_of_service then
    raise exception
      'Your original bay is usable. Refresh your reservation.';
  end if;

  if new_bay.facility_id <> booking_record.facility_id
     or new_bay.level is distinct from old_bay.level
     or new_bay.type <> old_bay.type then
    raise exception
      'Choose a bay of the same type and level at this facility.';
  end if;

  if new_bay.status <> 'available'
     or new_bay.is_out_of_service then
    raise exception
      'This alternative bay is no longer available. Refresh to find another.';
  end if;

  if exists (
    select 1
    from public.bookings other_booking
    where other_booking.bay_id = new_bay.id
      and other_booking.status in ('reserved', 'active')
  ) then
    raise exception
      'Another driver has reserved this bay. Refresh to find another.';
  end if;

  -- Existing project triggers release the old bay
  -- and mark the new bay as reserved.
  update public.bookings
  set bay_id = new_bay.id
  where id = booking_record.id;

  -- The original bay remains marked out of service,
  -- even when its occupancy status becomes available.
  insert into public.notifications (
    user_id,
    booking_id,
    title,
    message,
    type,
    is_read
  )
  values (
    booking_record.driver_id,
    booking_record.id,
    'Reservation recovered',
    format(
      'Your reservation moved from Bay %s to Bay %s. '
      'Your booking times and price remain unchanged.',
      old_bay.label,
      new_bay.label
    ),
    'booking',
    false
  );

  return booking_record.id;
end;
$$;

revoke all on function
  public.driver_accept_recovery_bay(uuid, uuid, uuid)
from public, anon, authenticated;

grant execute on function
  public.driver_accept_recovery_bay(uuid, uuid, uuid)
to authenticated;

commit;