import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/l10n/localization.dart';

class _Repository extends MockAccountRepository
    implements AppleAccountRepository {
  _Repository(this.provider)
    : super(history: MockHistoryRepository(clock: DateTime.now));
  final IdentityProvider provider;
  int links = 0;
  int googleLinks = 0;
  String? password;
  @override
  bool get appleSignInAvailable => true;
  @override
  bool get canLinkApple => provider != IdentityProvider.apple && links == 0;
  @override
  bool get canLinkGoogle =>
      provider != IdentityProvider.google && googleLinks == 0;
  @override
  Future<Account> linkGoogle({String? password}) async {
    googleLinks++;
    this.password = password;
    return current();
  }

  @override
  Future<Account> current() async =>
      Account(id: 'same-account', provider: provider);
  @override
  Future<Account> signInWithApple() async => current();
  @override
  Future<Account> linkApple({String? password}) async {
    links++;
    this.password = password;
    return current();
  }
}

void main() {
  testWidgets(
    'Apple-first account can explicitly add Google for Android sign-in',
    (tester) async {
      final repository = _Repository(IdentityProvider.apple);
      final strings = polishStrings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, strings.linkApple),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, strings.linkGoogle));
      await tester.pumpAndSettle();
      expect(find.text(strings.confirmGoogleAccountLink), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(repository.googleLinks, 0);
      await tester.tap(find.widgetWithText(FilledButton, strings.linkGoogle));
      await tester.pumpAndSettle();
      expect(repository.googleLinks, 1);
      expect(
        find.widgetWithText(OutlinedButton, strings.linkGoogle),
        findsNothing,
      );
      expect(find.text(strings.signOut), findsOneWidget);
    },
  );

  testWidgets(
    'email account explicitly confirms Apple linking with its password',
    (tester) async {
      final repository = _Repository(IdentityProvider.email);
      final strings = polishStrings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, strings.linkApple));
      await tester.pumpAndSettle();
      expect(find.text(strings.confirmAccountLink), findsOneWidget);
      expect(find.text(strings.passwordToLink), findsOneWidget);
      expect(repository.links, 0);
      await tester.enterText(find.byType(TextField), 'current-password');
      await tester.tap(find.widgetWithText(FilledButton, strings.linkApple));
      await tester.pumpAndSettle();
      expect(repository.links, 1);
      expect(repository.password, 'current-password');
      expect(
        find.widgetWithText(OutlinedButton, strings.linkApple),
        findsNothing,
      );
      expect(find.text(strings.signOut), findsOneWidget);
    },
  );
  testWidgets(
    'Google linking asks for confirmation without a password and supports cancellation',
    (tester) async {
      final repository = _Repository(IdentityProvider.google);
      final strings = polishStrings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, strings.linkApple));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.links, 0);
    },
  );
}
