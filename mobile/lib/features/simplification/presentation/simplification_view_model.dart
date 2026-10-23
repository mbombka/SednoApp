import 'dart:async';
import 'dart:math';

import 'package:sedno_app/features/simplification/domain/text_mode.dart';

import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

/// Keeps the request identifier across retries, so a request still processing
/// is not started twice. If the backend reports the old request as closed, the
/// same tap sends a new one; a lost successful result then uses one more allowance.
class SimplificationViewModel {
  SimplificationViewModel({
    required this.repository,
    this.timeout = const Duration(seconds: 20),
    String Function()? newRequestId,
  }) : _newRequestId = newRequestId ?? _randomRequestId;

  final SimplificationRepository repository;
  final Duration timeout;
  final String Function() _newRequestId;
  String? _pendingText;
  TextMode? _pendingMode;
  String? _pendingRequestId;

  void reset() {
    _pendingText = null;
    _pendingMode = null;
    _pendingRequestId = null;
  }

  Future<SimplificationResult> simplify(
    InputText input, {
    TextMode mode = TextMode.simplify,
  }) async {
    if (_pendingText != input.value || _pendingMode != mode) {
      _pendingText = input.value;
      _pendingMode = mode;
      _pendingRequestId = _newRequestId();
    }
    final response = await _attempt(input, mode);
    _pendingText = null;
    _pendingRequestId = null;
    final result = response.result;
    return SimplificationResult(
      id: result.id,
      text: result.text,
      createdAt: result.createdAt,
      mode: mode,
    );
  }

  Future<SimplificationResponse> _attempt(
    InputText input,
    TextMode mode,
  ) async {
    try {
      return await _send(input, mode);
    } on SimplificationRequestClosedException {
      // A timeout alone is ambiguous. Replace the id only after the backend
      // confirms the earlier attempt is closed. Retry at most once.
      _pendingRequestId = _newRequestId();
      return _send(input, mode);
    }
  }

  // Each attempt has its own deadline, so a retry is not cut short.
  Future<SimplificationResponse> _send(InputText input, TextMode mode) {
    return repository
        .simplify(
          SimplificationRequest(
            input: input,
            requestId: _pendingRequestId!,
            mode: mode,
          ),
        )
        .timeout(timeout);
  }

  static String _randomRequestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
