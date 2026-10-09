-- ParkPin – operator demo data (run AFTER seed.sql, in the Supabase SQL editor)
-- Gives One Galle Face bookings, payments and notifications so the operator
-- screens (O02–O09) have something to show. Safe to run again: it removes the
-- previous demo rows first. Gate-check demo codes: PP-DEMO01 … PP-DEMO06.

delete from public.bookings where booking_code like 'PP-DEMO%';
delete from public.notifications
where user_id = (select id from auth.users where email = 'operator@parkpin.lk')
  and title in ('New booking — B2', 'Gate scan complete', 'Low availability');

with ctx as (
  select f.id as facility_id,
         (select id from auth.users where email = 'driver@parkpin.lk') as driver_id
  from public.parking_facilities f
  where f.name = 'One Galle Face'
),
bay as (
  select b.label, b.id from public.bays b join ctx on b.facility_id = ctx.facility_id
)
insert into public.bookings
  (driver_id, facility_id, bay_id, vehicle_number, start_time, end_time, status, booking_code)
select ctx.driver_id, ctx.facility_id, v.bay_id, v.vehicle, v.st, v.et, v.status::public.booking_status, v.code
from ctx,
lateral (values
  ((select id from bay where label = 'B2'), 'CAB-1234', now() + interval '1 hour',   now() + interval '3 hours',  'reserved',  'PP-DEMO01'),
  (null::uuid,                              'KX-4521',  now() + interval '2 hours',  now() + interval '4 hours',  'reserved',  'PP-DEMO02'),
  ((select id from bay where label = 'B3'), 'WP-CAD-7788', now() + interval '20 minutes', now() + interval '2 hours', 'reserved', 'PP-DEMO03'),
  ((select id from bay where label = 'B5'), 'CAR-9087', now() - interval '1 hour',   now() + interval '1 hour',   'active',    'PP-DEMO04'),
  ((select id from bay where label = 'B6'), 'BEE-3321', now() - interval '5 hours',  now() - interval '3 hours',  'completed', 'PP-DEMO05'),
  ((select id from bay where label = 'B7'), 'CAA-5555', now() - interval '26 hours', now() - interval '24 hours', 'expired',   'PP-DEMO06')
) as v(bay_id, vehicle, st, et, status, code);

-- Simulated payments (cascade-deleted with their bookings)
insert into public.payments
  (booking_id, driver_id, facility_id, parking_fee, reservation_fee, total, method, status, type, created_at)
select b.id, b.driver_id, b.facility_id, p.fee, 50, p.fee + 50, p.method::public.payment_method,
       'paid', p.type, p.at
from public.bookings b
join (values
  ('PP-DEMO01', 200, 'card',   'booking',   now() - interval '20 minutes'),
  ('PP-DEMO03', 100, 'wallet', 'booking',   now() - interval '35 minutes'),
  ('PP-DEMO04', 200, 'card',   'booking',   now() - interval '70 minutes'),
  ('PP-DEMO05', 200, 'card',   'booking',   now() - interval '5 hours'),
  ('PP-DEMO06', 200, 'wallet', 'booking',   now() - interval '3 days')
) as p(code, fee, method, type, at) on p.code = b.booking_code;

-- Operator notifications (O09)
insert into public.notifications (user_id, title, message, type, is_read, created_at)
select u.id, n.title, n.message, n.type, n.is_read, now() - n.ago
from auth.users u,
lateral (values
  ('New booking — B2',   'Arrival soon · hold placed',   'booking', false, interval '1 minute'),
  ('Gate scan complete', 'Bay B5 admitted · PP-DEMO04',  'system',  false, interval '1 hour'),
  ('Low availability',   'Only a few bays free on L1',   'system',  true,  interval '3 hours')
) as n(title, message, type, is_read, ago)
where u.email = 'operator@parkpin.lk';
