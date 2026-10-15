import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';

import 'backend_session_gateway_test.dart'
    show MemorySessionStorage, CapturingIntegrity;

void main() {
  test(
    'deletion uses account bearer; cleanup can resume after a local failure',
    () async {
      final storage = MemorySessionStorage();
      storage.values.addAll({
        'account_token': 'owner',
        'account_json': '{}',
        'guest_token': 'old',
        'installation_id': 'installation',
      });
      var calls = 0;
      final gateway = BackendSessionGateway(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'DELETE');
          expect(request.url.path, '/v1/account');
          expect(request.headers['authorization'], 'Bearer owner');
          expect(request.body, isEmpty);
          return http.Response('', 204);
        }),
        storage: storage,
        integrity: CapturingIntegrity(),
      );
      await gateway.deleteAccount();
      expect(await gateway.deletionPending, isTrue);
      await expectLater(gateway.accessToken(), throwsStateError);
      await gateway.deleteAccount(); // Retry does not need the revoked bearer.
      expect(calls, 1);
      await gateway.clearDeletedSession();
      expect(storage.values, {'installation_id': 'installation'});
      expect(await gateway.deletionPending, isFalse);
    },
  );

  for (final status in [401, 403, 500]) {
    test(
      'failure $status retains credentials for retry and never reports success',
      () async {
        final storage = MemorySessionStorage();
        storage.values['account_token'] = 'owner';
        final gateway = BackendSessionGateway(
          baseUrl: Uri.parse('https://api.example.test'),
          client: MockClient((_) async => http.Response('', status)),
          storage: storage,
          integrity: CapturingIntegrity(),
        );
        await expectLater(gateway.deleteAccount(), throwsStateError);
        expect(await gateway.deletionPending, isFalse);
        expect(storage.values['account_token'], 'owner');
      },
    );
  }
}
