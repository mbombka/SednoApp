import 'package:sedno_app/features/account/domain/account.dart';

abstract interface class AccountRepository {
  Future<Account> current();
  Future<Account> signInWithGoogle();
  Future<Account> signInWithEmail(String email, String password);
  Future<Account> registerWithEmail(String email, String password);
  Future<Account> checkEmailVerification();
  Future<void> resendVerificationEmail();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
}

class AccountActionException implements Exception {
  const AccountActionException(this.message, {this.account});

  final String message;
  final Account? account;
}
