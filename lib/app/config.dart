/// Compile-time configuration for the optional cloud layer.
///
/// The app is offline-first: every value here defaults to empty/off, and no
/// feature may require any of them (hard rule — see CLAUDE.md). Supply values
/// at build time so one binary can point at any self-hosted API:
///
///   flutter build apk --dart-define=BECHAKENA_API_BASE_URL=https://pos.example.com
///   flutter build windows --dart-define=BECHAKENA_SUPABASE_URL=... \
///                         --dart-define=BECHAKENA_SUPABASE_ANON_KEY=...
///
/// See `.env.example` at the repository root for every variable.
abstract final class AppConfig {
  /// Base URL of the optional Cloud Plan API / Edge Functions host.
  static const String apiBaseUrl =
      String.fromEnvironment('BECHAKENA_API_BASE_URL');

  /// Supabase project URL used only by the optional sync/licensing layer.
  static const String supabaseUrl =
      String.fromEnvironment('BECHAKENA_SUPABASE_URL');

  /// Supabase anon key — a public client key; never the service-role key.
  static const String supabaseAnonKey =
      String.fromEnvironment('BECHAKENA_SUPABASE_ANON_KEY');

  /// Ed25519 public key used to verify offline license keys. Public by design;
  /// the matching private key never leaves the license server.
  static const String licensePublicKey =
      String.fromEnvironment('BECHAKENA_LICENSE_PUBLIC_KEY');

  /// Whether the optional Supabase Cloud Plan is configured for this build.
  static bool get cloudConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
