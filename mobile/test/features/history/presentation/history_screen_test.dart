import '../../../helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/presentation/history_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

void main() {
  testWidgets('shows retention notice and deletes a saved entry', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 14);
    final repository = MockHistoryRepository(clock: () => now);
    await repository.save(
      HistoryEntry(
        original: InputText('Trudny tekst'),
        result: SimplificationResult(
          id: 'one',
          text: 'Łatwy tekst',
          createdAt: now,
        ),
      ),
    );
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
    expect(
      find.text('Teksty są przechowywane tylko na tym urządzeniu przez 7 dni.'),
      findsOneWidget,
    );
    expect(find.text('Łatwy tekst'), findsOneWidget);
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    expect(find.text('Łatwy tekst'), findsNothing);
    expect(await repository.readAll(), isEmpty);
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
