import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/data/firebase_account_repository.dart';
import 'package:sedno_app/features/account/domain/account.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;
import 'firebase_account_deletion_test.dart'
    show FakeAuth, FakeGoogle, DeletionUser, DeletionProvider;

class AppleProvider implements firebase.UserInfo {
  @override
  String get providerId => 'apple.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AppleCredential implements firebase.UserCredential {
  AppleCredential({this.accessToken = 'apple-access-token'});
  final String? accessToken;
  @override
  firebase.AuthCredential? get credential =>
      firebase.OAuthProvider('apple.com').credential(accessToken: accessToken);
  @override
  firebase.AdditionalUserInfo? get additionalUserInfo => AppleAdditionalInfo();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AppleAdditionalInfo implements firebase.AdditionalUserInfo {
  @override
  String? get authorizationCode => 'apple-authorization-code';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AppleUser extends DeletionUser {
  String? accessToken = 'apple-access-token';
  @override
  List<firebase.UserInfo> get providerData => [AppleProvider()];
  @override
  Future<firebase.UserCredential> reauthenticateWithProvider(
    firebase.AuthProvider provider,
  ) async {
    expect(provider.providerId, 'apple.com');
    reauthentications++;
    return AppleCredential(accessToken: accessToken);
  }
}

class LinkedAppleUser extends AppleUser {
  @override
  List<firebase.UserInfo> get providerData => [
    AppleProvider(),
    DeletionProvider(),
  ];
}

class GoogleProvider extends AppleProvider {
  @override
  String get providerId => 'google.com';
}

class LinkedGoogleAppleUser extends AppleUser {
  @override
  List<firebase.UserInfo> get providerData => [
    AppleProvider(),
    GoogleProvider(),
  ];
}

class AppleAuth extends FakeAuth {
  String? revokedCode;
  String? revokedAccessToken;
  @override
  Future<void> revokeAccessToken(String token) async {
    revokedAccessToken = token;
  }

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    revokedCode = code;
  }
}

void main() {
  test(
    'Apple account representation round-trips without a disclosed email',
    () {
      expect(
        Account.fromJson(
          Account(id: 'apple-user', provider: IdentityProvider.apple).toJson(),
        ).provider,
        IdentityProvider.apple,
      );
    },
  );
  test('Apple deletion reauthenticates and revokes Apple before deleting backend data', () async {
    final auth = AppleAuth()..user = AppleUser();
    final google = FakeGoogle();
    final storage = MemorySessionStorage()..values['account_token'] = 'account';
    var deleted = false;
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: google,
      appleSignInAvailable: true,
      platform: TargetPlatform.iOS,
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient((request) async {
          expect(auth.revokedCode, 'apple-authorization-code');
          expect(request.method, 'DELETE');
          deleted = true;
          return http.Response('', 204);
        }),
      ),
      clearHistory: () async {},
    );
    await repository.deleteAccount();
    expect(deleted, true);
    expect(google.authentications, 0);
    expect(await repository.current(), isA<Account>());
  });
  test('linked email account revokes Apple instead of only reauthenticating a password', () async {
    final auth = AppleAuth()..user = LinkedAppleUser();
    var deleted = false;
    final storage = MemorySessionStorage()..values['account_token'] = 'account';
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: FakeGoogle(),
      appleSignInAvailable: true,
      platform: TargetPlatform.iOS,
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient((request) async {
          expect(auth.revokedCode, 'apple-authorization-code');
          deleted = true;
          return http.Response('', 204);
        }),
      ),
      clearHistory: () async {},
    );
    await repository
        .deleteAccount(); // no password: Apple reauthentication is mandatory
    expect(deleted, true);
  });
  test('Android Apple-linked Google account revokes access token and never invokes Apple-only authorization-code API', () async {
    final auth = AppleAuth()..user = LinkedGoogleAppleUser();
    final storage = MemorySessionStorage()..values['account_token'] = 'account';
    var deleted = false;
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: FakeGoogle(),
      platform: TargetPlatform.android,
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient((request) async {
          expect(auth.revokedAccessToken, 'apple-access-token');
          expect(auth.revokedCode, isNull);
          expect(request.method, 'DELETE');
          deleted = true;
          return http.Response('', 204);
        }),
      ),
      clearHistory: () async {},
    );
    await repository.deleteAccount();
    expect(deleted, true);
    expect(auth.revokedCode, isNull);
  });
  test('missing Apple access token on Android prevents backend deletion and retains the account', () async {
    final auth = AppleAuth()
      ..user = (LinkedGoogleAppleUser()..accessToken = null);
    final storage = MemorySessionStorage()..values['account_token'] = 'account';
    var cleared = false;
    final repository = FirebaseAccountRepository(
      auth: auth,
      google: FakeGoogle(),
      platform: TargetPlatform.android,
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient(
          (request) async =>
              throw StateError('No deletion before successful revocation'),
        ),
      ),
      clearHistory: () async {
        cleared = true;
      },
    );
    await expectLater(
      repository.deleteAccount(),
      throwsA(isA<AccountActionException>()),
    );
    expect(auth.revokedCode, isNull);
    expect(auth.revokedAccessToken, isNull);
    expect(storage.values['account_token'], 'account');
    expect(auth.signOuts, 0);
    expect(cleared, false);
  });
}
