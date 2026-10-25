import 'package:sedno_app/features/privacy/domain/ai_notice_repository.dart';

class LocalAiNoticeRepository implements AiNoticeRepository {
  LocalAiNoticeRepository({required this.read, required this.write});

  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  bool _accepted = false;

  @override
  Future<bool> hasAccepted() async {
    if (_accepted) return true;
    try {
      _accepted = await read() == 'true';
    } catch (_) {
      // Unreadable storage must not bypass the notice.
    }
    return _accepted;
  }

  @override
  Future<void> accept() async {
    _accepted = true;
    try {
      await write('true');
    } catch (_) {
      // Keep acceptance for this run; ask again next launch if saving failed.
    }
  }
}
