-- ParkPin – Row Level Security (run third)
-- Every table is locked by default; these policies open only what each role needs (NFR3).

alter table public.profiles                enable row level security;
alter table public.parking_facilities      enable row level security;
alter table public.bays                    enable row level security;
alter table public.bookings                enable row level security;
alter table public.payments                enable row level security;
alter table public.pricing_rules           enable row level security;
alter table public.illegal_parking_reports enable row level security;
alter table public.legal_parking_zones     enable row level security;
alter table public.notifications           enable row level security;

-- ───────── profiles ─────────
create policy "profiles: read own, staff read all" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.current_user_role() in ('operator', 'authority'));

create policy "profiles: update own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Users may change their name/phone but never their own role or facility
revoke update on public.profiles from authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

-- ───────── parking_facilities ─────────
create policy "facilities: everyone signed in can read" on public.parking_facilities
  for select to authenticated using (true);

create policy "facilities: operator updates own" on public.parking_facilities
  for update to authenticated
  using (operator_id = auth.uid()) with check (operator_id = auth.uid());

-- ───────── bays ─────────
create policy "bays: everyone signed in can read" on public.bays
  for select to authenticated using (true);

create policy "bays: operator manages own facility" on public.bays
  for all to authenticated
  using (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id())
  with check (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id());

-- ───────── bookings ─────────
create policy "bookings: driver reads own" on public.bookings
  for select to authenticated using (driver_id = auth.uid());

-- Drivers can only book a bay that is currently available
create policy "bookings: driver creates own" on public.bookings
  for insert to authenticated
  with check (
    driver_id = auth.uid()
    and (
      bay_id is null
      or exists (select 1 from public.bays b where b.id = bay_id and b.status = 'available')
    )
  );

create policy "bookings: driver updates own" on public.bookings
  for update to authenticated
  using (driver_id = auth.uid()) with check (driver_id = auth.uid());

create policy "bookings: driver deletes own" on public.bookings
  for delete to authenticated using (driver_id = auth.uid());

create policy "bookings: operator reads own facility" on public.bookings
  for select to authenticated
  using (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id());

create policy "bookings: operator updates own facility" on public.bookings
  for update to authenticated
  using (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id())
  with check (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id());

create policy "bookings: authority reads all" on public.bookings
  for select to authenticated
  using (public.current_user_role() = 'authority');

-- ───────── payments ─────────
create policy "payments: driver reads own" on public.payments
  for select to authenticated using (driver_id = auth.uid());

create policy "payments: driver creates own" on public.payments
  for insert to authenticated with check (driver_id = auth.uid());

create policy "payments: operator reads own facility" on public.payments
  for select to authenticated
  using (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id());

-- ───────── pricing_rules ─────────
create policy "pricing: everyone signed in can read" on public.pricing_rules
  for select to authenticated using (true);

create policy "pricing: operator manages own facility" on public.pricing_rules
  for all to authenticated
  using (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id())
  with check (public.current_user_role() = 'operator' and facility_id = public.operator_facility_id());

-- ───────── illegal_parking_reports ─────────
create policy "reports: authority full access" on public.illegal_parking_reports
  for all to authenticated
  using (public.current_user_role() = 'authority')
  with check (public.current_user_role() = 'authority');

-- ───────── legal_parking_zones ─────────
create policy "zones: everyone signed in can read" on public.legal_parking_zones
  for select to authenticated using (true);

create policy "zones: authority manages" on public.legal_parking_zones
  for all to authenticated
  using (public.current_user_role() = 'authority')
  with check (public.current_user_role() = 'authority');

-- ───────── notifications ─────────
create policy "notifications: user reads own" on public.notifications
  for select to authenticated using (user_id = auth.uid());

create policy "notifications: user updates own" on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "notifications: user deletes own" on public.notifications
  for delete to authenticated using (user_id = auth.uid());

create policy "notifications: self or staff can create" on public.notifications
  for insert to authenticated
  with check (user_id = auth.uid() or public.current_user_role() in ('operator', 'authority'));
