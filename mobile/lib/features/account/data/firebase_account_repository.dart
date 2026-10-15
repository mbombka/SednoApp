import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository({
    required this.auth,
    required this.google,
    required this.sessions,
    required this.clearHistory,
  });

  final firebase.FirebaseAuth auth;
  final GoogleSignIn google;
  final BackendSessionGateway sessions;
  final Future<void> Function() clearHistory;

  @override
  Future<Account> current() async {
    if (await sessions.deletionPending) await deleteAccount();
    return auth.currentUser == null
        ? Account(id: 'guest', provider: IdentityProvider.guest)
        : (await sessions.savedAccount() ??
              Account(id: 'guest', provider: IdentityProvider.guest));
  }

  @override
  Future<Account> signInWithGoogle() async {
    final googleUser = await google.authenticate();
    final credential = firebase.GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    await auth.signInWithCredential(credential);
    return _linkCurrentUser();
  }

  @override
  Future<Account> signInWithEmail(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _linkCurrentUser();
  }

  @override
  Future<Account> registerWithEmail(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _linkCurrentUser();
  }

  Future<Account> _linkCurrentUser() async {
    try {
      final token = await auth.currentUser!.getIdToken(true);
      if (token == null) throw StateError('Brak tokenu tożsamości.');
      return await sessions.link(token);
    } catch (_) {
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
  Future<void> deleteAccount() async {
    // The backend deletes Firebase identity and all server records first.
    // Keep local credentials on failure so the user can retry.
    await sessions.deleteAccount();
    await clearHistory();
    await auth.signOut();
    await google.signOut();
    await sessions.clearDeletedSession();
  }
}
