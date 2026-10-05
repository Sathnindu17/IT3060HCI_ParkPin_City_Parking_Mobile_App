-- ParkPin – demo data (run after the three migrations)

-- ───────── Part 1: facilities and bays ─────────
insert into public.parking_facilities
  (name, address, latitude, longitude, rate_per_hour, reservation_fee, total_bays, amenities)
values
  ('One Galle Face',      'Colombo 02', 6.9271, 79.8450, 100, 50, 12, array['Covered', 'CCTV', 'EV']),
  ('Liberty Plaza',       'Colombo 03', 6.9116, 79.8510,  80, 50,  8, array['CCTV']),
  ('Colombo City Centre', 'Colombo 02', 6.9175, 79.8560, 120, 75, 10, array['Covered', 'CCTV']);

insert into public.bays (facility_id, label, level, type, status)
select
  f.id,
  'B' || g.n,
  case when g.n <= f.total_bays / 2 then 'L1' else 'L2' end,
  case when g.n = 1 then 'ev'::public.bay_type else 'standard'::public.bay_type end,
  case when g.n % 4 = 0 then 'occupied'::public.bay_status else 'available'::public.bay_status end
from public.parking_facilities f
cross join lateral generate_series(1, f.total_bays) as g(n);

insert into public.legal_parking_zones (name, area, latitude, longitude, capacity, notes)
values
  ('Galle Face Green roadside', 'Colombo 03', 6.9245, 79.8455, 40, 'Pay-and-display, 7am–9pm'),
  ('Fort Railway Station lot',  'Colombo 01', 6.9339, 79.8500, 60, 'Open 24 hours');

-- ───────── Part 2: demo accounts ─────────
-- 1. In Supabase: Authentication → Users → Add user (tick "Auto Confirm User") and create:
--      driver@parkpin.lk, operator@parkpin.lk, authority@parkpin.lk   (password: Password123)
-- 2. Then run the lines below to give the operator and authority their roles.

update public.profiles
set full_name = 'Demo Operator',
    role = 'operator',
    facility_id = (select id from public.parking_facilities where name = 'One Galle Face')
where id = (select id from auth.users where email = 'operator@parkpin.lk');

update public.parking_facilities
set operator_id = (select id from auth.users where email = 'operator@parkpin.lk')
where name = 'One Galle Face';

update public.profiles
set full_name = 'Demo Authority', role = 'authority'
where id = (select id from auth.users where email = 'authority@parkpin.lk');

update public.profiles
set full_name = 'Demo Driver'
where id = (select id from auth.users where email = 'driver@parkpin.lk');
