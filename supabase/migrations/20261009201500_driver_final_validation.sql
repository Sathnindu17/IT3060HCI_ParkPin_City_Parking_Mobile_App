begin;

alter table public.payments
  add column if not exists is_demo boolean not null default false;

-- Drivers use protected functions for session changes.
-- Existing operator and authority policies remain in place.
drop policy if exists "bookings: driver updates own"
  on public.bookings;

drop policy if exists "bookings: driver deletes own"
  on public.bookings;

drop policy if exists "payments: driver creates own"
  on public.payments;

drop policy if exists driver_bookings_no_direct_update
  on public.bookings;

create policy driver_bookings_no_direct_update
on public.bookings
as restrictive
for update
to authenticated
using (public.current_user_role() = 'operator')
with check (public.current_user_role() = 'operator');

drop policy if exists driver_bookings_no_direct_delete
  on public.bookings;

create policy driver_bookings_no_direct_delete
on public.bookings
as restrictive
for delete
to authenticated
using (false);

-- Payment writes must come from protected backend functions.
drop policy if exists payments_backend_insert_only
  on public.payments;

create policy payments_backend_insert_only
on public.payments
as restrictive
for insert
to authenticated
with check (false);

drop policy if exists payments_backend_update_only
  on public.payments;

create policy payments_backend_update_only
on public.payments
as restrictive
for update
to authenticated
using (false)
with check (false);

drop policy if exists payments_backend_delete_only
  on public.payments;

create policy payments_backend_delete_only
on public.payments
as restrictive
for delete
to authenticated
using (false);

-- Drivers may create only their own valid reservations.
drop policy if exists driver_bookings_reservation_insert_only
  on public.bookings;

create policy driver_bookings_reservation_insert_only
on public.bookings
as restrictive
for insert
to authenticated
with check (
  driver_id = auth.uid()
  and public.current_user_role() = 'driver'
  and status = 'reserved'
  and not hidden_from_history
  and completed_at is null
  and end_time > now()
  and exists (
    select 1
    from public.bays b
    where b.id = bookings.bay_id
      and b.facility_id = bookings.facility_id
      and b.status = 'available'
      and not b.is_out_of_service
  )
);

-- Expire only the signed-in driver's elapsed reservations.
-- Existing booking triggers release their bays.
create or replace function public.driver_expire_own_reservations()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  if auth.uid() is null
     or public.current_user_role()
        is distinct from 'driver'::public.user_role then
    raise exception 'A signed-in driver account is required.';
  end if;

  update public.bookings
  set status = 'expired'
  where driver_id = auth.uid()
    and status = 'reserved'
    and end_time <= now();

  get diagnostics affected = row_count;

  return affected;
end;
$$;

revoke all on function public.driver_expire_own_reservations()
from public, anon, authenticated;

grant execute on function public.driver_expire_own_reservations()
to authenticated;

-- Current assignment extension payments are simulated.
create or replace function public.driver_label_demo_extension()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.type = 'extension' then
    new.is_demo := true;
  end if;

  return new;
end;
$$;

revoke all on function public.driver_label_demo_extension()
from public, anon, authenticated;

drop trigger if exists driver_demo_extension_label
on public.payments;

create trigger driver_demo_extension_label
before insert on public.payments
for each row
execute function public.driver_label_demo_extension();

-- Label new receipt snapshots using their actual payment records.
-- Existing final receipts remain unchanged.
create or replace function public.driver_label_receipt_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select coalesce(
    string_agg(
      distinct case
        when p.is_demo then 'Demo payment (no charge)'
        when p.method = 'wallet' then 'Wallet'
        else 'Card'
      end,
      ' + '
    ),
    new.payment_method
  )
  into new.payment_method
  from public.payments p
  where p.booking_id = new.booking_id
    and p.driver_id = new.driver_id
    and p.status = 'paid';

  return new;
end;
$$;

revoke all on function public.driver_label_receipt_payment()
from public, anon, authenticated;

drop trigger if exists driver_receipt_payment_label
on public.driver_booking_receipts;

create trigger driver_receipt_payment_label
before insert on public.driver_booking_receipts
for each row
execute function public.driver_label_receipt_payment();

-- Protected checkout for the group's assignment demo.
-- Calculates fees on the server. Does not charge a card.
create or replace function public.driver_confirm_demo_booking_payment(
  p_booking_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  b public.bookings%rowtype;
  f public.parking_facilities%rowtype;
  parking numeric;
begin
  if auth.uid() is null
     or public.current_user_role()
        is distinct from 'driver'::public.user_role then
    raise exception 'A signed-in driver account is required.';
  end if;

  select *
  into b
  from public.bookings
  where id = p_booking_id
    and driver_id = auth.uid()
  for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  if b.status <> 'reserved' or b.end_time <= now() then
    raise exception 'Only a valid reservation can be paid.';
  end if;

  if exists (
    select 1
    from public.payments p
    where p.booking_id = b.id
      and p.driver_id = b.driver_id
      and p.type = 'booking'
      and p.status = 'paid'
  ) then
    return;
  end if;

  select *
  into f
  from public.parking_facilities
  where id = b.facility_id
  for share;

  if not found then
    raise exception 'Parking facility not found.';
  end if;

  if f.rate_per_hour < 0 or f.reservation_fee < 0 then
    raise exception 'The parking price is invalid.';
  end if;

  parking := round(
    f.rate_per_hour *
    extract(epoch from (b.end_time - b.start_time)) /
    3600,
    2
  );

  insert into public.payments (
    booking_id,
    driver_id,
    facility_id,
    parking_fee,
    reservation_fee,
    total,
    method,
    status,
    type,
    is_demo
  )
  values (
    b.id,
    b.driver_id,
    b.facility_id,
    parking,
    f.reservation_fee,
    parking + f.reservation_fee,
    'card',
    'paid',
    'booking',
    true
  );
end;
$$;

revoke all on function
public.driver_confirm_demo_booking_payment(uuid)
from public, anon, authenticated;

grant execute on function
public.driver_confirm_demo_booking_payment(uuid)
to authenticated;

commit;