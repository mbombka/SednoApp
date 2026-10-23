import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/presentation/history_screen.dart';
import 'package:sedno_app/features/history/presentation/history_view_model.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class ControlledHistory extends MockHistoryRepository {
  ControlledHistory() : super(clock: () => DateTime.now().toUtc());
  int clears = 0;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> clear() async {
    clears++;
    if (gate != null) await gate!.future;
    if (fail) throw StateError('private storage details');
    await super.clear();
  }
}

void main() {
  Future<ControlledHistory> seeded() async {
    final repository = ControlledHistory();
    for (final id in ['one', 'two']) {
      await repository.save(
        HistoryEntry(
          original: InputText('Oryginał $id'),
          result: SimplificationResult(
            id: id,
            text: 'Wynik $id',
            createdAt: DateTime.now().toUtc(),
          ),
        ),
      );
    }
    return repository;
  }

  Future<void> show(
    WidgetTester tester,
    ControlledHistory repository, {
    double scale = 1,
  }) async {
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: HistoryScreen(repository: repository, revision: revision),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('clearHistoryButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń całą historię'));
  }

  testWidgets(
    'button follows notice; cancel keeps all and confirm removes all',
    (tester) async {
      final repository = await seeded();
      await show(tester, repository);
      final button = find.byKey(const Key('clearHistoryButton'));
      expect(
        tester.getTopLeft(button).dy,
        greaterThan(
          tester
              .getBottomLeft(find.text('Wylogowanie usuwa całą historię.'))
              .dy,
        ),
      );
      expect(
        find.descendant(
          of: button,
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Usunąć całą historię?'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(repository.clears, 0);
      expect(await repository.readAll(), hasLength(2));
      await confirm(tester);
      await tester.pumpAndSettle();
      expect(await repository.readAll(), isEmpty);
      expect(find.text('Usunięto całą historię.'), findsOneWidget);
      expect(find.text('Nie masz jeszcze zapisanych tekstów.'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    },
  );

  testWidgets('failure retains entries and allows a successful retry', (
    tester,
  ) async {
    final repository = await seeded();
    repository.fail = true;
    await show(tester, repository);
    await confirm(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się usunąć całej historii. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(find.text('Usunięto całą historię.'), findsNothing);
    expect(await repository.readAll(), hasLength(2));
    repository.fail = false;
    await confirm(tester);
    await tester.pumpAndSettle();
    expect(await repository.readAll(), isEmpty);
  });

  testWidgets('pending clear blocks duplicate actions', (tester) async {
    final repository = await seeded();
    repository.gate = Completer<void>();
    await show(tester, repository);
    await confirm(tester);
    await tester.pump();
    expect(find.bySemanticsLabel('Usuwanie historii'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('clearHistoryButton')))
          .onPressed,
      isNull,
    );
    expect(repository.clears, 1);
    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(await repository.readAll(), isEmpty);
  });

  testWidgets('clear action supports large text and accessible touch targets', (
    tester,
  ) async {
    final repository = await seeded();
    final semantics = tester.ensureSemantics();
    await show(tester, repository, scale: 2.5);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('clearHistoryButton'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.bySemanticsLabel('Usuń całą historię teraz'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  test(
    'model does not re-read cleared data while deletion is pending',
    () async {
      final repository = await seeded();
      final model = HistoryViewModel(repository);
      addTearDown(model.dispose);
      await model.refresh();
      repository.gate = Completer<void>();
      final pending = model.clearAll();
      expect(await model.clearAll(), isFalse);
      await model.refresh();
      expect(repository.clears, 1);
      repository.gate!.complete();
      expect(await pending, isTrue);
      expect(model.entries, isEmpty);
      expect(model.isClearing, isFalse);
    },
  );
}
