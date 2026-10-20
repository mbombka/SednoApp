import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

enum SimplificationFailure {
  offline,
  timeout,
  unauthorized,
  rateLimited,
  unavailable,
  rejected,
}

class SimplificationApiException implements Exception {
  const SimplificationApiException(this.kind);
  final SimplificationFailure kind;
}

/// All quota values come from the backend. Retries reuse the request's key;
/// a completed response that was lost cannot be recovered by this API, so it
/// is reported as a closed request and the caller may send a new one.
class HttpSimplificationRepository
    implements SimplificationRepository, QuotaStateSource {
  HttpSimplificationRepository({
    required this.baseUrl,
    required this.client,
    required this.sessions,
    // Covers a Cloud Run cold start (~7 s) plus the server's 9 s deadline.
    this.requestTimeout = const Duration(seconds: 20),
    this.retryDelay = const Duration(milliseconds: 250),
    this.maxAttempts = 3,
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed {
    if (baseUrl.scheme != 'https' &&
        (kReleaseMode ||
            baseUrl.scheme != 'http' ||
            !{'localhost', '127.0.0.1', '10.0.2.2'}.contains(baseUrl.host))) {
      throw ArgumentError('Wymagany jest adres HTTPS.');
    }
    if (maxAttempts < 1) throw ArgumentError.value(maxAttempts, 'maxAttempts');
    sessions.sessionRevision.addListener(_refreshAfterSessionChange);
    sessions.quotaRevision.addListener(_refreshQuota);
  }

  final Uri baseUrl;
  final http.Client client;
  final BackendSessionGateway sessions;
  final Duration requestTimeout;
  final Duration retryDelay;
  final int maxAttempts;
  final Future<void> Function(Duration) _wait;
  final ValueNotifier<QuotaState?> _quota = ValueNotifier(null);

  void _refreshAfterSessionChange() {
    _quota.value = null;
    _refreshQuota();
  }

  void _refreshQuota() {
    unawaited(current().then<void>((_) {}, onError: (Object _) {}));
  }

  int _quotaRequest = 0;

  @override
  ValueListenable<QuotaState?> get quotaListenable => _quota;

  @override
  Future<QuotaState> current() async {
    final revision = sessions.sessionRevision.value;
    final request = ++_quotaRequest;
    final response = await _send('GET', '/v1/quota', sessionRevision: revision);
    _requireSession(revision);
    if (response.statusCode != 200) throw _failure(response);
    final quota = QuotaState.fromJson(_object(response.body));
    if (request == _quotaRequest) _quota.value = quota;
    return quota;
  }

  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) async {
    final abort = Completer<void>();
    try {
      return await _simplify(request, abort).timeout(
        requestTimeout,
        onTimeout: () {
          if (!abort.isCompleted) abort.complete();
          throw const SimplificationApiException(SimplificationFailure.timeout);
        },
      );
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<SimplificationResponse> _simplify(
    SimplificationRequest request,
    Completer<void> abort,
  ) async {
    final revision = sessions.sessionRevision.value;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (abort.isCompleted) {
          throw const SimplificationApiException(SimplificationFailure.timeout);
        }
        _requireSession(revision);
        final response = await _send(
          'POST',
          '/v1/simplifications',
          body: jsonEncode(request.toJson()),
          sessionRevision: revision,
          abortTrigger: abort.future,
        );
        if (abort.isCompleted) {
          throw const SimplificationApiException(SimplificationFailure.timeout);
        }
        _requireSession(revision);
        if (response.statusCode == 200) {
          final value = SimplificationResponse.fromJson(_object(response.body));
          _quotaRequest++;
          _quota.value = value.quota;
          return value;
        }
        if (response.statusCode == 202) {
          _readQuota(response.body);
          if (attempt < maxAttempts) {
            await _wait(retryDelay * attempt);
            continue;
          }
          throw const SimplificationApiException(
            SimplificationFailure.unavailable,
          );
        }
        if (response.statusCode == 429) _readQuota(response.body);
        if (response.statusCode == 504) throw _failure(response);
        if (response.statusCode >= 500 && attempt < maxAttempts) {
          await _wait(retryDelay * attempt);
          continue;
        }
        throw _failure(response);
      } on SocketException {
        if (attempt == maxAttempts) {
          throw const SimplificationApiException(SimplificationFailure.offline);
        }
      } on http.ClientException {
        if (attempt == maxAttempts) {
          throw const SimplificationApiException(SimplificationFailure.offline);
        }
      } on TimeoutException {
        if (!abort.isCompleted) abort.complete();
        throw const SimplificationApiException(SimplificationFailure.timeout);
      }
      if (abort.isCompleted) {
        throw const SimplificationApiException(SimplificationFailure.timeout);
      }
      await _wait(retryDelay * attempt);
    }
    throw const SimplificationApiException(SimplificationFailure.unavailable);
  }

  void _requireSession(int revision) {
    if (sessions.sessionRevision.value != revision) {
      throw const SimplificationApiException(
        SimplificationFailure.unauthorized,
      );
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    int? sessionRevision,
    Future<void>? abortTrigger,
  }) async {
    final token = await sessions.accessToken().timeout(requestTimeout);
    if (sessionRevision != null) _requireSession(sessionRevision);
    final url = baseUrl.resolve(path);
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (abortTrigger != null) {
      final request = http.AbortableRequest(
        method,
        url,
        abortTrigger: abortTrigger,
      );
      request.headers.addAll(headers);
      if (body != null) request.body = body;
      return http.Response.fromStream(await client.send(request));
    }
    return (method == 'GET'
            ? client.get(url, headers: headers)
            : client.post(url, headers: headers, body: body))
        .timeout(requestTimeout);
  }

  void _readQuota(String body) {
    try {
      final value = _object(body)['quota'];
      if (value is Map<String, dynamic>) {
        _quota.value = QuotaState.fromJson(value);
      }
    } on FormatException {
      // Invalid problem data must not replace the last trusted quota.
    }
  }

  Exception _failure(http.Response response) {
    if (response.statusCode == 504) {
      return const SimplificationApiException(SimplificationFailure.timeout);
    }
    if (response.statusCode == 401) {
      return const SimplificationApiException(
        SimplificationFailure.unauthorized,
      );
    }
    if (response.statusCode == 429) {
      return const SimplificationApiException(
        SimplificationFailure.rateLimited,
      );
    }
    if (response.statusCode == 409) {
      try {
        final code = _object(response.body)['code'];
        if (code == 'request_failed' ||
            code == 'reservation_expired' ||
            code == 'result_unavailable') {
          return const SimplificationRequestClosedException();
        }
      } on FormatException {
        // A malformed error is still a terminal response.
      }
    }
    if (response.statusCode >= 500) {
      return const SimplificationApiException(
        SimplificationFailure.unavailable,
      );
    }
    return const SimplificationApiException(SimplificationFailure.rejected);
  }

  Map<String, dynamic> _object(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowa odpowiedź serwera.');
    }
    return decoded;
  }
}
