import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ReturnHandler = void Function(Uri uri);

/// Loads [checkoutUrl] and intercepts [returnUrl] (custom scheme or https).
class CheckoutWebView extends StatefulWidget {
  final String returnDeepLink;
  final String checkoutUrl;
  final ValueChanged<Uri> onReturn;
  final String? appBarTitle;

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
