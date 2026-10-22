import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sedno_app/features/simplification/domain/text_mode.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/simplification/data/http_simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class _MemoryStorage implements SessionStorage {
  final values = <String, String>{'guest_token': 'test-bearer'};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _NoIntegrity implements IntegrityTokenSource {
  @override
  Future<String?> tokenFor(String hash) async => null;
}

class _AbortClient extends http.BaseClient {
  int calls = 0;
  final aborted = Completer<void>();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    final abortable = request as http.AbortableRequest;
    await abortable.abortTrigger;
    aborted.complete();
    throw http.RequestAbortedException(request.url);
  }
}

final _url = Uri.parse('https://api.example.test');

HttpSimplificationRepository _repository(
  http.Client client, {
  int attempts = 3,
}) {
  return HttpSimplificationRepository(
    baseUrl: _url,
    client: client,
    sessions: BackendSessionGateway(
      baseUrl: _url,
      client: client,
      storage: _MemoryStorage(),
      integrity: _NoIntegrity(),
    ),
    requestTimeout: const Duration(milliseconds: 10),
    retryDelay: Duration.zero,
    maxAttempts: attempts,
    wait: (_) async {},
  );
}

Map<String, Object?> _quota(
  int used, {
  int? remaining,
  String day = '2026-10-14',
}) => {
  'tier': 'free',
  'limit': 5,
  'used': used,
  'remaining': remaining ?? 5 - used,
  'serverTime': '${day}T12:00:00Z',
  'resetAt': day == '2026-10-14'
      ? '2026-10-15T00:00:00Z'
      : '2026-10-16T00:00:00Z',
};

http.Response _success(String id, int used) => http.Response(
  jsonEncode({
    'result': {
      'id': id,
      'text': 'Prosty tekst',
      'createdAt': '2026-10-14T12:00:00Z',
    },
    'quota': _quota(used),
  }),
  200,
);

SimplificationRequest _request(String id) =>
    SimplificationRequest(input: InputText('Trudny tekst'), requestId: id);

void main() {
  for (final supportsCorrection in [true, false]) {
    test(
      'correction is sent and requires backend mode confirmation: $supportsCorrection',
      () async {
        final repo = _repository(
          MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['mode'], 'correct');
            final result = jsonDecode(
              _success('correct-id', 1).body,
            ) as Map<String, dynamic>;
            if (supportsCorrection) result['result']['mode'] = 'correct';
            return http.Response(jsonEncode(result), 200);
          }),
        );
        final future = repo.simplify(
          SimplificationRequest(
            input: InputText('Tekst'),
            requestId: 'correct-id',
            mode: TextMode.correct,
          ),
        );
        if (supportsCorrection) {
          expect((await future).result.mode, TextMode.correct);
        } else {
          await expectLater(
            future,
            throwsA(
              isA<SimplificationApiException>().having(
                (e) => e.kind,
                'kind',
                SimplificationFailure.rejected,
              ),
            ),
          );
        }
      },
    );
  }

  test(
    'deadline aborts the HTTP request and does not launch another attempt',
    () async {
      final client = _AbortClient();
      final repo = _repository(client);
      await expectLater(
        repo.simplify(_request('abort')),
        throwsA(
          isA<SimplificationApiException>().having(
            (e) => e.kind,
            'kind',
            SimplificationFailure.timeout,
          ),
        ),
      );
      await client.aborted.future;
      await Future<void>.delayed(Duration.zero);
      expect(client.calls, 1);
      expect(repo.quotaListenable.value, isNull);
    },
  );

  test('server 504 is terminal and a late result cannot update quota after timeout', () async {
    var calls = 0;
    final failed = _repository(
      MockClient((_) async {
        calls++;
        return http.Response('{"code":"simplification_timeout"}', 504);
      }),
    );
    await expectLater(
      failed.simplify(_request('server-timeout')),
      throwsA(
        isA<SimplificationApiException>().having(
          (e) => e.kind,
          'kind',
          SimplificationFailure.timeout,
        ),
      ),
    );
    expect(calls, 1);
    final pending = Completer<http.Response>();
    final late = _repository(MockClient((_) => pending.future));
    await expectLater(
      late.simplify(_request('late')),
      throwsA(isA<SimplificationApiException>()),
    );
    pending.complete(_success('late', 1));
    await Future<void>.delayed(Duration.zero);
    expect(late.quotaListenable.value, isNull);
  });

  test(
    'reads ASP.NET UTC offsets in quota and simplification result',
    () async {
      final quota = {
        ..._quota(0),
        'serverTime': '2026-10-14T12:00:00.4732661+00:00',
        'resetAt': '2026-10-15T00:00:00+00:00',
      };
      final repo = _repository(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode(quota), 200);
          }
          return http.Response(
            jsonEncode({
              'result': {
                'id': 'offset-test',
                'text': 'Prosty tekst',
                'createdAt': '2026-10-14T12:00:01.1234567+00:00',
              },
              'quota': {...quota, 'used': 1, 'remaining': 4},
            }),
            200,
          );
        }),
      );
      final current = await repo.current();
      expect(current.remaining, 5);
      expect(current.serverTime.isUtc, isTrue);
      expect(current.resetAt, DateTime.utc(2026, 10, 15));
      final result = await repo.simplify(_request('offset-test'));
      expect(result.result.text, 'Prosty tekst');
      expect(result.result.createdAt.isUtc, isTrue);
      expect(repo.quotaListenable.value!.remaining, 4);
    },
  );

  test('session deletion stops retries from resending the old text', () async {
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode(_quota(0)), 200);
      }
      posts++;
      return http.Response('', 503);
    });
    final sessions = BackendSessionGateway(
      baseUrl: _url,
      client: client,
      storage: _MemoryStorage(),
      integrity: _NoIntegrity(),
    );
    final repo = HttpSimplificationRepository(
      baseUrl: _url,
      client: client,
      sessions: sessions,
      wait: (_) async {
        sessions.sessionRevision.value++;
      },
    );
    await expectLater(
      repo.simplify(_request('delete-in-flight')),
      throwsA(
        isA<SimplificationApiException>().having(
          (error) => error.kind,
          'kind',
          SimplificationFailure.unauthorized,
        ),
      ),
    );
    expect(posts, 1);
  });

  test('uses server quota for 5 to 0 and next UTC day reset', () async {
    var used = 0;
    var nextDay = false;
    final repo = _repository(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-bearer');
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(nextDay ? _quota(0, day: '2026-10-15') : _quota(used)),
            200,
          );
        }
        used++;
        return _success(
          (jsonDecode(request.body) as Map<String, dynamic>)['requestId']
              as String,
          used,
        );
      }),
    );
    expect((await repo.current()).remaining, 5);
    expect(repo.quotaListenable.value!.remaining, 5);
    for (var i = 1; i <= 5; i++) {
      await repo.simplify(_request('request-$i'));
      expect(repo.quotaListenable.value!.remaining, 5 - i);
    }
    nextDay = true;
    expect((await repo.current()).remaining, 5);
    expect(repo.quotaListenable.value!.resetAt, DateTime.utc(2026, 10, 16));
  });

  test('202 retries keep one key and one quota charge', () async {
    var calls = 0;
    var charges = 0;
    final ids = <String>[];
    final repo = _repository(
      MockClient((request) async {
        calls++;
        final id =
            (jsonDecode(request.body) as Map<String, dynamic>)['requestId']
                as String;
        ids.add(id);
        if (calls < 3) {
          return http.Response(
            jsonEncode({
              'status': 'processing',
              'quota': _quota(0, remaining: 4),
            }),
            202,
          );
        }
        charges++;
        return _success(id, 1);
      }),
    );
    final result = await repo.simplify(_request('same-key'));
    expect(result.result.text, 'Prosty tekst');
    expect(ids, ['same-key', 'same-key', 'same-key']);
    expect(charges, 1);
    expect(repo.quotaListenable.value!.remaining, 4);
  });

  test('offline and repeated timeout surface typed failures', () async {
    final offline = _repository(
      MockClient((_) async => throw const SocketException('offline')),
    );
    await expectLater(
      offline.simplify(_request('one')),
      throwsA(
        isA<SimplificationApiException>().having(
          (e) => e.kind,
          'kind',
          SimplificationFailure.offline,
        ),
      ),
    );
    final timeout = _repository(
      MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      timeout.simplify(_request('two')),
      throwsA(
        isA<SimplificationApiException>().having(
          (e) => e.kind,
          'kind',
          SimplificationFailure.timeout,
        ),
      ),
    );
  });

  test('401 is terminal, 429 publishes quota, 5xx retries same key', () async {
    var calls = 0;
    final unauthorized = _repository(
      MockClient((_) async {
        calls++;
        return http.Response('{}', 401);
      }),
    );
    await expectLater(
      unauthorized.simplify(_request('auth')),
      throwsA(
        isA<SimplificationApiException>().having(
          (e) => e.kind,
          'kind',
          SimplificationFailure.unauthorized,
        ),
      ),
    );
    expect(calls, 1);

    final limited = _repository(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'quota_exceeded', 'quota': _quota(5)}),
          429,
        ),
      ),
    );
    await expectLater(
      limited.simplify(_request('limit')),
      throwsA(
        isA<SimplificationApiException>().having(
          (e) => e.kind,
          'kind',
          SimplificationFailure.rateLimited,
        ),
      ),
    );
    expect(limited.quotaListenable.value!.remaining, 0);

    final ids = <String>[];
    final unavailable = _repository(
      MockClient((request) async {
        ids.add(
          (jsonDecode(request.body) as Map<String, dynamic>)['requestId']
              as String,
        );
        return ids.length < 3 ? http.Response('{}', 503) : _success('retry', 1);
      }),
    );
    await unavailable.simplify(_request('retry'));
    expect(ids, ['retry', 'retry', 'retry']);
  });

  test(
    'lost successful result is reported as closed without a new request',
    () async {
      var charges = 0;
      final repo = _repository(
        MockClient((request) async {
          final id =
              (jsonDecode(request.body) as Map<String, dynamic>)['requestId']
                  as String;
          expect(id, 'lost');
          if (charges++ == 0) return http.Response('{}', 503);
          return http.Response(jsonEncode({'code': 'result_unavailable'}), 409);
        }),
      );
      await expectLater(
        repo.simplify(_request('lost')),
        throwsA(isA<SimplificationRequestClosedException>()),
      );
      expect(charges, 2);
    },
  );
}
