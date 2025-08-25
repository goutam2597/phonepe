import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ReturnHandler = void Function(Uri uri);

/// Loads [checkoutUrl] and intercepts [returnUrl] (custom scheme or https).
class CheckoutWebView extends StatefulWidget {
  final String returnDeepLink;
  final String checkoutUrl;
  final String returnUrl; // e.g. myapp://payment-return
  final ReturnHandler onReturn;
  final String? appBarTitle;

  const CheckoutWebView({
    super.key,
    required this.checkoutUrl,
    required this.returnUrl,
    required this.returnDeepLink,
    required this.onReturn,
    this.appBarTitle,
  });

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  late final Uri _target;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _target = Uri.parse(widget.returnUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            if (req.url.startsWith(widget.returnDeepLink)) {
              widget.onReturn(Uri.parse(req.url)); // full URI (has status_id)
              if (mounted) Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isReturnUrl(Uri u) {
    final customMatch =
        (u.scheme == _target.scheme) && (u.host == _target.host);
    final httpsMatch =
        (u.scheme == 'https' &&
        _target.scheme == 'https' &&
        u.host == _target.host &&
        u.path == _target.path);
    final prefix = u.toString().startsWith(widget.returnUrl);
    return customMatch || httpsMatch || prefix;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle ?? 'PhonePe Checkout')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
