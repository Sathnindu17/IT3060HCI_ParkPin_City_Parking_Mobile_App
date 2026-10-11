-- ParkPin: SIMULATED payment only. NO PayHere payment, NO real money.
-- Additive migration. REVIEW WITH TEAM BEFORE APPLYING TO SHARED DATABASE.
-- Compatible with the existing WE_46 schema and booking status trigger.

-- Flag simulated transactions clearly for operator reporting.
ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS is_demo boolean NOT NULL DEFAULT false;

-- Owner-controlled switch: OFF by default, even after migration.
CREATE TABLE IF NOT EXISTS public.parkpin_demo_control (
    id boolean PRIMARY KEY DEFAULT true CHECK (id = true),
    enabled boolean NOT NULL DEFAULT false
);
INSERT INTO public.parkpin_demo_control(id, enabled)
VALUES (true, false)
ON CONFLICT (id) DO NOTHING;
ALTER TABLE public.parkpin_demo_control ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.parkpin_demo_control FROM PUBLIC, anon, authenticated;

-- Prevent duplicate demo booking-payment rows.
CREATE UNIQUE INDEX IF NOT EXISTS parkpin_one_demo_payment_per_booking
    ON public.payments(booking_id)
    WHERE is_demo = true AND type = 'booking';

-- Atomic transaction: one reservation + one simulated payment.
-- This function uses the logged-in user, locks the selected bay, and
-- recomputes the price FROM DATABASE, not from client input.
CREATE OR REPLACE FUNCTION public.parkpin_confirm_demo_booking(
    p_facility_id uuid,
    p_bay_id uuid,
    p_start_time timestamptz,
    p_hours integer,
    p_method text,
    p_vehicle_number text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_driver_id uuid := auth.uid();
    v_role public.user_role;
    v_bay public.bays%ROWTYPE;
    v_rate numeric(10,2);
    v_reservation_fee numeric(10,2);
    v_parking_fee numeric(10,2);
    v_amount numeric(10,2);
    v_booking_id uuid;
    v_booking_code text;
    v_vehicle_number text;
BEGIN
    IF auth.role() IS DISTINCT FROM 'authenticated' OR v_driver_id IS NULL THEN
        RAISE EXCEPTION 'Sign in as a driver before booking';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.parkpin_demo_control
         WHERE id = true AND enabled = true
    ) THEN
        RAISE EXCEPTION 'Demo booking is currently disabled by the project owner';
    END IF;

    SELECT role INTO v_role FROM public.profiles WHERE id = v_driver_id;
    IF v_role IS DISTINCT FROM 'driver'::public.user_role THEN
        RAISE EXCEPTION 'Only drivers can create demo bookings';
    END IF;

    IF p_facility_id IS NULL OR p_bay_id IS NULL OR p_start_time IS NULL THEN
        RAISE EXCEPTION 'Select a facility, bay and arrival time';
    END IF;
    IF p_hours IS NULL OR p_hours NOT BETWEEN 1 AND 24 THEN
        RAISE EXCEPTION 'Duration must be between 1 and 24 hours';
    END IF;
    IF p_method IS NULL OR p_method NOT IN ('card', 'wallet') THEN
        RAISE EXCEPTION 'Choose demo card or demo wallet';
    END IF;
    IF p_start_time < now() - interval '5 minutes'
       OR p_start_time > now() + interval '30 days' THEN
        RAISE EXCEPTION 'Choose an arrival time within the next 30 days';
    END IF;

    v_vehicle_number := NULLIF(btrim(p_vehicle_number), '');
    IF length(coalesce(v_vehicle_number, '')) > 24 THEN
        RAISE EXCEPTION 'Vehicle registration is too long';
    END IF;

    -- Lock the bay so two drivers cannot reserve it simultaneously.
    SELECT * INTO v_bay
      FROM public.bays
     WHERE id = p_bay_id
     FOR UPDATE;

    IF NOT FOUND OR v_bay.facility_id <> p_facility_id THEN
        RAISE EXCEPTION 'Selected bay does not belong to this facility';
    END IF;
    IF v_bay.status <> 'available'::public.bay_status THEN
        RAISE EXCEPTION 'This parking bay is no longer available';
    END IF;
    -- Respect the team's existing unique index: one live booking per bay.
    IF EXISTS (
        SELECT 1 FROM public.bookings
         WHERE bay_id = p_bay_id AND status IN ('reserved','active')
    ) THEN
        RAISE EXCEPTION 'The selected bay has already been reserved';
    END IF;

    SELECT rate_per_hour, reservation_fee
      INTO v_rate, v_reservation_fee
      FROM public.parking_facilities
     WHERE id = p_facility_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Parking facility not found';
    END IF;
    v_parking_fee := round(v_rate * p_hours, 2);
    v_amount := v_parking_fee + v_reservation_fee;

    INSERT INTO public.bookings (
        driver_id, facility_id, bay_id, vehicle_number,
        start_time, end_time, status
    ) VALUES (
        v_driver_id, p_facility_id, p_bay_id, v_vehicle_number,
        p_start_time, p_start_time + make_interval(hours => p_hours),
        'reserved'::public.booking_status
    )
    RETURNING id, booking_code INTO v_booking_id, v_booking_code;

    INSERT INTO public.payments (
        booking_id, driver_id, facility_id,
        parking_fee, reservation_fee, total,
        method, status, type, is_demo
    ) VALUES (
        v_booking_id, v_driver_id, p_facility_id,
        v_parking_fee, v_reservation_fee, v_amount,
        p_method::public.payment_method,
        'paid'::public.payment_status, 'booking', true
    );

    -- Any exception rolls back BOTH rows. Existing trigger updates bay status.
    RETURN jsonb_build_object(
        'booking_id', v_booking_id,
        'booking_code', v_booking_code,
        'amount', v_amount,
        'method', p_method,
        'is_demo', true
    );
END;
$$;

REVOKE ALL ON FUNCTION public.parkpin_confirm_demo_booking(
    uuid,uuid,timestamptz,integer,text,text
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.parkpin_confirm_demo_booking(
    uuid,uuid,timestamptz,integer,text,text
) TO authenticated;

-- Refresh Supabase's REST RPC metadata cache.
NOTIFY pgrst, 'reload schema';

-- After team approval, the project owner must explicitly enable demo writes:
-- UPDATE public.parkpin_demo_control SET enabled = true WHERE id = true;
-- Disable after testing:
-- UPDATE public.parkpin_demo_control SET enabled = false WHERE id = true;
