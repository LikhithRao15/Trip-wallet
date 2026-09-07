import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('Trip Wallet app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TripWalletApp());

    expect(find.text('Trip Wallet'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
