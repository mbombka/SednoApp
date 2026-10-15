import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/data/firebase_account_repository.dart';
import 'package:sedno_app/features/account/domain/account.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;

class FakeAuth implements firebase.FirebaseAuth {
  int signOuts = 0;
  @override
  firebase.User? get currentUser => null;
  @override
  Future<void> signOut() async {
    signOuts++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogle implements GoogleSignIn {
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
    await expectLater(repository.deleteAccount(), throwsStateError);
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
    await expectLater(repository.deleteAccount(), throwsStateError);
    expect(cleared, isFalse);
    expect(auth.signOuts, 0);
    expect(storage.values['account_token'], 'owner');
  });
}
