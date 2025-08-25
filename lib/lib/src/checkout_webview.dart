import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Minimal WebView that loads [checkoutUrl] and intercepts [returnDeepLink].
class CheckoutWebView extends StatefulWidget {
  /// Hosted checkout URL returned by PhonePe (from `/pg/v1/pay`).
  final String checkoutUrl;

  /// Custom deep link you passed as `redirectUrl`, e.g. `myapp://payment-return`.
  final String returnDeepLink;

  /// Called when [returnDeepLink] is intercepted; sends the full [Uri].
  final ValueChanged<Uri> onReturn;

  /// Optional title for the AppBar.
  final String? appBarTitle;

  /// Creates a [CheckoutWebView].
  const CheckoutWebView({
    super.key,
    required this.checkoutUrl,
    required this.returnDeepLink,
    required this.onReturn,
    this.appBarTitle,
  });

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            if (req.url.startsWith(widget.returnDeepLink)) {
              widget.onReturn(Uri.parse(req.url));
              if (mounted) Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
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
