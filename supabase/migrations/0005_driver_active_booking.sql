begin;

-- Record when a driver actually finishes parking.
-- Keep end_time as the purchased parking end time.
alter table public.bookings
  add column if not exists completed_at timestamptz;


-- ============================================================
-- 1. Start a paid reservation
-- ============================================================

create or replace function public.driver_start_booking(
  p_booking_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_booking public.bookings%rowtype;
  v_bay public.bays%rowtype;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Please sign in first.';
  end if;

  select *
  into v_booking
  from public.bookings
  where id = p_booking_id
    and driver_id = v_user_id
  for update;

  if not found then
    raise exception 'Booking not found or access denied.';
  end if;

  -- Repeated requests must not restart an existing session.
  if v_booking.status in (
    'active',
    'completed',
    'cancelled',
    'expired'
  ) then
    return;
  end if;

  if v_booking.status <> 'reserved' then
    raise exception 'This booking cannot be started.';
  end if;

  if now() < v_booking.start_time then
    raise exception 'Your reservation has not started yet.';
  end if;

  if now() >= v_booking.end_time then
    raise exception 'Your reservation period has ended.';
  end if;

  if v_booking.bay_id is null then
    raise exception 'No parking bay is assigned to this booking.';
  end if;

  select *
  into v_bay
  from public.bays
  where id = v_booking.bay_id
    and facility_id = v_booking.facility_id
  for update;

  if not found then
    raise exception 'The assigned parking bay is invalid.';
  end if;

  if v_bay.status <> 'reserved' then
    raise exception 'The assigned bay is not in the reserved state.';
  end if;

  if not exists (
    select 1
    from public.payments payment
    where payment.booking_id = v_booking.id
      and payment.driver_id = v_user_id
      and payment.type = 'booking'
      and payment.status = 'paid'
  ) then
    raise exception 'A paid booking payment is required.';
  end if;

  update public.bookings
  set status = 'active'
  where id = v_booking.id;

  -- The existing booking trigger changes the bay to occupied.
end;
$$;


-- ============================================================
-- 2. Extend an active parking session
-- Allowed options: 30, 60, or 120 minutes
-- Payment and end-time changes happen in one transaction.
-- Payments are simulated for the assignment.
-- ============================================================

create or replace function public.driver_extend_booking_minutes(
  p_booking_id uuid,
  p_minutes integer,
  p_expected_end_time timestamptz,
  p_expected_fee numeric
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_booking public.bookings%rowtype;
  v_bay public.bays%rowtype;
  v_rate numeric;
  v_fee numeric;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Please sign in first.';
  end if;

  if p_minutes is null or p_minutes not in (30, 60, 120) then
    raise exception 'Choose an extension of 30, 60, or 120 minutes.';
  end if;

  select *
  into v_booking
  from public.bookings
  where id = p_booking_id
    and driver_id = v_user_id
  for update;

  if not found then
    raise exception 'Booking not found or access denied.';
  end if;

  if v_booking.status <> 'active' then
    raise exception 'Only an active parking session can be extended.';
  end if;

  if now() >= v_booking.end_time then
    raise exception 'This session has ended and cannot be extended.';
  end if;

  -- Reject stale or repeated extension requests.
  if v_booking.end_time is distinct from p_expected_end_time then
    raise exception
      'The booking end time has changed. Refresh and try again.';
  end if;

  if v_booking.bay_id is null then
    raise exception 'No bay is assigned to this session.';
  end if;

  select *
  into v_bay
  from public.bays
  where id = v_booking.bay_id
    and facility_id = v_booking.facility_id
  for update;

  if not found then
    raise exception 'The assigned parking bay is invalid.';
  end if;

  if v_bay.status <> 'occupied' then
    raise exception 'The bay is not in an active occupied state.';
  end if;

  if not exists (
    select 1
    from public.payments payment
    where payment.booking_id = v_booking.id
      and payment.driver_id = v_user_id
      and payment.type = 'booking'
      and payment.status = 'paid'
  ) then
    raise exception 'A paid booking payment is required.';
  end if;

  select rate_per_hour
  into v_rate
  from public.parking_facilities
  where id = v_booking.facility_id
  for share;

  if not found then
    raise exception 'Parking facility not found.';
  end if;

  v_fee := round(v_rate * p_minutes / 60.0, 2);

  if p_expected_fee is null
     or round(p_expected_fee, 2) is distinct from v_fee then
    raise exception
      'The extension price has changed. Refresh and try again.';
  end if;

  insert into public.payments (
    booking_id,
    driver_id,
    facility_id,
    parking_fee,
    reservation_fee,
    total,
    method,
    status,
    type
  )
  values (
    v_booking.id,
    v_user_id,
    v_booking.facility_id,
    v_fee,
    0,
    v_fee,
    'card',
    'paid',
    'extension'
  );

  update public.bookings
  set end_time =
    v_booking.end_time + make_interval(mins => p_minutes)
  where id = v_booking.id;
end;
$$;


-- ============================================================
-- 3. Compatibility function for the original 30-minute option
-- ============================================================

create or replace function public.driver_extend_booking(
  p_booking_id uuid,
  p_expected_end_time timestamptz,
  p_expected_fee numeric
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform public.driver_extend_booking_minutes(
    p_booking_id,
    30,
    p_expected_end_time,
    p_expected_fee
  );
end;
$$;


-- ============================================================
-- 4. Finish an active parking session
-- ============================================================

create or replace function public.driver_finish_booking(
  p_booking_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_booking public.bookings%rowtype;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Please sign in first.';
  end if;

  select *
  into v_booking
  from public.bookings
  where id = p_booking_id
    and driver_id = v_user_id
  for update;

  if not found then
    raise exception 'Booking not found or access denied.';
  end if;

  -- Repeated finish requests are harmless.
  if v_booking.status = 'completed' then
    return;
  end if;

  if v_booking.status <> 'active' then
    raise exception 'Only an active parking session can be completed.';
  end if;

  update public.bookings
  set
    status = 'completed',
    completed_at = now()
  where id = v_booking.id;

  -- The existing booking trigger releases the parking bay.
  -- Booking and payment records remain available for history.
end;
$$;


-- ============================================================
-- Permissions
-- Only signed-in users can call these functions.
-- Each function also checks ownership of the booking.
-- ============================================================

revoke all on function public.driver_start_booking(uuid)
  from public, anon;

grant execute on function public.driver_start_booking(uuid)
  to authenticated;


revoke all on function public.driver_finish_booking(uuid)
  from public, anon;

grant execute on function public.driver_finish_booking(uuid)
  to authenticated;


revoke all on function public.driver_extend_booking(
  uuid,
  timestamptz,
  numeric
) from public, anon;

grant execute on function public.driver_extend_booking(
  uuid,
  timestamptz,
  numeric
) to authenticated;


revoke all on function public.driver_extend_booking_minutes(
  uuid,
  integer,
  timestamptz,
  numeric
) from public, anon;

grant execute on function public.driver_extend_booking_minutes(
  uuid,
  integer,
  timestamptz,
  numeric
) to authenticated;

commit;


-- Verify installation.
select
  to_regprocedure(
    'public.driver_start_booking(uuid)'
  ) as start_booking_function,

  to_regprocedure(
    'public.driver_finish_booking(uuid)'
  ) as finish_booking_function,

  to_regprocedure(
    'public.driver_extend_booking(uuid,timestamp with time zone,numeric)'
  ) as fixed_extension_function,

  to_regprocedure(
    'public.driver_extend_booking_minutes(uuid,integer,timestamp with time zone,numeric)'
  ) as extension_options_function;