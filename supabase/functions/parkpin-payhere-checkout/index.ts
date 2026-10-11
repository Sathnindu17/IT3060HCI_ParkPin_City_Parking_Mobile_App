import { createClient } from 'npm:@supabase/supabase-js@2';
import md5 from 'npm:blueimp-md5@2.19.0';

const url = Deno.env.get('SUPABASE_URL')!;
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const merchantId = Deno.env.get('PAYHERE_MERCHANT_ID')!;
const merchantSecret = Deno.env.get('PAYHERE_MERCHANT_SECRET')!;
const functionsBase = `${url}/functions/v1`;
const admin = createClient(url, serviceKey);

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};
const json = (value: unknown, status = 200) =>
  new Response(JSON.stringify(value), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
const html = (value: string) =>
  new Response(value, {
    headers: {
      ...cors,
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    },
  });
const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('"', '&quot;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;');
const md5Upper = (value: string) => md5(value).toUpperCase();

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('OK', { status: 200, headers: cors });
  }

  try {
    const requestUrl = new URL(req.url);

    if (req.method === 'GET') {
      const token = requestUrl.searchParams.get('token');
      if (!token || !/^[0-9a-f-]{36}$/i.test(token)) {
        return html('Invalid checkout link');
      }
      const { data: attempt, error } = await admin
        .from('parkpin_checkout_attempts')
        .select('id,state,amount,expires_at')
        .eq('id', token)
        .single();
      if (error || !attempt) return html('Checkout not found');

      if (requestUrl.searchParams.has('return')) {
        return html('<h2>Return to ParkPin</h2><p>Return to ParkPin '
          + 'and tap Check payment status. The server must verify PayHere '
          + 'before your booking is confirmed.</p>');
      }
      if (attempt.state !== 'pending'
          || Date.parse(attempt.expires_at) <= Date.now()) {
        return html('Checkout is no longer available');
      }

      const amount = Number(attempt.amount).toFixed(2);
      const checkoutHash = md5Upper(
        `${merchantId}${attempt.id}${amount}LKR${md5Upper(merchantSecret)}`,
      );
      const values: Record<string, string> = {
        merchant_id: merchantId,
        return_url: `${functionsBase}/parkpin-payhere-checkout?token=${attempt.id}&return=1`,
        cancel_url: `${functionsBase}/parkpin-payhere-checkout?token=${attempt.id}&return=1`,
        notify_url: `${functionsBase}/parkpin-payhere-notify`,
        order_id: attempt.id,
        items: 'ParkPin Sandbox Parking Reservation',
        currency: 'LKR',
        amount,
        first_name: 'ParkPin',
        last_name: 'Test Driver',
        email: 'testdriver@example.com',
        phone: '0771234567',
        address: 'Sandbox Test',
        city: 'Colombo',
        country: 'Sri Lanka',
        hash: checkoutHash,
      };
      const inputs = Object.entries(values)
        .map(([key, value]) =>
          `<input type="hidden" name="${escapeHtml(key)}" value="${escapeHtml(value)}">`)
        .join('\n');

      // This is a browser POST form, not the native Android PayHere SDK.
      // PayHere may require its host/domain to be approved separately.
      return html(`<!doctype html><html><head><meta name="referrer" `
        + `content="strict-origin-when-cross-origin"><title>PayHere Sandbox</title>`
        + `</head><body><h3>Redirecting to PayHere Sandbox...</h3>`
        + `<form id="pay" method="POST" action="https://sandbox.payhere.lk/pay/checkout">`
        + `${inputs}<button type="submit">Continue to PayHere Sandbox</button>`
        + `</form><script>document.getElementById('pay').submit()</script>`
        + `</body></html>`);
    }

    if (req.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }
    const jwt = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
    if (!jwt) return json({ error: 'Sign in required' }, 401);
    const authClient = createClient(url, anonKey);
    const { data: { user }, error: authError } = await authClient.auth.getUser(jwt);
    if (authError || !user) return json({ error: 'Invalid login' }, 401);

    const body = await req.json();
    const facilityId = String(body.facility_id ?? '');
    const bayId = String(body.bay_id ?? '');
    const hours = Number(body.duration_hours);
    const start = new Date(body.start_time);
    if (!Number.isInteger(hours) || hours < 1 || hours > 24
        || !Number.isFinite(start.getTime())
        || start.getTime() < Date.now() - 60000) {
      return json({ error: 'Invalid arrival or duration' }, 400);
    }
    const vehicleType = String(body.vehicle_type ?? '').trim().slice(0, 40);
    const vehicleNumberRaw = String(body.vehicle_number ?? '').trim().toUpperCase();
    if (vehicleNumberRaw.length > 24 ||
        (vehicleNumberRaw && !/^[A-Z0-9 -]+$/.test(vehicleNumberRaw))) {
      return json({ error: 'Invalid vehicle registration' }, 400);
    }
    const vehicleNumber = vehicleNumberRaw.length ? vehicleNumberRaw : null;
    const end = new Date(start.getTime() + hours * 3600000);

    const [facilityResult, bayResult, bookingResult] = await Promise.all([
      admin.from('parking_facilities')
        .select('id,rate_per_hour,reservation_fee')
        .eq('id', facilityId).single(),
      admin.from('bays')
        .select('id,facility_id,status').eq('id', bayId).single(),
      admin.from('bookings')
        .select('id').eq('bay_id', bayId)
        .in('status', ['reserved', 'active']).limit(1),
    ]);
    if (facilityResult.error || bayResult.error || bookingResult.error) {
      return json({ error: 'Could not check parking availability or pricing' }, 503);
    }
    const facility = facilityResult.data;
    const bay = bayResult.data;
    if (!facility || !bay || bay.facility_id !== facilityId
        || bay.status !== 'available' || (bookingResult.data?.length ?? 0) > 0) {
      return json({ error: 'Bay unavailable' }, 409);
    }

    const rate = Number(facility.rate_per_hour);
    const reservationFee = Number(facility.reservation_fee);
    if (!Number.isFinite(rate) || !Number.isFinite(reservationFee)
        || rate < 0 || reservationFee < 0) {
      return json({ error: 'Invalid server pricing' }, 500);
    }
    const parkingFee = Number((rate * hours).toFixed(2));
    const amount = Number((parkingFee + reservationFee).toFixed(2));
    if (amount <= 0 || !Number.isFinite(amount)) {
      return json({ error: 'Invalid checkout amount' }, 400);
    }

    const { data: attempt, error } = await admin
      .from('parkpin_checkout_attempts')
      .insert({
        driver_id: user.id,
        facility_id: facilityId,
        bay_id: bayId,
        start_time: start.toISOString(),
        end_time: end.toISOString(),
        vehicle_type: vehicleType || 'Car',
        vehicle_number: vehicleNumber,
        parking_fee: parkingFee,
        reservation_fee: reservationFee,
        amount,
      })
      .select('id,amount')
      .single();
    if (error || !attempt) {
      console.error('Checkout insert failed:', error?.code, error?.message);
      return json({ error: 'Could not create checkout. Verify the SQL migration.' }, 500);
    }

    return json({
      attempt_id: attempt.id,
      amount: attempt.amount,
      checkout_url: `${functionsBase}/parkpin-payhere-checkout?token=${attempt.id}`,
    });
  } catch (error) {
    console.error('Checkout error:', error);
    return json({ error: 'Checkout temporarily unavailable' }, 500);
  }
});
