import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'checkout_webview.dart';
import 'phonepe_models.dart';

/// **INSECURE** PhonePe checkout helper for sandbox testing only.
/// Embeds merchant secrets in the app; anyone can extract them.
/// Do not use in production.
///
/// Flow:
/// 1) Build payload for `/pg/v1/pay` and compute `X-VERIFY = SHA256(base64(payload) + "/pg/v1/pay" + SALT_KEY) + "###" + SALT_INDEX`.
/// 2) POST to `https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay`.
/// 3) Open `redirectInfo.url` in WebView; set `redirectMode: "GET"` and `redirectUrl` as your deep link.
/// 4) After return, call Status API: `/pg/v1/status/{merchantId}/{merchantTransactionId}` with `X-VERIFY = SHA256("/pg/v1/status/{merchantId}/{merchantTransactionId}" + SALT_KEY) + "###" + SALT_INDEX`.
class PhonePeInsecureCheckout {
  /// Creates a payment, opens the hosted pay page, verifies status, and returns the result.
  ///
  /// - [merchantId] sandbox MID (e.g., `"PGTESTPAYUAT"`).
  /// - [saltKey] sandbox salt key (e.g., `"099eb0cd-02cf-4e2a-8aca-3e6c6aff0399"`).
  /// - [saltIndex] typically `"1"` for sandbox.
  /// - [amountPaise] is amount in paise (e.g., `10000` = ₹100.00).
  /// - [returnDeepLink] must match what you pass in `redirectUrl`.
  /// - [merchantTransactionId] if omitted, a timestamp-based ID is generated.
  static Future<PhonePePaymentResult> startPayment({
    required BuildContext context,
    required String merchantId,
    required String saltKey,
    required String saltIndex,
    required int amountPaise,
    required String returnDeepLink,
    String base = 'https://api-preprod.phonepe.com/apis/pg-sandbox',
    String? merchantTransactionId,
    String? appBarTitle,
  }) async {
    // 1) Build payload
    final txnId =
        merchantTransactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'merchantId': merchantId,
      'merchantTransactionId': txnId,
      'merchantUserId': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amountPaise, // paise (₹ * 100)
      'redirectUrl': returnDeepLink, // deep link back into app
      'redirectMode': 'GET', // use GET for deep link interception
      'callbackUrl': returnDeepLink, // sandbox ok; in prod use server webhook
      'paymentInstrument': {'type': 'PAY_PAGE'},
    };

    final jsonPayload = jsonEncode(payload);
    final base64Payload = base64.encode(utf8.encode(jsonPayload));

    String _xVerifyForPay() {
      const path = '/pg/v1/pay';
      final toSign = base64Payload + path + saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$saltIndex';
    }

    // 2) Call /pg/v1/pay
    final payRes = await http.post(
      Uri.parse('$base/pg/v1/pay'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': _xVerifyForPay(),
        // 'X-MERCHANT-ID': merchantId, // optional
      },
      body: jsonEncode({'request': base64Payload}),
    );

    if (payRes.statusCode != 200 && payRes.statusCode != 201) {
      throw PhonePeCheckoutException(
        'Create payment failed: ${payRes.statusCode} ${payRes.body}',
      );
    }

    final payBody = jsonDecode(payRes.body) as Map<String, dynamic>;
    final redirectUrl =
        payBody['data']?['instrumentResponse']?['redirectInfo']?['url']
            as String?;
    if (redirectUrl == null) {
      throw PhonePeCheckoutException('Missing redirect URL in create response');
    }

    // 3) Open WebView and wait for deep-link return
    Uri? returned;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutWebView(
          checkoutUrl: redirectUrl,
          returnDeepLink: returnDeepLink,
          onReturn: (uri) => returned = uri,
          appBarTitle: appBarTitle ?? 'PhonePe Checkout',
        ),
      ),
    );

    // 4) Verify via Status API
    String _xVerifyForStatus() {
      final path = '/pg/v1/status/$merchantId/$txnId';
      final toSign = path + saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$saltIndex';
    }

    final statusRes = await http.get(
      Uri.parse('$base/pg/v1/status/$merchantId/$txnId'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': _xVerifyForStatus(),
        'X-MERCHANT-ID': merchantId,
      },
    );

    if (statusRes.statusCode != 200) {
      throw PhonePeCheckoutException(
        'Status check failed: ${statusRes.statusCode} ${statusRes.body}',
      );
    }

    final statusBody = jsonDecode(statusRes.body) as Map<String, dynamic>;

    // Map a simple final status
    // Common patterns: code = PAYMENT_SUCCESS / PAYMENT_PENDING / PAYMENT_ERROR
    final code = (statusBody['code'] ?? '').toString().toUpperCase();
    String finalStatus = 'PENDING';
    if (code.contains('SUCCESS'))
      finalStatus = 'SUCCESS';
    else if (code.contains('ERROR') || code.contains('FAILED'))
      finalStatus = 'FAILED';

    return PhonePePaymentResult(
      merchantTransactionId: txnId,
      status: finalStatus,
      raw: {
        'request': payload,
        'createResponse': payBody,
        'returnUri': returned?.toString(),
        'statusResponse': statusBody,
      },
    );
  }
}
