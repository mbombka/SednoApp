import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/home/presentation/editor_result_view_model.dart';

import '../../../helpers.dart';
import '../../simplification/presentation/result_flow_test.dart'
    show StubRepository, response;
import 'text_mode_test.dart' show Playback;

void main() {
  String text(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;
  final field = find.byType(TextField);

  Future<void> show(
    WidgetTester tester, {
    HistoryRepository? history,
    List<SimplificationRequest>? requests,
  }) => tester.pumpWidget(
    SednoApp(
      historyRepository: history,
      simplificationRepository: StubRepository((request) async {
        requests?.add(request);
        return response(request.requestId);
      }),
    ),
  );

  testWidgets(
    'next submission uses displayed edits; history retains each original',
    (tester) async {
      final requests = <SimplificationRequest>[];
      final history = MockHistoryRepository(
        clock: () => DateTime.utc(2026, 10, 14),
      );
      await show(tester, history: history, requests: requests);
      await tester.enterText(field, 'Pierwszy oryginał');
      await submitText(tester);
      await tester.pumpAndSettle();
      // This must send the new result, not the original cached by the input model.
      await submitText(tester);
      await tester.pumpAndSettle();
      expect(requests.last.input.value, 'To jest prosty tekst.');
      await tester.enterText(field, 'Edytowany wynik');
      await submitText(tester);
      await tester.pumpAndSettle();
      expect(requests.last.input.value, 'Edytowany wynik');
      await tester.tap(find.byKey(const Key('restoreOriginalButton')));
      await tester.pumpAndSettle();
      expect(text(tester), 'Edytowany wynik');
      final saved = await history.readAll();
      expect(
        saved.map((e) => e.original.value),
        containsAll([
          'Pierwszy oryginał',
          'To jest prosty tekst.',
          'Edytowany wynik',
        ]),
      );
    },
  );

  testWidgets(
    'eraser matches mode switch, clears result and prevents restoring old text',
    (tester) async {
      await show(tester);
      final clear = find.byKey(const Key('clearTextButton'));
      final mode = find.byKey(const Key('modeSwitch'));
      expect(tester.getSize(clear), tester.getSize(mode));
      expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
      expect(tester.getCenter(clear).dy, tester.getCenter(mode).dy);
      expect(
        tester.getCenter(clear).dx,
        greaterThan(tester.getCenter(mode).dx),
      );
      expect(find.byTooltip('Wyczyść tekst'), findsOneWidget);
      await tester.enterText(field, 'Oryginał');
      await submitText(tester);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(text(tester), isEmpty);
      expect(find.byKey(const Key('restoreOriginalButton')), findsNothing);
      expect(find.text('Sedno - uprość tekst:'), findsOneWidget);
    },
  );

  testWidgets('switching modes discards typed text and the previous result', (
    tester,
  ) async {
    await show(tester);
    await tester.enterText(field, 'Oryginał');
    await submitText(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    expect(text(tester), isEmpty);
    expect(find.text('Sedno - popraw tekst:'), findsOneWidget);
    expect(find.byKey(const Key('restoreOriginalButton')), findsNothing);
    await tester.enterText(field, 'Nowy tekst');
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    expect(text(tester), isEmpty);
  });

  testWidgets(
    'system back restores original before exiting; menu closes first',
    (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await show(tester);
      await tester.enterText(field, 'Oryginał');
      await submitText(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Menu użytkownika'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(text(tester), 'To jest prosty tekst.');
      expect(find.text('Uproszczony tekst'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(text(tester), 'Oryginał');
      expect(calls.where((c) => c.method == 'SystemNavigator.pop'), isEmpty);
      await tester.binding.handlePopRoute();
      expect(
        calls.where((c) => c.method == 'SystemNavigator.pop'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'pending resubmission disables restoring, erasing and switching',
    (tester) async {
      final next = Completer<SimplificationResponse>();
      var calls = 0;
      await tester.pumpWidget(
        SednoApp(
          simplificationRepository: StubRepository((request) async {
            if (calls++ == 0) return response(request.requestId);
            return next.future;
          }),
        ),
      );
      await tester.enterText(field, 'Oryginał');
      await submitText(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uprość'));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('restoreOriginalButton')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('clearTextButton')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('modeSwitch')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(text(tester), 'To jest prosty tekst.');
      next.complete(response('second'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clearing stops playback and resets an empty-input validation error',
    (tester) async {
      final controller = TextEditingController();
      final playback = Playback();
      final result = EditorResultViewModel();
      addTearDown(controller.dispose);
      addTearDown(result.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              appName: 'Sedno',
              textController: controller,
              playbackService: playback,
              editorResult: result,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('modeSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Popraw'));
      await tester.pumpAndSettle();
      expect(find.text('Tekst nie może być pusty.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clearTextButton')));
      await tester.pump();
      expect(find.text('Tekst nie może być pusty.'), findsNothing);
      await tester.enterText(field, 'Tekst do odczytu');
      await tester.tap(find.byKey(const Key('speakerButton')));
      await tester.pump();
      final stops = playback.stops;
      await tester.tap(find.byKey(const Key('clearTextButton')));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(playback.stops, greaterThan(stops));
      expect(find.byTooltip('Odczytaj tekst'), findsOneWidget);
    },
  );
}
