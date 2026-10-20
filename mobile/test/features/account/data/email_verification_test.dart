import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/data/firebase_account_repository.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;
import 'firebase_account_deletion_test.dart' show FakeGoogle;

class PasswordProvider implements firebase.UserInfo {
  @override
  String get providerId => 'password';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VerificationUser implements firebase.User {
  bool verified = false;
  bool verifyOnReload = false;
  bool failDelivery = false;
  int deliveries = 0;
  int refreshes = 0;
  int tokenReads = 0;
  @override
  String get uid => 'firebase-user';
  @override
  String get email => 'test@example.com';
  @override
  bool get emailVerified => verified;
  @override
  List<firebase.UserInfo> get providerData => [PasswordProvider()];
  @override
  Future<void> reload() async {
    refreshes++;
    verified = verifyOnReload;
  }

  @override
  Future<void> sendEmailVerification([
    firebase.ActionCodeSettings? settings,
  ]) async {
    deliveries++;
    if (failDelivery) {
      throw firebase.FirebaseAuthException(code: 'network-request-failed');
    }
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    expect(forceRefresh, isTrue);
    tokenReads++;
    return 'fresh-verified-token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VerificationAuth implements firebase.FirebaseAuth {
  VerificationAuth(this.user);
  VerificationUser? user;
  int registrations = 0;
  String? language;
  String? registrationError;
  String? resetEmail;
  String? resetError;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    firebase.ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmail = email;
    if (resetError != null) {
      throw firebase.FirebaseAuthException(code: resetError!);
    }
  }

  @override
  firebase.User? get currentUser => user;
  @override
  Future<firebase.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrations++;
    expect(email, 'test@example.com');
    if (registrationError != null) {
      throw firebase.FirebaseAuthException(code: registrationError!);
    }
    return VerificationCredential();
  }

  @override
  Future<firebase.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => VerificationCredential();
  @override
  Future<void> setLanguageCode(String? languageCode) async {
    language = languageCode;
  }

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VerificationCredential implements firebase.UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late VerificationUser user;
  late VerificationAuth auth;
  late MemorySessionStorage storage;
  late FirebaseAccountRepository repository;
  late List<String> paths;
  late bool backendUnavailable;
  late bool rejectIntegrity;
  setUp(() {
    backendUnavailable = false;
    rejectIntegrity = false;
    user = VerificationUser();
    auth = VerificationAuth(user);
    storage = MemorySessionStorage();
    storage.values['guest_token'] = 'guest-with-usage';
    paths = [];
    repository = FirebaseAccountRepository(
      auth: auth,
      google: FakeGoogle(),
      clearHistory: () async {},
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == '/v1/guest-sessions') {
            return rejectIntegrity
                ? http.Response('{"code":"integrity_failed"}', 403)
                : http.Response('{"accessToken":"guest-with-usage"}', 200);
          }
          if (backendUnavailable) return http.Response('', 503);
          if (request.url.path == '/v1/auth/sign-out') {
            return http.Response('', 204);
          }
          expect(request.url.path, '/v1/auth/sessions');
          expect(request.headers['authorization'], 'Bearer guest-with-usage');
          expect(jsonDecode(request.body)['idToken'], 'fresh-verified-token');
          return http.Response(
            jsonEncode({
              'accessToken': 'account',
              'account': {'id': 'account-id', 'provider': 'email'},
            }),
            200,
          );
        }),
      ),
    );
  });

  test(
    'registration sends Polish email and keeps backend guest and its usage',
    () async {
      final account = await repository.registerWithEmail(
        ' test@example.com ',
        'password',
      );
      expect(account.emailVerificationRequired, isTrue);
      expect(user.deliveries, 1);
      expect(auth.language, 'pl');
      expect(paths, isEmpty);
      expect(user.tokenReads, 0);
      expect(storage.values['guest_token'], 'guest-with-usage');
      expect((await repository.current()).emailVerificationRequired, isTrue);
      expect(
        user.deliveries,
        1,
      ); // Screen reload must not send another message.
    },
  );

  test('existing unverified account can resend and link only after reload verifies it', () async {
    expect(
      (await repository.signInWithEmail(
        'test@example.com',
        'password',
      )).emailVerificationRequired,
      isTrue,
    );
    expect(
      (await repository.checkEmailVerification()).emailVerificationRequired,
      isTrue,
    );
    expect(paths, isEmpty);
    await repository.resendVerificationEmail();
    expect(user.deliveries, 1);
    user.verifyOnReload = true;
    final account = await repository.checkEmailVerification();
    expect(account.emailVerificationRequired, isFalse);
    expect(account.id, 'account-id');
    expect(user.tokenReads, 1);
    expect(paths, ['/v1/auth/sessions']);
  });

  test('delivery failure retains pending account and retry does not register again', () async {
    user.failDelivery = true;
    await expectLater(
      repository.registerWithEmail('test@example.com', 'password'),
      throwsA(
        isA<AccountActionException>().having(
          (e) => e.account?.emailVerificationRequired,
          'pending',
          true,
        ),
      ),
    );
    expect((await repository.current()).emailVerificationRequired, isTrue);
    user.failDelivery = false;
    await repository.resendVerificationEmail();
    expect(auth.registrations, 1);
    expect(user.deliveries, 2);
    expect(paths, isEmpty);
  });

  test(
    'old local account session is revoked before unverified guest use',
    () async {
      storage.values.addAll({
        'account_token': 'old-account',
        'account_json': '{"id":"old","provider":"email"}',
      });
      expect((await repository.current()).emailVerificationRequired, isTrue);
      expect(paths, ['/v1/auth/sign-out']);
      expect(storage.values.containsKey('account_token'), isFalse);
      expect(storage.values['guest_token'], 'guest-with-usage');
    },
  );

  test(
    'weak password has a specific Polish error without raw Firebase details',
    () async {
      auth.registrationError = 'weak-password';
      await expectLater(
        repository.registerWithEmail('test@example.com', 'x'),
        throwsA(
          isA<AccountActionException>().having(
            (e) => e.message,
            'message',
            contains('co najmniej 6 znaków'),
          ),
        ),
      );
      expect(user.deliveries, 0);
      expect(paths, isEmpty);
    },
  );
  test('verified Firebase identity survives backend failure and retry completes login', () async {
    user.verifyOnReload = true;
    backendUnavailable = true;
    await expectLater(
      repository.checkEmailVerification(),
      throwsA(
        isA<AccountActionException>()
            .having(
              (e) => e.account?.sessionLinkRequired,
              'session pending',
              true,
            )
            .having(
              (e) => e.account?.emailVerificationRequired,
              'verification pending',
              false,
            ),
      ),
    );
    expect(auth.currentUser, same(user));
    expect((await repository.current()).sessionLinkRequired, isTrue);
    expect(storage.values['guest_token'], 'guest-with-usage');
    backendUnavailable = false;
    final account = await repository.checkEmailVerification();
    expect(account.signInPending, isFalse);
    expect(account.id, 'account-id');
    expect(auth.registrations, 0);
    expect(user.deliveries, 0);
    expect(paths, ['/v1/auth/sessions', '/v1/auth/sessions']);
  });

  test('Integrity rejection keeps verified identity and a later retry starts a session', () async {
    storage.values.remove('guest_token');
    user.verifyOnReload = true;
    rejectIntegrity = true;
    await expectLater(
      repository.checkEmailVerification(),
      throwsA(
        isA<AccountActionException>()
            .having((e) => e.message, 'cause', contains('instalacji aplikacji'))
            .having(
              (e) => e.account?.sessionLinkRequired,
              'session pending',
              true,
            ),
      ),
    );
    expect(auth.currentUser, same(user));
    expect(storage.values.containsKey('account_token'), isFalse);
    rejectIntegrity = false;
    expect((await repository.checkEmailVerification()).signInPending, isFalse);
    expect(paths, [
      '/v1/guest-sessions',
      '/v1/guest-sessions',
      '/v1/auth/sessions',
    ]);
  });

  test('missing Firebase identity returns to login instead of a dead verification screen', () async {
    auth.user = null;
    await expectLater(
      repository.checkEmailVerification(),
      throwsA(
        isA<AccountActionException>()
            .having((e) => e.account?.signInPending, 'pending', false)
            .having(
              (e) => e.message,
              'recovery',
              contains('Zaloguj się ponownie'),
            ),
      ),
    );
  });
  test(
    'password reset uses Polish and trimmed address without starting a session',
    () async {
      await repository.sendPasswordResetEmail(' test@example.com ');
      expect(auth.resetEmail, 'test@example.com');
      expect(auth.language, 'pl');
      expect(paths, isEmpty);
      expect(auth.registrations, 0);
    },
  );

  test('password reset does not reveal a missing account and reports rate limiting', () async {
    auth.resetError = 'user-not-found';
    await repository.sendPasswordResetEmail('test@example.com');
    auth.resetError = 'too-many-requests';
    await expectLater(
      repository.sendPasswordResetEmail('test@example.com'),
      throwsA(
        isA<AccountActionException>().having(
          (e) => e.message,
          'rate limit',
          contains('Za dużo prób'),
        ),
      ),
    );
  });
}
