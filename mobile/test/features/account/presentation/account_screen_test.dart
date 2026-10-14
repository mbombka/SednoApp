import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';

void main() {
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
