import 'package:flutter/material.dart';
import 'package:payment_dialog/payment_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final success = await showPaymentDialog(
                context: context,
                paymentUrl: 'https://yourpaymentgateway.com/start',
                succeededUrl: 'https://your-payment-website.com/success',
                failedUrl: 'https://your-payment-website.com/failed',
                cancelledUrl: 'https://your-payment-website.com/cancelled',
              );
              debugPrint(success ? "Payment Success" : "Payment Failed/Cancelled");
            },
            child: const Text("Pay Now"),
          ),
        ),
      ),
    );
  }
}
