import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('Trip Wallet app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TripWalletApp());
    await tester.pumpAndSettle();

    expect(find.text('Trip Wallet'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
