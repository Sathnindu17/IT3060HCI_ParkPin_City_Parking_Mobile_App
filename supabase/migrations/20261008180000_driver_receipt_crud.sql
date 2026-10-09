begin;

-- A final receipt snapshot: one per completed booking.
create table if not exists public.driver_booking_receipts (
  booking_id uuid primary key
    references public.bookings(id) on delete restrict,
  driver_id uuid not null
    references public.profiles(id) on delete restrict,
  reference text not null,
  facility_name text not null,
  bay_label text not null,
  paid_at timestamptz not null,
  duration_minutes integer not null
    check (duration_minutes >= 0),
  parking_fee_cents bigint not null,
  reservation_fee_cents bigint not null,
  extension_fee_cents bigint not null,
  total_cents bigint not null,
  payment_method text not null,
  created_at timestamptz not null default now(),
  viewed_at timestamptz,
  check (
    total_cents =
      parking_fee_cents +
      reservation_fee_cents +
      extension_fee_cents
  )
);

alter table public.driver_booking_receipts
  enable row level security;

drop policy if exists driver_receipts_read_own
  on public.driver_booking_receipts;

create policy driver_receipts_read_own
on public.driver_booking_receipts
for select
to authenticated
using (driver_id = (select auth.uid()));

-- Clients read snapshots; protected functions create/update them.
revoke all on public.driver_booking_receipts
from public, anon, authenticated;

grant select on public.driver_booking_receipts
to authenticated;

-- Internal function. Clients cannot call this directly.
create or replace function public.driver_create_final_receipt_internal(
  p_booking_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_record public.bookings%rowtype;
  facility_name_value text;
  bay_label_value text;
  parking_cents bigint;
  reservation_cents bigint;
  extension_cents bigint;
  total_paid_cents bigint;
  latest_payment_at timestamptz;
  payment_method_value text;
begin
  select *
  into booking_record
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  if booking_record.status <> 'completed' then
    raise exception 'Complete parking before creating a final receipt.';
  end if;

  -- Preserve an existing final snapshot.
  if exists (
    select 1
    from public.driver_booking_receipts
    where booking_id = p_booking_id
  ) then
    return;
  end if;

  select name
  into facility_name_value
  from public.parking_facilities
  where id = booking_record.facility_id;

  select label
  into bay_label_value
  from public.bays
  where id = booking_record.bay_id;

  select
    coalesce(sum(
      case when p.type = 'booking'
        then round(p.parking_fee * 100)::bigint
        else 0
      end
    ), 0),
    coalesce(sum(
      case when p.type = 'booking'
        then round(p.reservation_fee * 100)::bigint
        else 0
      end
    ), 0),
    coalesce(sum(
      case when p.type = 'extension'
        then round(p.total * 100)::bigint
        else 0
      end
    ), 0),
    coalesce(sum(round(p.total * 100)::bigint), 0),
    max(p.created_at),
    string_agg(
      distinct case
        when p.method = 'wallet' then 'Wallet'
        else 'Card'
      end,
      ' + '
    )
  into
    parking_cents,
    reservation_cents,
    extension_cents,
    total_paid_cents,
    latest_payment_at,
    payment_method_value
  from public.payments p
  where p.booking_id = booking_record.id
    and p.driver_id = booking_record.driver_id
    and p.status = 'paid';

  if latest_payment_at is null then
    raise exception 'No paid transactions found for this booking.';
  end if;

  if parking_cents + reservation_cents + extension_cents
      <> total_paid_cents then
    raise exception 'Payment breakdown does not match the total.';
  end if;

  insert into public.driver_booking_receipts (
    booking_id,
    driver_id,
    reference,
    facility_name,
    bay_label,
    paid_at,
    duration_minutes,
    parking_fee_cents,
    reservation_fee_cents,
    extension_fee_cents,
    total_cents,
    payment_method
  )
  values (
    booking_record.id,
    booking_record.driver_id,
    booking_record.booking_code,
    coalesce(facility_name_value, 'Parking facility'),
    coalesce(bay_label_value, 'Not assigned'),
    latest_payment_at,
    greatest(
      0,
      floor(extract(
        epoch from
        (booking_record.end_time - booking_record.start_time)
      ) / 60)::integer
    ),
    parking_cents,
    reservation_cents,
    extension_cents,
    total_paid_cents,
    coalesce(payment_method_value, 'Card')
  )
  on conflict (booking_id) do nothing;
end;
$$;

revoke all on function
  public.driver_create_final_receipt_internal(uuid)
from public, anon, authenticated;

-- Automatically create the final receipt on completion.
create or replace function public.driver_receipt_on_completion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'completed' then
    perform public.driver_create_final_receipt_internal(new.id);
  end if;

  return new;
end;
$$;

revoke all on function public.driver_receipt_on_completion()
from public, anon, authenticated;

drop trigger if exists driver_create_receipt_on_completion
on public.bookings;

create trigger driver_create_receipt_on_completion
after insert or update of status
on public.bookings
for each row
execute function public.driver_receipt_on_completion();

-- UPDATE: save the first time the owner opens their receipt.
create or replace function public.driver_mark_receipt_viewed(
  p_booking_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Please sign in to view your receipt.';
  end if;

  update public.driver_booking_receipts
  set viewed_at = coalesce(viewed_at, now())
  where booking_id = p_booking_id
    and driver_id = auth.uid();

  if not found then
    raise exception 'Receipt not found.';
  end if;
end;
$$;

revoke all on function public.driver_mark_receipt_viewed(uuid)
from public, anon;

grant execute on function public.driver_mark_receipt_viewed(uuid)
to authenticated;

-- DELETE / RESTORE: change history visibility.
-- Payment and receipt records remain saved.
create or replace function public.driver_set_booking_history_visibility(
  p_booking_id uuid,
  p_hidden boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  booking_record public.bookings%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to manage your history.';
  end if;

  if p_hidden is null then
    raise exception 'Choose hide or restore.';
  end if;

  select *
  into booking_record
  from public.bookings
  where id = p_booking_id
    and driver_id = auth.uid()
  for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  if booking_record.status not in (
    'completed', 'cancelled', 'expired'
  ) then
    raise exception 'Active reservations cannot be hidden.';
  end if;

  update public.bookings
  set hidden_from_history = p_hidden
  where id = booking_record.id;
end;
$$;

revoke all on function
  public.driver_set_booking_history_visibility(uuid, boolean)
from public, anon;

grant execute on function
  public.driver_set_booking_history_visibility(uuid, boolean)
to authenticated;

-- Create snapshots for previously completed paid bookings,
-- including your existing test booking.
do $$
declare
  booking_record record;
begin
  for booking_record in
    select b.id
    from public.bookings b
    where b.status = 'completed'
      and not exists (
        select 1
        from public.driver_booking_receipts r
        where r.booking_id = b.id
      )
      and exists (
        select 1
        from public.payments p
        where p.booking_id = b.id
          and p.driver_id = b.driver_id
          and p.status = 'paid'
      )
  loop
    perform public.driver_create_final_receipt_internal(
      booking_record.id
    );
  end loop;
end;
$$;

commit;

select
  reference,
  total_cents,
  created_at,
  viewed_at
from public.driver_booking_receipts
where booking_id =
  '56e98c8e-f0b7-46de-9ab5-c81001e4d5ff'::uuid;