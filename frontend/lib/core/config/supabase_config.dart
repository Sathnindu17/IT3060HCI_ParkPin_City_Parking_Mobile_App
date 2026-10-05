/// Supabase project keys (Project Settings → API Keys).
/// The anon/publishable key is safe in the app because RLS protects every table.
/// Never put the service_role / secret key here.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://meruhyuwtvenauhqpbnn.supabase.co';
  static const String publishableKey = 'sb_publishable_Nv9dnaNnXgOqsDgJdWAZXA_TlQIZdcr';
}