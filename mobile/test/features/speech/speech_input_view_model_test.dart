import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';
import 'package:sedno_app/features/speech/presentation/speech_input_view_model.dart';

import 'fake_speech_service.dart';

void main() {
  test('one recording at a time; trims the final text', () async {
    final service = FakeSpeechService();
    final model = SpeechInputViewModel(service);
    addTearDown(model.dispose);
    final first = model.listen();
    expect(model.busy, isTrue);
    expect(await model.listen(), isNull);
    expect(service.calls, 1);
    service.pending.complete('  Trudny tekst.  ');
    expect(await first, 'Trudny tekst.');
    expect(model.busy, isFalse);
  });

  test('a late result after cancellation cannot be submitted', () async {
    final service = FakeSpeechService();
    final model = SpeechInputViewModel(service);
    addTearDown(model.dispose);
    final result = model.listen();
    service.pending.complete('Spóźniony wynik');
    await model.cancel();
    expect(await result, isNull);
    expect(model.busy, isFalse);
    expect(model.message, isNull);
  });

  test('empty speech has a Polish message', () async {
    final service = FakeSpeechService();
    final model = SpeechInputViewModel(service);
    addTearDown(model.dispose);
    final result = model.listen();
    service.pending.complete(' \n ');
    expect(await result, isNull);
    expect(model.message, 'Nie rozpoznano mowy. Spróbuj ponownie.');
  });

  test('permission error releases the busy state', () async {
    final service = FakeSpeechService();
    final model = SpeechInputViewModel(service);
    addTearDown(model.dispose);
    final result = model.listen();
    service.pending.completeError(const SpeechException('Brak dostępu.'));
    expect(await result, isNull);
    expect(model.message, 'Brak dostępu.');
    expect(model.busy, isFalse);
  });

  test('dispose cancels recording and ignores its eventual result', () async {
    final service = FakeSpeechService();
    final model = SpeechInputViewModel(service);
    final result = model.listen();
    model.dispose();
    expect(await result, isNull);
    expect(service.cancellations, 1);
  });
}
