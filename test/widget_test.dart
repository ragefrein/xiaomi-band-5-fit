// Smoke test dasar untuk app ragefit (Kinetix).
import 'package:flutter_test/flutter_test.dart';

import 'package:ragefit/main.dart';

void main() {
  testWidgets('App Kinetix bisa dibangun tanpa error', (WidgetTester tester) async {
    await tester.pumpWidget(const KinetixApp());
    await tester.pump();

    // Bottom navigation harus tampil dengan 4 tab.
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Langkah'), findsWidgets);
    expect(find.text('Tidur'), findsOneWidget);
    expect(find.text('Jantung'), findsOneWidget);
  });
}
