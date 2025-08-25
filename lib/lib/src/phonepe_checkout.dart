import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'checkout_webview.dart';
import 'phonepe_models.dart';

/// PhonePe checkout helper (server-first).
///
/// ⚠️ PhonePe merchant credentials (merchantId, saltKey, X-VERIFY, etc.)
/// are **secrets** and must never ship in the app. Your backend should:
///  - Create/initiate a transaction with PhonePe.
///  - Return a hosted `checkoutUrl` and your `referenceId`.
///  - Provide a status endpoint you control for verification.
///
/// This client wraps:
///  1) Opening the hosted `checkoutUrl` in a WebView.
///  2) Intercepting a custom deep link when the user returns.
///  3) (Optional) Polling *your server* for the final status.
class PhonePeCheckout {
  /// Opens an existing PhonePe hosted [checkoutUrl] and returns a result.
  ///
  /// Use this when your backend already created the payment session and
  /// can tell you the merchant [referenceId] (e.g. your order id).
  static Future<PhonePePaymentResult> openCheckoutUrl({
    required BuildContext context,
    required String checkoutUrl,
    required String returnDeepLink,
    required String referenceId,
    String?
    statusPollUrl, // your server status endpoint, e.g. https://api.example.com/payments/{ref}
    String? appBarTitle,
  }) async {
    // 1) Open checkout
    Uri? returnedUri;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutWebView(
          checkoutUrl: checkoutUrl,
          returnDeepLink: returnDeepLink,
          onReturn: (uri) => returnedUri = uri,
          appBarTitle: appBarTitle ?? 'PhonePe Checkout',
        ),
      ),
    );

    // 2) Optional: verify with your backend
    String finalStatus = 'PENDING';
    Map<String, dynamic> raw = {
      'returnUri': returnedUri?.toString(),
      'referenceId': referenceId,
    };

    if (statusPollUrl != null) {
      try {
        final res = await http.get(Uri.parse(statusPollUrl));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          finalStatus = (body['status'] ?? 'PENDING').toString();
          raw['verify'] = body;
        } else {
          raw['verifyError'] = 'HTTP ${res.statusCode} ${res.body}';
        }
      } catch (e) {
        raw['verifyException'] = e.toString();
      }
    }

    return PhonePePaymentResult(
      referenceId: referenceId,
      status: finalStatus,
      raw: raw,
    );
  }

  /// Convenience helper that asks *your backend* to create a checkout,
  /// then opens it and (optionally) polls for status.
  ///
  /// Your backend must expose [createCheckoutUrlEndpoint] that accepts a POST
  /// and returns JSON:
  /// ```json
  /// { "checkoutUrl": "...", "referenceId": "ORDER_123" }
  /// ```
  static Future<PhonePePaymentResult> startPaymentViaServer({
    required BuildContext context,
    required Uri createCheckoutUrlEndpoint,
    required String returnDeepLink,
    Map<String, dynamic>?
    createPayload, // what your backend needs (amount, currency, etc.)
    Uri? statusPollEndpoint, // e.g. https://api.example.com/payments/ORDER_123
    String? appBarTitle,
    Map<String, String>? headers, // auth headers for your backend, if any
  }) async {
    // 1) Ask your server to create a checkout session
    final res = await http.post(
      createCheckoutUrlEndpoint,
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: jsonEncode(createPayload ?? {}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw PhonePeCheckoutException(
        'Failed to create checkout: ${res.statusCode} ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final checkoutUrl = body['checkoutUrl'] as String?;
    final referenceId = (body['referenceId'] ?? body['orderId'])?.toString();

    if (checkoutUrl == null || referenceId == null) {
      throw PhonePeCheckoutException(
        'Invalid create response: missing checkoutUrl/referenceId',
      );
    }

    // 2) Open it

    final result = await openCheckoutUrl(
      context: context,
      checkoutUrl: checkoutUrl,
      returnDeepLink: returnDeepLink,
      referenceId: referenceId,
      statusPollUrl: statusPollEndpoint?.toString(),
      appBarTitle: appBarTitle,
    );

    return result;
  }
}
