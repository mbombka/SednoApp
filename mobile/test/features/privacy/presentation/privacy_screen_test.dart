import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

void main() {
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
