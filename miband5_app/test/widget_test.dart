import 'package:flutter_test/flutter_test.dart';
import 'package:miband5_app/main.dart';

void main() {
  testWidgets('App builds and shows the connect button', (tester) async {
    await tester.pumpWidget(const MiBandApp());
    expect(find.text('Connect & Authenticate'), findsOneWidget);
  });
}
