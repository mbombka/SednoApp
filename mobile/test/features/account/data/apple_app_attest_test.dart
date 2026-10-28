import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/apple_app_attest.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedno/app_attest');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('expired key rotates once automatically while retaining installation and quota identity', () async {
    final oldKey = base64Encode(List.filled(32, 1));
    final newKey = base64Encode(List.filled(32, 2));
    final storage = MemorySessionStorage()
      ..values.addAll({
        'installation_id': 'retained-installation=',
        'app_attest_key_id': oldKey,
        'app_attest_registered': oldKey,
      });
    var generated = 0;
    var admissions = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'isSupported' => true,
        'generateKey' => () {
          generated++;
          return newKey;
        }(),
        'attestKey' => 'new-attestation',
        'generateAssertion' => 'assertion',
        _ => throw MissingPluginException(),
      };
    });
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['installationId'], 'retained-installation=');
      if (request.url.path.endsWith('/challenges')) {
        return http.Response('{"challengeId":"id","challenge":"random"}', 200);
      }
      if (request.url.path.endsWith('/keys')) return http.Response('', 204);
      admissions++;
      return body['keyId'] == oldKey
          ? http.Response('{"code":"app_attest_key_unknown"}', 403)
          : http.Response('{"accessToken":"guest"}', 200);
    });
    final gateway = BackendSessionGateway(
      baseUrl: Uri.parse('https://api.test'),
      client: client,
      storage: storage,
      integrity: CapturingIntegrity(),
      guestAdmission: AppleAppAttestAdmission(
        baseUrl: Uri.parse('https://api.test'),
        client: client,
        storage: storage,
      ),
    );
    expect(await gateway.accessToken(), 'guest');
    expect(generated, 1);
    expect(admissions, 2);
    expect(storage.values['installation_id'], 'retained-installation=');
  });

  test('registration retries exact proof after response loss without resetting installation', () async {
    final storage = MemorySessionStorage();
    var attestations = 0;
    var registrations = 0;
    String? firstProof;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'generateKey':
          return base64Encode(List.filled(32, 1));
        case 'attestKey':
          attestations++;
          return 'attestation';
        case 'generateAssertion':
          return 'assertion';
        default:
          throw MissingPluginException();
      }
    });
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['installationId'], 'same-installation');
      if (request.url.path.endsWith('/challenges')) {
        return http.Response(
          jsonEncode({'challengeId': 'challenge-id', 'challenge': 'random'}),
          200,
        );
      }
      if (request.url.path.endsWith('/keys')) {
        registrations++;
        if (registrations == 1) {
          firstProof = request.body;
          throw http.ClientException('response lost');
        }
        expect(request.body, firstProof);
        return http.Response('', 204);
      }
      expect(request.url.path, '/v1/ios/guest-sessions');
      return http.Response('{"accessToken":"guest"}', 200);
    });
    final admission = AppleAppAttestAdmission(
      baseUrl: Uri.parse('https://api.test'),
      client: client,
      storage: storage,
    );
    await expectLater(
      admission.create('same-installation'),
      throwsA(isA<http.ClientException>()),
    );
    expect((await admission.create('same-installation')).statusCode, 200);
    expect(attestations, 1);
    expect(registrations, 2);
    expect(
      storage.values.containsKey('app_attest_pending_registration'),
      false,
    );
  });

  test(
    'unsupported hardware never requests a session or falls back to Play',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => false);
      final storage = MemorySessionStorage();
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('', 200);
      });
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        client: client,
        storage: storage,
        integrity: CapturingIntegrity(),
        guestAdmission: AppleAppAttestAdmission(
          baseUrl: Uri.parse('https://api.test'),
          client: client,
          storage: storage,
        ),
      );
      await expectLater(sessions.accessToken(), throwsStateError);
      expect(requests, 0);
      expect(storage.values['installation_id'], isNotEmpty);
      expect(storage.values['guest_token'], null);
    },
  );

  test(
    'concurrent admission creates one installation and guest session',
    () async {
      final storage = MemorySessionStorage();
      var calls = 0;
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.test'),
        client: MockClient((_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return http.Response('{"accessToken":"guest"}', 200);
        }),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      expect(
        await Future.wait(List.generate(10, (_) => sessions.accessToken())),
        everyElement('guest'),
      );
      expect(calls, 1);
    },
  );
}
