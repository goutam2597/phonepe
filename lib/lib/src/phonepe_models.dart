/// Payment result returned from a PhonePe checkout flow.
///
/// This model wraps both a simplified [status] string and the full [raw]
/// response payloads captured during the transaction. It also provides a
/// convenience [isSuccess] getter.
///
/// Example:
/// ```dart
/// final result = await PhonePeCheckout.startPayment(...);
/// if (result.isSuccess) {
///   debugPrint('Payment successful: ${result.merchantTransactionId}');
/// } else {
///   debugPrint('Payment failed: ${result.status}');
/// }
/// ```
class PhonePePaymentResult {
  /// Creates a new [PhonePePaymentResult].
  ///
  /// - [merchantTransactionId] is the transaction ID you provided in the request.
  /// - [status] is a simplified string such as `"SUCCESS"`, `"PENDING"`,
  ///   or `"FAILED"`.
  /// - [raw] contains the full unmodified payloads (e.g. from `create` and
  ///   `status` API calls).
  const PhonePePaymentResult({
    required this.merchantTransactionId,
    required this.status,
    required this.raw,
  });

  /// The merchant transaction ID you passed when starting the checkout.
  final String merchantTransactionId;

  /// The simplified transaction status.
  ///
  /// Values are typically `"SUCCESS"`, `"PENDING"`, or `"FAILED"`.
  /// Note: this is a convenience mapping; consult [raw] for complete details.
  final String status;

  /// Raw payloads captured during the flow (create/status/etc).
  ///
  /// This provides full access to the provider responses, useful for auditing
  /// or debugging.
  final Map<String, dynamic> raw;

  /// Returns `true` if the [status] equals `"SUCCESS"` (case-insensitive).
  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
}

/// Exception thrown by the PhonePe checkout helper.
///
/// Wraps a descriptive [message] and an optional [cause]. This is typically
/// thrown if the helper cannot complete the flow due to networking errors,
/// invalid responses, or unexpected states.
///
/// Example:
/// ```dart
/// try {
///   await PhonePeCheckout.startPayment(...);
/// } on PhonePeCheckoutException catch (e) {
///   debugPrint('Checkout failed: $e');
/// }
/// ```
class PhonePeCheckoutException implements Exception {
  /// Creates a [PhonePeCheckoutException] with a [message] and optional [cause].
  PhonePeCheckoutException(this.message, [this.cause]);

  /// A human-readable description of the error.
  final String message;

  /// The underlying cause of the error, if available.
  ///
  /// This may be an [Exception], a raw response map, or any other object
  /// describing the failure.
  final Object? cause;

  @override
  String toString() => 'PhonePeCheckoutException: $message';
}
