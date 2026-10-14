import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';

abstract interface class QuotaRepository {
  Future<QuotaState> current();
}

abstract interface class QuotaStateSource implements QuotaRepository {
  ValueListenable<QuotaState?> get quotaListenable;
}
