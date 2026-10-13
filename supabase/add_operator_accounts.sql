-- ParkPin – one operator account for each car park.
-- Each operator only sees the bookings of their own car park (RLS), so a
-- driver booking at Galle Face is handled by the Galle Face operator.
--
-- Run this file in the Supabase SQL editor. Safe to run again.
-- For every car park that has no operator yet it creates a confirmed login:
--   email:    operator.<car park name, letters only>@parkpin.lk
--             e.g. Galle Face Parking (Demo) -> operator.gallefaceparking@parkpin.lk
--   password: Password123
-- The last query lists every car park with its operator email.

do $$
declare
  f record;
  v_email text;
  v_name text;
  v_uid uuid;
begin
  for f in
    select id, name from public.parking_facilities where operator_id is null
  loop
    v_name := trim(replace(f.name, '(Demo)', ''));
    v_email := 'operator.' || lower(regexp_replace(v_name, '[^a-zA-Z]', '', 'g')) || '@parkpin.lk';

    select id into v_uid from auth.users where email = v_email;

    if v_uid is null then
      v_uid := gen_random_uuid();

      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new
      ) values (
        '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
        v_email, extensions.crypt('Password123', extensions.gen_salt('bf')),
        now(), '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', v_name || ' Operator'),
        now(), now(),
        '', '', '', ''
      );

      insert into auth.identities (
        id, user_id, provider_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), v_uid, v_uid::text,
        jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true),
        'email', now(), now(), now()
      );
    end if;

    -- profile row is created by the handle_new_user trigger
    update public.profiles
    set full_name = v_name || ' Operator',
        role = 'operator',
        facility_id = f.id
    where id = v_uid;

    update public.parking_facilities
    set operator_id = v_uid
    where id = f.id;
  end loop;
end $$;

-- Check: every car park and its operator.
select f.name as car_park, u.email as operator
from public.parking_facilities f
left join public.profiles p on p.role = 'operator' and p.facility_id = f.id
left join auth.users u on u.id = p.id
order by f.name;
