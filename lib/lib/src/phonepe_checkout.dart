import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phone_pe/lib/src/phonepe_env.dart';

import 'checkout_webview.dart';
import 'phonepe_config.dart';
import 'phonepe_models.dart';

/// INSECURE on-device signing. Good for sandbox tests only.
/// In production, move signing to your backend.
class PhonePeCheckout {
  /// Create payment → open WebView → verify status → return result.
  static Future<PhonePePaymentResult> startPayment({
    required BuildContext context,
    required PhonePeConfig config,
    required int amountPaise, // ₹ * 100
    required String returnDeepLink, // e.g. myapp://payment-return
    String? merchantUserId,
    String? merchantTransactionId,
    String? appBarTitle,
  }) async {
    final base = config.environment.baseUrl;

    final txnId =
        merchantTransactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';
    final userId =
        merchantUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    if (config.enableLogs) {
      // ignore: avoid_print
      print(
        '[PhonePe] Env=${config.environment.label} Amount=$amountPaise Txn=$txnId',
      );
    }

    // 1) Build payload for /pg/v1/pay
    final payload = {
      'merchantId': config.merchantId,
      'merchantTransactionId': txnId,
      'merchantUserId': userId,
      'amount': amountPaise,
      'redirectUrl': returnDeepLink,
      'redirectMode': 'GET', // required for deep-link interception
      'callbackUrl': returnDeepLink, // sandbox ok; use server webhook in prod
      'paymentInstrument': {'type': 'PAY_PAGE'},
    };

    final jsonPayload = jsonEncode(payload);
    final base64Payload = base64.encode(utf8.encode(jsonPayload));

    String xVerifyForPay() {
      const path = '/pg/v1/pay';
      final toSign = base64Payload + path + config.saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###${config.saltIndex}';
    }

    // 2) Create payment
    final payRes = await http.post(
      Uri.parse('$base/pg/v1/pay'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': xVerifyForPay(),
        if (config.headers.isNotEmpty) ...config.headers,
      },
      body: jsonEncode({'request': base64Payload}),
    );

    if (config.enableLogs) {
      // ignore: avoid_print
      print('[PhonePe] /pay status=${payRes.statusCode} body=${payRes.body}');
    }

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

    String interimStatus = 'pending';
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutWebView(
            returnDeepLink: returnDeepLink,
            checkoutUrl: redirectUrl,
            onReturn: (uri) {
              final statusId = uri.queryParameters['status_id'];
              // 1=success, 2=pending, 3=failed
              if (statusId == '1') {
                interimStatus = 'success';
              } else if (statusId == '3') {
                interimStatus = 'failed';
              } else {
                interimStatus = 'pending';
              }
            },
            appBarTitle: appBarTitle ?? 'PhonePe Checkout',
          ),
        ),
      );
    }

    // 4) Verify via Status API
    String xVerifyForStatus() {
      final path = '/pg/v1/status/${config.merchantId}/$txnId';
      final toSign = path + config.saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###${config.saltIndex}';
    }

    final statusRes = await http.get(
      Uri.parse('$base/pg/v1/status/${config.merchantId}/$txnId'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': xVerifyForStatus(),
        'X-MERCHANT-ID': config.merchantId,
        if (config.headers.isNotEmpty) ...config.headers,
      },
    );

    if (config.enableLogs) {
      // ignore: avoid_print
      print(
        '[PhonePe] /status code=${statusRes.statusCode} body=${statusRes.body}',
      );
    }

    if (statusRes.statusCode != 200) {
      throw PhonePeCheckoutException(
        'Status check failed: ${statusRes.statusCode} ${statusRes.body}',
      );
    }

    final statusBody = jsonDecode(statusRes.body) as Map<String, dynamic>;
    final code = (statusBody['code'] ?? '').toString().toUpperCase();

    String finalStatus = interimStatus;
    if (code.contains('SUCCESS')) {
      finalStatus = 'SUCCESS';
    } else if (code.contains('ERROR') || code.contains('FAIL')) {
      finalStatus = 'FAILED';
    }

    return PhonePePaymentResult(
      merchantTransactionId: txnId,
      status: finalStatus,
      raw: {
        'flowId': config.flowId,
        'request': payload,
        'createResponse': payBody,

        'statusResponse': statusBody,
      },
    );
  }
}
