import 'package:sedno_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';

void main() {
  testWidgets('app clears editor and history when an account is deleted', (
    tester,
  ) async {
    final history = MockHistoryRepository(clock: DateTime.now);
    await history.save(
      HistoryEntry(
        original: InputText('Oryginał'),
        result: SimplificationResult(
          id: 'saved',
          text: 'Wynik',
          createdAt: DateTime.now(),
        ),
      ),
    );
    final accounts = MockAccountRepository(history: history);
    await accounts.signInWithGoogle();
    await tester.pumpWidget(
      SednoApp(historyRepository: history, accountRepository: accounts),
    );
    await tester.enterText(find.byType(TextField), 'Tekst roboczy');
    await tester.tap(find.widgetWithText(Tab, 'Konto'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Usuń konto'));
    await tester.tap(find.text('Usuń konto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń konto i dane'));
    await tester.pumpAndSettle();
    expect(await history.readAll(), isEmpty);
    await tester.tap(find.widgetWithText(Tab, 'Start'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deletion warns, supports cancel and clears local history on confirmation',
    (tester) async {
      final history = MockHistoryRepository(clock: DateTime.now);
      await history.save(
        HistoryEntry(
          original: InputText('Prywatny tekst'),
          result: SimplificationResult(
            id: 'result',
            text: 'Wynik',
            createdAt: DateTime.now(),
          ),
        ),
      );
      final repository = MockAccountRepository(history: history);
      await repository.signInWithGoogle();
      var cleared = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountScreen(
              repository: repository,
              onDataCleared: () => cleared++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń konto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('nie anuluje subskrypcji'), findsOneWidget);
      await tester.tap(find.text('Zachowaj konto'));
      await tester.pumpAndSettle();
      expect((await history.readAll()).length, 1);
      expect(cleared, 0);
      await tester.tap(find.text('Usuń konto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń konto i dane'));
      await tester.pumpAndSettle();
      expect(await history.readAll(), isEmpty);
      expect((await repository.current()).provider, IdentityProvider.guest);
      expect(cleared, 1);
    },
  );

  testWidgets('privacy information is accessible to guests', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AccountScreen())),
    );
    await tester.tap(find.text('Prywatność i dane'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DO UZUPEŁNIENIA'), findsOneWidget);
    expect(
      find.textContaining('Zdjęcia zostają na urządzeniu'),
      findsOneWidget,
    );
  });

  testWidgets('guest can sign in and sign out from the account tab', (
    tester,
  ) async {
    final history = MockHistoryRepository(clock: DateTime.now);
    final repository = MockAccountRepository(history: history);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zaloguj przez Google'), findsOneWidget);
    await tester.tap(find.text('Zaloguj przez Google'));
    await tester.pumpAndSettle();
    expect((await repository.current()).provider, IdentityProvider.google);
    expect(find.text('Wyloguj się'), findsOneWidget);
    await tester.tap(find.text('Wyloguj się'));
    await tester.pumpAndSettle();
    expect((await repository.current()).provider, IdentityProvider.guest);
    expect(find.text('Zaloguj przez Google'), findsOneWidget);
  });

  testWidgets('email registration uses the supplied address', (tester) async {
    final repository = MockAccountRepository(
      history: MockHistoryRepository(clock: DateTime.now),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'sample-password');
    await tester.tap(find.text('Utwórz konto'));
    await tester.pumpAndSettle();
    expect((await repository.current()).email, 'test@example.com');
    expect(find.text('Zalogowano.'), findsOneWidget);
  });
}
