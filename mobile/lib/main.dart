import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/account/data/firebase_account_repository.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';
import 'package:sedno_app/features/history/data/encrypted_history_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  const backendUrl = String.fromEnvironment('BACKEND_BASE_URL');
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  const playProjectNumber = int.fromEnvironment('PLAY_CLOUD_PROJECT_NUMBER');
  final history = EncryptedHistoryRepository(
    store: const AndroidHistoryDocumentStore(),
    clock: DateTime.now,
  );
  AccountRepository? accounts;
  if (apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty &&
      backendUrl.isNotEmpty &&
      webClientId.isNotEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
      ),
    );
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    accounts = FirebaseAccountRepository(
      auth: FirebaseAuth.instance,
      google: GoogleSignIn.instance,
      sessions: BackendSessionGateway(
        baseUrl: Uri.parse(backendUrl),
        client: http.Client(),
        storage: const SecureSessionStorage(FlutterSecureStorage()),
        integrity: const AndroidIntegrityTokenSource(playProjectNumber),
      ),
      clearHistory: history.clear,
    );
  }
  runApp(SednoApp(accountRepository: accounts, historyRepository: history));
}
