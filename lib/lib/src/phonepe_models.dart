/// Payment result for PhonePe flows.
class PhonePePaymentResult {
  /// Your merchant transaction id used in the request.
  final String merchantTransactionId;

  /// Simplified status mapping: e.g. SUCCESS / PENDING / FAILED.
  final String status;

  /// Raw payloads captured during the flow (create/status/etc).
  final Map<String, dynamic> raw;

  const PhonePePaymentResult({
    required this.merchantTransactionId,
    required this.status,
    required this.raw,
  });

  /// True if [status] is SUCCESS (case-insensitive).
  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

/// Exception used by the PhonePe checkout helper.
class PhonePeCheckoutException implements Exception {
  final String message;
  final Object? cause;
  PhonePeCheckoutException(this.message, [this.cause]);
  @override
  String toString() => 'PhonePeCheckoutException: $message';
}
