import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'checkout_webview.dart';
import 'phonepe_models.dart'; // <- brings in PhonePePaymentResult & PhonePeCheckoutException

/// Environment switch for PhonePe
enum PhonePeEnv { sandbox, live }

extension _EnvX on PhonePeEnv {
  String get base => this == PhonePeEnv.sandbox
      ? 'https://api-preprod.phonepe.com/apis/pg-sandbox'
      : 'https://api.phonepe.com/apis/hermes';
}

/// INSECURE helper for PhonePe (keys in app). Use only for sandbox tests.
class PhonePeCheckout {
  /// Create payment → open WebView → verify status → return result.
  static Future<PhonePePaymentResult> startPayment({
    required BuildContext context,
    required PhonePeEnv env,
    required String merchantId,
    required String saltKey,
    required String saltIndex,
    required int amountPaise, // ₹ * 100
    required String returnDeepLink, // e.g. myapp://payment-return
    String? merchantUserId,
    String? merchantTransactionId,
    String? appBarTitle,
  }) async {
    final base = env.base;
    final txnId =
        merchantTransactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';
    final userId =
        merchantUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    // 1) Build payload for /pg/v1/pay
    final payload = {
      'merchantId': merchantId,
      'merchantTransactionId': txnId,
      'merchantUserId': userId,
      'amount': amountPaise,
      'redirectUrl': returnDeepLink,
      'redirectMode': 'GET', // must be GET for deep link interception
      'callbackUrl':
          returnDeepLink, // sandbox ok; prod should be server webhook
      'paymentInstrument': {'type': 'PAY_PAGE'},
    };

    final jsonPayload = jsonEncode(payload);
    final base64Payload = base64.encode(utf8.encode(jsonPayload));

    String xVerifyForPay() {
      const path = '/pg/v1/pay';
      final toSign = base64Payload + path + saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$saltIndex';
    }

    // 2) Create payment
    final payRes = await http.post(
      Uri.parse('$base/pg/v1/pay'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': xVerifyForPay(),
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

    // 3) Open WebView and intercept the deep link
    Uri? returned;
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutWebView(
            checkoutUrl: redirectUrl,
            returnUrl: returnDeepLink,
            onReturn: (uri) => returned = uri,
            appBarTitle: appBarTitle ?? 'PhonePe Checkout',
          ),
        ),
      );
    }

    // 4) Verify via Status API
    String xVerifyForStatus() {
      final path = '/pg/v1/status/$merchantId/$txnId';
      final toSign = path + saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$saltIndex';
    }

    final statusRes = await http.get(
      Uri.parse('$base/pg/v1/status/$merchantId/$txnId'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': xVerifyForStatus(),
        'X-MERCHANT-ID': merchantId,
      },
    );

    if (statusRes.statusCode != 200) {
      throw PhonePeCheckoutException(
        'Status check failed: ${statusRes.statusCode} ${statusRes.body}',
      );
    }

    final statusBody = jsonDecode(statusRes.body) as Map<String, dynamic>;
    final code = (statusBody['code'] ?? '').toString().toUpperCase();

    String finalStatus = 'PENDING';
    if (code.contains('SUCCESS')) {
      finalStatus = 'SUCCESS';
    } else if (code.contains('ERROR') || code.contains('FAIL')) {
      finalStatus = 'FAILED';
    }

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
