import 'package:sedno_app/l10n/localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

class FirebaseAccountRepository
    implements AccountRepository, AccountStateSource {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();
  FirebaseAccountRepository({
    required this.auth,
    required this.google,
    required this.sessions,
    required this.clearHistory,
  }) {
    sessions.onSessionRejected = () async {
      await auth.signOut();
      await google.signOut();
      await clearHistory();
    };
  }

  @override
  ValueListenable<int> get accountRevision => sessions.sessionRevision;

  final firebase.FirebaseAuth auth;
  final GoogleSignIn google;
  final BackendSessionGateway sessions;
  final Future<void> Function() clearHistory;

  @override
  Future<Account> current() async {
    if (await sessions.deletionPending) await deleteAccount();
    final user = auth.currentUser;
    if (user != null && _requiresVerification(user)) {
      return _pendingAccount(user);
    }
    return user == null
        ? Account(id: 'guest', provider: IdentityProvider.guest)
        : (await sessions.savedAccount() ??
              (_usesPassword(user)
                  ? _awaitingSession(user)
                  : Account(id: 'guest', provider: IdentityProvider.guest)));
  }

  @override
  Future<Account> signInWithGoogle() => _firebaseOperation(() async {
    final googleUser = await google.authenticate();
    final credential = firebase.GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    await auth.signInWithCredential(credential);
    return _linkCurrentUser();
  });

  @override
  Future<Account> signInWithEmail(String email, String password) =>
      _firebaseOperation(() async {
        await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _linkCurrentUser();
      });

  @override
  Future<Account> registerWithEmail(String email, String password) =>
      _firebaseOperation(() async {
        await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final pending = _pending(auth.currentUser!);
        try {
          await resendVerificationEmail();
        } on AccountActionException catch (error) {
          // The Firebase account already exists. Keep the verification screen
          // available so a delivery failure can be retried without registering again.
          throw AccountActionException(error.message, account: pending);
        } catch (_) {
          throw AccountActionException(
            strings.accountCreatedEmailFailed,
            account: pending,
          );
        }
        return pending;
      });

  bool _requiresVerification(firebase.User user) =>
      !user.emailVerified && _usesPassword(user);

  bool _usesPassword(firebase.User user) =>
      user.providerData.any((provider) => provider.providerId == 'password');

  Account _awaitingSession(firebase.User user) => Account(
    id: user.uid,
    provider: IdentityProvider.email,
    email: user.email,
    sessionLinkRequired: true,
  );

  Future<Account> _pendingAccount(firebase.User user) async {
    // Existing clients may have saved an account session before verification
    // was required. Revoke it locally and remotely before returning to guest use.
    if (await sessions.savedAccount() != null) await sessions.signOut();
    return _pending(user);
  }

  Account _pending(firebase.User user) => Account(
    id: user.uid,
    provider: IdentityProvider.email,
    email: user.email,
    emailVerificationRequired: true,
  );

  @override
  Future<void> resendVerificationEmail() => _firebaseOperation(() async {
    final user = auth.currentUser;
    if (user == null || !_requiresVerification(user)) {
      throw AccountActionException(strings.signInToVerify);
    }
    await auth.setLanguageCode(strings.localeName.split('_').first);
    await user.sendEmailVerification();
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseOperation(() async {
        await auth.setLanguageCode(strings.localeName.split('_').first);
        try {
          await auth.sendPasswordResetEmail(email: email.trim());
        } on firebase.FirebaseAuthException catch (error) {
          // Do not disclose whether the address has an account.
          if (error.code != 'user-not-found') rethrow;
        }
      });

  @override
  Future<Account> checkEmailVerification() => _firebaseOperation(() async {
    final user = auth.currentUser;
    if (user == null) {
      throw AccountActionException(
        strings.signInToCheckAccount,
        account: Account(id: 'guest', provider: IdentityProvider.guest),
      );
    }
    await user.reload();
    return _linkCurrentUser();
  });

  Future<T> _firebaseOperation<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on firebase.FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'weak-password' => strings.weakPassword,
        'invalid-email' => strings.checkEmailAddress,
        'email-already-in-use' => strings.emailAlreadyUsed,
        'too-many-requests' => strings.tooManyAttempts,
        'network-request-failed' => strings.checkInternet,
        'user-mismatch' => strings.chooseSameAccount,
        'requires-recent-login' => strings.signInToDelete,
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => strings.invalidCredentials,
        'user-token-expired' ||
        'invalid-user-token' ||
        'user-disabled' => strings.signInToCheckAccount,
        _ => strings.actionFailed,
      };
      final user = auth.currentUser;
      final sessionExpired = {
        'user-token-expired',
        'invalid-user-token',
        'user-disabled',
      }.contains(error.code);
      if (sessionExpired) {
        await sessions.rejectCurrentAccount();
        await auth.signOut();
      }
      throw AccountActionException(
        message,
        account: sessionExpired
            ? Account(id: 'guest', provider: IdentityProvider.guest)
            : user != null && _usesPassword(user) && user.emailVerified
            ? _awaitingSession(user)
            : null,
      );
    }
  }

  Future<Account> _linkCurrentUser() async {
    final user = auth.currentUser;
    if (user == null) {
      throw AccountActionException(
        strings.signInToCheckAccount,
        account: Account(id: 'guest', provider: IdentityProvider.guest),
      );
    }
    if (_requiresVerification(user)) return _pendingAccount(user);
    try {
      final token = await auth.currentUser!.getIdToken(true);
      if (token == null) throw StateError('Brak tokenu tożsamości.');
      return await sessions.link(token);
    } on firebase.FirebaseAuthException {
      rethrow;
    } catch (error) {
      if (error is AccountActionException &&
          error.account?.provider == IdentityProvider.guest) {
        await sessions.rejectCurrentAccount();
        await auth.signOut();
        rethrow;
      }
      if (_usesPassword(user)) {
        // Verification and backend admission are separate steps. A rejected
        // installation or network failure must not discard Firebase identity.
        throw AccountActionException(
          error is AccountActionException
              ? error.message
              : strings.accountLinkFailed,
          account: _awaitingSession(user),
        );
      }
      await auth.signOut();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await sessions.signOut();
    await auth.signOut();
    await google.signOut();
    await clearHistory();
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    if (!await sessions.deletionPending) {
      await _firebaseOperation(() async {
        final user = auth.currentUser;
        if (user == null) {
          throw AccountActionException(strings.signInToDelete);
        }
        final firebase.AuthCredential credential;
        if (_usesPassword(user)) {
          if (password == null || password.isEmpty) {
            throw AccountActionException(strings.passwordToDelete);
          }
          credential = firebase.EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
        } else {
          final selected = await google.authenticate();
          credential = firebase.GoogleAuthProvider.credential(
            idToken: selected.authentication.idToken,
          );
        }
        await user.reauthenticateWithCredential(credential);
        final token = await user.getIdToken(true);
        if (token == null) {
          throw AccountActionException(strings.signInToDelete);
        }
        await sessions.deleteAccount(firebaseIdToken: token);
      });
    }
    await clearHistory();
    await auth.signOut();
    await google.signOut();
    await sessions.clearDeletedSession();
  }
}
