import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/data/firebase_account_repository.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/features/simplification/data/http_simplification_repository.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;

class DeletionProvider implements firebase.UserInfo {
  @override
  String get providerId => 'password';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DeletionUser implements firebase.User {
  int reauthentications = 0;
  firebase.AuthCredential? lastCredential;
  String? reauthenticationError;
  String provider = 'password';
  @override
  List<firebase.UserInfo> get providerData =>
      provider == 'password' ? [DeletionProvider()] : [];
  @override
  String get email => 'owner@example.com';
  @override
  String get uid => 'firebase-owner';
  @override
  bool get emailVerified => true;
  @override
  Future<firebase.UserCredential> reauthenticateWithCredential(
    firebase.AuthCredential credential,
  ) async {
    reauthentications++;
    lastCredential = credential;
    if (reauthenticationError != null) {
      throw firebase.FirebaseAuthException(code: reauthenticationError!);
    }
    return DeletionCredential();
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'fresh-firebase';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DeletionCredential implements firebase.UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuth implements firebase.FirebaseAuth {
  int signOuts = 0;
  firebase.User? user = DeletionUser();
  @override
  firebase.User? get currentUser => user;
  @override
  Future<void> signOut() async {
    signOuts++;
    user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GoogleAccount implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'google-reauth');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogle implements GoogleSignIn {
  int authentications = 0;
  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    authentications++;
    return GoogleAccount();
  }

  int signOuts = 0;
  @override
  Future<void> signOut() async {
    signOuts++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('repository resumes local cleanup after server success and local storage failure', () async {
    final storage = MemorySessionStorage();
    storage.values.addAll({'account_token': 'owner', 'account_json': '{}'});
    var serverCalls = 0;
    final sessions = BackendSessionGateway(
      baseUrl: Uri.parse('https://api.example.test'),
      client: MockClient((_) async {
        serverCalls++;
        return http.Response('', 204);
      }),
      storage: storage,
      integrity: CapturingIntegrity(),
    );
    final auth = FakeAuth();
    final google = FakeGoogle();
    var historyExists = true;
    var fail = true;
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: google,
      sessions: sessions,
      clearHistory: () async {
        if (fail) throw StateError('storage unavailable');
        historyExists = false;
      },
    );
    await expectLater(
      repository.deleteAccount(password: 'password'),
      throwsStateError,
    );
    expect(historyExists, isTrue);
    expect(await sessions.deletionPending, isTrue);
    expect(auth.signOuts, 0);
    fail = false;
    expect((await repository.current()).provider, IdentityProvider.guest);
    expect(historyExists, isFalse);
    expect(auth.signOuts, 1);
    expect(google.signOuts, 1);
    expect(serverCalls, 1);
    expect(storage.values, isEmpty);
  });

  test('remote rejection keeps local data and identity for retry', () async {
    final storage = MemorySessionStorage();
    storage.values['account_token'] = 'owner';
    final auth = FakeAuth();
    var cleared = false;
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: FakeGoogle(),
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((_) async => http.Response('', 500)),
        storage: storage,
        integrity: CapturingIntegrity(),
      ),
      clearHistory: () async {
        cleared = true;
      },
    );
    await expectLater(
      repository.deleteAccount(password: 'password'),
      throwsStateError,
    );
    expect(cleared, isFalse);
    expect(auth.signOuts, 0);
    expect(storage.values['account_token'], 'owner');
  });
  for (final provider in ['password', 'google']) {
    test(
      '$provider deletion reauthenticates before sending a fresh token',
      () async {
        final storage = MemorySessionStorage()
          ..values['account_token'] = 'owner';
        final user = DeletionUser()..provider = provider;
        final auth = FakeAuth()..user = user;
        final google = FakeGoogle();
        var calls = 0;
        final sessions = BackendSessionGateway(
          baseUrl: Uri.parse('https://api.example.test'),
          client: MockClient((request) async {
            expect(user.reauthentications, 1);
            expect(request.body, '{"idToken":"fresh-firebase"}');
            calls++;
            return http.Response('', 204);
          }),
          storage: storage,
          integrity: CapturingIntegrity(),
        );
        final repository = FirebaseAccountRepository(
          auth: auth,
          google: google,
          sessions: sessions,
          clearHistory: () async {},
        );
        await repository.deleteAccount(password: 'secret');
        expect(calls, 1);
        expect(
          user.lastCredential?.providerId,
          provider == 'password' ? 'password' : 'google.com',
        );
        expect(google.authentications, provider == 'password' ? 0 : 1);
      },
    );
  }

  test(
    'failed reauthentication never sends deletion or clears history',
    () async {
      final storage = MemorySessionStorage()..values['account_token'] = 'owner';
      final user = DeletionUser()..reauthenticationError = 'user-mismatch';
      var calls = 0;
      var cleared = false;
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((_) async {
          calls++;
          return http.Response('', 204);
        }),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      final repository = FirebaseAccountRepository(
        auth: FakeAuth()..user = user,
        google: FakeGoogle(),
        sessions: sessions,
        clearHistory: () async {
          cleared = true;
        },
      );
      await expectLater(
        repository.deleteAccount(password: 'secret'),
        throwsA(isA<AccountActionException>()),
      );
      expect(calls, 0);
      expect(cleared, isFalse);
      expect(storage.values['account_token'], 'owner');
    },
  );

  test(
    '401 discards the old bearer, signs out and clears local history',
    () async {
      final storage = MemorySessionStorage()
        ..values.addAll({'account_token': 'revoked', 'account_json': '{}'});
      final auth = FakeAuth();
      var cleared = false;
      var calls = 0;
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((_) async {
          calls++;
          return http.Response('', 401);
        }),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      final accounts = FirebaseAccountRepository(
        auth: auth,
        google: FakeGoogle(),
        sessions: sessions,
        clearHistory: () async {
          cleared = true;
        },
      );
      final repository = HttpSimplificationRepository(
        baseUrl: sessions.baseUrl,
        client: sessions.client,
        sessions: sessions,
      );
      await expectLater(
        repository.current(),
        throwsA(isA<SimplificationApiException>()),
      );
      expect(await sessions.savedAccount(), isNull);
      expect(auth.currentUser, isNull);
      expect(cleared, isTrue);
      expect((await accounts.current()).provider, IdentityProvider.guest);
      expect(calls, 1);
    },
  );
}
