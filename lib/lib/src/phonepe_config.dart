import 'phonepe_env.dart';

/// Runtime configuration provided by the package user.
class PhonePeConfig {
  /// Choose SANDBOX or PRODUCTION.
  final PhonePeEnvironment environment;

  /// Merchant credentials (⚠️ keep live creds on server in production).
  final String merchantId;
  final String saltKey;
  final String saltIndex; // e.g. "1"

  /// Optional: extra headers to attach to HTTP calls.
  final Map<String, String> headers;

  /// Optional: enable verbose logging.
  final bool enableLogs;

  /// Optional: target app package (for UPI intent use-cases; not required here).
  final String packageName;

  /// Optional: custom flow/user id echoed back in the result.raw.
  final String flowId;

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

  bool get isSandbox => environment == PhonePeEnvironment.sandbox;
  bool get isProduction => environment == PhonePeEnvironment.production;
}
