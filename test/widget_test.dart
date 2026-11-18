// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sistem_pinjam_alat/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SipelaApp(isLoggedIn: false));
    expect(find.text('SIPELA'), findsOneWidget);
  });
}
