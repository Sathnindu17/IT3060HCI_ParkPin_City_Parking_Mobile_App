-- ParkPin – functions and triggers (run second)

-- Create a profile automatically when someone signs up.
-- New accounts are always drivers; operator/authority roles are set by the team (see seed.sql).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Role of the logged-in user (used by RLS policies)
create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- Facility managed by the logged-in operator (used by RLS policies)
create or replace function public.operator_facility_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select facility_id from public.profiles where id = auth.uid();
$$;

-- Keep bays.updated_at current
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger bays_touch_updated_at
  before update on public.bays
  for each row execute function public.touch_updated_at();

-- Keep bay status in sync with its booking, so drivers never edit bays directly.
-- reserved -> bay reserved · active -> bay occupied · completed/cancelled/expired -> bay available
create or replace function public.sync_bay_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Bay changed on an existing booking: free the old bay
  if tg_op = 'UPDATE' and old.bay_id is distinct from new.bay_id and old.bay_id is not null then
    update public.bays set status = 'available' where id = old.bay_id;
  end if;

  if new.bay_id is not null then
    update public.bays
    set status = case new.status
                   when 'reserved' then 'reserved'::public.bay_status
                   when 'active'   then 'occupied'::public.bay_status
                   else 'available'::public.bay_status
                 end
    where id = new.bay_id;
  end if;

  return new;
end;
$$;

create trigger bookings_sync_bay_status
  after insert or update of status, bay_id on public.bookings
  for each row execute function public.sync_bay_status();

-- Free the bay if a live booking is deleted
create or replace function public.free_bay_on_booking_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.bay_id is not null and old.status in ('reserved', 'active') then
    update public.bays set status = 'available' where id = old.bay_id;
  end if;
  return old;
end;
$$;

create trigger bookings_free_bay_on_delete
  after delete on public.bookings
  for each row execute function public.free_bay_on_booking_delete();

-- Live bay availability for the app (FR1)
alter publication supabase_realtime add table public.bays;
