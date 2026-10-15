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
  resultUnavailable,
  rejected,
}

class SimplificationApiException implements Exception {
  const SimplificationApiException(this.kind);
  final SimplificationFailure kind;
}

/// All quota values come from the backend. Retries reuse the request's key;
/// a completed response that was lost cannot be recovered by this API.
class HttpSimplificationRepository
    implements SimplificationRepository, QuotaStateSource {
  HttpSimplificationRepository({
    required this.baseUrl,
    required this.client,
    required this.sessions,
    this.requestTimeout = const Duration(seconds: 8),
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
    unawaited(current().then<void>((_) {}, onError: (Object _) {}));
  }

  @override
  ValueListenable<QuotaState?> get quotaListenable => _quota;

  @override
  Future<QuotaState> current() async {
    final response = await _send('GET', '/v1/quota');
    if (response.statusCode != 200) throw _failure(response);
    final quota = QuotaState.fromJson(_object(response.body));
    _quota.value = quota;
    return quota;
  }

  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) async {
    final revision = sessions.sessionRevision.value;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _requireSession(revision);
        final response = await _send(
          'POST',
          '/v1/simplifications',
          body: jsonEncode(request.toJson()),
          sessionRevision: revision,
        );
        _requireSession(revision);
        if (response.statusCode == 200) {
          final value = SimplificationResponse.fromJson(_object(response.body));
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
        if (attempt == maxAttempts) {
          throw const SimplificationApiException(SimplificationFailure.timeout);
        }
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
  }) async {
    final token = await sessions.accessToken().timeout(requestTimeout);
    if (sessionRevision != null) _requireSession(sessionRevision);
    final url = baseUrl.resolve(path);
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (body != null) headers['Content-Type'] = 'application/json';
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

  SimplificationApiException _failure(http.Response response) {
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
        if (_object(response.body)['code'] == 'result_unavailable') {
          return const SimplificationApiException(
            SimplificationFailure.resultUnavailable,
          );
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
