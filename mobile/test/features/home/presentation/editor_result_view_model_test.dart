import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/editor_result_view_model.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';

void main() {
  test('restores only the original of the latest successful operation', () {
    final model = EditorResultViewModel();
    addTearDown(model.dispose);
    model.show(originalText: 'Pierwszy tekst', mode: TextMode.simplify);
    model.show(originalText: 'Drugi tekst', mode: TextMode.correct);
    expect(model.mode, TextMode.correct);
    expect(model.restoreOriginal(), 'Drugi tekst');
    expect(model.hasOriginal, isFalse);
    expect(model.mode, isNull);
    expect(model.restoreOriginal(), isNull);
  });

  test('clear removes the original; pending operations block restoring it', () {
    final model = EditorResultViewModel();
    addTearDown(model.dispose);
    model.show(originalText: 'Oryginał', mode: TextMode.correct);
    model.setBusy(true);
    expect(model.restoreOriginal(), isNull);
    expect(model.hasOriginal, isTrue);
    model.setBusy(false);
    model.clear();
    expect(model.restoreOriginal(), isNull);
    expect(model.mode, isNull);
  });
}
