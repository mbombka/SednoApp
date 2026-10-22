import 'dart:async';

import 'package:sedno_app/features/speech/domain/speech_service.dart';

class FakeSpeechService implements SpeechService {
  // Create the future inside the widget test clock, when listening starts.
  late final Completer<String?> pending = Completer<String?>();
  int calls = 0;
  int cancellations = 0;

  @override
  Future<String?> listen() {
    calls++;
    return pending.future;
  }

  @override
  Future<void> cancel() async {
    cancellations++;
    if (!pending.isCompleted) pending.complete(null);
  }
}
