import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'checkout_webview.dart';
import 'phonepe_models.dart'; // <- brings in PhonePePaymentResult & PhonePeCheckoutException

/// ⚠️ INSECURE demo: keys in app (for sandbox tests only).
class PhonePeCheckout {
  static const String _base = 'https://api-preprod.phonepe.com/apis/pg-sandbox';
  static const String _merchantId = 'PGTESTPAYUAT86';
  static const String _saltKey = '96434309-7796-489d-8924-ab56988a6076';
  static const String _saltIndex = '1';

  /// Create payment → open WebView → verify status → return result.
  static Future<PhonePePaymentResult> startPayment({
    required BuildContext context,
    required int amountPaise,
    required String returnDeepLink,
    String? merchantUserId,
    String? merchantTransactionId,
    String? appBarTitle,
  }) async {
    final txnId =
        merchantTransactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';
    final userId =
        merchantUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'merchantId': _merchantId,
      'merchantTransactionId': txnId,
      'merchantUserId': userId,
      'amount': amountPaise,
      'redirectUrl': returnDeepLink,
      'redirectMode': 'GET',
      'callbackUrl': returnDeepLink,
      'paymentInstrument': {'type': 'PAY_PAGE'},
    };

    final base64Payload = base64.encode(utf8.encode(jsonEncode(payload)));

    String xVerifyForPay() {
      const path = '/pg/v1/pay';
      final toSign = base64Payload + path + _saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$_saltIndex';
    }

    final payRes = await http.post(
      Uri.parse('$_base/pg/v1/pay'),
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

    Uri? returned;
    if(context.mounted){
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

    String xVerifyForStatus() {
      final path = '/pg/v1/status/$_merchantId/$txnId';
      final toSign = path + _saltKey;
      final digest = sha256.convert(utf8.encode(toSign)).toString();
      return '$digest###$_saltIndex';
    }

    final statusRes = await http.get(
      Uri.parse('$_base/pg/v1/status/$_merchantId/$txnId'),
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': xVerifyForStatus(),
        'X-MERCHANT-ID': _merchantId,
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
