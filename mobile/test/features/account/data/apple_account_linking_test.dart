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
import 'firebase_account_deletion_test.dart'
    show FakeAuth, FakeGoogle, DeletionUser;

class _Provider implements firebase.UserInfo {
  _Provider(this.providerId);
  @override
  final String providerId;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements firebase.UserCredential {
  _Credential(this.user);
  @override
  final firebase.User? user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User extends DeletionUser {
  final providers = <String>['password'];
  int links = 0;
  String? linkError;
  firebase.User? returnedReauthUser;
  firebase.User? returnedLinkUser;
  @override
  List<firebase.UserInfo> get providerData =>
      providers.map(_Provider.new).toList();
  @override
  Future<firebase.UserCredential> reauthenticateWithCredential(
    firebase.AuthCredential credential,
  ) async {
    await super.reauthenticateWithCredential(credential);
    return _Credential(returnedReauthUser ?? this);
  }

  @override
  Future<firebase.UserCredential> reauthenticateWithProvider(
    firebase.AuthProvider provider,
  ) async {
    expect(provider.providerId, 'apple.com');
    reauthentications++;
    return _Credential(returnedReauthUser ?? this);
  }

  @override
  Future<firebase.UserCredential> linkWithCredential(
    firebase.AuthCredential credential,
  ) async {
    expect(reauthentications, 1);
    expect(credential.providerId, 'google.com');
    links++;
    if (linkError != null) {
      throw firebase.FirebaseAuthException(code: linkError!);
    }
    providers.add('google.com');
    return _Credential(returnedLinkUser ?? this);
  }

  @override
  Future<firebase.UserCredential> linkWithProvider(
    firebase.AuthProvider provider,
  ) async {
    expect(reauthentications, 1);
    expect(provider.providerId, 'apple.com');
    links++;
    if (linkError != null) {
      throw firebase.FirebaseAuthException(code: linkError!);
    }
    providers.add('apple.com');
    return _Credential(this);
  }
}

class _OtherUser extends _User {
  @override
  String get uid => 'other-user';
}

void main() {
  late _User user;
  late FakeAuth auth;
  late FakeGoogle google;
  late MemorySessionStorage storage;
  late FirebaseAccountRepository repository;
  late BackendSessionGateway sessions;
  var requests = <http.Request>[];
  var backendFails = false;
  setUp(() {
    requests = [];
    backendFails = false;
    user = _User();
    auth = FakeAuth()..user = user;
    google = FakeGoogle();
    storage = MemorySessionStorage();
    storage.values.addAll({
      'installation_id': 'original-installation',
      'account_token': 'existing-account',
      'account_json': jsonEncode({'id': 'sedno-account', 'provider': 'email'}),
    });
    sessions = BackendSessionGateway(
      baseUrl: Uri.parse('https://api.test'),
      storage: storage,
      integrity: CapturingIntegrity(),
      client: MockClient((request) async {
        requests.add(request);
        expect(user.links, 1);
        if (backendFails) return http.Response('', 503);
        if (request.url.path == '/v1/guest-sessions') {
          expect(
            jsonDecode(request.body)['installationId'],
            'original-installation',
          );
          return http.Response(jsonEncode({'accessToken': 'new-guest'}), 200);
        }
        expect(request.url.path, '/v1/auth/sessions');
        expect(request.headers['Authorization'], 'Bearer new-guest');
        expect(jsonDecode(request.body), {'idToken': 'fresh-firebase'});
        return http.Response(
          jsonEncode({
            'accessToken': 'refreshed-account',
            'account': {'id': 'sedno-account', 'provider': 'apple'},
          }),
          200,
        );
      }),
    );
    repository = FirebaseAccountRepository(
      auth: auth,
      google: google,
      sessions: sessions,
      appleSignInAvailable: true,
      clearHistory: () async {},
    );
  });

  void appleAccount() {
    user.providers
      ..clear()
      ..add('apple.com');
    storage.values['account_json'] = jsonEncode({
      'id': 'sedno-account',
      'provider': 'apple',
    });
  }

  test('Apple-first user reauthenticates Apple then links Google to the same UID and account', () async {
    appleAccount();
    expect(repository.canLinkGoogle, true);
    expect(repository.canLinkApple, false);
    final account = await repository.linkGoogle();
    expect(account.id, 'sedno-account');
    expect(user.uid, 'firebase-owner');
    expect(user.providers, ['apple.com', 'google.com']);
    expect(user.reauthentications, 1);
    expect(google.authentications, 1);
    expect(repository.canLinkGoogle, false);
    expect(storage.values['installation_id'], 'original-installation');
    expect(storage.values['account_token'], 'refreshed-account');
    expect(requests, hasLength(2));
  });
  test('conflicting Google credential never merges accounts or discards the Apple session', () async {
    appleAccount();
    user.linkError = 'credential-already-in-use';
    await expectLater(
      repository.linkGoogle(),
      throwsA(isA<AccountActionException>()),
    );
    expect(user.providers, ['apple.com']);
    expect(auth.signOuts, 0);
    expect((await repository.current()).id, 'sedno-account');
    expect(storage.values['account_token'], 'existing-account');
    expect(requests, isEmpty);
  });
  test(
    'Apple reauthentication UID mismatch prevents selecting and linking Google',
    () async {
      appleAccount();
      user.returnedReauthUser = _OtherUser();
      await expectLater(
        repository.linkGoogle(),
        throwsA(isA<AccountActionException>()),
      );
      expect(google.authentications, 0);
      expect(user.links, 0);
      expect(requests, isEmpty);
      expect(storage.values['account_token'], 'existing-account');
    },
  );
  test('Google linking UID mismatch prevents backend admission', () async {
    appleAccount();
    user.returnedLinkUser = _OtherUser();
    await expectLater(
      repository.linkGoogle(),
      throwsA(isA<AccountActionException>()),
    );
    expect(requests, isEmpty);
    expect(storage.values['account_token'], 'existing-account');
  });
  test(
    'email account can link Google after password reauthentication',
    () async {
      await expectLater(
        repository.linkGoogle(),
        throwsA(isA<AccountActionException>()),
      );
      expect(google.authentications, 0);
      await repository.linkGoogle(password: 'existing-password');
      expect(user.lastCredential?.providerId, 'password');
      expect(user.providers, ['password', 'google.com']);
    },
  );
  test(
    'Google-link admission failure preserves the Apple account session',
    () async {
      appleAccount();
      backendFails = true;
      await expectLater(
        repository.linkGoogle(),
        throwsA(isA<AccountActionException>()),
      );
      expect(user.providers, ['apple.com', 'google.com']);
      expect(storage.values['account_token'], 'existing-account');
      expect(auth.signOuts, 0);
    },
  );

  test('email linking reauthenticates before linking and keeps the same backend account', () async {
    expect(repository.canLinkApple, isTrue);
    final account = await repository.linkApple(password: 'current-password');
    expect(account.id, 'sedno-account');
    expect(user.lastCredential?.providerId, 'password');
    expect(user.uid, 'firebase-owner');
    expect(google.authentications, 0);
    expect(repository.canLinkApple, isFalse);
    expect(storage.values['installation_id'], 'original-installation');
    expect(storage.values['account_token'], 'refreshed-account');
    expect(requests, hasLength(2));
  });
  test(
    'Google linking reauthenticates Google without creating a Firebase user',
    () async {
      user.providers
        ..clear()
        ..add('google.com');
      storage.values['account_json'] = jsonEncode({
        'id': 'sedno-account',
        'provider': 'google',
      });
      await repository.linkApple();
      expect(user.lastCredential?.providerId, 'google.com');
      expect(google.authentications, 1);
      expect(user.links, 1);
    },
  );
  test('email linking requires a password and never starts Apple or backend calls without it', () async {
    await expectLater(
      repository.linkApple(),
      throwsA(isA<AccountActionException>()),
    );
    expect(user.reauthentications, 0);
    expect(user.links, 0);
    expect(requests, isEmpty);
  });
  test(
    'choosing a different reauthentication identity never links Apple',
    () async {
      user.returnedReauthUser = _OtherUser();
      await expectLater(
        repository.linkApple(password: 'password'),
        throwsA(isA<AccountActionException>()),
      );
      expect(user.links, 0);
      expect(requests, isEmpty);
      expect((await repository.current()).id, 'sedno-account');
      expect(auth.signOuts, 0);
    },
  );
  test('Apple credential belonging to another Firebase user is not merged or signed in', () async {
    user.linkError = 'credential-already-in-use';
    await expectLater(
      repository.linkApple(password: 'password'),
      throwsA(isA<AccountActionException>()),
    );
    expect(requests, isEmpty);
    expect((await repository.current()).id, 'sedno-account');
    expect(storage.values['account_token'], 'existing-account');
    expect(auth.signOuts, 0);
    expect(user.providers, ['password']);
  });
  test(
    'backend admission failure preserves the existing signed-in session',
    () async {
      backendFails = true;
      await expectLater(
        repository.linkApple(password: 'password'),
        throwsA(isA<AccountActionException>()),
      );
      expect(user.providers, contains('apple.com'));
      expect((await repository.current()).id, 'sedno-account');
      expect(storage.values['account_token'], 'existing-account');
      expect(auth.signOuts, 0);
    },
  );
  test('disabled Apple linking cannot start an operation', () async {
    repository = FirebaseAccountRepository(
      auth: auth,
      google: google,
      sessions: sessions,
      clearHistory: () async {},
    );
    expect(repository.canLinkApple, false);
    await expectLater(
      repository.linkApple(password: 'password'),
      throwsA(isA<AccountActionException>()),
    );
    expect(requests, isEmpty);
  });
}
