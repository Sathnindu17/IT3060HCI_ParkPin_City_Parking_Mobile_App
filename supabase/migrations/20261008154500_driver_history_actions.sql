begin;

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
  current_driver uuid;
  current_booking public.bookings%rowtype;
begin
  current_driver := auth.uid();

  if current_driver is null then
    raise exception 'Please sign in to manage your booking history.';
  end if;

  if p_hidden is null then
    raise exception 'Choose whether to hide or restore the booking.';
  end if;

  select *
  into current_booking
  from public.bookings
  where id = p_booking_id
    and driver_id = current_driver
  for update;

  if not found then
    raise exception 'Booking not found.';
  end if;

  if current_booking.status not in (
    'completed',
    'cancelled',
    'expired'
  ) then
    raise exception
      'Only completed, cancelled or expired bookings can be hidden.';
  end if;

  update public.bookings
  set hidden_from_history = p_hidden
  where id = current_booking.id;
end;
$$;

revoke all on function
  public.driver_set_booking_history_visibility(uuid, boolean)
from public, anon;

grant execute on function
  public.driver_set_booking_history_visibility(uuid, boolean)
to authenticated;

commit;

select to_regprocedure(
  'public.driver_set_booking_history_visibility(uuid,boolean)'
) as history_action_function;