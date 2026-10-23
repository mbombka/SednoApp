import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';

import '../../../helpers.dart';

class Playback implements TextPlaybackService {
  String? text;
  int stops = 0;
  Completer<void>? done;
  @override
  Future<void> speak(String value) {
    text = value;
    return (done = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (done?.isCompleted == false) done!.complete();
  }
}

void main() {
  testWidgets('correction updates header, result and stored history mode', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final history = MockHistoryRepository(clock: () => now);
    await tester.pumpWidget(
      SednoApp(
        historyRepository: history,
        simplificationRepository: MockSimplificationRepository(
          quota: MockQuotaRepository(clock: () => now),
          clock: () => now,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    expect(find.text('Sedno - popraw tekst:'), findsOneWidget);
    expect(find.byKey(const Key('cameraButton')), findsNothing);
    expect(find.byKey(const Key('microphoneButton')), findsNothing);
    expect(find.byKey(const Key('speakerButton')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'Czy bendzie woda?');
    await tester.tap(find.text('Popraw'));
    await tester.pumpAndSettle();
    expect(find.text('Zanim poprawisz tekst'), findsOneWidget);
    expect(find.textContaining('aby go uprościć lub poprawić'), findsOneWidget);
    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pumpAndSettle();
    expect(find.text('Poprawiony tekst'), findsOneWidget);
    expect((await history.readAll()).single.result.mode, TextMode.correct);
    await tester.tap(find.byKey(const Key('clearTextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Popraw'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await navigateTo(tester, 'Historia');
    expect(find.text('Wersja poprawiona'), findsOneWidget);
    await navigateTo(tester, 'Start');
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    expect(find.text('Sedno - uprość tekst:'), findsOneWidget);
    expect(find.byKey(const Key('cameraButton')), findsOneWidget);
    expect(find.byKey(const Key('microphoneButton')), findsOneWidget);
  });

  testWidgets(
    'speaker reads editor, stops on mode change and inactive screen',
    (tester) async {
      final controller = TextEditingController(text: 'Polski tekst');
      final playback = Playback();
      addTearDown(controller.dispose);
      Future<void> show({bool active = true}) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              appName: 'Sedno',
              textController: controller,
              playbackService: playback,
              isActive: active,
            ),
          ),
        ),
      );
      await show();
      await tester.tap(find.byKey(const Key('modeSwitch')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Polski tekst');
      await tester.tap(find.byKey(const Key('speakerButton')));
      await tester.pump();
      expect(playback.text, 'Polski tekst');
      expect(find.byTooltip('Zatrzymaj odczyt'), findsOneWidget);
      await tester.tap(find.byKey(const Key('modeSwitch')));
      await tester.pumpAndSettle();
      expect(playback.stops, greaterThanOrEqualTo(2));
      expect(find.byKey(const Key('microphoneButton')), findsOneWidget);
      final stops = playback.stops;
      await show(active: false);
      await tester.pumpAndSettle();
      expect(playback.stops, greaterThan(stops));
      expect(tester.takeException(), isNull);
    },
  );
}
