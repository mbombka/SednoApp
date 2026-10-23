import 'package:flutter_test/flutter_test.dart';

Future<void> submitText(WidgetTester tester) async {
  await tester.tap(find.text('Uprość'));
  await tester.pump();
  if (find.text('Rozumiem, wyślij').evaluate().isNotEmpty) {
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> navigateTo(
  WidgetTester tester,
  String destination, {
  String menuTooltip = 'Menu użytkownika',
}) async {
  await tester.tap(find.byTooltip(menuTooltip));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(destination).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(destination).last);
  await tester.pumpAndSettle();
}
