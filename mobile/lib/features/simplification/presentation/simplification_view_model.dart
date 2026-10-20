import 'dart:async';
import 'dart:math';

import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

/// Keeps the request identifier across retries so a timed-out response cannot
/// consume a second allowance if the backend already processed it.
class SimplificationViewModel {
  SimplificationViewModel({
    required this.repository,
    this.timeout = const Duration(seconds: 10),
    String Function()? newRequestId,
  }) : _newRequestId = newRequestId ?? _randomRequestId;

  final SimplificationRepository repository;
  final Duration timeout;
  final String Function() _newRequestId;
  String? _pendingText;
  String? _pendingRequestId;

  Future<SimplificationResult> simplify(InputText input) async {
    if (_pendingText != input.value) {
      _pendingText = input.value;
      _pendingRequestId = _newRequestId();
    }
    final response = await _attempt(input).timeout(timeout);
    _pendingText = null;
    _pendingRequestId = null;
    return response.result;
  }

  Future<SimplificationResponse> _attempt(InputText input) async {
    try {
      return await repository.simplify(
        SimplificationRequest(input: input, requestId: _pendingRequestId!),
      );
    } on SimplificationRequestClosedException {
      // A timeout alone is ambiguous. Replace the id only after the backend
      // confirms the earlier attempt cannot have succeeded. Retry at most once.
      _pendingRequestId = _newRequestId();
      return repository.simplify(
        SimplificationRequest(input: input, requestId: _pendingRequestId!),
      );
    }
  }

  static String _randomRequestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
