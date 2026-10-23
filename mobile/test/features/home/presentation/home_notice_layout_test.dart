import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

import '../../../helpers.dart';
import '../../photo/presentation/photo_input_widget_test.dart'
    show FakePhotoRepository;

class _Speech implements SpeechService {
  _Speech(this.pending, {required this.fail});
  final Completer<String?> pending;
  final bool fail;

  @override
  Future<String?> listen() async {
    if (fail) {
      throw const SpeechException('Nie rozpoznano mowy. Spróbuj ponownie.');
    }
    return pending.future;
  }

  @override
  Future<void> cancel() async {
    if (!pending.isCompleted) pending.complete(null);
  }
}

void main() {
  for (final scale in [1.0, 2.5]) {
    for (final scenario in [
      'emptyPhoto',
      'cameraDenied',
      'photoFailure',
      'cameraUnavailable',
      'validation',
      'speechFailure',
      'listening',
      'playbackValidation',
      'success',
    ]) {
      testWidgets('$scenario stays above buttons at text scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(412, 892);
        addTearDown(tester.view.reset);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final pending = Completer<String?>();
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
                onSubmit: (_) async {},
                speechService: _Speech(
                  pending,
                  fail: scenario == 'speechFailure',
                ),
                photoRepository: scenario == 'cameraUnavailable'
                    ? null
                    : FakePhotoRepository(() async {
                        if (scenario == 'cameraDenied') {
                          throw const CameraPermissionDenied();
                        }
                        if (scenario == 'photoFailure') {
                          throw StateError('test failure');
                        }
                        return '   ';
                      }),
              ),
            ),
          ),
        );
        final mode = find.byKey(const Key('modeSwitch'));
        final buttonsBefore = tester.getRect(mode);
        final outerScroll = find
            .descendant(
              of: find.byType(SingleChildScrollView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        final extentBefore = tester
            .state<ScrollableState>(outerScroll)
            .position
            .maxScrollExtent;
        switch (scenario) {
          case 'emptyPhoto' ||
              'cameraDenied' ||
              'photoFailure' ||
              'cameraUnavailable':
            await tester.tap(find.byKey(const Key('cameraButton')));
          case 'validation':
            await tester.tap(find.text('Uprość'));
          case 'speechFailure' || 'listening':
            await tester.tap(find.byKey(const Key('microphoneButton')));
          case 'playbackValidation':
            await tester.tap(mode);
            await tester.pump();
            await tester.tap(find.byKey(const Key('speakerButton')));
          case 'success':
            controller.text = 'Tekst';
            await tester.pump();
            await submitText(tester);
        }
        await tester.pumpAndSettle();
        final message = switch (scenario) {
          'emptyPhoto' => 'Nie wykryto tekstu. Zrób wyraźniejsze zdjęcie.',
          'cameraDenied' => 'Brak dostępu do aparatu. Zezwól na dostęp w ustawieniach telefonu.',
          'photoFailure' => 'Nie udało się odczytać tekstu. Spróbuj ponownie.',
          'cameraUnavailable' => 'Aparat będzie dostępny wkrótce.',
          'speechFailure' => 'Nie rozpoznano mowy. Spróbuj ponownie.',
          'listening' => 'Nasłuchiwanie…',
          'success' => 'Tekst został przekazany do uproszczenia.',
          _ => 'Tekst nie może być pusty.',
        };
        expect(find.textContaining(message), findsOneWidget);
        final messages = find.byKey(const Key('editorMessages'));
        expect(
          find.descendant(of: messages, matching: find.textContaining(message)),
          findsOneWidget,
        );
        final panel = tester.getRect(messages);
        final field = tester.getRect(find.byType(TextField));
        expect(panel.left, field.left);
        expect(panel.top, field.bottom);
        expect(panel.bottom, lessThan(buttonsBefore.top));
        expect(tester.getRect(mode), buttonsBefore);
        expect(
          tester.state<ScrollableState>(outerScroll).position.maxScrollExtent,
          extentBefore,
        );
        expect(tester.takeException(), isNull);

        // Long notices remain readable without overflowing at keyboard height.
        tester.view.physicalSize = const Size(320, 280);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(TextField)).height, greaterThan(0));
        expect(tester.takeException(), isNull);
        if (scenario == 'listening') {
          await tester.ensureVisible(find.byKey(const Key('microphoneButton')));
          await tester.tap(find.byKey(const Key('microphoneButton')));
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
