import 'package:simplifier_app/features/history/domain/history_entry.dart';

abstract interface class HistoryRepository {
  Future<void> save(HistoryEntry entry);
  Future<List<HistoryEntry>> readAll();
  Future<void> delete(String id);
  Future<void> clear();
}
