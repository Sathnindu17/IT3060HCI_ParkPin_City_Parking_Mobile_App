import { createClient } from 'npm:@supabase/supabase-js@2';
import md5 from 'npm:blueimp-md5@2.19.0';

const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);
const merchantId = Deno.env.get('PAYHERE_MERCHANT_ID')!;
const merchantSecret = Deno.env.get('PAYHERE_MERCHANT_SECRET')!;
const md5Upper = (value: string) => md5(value).toUpperCase();

// PayHere calls notify_url on the server. This is NOT ParkPin push-notification.
Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('POST only', { status: 405 });
  }
  try {
    const params = new URLSearchParams(await request.text());
    const get = (key: string) => params.get(key) ?? '';
    const attemptId = get('order_id');
    const amount = get('payhere_amount');
    const currency = get('payhere_currency');
    const status = get('status_code');
    const signature = get('md5sig').toUpperCase();
    const paymentId = get('payment_id');

    const expected = md5Upper(
      `${merchantId}${attemptId}${amount}${currency}${status}${md5Upper(merchantSecret)}`,
    );
    if (!signature || get('merchant_id') !== merchantId || signature !== expected) {
      return new Response('Invalid signature', { status: 403 });
    }
    const paidAmount = Number(amount);
    if (!Number.isFinite(paidAmount) || paidAmount <= 0 || currency !== 'LKR') {
      return new Response('Invalid amount or currency', { status: 400 });
    }

    const { data: checkout, error } = await admin
      .from('parkpin_checkout_attempts')
      .select('id,amount,currency,state')
      .eq('id', attemptId)
      .single();
    if (error || !checkout || checkout.currency !== currency
        || Number(checkout.amount).toFixed(2) !== paidAmount.toFixed(2)) {
      return new Response('Unknown order or incorrect amount', { status: 400 });
    }
    if (checkout.state !== 'pending') {
      return new Response('Already processed', { status: 200 });
    }

    if (status === '2') {
      if (!paymentId) return new Response('Missing payment ID', { status: 400 });
      const { data: bookingId, error: rpcError } = await admin.rpc(
        'parkpin_finalize_sandbox_checkout',
        { p_attempt_id: attemptId, p_payment_id: paymentId },
      );
      if (rpcError) {
        console.error('Payment finalization failed:', rpcError.code, rpcError.message);
        return new Response('Database confirmation failed', { status: 500 });
      }
      if (bookingId == null) {
        // Successful PayHere payment but no parking booking. The SQL function
        // recorded 'conflict' and the PayHere payment ID for manual follow-up.
        console.error('SANDBOX PAYMENT NEEDS RECONCILIATION', { attemptId });
        return new Response('Recorded for manual reconciliation', { status: 200 });
      }
    } else if (status === '-1' || status === '-2') {
      const newState = status === '-1' ? 'cancelled' : 'failed';
      const { error: updateError } = await admin
        .from('parkpin_checkout_attempts')
        .update({ state: newState })
        .eq('id', attemptId)
        .eq('state', 'pending');
      if (updateError) {
        return new Response('Could not update failed payment', { status: 500 });
      }
    } else {
      // Other gateway statuses (e.g. chargebacks) need separate operations
      // and should NOT automatically create or mark a booking as paid.
      console.warn('Unhandled PayHere status:', { attemptId, status });
    }
    return new Response('OK', { status: 200 });
  } catch (error) {
    console.error('PayHere notify error:', error);
    return new Response('Notification failed', { status: 500 });
  }
});
