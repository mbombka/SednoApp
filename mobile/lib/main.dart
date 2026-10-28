import 'dart:io';

import 'package:sedno_app/app/ios_installation_initializer.dart';

import 'package:sedno_app/features/account/data/apple_app_attest.dart';
import 'package:sedno_app/features/subscription/data/apple_subscription_store.dart';
import 'package:sedno_app/features/subscription/domain/apple_subscription_configuration.dart';
import 'package:sedno_app/features/privacy/data/local_ai_notice_repository.dart';
import 'package:sedno_app/app/app_language.dart';
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
import 'package:sedno_app/features/simplification/data/http_simplification_repository.dart';
import 'package:sedno_app/features/subscription/data/backend_subscription_repository.dart';
import 'package:sedno_app/features/subscription/data/google_play_store.dart';
import 'package:sedno_app/features/subscription/domain/play_subscription_configuration.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const preferences = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );
  if (Platform.isIOS) {
    await const IosInstallationInitializer().initialize(() async {
      await preferences.deleteAll();
      // Firebase has a separate Keychain namespace. Keep this marker until its
      // surviving credentials are cleared, even across failed startup attempts.
      await preferences.write(
        key: 'ios_firebase_signout_pending',
        value: 'true',
      );
    });
  }
  final languages = LanguageController(
    read: () => preferences.read(key: 'app_language'),
    write: (value) => value == null
        ? preferences.delete(key: 'app_language')
        : preferences.write(key: 'app_language', value: value),
  );
  await languages.load();
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const androidAppId = String.fromEnvironment('FIREBASE_APP_ID');
  const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  const iosBundleId = String.fromEnvironment('IOS_BUNDLE_ID');
  final appId = Platform.isIOS ? iosAppId : androidAppId;
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  const backendUrl = String.fromEnvironment('BACKEND_BASE_URL');
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  const playProjectNumber = int.fromEnvironment('PLAY_CLOUD_PROJECT_NUMBER');
  final history = EncryptedHistoryRepository(
    store: Platform.isIOS
        ? const IosHistoryDocumentStore()
        : const AndroidHistoryDocumentStore(),
    clock: DateTime.now,
  );
  AccountRepository? accounts;
  BackendSessionGateway? sessions;
  if (backendUrl.isNotEmpty) {
    sessions = BackendSessionGateway(
      baseUrl: Uri.parse(backendUrl),
      client: http.Client(),
      storage: const SecureSessionStorage(preferences),
      integrity: const AndroidIntegrityTokenSource(playProjectNumber),
      guestAdmission: Platform.isIOS
          ? AppleAppAttestAdmission(
              baseUrl: Uri.parse(backendUrl),
              client: http.Client(),
              storage: const SecureSessionStorage(preferences),
            )
          : null,
    );
  }
  if (sessions != null) sessions.localizations = () => languages.strings;
  if (sessions != null &&
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty &&
      webClientId.isNotEmpty) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        iosClientId: Platform.isIOS ? iosClientId : null,
        iosBundleId: Platform.isIOS ? iosBundleId : null,
      ),
    );
    if (Platform.isIOS &&
        await preferences.read(key: 'ios_firebase_signout_pending') == 'true') {
      await FirebaseAuth.instance.signOut();
      await preferences.delete(key: 'ios_firebase_signout_pending');
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
      clientId: Platform.isIOS ? iosClientId : null,
    );
    accounts = FirebaseAccountRepository(
      auth: FirebaseAuth.instance,
      google: GoogleSignIn.instance,
      sessions: sessions,
      clearHistory: history.clear,
      appleSignInAvailable: Platform.isIOS,
    )..localizations = () => languages.strings;
  }
  final productId = Platform.isIOS
      ? AppleSubscriptionConfiguration.productId
      : PlaySubscriptionConfiguration.productId;
  final billingEnabled = Platform.isIOS
      ? AppleSubscriptionConfiguration.enabled
      : PlaySubscriptionConfiguration.enabled;
  final subscription =
      sessions == null ||
          !billingEnabled ||
          productId.isEmpty ||
          (!Platform.isIOS && PlaySubscriptionConfiguration.basePlanId.isEmpty)
      ? null
      : SubscriptionViewModel(
          store: Platform.isIOS
              ? AppleSubscriptionStore(productId: productId)
              : GooglePlayStore(
                  productId: productId,
                  basePlanId: PlaySubscriptionConfiguration.basePlanId,
                ),
          repository: BackendSubscriptionRepository(
            sessions,
            apple: Platform.isIOS,
          ),
          productId: productId,
          storeSource: Platform.isIOS ? 'app_store' : 'google_play',
        );
  if (subscription != null) {
    subscription.localizations = () => languages.strings;
    sessions!.sessionRevision.addListener(subscription.refresh);
  }
  runApp(
    SednoApp(
      languageController: languages,
      aiNoticeRepository: LocalAiNoticeRepository(
        read: () => preferences.read(key: 'ai_notice_accepted'),
        write: (value) =>
            preferences.write(key: 'ai_notice_accepted', value: value),
      ),
      accountRepository: accounts,
      subscriptionModel: subscription,
      historyRepository: history,
      simplificationRepository: sessions == null
          ? null
          : HttpSimplificationRepository(
              baseUrl: Uri.parse(backendUrl),
              client: http.Client(),
              sessions: sessions,
            ),
    ),
  );
}
