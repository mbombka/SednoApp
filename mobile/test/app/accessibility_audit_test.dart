import 'package:flutter/material.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';

import '../helpers.dart';

void main() {
  for (final mode in TextMode.values) {
    for (final scale in [1.0, 2.5]) {
      testWidgets(
        'main flow meets Android accessibility guidelines at $scale in ${mode.name}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view.physicalSize = const Size(412, 892);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final now = DateTime.utc(2026, 10, 16);
          final history = MockHistoryRepository(clock: () => now);
          final quota = MockQuotaRepository(clock: () => now);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SednoApp(
                historyRepository: history,
                simplificationRepository: MockSimplificationRepository(
                  quota: quota,
                  clock: () => now,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<void> audit() async {
            expect(tester.takeException(), isNull);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }

          if (mode == TextMode.correct) {
            await tester.tap(find.byKey(const Key('modeSwitch')));
            await tester.pumpAndSettle();
          }
          await audit();
          await tester.enterText(
            find.byType(TextField),
            'Tekst do uproszczenia.',
          );
          tester.testTextInput.hide();
          await tester.tap(find.byKey(const Key('simplifyButton')));
          await tester.pumpAndSettle();
          await audit(); // First-submission AI processing notice.
          await tester.tap(find.text('Rozumiem, wyślij'));
          await tester.pumpAndSettle();
          await audit(); // Result and its actions.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await navigateTo(tester, 'Historia');
          await audit(); // Retained local entry and delete action.
          await navigateTo(tester, 'Konto');
          await audit();
          semantics.dispose();
        },
      );
    }
  }
}
