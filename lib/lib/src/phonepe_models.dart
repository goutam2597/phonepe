/// Result of a PhonePe checkout flow.
class PhonePePaymentResult {
  /// Your chosen merchant transaction ID sent to PhonePe.
  final String merchantTransactionId;

  /// Final status derived from the Status API, e.g. `SUCCESS`, `PENDING`, `FAILED`.
  final String status;

  /// Raw payloads captured (create + verify responses).
  final Map<String, dynamic> raw;

  /// Creates an immutable [PhonePePaymentResult].
  const PhonePePaymentResult({
    required this.merchantTransactionId,
    required this.status,
    required this.raw,
  });

  /// Convenience flag: `true` if [status] equals `"SUCCESS"`.
  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

/// Exception thrown for PhonePe checkout errors.
class PhonePeCheckoutException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional cause.
  final Object? cause;

  /// Creates a [PhonePeCheckoutException].
  PhonePeCheckoutException(this.message, [this.cause]);

  @override
  String toString() => 'PhonePeCheckoutException: $message';
}
