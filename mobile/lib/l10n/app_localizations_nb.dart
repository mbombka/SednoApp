// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get restoreOriginal => 'Gjenopprett originalteksten';

  @override
  String get userMenu => 'Brukermeny';

  @override
  String get speechNotRecognised => 'Ingen tale gjenkjent. Prøv igjen.';

  @override
  String get speechFailed => 'Kunne ikke gjenkjenne talen. Prøv igjen.';

  @override
  String get microphonePermission => 'Tillat mikrofonen i appinnstillingene.';

  @override
  String get speechRequirements =>
      'Lokal talegjenkjenning krever Android 13 eller nyere og en kompatibel talemotor.';

  @override
  String get speechModelMissing =>
      'Last ned den norske talemodellen i Androids innstillinger for talegjenkjenning.';

  @override
  String get speechTimeout =>
      'Talegjenkjenningen tok for lang tid. Prøv igjen.';

  @override
  String get speechAndroidOnly =>
      'Lokal talegjenkjenning er tilgjengelig fra Android 13.';

  @override
  String get historyClearFailed =>
      'Kunne ikke slette hele historikken. Prøv igjen.';

  @override
  String get deleteHistoryEntryTitle => 'Slette denne teksten fra historikken?';

  @override
  String get cannotUndo => 'Dette kan ikke angres.';

  @override
  String get delete => 'Slett';

  @override
  String get historyEntryDeleted => 'Teksten er slettet.';

  @override
  String get deleteHistoryTitle => 'Slette hele historikken?';

  @override
  String get deleteHistoryNotice =>
      'Alle lagrede tekster slettes fra denne telefonen. Dette kan ikke angres.';

  @override
  String get deleteAllHistory => 'Slett hele historikken';

  @override
  String get historyDeleted => 'Historikken er slettet.';

  @override
  String get historyLocalNotice => 'Tekster lagres bare på denne telefonen.';

  @override
  String get historyRetentionNotice =>
      'Hver tekst slettes automatisk etter 7 dager.';

  @override
  String get historySignOutNotice =>
      'Når du logger ut, slettes hele historikken.';

  @override
  String get deleteHistoryNow => 'Slett hele historikken nå';

  @override
  String get deletingHistory => 'Sletter historikken';

  @override
  String get loadingHistory => 'Laster historikken';

  @override
  String get historyLoadFailed => 'Kunne ikke laste historikken.';

  @override
  String get tryAgain => 'Prøv igjen';

  @override
  String get historyEmpty => 'Du har ingen lagrede tekster ennå.';

  @override
  String get historyEmptyNotice => 'Forenklede og rettede tekster vises her.';

  @override
  String get correctedVersion => 'Rettet versjon';

  @override
  String get simplifiedVersion => 'Enkel versjon';

  @override
  String get originalText => 'Originaltekst';

  @override
  String get hideOriginal => 'Skjul originalen';

  @override
  String get showOriginal => 'Vis originalen';

  @override
  String get today => 'I dag';

  @override
  String get readTextFailed => 'Kunne ikke lese teksten. Prøv igjen.';

  @override
  String get voiceMissing =>
      'Sjekk at en norsk stemme for opplesning uten internett er lastet ned på telefonen.';

  @override
  String get playbackAndroidOnly => 'Opplesning er tilgjengelig på Android.';

  @override
  String get about => 'Om appen';

  @override
  String get back => 'Tilbake';

  @override
  String get appPurpose => 'Hva Sedno gjør';

  @override
  String get appDescription =>
      'Sedno forenkler og retter tekster på støttede språk.';

  @override
  String get appAudience =>
      'For personer med nedsatt hørsel og personer som synes komplekse tekster er vanskelige å forstå.';

  @override
  String get appAge => 'Appen er for personer fra 13 år.';

  @override
  String get howItWorks => 'Slik fungerer det';

  @override
  String get typingInstructions =>
      'Skriv eller lim inn tekst. Velg Forenkle eller Rett.';

  @override
  String get captureInstructions =>
      'I modusen Forenkle kan du også ta bilde av tekst eller diktere.';

  @override
  String get captureSubmitInstructions =>
      'Marker teksten på bildet og velg Forenkle. Diktert tekst forenkles automatisk.';

  @override
  String get localMediaNotice =>
      'Bilder og lyd blir på telefonen. Bare tekst sendes til KI.';

  @override
  String get speechModelRequirements =>
      'Diktering krever Android 13 eller nyere og en nedlastet norsk talemodell.';

  @override
  String get playbackRequirements =>
      'I modusen Rett leser høyttaleren teksten høyt. Du trenger en nedlastet norsk stemme som virker uten internett.';

  @override
  String get restoreInstructions =>
      'Resultatet vises i samme felt. Trykk på overskriften eller Tilbake for å gjenopprette originalen.';

  @override
  String get inputLimitNotice => 'Teksten kan ha opptil 4000 tegn.';

  @override
  String get guestNotice => 'Du kan begynne uten å opprette en konto.';

  @override
  String get dailyLimit => 'Dagsgrense';

  @override
  String get freeAllowance => 'Uten abonnement: 5 tekster per dag.';

  @override
  String get paidAllowance => 'Med abonnement: 400 tekster per dag.';

  @override
  String get sharedAllowance => 'Forenkling og retting deler samme grense.';

  @override
  String get subscriptionPriceNotice =>
      'Prisen på abonnementet vises under Konto og i Google Play.';

  @override
  String get important => 'Viktig';

  @override
  String get aiErrorNotice => 'KI kan gjøre feil.';

  @override
  String get checkResult => 'Sjekk resultatet før du bruker det.';

  @override
  String get author => 'Utvikler: Mariusz Bąbka';

  @override
  String get privacy => 'Personvern og data';

  @override
  String get websiteOpenFailed =>
      'Kunne ikke åpne nettsiden. Sjekk nettleseren.';

  @override
  String get website => 'Sednos nettside';

  @override
  String get photoNoText => 'Ingen tekst funnet. Ta et tydeligere bilde.';

  @override
  String get cameraPermission => 'Tillat kameraet i telefoninnstillingene.';

  @override
  String get cameraStartFailed => 'Kunne ikke starte kameraet. Prøv igjen.';

  @override
  String get photoCaptureFailed => 'Kunne ikke ta bildet. Prøv igjen.';

  @override
  String get selectText => 'Marker tekst';

  @override
  String get cropInstructions =>
      'Flytt hjørnene på rammen for å markere teksten. ';

  @override
  String get cropWholePhotoNotice =>
      'Uten endringer forenkles teksten fra hele bildet.';

  @override
  String get openingPhoto => 'Åpner bildet';

  @override
  String get simplify => 'Forenkle';

  @override
  String get cropTopLeft => 'Øvre venstre hjørne av rammen';

  @override
  String get cropTopRight => 'Øvre høyre hjørne av rammen';

  @override
  String get cropBottomLeft => 'Nedre venstre hjørne av rammen';

  @override
  String get cropBottomRight => 'Nedre høyre hjørne av rammen';

  @override
  String get smallerSelection => 'Mindre utvalg';

  @override
  String get largerSelection => 'Større utvalg';

  @override
  String get cropResizeHint =>
      'Øk for å gjøre utvalget mindre. Reduser for å gjøre det større.';

  @override
  String get takeTextPhoto => 'Ta bilde av tekst';

  @override
  String get startingCamera => 'Starter kameraet';

  @override
  String get takingPhoto => 'Tar bilde…';

  @override
  String get takePhoto => 'Ta bilde';

  @override
  String get photoOpenFailed => 'Kunne ikke åpne bildet. Ta et nytt.';

  @override
  String get photoPrepareFailed => 'Kunne ikke klargjøre bildet. Prøv igjen.';

  @override
  String get simplifyHeading => 'forenkle tekst';

  @override
  String get simplifiedText => 'Forenklet tekst';

  @override
  String get correctedText => 'Rettet tekst';

  @override
  String get emptyText => 'Teksten kan ikke være tom.';

  @override
  String get textTooLong => 'Teksten kan ha opptil 4000 tegn.';

  @override
  String get subscriptionActive => 'Abonnementet ditt er aktivt.';

  @override
  String get subscriptionAllowance =>
      'Du kan forenkle opptil 400 tekster per dag.';

  @override
  String get manageSubscriptionNotice =>
      'Åpne Google Play for å endre betalingen eller avslutte abonnementet.';

  @override
  String get manageSubscription => 'Administrer abonnement i Google Play';

  @override
  String get testerAccessNotice => 'Du har gratis testtilgang.';

  @override
  String get restorePurchases => 'Gjenopprett kjøp';

  @override
  String get refreshAccess => 'Oppdater tilgang';

  @override
  String get subscriptionBenefits =>
      'Opptil 400 tekster per dag med abonnement, 5 uten.';

  @override
  String get subscriptionSignInNotice =>
      'Logg inn på Sedno for å kjøpe eller gjenopprette et abonnement.';

  @override
  String get buySubscription => 'Kjøp abonnement';

  @override
  String get refreshSubscription => 'Oppdater abonnement';

  @override
  String get subscriptionRenewalNotice =>
      'Abonnementet fornyes automatisk hver måned.';

  @override
  String get subscriptionCancelNotice =>
      'Du kan avslutte det når som helst i Google Play.';

  @override
  String get paymentReadFailed =>
      'Kunne ikke lese betalinger. Prøv å gjenopprette kjøp.';

  @override
  String get signInBeforePurchase => 'Logg inn før kjøpet.';

  @override
  String get subscriptionAlreadyActive =>
      'Abonnementet ditt er allerede aktivt.';

  @override
  String get signInBeforeRestore => 'Logg inn før du gjenoppretter et kjøp.';

  @override
  String get purchasesChecked =>
      'Kjøp er kontrollert. Bekreftelsen kan ta litt tid.';

  @override
  String get playOpenFailed =>
      'Kunne ikke åpne Google Play. Åpne butikken og velg Betalinger og abonnementer → Abonnementer.';

  @override
  String get paymentPending =>
      'Betalingen venter på bekreftelse. Grensen endres ikke.';

  @override
  String get purchaseCancelled => 'Kjøpet ble avbrutt.';

  @override
  String get purchaseFailed => 'Kunne ikke kjøpe abonnementet. Prøv igjen.';

  @override
  String get subscriptionInactive => 'Abonnementet ditt er ikke aktivt.';

  @override
  String get subscriptionVerifyFailed =>
      'Kan ikke bekrefte abonnementet. Logg inn, sjekk tilkoblingen og gjenopprett kjøp.';

  @override
  String get subscriptionCheckFailed =>
      'Kan ikke sjekke abonnementet. Logg inn og prøv igjen.';

  @override
  String get hideConfirmedPassword => 'Skjul gjentatt passord';

  @override
  String get showConfirmedPassword => 'Vis gjentatt passord';

  @override
  String get hidePassword => 'Skjul passord';

  @override
  String get showPassword => 'Vis passord';

  @override
  String get enterEmail => 'Skriv inn e-postadressen din.';

  @override
  String get enterValidEmail => 'Skriv inn en gyldig e-postadresse.';

  @override
  String get passwordResetSent =>
      'Hvis det finnes en konto med denne adressen, får du en lenke for å endre passordet. Sjekk også søppelpost.';

  @override
  String get emailSendFailed => 'Kunne ikke sende e-posten. Prøv igjen.';

  @override
  String get accountLoadFailed =>
      'Kunne ikke laste kontoen eller fullføre sletting av data. Prøv igjen.';

  @override
  String get verificationEmailSent =>
      'Vi har sendt en e-post med en lenke. Sjekk innboksen og søppelpost.';

  @override
  String get emailNotVerified =>
      'Adressen er ikke bekreftet ennå. Åpne lenken i e-posten og prøv igjen.';

  @override
  String get signInFailed =>
      'Kunne ikke logge inn. Sjekk opplysningene og prøv igjen.';

  @override
  String get signOutFailed => 'Kunne ikke logge ut. Prøv igjen.';

  @override
  String get deleteAccountTitle => 'Slette kontoen?';

  @override
  String get deleteAccountIdentity =>
      'Bekreft identiteten din for å slette kontoen.';

  @override
  String get password => 'Passord';

  @override
  String get keepAccount => 'Behold kontoen';

  @override
  String get deleteAccountAndData => 'Slett konto og data';

  @override
  String get accountDeleted =>
      'Kontoen og dataene er slettet. Avslutt abonnementet separat i Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Kunne ikke fullføre slettingen. Prøv igjen.';

  @override
  String get emailAccountMethod => ' (e-post og passord)';

  @override
  String get finishDataCleanup => 'Oppdater kontoen og fullfør oppryddingen';

  @override
  String get accountNotConfigured => 'Kontoalternativer vises her.';

  @override
  String get signOut => 'Logg ut';

  @override
  String get deleteAccount => 'Slett konto';

  @override
  String get emailVerified => 'E-postadresse bekreftet';

  @override
  String get checkInbox => 'Sjekk e-posten din';

  @override
  String get finishAccountLinkNotice =>
      'Adressen er bekreftet. Du må fortsatt koble til Sedno-kontoen. Du trenger ikke åpne e-postlenken igjen.';

  @override
  String get verifyEmailInstructions =>
      'Åpne lenken i e-posten fra Sedno for å fullføre kontoen. Sjekk også søppelpost. Kom tilbake og velg «Sjekk bekreftelse».';

  @override
  String get guestWhileVerifying =>
      'I mellomtiden kan du bruke appen uten konto.';

  @override
  String get finishSignIn => 'Fullfør innlogging';

  @override
  String get checkVerification => 'Sjekk bekreftelse';

  @override
  String get resendEmail => 'Send e-post på nytt';

  @override
  String get signOutUseGuest => 'Logg ut og bruk uten konto';

  @override
  String get signIn => 'Logg inn';

  @override
  String get newAccount => 'Ny konto';

  @override
  String get recoverAccess => 'Gjenopprett tilgang';

  @override
  String get guestSignInNotice => 'Du kan bruke appen uten å logge inn.';

  @override
  String get signInGoogle => 'Logg inn med Google';

  @override
  String get emailAddress => 'E-postadresse';

  @override
  String get enterPassword => 'Skriv inn passordet.';

  @override
  String get passwordMinLength => 'Bruk minst 6 tegn.';

  @override
  String get repeatPassword => 'Gjenta passord';

  @override
  String get enterRepeatedPassword => 'Gjenta passordet.';

  @override
  String get passwordMismatch => 'Passordene må være like.';

  @override
  String get verificationEmailNotice =>
      'Vi sender en e-post med en lenke for å bekrefte adressen.';

  @override
  String get passwordResetInstructions =>
      'Skriv inn kontoens e-postadresse. Vi sender en lenke for å endre passordet.';

  @override
  String get signInEmail => 'Logg inn med e-post';

  @override
  String get createAccount => 'Opprett konto';

  @override
  String get sendResetLink => 'Send lenke for å endre passord';

  @override
  String get forgotPassword => 'Glemt passord';

  @override
  String get createAccountLink => 'Ingen konto? Opprett en';

  @override
  String get backToSignIn => 'Tilbake til innlogging';

  @override
  String get testerAccess => 'Testtilgang';

  @override
  String get testerAllowance => 'Du kan behandle opptil 400 tekster per dag.';

  @override
  String get testerExpiryNotice => 'Tilgangen er gratis og utløper automatisk.';

  @override
  String get testerHasSubscription =>
      'Du har også et aktivt Google Play-abonnement.';

  @override
  String get testerExpired => 'Testtilgangen har utløpt.';

  @override
  String get subscriptionStillActive =>
      'Google Play-abonnementet ditt gir fortsatt en høyere grense.';

  @override
  String get freeLimitRestored =>
      'Gratisgrensen på 5 tekster per dag gjelder. Dagens bruk endres ikke.';

  @override
  String get closeMenu => 'Lukk menyen';

  @override
  String get welcome => 'Velkommen til Sedno';

  @override
  String get inApp => 'I appen';

  @override
  String get accountCreatedEmailFailed =>
      'Kontoen ble opprettet, men e-posten kunne ikke sendes. Prøv å sende den på nytt.';

  @override
  String get signInToVerify => 'Logg inn med e-post for å bekrefte adressen.';

  @override
  String get signInToCheckAccount => 'Logg inn igjen for å sjekke kontostatus.';

  @override
  String get weakPassword => 'Passordet er for svakt. Bruk minst 6 tegn.';

  @override
  String get checkEmailAddress => 'Sjekk e-postadressen du skrev inn.';

  @override
  String get emailAlreadyUsed =>
      'Adressen er allerede i bruk. Logg inn på den eksisterende kontoen.';

  @override
  String get tooManyAttempts => 'For mange forsøk. Vent litt og prøv igjen.';

  @override
  String get checkInternet =>
      'Ingen tilkobling. Sjekk internett og prøv igjen.';

  @override
  String get chooseSameAccount => 'Velg kontoen du vil slette.';

  @override
  String get signInToDelete => 'Logg inn igjen for å slette kontoen.';

  @override
  String get invalidCredentials =>
      'Kunne ikke logge inn. Sjekk e-post og passord.';

  @override
  String get actionFailed => 'Handlingen mislyktes. Prøv igjen.';

  @override
  String get accountLinkFailed =>
      'Kunne ikke koble til Sedno-kontoen. Sjekk tilkoblingen og prøv igjen.';

  @override
  String get passwordToDelete => 'Skriv inn passordet for å bekrefte sletting.';

  @override
  String get finishLocalDeletion =>
      'Fullfør sletting av data på denne enheten.';

  @override
  String get installationRejected =>
      'Serveren kunne ikke bekrefte installasjonen. Prøv igjen eller installer Sedno fra Google Play.';

  @override
  String get sessionStartFailed => 'Kan ikke starte økten. Prøv igjen.';

  @override
  String get signInToLink => 'Logg inn igjen for å koble til kontoen.';

  @override
  String get cannotLinkAccount => 'Kan ikke koble til kontoen. Prøv igjen.';

  @override
  String get signInAgain => 'Logg inn igjen.';

  @override
  String get sessionExpiredSignIn => 'Økten har utløpt. Logg inn igjen.';

  @override
  String get cannotDeleteAccount => 'Kan ikke slette kontoen. Prøv igjen.';

  @override
  String get cannotSignOut => 'Kan ikke logge ut. Prøv igjen.';

  @override
  String get correctionUnavailable => 'Tekstretting er ikke tilgjengelig ennå.';

  @override
  String get simplificationUnavailable =>
      'Tekstforenkling er ikke tilgjengelig ennå.';

  @override
  String get requestTimeout => 'Tidsfristen er overskredet. Prøv igjen.';

  @override
  String get offline => 'Ingen internettilkobling. Prøv igjen.';

  @override
  String get sessionExpired => 'Økten har utløpt. Sjekk kontoen og prøv igjen.';

  @override
  String get quotaExhausted =>
      'Dagens grense er brukt opp. Sjekk når den fornyes.';

  @override
  String get serviceUnavailable =>
      'Tjenesten er midlertidig utilgjengelig. Prøv igjen.';

  @override
  String get correctionRejected =>
      'Kan ikke rette denne teksten. Sjekk den og prøv igjen.';

  @override
  String get simplificationRejected =>
      'Kan ikke forenkle denne teksten. Sjekk den og prøv igjen.';

  @override
  String get correctionFailed => 'Kunne ikke rette teksten. Prøv igjen.';

  @override
  String get simplificationFailed => 'Kunne ikke forenkle teksten. Prøv igjen.';

  @override
  String get checkConnection => 'Sjekk tilkoblingen';

  @override
  String get quotaCheckFailed => 'Kan ikke sjekke grensen. Sjekk tilkoblingen.';

  @override
  String get subscriptionInAccount =>
      'Abonnementet og prisen finner du under Konto.';

  @override
  String get beforeCorrection => 'Før du retter tekst';

  @override
  String get beforeSimplification => 'Før du forenkler tekst';

  @override
  String get acceptAndSend => 'Jeg forstår, send';

  @override
  String get cameraUnavailable => 'Kameraet blir snart tilgjengelig.';

  @override
  String get aiWarning => 'KI kan ta feil';

  @override
  String get listeningNotice =>
      'Lytter… Snakk norsk. Slutter etter 1,5 sekunders stillhet eller 60 sekunder. Stoppknappen avbryter opptaket.';

  @override
  String get correctionSubmitted => 'Teksten er sendt til retting.';

  @override
  String get simplificationSubmitted => 'Teksten er sendt til forenkling.';

  @override
  String get textForCorrection => 'Tekst som skal rettes';

  @override
  String get textForSimplification => 'Tekst som skal forenkles';

  @override
  String get inputHint => 'Skriv eller lim inn tekst';

  @override
  String get switchToCorrection => 'Bytt til tekstretting';

  @override
  String get switchToSimplification => 'Bytt til tekstforenkling';

  @override
  String get clearText => 'Tøm teksten';

  @override
  String get stopPlayback => 'Stopp opplesning';

  @override
  String get readAloud => 'Les teksten høyt';

  @override
  String get cancelRecording => 'Avbryt opptak';

  @override
  String get simplifySpeech => 'Forenkle tale';

  @override
  String get cancel => 'Avbryt';

  @override
  String get history => 'Historikk';

  @override
  String get account => 'Konto';

  @override
  String get start => 'Hjem';

  @override
  String get contact => 'Kontakt';

  @override
  String get close => 'Lukk';

  @override
  String get continueAction => 'Fortsett';

  @override
  String get correct => 'Rett';

  @override
  String get correctHeading => 'rett tekst';

  @override
  String get correcting => 'Retter…';

  @override
  String get simplifying => 'Forenkler…';

  @override
  String get reading => 'Leser…';

  @override
  String get camera => 'Kamera';

  @override
  String get preparing => 'Klargjør…';

  @override
  String get subscription => 'Abonnement';

  @override
  String get yesterday => 'I går';

  @override
  String get signedIn => 'Logget inn.';

  @override
  String get googleAccountMethod => ' (Google-konto)';

  @override
  String get language => 'Språk';

  @override
  String get systemLanguage => 'Telefonens språk';

  @override
  String get polish => 'Polsk';

  @override
  String get english => 'Engelsk (Storbritannia)';

  @override
  String get languageNotice =>
      'Språket gjelder menyer, forenkling, retting og tale. Velg tekstens språk. Sedno oversetter ikke tekster.';

  @override
  String get languageSaveFailed => 'Kunne ikke lagre språket. Prøv igjen.';

  @override
  String resetDaily(String time) {
    return 'Grensen fornyes hver dag kl. $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Grensen fornyes hver dag kl. $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Grensen fornyes kl. $time.';
  }

  @override
  String get quotaUsed => 'Dagens grense er brukt opp.';

  @override
  String get quotaOneSimplification => 'Du har 1 forenkling igjen.';

  @override
  String get quotaOneUse => 'Du har 1 KI-bruk igjen.';

  @override
  String get quotaUsedDialog => 'Dagsgrensen er brukt opp.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Grensen fornyes kl. $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'om $hours t $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price per måned';
  }

  @override
  String historyExpires(String date) {
    return 'Slettes $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Slett tekst lagret $date';
  }

  @override
  String contactAddress(String email) {
    return 'Kontakt: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Logget inn som $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'E-postadresse: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Adresse som skal bekreftes: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Send på nytt om $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Testtilgang til $date (lokal tid).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Vannrett $horizontal %, loddrett $vertical %';
  }

  @override
  String welcomeName(String name) {
    return 'Velkommen til $name';
  }

  @override
  String policyVersion(String date) {
    return 'Versjon: $date';
  }

  @override
  String get speechModelDownloading =>
      'Talemodellen lastes ned. Prøv igjen senere.';

  @override
  String get speechLanguageUnsupported =>
      'Talemotoren på denne telefonen tilbyr ikke lokal diktering på dette språket. Du kan skrive eller bruke kameraet.';
}
