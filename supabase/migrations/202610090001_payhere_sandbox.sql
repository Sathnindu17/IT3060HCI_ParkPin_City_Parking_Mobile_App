-- ParkPin PayHere SANDBOX migration.
-- REVIEW / TEST AGAINST A DEVELOPMENT DATABASE BEFORE PRODUCTION.
-- Requires existing public.profiles, public.parking_facilities, public.bays,
-- public.bookings and public.payments with the columns/types used below.
-- IMPORTANT: A bay is NOT held while payment is pending. A successful PayHere
-- charge can reach state='conflict' and MUST be reconciled/refunded manually.

create table if not exists public.parkpin_checkout_attempts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.profiles(id),
  facility_id uuid not null references public.parking_facilities(id),
  bay_id uuid not null references public.bays(id),
  start_time timestamptz not null,
  end_time timestamptz not null,
  vehicle_type text not null,
  vehicle_number text,
  parking_fee numeric(10,2) not null,
  reservation_fee numeric(10,2) not null,
  amount numeric(10,2) not null,
  currency text not null default 'LKR' check(currency = 'LKR'),
  state text not null default 'pending'
      check(state in ('pending','paid','failed','cancelled','conflict')),
  booking_id uuid references public.bookings(id),
  payhere_payment_id text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '15 minutes'),
  check(end_time > start_time),
  check(amount > 0),
  check(parking_fee >= 0),
  check(reservation_fee >= 0)
);

-- Makes the migration repeatable on a development database where the older
-- starter version of the table might have been applied already.
alter table public.parkpin_checkout_attempts
  add column if not exists vehicle_number text;

create index if not exists parkpin_checkout_driver_idx
  on public.parkpin_checkout_attempts(driver_id);

create unique index if not exists parkpin_checkout_payhere_payment_id_idx
  on public.parkpin_checkout_attempts(payhere_payment_id)
  where payhere_payment_id is not null;

alter table public.parkpin_checkout_attempts enable row level security;

drop policy if exists "Drivers read own sandbox checkout"
  on public.parkpin_checkout_attempts;
create policy "Drivers read own sandbox checkout"
  on public.parkpin_checkout_attempts
  for select to authenticated
  using (driver_id = (select auth.uid()));

-- Drivers only READ their own attempts. The Edge Functions write as service_role.
revoke all on public.parkpin_checkout_attempts from anon, authenticated;
grant select on public.parkpin_checkout_attempts to authenticated;
grant all on public.parkpin_checkout_attempts to service_role;

-- Only the verified webhook's service_role client may finalize a checkout.
-- This is one database transaction, with a row lock on the checkout and bay.
create or replace function public.parkpin_finalize_sandbox_checkout(
  p_attempt_id uuid,
  p_payment_id text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.parkpin_checkout_attempts%rowtype;
  b uuid;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Service role required';
  end if;
  if p_payment_id is null or length(btrim(p_payment_id)) = 0 then
    raise exception 'Payment ID required';
  end if;

  select * into a
    from public.parkpin_checkout_attempts
    where id = p_attempt_id
    for update;

  if not found then
    raise exception 'Checkout not found';
  end if;
  if a.state = 'paid' then
    return a.booking_id; -- Idempotent retry of a verified PayHere success.
  end if;
  if a.state = 'conflict' then
    return null; -- Already flagged for manual reconciliation.
  end if;
  if a.state <> 'pending' then
    raise exception 'Checkout is not pending';
  end if;

  -- A late payment is recorded, but is NOT represented as a confirmed booking.
  if clock_timestamp() > a.expires_at then
    update public.parkpin_checkout_attempts
      set state = 'conflict', payhere_payment_id = p_payment_id
      where id = a.id;
    return null;
  end if;

  perform 1 from public.bays where id = a.bay_id for update;
  if not found then
    update public.parkpin_checkout_attempts
      set state = 'conflict', payhere_payment_id = p_payment_id
      where id = a.id;
    return null;
  end if;

  -- The EXISTING ParkPin schema has a partial unique index for live bookings
  -- (reserved,active) on each bay, regardless of overlapping time slots.
  if exists (
    select 1 from public.bookings
     where bay_id = a.bay_id and status in ('reserved','active')
  ) then
    update public.parkpin_checkout_attempts
      set state = 'conflict', payhere_payment_id = p_payment_id
      where id = a.id;
    return null;
  end if;

  insert into public.bookings(
    driver_id, facility_id, bay_id, start_time, end_time, status, vehicle_number
  ) values (
    a.driver_id, a.facility_id, a.bay_id, a.start_time, a.end_time,
    'reserved', a.vehicle_number
  ) returning id into b;

  insert into public.payments(
    booking_id, driver_id, facility_id, parking_fee, reservation_fee,
    total, method, status, type
  ) values (
    b, a.driver_id, a.facility_id, a.parking_fee, a.reservation_fee,
    a.amount, 'card', 'paid', 'booking'
  );

  update public.parkpin_checkout_attempts
     set state = 'paid', booking_id = b, payhere_payment_id = p_payment_id
   where id = a.id;
  return b;
end;
$$;

revoke all on function public.parkpin_finalize_sandbox_checkout(uuid,text)
  from public, anon, authenticated;
grant execute on function public.parkpin_finalize_sandbox_checkout(uuid,text)
  to service_role;

-- IMPORTANT: state='conflict' + payhere_payment_id means PayHere reported
-- successful payment but no booking was created. Inspect and manually
-- reconcile/refund that test transaction; NEVER display D14 for a conflict.
