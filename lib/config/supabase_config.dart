class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_SUPABASE_URL',
      defaultValue: 'https://nydvzmqmcldmbglplrxs.supabase.co',
    ),
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_B92GMI0F7qqcCJmCISN07g_ZT5iRQ1z',
    ),
  );

  static String get restUrl => '$url/rest/v1';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
