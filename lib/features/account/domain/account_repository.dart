import 'package:simplifier_app/features/account/domain/account.dart';

abstract interface class AccountRepository {
  Future<Account> current();
  Future<void> signOut();
  Future<void> deleteAccount();
}
