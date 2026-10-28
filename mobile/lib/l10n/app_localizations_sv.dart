// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get restoreOriginal => 'Återställ originaltexten';

  @override
  String get userMenu => 'Användarmeny';

  @override
  String get speechNotRecognised =>
      'Inget tal kunde identifieras. Försök igen.';

  @override
  String get speechFailed => 'Taligenkänningen misslyckades. Försök igen.';

  @override
  String get microphonePermission =>
      'Tillåt mikrofonen i appens inställningar.';

  @override
  String get speechRequirements =>
      'Lokal taligenkänning kräver Android 13 eller senare och en kompatibel talmotor.';

  @override
  String get speechModelMissing =>
      'Ladda ned den svenska talmodellen i Androids inställningar för taligenkänning.';

  @override
  String get speechTimeout => 'Taligenkänningen tog för lång tid. Försök igen.';

  @override
  String get speechAndroidOnly => 'Lokal taligenkänning finns från Android 13.';

  @override
  String get historyClearFailed =>
      'Det gick inte att radera hela historiken. Försök igen.';

  @override
  String get deleteHistoryEntryTitle =>
      'Radera den här texten från historiken?';

  @override
  String get cannotUndo => 'Detta går inte att ångra.';

  @override
  String get delete => 'Radera';

  @override
  String get historyEntryDeleted => 'Texten har raderats.';

  @override
  String get deleteHistoryTitle => 'Radera hela historiken?';

  @override
  String get deleteHistoryNotice =>
      'Alla sparade texter raderas från den här telefonen. Detta går inte att ångra.';

  @override
  String get deleteAllHistory => 'Radera hela historiken';

  @override
  String get historyDeleted => 'Historiken har raderats.';

  @override
  String get historyLocalNotice => 'Texter sparas bara på den här telefonen.';

  @override
  String get historyRetentionNotice =>
      'Varje text raderas automatiskt efter 7 dagar.';

  @override
  String get historySignOutNotice =>
      'När du loggar ut raderas hela historiken.';

  @override
  String get deleteHistoryNow => 'Radera hela historiken nu';

  @override
  String get deletingHistory => 'Raderar historiken';

  @override
  String get loadingHistory => 'Läser in historiken';

  @override
  String get historyLoadFailed => 'Det gick inte att läsa in historiken.';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get historyEmpty => 'Du har inga sparade texter än.';

  @override
  String get historyEmptyNotice => 'Förenklade och rättade texter visas här.';

  @override
  String get correctedVersion => 'Rättad version';

  @override
  String get simplifiedVersion => 'Enkel version';

  @override
  String get originalText => 'Originaltext';

  @override
  String get hideOriginal => 'Dölj originalet';

  @override
  String get showOriginal => 'Visa originalet';

  @override
  String get today => 'I dag';

  @override
  String get readTextFailed => 'Det gick inte att läsa texten. Försök igen.';

  @override
  String get voiceMissing =>
      'Kontrollera att en svensk röst för uppläsning utan internet är nedladdad på telefonen.';

  @override
  String get playbackAndroidOnly => 'Uppläsning finns på Android.';

  @override
  String get about => 'Om appen';

  @override
  String get back => 'Tillbaka';

  @override
  String get appPurpose => 'Vad Sedno gör';

  @override
  String get appDescription =>
      'Sedno förenklar och rättar texter på de språk som stöds.';

  @override
  String get appAudience =>
      'För personer med hörselnedsättning och personer som har svårt att förstå komplicerade texter.';

  @override
  String get appAge => 'Appen är för personer från 13 år.';

  @override
  String get howItWorks => 'Så fungerar det';

  @override
  String get typingInstructions =>
      'Skriv eller klistra in en text. Välj Förenkla eller Rätta.';

  @override
  String get captureInstructions =>
      'I läget Förenkla kan du också fotografera text eller diktera.';

  @override
  String get captureSubmitInstructions =>
      'Markera texten i bilden och välj Förenkla. Dikterad text förenklas automatiskt.';

  @override
  String get localMediaNotice =>
      'Bilder och ljud stannar på telefonen. Bara text skickas till AI.';

  @override
  String get speechModelRequirements =>
      'Diktering kräver Android 13 eller senare och en nedladdad svensk talmodell.';

  @override
  String get playbackRequirements =>
      'I läget Rätta läser högtalaren texten högt. Du behöver en nedladdad svensk röst som fungerar utan internet.';

  @override
  String get restoreInstructions =>
      'Resultatet visas i samma fält. Tryck på rubriken eller Tillbaka för att återställa originalet.';

  @override
  String get inputLimitNotice => 'Texten får ha högst 4000 tecken.';

  @override
  String get guestNotice => 'Du kan börja utan att skapa ett konto.';

  @override
  String get dailyLimit => 'Daglig gräns';

  @override
  String get freeAllowance => 'Utan prenumeration: 5 texter per dag.';

  @override
  String get paidAllowance => 'Med prenumeration: 400 texter per dag.';

  @override
  String get sharedAllowance => 'Förenkling och rättning delar samma gräns.';

  @override
  String get subscriptionPriceNotice =>
      'Priset visas under Konto och i Google Play.';

  @override
  String get important => 'Viktigt';

  @override
  String get aiErrorNotice => 'AI kan göra fel.';

  @override
  String get checkResult => 'Kontrollera resultatet innan du använder det.';

  @override
  String get author => 'Utvecklare: Mariusz Bąbka';

  @override
  String get privacy => 'Integritet och data';

  @override
  String get websiteOpenFailed =>
      'Det gick inte att öppna webbplatsen. Kontrollera webbläsaren.';

  @override
  String get website => 'Sednos webbplats';

  @override
  String get photoNoText => 'Ingen text hittades. Ta en tydligare bild.';

  @override
  String get cameraPermission => 'Tillåt kameran i telefonens inställningar.';

  @override
  String get cameraStartFailed =>
      'Det gick inte att starta kameran. Försök igen.';

  @override
  String get photoCaptureFailed => 'Det gick inte att ta bilden. Försök igen.';

  @override
  String get selectText => 'Markera text';

  @override
  String get cropInstructions => 'Flytta ramens hörn för att markera texten. ';

  @override
  String get cropWholePhotoNotice =>
      'Utan ändring förenklas texten från hela bilden.';

  @override
  String get openingPhoto => 'Öppnar bilden';

  @override
  String get simplify => 'Förenkla';

  @override
  String get cropTopLeft => 'Ramens övre vänstra hörn';

  @override
  String get cropTopRight => 'Ramens övre högra hörn';

  @override
  String get cropBottomLeft => 'Ramens nedre vänstra hörn';

  @override
  String get cropBottomRight => 'Ramens nedre högra hörn';

  @override
  String get smallerSelection => 'Mindre markering';

  @override
  String get largerSelection => 'Större markering';

  @override
  String get cropResizeHint =>
      'Öka för att minska markeringen. Minska för att göra den större.';

  @override
  String get takeTextPhoto => 'Fotografera text';

  @override
  String get startingCamera => 'Startar kameran';

  @override
  String get takingPhoto => 'Tar bild…';

  @override
  String get takePhoto => 'Ta bild';

  @override
  String get photoOpenFailed => 'Det gick inte att öppna bilden. Ta en ny.';

  @override
  String get photoPrepareFailed =>
      'Det gick inte att förbereda bilden. Försök igen.';

  @override
  String get simplifyHeading => 'förenkla text';

  @override
  String get simplifiedText => 'Förenklad text';

  @override
  String get correctedText => 'Rättad text';

  @override
  String get emptyText => 'Texten får inte vara tom.';

  @override
  String get textTooLong => 'Texten får ha högst 4000 tecken.';

  @override
  String get subscriptionActive => 'Din prenumeration är aktiv.';

  @override
  String get subscriptionAllowance =>
      'Du kan förenkla upp till 400 texter per dag.';

  @override
  String get manageSubscriptionNotice =>
      'Öppna Google Play för att ändra betalningen eller avsluta prenumerationen.';

  @override
  String get manageSubscription => 'Hantera prenumeration i Google Play';

  @override
  String get testerAccessNotice => 'Du har kostnadsfri teståtkomst.';

  @override
  String get restorePurchases => 'Återställ köp';

  @override
  String get refreshAccess => 'Uppdatera åtkomst';

  @override
  String get subscriptionBenefits =>
      'Upp till 400 texter per dag med prenumeration, 5 utan.';

  @override
  String get subscriptionSignInNotice =>
      'Logga in på Sedno för att köpa eller återställa en prenumeration.';

  @override
  String get buySubscription => 'Köp prenumeration';

  @override
  String get refreshSubscription => 'Uppdatera prenumeration';

  @override
  String get subscriptionRenewalNotice =>
      'Prenumerationen förnyas automatiskt varje månad.';

  @override
  String get subscriptionCancelNotice =>
      'Du kan avsluta den när som helst i Google Play.';

  @override
  String get paymentReadFailed =>
      'Det gick inte att läsa betalningar. Försök återställa köp.';

  @override
  String get signInBeforePurchase => 'Logga in före köpet.';

  @override
  String get subscriptionAlreadyActive => 'Din prenumeration är redan aktiv.';

  @override
  String get signInBeforeRestore => 'Logga in innan du återställer köp.';

  @override
  String get purchasesChecked =>
      'Köpen har kontrollerats. Bekräftelsen kan ta en stund.';

  @override
  String get playOpenFailed =>
      'Det gick inte att öppna Google Play. Öppna butiken och välj Betalningar och prenumerationer → Prenumerationer.';

  @override
  String get paymentPending =>
      'Betalningen väntar på bekräftelse. Gränsen ändras inte.';

  @override
  String get purchaseCancelled => 'Köpet avbröts.';

  @override
  String get purchaseFailed =>
      'Det gick inte att köpa prenumerationen. Försök igen.';

  @override
  String get subscriptionInactive => 'Din prenumeration är inte aktiv.';

  @override
  String get subscriptionVerifyFailed =>
      'Det går inte att bekräfta prenumerationen. Logga in, kontrollera anslutningen och återställ köp.';

  @override
  String get subscriptionCheckFailed =>
      'Det går inte att kontrollera prenumerationen. Logga in och försök igen.';

  @override
  String get hideConfirmedPassword => 'Dölj upprepat lösenord';

  @override
  String get showConfirmedPassword => 'Visa upprepat lösenord';

  @override
  String get hidePassword => 'Dölj lösenord';

  @override
  String get showPassword => 'Visa lösenord';

  @override
  String get enterEmail => 'Ange din e-postadress.';

  @override
  String get enterValidEmail => 'Ange en giltig e-postadress.';

  @override
  String get passwordResetSent =>
      'Om ett konto med adressen finns får du en länk för att återställa lösenordet. Kontrollera även skräppost.';

  @override
  String get emailSendFailed => 'Det gick inte att skicka e-post. Försök igen.';

  @override
  String get accountLoadFailed =>
      'Det gick inte att läsa in kontot eller slutföra raderingen av data. Försök igen.';

  @override
  String get verificationEmailSent =>
      'Vi har skickat ett mejl med en länk. Kontrollera inkorgen och skräppost.';

  @override
  String get emailNotVerified =>
      'Adressen är inte bekräftad än. Öppna länken i mejlet och försök igen.';

  @override
  String get signInFailed =>
      'Det gick inte att logga in. Kontrollera uppgifterna och försök igen.';

  @override
  String get signOutFailed => 'Det gick inte att logga ut. Försök igen.';

  @override
  String get deleteAccountTitle => 'Radera kontot?';

  @override
  String get deleteAccountIdentity =>
      'Bekräfta din identitet för att radera kontot.';

  @override
  String get password => 'Lösenord';

  @override
  String get keepAccount => 'Behåll kontot';

  @override
  String get deleteAccountAndData => 'Radera konto och data';

  @override
  String get accountDeleted =>
      'Kontot och data har raderats. Avsluta prenumerationen separat i Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Det gick inte att slutföra raderingen. Försök igen.';

  @override
  String get emailAccountMethod => ' (e-post och lösenord)';

  @override
  String get finishDataCleanup => 'Uppdatera kontot och slutför rensningen';

  @override
  String get accountNotConfigured => 'Kontoalternativ visas här.';

  @override
  String get signOut => 'Logga ut';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get emailVerified => 'E-postadressen bekräftad';

  @override
  String get checkInbox => 'Kontrollera din e-post';

  @override
  String get finishAccountLinkNotice =>
      'Adressen är bekräftad. Du behöver fortfarande ansluta Sedno-kontot. Du behöver inte öppna mejllänken igen.';

  @override
  String get verifyEmailInstructions =>
      'Öppna länken i mejlet från Sedno för att skapa kontot färdigt. Kontrollera även skräppost. Kom sedan tillbaka och välj ”Kontrollera bekräftelse”.';

  @override
  String get guestWhileVerifying =>
      'Under tiden kan du använda appen utan konto.';

  @override
  String get finishSignIn => 'Slutför inloggningen';

  @override
  String get checkVerification => 'Kontrollera bekräftelse';

  @override
  String get resendEmail => 'Skicka mejlet igen';

  @override
  String get signOutUseGuest => 'Logga ut och använd utan konto';

  @override
  String get signIn => 'Logga in';

  @override
  String get newAccount => 'Nytt konto';

  @override
  String get recoverAccess => 'Återställ åtkomst';

  @override
  String get guestSignInNotice => 'Du kan använda appen utan att logga in.';

  @override
  String get signInGoogle => 'Logga in med Google';

  @override
  String get emailAddress => 'E-postadress';

  @override
  String get enterPassword => 'Ange lösenordet.';

  @override
  String get passwordMinLength => 'Använd minst 6 tecken.';

  @override
  String get repeatPassword => 'Upprepa lösenord';

  @override
  String get enterRepeatedPassword => 'Upprepa lösenordet.';

  @override
  String get passwordMismatch => 'Lösenorden måste vara lika.';

  @override
  String get verificationEmailNotice =>
      'Vi skickar ett mejl med en länk för att bekräfta adressen.';

  @override
  String get passwordResetInstructions =>
      'Ange kontots e-postadress. Vi skickar en länk för att byta lösenord.';

  @override
  String get signInEmail => 'Logga in med e-post';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get sendResetLink => 'Skicka länk för att återställa lösenord';

  @override
  String get forgotPassword => 'Glömt lösenord';

  @override
  String get createAccountLink => 'Inget konto? Skapa ett';

  @override
  String get backToSignIn => 'Tillbaka till inloggningen';

  @override
  String get testerAccess => 'Teståtkomst';

  @override
  String get testerAllowance => 'Du kan bearbeta upp till 400 texter per dag.';

  @override
  String get testerExpiryNotice =>
      'Åtkomsten är gratis och upphör automatiskt.';

  @override
  String get testerHasSubscription =>
      'Du har också en aktiv Google Play-prenumeration.';

  @override
  String get testerExpired => 'Teståtkomsten har upphört.';

  @override
  String get subscriptionStillActive =>
      'Din Google Play-prenumeration ger fortfarande en högre gräns.';

  @override
  String get freeLimitRestored =>
      'Gratisgränsen på 5 texter per dag gäller. Dagens användning ändras inte.';

  @override
  String get closeMenu => 'Stäng menyn';

  @override
  String get welcome => 'Välkommen till Sedno';

  @override
  String get inApp => 'I appen';

  @override
  String get accountCreatedEmailFailed =>
      'Kontot skapades, men mejlet kunde inte skickas. Försök skicka det igen.';

  @override
  String get signInToVerify => 'Logga in med e-post för att bekräfta adressen.';

  @override
  String get signInToCheckAccount =>
      'Logga in igen för att kontrollera kontots status.';

  @override
  String get weakPassword => 'Lösenordet är för svagt. Använd minst 6 tecken.';

  @override
  String get checkEmailAddress => 'Kontrollera e-postadressen du angav.';

  @override
  String get emailAlreadyUsed =>
      'Adressen används redan. Logga in på det befintliga kontot.';

  @override
  String get tooManyAttempts =>
      'För många försök. Vänta en stund och försök igen.';

  @override
  String get checkInternet =>
      'Ingen anslutning. Kontrollera internet och försök igen.';

  @override
  String get chooseSameAccount => 'Välj kontot du vill radera.';

  @override
  String get signInToDelete => 'Logga in igen för att radera kontot.';

  @override
  String get invalidCredentials =>
      'Det gick inte att logga in. Kontrollera e-post och lösenord.';

  @override
  String get actionFailed => 'Åtgärden misslyckades. Försök igen.';

  @override
  String get accountLinkFailed =>
      'Det gick inte att ansluta Sedno-kontot. Kontrollera anslutningen och försök igen.';

  @override
  String get passwordToDelete => 'Ange lösenordet för att bekräfta raderingen.';

  @override
  String get finishLocalDeletion =>
      'Slutför raderingen av data på den här enheten.';

  @override
  String get installationRejected =>
      'Servern kunde inte verifiera installationen. Försök igen eller installera Sedno från Google Play.';

  @override
  String get sessionStartFailed =>
      'Det går inte att starta sessionen. Försök igen.';

  @override
  String get signInToLink => 'Logga in igen för att ansluta kontot.';

  @override
  String get cannotLinkAccount =>
      'Det går inte att ansluta kontot. Försök igen.';

  @override
  String get signInAgain => 'Logga in igen.';

  @override
  String get sessionExpiredSignIn => 'Sessionen har gått ut. Logga in igen.';

  @override
  String get cannotDeleteAccount =>
      'Det går inte att radera kontot. Försök igen.';

  @override
  String get cannotSignOut => 'Det går inte att logga ut. Försök igen.';

  @override
  String get correctionUnavailable => 'Texträttning är inte tillgänglig än.';

  @override
  String get simplificationUnavailable =>
      'Textförenkling är inte tillgänglig än.';

  @override
  String get requestTimeout => 'Tidsgränsen har överskridits. Försök igen.';

  @override
  String get offline => 'Ingen internetanslutning. Försök igen.';

  @override
  String get sessionExpired =>
      'Sessionen har gått ut. Kontrollera kontot och försök igen.';

  @override
  String get quotaExhausted =>
      'Dagens gräns är förbrukad. Kontrollera när den förnyas.';

  @override
  String get serviceUnavailable =>
      'Tjänsten är tillfälligt otillgänglig. Försök igen.';

  @override
  String get correctionRejected =>
      'Det går inte att rätta texten. Kontrollera den och försök igen.';

  @override
  String get simplificationRejected =>
      'Det går inte att förenkla texten. Kontrollera den och försök igen.';

  @override
  String get correctionFailed => 'Det gick inte att rätta texten. Försök igen.';

  @override
  String get simplificationFailed =>
      'Det gick inte att förenkla texten. Försök igen.';

  @override
  String get checkConnection => 'Kontrollera anslutningen';

  @override
  String get quotaCheckFailed =>
      'Det går inte att kontrollera gränsen. Kontrollera anslutningen.';

  @override
  String get subscriptionInAccount =>
      'Prenumerationen och priset finns under Konto.';

  @override
  String get beforeCorrection => 'Innan du rättar text';

  @override
  String get beforeSimplification => 'Innan du förenklar text';

  @override
  String get acceptAndSend => 'Jag förstår, skicka';

  @override
  String get cameraUnavailable => 'Kameran blir snart tillgänglig.';

  @override
  String get aiWarning => 'AI kan ha fel';

  @override
  String get listeningNotice =>
      'Lyssnar… Tala svenska. Slutar efter 1,5 sekunders tystnad eller 60 sekunder. Stoppknappen avbryter inspelningen.';

  @override
  String get correctionSubmitted => 'Texten har skickats för rättning.';

  @override
  String get simplificationSubmitted => 'Texten har skickats för förenkling.';

  @override
  String get textForCorrection => 'Text att rätta';

  @override
  String get textForSimplification => 'Text att förenkla';

  @override
  String get inputHint => 'Skriv eller klistra in text';

  @override
  String get switchToCorrection => 'Byt till texträttning';

  @override
  String get switchToSimplification => 'Byt till textförenkling';

  @override
  String get clearText => 'Rensa texten';

  @override
  String get stopPlayback => 'Stoppa uppläsningen';

  @override
  String get readAloud => 'Läs texten högt';

  @override
  String get cancelRecording => 'Avbryt inspelning';

  @override
  String get simplifySpeech => 'Förenkla tal';

  @override
  String get cancel => 'Avbryt';

  @override
  String get history => 'Historik';

  @override
  String get account => 'Konto';

  @override
  String get start => 'Hem';

  @override
  String get contact => 'Kontakt';

  @override
  String get close => 'Stäng';

  @override
  String get continueAction => 'Fortsätt';

  @override
  String get correct => 'Rätta';

  @override
  String get correctHeading => 'rätta text';

  @override
  String get correcting => 'Rättar…';

  @override
  String get simplifying => 'Förenklar…';

  @override
  String get reading => 'Läser…';

  @override
  String get camera => 'Kamera';

  @override
  String get preparing => 'Förbereder…';

  @override
  String get subscription => 'Prenumeration';

  @override
  String get yesterday => 'I går';

  @override
  String get signedIn => 'Inloggad.';

  @override
  String get googleAccountMethod => ' (Google-konto)';

  @override
  String get language => 'Språk';

  @override
  String get systemLanguage => 'Telefonens språk';

  @override
  String get polish => 'Polska';

  @override
  String get english => 'Engelska (Storbritannien)';

  @override
  String get languageNotice =>
      'Språket gäller menyer, förenkling, rättning och tal. Välj textens språk. Sedno översätter inte texter.';

  @override
  String get languageSaveFailed =>
      'Det gick inte att spara språket. Försök igen.';

  @override
  String resetDaily(String time) {
    return 'Gränsen förnyas varje dag kl. $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Gränsen förnyas varje dag kl. $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Gränsen förnyas kl. $time.';
  }

  @override
  String get quotaUsed => 'Dagens gräns är förbrukad.';

  @override
  String get quotaOneSimplification => 'Du har 1 förenkling kvar.';

  @override
  String get quotaOneUse => 'Du har 1 AI-användning kvar.';

  @override
  String get quotaUsedDialog => 'Dagsgränsen är förbrukad.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Gränsen förnyas kl. $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'om $hours tim $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price per månad';
  }

  @override
  String historyExpires(String date) {
    return 'Raderas $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Radera text sparad $date';
  }

  @override
  String contactAddress(String email) {
    return 'Kontakt: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Inloggad som $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'E-postadress: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Adress att bekräfta: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Skicka igen om $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Teståtkomst till $date (lokal tid).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Vågrätt $horizontal %, lodrätt $vertical %';
  }

  @override
  String welcomeName(String name) {
    return 'Välkommen till $name';
  }

  @override
  String policyVersion(String date) {
    return 'Version: $date';
  }

  @override
  String get speechModelDownloading =>
      'Talmodellen laddas ned. Försök igen senare.';

  @override
  String get speechLanguageUnsupported =>
      'Talmotorn på den här telefonen erbjuder inte lokal diktering på det här språket. Du kan skriva eller använda kameran.';

  @override
  String get signInApple => 'Logga in med Apple';

  @override
  String get appleAccountMethod => 'Apple';

  @override
  String get signInCancelled => 'Inloggning avbruten.';

  @override
  String get accountMethodConflict =>
      'Kontot använder en annan inloggningsmetod. Använd din vanliga metod.';

  @override
  String get localSpeechUnavailable =>
      'Lokal taligenkänning är inte tillgänglig för detta språk på den här enheten.';

  @override
  String get localSpeechModelMissing =>
      'Installera den lokala talmodellen i enhetens inställningar.';

  @override
  String get deviceFeatureUnavailable =>
      'Den här funktionen är inte tillgänglig på den här enheten.';

  @override
  String get subscriptionOtherStore =>
      'Den här prenumerationen köptes i en annan butik. Hantera den i butiken där du köpte den.';

  @override
  String get storeOpenFailed =>
      'Det gick inte att öppna prenumerationsinställningarna. Försök igen.';

  @override
  String get appleManageSubscriptionNotice =>
      'Öppna App Store för att ändra betalningen eller avsluta prenumerationen.';

  @override
  String get appleManageSubscription => 'Hantera prenumeration i App Store';

  @override
  String get appleSubscriptionCancelNotice =>
      'Du kan avsluta den när som helst i App Store.';

  @override
  String get appleAccountDeleted =>
      'Kontot och data har raderats. Avsluta prenumerationen separat i App Store.';

  @override
  String get appleTesterHasSubscription =>
      'Du har också en aktiv App Store-prenumeration.';

  @override
  String get appleSubscriptionStillActive =>
      'Din App Store-prenumeration ger fortfarande en högre gräns.';

  @override
  String get appleInstallationRejected =>
      'Servern kunde inte verifiera installationen. Försök igen eller installera Sedno från App Store.';

  @override
  String get appleSubscriptionPriceNotice =>
      'Priset visas under Konto och i App Store.';

  @override
  String get privacyIosSupplementTitle => 'Ytterligare information för iPhone';

  @override
  String get privacyIosSupplementBody =>
      'Hänvisningarna nedan till Android, Google Play och Play Integrity gäller bara Android. På iPhone kan du logga in med Apple och dölja din e-postadress. Firebase hanterar också inloggning. Apple debiterar prenumerationer köpta i App Store; Sedno får inga kortuppgifter. Att radera kontot avslutar inte prenumerationen.\n\nApp Attest kontrollerar appens äkthet utan att skicka text, resultat eller foton till Apple. Servern lagrar pseudonyma installationsuppgifter och offentliga nycklar. Utmaningar gäller i 5 minuter och nycklar i 90 dagar efter den senaste lyckade sessionskontrollen. Köpmeddelanden sparas i 30 dagar. Ett serverjobb raderar utgångna poster. Köpmetadata sparas tills kontot raderas.\n\nHistoriken är krypterad, lokal, undantagen från säkerhetskopior och går ut efter 7 dagar. Foton och ljud stannar på enheten. Diktering och uppläsning sker bara lokalt när enheten och språket stöder det. Du skickar igenkänd text till OpenAI via Sedno efter att ha godkänt AI-informationen.\n\nÖvrig information nedan, inklusive personuppgiftsansvarig, ändamål, rättsliga grunder och OpenAI:s rutiner, gäller även iPhone. Apples integritetspolicy: https://www.apple.com/legal/privacy/';

  @override
  String get linkApple => 'Länka Apple-konto';

  @override
  String get confirmAccountLink =>
      'Bekräfta ditt nuvarande konto igen. Välj sedan ett Apple-konto för att logga in på samma Sedno-konto.';

  @override
  String get passwordToLink =>
      'Ange lösenordet för ditt nuvarande konto för att länka det till Apple.';

  @override
  String get linkGoogle => 'Länka Google-konto';

  @override
  String get confirmGoogleAccountLink =>
      'Bekräfta ditt nuvarande konto igen. Välj sedan ett Google-konto för att logga in på samma Sedno-konto.';

  @override
  String get passwordToLinkGoogle =>
      'Ange lösenordet för ditt nuvarande konto för att länka Google.';
}
