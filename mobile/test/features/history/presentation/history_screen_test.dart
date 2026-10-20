import '../../../helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';
import 'package:sedno_app/features/history/presentation/history_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class FailingOnceHistory implements HistoryRepository {
  var _failed = false;
  @override
  Future<List<HistoryEntry>> readAll() async {
    if (_failed) return [];
    _failed = true;
    throw StateError('locked');
  }

  @override
  Future<void> save(HistoryEntry entry) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  // Local times keep expectations independent of the machine's time zone.
  final now = DateTime(2026, 10, 20, 18).toUtc();
  HistoryEntry entry(String id, DateTime createdLocal, {String? text}) =>
      HistoryEntry(
        original: InputText('Trudny tekst $id'),
        result: SimplificationResult(
          id: id,
          text: text ?? 'Łatwy tekst $id',
          createdAt: createdLocal.toUtc(),
        ),
      );

  Future<MockHistoryRepository> show(
    WidgetTester tester,
    List<HistoryEntry> entries,
  ) async {
    final repository = MockHistoryRepository(clock: () => now);
    for (final item in entries) {
      await repository.save(item);
    }
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            repository: repository,
            revision: revision,
            clock: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('explains storage, dates and expiry in plain lines', (
    tester,
  ) async {
    await show(tester, [
      entry('today', DateTime(2026, 10, 20, 13, 5)),
      entry('yesterday', DateTime(2026, 10, 19, 9, 30)),
      entry('older', DateTime(2026, 10, 17, 8, 0)),
    ]);
    expect(
      find.text('Teksty są zapisane tylko na tym telefonie.'),
      findsOneWidget,
    );
    expect(find.text('Każdy tekst usuwa się sam po 7 dniach.'), findsOneWidget);
    expect(find.text('Wylogowanie usuwa całą historię.'), findsOneWidget);
    expect(find.text('Dziś, 13:05'), findsOneWidget);
    expect(find.text('Zostanie usunięty 27.10.'), findsOneWidget);
    expect(find.text('Wczoraj, 9:30'), findsOneWidget);
    expect(find.text('17.10, 8:00'), findsOneWidget);
    expect(find.text('Zostanie usunięty 24.10.'), findsOneWidget);
  });

  testWidgets('original is hidden until requested and texts are selectable', (
    tester,
  ) async {
    await show(tester, [entry('one', DateTime(2026, 10, 20, 13, 5))]);
    expect(find.text('Wersja prosta'), findsOneWidget);
    expect(find.text('Trudny tekst one'), findsNothing);
    expect(
      find.widgetWithText(SelectableText, 'Łatwy tekst one'),
      findsOneWidget,
    );
    await tester.tap(find.text('Pokaż oryginał'));
    await tester.pump();
    expect(
      find.widgetWithText(SelectableText, 'Trudny tekst one'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ukryj oryginał'));
    await tester.pump();
    expect(find.text('Trudny tekst one'), findsNothing);
  });

  testWidgets('delete asks first; cancel keeps and confirm removes', (
    tester,
  ) async {
    final repository = await show(tester, [
      entry('one', DateTime(2026, 10, 20, 13, 5)),
    ]);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(find.text('Usunąć ten tekst z historii?'), findsOneWidget);
    expect(find.text('Tego nie można cofnąć.'), findsOneWidget);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(await repository.readAll(), hasLength(1));

    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();
    expect(await repository.readAll(), isEmpty);
    expect(find.text('Usunięto tekst.'), findsOneWidget);
    expect(find.text('Nie masz jeszcze zapisanych tekstów.'), findsOneWidget);
  });

  testWidgets('TalkBack names which entry the delete button removes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await show(tester, [entry('one', DateTime(2026, 10, 20, 13, 5))]);
    expect(
      find.bySemanticsLabel('Usuń tekst zapisany: Dziś, 13:05'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('read failure explains and offers a retry', (tester) async {
    final repository = FailingOnceHistory();
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(repository: repository, revision: revision),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się wczytać historii.'), findsOneWidget);
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();
    expect(find.text('Nie masz jeszcze zapisanych tekstów.'), findsOneWidget);
  });

  testWidgets('successful simplification appears in local history', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 14);
    final history = MockHistoryRepository(clock: () => now);
    final quota = MockQuotaRepository(clock: () => now);
    final simplification = MockSimplificationRepository(
      quota: quota,
      clock: () => now,
    );
    await tester.pumpWidget(
      SednoApp(
        simplificationRepository: simplification,
        historyRepository: history,
      ),
    );
    await tester.enterText(find.byType(TextField), 'Trudny tekst');
    await submitText(tester);
    await tester.pumpAndSettle();
    expect((await history.readAll()).single.original.value, 'Trudny tekst');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await navigateTo(tester, 'Historia');
    await tester.pumpAndSettle();
    expect(find.text('Przykładowe uproszczenie: Trudny tekst'), findsOneWidget);
  });
}
