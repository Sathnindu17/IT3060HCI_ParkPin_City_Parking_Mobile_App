-- ParkPin – database schema (run first)
-- IT3060 HCI · Group WE_46

-- ───────── Enum types ─────────
create type public.user_role      as enum ('driver', 'operator', 'authority');
create type public.bay_type       as enum ('standard', 'ev');
create type public.bay_status     as enum ('available', 'occupied', 'reserved');
create type public.booking_status as enum ('reserved', 'active', 'completed', 'cancelled', 'expired');
create type public.payment_method as enum ('card', 'wallet');
create type public.payment_status as enum ('paid', 'refunded');
create type public.report_status  as enum ('open', 'in_progress', 'resolved');

-- ───────── Profiles (one row per auth user) ─────────
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  phone       text,
  role        public.user_role not null default 'driver',
  facility_id uuid,                                   -- operators only
  created_at  timestamptz not null default now()
);

-- ───────── Parking facilities ─────────
create table public.parking_facilities (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  address           text,
  latitude          double precision not null,
  longitude         double precision not null,
  rate_per_hour     numeric(10, 2) not null check (rate_per_hour >= 0),
  reservation_fee   numeric(10, 2) not null default 50
                    check (reservation_fee between 0 and 100),   -- NFR4
  total_bays        int not null default 0,
  amenities         text[] not null default '{}',
  is_verified_legal boolean not null default true,
  operator_id       uuid references public.profiles (id) on delete set null,
  created_at        timestamptz not null default now()
);

alter table public.profiles
  add constraint profiles_facility_fk
  foreign key (facility_id) references public.parking_facilities (id) on delete set null;

-- ───────── Bays ─────────
create table public.bays (
  id          uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.parking_facilities (id) on delete cascade,
  label       text not null,                          -- e.g. B3
  level       text,
  type        public.bay_type   not null default 'standard',
  status      public.bay_status not null default 'available',
  updated_at  timestamptz not null default now(),
  unique (facility_id, label)
);

-- ───────── Bookings ─────────
create table public.bookings (
  id                  uuid primary key default gen_random_uuid(),
  driver_id           uuid not null references public.profiles (id) on delete cascade,
  facility_id         uuid not null references public.parking_facilities (id) on delete cascade,
  bay_id              uuid references public.bays (id) on delete set null,
  vehicle_number      text,
  start_time          timestamptz not null,
  end_time            timestamptz not null,
  status              public.booking_status not null default 'reserved',
  booking_code        text not null unique
                      default 'PP-' || upper(substr(md5(random()::text), 1, 6)),
  hidden_from_history boolean not null default false,
  created_at          timestamptz not null default now(),
  check (end_time > start_time)
);

-- One live booking per bay (stops double-booking – FR2 reliability)
create unique index bookings_one_live_per_bay
  on public.bookings (bay_id)
  where status in ('reserved', 'active');

-- ───────── Payments (simulated) ─────────
create table public.payments (
  id              uuid primary key default gen_random_uuid(),
  booking_id      uuid not null references public.bookings (id) on delete cascade,
  driver_id       uuid not null references public.profiles (id) on delete cascade,
  facility_id     uuid references public.parking_facilities (id) on delete set null,
  parking_fee     numeric(10, 2) not null,
  reservation_fee numeric(10, 2) not null default 0,
  total           numeric(10, 2) not null,
  method          public.payment_method not null default 'card',
  status          public.payment_status not null default 'paid',
  type            text not null default 'booking' check (type in ('booking', 'extension')),
  created_at      timestamptz not null default now()
);

-- ───────── Pricing rules (operator) ─────────
create table public.pricing_rules (
  id            uuid primary key default gen_random_uuid(),
  facility_id   uuid not null references public.parking_facilities (id) on delete cascade,
  label         text not null,
  rate_per_hour numeric(10, 2) not null check (rate_per_hour >= 0),
  start_hour    int not null check (start_hour between 0 and 23),
  end_hour      int not null check (end_hour between 0 and 23),
  days          int[] not null default '{0,1,2,3,4,5,6}',  -- 0 = Sunday
  is_off_peak   boolean not null default false,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- ───────── Illegal parking reports (authority) ─────────
create table public.illegal_parking_reports (
  id             uuid primary key default gen_random_uuid(),
  area           text not null,
  latitude       double precision,
  longitude      double precision,
  description    text,
  vehicle_number text,
  status         public.report_status not null default 'open',
  reported_by    uuid references public.profiles (id) on delete set null,
  resolved_at    timestamptz,
  created_at     timestamptz not null default now()
);

-- ───────── Legal parking zones (authority) ─────────
create table public.legal_parking_zones (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  area       text,
  latitude   double precision,
  longitude  double precision,
  capacity   int not null default 0,
  notes      text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

-- ───────── Notifications ─────────
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null,
  message    text not null,
  type       text not null default 'system'
             check (type in ('booking', 'reminder', 'payment', 'system')),
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

-- ───────── Helpful indexes ─────────
create index bays_facility_idx          on public.bays (facility_id);
create index bookings_driver_idx        on public.bookings (driver_id);
create index bookings_facility_idx      on public.bookings (facility_id);
create index payments_facility_idx      on public.payments (facility_id);
create index pricing_rules_facility_idx on public.pricing_rules (facility_id);
create index notifications_user_idx     on public.notifications (user_id);
