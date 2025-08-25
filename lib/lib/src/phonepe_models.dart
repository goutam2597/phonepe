/// Result of a PhonePe checkout flow.
class PhonePePaymentResult {
  /// Merchant-side reference for the transaction (e.g. order id).
  final String referenceId;

  /// Final status mapped by your backend (e.g. `SUCCESS`, `PENDING`, `FAILED`).
  final String status;

  /// Any raw payload captured/returned by your backend.
  final Map<String, dynamic> raw;

  /// Creates an immutable [PhonePePaymentResult].
  const PhonePePaymentResult({
    required this.referenceId,
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

  /// Optional root cause.
  final Object? cause;

  /// Creates a [PhonePeCheckoutException].
  PhonePeCheckoutException(this.message, [this.cause]);

  @override
  String toString() => 'PhonePeCheckoutException: $message';
}
