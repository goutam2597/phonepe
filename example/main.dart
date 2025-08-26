import 'package:flutter/material.dart';
import 'package:phone_pe/phone_pe.dart';

/// Deep link you’ll intercept inside the WebView + register on iOS/Android.
const kReturnDeepLink = 'myapp://payment-return';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhonePe Checkout Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'idle';
  bool _busy = false;

  // ✅ Publicly available SANDBOX credentials (for testing only)
  final _sandboxConfig = const PhonePeConfig(
    environment: PhonePeEnvironment.sandbox,
    merchantId: 'MarchantID',
    saltKey: 'Sanbox Key',
    saltIndex: '1',
    enableLogs: true,
    headers: {},
    packageName: 'com.phonepe.simulator',
    flowId: 'user123',
  );

  // 🔒 When you go live, replace these (and move signing to backend!)
  final _productionConfig = const PhonePeConfig(
    environment: PhonePeEnvironment.sandbox,
    merchantId: 'MarchantID',
    saltKey: 'Live Key',
    saltIndex: '1',
    enableLogs: true,
  );

  Future<void> _paySandbox() => _payWithConfig(_sandboxConfig);
  Future<void> _payProduction() => _payWithConfig(_productionConfig);

  Future<void> _payWithConfig(PhonePeConfig config) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'creating payment...';
    });

    try {
      final result = await PhonePeCheckout.startPayment(
        context: context,
        config: config,
        amountPaise: 10000, // ₹100.00
        returnDeepLink: kReturnDeepLink,
      );

      setState(
        () => _status = 'Txn ${result.merchantTransactionId}: ${result.status}',
      );
      if (!mounted) return;

      if (result.isSuccess) {
        _showSnack('Payment SUCCESS');
      } else {
        _showSnack('Payment ${result.status}');
      }
    } catch (e) {
      setState(() => _status = 'error: $e');
      _showSnack('Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PhonePe Checkout Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: _busy ? null : _paySandbox,
                child: const Text('Pay ₹100 (SANDBOX)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _payProduction,
                child: const Text('Pay ₹100 (PRODUCTION)'),
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Demo signs on device. Move signing to your backend for live.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
