   -- ParkPin – extra realtime tables (already applied in the Supabase dashboard)
   alter publication supabase_realtime add table public.bookings, public.notifications;