import 'package:flutter/material.dart';
import 'package:phone_pe/lib/widgets/custom_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Callback signature used when the WebView navigates to the return deep link.
///
/// Implementations typically inspect the [Uri] for query parameters such as
/// transaction status, merchant reference, or error codes.
typedef ReturnHandler = void Function(Uri uri);

/// A widget that opens a [WebView] for a payment checkout flow.
///
/// It loads the given [checkoutUrl] and monitors navigation events. When the
/// page navigates to [returnDeepLink], the [onReturn] callback is invoked with
/// the full [Uri]. The widget then automatically pops itself from the
/// navigation stack.
///
/// This is commonly used for handling PhonePe (or other PSP) checkout flows
/// where the provider redirects back to your app via a deep link.
///
/// Example:
/// ```dart
/// await Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => CheckoutWebView(
///       checkoutUrl: 'https://example.com/pay',
///       returnDeepLink: 'myapp://payment-return',
///       onReturn: (uri) {
///         final status = uri.queryParameters['status'];
///         debugPrint('Returned with status: $status');
///       },
///     ),
///   ),
/// );
/// ```
class CheckoutWebView extends StatefulWidget {
  /// The deep link (custom scheme or https) that signals checkout completion.
  ///
  /// When the WebView navigates to a URL starting with this prefix,
  /// [onReturn] is invoked and the view is closed.
  final String returnDeepLink;

  /// The initial URL to load in the WebView for checkout.
  final String checkoutUrl;

  /// Called when [returnDeepLink] is reached. Receives the full return [Uri].
  final ValueChanged<Uri> onReturn;

  /// Optional title shown in the [CustomAppBar]. Defaults to `'PhonePe Checkout'`.
  final String? appBarTitle;

  /// Creates a new [CheckoutWebView].
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
      body: Column(
        children: [
          CustomAppBar(title: widget.appBarTitle ?? 'PhonePe Checkout'),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
