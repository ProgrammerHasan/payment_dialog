import 'package:flutter_test/flutter_test.dart';

import '../example/main.dart';

void main() {
  testWidgets('PaymentDialog shows title and button', (WidgetTester tester) async {
    // Widget build
    await tester.pumpWidget(
      const MyApp(),
    );

    // Expect title text is visible
    expect(find.text('Pay Now'), findsOneWidget);

    // Expect a button (ধরি 'Confirm Payment' নামের)
    expect(find.text('Confirm Payment'), findsOneWidget);
  });
}
