<h1 align="center">Payment Dialog.</h1>
<h4 align="center">A simple Flutter package for displaying customizable payment dialogs in your app.</h4>

<p align="center">
  <a href="https://pub.dartlang.org/packages/payment_dialog"><img src="https://img.shields.io/pub/v/payment_dialog.svg"></a>
</p>

<p align="center">
  <img src="https://github.com/programmerhasan/payment_dialog/raw/master/screenshots/01.png" alt="Payment dialog for Flutter" width="100" style="border-radius: 50%;" />
  <img src="https://github.com/programmerhasan/payment_dialog/raw/master/screenshots/02.png" alt="Payment dialog for Flutter" width="100" style="border-radius: 50%;" />
  <img src="https://github.com/programmerhasan/payment_dialog/raw/master/screenshots/03.png" alt="Payment dialog for Flutter" width="100" style="border-radius: 50%;" />
  <img src="https://github.com/programmerhasan/payment_dialog/raw/master/screenshots/04.png" alt="Payment dialog for Flutter" width="100" style="border-radius: 50%;" />
</p>


---

## Features

- Show a payment confirmation dialog.
- Customize title, message, and buttons.

---

## Quickstart

### Add dependency to your pubspec file

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  payment_dialog: ^1.0.0
```

### Add PaymentDialog to your app

```dart
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
```
