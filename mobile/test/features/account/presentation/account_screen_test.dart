import '../../../helpers.dart';

import 'package:sedno_app/features/account/domain/account_repository.dart';

import 'package:sedno_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';
import 'package:sedno_app/features/account/presentation/account_screen.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';

class RevocableAccountRepository extends MockAccountRepository
    implements AccountStateSource {
  RevocableAccountRepository()
    : super(history: MockHistoryRepository(clock: DateTime.now));
  @override
  final ValueNotifier<int> accountRevision = ValueNotifier<int>(0);
  String? deletionPassword;
  @override
  Future<void> deleteAccount({String? password}) async {
    deletionPassword = password;
    await super.deleteAccount(password: password);
  }

  Future<void> revoke() async {
    await signOut();
    accountRevision.value++;
  }
}

class VerificationScreenRepository extends MockAccountRepository {
  VerificationScreenRepository()
    : super(history: MockHistoryRepository(clock: DateTime.now));
  bool confirmed = false;
  bool failDelivery = false;
  bool failLink = false;
  int resends = 0;
  int registrations = 0;
  String? resetEmail;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmail = email.trim();
  }

  @override
  Future<Account> registerWithEmail(String email, String password) async {
    registrations++;
    final account = await super.registerWithEmail(email, password);
    if (failDelivery) {
      throw AccountActionException(
        'Nie udało się wysłać wiadomości. Spróbuj ponownie.',
        account: account,
      );
    }
    return account;
  }

  @override
  Future<Account> checkEmailVerification() async {
    if (failLink) {
      throw AccountActionException(
        'Serwer nie potwierdził instalacji aplikacji.',
        account: Account(
          id: 'pending-link',
          provider: IdentityProvider.email,
          email: 'test@example.com',
          sessionLinkRequired: true,
        ),
      );
    }
    return confirmed ? super.checkEmailVerification() : current();
  }

  @override
  Future<void> resendVerificationEmail() async {
    resends++;
  }
}

class GoogleEmailRepository extends MockAccountRepository {
  GoogleEmailRepository()
    : super(history: MockHistoryRepository(clock: DateTime.now));
  Account? _signedIn;

  @override
  Future<Account> current() async => _signedIn ?? super.current();

  @override
  Future<Account> signInWithGoogle() async => _signedIn = Account(
    id: 'google-email',
    provider: IdentityProvider.google,
    email: 'jan@example.com',
  );
}

void main() {
  testWidgets(
    'email deletion asks for the password and passes it for reauthentication',
    (tester) async {
      final repository = RevocableAccountRepository();
      await repository.signInWithEmail('jan@example.com', 'original');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń konto'));
      await tester.pumpAndSettle();
      final password = find.widgetWithText(TextField, 'Hasło');
      expect(password, findsOneWidget);
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      await tester.enterText(password, 'confirmed-password');
      await tester.tap(find.text('Usuń konto i dane'));
      await tester.pumpAndSettle();
      expect(repository.deletionPassword, 'confirmed-password');
      expect(find.text('Zaloguj przez Google'), findsOneWidget);
    },
  );

  testWidgets('rejected session returns an open account screen to sign in', (
    tester,
  ) async {
    final repository = RevocableAccountRepository();
    await repository.signInWithGoogle();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Usuń konto'), findsOneWidget);
    await repository.revoke();
    await tester.pumpAndSettle();
    expect(find.text('Usuń konto'), findsNothing);
    expect(find.text('Zaloguj przez Google'), findsOneWidget);
  });

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
    await navigateTo(tester, 'Konto');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Usuń konto'));
    await tester.tap(find.text('Usuń konto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń konto i dane'));
    await tester.pumpAndSettle();
    expect(await history.readAll(), isEmpty);
    await navigateTo(tester, 'Start');
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

  testWidgets('guest can open privacy from the menu while viewing Konto', (
    tester,
  ) async {
    await tester.pumpWidget(const SednoApp());
    await navigateTo(tester, 'Konto');
    await tester.tap(find.byTooltip('Menu użytkownika'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prywatność i dane'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Prywatność i dane'));
    await tester.pumpAndSettle();
    expect(find.text('Twoje prawa i kontakt'), findsOneWidget);
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

  testWidgets('signed-in Google account shows its email address', (
    tester,
  ) async {
    final repository = GoogleEmailRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zaloguj przez Google'));
    await tester.pumpAndSettle();
    expect(
      find.text('Zalogowano jako jan@example.com (konto Google)'),
      findsOneWidget,
    );
  });

  testWidgets('email registration uses the supplied address', (tester) async {
    final repository = VerificationScreenRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nie masz konta? Utwórz konto'));
    await tester.tap(find.text('Nie masz konta? Utwórz konto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'sample-password');
    await tester.enterText(find.byType(TextField).at(2), 'sample-password');
    await tester.ensureVisible(find.text('Utwórz konto'));
    await tester.tap(find.text('Utwórz konto'));
    await tester.pumpAndSettle();
    expect((await repository.current()).email, 'test@example.com');
    expect(find.textContaining('Zalogowano'), findsNothing);
    expect(find.text('Sprawdź pocztę'), findsOneWidget);
    expect(
      find.textContaining('Do tego czasu możesz korzystać'),
      findsOneWidget,
    );
    expect(find.text('Wyślij ponownie za 60 s'), findsOneWidget);
    await tester.ensureVisible(find.text('Sprawdź potwierdzenie'));
    await tester.tap(find.text('Sprawdź potwierdzenie'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Adres nie jest jeszcze potwierdzony'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.ensureVisible(find.text('Wyślij wiadomość ponownie'));
    await tester.tap(find.text('Wyślij wiadomość ponownie'));
    await tester.pumpAndSettle();
    expect(repository.resends, 1);
    expect(find.text('Wyślij ponownie za 60 s'), findsOneWidget);
    repository.confirmed = true;
    await tester.ensureVisible(find.text('Sprawdź potwierdzenie'));
    await tester.tap(find.text('Sprawdź potwierdzenie'));
    await tester.pumpAndSettle();
    expect(
      find.text('Zalogowano jako test@example.com (e-mail i hasło)'),
      findsOneWidget,
    );
    expect(find.text('Sprawdź pocztę'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('delivery failure keeps verification screen and allows retry', (
    tester,
  ) async {
    final repository = VerificationScreenRepository()..failDelivery = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nie masz konta? Utwórz konto'));
    await tester.tap(find.text('Nie masz konta? Utwórz konto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'sample-password');
    await tester.enterText(find.byType(TextField).at(2), 'sample-password');
    await tester.ensureVisible(find.text('Utwórz konto'));
    await tester.tap(find.text('Utwórz konto'));
    await tester.pumpAndSettle();
    expect(find.text('Sprawdź pocztę'), findsOneWidget);
    expect(
      find.textContaining('Nie udało się wysłać wiadomości'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Wyślij wiadomość ponownie'));
    await tester.tap(find.text('Wyślij wiadomość ponownie'));
    await tester.pumpAndSettle();
    expect(repository.resends, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'verified email with backend failure shows cause and can retry without verification',
    (tester) async {
      final repository = VerificationScreenRepository()..failLink = true;
      await repository.registerWithEmail('test@example.com', 'password');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sprawdź potwierdzenie'));
      await tester.tap(find.text('Sprawdź potwierdzenie'));
      await tester.pumpAndSettle();
      expect(find.text('Adres e-mail potwierdzony'), findsOneWidget);
      expect(
        find.text('Serwer nie potwierdził instalacji aplikacji.'),
        findsOneWidget,
      );
      expect(find.text('Sprawdź pocztę'), findsNothing);
      expect(find.text('Wyślij wiadomość ponownie'), findsNothing);
      expect(find.textContaining('Zalogowano'), findsNothing);
      final errorRect = tester.getRect(
        find.text('Serwer nie potwierdził instalacji aplikacji.'),
      );
      expect(errorRect.top, greaterThanOrEqualTo(0));
      expect(
        errorRect.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      repository
        ..failLink = false
        ..confirmed = true;
      await tester.ensureVisible(find.text('Dokończ logowanie'));
      await tester.tap(find.text('Dokończ logowanie'));
      await tester.pumpAndSettle();
      expect(
        find.text('Zalogowano jako test@example.com (e-mail i hasło)'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'login and registration are separate and passwords have independent visibility',
    (tester) async {
      final repository = VerificationScreenRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.text('Utwórz konto'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).at(1), 'private-password');
      await tester.tap(find.byTooltip('Pokaż hasło'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
      await tester.ensureVisible(find.text('Nie masz konta? Utwórz konto'));
      await tester.tap(find.text('Nie masz konta? Utwórz konto'));
      await tester.pumpAndSettle();
      expect(find.text('Nowe konto'), findsOneWidget);
      expect(find.text('Zaloguj przez e-mail'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue,
      );
      await tester.ensureVisible(find.byTooltip('Pokaż powtórzone hasło'));
      await tester.tap(find.byTooltip('Pokaż powtórzone hasło'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Ukryj powtórzone hasło'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isTrue,
      );
    },
  );

  testWidgets(
    'registration rejects missing or different confirmation before creating an account',
    (tester) async {
      final repository = VerificationScreenRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nie masz konta? Utwórz konto'));
      await tester.tap(find.text('Nie masz konta? Utwórz konto'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.ensureVisible(find.text('Utwórz konto'));
      await tester.tap(find.text('Utwórz konto'));
      await tester.pumpAndSettle();
      expect(find.text('Powtórz hasło.'), findsOneWidget);
      expect(repository.registrations, 0);
      await tester.enterText(find.byType(TextField).at(2), 'different');
      await tester.ensureVisible(find.text('Utwórz konto'));
      await tester.tap(find.text('Utwórz konto'));
      await tester.pumpAndSettle();
      expect(find.text('Hasła muszą być takie same.'), findsOneWidget);
      expect(repository.registrations, 0);
      await tester.enterText(find.byType(TextField).at(2), 'password');
      await tester.ensureVisible(find.text('Utwórz konto'));
      await tester.tap(find.text('Utwórz konto'));
      await tester.pumpAndSettle();
      expect(repository.registrations, 1);
      expect(find.text('Sprawdź pocztę'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'password recovery has only an email field and a neutral delivery message',
    (tester) async {
      final repository = VerificationScreenRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AccountScreen(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nie pamiętam hasła'));
      await tester.tap(find.text('Nie pamiętam hasła'));
      await tester.pumpAndSettle();
      expect(find.text('Odzyskaj dostęp'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.ensureVisible(find.text('Wyślij link do zmiany hasła'));
      await tester.tap(find.text('Wyślij link do zmiany hasła'));
      await tester.pumpAndSettle();
      expect(repository.resetEmail, 'test@example.com');
      expect(
        find.textContaining('Jeśli konto z tym adresem istnieje'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Wróć do logowania'));
      await tester.tap(find.text('Wróć do logowania'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Zaloguj się'), findsOneWidget);
    },
  );
  testWidgets(
    'registration supports large text on a narrow screen and labelled touch targets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: AccountScreen(repository: VerificationScreenRepository()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nie masz konta? Utwórz konto'));
      await tester.tap(find.text('Nie masz konta? Utwórz konto'));
      await tester.pumpAndSettle();
      for (final label in ['Pokaż hasło', 'Pokaż powtórzone hasło']) {
        await tester.ensureVisible(find.byTooltip(label));
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await tester.ensureVisible(find.text('Utwórz konto'));
      expect(tester.takeException(), isNull);
    },
  );
}
