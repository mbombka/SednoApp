import 'package:sedno_app/features/shared/domain/app_language.dart';
import 'package:sedno_app/l10n/localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

class FirebaseAccountRepository
    implements AccountRepository, AccountStateSource, AppleAccountRepository {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();
  FirebaseAccountRepository({
    required this.auth,
    required this.google,
    required this.sessions,
    required this.clearHistory,
    this.appleSignInAvailable = false,
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform {
    sessions.onSessionRejected = () async {
      await auth.signOut();
      await google.signOut();
      await clearHistory();
    };
  }

  final TargetPlatform _platform;

  @override
  ValueListenable<int> get accountRevision => sessions.sessionRevision;

  @override
  final bool appleSignInAvailable;

  @override
  Future<Account> signInWithApple() => _firebaseOperation(() async {
    if (!appleSignInAvailable) {
      throw StateError('Apple sign-in is unavailable.');
    }
    // Firebase's native provider manages the Apple nonce and credential exchange.
    await auth.signInWithProvider(firebase.AppleAuthProvider());
    return _linkCurrentUser();
  });

  @override
  bool get canLinkApple {
    final user = auth.currentUser;
    return appleSignInAvailable &&
        user != null &&
        !_usesApple(user) &&
        !_requiresVerification(user) &&
        user.providerData.any(
          (provider) =>
              provider.providerId == 'google.com' ||
              provider.providerId == 'password',
        );
  }

  @override
  Future<Account> linkApple({String? password}) async {
    final existingAccount = await sessions.savedAccount();
    if (!canLinkApple ||
        existingAccount == null ||
        existingAccount.signInPending) {
      throw AccountActionException(strings.signInToCheckAccount);
    }
    try {
      return await _firebaseOperation(() async {
        final user = auth.currentUser!;
        final uid = user.uid;
        final firebase.AuthCredential credential;
        if (existingAccount.provider == IdentityProvider.email) {
          if (password == null || password.isEmpty) {
            throw AccountActionException(strings.passwordToLink);
          }
          credential = firebase.EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
        } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
          final selected = await google.authenticate();
          credential = firebase.GoogleAuthProvider.credential(
            idToken: selected.authentication.idToken,
          );
        } else {
          throw AccountActionException(strings.signInToCheckAccount);
        }
        // Reauthentication proves the existing identity. Signing in here could
        // silently switch UID and create a separate backend account and quota.
        final reauthenticated = await user.reauthenticateWithCredential(
          credential,
        );
        await _checkLinkedIdentity(uid, reauthenticated.user);
        final linked = await user.linkWithProvider(
          firebase.AppleAuthProvider(),
        );
        await _checkLinkedIdentity(uid, linked.user);
        final token = await auth.currentUser!.getIdToken(true);
        if (token == null) {
          throw AccountActionException(strings.accountLinkFailed);
        }
        // The backend admits a new guest session from this same installation,
        // then resolves the unchanged Firebase UID to the same Sedno account.
        // Existing account credentials remain available if admission fails.
        return await sessions.link(token);
      });
    } on AccountActionException catch (error) {
      if (error.account?.provider == IdentityProvider.guest) rethrow;
      throw AccountActionException(error.message, account: existingAccount);
    } catch (_) {
      throw AccountActionException(
        strings.accountLinkFailed,
        account: existingAccount,
      );
    }
  }

  @override
  bool get canLinkGoogle {
    final user = auth.currentUser;
    return appleSignInAvailable &&
        user != null &&
        !_requiresVerification(user) &&
        !user.providerData.any(
          (provider) => provider.providerId == 'google.com',
        ) &&
        user.providerData.any(
          (provider) =>
              provider.providerId == 'apple.com' ||
              provider.providerId == 'password',
        );
  }

  @override
  Future<Account> linkGoogle({String? password}) async {
    final existingAccount = await sessions.savedAccount();
    if (!canLinkGoogle ||
        existingAccount == null ||
        existingAccount.signInPending) {
      throw AccountActionException(strings.signInToCheckAccount);
    }
    try {
      return await _firebaseOperation(() async {
        final user = auth.currentUser!;
        final uid = user.uid;
        final firebase.UserCredential reauthenticated;
        if (_usesApple(user)) {
          reauthenticated = await user.reauthenticateWithProvider(
            firebase.AppleAuthProvider(),
          );
        } else {
          if (password == null || password.isEmpty) {
            throw AccountActionException(strings.passwordToLinkGoogle);
          }
          reauthenticated = await user.reauthenticateWithCredential(
            firebase.EmailAuthProvider.credential(
              email: user.email!,
              password: password,
            ),
          );
        }
        await _checkLinkedIdentity(uid, reauthenticated.user);
        final selected = await google.authenticate();
        // Link the selected credential to the already authenticated Firebase UID.
        // Never sign in with it or merge an existing Google account implicitly.
        final linked = await user.linkWithCredential(
          firebase.GoogleAuthProvider.credential(
            idToken: selected.authentication.idToken,
          ),
        );
        await _checkLinkedIdentity(uid, linked.user);
        final token = await auth.currentUser!.getIdToken(true);
        if (token == null) {
          throw AccountActionException(strings.accountLinkFailed);
        }
        return await sessions.link(token);
      });
    } on AccountActionException catch (error) {
      if (error.account?.provider == IdentityProvider.guest) rethrow;
      throw AccountActionException(error.message, account: existingAccount);
    } catch (_) {
      throw AccountActionException(
        strings.accountLinkFailed,
        account: existingAccount,
      );
    }
  }

  Future<void> _checkLinkedIdentity(String uid, firebase.User? returned) async {
    if (auth.currentUser?.uid != uid) {
      await sessions.rejectCurrentAccount();
      throw AccountActionException(
        strings.chooseSameAccount,
        account: Account(id: 'guest', provider: IdentityProvider.guest),
      );
    }
    if (returned?.uid != uid) {
      throw firebase.FirebaseAuthException(code: 'user-mismatch');
    }
  }

  bool _usesApple(firebase.User user) =>
      user.providerData.any((provider) => provider.providerId == 'apple.com');

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
    await auth.setLanguageCode(
      AppLanguage.resolve([strings.localeName]).firebaseLanguage,
    );
    await user.sendEmailVerification();
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseOperation(() async {
        await auth.setLanguageCode(
          AppLanguage.resolve([strings.localeName]).firebaseLanguage,
        );
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
        'web-context-canceled' || 'canceled' => strings.signInCancelled,
        'account-exists-with-different-credential' ||
        'credential-already-in-use' => strings.accountMethodConflict,
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

  Future<void> _revokeAppleAccess(firebase.UserCredential result) async {
    // FlutterFire exposes different native revocation APIs. Never invoke the
    // Apple-only authorization-code method when an Apple-linked user is on Android.
    switch (_platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final code = result.additionalUserInfo?.authorizationCode;
        if (code == null || code.isEmpty) {
          throw AccountActionException(strings.signInToDelete);
        }
        await auth.revokeTokenWithAuthorizationCode(code);
      case TargetPlatform.android:
        final credential = result.credential;
        final token =
            credential is firebase.OAuthCredential &&
                credential.providerId == 'apple.com'
            ? credential.accessToken
            : null;
        if (token == null || token.isEmpty) {
          throw AccountActionException(strings.signInToDelete);
        }
        await auth.revokeAccessToken(token);
      default:
        throw AccountActionException(strings.signInToDelete);
    }
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    if (!await sessions.deletionPending) {
      await _firebaseOperation(() async {
        final user = auth.currentUser;
        if (user == null) {
          throw AccountActionException(strings.signInToDelete);
        }
        if (_usesApple(user)) {
          final result = await user.reauthenticateWithProvider(
            firebase.AppleAuthProvider(),
          );
          await _revokeAppleAccess(result);
        } else {
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
        }
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
