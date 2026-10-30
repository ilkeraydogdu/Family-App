class SupabaseConfig {
  static const String url = 'https://aaotejwujfipmgxiyoma.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhb3Rland1amZpcG1neGl5b21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMzMDM4ODEsImV4cCI6MjEwODg3OTg4MX0.0dC65up9-8ibGKvH12ZPNjfBiDE2_M5svtz4VaeWxzE';
  static const String publishableKey =
      'sb_publishable_zkNph2yuMt2UjJaYrql3WQ_TlNzoEjs';

  // Pre-seeded member handles (@username ecosystem — no email exposed in UI)
  static const String defaultHusbandUsername = 'ilker';
  static const String defaultWifeUsername = 'neslihan';
  static const String defaultHusbandEmail = 'ilker@familyapp.app';
  static const String defaultWifeEmail = 'esim@familyapp.app';
  static const String defaultCouplePassword = 'FamilyApp2026!';
  static const String defaultInviteCode = 'AYDOGDU26';

  static String normalizeUsernameHandle(String input) {
    final cleaned = input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'c')
        .replaceAll('ç', 'c')
        .toLowerCase()
        .replaceAll('@', '')
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'uye' : cleaned;
  }

  /// Maps a public `@username` handle to an internal Supabase Auth identity
  /// so users never have to enter or expose personal email addresses.
  static String usernameToInternalAuthIdentity(String usernameOrHandle) {
    final raw = usernameOrHandle.trim().toLowerCase();
    if (raw.contains('@') && !raw.startsWith('@')) {
      return raw;
    }
    final handle = normalizeUsernameHandle(raw);
    if (handle == 'ilker') return defaultHusbandEmail;
    if (handle == 'neslihan' || handle == 'esim') return defaultWifeEmail;
    return '$handle@familyapp.app';
  }
}
