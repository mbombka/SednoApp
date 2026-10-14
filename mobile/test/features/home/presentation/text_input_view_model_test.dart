import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';

void main() {
  test('starts idle and counts visible Unicode characters', () {
    final model = TextInputViewModel(onSubmit: (_) async {});
    addTearDown(model.dispose);

    expect(model.status, TextInputStatus.idle);
    expect(model.characterCounter, '0/4000');
    model.setText('A👨‍👩‍👧‍👦e\u0301');
    expect(model.characterCounter, '3/4000');
    expect(model.canSubmit, isTrue);
  });

  test(
    'rejects empty and whitespace-only input without calling submit',
    () async {
      var calls = 0;
      final model = TextInputViewModel(
        onSubmit: (_) async {
          calls++;
        },
      );
      addTearDown(model.dispose);

      await model.submit();
      expect(model.status, TextInputStatus.error);
      expect(model.errorMessage, 'Tekst nie może być pusty.');
      model.setText(' \n\t ');
      await model.submit();
      expect(model.errorMessage, 'Tekst nie może być pusty.');
      expect(calls, 0);
    },
  );

  test('accepts exactly 4000 characters and rejects 4001', () async {
    final submitted = <String>[];
    final model = TextInputViewModel(
      onSubmit: (input) async => submitted.add(input.value),
    );
    addTearDown(model.dispose);

    model.setText('a' * InputText.maxCharacters);
    expect(model.characterCounter, '4000/4000');
    await model.submit();
    expect(model.status, TextInputStatus.success);
    expect(submitted.single.length, 4000);

    model.setText('a' * 4001);
    expect(model.characterCounter, '4001/4000');
    expect(model.isOverLimit, isTrue);
    expect(model.canSubmit, isFalse);
    expect(model.errorMessage, 'Tekst może mieć maksymalnie 4000 znaków.');
    await model.submit();
    expect(submitted.length, 1);
  });

  test('shows loading and prevents duplicate submissions', () async {
    final pending = Completer<void>();
    var calls = 0;
    final model = TextInputViewModel(
      onSubmit: (_) {
        calls++;
        return pending.future;
      },
    );
    addTearDown(model.dispose);
    model.setText('Tekst');

    final first = model.submit();
    expect(model.status, TextInputStatus.loading);
    expect(model.canSubmit, isFalse);
    await model.submit();
    expect(calls, 1);
    model.setText('Zmiana');
    expect(model.characterCounter, '5/4000');
    pending.complete();
    await first;
    expect(model.status, TextInputStatus.success);
  });

  test('keeps input after failure and permits retry', () async {
    var calls = 0;
    final model = TextInputViewModel(
      onSubmit: (input) async {
        expect(input.value, 'Trudny tekst');
        if (calls++ == 0) throw StateError('private error');
      },
    );
    addTearDown(model.dispose);
    model.setText('Trudny tekst');

    await model.submit();
    expect(model.status, TextInputStatus.error);
    expect(
      model.errorMessage,
      'Nie udało się uprościć tekstu. Spróbuj ponownie.',
    );
    expect(model.characterCounter, '12/4000');
    await model.submit();
    expect(calls, 2);
    expect(model.status, TextInputStatus.success);
    expect(model.errorMessage, isNull);
  });

  test('timeout keeps input and shows a retry message', () async {
    final model = TextInputViewModel(
      onSubmit: (_) async => throw TimeoutException('private detail'),
    );
    addTearDown(model.dispose);
    model.setText('Zachowaj tekst');

    await model.submit();
    expect(model.status, TextInputStatus.error);
    expect(
      model.errorMessage,
      'Przekroczono czas oczekiwania. Spróbuj ponownie.',
    );
    expect(model.characterCounter, '14/4000');
    expect(model.canSubmit, isTrue);
  });

  test('clears an error on edit and reports an unavailable handler', () async {
    final model = TextInputViewModel(
      onSubmit: (_) async => throw const SubmissionUnavailableException(),
    );
    addTearDown(model.dispose);
    model.setText('Tekst');
    await model.submit();
    expect(
      model.errorMessage,
      'Upraszczanie tekstu nie jest jeszcze dostępne.',
    );
    model.setText('Inny tekst');
    expect(model.status, TextInputStatus.idle);
    expect(model.errorMessage, isNull);
  });

  test('ignores a response after the view model is disposed', () async {
    final pending = Completer<void>();
    final model = TextInputViewModel(onSubmit: (_) => pending.future);
    model.setText('Tekst');
    final submission = model.submit();
    model.dispose();
    pending.complete();
    await submission;
  });
}
