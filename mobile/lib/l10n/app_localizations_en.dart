// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get restoreOriginal => 'Restore original text';

  @override
  String get userMenu => 'User menu';

  @override
  String get speechNotRecognised => 'No speech recognised. Please try again.';

  @override
  String get speechFailed => 'Could not recognise speech. Please try again.';

  @override
  String get microphonePermission =>
      'To use speech, allow microphone access in the app settings.';

  @override
  String get speechRequirements =>
      'On-device speech recognition needs Android 13 or later and a compatible speech engine.';

  @override
  String get speechModelMissing =>
      'No on-device English speech model is installed. Download it in the Android speech recognition settings.';

  @override
  String get speechTimeout =>
      'Speech recognition took too long. Please try again.';

  @override
  String get speechAndroidOnly =>
      'On-device speech recognition is available on Android 13 or later.';

  @override
  String get historyClearFailed =>
      'Could not delete all history. Please try again.';

  @override
  String get deleteHistoryEntryTitle => 'Delete this text from history?';

  @override
  String get cannotUndo => 'This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get historyEntryDeleted => 'Text deleted.';

  @override
  String get deleteHistoryTitle => 'Delete all history?';

  @override
  String get deleteHistoryNotice =>
      'All saved texts will be deleted from this phone. This cannot be undone.';

  @override
  String get deleteAllHistory => 'Delete all history';

  @override
  String get historyDeleted => 'All history deleted.';

  @override
  String get historyLocalNotice => 'Texts are saved only on this phone.';

  @override
  String get historyRetentionNotice =>
      'Each text is automatically deleted after 7 days.';

  @override
  String get historySignOutNotice => 'Signing out deletes all history.';

  @override
  String get deleteHistoryNow => 'Delete all history now';

  @override
  String get deletingHistory => 'Deleting history';

  @override
  String get loadingHistory => 'Loading history';

  @override
  String get historyLoadFailed => 'Could not load history.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get historyEmpty => 'You have no saved texts yet.';

  @override
  String get historyEmptyNotice =>
      'Every simplified or corrected text will appear here.';

  @override
  String get correctedVersion => 'Corrected version';

  @override
  String get simplifiedVersion => 'Simple version';

  @override
  String get originalText => 'Original text';

  @override
  String get hideOriginal => 'Hide original';

  @override
  String get showOriginal => 'Show original';

  @override
  String get today => 'Today';

  @override
  String get readTextFailed => 'Could not read the text. Please try again.';

  @override
  String get voiceMissing =>
      'Cannot read the text aloud. Check that an English voice for offline reading is downloaded in your phone settings.';

  @override
  String get playbackAndroidOnly => 'Reading aloud is available on Android.';

  @override
  String get about => 'About';

  @override
  String get back => 'Back';

  @override
  String get appPurpose => 'What Sedno does';

  @override
  String get appDescription =>
      'Sedno simplifies and corrects texts in the supported languages.';

  @override
  String get appAudience =>
      'It was created for people who are hard of hearing and people who find complex text difficult to understand.';

  @override
  String get appAge => 'The app is for people aged 13 and over.';

  @override
  String get howItWorks => 'How it works';

  @override
  String get typingInstructions =>
      'Type or paste text. Choose Simplify or Correct.';

  @override
  String get captureInstructions =>
      'In Simplify mode, you can also take a photo of text or say it aloud.';

  @override
  String get captureSubmitInstructions =>
      'After selecting text in a photo, choose Simplify. Dictated text is simplified automatically.';

  @override
  String get localMediaNotice =>
      'Photos and audio stay on your phone. Only text is sent to AI.';

  @override
  String get speechModelRequirements =>
      'Speech needs Android 13 or later and a downloaded English speech model.';

  @override
  String get playbackRequirements =>
      'In Correct mode, the speaker reads the text aloud. You need a downloaded English voice for offline reading.';

  @override
  String get restoreInstructions =>
      'The result appears in the same field. Tap its heading or Back to return to the original.';

  @override
  String get inputLimitNotice => 'Text can have up to 4000 characters.';

  @override
  String get guestNotice => 'You can start without creating an account.';

  @override
  String get dailyLimit => 'Daily limit';

  @override
  String get freeAllowance => 'Without a subscription: 5 texts a day.';

  @override
  String get paidAllowance => 'With a subscription: 400 texts a day.';

  @override
  String get sharedAllowance =>
      'Simplifying and correcting share the same limit.';

  @override
  String get subscriptionPriceNotice =>
      'You can see the subscription price in Account and in Google Play.';

  @override
  String get important => 'Important';

  @override
  String get aiErrorNotice => 'AI can make mistakes.';

  @override
  String get checkResult => 'Check the result before using it.';

  @override
  String get author => 'Author: Mariusz Bąbka';

  @override
  String get privacy => 'Privacy and data';

  @override
  String get websiteOpenFailed =>
      'Cannot open the website. Check your browser.';

  @override
  String get website => 'Sedno website';

  @override
  String get photoNoText => 'No text detected. Take a clearer photo.';

  @override
  String get cameraPermission =>
      'No camera access. Allow access in your phone settings.';

  @override
  String get cameraStartFailed =>
      'Could not start the camera. Please try again.';

  @override
  String get photoCaptureFailed => 'Could not take a photo. Please try again.';

  @override
  String get selectText => 'Select text';

  @override
  String get cropInstructions =>
      'Move the corners of the frame to select the text. ';

  @override
  String get cropWholePhotoNotice =>
      'If you leave it unchanged, we will simplify text from the whole photo.';

  @override
  String get openingPhoto => 'Opening photo';

  @override
  String get simplify => 'Simplify';

  @override
  String get cropTopLeft => 'Top left corner of the frame';

  @override
  String get cropTopRight => 'Top right corner of the frame';

  @override
  String get cropBottomLeft => 'Bottom left corner of the frame';

  @override
  String get cropBottomRight => 'Bottom right corner of the frame';

  @override
  String get smallerSelection => 'Smaller selection';

  @override
  String get largerSelection => 'Larger selection';

  @override
  String get cropResizeHint =>
      'Increase to make the selection smaller. Decrease to make it larger.';

  @override
  String get takeTextPhoto => 'Take a photo of text';

  @override
  String get startingCamera => 'Starting camera';

  @override
  String get takingPhoto => 'Taking photo…';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get photoOpenFailed => 'Could not open the photo. Take a new photo.';

  @override
  String get photoPrepareFailed =>
      'Could not prepare the photo. Please try again.';

  @override
  String get simplifyHeading => 'simplify text';

  @override
  String get simplifiedText => 'Simplified text';

  @override
  String get correctedText => 'Corrected text';

  @override
  String get emptyText => 'Text cannot be empty.';

  @override
  String get textTooLong => 'Text can have up to 4000 characters.';

  @override
  String get subscriptionActive => 'Your subscription is active.';

  @override
  String get subscriptionAllowance => 'You can simplify up to 400 texts a day.';

  @override
  String get manageSubscriptionNotice =>
      'To change your payment or cancel your subscription, go to Google Play.';

  @override
  String get manageSubscription => 'Manage subscription in Google Play';

  @override
  String get testerAccessNotice => 'You have free tester access.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get refreshAccess => 'Refresh access';

  @override
  String get subscriptionBenefits =>
      'You can simplify up to 400 texts a day (without a subscription: 5).';

  @override
  String get subscriptionSignInNotice =>
      'To buy or restore a subscription, sign in to your Sedno account.';

  @override
  String get buySubscription => 'Buy subscription';

  @override
  String get refreshSubscription => 'Refresh subscription';

  @override
  String get subscriptionRenewalNotice =>
      'The subscription renews automatically every month.';

  @override
  String get subscriptionCancelNotice =>
      'You can cancel it at any time in Google Play.';

  @override
  String get paymentReadFailed =>
      'Cannot read payments. Try restoring purchases.';

  @override
  String get signInBeforePurchase => 'Sign in before buying.';

  @override
  String get subscriptionAlreadyActive =>
      'Your subscription is already active.';

  @override
  String get signInBeforeRestore => 'Sign in before restoring a purchase.';

  @override
  String get purchasesChecked =>
      'Purchases checked. Confirmation may take a moment.';

  @override
  String get playOpenFailed =>
      'Cannot open Google Play. Open the store and choose Payments and subscriptions → Subscriptions.';

  @override
  String get paymentPending =>
      'Payment is awaiting confirmation. Your limit stays the same.';

  @override
  String get purchaseCancelled => 'Purchase cancelled.';

  @override
  String get purchaseFailed =>
      'Could not buy the subscription. Please try again.';

  @override
  String get subscriptionInactive => 'Your subscription is not active.';

  @override
  String get subscriptionVerifyFailed =>
      'Cannot confirm your subscription. Sign in, check your connection and restore purchases.';

  @override
  String get subscriptionCheckFailed =>
      'Cannot check your subscription. Sign in and try again.';

  @override
  String get hideConfirmedPassword => 'Hide repeated password';

  @override
  String get showConfirmedPassword => 'Show repeated password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get enterEmail => 'Enter your email address.';

  @override
  String get enterValidEmail => 'Enter a valid email address.';

  @override
  String get passwordResetSent =>
      'If an account with this address exists, you will receive a password reset link. Check your spam folder too.';

  @override
  String get emailSendFailed => 'Could not send the email. Please try again.';

  @override
  String get accountLoadFailed =>
      'Could not load your account or finish deleting data. Please try again.';

  @override
  String get verificationEmailSent =>
      'We sent an email with a link. Check your inbox and spam folder.';

  @override
  String get emailNotVerified =>
      'Your address is not verified yet. Click the link in the email and try again.';

  @override
  String get signInFailed =>
      'Could not sign in. Check your details and try again.';

  @override
  String get signOutFailed => 'Could not sign out. Please try again.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountIdentity =>
      'Confirm your identity to delete your account.';

  @override
  String get password => 'Password';

  @override
  String get keepAccount => 'Keep account';

  @override
  String get deleteAccountAndData => 'Delete account and data';

  @override
  String get accountDeleted =>
      'Your account and data have been deleted. Cancel your subscription separately in Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Could not finish deleting. Please try again.';

  @override
  String get emailAccountMethod => ' (email and password)';

  @override
  String get finishDataCleanup => 'Refresh account and finish clearing data';

  @override
  String get accountNotConfigured => 'Account options will appear here.';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get emailVerified => 'Email address verified';

  @override
  String get checkInbox => 'Check your email';

  @override
  String get finishAccountLinkNotice =>
      'Your address is verified. You still need to connect to your Sedno account. You do not need to click the email link again.';

  @override
  String get verifyEmailInstructions =>
      'To finish creating your account, click the link in the email from Sedno. Check your spam folder too. Then come back here and choose “Check verification”.';

  @override
  String get guestWhileVerifying =>
      'Until then, you can use the app without an account.';

  @override
  String get finishSignIn => 'Finish signing in';

  @override
  String get checkVerification => 'Check verification';

  @override
  String get resendEmail => 'Send email again';

  @override
  String get signOutUseGuest => 'Sign out and use without an account';

  @override
  String get signIn => 'Sign in';

  @override
  String get newAccount => 'New account';

  @override
  String get recoverAccess => 'Recover access';

  @override
  String get guestSignInNotice => 'You can use the app without signing in.';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get emailAddress => 'Email address';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get passwordMinLength => 'Use at least 6 characters.';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get enterRepeatedPassword => 'Repeat your password.';

  @override
  String get passwordMismatch => 'Passwords must match.';

  @override
  String get verificationEmailNotice =>
      'We will send an email with a link to verify your email address.';

  @override
  String get passwordResetInstructions =>
      'Enter your account email address. We will send a password reset link.';

  @override
  String get signInEmail => 'Sign in with email';

  @override
  String get createAccount => 'Create account';

  @override
  String get sendResetLink => 'Send password reset link';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get createAccountLink => 'No account? Create one';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get testerAccess => 'Tester access';

  @override
  String get testerAllowance => 'You can process up to 400 texts a day.';

  @override
  String get testerExpiryNotice =>
      'Access is free and will expire automatically.';

  @override
  String get testerHasSubscription =>
      'You also have an active Google Play subscription.';

  @override
  String get testerExpired => 'Tester access has expired.';

  @override
  String get subscriptionStillActive =>
      'Your Google Play subscription still gives you a higher limit.';

  @override
  String get freeLimitRestored =>
      'The free limit of 5 texts a day applies. Today\'s usage stays the same.';

  @override
  String get closeMenu => 'Close menu';

  @override
  String get welcome => 'Welcome to Sedno';

  @override
  String get inApp => 'In the app';

  @override
  String get accountCreatedEmailFailed =>
      'Your account was created, but the email could not be sent. Try sending it again.';

  @override
  String get signInToVerify => 'Sign in with email to verify your address.';

  @override
  String get signInToCheckAccount =>
      'Sign in again to check your account status.';

  @override
  String get weakPassword =>
      'Your password is too weak. Use at least 6 characters.';

  @override
  String get checkEmailAddress =>
      'Check that your email address is entered correctly.';

  @override
  String get emailAlreadyUsed =>
      'This address is already in use. Sign in to your existing account.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get checkInternet =>
      'No connection. Check your internet and try again.';

  @override
  String get chooseSameAccount =>
      'Choose the same account that you want to delete.';

  @override
  String get signInToDelete => 'Sign in again to delete your account.';

  @override
  String get invalidCredentials =>
      'Could not sign in. Check your email address and password.';

  @override
  String get actionFailed =>
      'Could not complete this action. Please try again.';

  @override
  String get accountLinkFailed =>
      'Could not connect to your Sedno account. Check your connection and try again.';

  @override
  String get passwordToDelete =>
      'Enter your password to confirm account deletion.';

  @override
  String get finishLocalDeletion => 'Finish deleting data on this device.';

  @override
  String get installationRejected =>
      'The server could not verify this app installation. Try again or install Sedno from Google Play.';

  @override
  String get sessionStartFailed => 'Cannot start a session. Please try again.';

  @override
  String get signInToLink => 'Sign in again to connect your account.';

  @override
  String get cannotLinkAccount =>
      'Cannot connect your account. Please try again.';

  @override
  String get signInAgain => 'Sign in again.';

  @override
  String get sessionExpiredSignIn => 'Your session has expired. Sign in again.';

  @override
  String get cannotDeleteAccount =>
      'Cannot delete your account. Please try again.';

  @override
  String get cannotSignOut => 'Cannot sign out. Please try again.';

  @override
  String get correctionUnavailable => 'Text correction is not available yet.';

  @override
  String get simplificationUnavailable =>
      'Text simplification is not available yet.';

  @override
  String get requestTimeout => 'The request timed out. Please try again.';

  @override
  String get offline => 'No internet connection. Please try again.';

  @override
  String get sessionExpired =>
      'Your session has expired. Check your account and try again.';

  @override
  String get quotaExhausted =>
      'You have used today\'s allowance. Check the reset time.';

  @override
  String get serviceUnavailable =>
      'The service is temporarily unavailable. Please try again.';

  @override
  String get correctionRejected =>
      'Cannot correct this text. Check it and try again.';

  @override
  String get simplificationRejected =>
      'Cannot simplify this text. Check it and try again.';

  @override
  String get correctionFailed =>
      'Could not correct the text. Please try again.';

  @override
  String get simplificationFailed =>
      'Could not simplify the text. Please try again.';

  @override
  String get checkConnection => 'Check your connection';

  @override
  String get quotaCheckFailed =>
      'Cannot check your allowance. Check your connection.';

  @override
  String get subscriptionInAccount =>
      'You can find the subscription and its price in Account.';

  @override
  String get beforeCorrection => 'Before you correct text';

  @override
  String get beforeSimplification => 'Before you simplify text';

  @override
  String get acceptAndSend => 'I understand, send';

  @override
  String get cameraUnavailable => 'The camera will be available soon.';

  @override
  String get aiWarning => 'AI can be wrong';

  @override
  String get listeningNotice =>
      'Listening… Speak English. Recording ends after 1.5 seconds of silence or after 60 seconds. The stop button cancels recording.';

  @override
  String get correctionSubmitted => 'The text has been sent for correction.';

  @override
  String get simplificationSubmitted =>
      'The text has been sent for simplification.';

  @override
  String get textForCorrection => 'Text to correct';

  @override
  String get textForSimplification => 'Text to simplify';

  @override
  String get inputHint => 'Type or paste text';

  @override
  String get switchToCorrection => 'Switch to text correction';

  @override
  String get switchToSimplification => 'Switch to text simplification';

  @override
  String get clearText => 'Clear text';

  @override
  String get stopPlayback => 'Stop reading';

  @override
  String get readAloud => 'Read text aloud';

  @override
  String get cancelRecording => 'Cancel recording';

  @override
  String get simplifySpeech => 'Simplify speech';

  @override
  String get cancel => 'Cancel';

  @override
  String get history => 'History';

  @override
  String get account => 'Account';

  @override
  String get start => 'Home';

  @override
  String get contact => 'Contact';

  @override
  String get close => 'Close';

  @override
  String get continueAction => 'Continue';

  @override
  String get correct => 'Correct';

  @override
  String get correctHeading => 'correct text';

  @override
  String get correcting => 'Correcting…';

  @override
  String get simplifying => 'Simplifying…';

  @override
  String get reading => 'Reading…';

  @override
  String get camera => 'Camera';

  @override
  String get preparing => 'Preparing…';

  @override
  String get subscription => 'Subscription';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get signedIn => 'Signed in.';

  @override
  String get googleAccountMethod => ' (Google account)';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get polish => 'Polish';

  @override
  String get english => 'English (UK)';

  @override
  String get languageNotice =>
      'The language applies to menus, simplification, correction and speech. Choose the language of your text. Sedno does not translate texts.';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String resetDaily(String time) {
    return 'Your allowance resets every day at $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Your allowance resets every day at $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Your allowance resets at $time.';
  }

  @override
  String get quotaUsed => 'You have used today’s allowance.';

  @override
  String get quotaOneSimplification => 'You have 1 simplification left.';

  @override
  String get quotaOneUse => 'You have 1 AI use left.';

  @override
  String get quotaUsedDialog => 'You have used your daily allowance.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Your allowance resets at $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'in $hours h $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price per month';
  }

  @override
  String historyExpires(String date) {
    return 'Will be deleted on $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Delete text saved: $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contact: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Signed in as $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Email address: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Address to verify: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Send again in $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Tester access until $date (local time).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal $horizontal%, vertical $vertical%';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome to $name';
  }

  @override
  String policyVersion(String date) {
    return 'Version: $date';
  }

  @override
  String get speechModelDownloading =>
      'The speech model is downloading. Try again later.';

  @override
  String get speechLanguageUnsupported =>
      'The speech engine on this phone does not support on-device dictation in this language. You can type or use the camera.';
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get restoreOriginal => 'Restore original text';

  @override
  String get userMenu => 'User menu';

  @override
  String get speechNotRecognised => 'No speech recognized. Please try again.';

  @override
  String get speechFailed => 'Could not recognize speech. Please try again.';

  @override
  String get microphonePermission =>
      'To use speech, allow microphone access in the app settings.';

  @override
  String get speechRequirements =>
      'On-device speech recognition needs Android 13 or later and a compatible speech engine.';

  @override
  String get speechModelMissing =>
      'No on-device English speech model is installed. Download it in the Android speech recognition settings.';

  @override
  String get speechTimeout =>
      'Speech recognition took too long. Please try again.';

  @override
  String get speechAndroidOnly =>
      'On-device speech recognition is available on Android 13 or later.';

  @override
  String get historyClearFailed =>
      'Could not delete all history. Please try again.';

  @override
  String get deleteHistoryEntryTitle => 'Delete this text from history?';

  @override
  String get cannotUndo => 'This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get historyEntryDeleted => 'Text deleted.';

  @override
  String get deleteHistoryTitle => 'Delete all history?';

  @override
  String get deleteHistoryNotice =>
      'All saved texts will be deleted from this phone. This cannot be undone.';

  @override
  String get deleteAllHistory => 'Delete all history';

  @override
  String get historyDeleted => 'All history deleted.';

  @override
  String get historyLocalNotice => 'Texts are saved only on this phone.';

  @override
  String get historyRetentionNotice =>
      'Each text is automatically deleted after 7 days.';

  @override
  String get historySignOutNotice => 'Signing out deletes all history.';

  @override
  String get deleteHistoryNow => 'Delete all history now';

  @override
  String get deletingHistory => 'Deleting history';

  @override
  String get loadingHistory => 'Loading history';

  @override
  String get historyLoadFailed => 'Could not load history.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get historyEmpty => 'You have no saved texts yet.';

  @override
  String get historyEmptyNotice =>
      'Every simplified or corrected text will appear here.';

  @override
  String get correctedVersion => 'Corrected version';

  @override
  String get simplifiedVersion => 'Simple version';

  @override
  String get originalText => 'Original text';

  @override
  String get hideOriginal => 'Hide original';

  @override
  String get showOriginal => 'Show original';

  @override
  String get today => 'Today';

  @override
  String get readTextFailed => 'Could not read the text. Please try again.';

  @override
  String get voiceMissing =>
      'Cannot read the text aloud. Check that an English voice for offline reading is downloaded in your phone settings.';

  @override
  String get playbackAndroidOnly => 'Reading aloud is available on Android.';

  @override
  String get about => 'About';

  @override
  String get back => 'Back';

  @override
  String get appPurpose => 'What Sedno does';

  @override
  String get appDescription =>
      'Sedno simplifies and corrects texts in the supported languages.';

  @override
  String get appAudience =>
      'It was created for people who are hard of hearing and people who find complex text difficult to understand.';

  @override
  String get appAge => 'The app is for people aged 13 and over.';

  @override
  String get howItWorks => 'How it works';

  @override
  String get typingInstructions =>
      'Type or paste text. Choose Simplify or Correct.';

  @override
  String get captureInstructions =>
      'In Simplify mode, you can also take a photo of text or say it aloud.';

  @override
  String get captureSubmitInstructions =>
      'After selecting text in a photo, choose Simplify. Dictated text is simplified automatically.';

  @override
  String get localMediaNotice =>
      'Photos and audio stay on your phone. Only text is sent to AI.';

  @override
  String get speechModelRequirements =>
      'Speech needs Android 13 or later and a downloaded English speech model.';

  @override
  String get playbackRequirements =>
      'In Correct mode, the speaker reads the text aloud. You need a downloaded English voice for offline reading.';

  @override
  String get restoreInstructions =>
      'The result appears in the same field. Tap its heading or Back to return to the original.';

  @override
  String get inputLimitNotice => 'Text can have up to 4000 characters.';

  @override
  String get guestNotice => 'You can start without creating an account.';

  @override
  String get dailyLimit => 'Daily limit';

  @override
  String get freeAllowance => 'Without a subscription: 5 texts a day.';

  @override
  String get paidAllowance => 'With a subscription: 400 texts a day.';

  @override
  String get sharedAllowance =>
      'Simplifying and correcting share the same limit.';

  @override
  String get subscriptionPriceNotice =>
      'You can see the subscription price in Account and in Google Play.';

  @override
  String get important => 'Important';

  @override
  String get aiErrorNotice => 'AI can make mistakes.';

  @override
  String get checkResult => 'Check the result before using it.';

  @override
  String get author => 'Author: Mariusz Bąbka';

  @override
  String get privacy => 'Privacy and data';

  @override
  String get websiteOpenFailed =>
      'Cannot open the website. Check your browser.';

  @override
  String get website => 'Sedno website';

  @override
  String get photoNoText => 'No text detected. Take a clearer photo.';

  @override
  String get cameraPermission =>
      'No camera access. Allow access in your phone settings.';

  @override
  String get cameraStartFailed =>
      'Could not start the camera. Please try again.';

  @override
  String get photoCaptureFailed => 'Could not take a photo. Please try again.';

  @override
  String get selectText => 'Select text';

  @override
  String get cropInstructions =>
      'Move the corners of the frame to select the text. ';

  @override
  String get cropWholePhotoNotice =>
      'If you leave it unchanged, we will simplify text from the whole photo.';

  @override
  String get openingPhoto => 'Opening photo';

  @override
  String get simplify => 'Simplify';

  @override
  String get cropTopLeft => 'Top left corner of the frame';

  @override
  String get cropTopRight => 'Top right corner of the frame';

  @override
  String get cropBottomLeft => 'Bottom left corner of the frame';

  @override
  String get cropBottomRight => 'Bottom right corner of the frame';

  @override
  String get smallerSelection => 'Smaller selection';

  @override
  String get largerSelection => 'Larger selection';

  @override
  String get cropResizeHint =>
      'Increase to make the selection smaller. Decrease to make it larger.';

  @override
  String get takeTextPhoto => 'Take a photo of text';

  @override
  String get startingCamera => 'Starting camera';

  @override
  String get takingPhoto => 'Taking photo…';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get photoOpenFailed => 'Could not open the photo. Take a new photo.';

  @override
  String get photoPrepareFailed =>
      'Could not prepare the photo. Please try again.';

  @override
  String get simplifyHeading => 'simplify text';

  @override
  String get simplifiedText => 'Simplified text';

  @override
  String get correctedText => 'Corrected text';

  @override
  String get emptyText => 'Text cannot be empty.';

  @override
  String get textTooLong => 'Text can have up to 4000 characters.';

  @override
  String get subscriptionActive => 'Your subscription is active.';

  @override
  String get subscriptionAllowance => 'You can simplify up to 400 texts a day.';

  @override
  String get manageSubscriptionNotice =>
      'To change your payment or cancel your subscription, go to Google Play.';

  @override
  String get manageSubscription => 'Manage subscription in Google Play';

  @override
  String get testerAccessNotice => 'You have free tester access.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get refreshAccess => 'Refresh access';

  @override
  String get subscriptionBenefits =>
      'You can simplify up to 400 texts a day (without a subscription: 5).';

  @override
  String get subscriptionSignInNotice =>
      'To buy or restore a subscription, sign in to your Sedno account.';

  @override
  String get buySubscription => 'Buy subscription';

  @override
  String get refreshSubscription => 'Refresh subscription';

  @override
  String get subscriptionRenewalNotice =>
      'The subscription renews automatically every month.';

  @override
  String get subscriptionCancelNotice =>
      'You can cancel it at any time in Google Play.';

  @override
  String get paymentReadFailed =>
      'Cannot read payments. Try restoring purchases.';

  @override
  String get signInBeforePurchase => 'Sign in before buying.';

  @override
  String get subscriptionAlreadyActive =>
      'Your subscription is already active.';

  @override
  String get signInBeforeRestore => 'Sign in before restoring a purchase.';

  @override
  String get purchasesChecked =>
      'Purchases checked. Confirmation may take a moment.';

  @override
  String get playOpenFailed =>
      'Cannot open Google Play. Open the store and choose Payments and subscriptions → Subscriptions.';

  @override
  String get paymentPending =>
      'Payment is awaiting confirmation. Your limit stays the same.';

  @override
  String get purchaseCancelled => 'Purchase canceled.';

  @override
  String get purchaseFailed =>
      'Could not buy the subscription. Please try again.';

  @override
  String get subscriptionInactive => 'Your subscription is not active.';

  @override
  String get subscriptionVerifyFailed =>
      'Cannot confirm your subscription. Sign in, check your connection and restore purchases.';

  @override
  String get subscriptionCheckFailed =>
      'Cannot check your subscription. Sign in and try again.';

  @override
  String get hideConfirmedPassword => 'Hide repeated password';

  @override
  String get showConfirmedPassword => 'Show repeated password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get enterEmail => 'Enter your email address.';

  @override
  String get enterValidEmail => 'Enter a valid email address.';

  @override
  String get passwordResetSent =>
      'If an account with this address exists, you will receive a password reset link. Check your spam folder too.';

  @override
  String get emailSendFailed => 'Could not send the email. Please try again.';

  @override
  String get accountLoadFailed =>
      'Could not load your account or finish deleting data. Please try again.';

  @override
  String get verificationEmailSent =>
      'We sent an email with a link. Check your inbox and spam folder.';

  @override
  String get emailNotVerified =>
      'Your address is not verified yet. Click the link in the email and try again.';

  @override
  String get signInFailed =>
      'Could not sign in. Check your details and try again.';

  @override
  String get signOutFailed => 'Could not sign out. Please try again.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountIdentity =>
      'Confirm your identity to delete your account.';

  @override
  String get password => 'Password';

  @override
  String get keepAccount => 'Keep account';

  @override
  String get deleteAccountAndData => 'Delete account and data';

  @override
  String get accountDeleted =>
      'Your account and data have been deleted. Cancel your subscription separately in Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Could not finish deleting. Please try again.';

  @override
  String get emailAccountMethod => ' (email and password)';

  @override
  String get finishDataCleanup => 'Refresh account and finish clearing data';

  @override
  String get accountNotConfigured => 'Account options will appear here.';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get emailVerified => 'Email address verified';

  @override
  String get checkInbox => 'Check your email';

  @override
  String get finishAccountLinkNotice =>
      'Your address is verified. You still need to connect to your Sedno account. You do not need to click the email link again.';

  @override
  String get verifyEmailInstructions =>
      'To finish creating your account, click the link in the email from Sedno. Check your spam folder too. Then come back here and choose “Check verification”.';

  @override
  String get guestWhileVerifying =>
      'Until then, you can use the app without an account.';

  @override
  String get finishSignIn => 'Finish signing in';

  @override
  String get checkVerification => 'Check verification';

  @override
  String get resendEmail => 'Send email again';

  @override
  String get signOutUseGuest => 'Sign out and use without an account';

  @override
  String get signIn => 'Sign in';

  @override
  String get newAccount => 'New account';

  @override
  String get recoverAccess => 'Recover access';

  @override
  String get guestSignInNotice => 'You can use the app without signing in.';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get emailAddress => 'Email address';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get passwordMinLength => 'Use at least 6 characters.';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get enterRepeatedPassword => 'Repeat your password.';

  @override
  String get passwordMismatch => 'Passwords must match.';

  @override
  String get verificationEmailNotice =>
      'We will send an email with a link to verify your email address.';

  @override
  String get passwordResetInstructions =>
      'Enter your account email address. We will send a password reset link.';

  @override
  String get signInEmail => 'Sign in with email';

  @override
  String get createAccount => 'Create account';

  @override
  String get sendResetLink => 'Send password reset link';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get createAccountLink => 'No account? Create one';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get testerAccess => 'Tester access';

  @override
  String get testerAllowance => 'You can process up to 400 texts a day.';

  @override
  String get testerExpiryNotice =>
      'Access is free and will expire automatically.';

  @override
  String get testerHasSubscription =>
      'You also have an active Google Play subscription.';

  @override
  String get testerExpired => 'Tester access has expired.';

  @override
  String get subscriptionStillActive =>
      'Your Google Play subscription still gives you a higher limit.';

  @override
  String get freeLimitRestored =>
      'The free limit of 5 texts a day applies. Today\'s usage stays the same.';

  @override
  String get closeMenu => 'Close menu';

  @override
  String get welcome => 'Welcome to Sedno';

  @override
  String get inApp => 'In the app';

  @override
  String get accountCreatedEmailFailed =>
      'Your account was created, but the email could not be sent. Try sending it again.';

  @override
  String get signInToVerify => 'Sign in with email to verify your address.';

  @override
  String get signInToCheckAccount =>
      'Sign in again to check your account status.';

  @override
  String get weakPassword =>
      'Your password is too weak. Use at least 6 characters.';

  @override
  String get checkEmailAddress =>
      'Check that your email address is entered correctly.';

  @override
  String get emailAlreadyUsed =>
      'This address is already in use. Sign in to your existing account.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get checkInternet =>
      'No connection. Check your internet and try again.';

  @override
  String get chooseSameAccount =>
      'Choose the same account that you want to delete.';

  @override
  String get signInToDelete => 'Sign in again to delete your account.';

  @override
  String get invalidCredentials =>
      'Could not sign in. Check your email address and password.';

  @override
  String get actionFailed =>
      'Could not complete this action. Please try again.';

  @override
  String get accountLinkFailed =>
      'Could not connect to your Sedno account. Check your connection and try again.';

  @override
  String get passwordToDelete =>
      'Enter your password to confirm account deletion.';

  @override
  String get finishLocalDeletion => 'Finish deleting data on this device.';

  @override
  String get installationRejected =>
      'The server could not verify this app installation. Try again or install Sedno from Google Play.';

  @override
  String get sessionStartFailed => 'Cannot start a session. Please try again.';

  @override
  String get signInToLink => 'Sign in again to connect your account.';

  @override
  String get cannotLinkAccount =>
      'Cannot connect your account. Please try again.';

  @override
  String get signInAgain => 'Sign in again.';

  @override
  String get sessionExpiredSignIn => 'Your session has expired. Sign in again.';

  @override
  String get cannotDeleteAccount =>
      'Cannot delete your account. Please try again.';

  @override
  String get cannotSignOut => 'Cannot sign out. Please try again.';

  @override
  String get correctionUnavailable => 'Text correction is not available yet.';

  @override
  String get simplificationUnavailable =>
      'Text simplification is not available yet.';

  @override
  String get requestTimeout => 'The request timed out. Please try again.';

  @override
  String get offline => 'No internet connection. Please try again.';

  @override
  String get sessionExpired =>
      'Your session has expired. Check your account and try again.';

  @override
  String get quotaExhausted =>
      'You have used today\'s allowance. Check the reset time.';

  @override
  String get serviceUnavailable =>
      'The service is temporarily unavailable. Please try again.';

  @override
  String get correctionRejected =>
      'Cannot correct this text. Check it and try again.';

  @override
  String get simplificationRejected =>
      'Cannot simplify this text. Check it and try again.';

  @override
  String get correctionFailed =>
      'Could not correct the text. Please try again.';

  @override
  String get simplificationFailed =>
      'Could not simplify the text. Please try again.';

  @override
  String get checkConnection => 'Check your connection';

  @override
  String get quotaCheckFailed =>
      'Cannot check your allowance. Check your connection.';

  @override
  String get subscriptionInAccount =>
      'You can find the subscription and its price in Account.';

  @override
  String get beforeCorrection => 'Before you correct text';

  @override
  String get beforeSimplification => 'Before you simplify text';

  @override
  String get acceptAndSend => 'I understand, send';

  @override
  String get cameraUnavailable => 'The camera will be available soon.';

  @override
  String get aiWarning => 'AI can be wrong';

  @override
  String get listeningNotice =>
      'Listening… Speak English. Recording ends after 1.5 seconds of silence or after 60 seconds. The stop button cancels recording.';

  @override
  String get correctionSubmitted => 'The text has been sent for correction.';

  @override
  String get simplificationSubmitted =>
      'The text has been sent for simplification.';

  @override
  String get textForCorrection => 'Text to correct';

  @override
  String get textForSimplification => 'Text to simplify';

  @override
  String get inputHint => 'Type or paste text';

  @override
  String get switchToCorrection => 'Switch to text correction';

  @override
  String get switchToSimplification => 'Switch to text simplification';

  @override
  String get clearText => 'Clear text';

  @override
  String get stopPlayback => 'Stop reading';

  @override
  String get readAloud => 'Read text aloud';

  @override
  String get cancelRecording => 'Cancel recording';

  @override
  String get simplifySpeech => 'Simplify speech';

  @override
  String get cancel => 'Cancel';

  @override
  String get history => 'History';

  @override
  String get account => 'Account';

  @override
  String get start => 'Home';

  @override
  String get contact => 'Contact';

  @override
  String get close => 'Close';

  @override
  String get continueAction => 'Continue';

  @override
  String get correct => 'Correct';

  @override
  String get correctHeading => 'correct text';

  @override
  String get correcting => 'Correcting…';

  @override
  String get simplifying => 'Simplifying…';

  @override
  String get reading => 'Reading…';

  @override
  String get camera => 'Camera';

  @override
  String get preparing => 'Preparing…';

  @override
  String get subscription => 'Subscription';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get signedIn => 'Signed in.';

  @override
  String get googleAccountMethod => ' (Google account)';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get polish => 'Polish';

  @override
  String get english => 'English (UK)';

  @override
  String get languageNotice =>
      'The language applies to menus, simplification, correction and speech. Choose the language of your text. Sedno does not translate texts.';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String resetDaily(String time) {
    return 'Your allowance resets every day at $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Your allowance resets every day at $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Your allowance resets at $time.';
  }

  @override
  String get quotaUsed => 'You have used today’s allowance.';

  @override
  String get quotaOneSimplification => 'You have 1 simplification left.';

  @override
  String get quotaOneUse => 'You have 1 AI use left.';

  @override
  String get quotaUsedDialog => 'You have used your daily allowance.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Your allowance resets at $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'in $hours h $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price per month';
  }

  @override
  String historyExpires(String date) {
    return 'Will be deleted on $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Delete text saved: $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contact: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Signed in as $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Email address: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Address to verify: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Send again in $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Tester access until $date (local time).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal $horizontal%, vertical $vertical%';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome to $name';
  }

  @override
  String policyVersion(String date) {
    return 'Version: $date';
  }

  @override
  String get speechModelDownloading =>
      'The speech model is downloading. Try again later.';

  @override
  String get speechLanguageUnsupported =>
      'The speech engine on this phone does not support on-device dictation in this language. You can type or use the camera.';
}
