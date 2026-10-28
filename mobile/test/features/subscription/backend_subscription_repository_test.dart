import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/subscription/data/backend_subscription_repository.dart';

import '../account/data/backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;

void main() {
  test('guest refresh does not create a session or contact billing', () async {
    final sessions = BackendSessionGateway(
      baseUrl: Uri.parse('https://sedno.test'),
      client: MockClient((_) async => throw StateError('Unexpected request')),
      storage: MemorySessionStorage(),
      integrity: CapturingIntegrity(),
    );
    final repository = BackendSubscriptionRepository(sessions);
    expect((await repository.current()).active, false);
    await expectLater(repository.verify('token'), throwsStateError);
  });

  test(
    'Apple sends transaction ID to its store-specific backend route',
    () async {
      final storage = MemorySessionStorage();
      await storage.write('account_token', 'test-bearer');
      await storage.write(
        'account_json',
        jsonEncode({'id': 'account-id', 'provider': 'apple'}),
      );
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://sedno.test'),
        storage: storage,
        integrity: CapturingIntegrity(),
        client: MockClient((request) async {
          expect(request.url.path, '/v1/subscription/apple');
          expect(jsonDecode(request.body), {'transactionId': '123'});
          return http.Response(
            jsonEncode({
              'active': true,
              'state': 'active',
              'accountBinding': 'uuid',
              'store': 'app_store',
            }),
            200,
          );
        }),
      );
      final repository = BackendSubscriptionRepository(sessions, apple: true);
      expect((await repository.verify('123')).store, 'app_store');
    },
  );

  test(
    'verification refreshes quota without changing authentication revision',
    () async {
      final storage = MemorySessionStorage();
      await storage.write('account_token', 'test-bearer');
      await storage.write(
        'account_json',
        jsonEncode({'id': 'account-id', 'provider': 'google'}),
      );
      final sessions = BackendSessionGateway(
        baseUrl: Uri.parse('https://sedno.test'),
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'active': true,
              'state': 'SUBSCRIPTION_STATE_ACTIVE',
              'accountBinding': 'binding',
            }),
            200,
          ),
        ),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      final repository = BackendSubscriptionRepository(sessions);
      expect((await repository.current()).active, true);
      expect(sessions.quotaRevision.value, 1);
      await repository.verify('token');
      expect(sessions.quotaRevision.value, 2);
      expect(sessions.sessionRevision.value, 0);
    },
  );
}
