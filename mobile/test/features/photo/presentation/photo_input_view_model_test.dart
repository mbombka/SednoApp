import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:simplifier_app/features/photo/domain/photo_text_repository.dart';
import 'package:simplifier_app/features/photo/presentation/photo_input_view_model.dart';

class FakePhotoRepository implements PhotoTextRepository {
  FakePhotoRepository(this.action);
  final Future<String?> Function() action;
  int calls = 0;
  @override
  Future<String?> recognizeFromCamera() {
    calls++;
    return action();
  }
}

void main() {
  test('reports denied permission in Polish', () async {
    final model = PhotoInputViewModel(
      FakePhotoRepository(() async => throw const CameraPermissionDenied()),
    );
    addTearDown(model.dispose);

    expect(await model.scan(), isNull);
    expect(model.message, contains('Brak dostępu do aparatu'));
  });

  test('cancellation leaves editor alone without an error', () async {
    final model = PhotoInputViewModel(FakePhotoRepository(() async => null));
    addTearDown(model.dispose);

    expect(await model.scan(), isNull);
    expect(model.message, isNull);
  });

  test('whitespace OCR reports no detected text', () async {
    final model = PhotoInputViewModel(FakePhotoRepository(() async => ' \n '));
    addTearDown(model.dispose);

    expect(await model.scan(), isNull);
    expect(model.message, contains('Nie wykryto tekstu'));
  });

  test('processing error hides details and permits retry', () async {
    var first = true;
    final model = PhotoInputViewModel(
      FakePhotoRepository(() async {
        if (first) {
          first = false;
          throw StateError('private detail');
        }
        return 'Poprawny tekst';
      }),
    );
    addTearDown(model.dispose);

    expect(await model.scan(), isNull);
    expect(model.message, 'Nie udało się odczytać tekstu. Spróbuj ponownie.');
    expect(await model.scan(), 'Poprawny tekst');
    expect(model.message, isNull);
  });

  test('does not start a second scan while busy', () async {
    final pending = Completer<String?>();
    final repository = FakePhotoRepository(() => pending.future);
    final model = PhotoInputViewModel(repository);
    addTearDown(model.dispose);

    final first = model.scan();
    expect(model.isLoading, isTrue);
    expect(await model.scan(), isNull);
    expect(repository.calls, 1);
    pending.complete('Tekst');
    expect(await first, 'Tekst');
    expect(model.isLoading, isFalse);
  });
}
