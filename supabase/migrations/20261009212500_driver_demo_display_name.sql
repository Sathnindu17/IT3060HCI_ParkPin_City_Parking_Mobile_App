begin;

-- Rename the fictional parking facility.
-- Active Booking, Extend Parking and History read this name.
update public.parking_facilities
set name = 'Colombo City Parking (Demo)'
where name = 'Final CRUD Test Parking (Demo)';

-- Correct the display name in existing receipt snapshots.
-- Receipt amounts and payment information remain unchanged.
update public.driver_booking_receipts
set facility_name = 'Colombo City Parking (Demo)'
where facility_name = 'Final CRUD Test Parking (Demo)';

commit;

-- Verify the renamed facilities.
select
  id,
  name
from public.parking_facilities
where name = 'Colombo City Parking (Demo)';

-- Verify the renamed receipts.
select
  reference,
  facility_name,
  total_cents
from public.driver_booking_receipts
where facility_name = 'Colombo City Parking (Demo)';