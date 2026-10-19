import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

void main() {
  testWidgets(
    'privacy contains controller, legal bases, retention and deployment status',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
      expect(
        find.textContaining('Administrator: Mariusz Bąbka'),
        findsOneWidget,
      );
      expect(find.textContaining('contact@sedno.xyz'), findsWidgets);
      expect(find.text('https://sedno.xyz'), findsOneWidget);
      expect(find.textContaining('nie oznacza braku retencji'), findsOneWidget);
      expect(find.textContaining('Infrastruktura Sedno'), findsOneWidget);
      expect(
        find.textContaining('płatności Google Play pozostają wyłączone'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Planowana infrastruktura produkcyjna'),
        findsNothing,
      );
      expect(find.text(PrivacyScreen.deletionNotice), findsOneWidget);
      expect(find.text('Cele i podstawy przetwarzania'), findsOneWidget);
      expect(find.text('Twoje prawa i kontakt'), findsOneWidget);
      expect(find.text('https://sedno.xyz/#prywatnosc'), findsOneWidget);
      expect(
        find.textContaining('Strona zawiera krótkie podsumowanie'),
        findsOneWidget,
      );
      expect(find.text('https://sedno.xyz/usun-konto'), findsOneWidget);
      expect(find.textContaining('DO UZUPEŁNIENIA'), findsNothing);
      expect(find.textContaining('DO POTWIERDZENIA'), findsNothing);
      expect(
        find.textContaining('Pozostałe magazyny, eksporty'),
        findsOneWidget,
      );
    },
  );

  testWidgets('provider and privacy notices remain readable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.5)),
          child: PrivacyScreen(),
        ),
      ),
    );
    expect(find.textContaining('dostawcy AI — OpenAI'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final deletion = find.text(PrivacyScreen.deletionNotice);
    await tester.scrollUntilVisible(
      deletion,
      200,
      maxScrolls: 250,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);
    // At 250% this paragraph is taller than the viewport; its center may be
    // outside the screen even though the first lines are visible.
    final paragraph = tester.getRect(deletion);
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    expect(paragraph.overlaps(viewport), isTrue);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });
}
