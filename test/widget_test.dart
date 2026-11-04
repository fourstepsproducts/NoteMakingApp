import 'package:flutter_test/flutter_test.dart';
import 'package:qr_registration_app/main.dart';

void main() {
  testWidgets('App launches successfully test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QrRegistrationApp());

    // Verify app title appears
    expect(find.text('QR Registration App'), findsOneWidget);
  });
}
