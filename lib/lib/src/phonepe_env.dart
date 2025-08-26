/// Supported environments for PhonePe checkout flows.
///
/// Use [sandbox] while developing and testing with PhonePe’s UAT credentials.
/// Switch to [production] when going live with real transactions.
enum PhonePeEnvironment {
  /// Sandbox / pre-production environment.
  ///
  /// Use this environment for testing and integration.
  sandbox,

  /// Production environment.
  ///
  /// Use this environment only when going live. Requires valid production
  /// merchant credentials and server-side signing.
  production,
}

/// Convenience extensions for [PhonePeEnvironment].
extension PhonePeEnvironmentX on PhonePeEnvironment {
  /// Returns the base API URL for this environment.
  ///
  /// - Sandbox → `https://api-preprod.phonepe.com/apis/pg-sandbox`
  /// - Production → `https://api.phonepe.com/apis/hermes`
  String get baseUrl => switch (this) {
    PhonePeEnvironment.sandbox =>
    'https://api-preprod.phonepe.com/apis/pg-sandbox',
    PhonePeEnvironment.production =>
    'https://api.phonepe.com/apis/hermes',
  };

  /// A human-friendly label for the environment.
  ///
  /// - Sandbox → `'SANDBOX'`
  /// - Production → `'PRODUCTION'`
  String get label =>
      this == PhonePeEnvironment.sandbox ? 'SANDBOX' : 'PRODUCTION';
}
