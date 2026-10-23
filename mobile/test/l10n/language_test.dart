import 'dart:convert';
import 'dart:io';

import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';
import 'package:sedno_app/l10n/app_localizations_en.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';
import 'package:sedno_app/features/simplification/presentation/simplification_view_model.dart';
import 'package:sedno_app/features/speech/data/android_speech_service.dart';
import 'package:sedno_app/features/speech_output/data/android_text_playback_service.dart';

import '../features/simplification/presentation/simplification_view_model_test.dart'
    as fakes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalogues have identical messages and placeholders', () {
    final polish = jsonDecode(
      File('lib/l10n/app_pl.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final english = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = polish.keys.where((key) => !key.startsWith('@')).toSet();
    expect(english.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    for (final key in keys) {
      expect((english[key] as String).trim(), isNotEmpty, reason: key);
      expect(
        english['@$key'],
        polish['@$key'],
        reason: 'Placeholders for $key',
      );
    }
  });

  test(
    'validation messages follow the language without changing text',
    () async {
      final model = TextInputViewModel(onSubmit: (_) async {});
      addTearDown(model.dispose);
      model.setText('x' * 4001);
      model.updateLocalizations(AppLocalizationsEn());
      expect(model.characterCount, 4001);
      expect(model.errorMessage, 'Text can have up to 4000 characters.');
      model.setText('   ');
      await model.submit();
      expect(model.errorMessage, 'Text cannot be empty.');
    },
  );

  test('an old backend cannot silently return Polish for English', () async {
    final model = SimplificationViewModel(
      repository: fakes.FakeSimplificationRepository(
        (_) async => fakes.response('legacy'),
      ),
    );
    await expectLater(
      model.simplify(InputText('Text'), language: AppLanguage.english),
      throwsFormatException,
    );
  });

  test('device preferences, unsupported fallback and saved override', () async {
    expect(AppLanguage.resolve(const ['de', 'en']), AppLanguage.english);
    expect(AppLanguage.resolve(const ['de']), AppLanguage.polish);
    String? saved = 'en';
    final controller = LanguageController(
      deviceLocales: const [Locale('pl')],
      read: () async => saved,
      write: (value) async => saved = value,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.language, AppLanguage.english);
    await controller.select(null);
    expect(saved, isNull);
    expect(controller.language, AppLanguage.polish);
    controller.didChangeLocales(const [Locale('en', 'GB')]);
    expect(controller.language, AppLanguage.english);
  });

  test('failed preference write preserves the selected language', () async {
    final controller = LanguageController(
      deviceLocales: const [Locale('pl')],
      write: (_) async => throw StateError('storage unavailable'),
    );
    addTearDown(controller.dispose);
    await expectLater(controller.select(AppLanguage.english), throwsStateError);
    expect(controller.language, AppLanguage.polish);
  });

  test('language changes create a new request id; retries keep it', () async {
    final requests = <SimplificationRequest>[];
    var serial = 0;
    final model = SimplificationViewModel(
      newRequestId: () => 'language-${++serial}',
      repository: fakes.FakeSimplificationRepository((request) async {
        requests.add(request);
        throw TimeoutException('synthetic');
      }),
    );
    for (final language in [
      AppLanguage.polish,
      AppLanguage.english,
      AppLanguage.english,
    ]) {
      await expectLater(
        model.simplify(InputText('Text'), language: language),
        throwsA(isA<TimeoutException>()),
      );
    }
    expect(requests.map((request) => request.requestId), [
      'language-1',
      'language-2',
      'language-2',
    ]);
    expect(requests.last.toJson()['language'], 'en');
    expect(requests.first.toJson().containsKey('language'), isFalse);
  });

  test('old history defaults to Polish and English metadata round trips', () {
    final old = fakes.response('old').result;
    expect(
      SimplificationResult.fromJson(old.toJson()).language,
      AppLanguage.polish,
    );
    final english = SimplificationResult(
      id: 'en',
      text: 'Text',
      createdAt: DateTime.utc(2026),
      language: AppLanguage.english,
    );
    expect(
      SimplificationResult.fromJson(english.toJson()).language,
      AppLanguage.english,
    );
  });

  test('native speech and playback receive the selected language', () async {
    final calls = <MethodCall>[];
    for (final name in ['sedno/speech', 'sedno/text-playback']) {
      final channel = MethodChannel(name);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'listen' ? 'Hello' : null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
    }
    await AndroidSpeechService(language: () => AppLanguage.english).listen();
    await AndroidTextPlaybackService(language: () => AppLanguage.english)
        .speak('Hello');
    expect(calls[0].arguments, {'language': 'en-GB'});
    expect(calls[1].arguments, {'text': 'Hello', 'language': 'en-GB'});
  });

  testWidgets(
    'English interface includes validation, menu, account and privacy',
    (tester) async {
      final controller = LanguageController(
        deviceLocales: const [Locale('en', 'GB')],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(SednoApp(languageController: controller));
      await tester.pumpAndSettle();
      expect(find.text('Simplify'), findsOneWidget);
      await tester.tap(find.text('Simplify'));
      await tester.pumpAndSettle();
      expect(find.text('Text cannot be empty.'), findsOneWidget);
      await tester.tap(find.byTooltip('User menu'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Privacy and data'), 150);
      await tester.tap(find.text('Privacy and data'));
      await tester.pumpAndSettle();
      expect(find.text('Controller and contact'), findsOneWidget);
      expect(find.textContaining('Your text will be sent'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Account options will appear here.'), findsOneWidget);
    },
  );

  testWidgets(
    'language picker switches existing screens and preserves editor text',
    (tester) async {
      final controller = LanguageController(
        deviceLocales: const [Locale('pl')],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(SednoApp(languageController: controller));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep this text');
      await tester.tap(find.byTooltip('Menu użytkownika'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Język'));
      await tester.tap(find.text('Język'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-en')));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Simplify'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep this text',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
