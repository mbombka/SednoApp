import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/home/presentation/editor_result_view_model.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';

void main() {
  for (final mode in TextMode.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${mode.name} result does not add page scrolling at text scale $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(412, 892);
          addTearDown(tester.view.reset);
          final controller = TextEditingController(text: 'Przykładowy tekst.');
          final result = EditorResultViewModel();
          addTearDown(controller.dispose);
          addTearDown(result.dispose);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: HomeScreen(
                  appName: 'Sedno',
                  textController: controller,
                  editorResult: result,
                ),
              ),
            ),
          );
          if (mode == TextMode.correct) {
            await tester.tap(find.byKey(const Key('modeSwitch')));
            await tester.pumpAndSettle();
          }
          final field = find.byType(TextField);
          final submit = find.byKey(const Key('simplifyButton'));
          final before = tester.getRect(field);
          final buttonBefore = tester.getRect(submit);
          final scroll = find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first;
          final scrollBefore = tester
              .state<ScrollableState>(scroll)
              .position
              .maxScrollExtent;
          if (scale == 1) expect(scrollBefore, 0);

          result.show(originalText: 'Oryginał', mode: mode);
          await tester.pumpAndSettle();

          final warning = find.byKey(const Key('aiErrorWarning'));
          final warningRect = tester.getRect(warning);
          final after = tester.getRect(field);
          expect(find.text('AI może się mylić'), findsOneWidget);
          expect(warningRect.left, after.left);
          expect(warningRect.top - after.bottom, closeTo(12, 0.01));
          expect(warningRect.bottom, lessThan(buttonBefore.top));
          expect(after.height, lessThan(before.height));
          expect(tester.getRect(submit), buttonBefore);
          expect(
            tester.state<ScrollableState>(scroll).position.maxScrollExtent,
            scrollBefore,
          );
          expect(tester.takeException(), isNull);

          result.clear();
          await tester.pumpAndSettle();
          expect(warning, findsNothing);
          expect(tester.getRect(field), before);

          // A short viewport (for example with the keyboard open) can still scroll.
          tester.view.physicalSize = const Size(412, 280);
          result.show(originalText: 'Oryginał', mode: mode);
          await tester.pumpAndSettle();
          expect(
            tester.state<ScrollableState>(scroll).position.maxScrollExtent,
            greaterThan(0),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
