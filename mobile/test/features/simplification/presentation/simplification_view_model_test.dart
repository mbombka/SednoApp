import 'dart:async';

import 'package:sedno_app/features/simplification/domain/text_mode.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';
import 'package:sedno_app/features/simplification/presentation/simplification_view_model.dart';

class FakeSimplificationRepository implements SimplificationRepository {
  FakeSimplificationRepository(this.respond);
  final Future<SimplificationResponse> Function(SimplificationRequest) respond;
  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) =>
      respond(request);
}

SimplificationResponse response(String id) => SimplificationResponse(
  result: SimplificationResult(
    id: id,
    text: 'Prosty tekst',
    createdAt: DateTime.utc(2026, 10, 14),
  ),
  quota: QuotaState(
    tier: QuotaTier.free,
    limit: 5,
    used: 1,
    remaining: 4,
    serverTime: DateTime.utc(2026, 10, 14),
    resetAt: DateTime.utc(2026, 10, 15),
  ),
);

void main() {
  test(
    'mode change after failure creates a new id; same mode reuses it',
    () async {
      final sent = <SimplificationRequest>[];
      var serial = 0;
      final model = SimplificationViewModel(
        newRequestId: () => 'request-${++serial}',
        repository: FakeSimplificationRepository((request) async {
          sent.add(request);
          if (sent.length < 3) throw StateError('offline');
          return response(request.requestId);
        }),
      );
      final input = InputText('Tekst');
      await expectLater(model.simplify(input), throwsStateError);
      await expectLater(
        model.simplify(input, mode: TextMode.correct),
        throwsStateError,
      );
      final result = await model.simplify(input, mode: TextMode.correct);
      expect(sent.map((r) => r.requestId), [
        'request-1',
        'request-2',
        'request-2',
      ]);
      expect(sent.last.toJson()['mode'], 'correct');
      expect(result.mode, TextMode.correct);
      expect(
        SimplificationResult.fromJson(result.toJson()).mode,
        TextMode.correct,
      );
      expect(
        SimplificationResult.fromJson(response('old').result.toJson()).mode,
        TextMode.simplify,
      );
    },
  );

  test('returns repository result and uses a new id after success', () async {
    final ids = <String>[];
    var serial = 0;
    final model = SimplificationViewModel(
      repository: FakeSimplificationRepository((request) async {
        ids.add(request.requestId);
        return response(request.requestId);
      }),
      newRequestId: () => 'request-${++serial}',
    );

    expect((await model.simplify(InputText('Tekst'))).text, 'Prosty tekst');
    await model.simplify(InputText('Tekst'));
    expect(ids, ['request-1', 'request-2']);
  });

  test('timeout and backend error preserve id on retry', () async {
    final ids = <String>[];
    var calls = 0;
    final model = SimplificationViewModel(
      repository: FakeSimplificationRepository((request) {
        ids.add(request.requestId);
        calls++;
        if (calls == 1) return Completer<SimplificationResponse>().future;
        if (calls == 2) throw StateError('server detail');
        return Future.value(response(request.requestId));
      }),
      timeout: const Duration(milliseconds: 1),
      newRequestId: () => 'same-id',
    );

    await expectLater(
      model.simplify(InputText('Tekst')),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(model.simplify(InputText('Tekst')), throwsStateError);
    expect((await model.simplify(InputText('Tekst'))).text, 'Prosty tekst');
    expect(ids, ['same-id', 'same-id', 'same-id']);
  });

  test('same text after a lost result sends a new request once', () async {
    final ids = <String>[];
    var serial = 0;
    var calls = 0;
    final model = SimplificationViewModel(
      repository: FakeSimplificationRepository((request) {
        ids.add(request.requestId);
        calls++;
        // 1: app stops waiting; 2: backend finished it but kept no result.
        if (calls == 1) return Completer<SimplificationResponse>().future;
        if (calls == 2) throw const SimplificationRequestClosedException();
        return Future.value(response(request.requestId));
      }),
      timeout: const Duration(milliseconds: 1),
      newRequestId: () => 'request-${++serial}',
    );

    await expectLater(
      model.simplify(InputText('Tekst')),
      throwsA(isA<TimeoutException>()),
    );
    expect((await model.simplify(InputText('Tekst'))).text, 'Prosty tekst');
    expect(ids, ['request-1', 'request-1', 'request-2']);
  });
}
