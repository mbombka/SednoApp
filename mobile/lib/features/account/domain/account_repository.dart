import 'package:sedno_app/features/account/domain/account.dart';

abstract interface class AccountRepository {
  Future<Account> current();
  Future<Account> signInWithGoogle();
  Future<Account> signInWithEmail(String email, String password);
  Future<Account> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
}
