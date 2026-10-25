/// Local acceptance of the AI processing notice, shared by both text modes.
abstract interface class AiNoticeRepository {
  Future<bool> hasAccepted();
  Future<void> accept();
}
