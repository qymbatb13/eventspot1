/// Runtime configuration pulled from `--dart-define` flags so no secret
/// ever gets committed to the repo.
///
/// Run with real Ticketmaster events:
///   flutter run --dart-define=TICKETMASTER_API_KEY=your_key_here
///
/// Without a key the app automatically falls back to generated demo
/// events. To force demo data even when a key is present:
///   flutter run --dart-define=USE_MOCK_DATA=true
class AppConfig {
  const AppConfig._();

  static const String ticketmasterApiKey = String.fromEnvironment(
    'TICKETMASTER_API_KEY',
  );

  static const bool forceMockData = bool.fromEnvironment('USE_MOCK_DATA');

  static bool get hasApiKey => ticketmasterApiKey.isNotEmpty;

  /// Demo data is used when forced by a flag or when there is no key.
  static bool get useMockData => forceMockData || !hasApiKey;
}
