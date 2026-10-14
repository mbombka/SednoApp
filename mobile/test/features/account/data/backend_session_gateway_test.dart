import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simplifier_app/features/account/data/backend_session_gateway.dart';
import 'package:simplifier_app/features/account/domain/account.dart';

class MemorySessionStorage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class CapturingIntegrity implements IntegrityTokenSource {
  String? hash;
  @override
  Future<String?> tokenFor(String requestHash) async {
    hash = requestHash;
    return 'integrity';
  }
}

void main() {
  test('guest session binds integrity hash and account exchange revokes local guest token', () async {
    final storage = MemorySessionStorage();
    final integrity = CapturingIntegrity();
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/v1/guest-sessions') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['integrityToken'], 'integrity');
        final expected = base64UrlEncode(
          sha256
              .convert(utf8.encode('guest-session:${body['installationId']}'))
              .bytes,
        ).replaceAll('=', '');
        expect(integrity.hash, expected);
        return http.Response(jsonEncode({'accessToken': 'guest-bearer'}), 200);
      }
      if (request.url.path == '/v1/auth/sessions') {
        expect(request.headers['authorization'], 'Bearer guest-bearer');
        expect(
          (jsonDecode(request.body) as Map<String, dynamic>)['idToken'],
          'firebase-token',
        );
        return http.Response(
          jsonEncode({
            'accessToken': 'account-bearer',
            'account': {'id': 'account-id', 'provider': 'google'},
            'quota': {'used': 1, 'remaining': 1},
          }),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer account-bearer');
      return http.Response('', 204);
    });
    final gateway = BackendSessionGateway(
      baseUrl: Uri.parse('https://api.example.test'),
      client: client,
      storage: storage,
      integrity: integrity,
    );
    final account = await gateway.link('firebase-token');
    expect(account.provider, IdentityProvider.google);
    expect(storage.values.containsKey('guest_token'), isFalse);
    expect((await gateway.savedAccount())?.id, 'account-id');
    await gateway.signOut();
    expect(await gateway.savedAccount(), isNull);
    expect(paths, [
      '/v1/guest-sessions',
      '/v1/auth/sessions',
      '/v1/auth/sign-out',
    ]);
  });

  test(
    'rejected identity leaves guest usage session available for retry',
    () async {
      final storage = MemorySessionStorage();
      storage.values['guest_token'] = 'existing-guest';
      final gateway = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((request) async => http.Response('', 401)),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      await expectLater(gateway.link('forged'), throwsStateError);
      expect(storage.values['guest_token'], 'existing-guest');
      expect(await gateway.savedAccount(), isNull);
    },
  );
}
