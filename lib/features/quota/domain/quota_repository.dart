import 'package:simplifier_app/features/quota/domain/quota_state.dart';

abstract interface class QuotaRepository {
  Future<QuotaState> current();
}
