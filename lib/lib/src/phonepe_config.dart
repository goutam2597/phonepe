import 'phonepe_env.dart';

/// Runtime configuration for the PhonePe checkout flow.
///
/// This class is provided by the package user when calling
/// [PhonePeCheckout.startPayment]. It encapsulates environment selection,
/// merchant credentials, and optional flags such as logging and headers.
///
/// Example (sandbox):
/// ```dart
/// final config = PhonePeConfig(
///   environment: PhonePeEnvironment.sandbox,
///   merchantId: 'PGTESTPAYUAT86',
///   saltKey: '96434309-7796-489d-8924-ab56988a6076',
///   saltIndex: '1',
///   enableLogs: true,
/// );
/// ```
class PhonePeConfig {
  /// Creates a new [PhonePeConfig].
  ///
  /// - [environment] must be set to either [PhonePeEnvironment.sandbox]
  ///   or [PhonePeEnvironment.production].
  /// - [merchantId], [saltKey], and [saltIndex] must be provided as
  ///   part of your credentials.
  /// - Optional values such as [headers], [enableLogs], [packageName], and
  ///   [flowId] can be used to customize the behavior.
  const PhonePeConfig({
    required this.environment,
    required this.merchantId,
    required this.saltKey,
    required this.saltIndex,
    this.headers = const {},
    this.enableLogs = true,
    this.packageName = 'com.phonepe.simulator',
    this.flowId = '',
  });

  /// The environment to use: [PhonePeEnvironment.sandbox] or
  /// [PhonePeEnvironment.production].
  final PhonePeEnvironment environment;

  /// The merchant identifier issued by PhonePe.
  ///
  /// ⚠️ **Important:** Never embed live merchant credentials directly in
  /// your mobile app. For production, keep them on a secure backend server.
  final String merchantId;

  /// The salt key used for signing requests.
  ///
  /// ⚠️ **Important:** Keep this on the server in production.
  final String saltKey;

  /// The salt index (for example, `"1"`).
  final String saltIndex;

  /// Extra HTTP headers to attach to API calls.
  ///
  /// Defaults to an empty map.
  final Map<String, String> headers;

  /// Whether verbose logging should be enabled.
  ///
  /// Defaults to `true`. It is recommended to set this to `false`
  /// in production builds.
  final bool enableLogs;

  /// Target app package for UPI intent use-cases.
  ///
  /// Not required for basic flows. Defaults to `'com.phonepe.simulator'`.
  final String packageName;

  /// Custom flow or user identifier.
  ///
  /// This value will be echoed back in `result.raw` to help with
  /// correlation in your systems. Defaults to an empty string.
  final String flowId;

  /// Returns `true` if [environment] is [PhonePeEnvironment.sandbox].
  bool get isSandbox => environment == PhonePeEnvironment.sandbox;

  /// Returns `true` if [environment] is [PhonePeEnvironment.production].
  bool get isProduction => environment == PhonePeEnvironment.production;
}
