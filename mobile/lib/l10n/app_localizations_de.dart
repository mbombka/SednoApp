// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get restoreOriginal => 'Originaltext wiederherstellen';

  @override
  String get userMenu => 'Benutzermenü';

  @override
  String get speechNotRecognised =>
      'Keine Sprache erkannt. Bitte erneut versuchen.';

  @override
  String get speechFailed =>
      'Spracherkennung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get microphonePermission =>
      'Erlaube den Mikrofonzugriff in den App-Einstellungen.';

  @override
  String get speechRequirements =>
      'Lokale Spracherkennung benötigt Android 13 oder neuer und eine passende Sprachsoftware.';

  @override
  String get speechModelMissing =>
      'Lade das deutsche Sprachmodell in den Android-Einstellungen zur Spracherkennung herunter.';

  @override
  String get speechTimeout =>
      'Die Spracherkennung dauerte zu lange. Bitte erneut versuchen.';

  @override
  String get speechAndroidOnly =>
      'Lokale Spracherkennung ist ab Android 13 verfügbar.';

  @override
  String get historyClearFailed =>
      'Der Verlauf konnte nicht vollständig gelöscht werden. Versuche es erneut.';

  @override
  String get deleteHistoryEntryTitle => 'Diesen Text aus dem Verlauf löschen?';

  @override
  String get cannotUndo => 'Das lässt sich nicht rückgängig machen.';

  @override
  String get delete => 'Löschen';

  @override
  String get historyEntryDeleted => 'Text gelöscht.';

  @override
  String get deleteHistoryTitle => 'Gesamten Verlauf löschen?';

  @override
  String get deleteHistoryNotice =>
      'Alle gespeicherten Texte werden von diesem Telefon gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get deleteAllHistory => 'Gesamten Verlauf löschen';

  @override
  String get historyDeleted => 'Verlauf gelöscht.';

  @override
  String get historyLocalNotice =>
      'Texte werden nur auf diesem Telefon gespeichert.';

  @override
  String get historyRetentionNotice =>
      'Jeder Text wird nach 7 Tagen automatisch gelöscht.';

  @override
  String get historySignOutNotice =>
      'Beim Abmelden wird der gesamte Verlauf gelöscht.';

  @override
  String get deleteHistoryNow => 'Gesamten Verlauf jetzt löschen';

  @override
  String get deletingHistory => 'Verlauf wird gelöscht';

  @override
  String get loadingHistory => 'Verlauf wird geladen';

  @override
  String get historyLoadFailed => 'Verlauf konnte nicht geladen werden.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get historyEmpty => 'Du hast noch keine gespeicherten Texte.';

  @override
  String get historyEmptyNotice =>
      'Vereinfachte und korrigierte Texte erscheinen hier.';

  @override
  String get correctedVersion => 'Korrigierte Fassung';

  @override
  String get simplifiedVersion => 'Einfache Fassung';

  @override
  String get originalText => 'Originaltext';

  @override
  String get hideOriginal => 'Original ausblenden';

  @override
  String get showOriginal => 'Original anzeigen';

  @override
  String get today => 'Heute';

  @override
  String get readTextFailed =>
      'Text konnte nicht gelesen werden. Versuche es erneut.';

  @override
  String get voiceMissing =>
      'Prüfe, ob eine deutsche Stimme zum Vorlesen ohne Internet heruntergeladen ist.';

  @override
  String get playbackAndroidOnly => 'Vorlesen ist auf Android verfügbar.';

  @override
  String get about => 'Über die App';

  @override
  String get back => 'Zurück';

  @override
  String get appPurpose => 'Wofür Sedno da ist';

  @override
  String get appDescription =>
      'Sedno vereinfacht und korrigiert Texte in den unterstützten Sprachen.';

  @override
  String get appAudience =>
      'Für schwerhörige Menschen und Menschen, denen komplexe Texte schwerfallen.';

  @override
  String get appAge => 'Die App ist für Menschen ab 13 Jahren.';

  @override
  String get howItWorks => 'So funktioniert es';

  @override
  String get typingInstructions =>
      'Schreibe oder füge Text ein. Wähle Vereinfachen oder Korrigieren.';

  @override
  String get captureInstructions =>
      'Im Modus Vereinfachen kannst du Text auch fotografieren oder diktieren.';

  @override
  String get captureSubmitInstructions =>
      'Markiere den Text im Foto und wähle Vereinfachen. Diktierter Text wird automatisch vereinfacht.';

  @override
  String get localMediaNotice =>
      'Fotos und Ton bleiben auf dem Telefon. Nur Text wird an die KI gesendet.';

  @override
  String get speechModelRequirements =>
      'Diktieren benötigt Android 13 oder neuer und ein heruntergeladenes deutsches Sprachmodell.';

  @override
  String get playbackRequirements =>
      'Im Modus Korrigieren liest der Lautsprecher den Text vor. Du brauchst eine heruntergeladene deutsche Stimme, die ohne Internet funktioniert.';

  @override
  String get restoreInstructions =>
      'Das Ergebnis erscheint im selben Feld. Tippe auf die Überschrift oder Zurück, um das Original wiederherzustellen.';

  @override
  String get inputLimitNotice => 'Der Text darf höchstens 4000 Zeichen haben.';

  @override
  String get guestNotice => 'Du kannst ohne Konto anfangen.';

  @override
  String get dailyLimit => 'Tageslimit';

  @override
  String get freeAllowance => 'Ohne Abo: 5 Texte pro Tag.';

  @override
  String get paidAllowance => 'Mit Abo: 400 Texte pro Tag.';

  @override
  String get sharedAllowance =>
      'Vereinfachen und Korrigieren teilen sich dasselbe Limit.';

  @override
  String get subscriptionPriceNotice =>
      'Den Abopreis siehst du unter Konto und in Google Play.';

  @override
  String get important => 'Wichtig';

  @override
  String get aiErrorNotice => 'Die KI kann Fehler machen.';

  @override
  String get checkResult => 'Prüfe das Ergebnis, bevor du es verwendest.';

  @override
  String get author => 'Autor: Mariusz Bąbka';

  @override
  String get privacy => 'Datenschutz und Daten';

  @override
  String get websiteOpenFailed =>
      'Website konnte nicht geöffnet werden. Prüfe den Browser.';

  @override
  String get website => 'Sedno-Website';

  @override
  String get photoNoText => 'Kein Text erkannt. Mache ein schärferes Foto.';

  @override
  String get cameraPermission =>
      'Erlaube den Kamerazugriff in den Telefoneinstellungen.';

  @override
  String get cameraStartFailed =>
      'Kamera konnte nicht gestartet werden. Versuche es erneut.';

  @override
  String get photoCaptureFailed =>
      'Foto konnte nicht aufgenommen werden. Versuche es erneut.';

  @override
  String get selectText => 'Text markieren';

  @override
  String get cropInstructions =>
      'Verschiebe die Rahmenecken, um den Text zu markieren. ';

  @override
  String get cropWholePhotoNotice =>
      'Ohne Änderung wird der Text des gesamten Fotos vereinfacht.';

  @override
  String get openingPhoto => 'Foto wird geöffnet';

  @override
  String get simplify => 'Vereinfachen';

  @override
  String get cropTopLeft => 'Obere linke Rahmenecke';

  @override
  String get cropTopRight => 'Obere rechte Rahmenecke';

  @override
  String get cropBottomLeft => 'Untere linke Rahmenecke';

  @override
  String get cropBottomRight => 'Untere rechte Rahmenecke';

  @override
  String get smallerSelection => 'Kleinere Auswahl';

  @override
  String get largerSelection => 'Größere Auswahl';

  @override
  String get cropResizeHint =>
      'Erhöhe den Wert, um die Auswahl zu verkleinern. Verringere ihn, um sie zu vergrößern.';

  @override
  String get takeTextPhoto => 'Text fotografieren';

  @override
  String get startingCamera => 'Kamera wird gestartet';

  @override
  String get takingPhoto => 'Foto wird aufgenommen…';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get photoOpenFailed =>
      'Foto konnte nicht geöffnet werden. Mache ein neues Foto.';

  @override
  String get photoPrepareFailed =>
      'Foto konnte nicht vorbereitet werden. Versuche es erneut.';

  @override
  String get simplifyHeading => 'Text vereinfachen';

  @override
  String get simplifiedText => 'Vereinfachter Text';

  @override
  String get correctedText => 'Korrigierter Text';

  @override
  String get emptyText => 'Der Text darf nicht leer sein.';

  @override
  String get textTooLong => 'Der Text darf höchstens 4000 Zeichen haben.';

  @override
  String get subscriptionActive => 'Dein Abo ist aktiv.';

  @override
  String get subscriptionAllowance =>
      'Du kannst bis zu 400 Texte pro Tag vereinfachen.';

  @override
  String get manageSubscriptionNotice =>
      'Öffne Google Play, um die Zahlung zu ändern oder das Abo zu kündigen.';

  @override
  String get manageSubscription => 'Abo in Google Play verwalten';

  @override
  String get testerAccessNotice => 'Du hast kostenlosen Testzugang.';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get refreshAccess => 'Zugang aktualisieren';

  @override
  String get subscriptionBenefits =>
      'Bis zu 400 Texte pro Tag mit Abo, 5 ohne Abo.';

  @override
  String get subscriptionSignInNotice =>
      'Melde dich bei Sedno an, um ein Abo zu kaufen oder wiederherzustellen.';

  @override
  String get buySubscription => 'Abo kaufen';

  @override
  String get refreshSubscription => 'Abo aktualisieren';

  @override
  String get subscriptionRenewalNotice =>
      'Das Abo verlängert sich jeden Monat automatisch.';

  @override
  String get subscriptionCancelNotice =>
      'Du kannst es jederzeit in Google Play kündigen.';

  @override
  String get paymentReadFailed =>
      'Zahlungen konnten nicht gelesen werden. Stelle die Käufe wieder her.';

  @override
  String get signInBeforePurchase => 'Melde dich vor dem Kauf an.';

  @override
  String get subscriptionAlreadyActive => 'Dein Abo ist bereits aktiv.';

  @override
  String get signInBeforeRestore => 'Melde dich vor der Wiederherstellung an.';

  @override
  String get purchasesChecked =>
      'Käufe geprüft. Die Bestätigung kann einen Moment dauern.';

  @override
  String get playOpenFailed =>
      'Google Play konnte nicht geöffnet werden. Wähle dort Zahlungen und Abos → Abos.';

  @override
  String get paymentPending =>
      'Die Zahlung wartet auf Bestätigung. Dein Limit bleibt gleich.';

  @override
  String get purchaseCancelled => 'Kauf abgebrochen.';

  @override
  String get purchaseFailed =>
      'Abo konnte nicht gekauft werden. Versuche es erneut.';

  @override
  String get subscriptionInactive => 'Dein Abo ist nicht aktiv.';

  @override
  String get subscriptionVerifyFailed =>
      'Abo konnte nicht bestätigt werden. Melde dich an, prüfe die Verbindung und stelle die Käufe wieder her.';

  @override
  String get subscriptionCheckFailed =>
      'Abo konnte nicht geprüft werden. Melde dich an und versuche es erneut.';

  @override
  String get hideConfirmedPassword => 'Wiederholtes Passwort ausblenden';

  @override
  String get showConfirmedPassword => 'Wiederholtes Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get enterEmail => 'Gib deine E-Mail-Adresse ein.';

  @override
  String get enterValidEmail => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get passwordResetSent =>
      'Falls ein Konto mit dieser Adresse existiert, erhältst du einen Link zum Zurücksetzen des Passworts. Prüfe auch den Spamordner.';

  @override
  String get emailSendFailed =>
      'E-Mail konnte nicht gesendet werden. Versuche es erneut.';

  @override
  String get accountLoadFailed =>
      'Konto konnte nicht geladen oder Datenlöschung nicht abgeschlossen werden. Versuche es erneut.';

  @override
  String get verificationEmailSent =>
      'Wir haben eine E-Mail mit einem Link gesendet. Prüfe Posteingang und Spamordner.';

  @override
  String get emailNotVerified =>
      'Die Adresse ist noch nicht bestätigt. Öffne den Link in der E-Mail und versuche es erneut.';

  @override
  String get signInFailed =>
      'Anmeldung fehlgeschlagen. Prüfe deine Angaben und versuche es erneut.';

  @override
  String get signOutFailed => 'Abmeldung fehlgeschlagen. Versuche es erneut.';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountIdentity =>
      'Bestätige deine Identität, um das Konto zu löschen.';

  @override
  String get password => 'Passwort';

  @override
  String get keepAccount => 'Konto behalten';

  @override
  String get deleteAccountAndData => 'Konto und Daten löschen';

  @override
  String get accountDeleted =>
      'Konto und Daten wurden gelöscht. Kündige das Abo separat in Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Löschung konnte nicht abgeschlossen werden. Versuche es erneut.';

  @override
  String get emailAccountMethod => ' (E-Mail und Passwort)';

  @override
  String get finishDataCleanup =>
      'Konto aktualisieren und Bereinigung abschließen';

  @override
  String get accountNotConfigured => 'Hier erscheinen die Kontooptionen.';

  @override
  String get signOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get emailVerified => 'E-Mail-Adresse bestätigt';

  @override
  String get checkInbox => 'Prüfe deine E-Mails';

  @override
  String get finishAccountLinkNotice =>
      'Deine Adresse ist bestätigt. Verbinde jetzt dein Sedno-Konto. Du musst den E-Mail-Link nicht erneut öffnen.';

  @override
  String get verifyEmailInstructions =>
      'Öffne den Link in der E-Mail von Sedno, um das Konto fertig einzurichten. Prüfe auch den Spamordner. Kehre zurück und wähle „Bestätigung prüfen“.';

  @override
  String get guestWhileVerifying =>
      'Bis dahin kannst du die App ohne Konto nutzen.';

  @override
  String get finishSignIn => 'Anmeldung abschließen';

  @override
  String get checkVerification => 'Bestätigung prüfen';

  @override
  String get resendEmail => 'E-Mail erneut senden';

  @override
  String get signOutUseGuest => 'Abmelden und ohne Konto nutzen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get newAccount => 'Neues Konto';

  @override
  String get recoverAccess => 'Zugang wiederherstellen';

  @override
  String get guestSignInNotice => 'Du kannst die App ohne Anmeldung nutzen.';

  @override
  String get signInGoogle => 'Mit Google anmelden';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get enterPassword => 'Gib dein Passwort ein.';

  @override
  String get passwordMinLength => 'Verwende mindestens 6 Zeichen.';

  @override
  String get repeatPassword => 'Passwort wiederholen';

  @override
  String get enterRepeatedPassword => 'Wiederhole dein Passwort.';

  @override
  String get passwordMismatch => 'Die Passwörter müssen übereinstimmen.';

  @override
  String get verificationEmailNotice =>
      'Wir senden eine E-Mail mit einem Link zur Bestätigung der Adresse.';

  @override
  String get passwordResetInstructions =>
      'Gib die E-Mail-Adresse deines Kontos ein. Wir senden einen Link zum Ändern des Passworts.';

  @override
  String get signInEmail => 'Mit E-Mail anmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get sendResetLink => 'Link zum Zurücksetzen senden';

  @override
  String get forgotPassword => 'Passwort vergessen';

  @override
  String get createAccountLink => 'Noch kein Konto? Konto erstellen';

  @override
  String get backToSignIn => 'Zurück zur Anmeldung';

  @override
  String get testerAccess => 'Testzugang';

  @override
  String get testerAllowance =>
      'Du kannst bis zu 400 Texte pro Tag bearbeiten.';

  @override
  String get testerExpiryNotice =>
      'Der Zugang ist kostenlos und endet automatisch.';

  @override
  String get testerHasSubscription =>
      'Du hast auch ein aktives Google-Play-Abo.';

  @override
  String get testerExpired => 'Der Testzugang ist abgelaufen.';

  @override
  String get subscriptionStillActive =>
      'Dein Google-Play-Abo bietet dir weiterhin ein höheres Limit.';

  @override
  String get freeLimitRestored =>
      'Es gilt das kostenlose Limit von 5 Texten pro Tag. Die heutige Nutzung bleibt gleich.';

  @override
  String get closeMenu => 'Menü schließen';

  @override
  String get welcome => 'Willkommen bei Sedno';

  @override
  String get inApp => 'In der App';

  @override
  String get accountCreatedEmailFailed =>
      'Das Konto wurde erstellt, aber die E-Mail konnte nicht gesendet werden. Sende sie erneut.';

  @override
  String get signInToVerify =>
      'Melde dich mit E-Mail an, um die Adresse zu bestätigen.';

  @override
  String get signInToCheckAccount =>
      'Melde dich erneut an, um den Kontostatus zu prüfen.';

  @override
  String get weakPassword =>
      'Das Passwort ist zu schwach. Verwende mindestens 6 Zeichen.';

  @override
  String get checkEmailAddress => 'Prüfe die eingegebene E-Mail-Adresse.';

  @override
  String get emailAlreadyUsed =>
      'Diese Adresse wird bereits verwendet. Melde dich beim vorhandenen Konto an.';

  @override
  String get tooManyAttempts =>
      'Zu viele Versuche. Warte einen Moment und versuche es erneut.';

  @override
  String get checkInternet =>
      'Keine Verbindung. Prüfe das Internet und versuche es erneut.';

  @override
  String get chooseSameAccount => 'Wähle das Konto, das du löschen möchtest.';

  @override
  String get signInToDelete => 'Melde dich erneut an, um das Konto zu löschen.';

  @override
  String get invalidCredentials =>
      'Anmeldung fehlgeschlagen. Prüfe E-Mail-Adresse und Passwort.';

  @override
  String get actionFailed => 'Aktion fehlgeschlagen. Versuche es erneut.';

  @override
  String get accountLinkFailed =>
      'Sedno-Konto konnte nicht verbunden werden. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get passwordToDelete =>
      'Gib das Passwort ein, um die Löschung zu bestätigen.';

  @override
  String get finishLocalDeletion =>
      'Schließe die Datenlöschung auf diesem Gerät ab.';

  @override
  String get installationRejected =>
      'Der Server konnte die Installation nicht prüfen. Versuche es erneut oder installiere Sedno über Google Play.';

  @override
  String get sessionStartFailed =>
      'Sitzung konnte nicht gestartet werden. Versuche es erneut.';

  @override
  String get signInToLink => 'Melde dich erneut an, um das Konto zu verbinden.';

  @override
  String get cannotLinkAccount =>
      'Konto konnte nicht verbunden werden. Versuche es erneut.';

  @override
  String get signInAgain => 'Melde dich erneut an.';

  @override
  String get sessionExpiredSignIn =>
      'Die Sitzung ist abgelaufen. Melde dich erneut an.';

  @override
  String get cannotDeleteAccount =>
      'Konto konnte nicht gelöscht werden. Versuche es erneut.';

  @override
  String get cannotSignOut => 'Abmeldung nicht möglich. Versuche es erneut.';

  @override
  String get correctionUnavailable => 'Textkorrektur ist noch nicht verfügbar.';

  @override
  String get simplificationUnavailable =>
      'Textvereinfachung ist noch nicht verfügbar.';

  @override
  String get requestTimeout => 'Zeitlimit überschritten. Versuche es erneut.';

  @override
  String get offline => 'Keine Internetverbindung. Versuche es erneut.';

  @override
  String get sessionExpired =>
      'Die Sitzung ist abgelaufen. Prüfe das Konto und versuche es erneut.';

  @override
  String get quotaExhausted =>
      'Dein Tageslimit ist erreicht. Prüfe die Zeit der Erneuerung.';

  @override
  String get serviceUnavailable =>
      'Der Dienst ist vorübergehend nicht verfügbar. Versuche es erneut.';

  @override
  String get correctionRejected =>
      'Dieser Text kann nicht korrigiert werden. Prüfe ihn und versuche es erneut.';

  @override
  String get simplificationRejected =>
      'Dieser Text kann nicht vereinfacht werden. Prüfe ihn und versuche es erneut.';

  @override
  String get correctionFailed =>
      'Textkorrektur fehlgeschlagen. Versuche es erneut.';

  @override
  String get simplificationFailed =>
      'Textvereinfachung fehlgeschlagen. Versuche es erneut.';

  @override
  String get checkConnection => 'Verbindung prüfen';

  @override
  String get quotaCheckFailed =>
      'Limit konnte nicht geprüft werden. Prüfe die Verbindung.';

  @override
  String get subscriptionInAccount => 'Abo und Preis findest du unter Konto.';

  @override
  String get beforeCorrection => 'Bevor du Text korrigierst';

  @override
  String get beforeSimplification => 'Bevor du Text vereinfachst';

  @override
  String get acceptAndSend => 'Verstanden, senden';

  @override
  String get cameraUnavailable => 'Die Kamera ist bald verfügbar.';

  @override
  String get aiWarning => 'Die KI kann sich irren';

  @override
  String get listeningNotice =>
      'Ich höre zu… Sprich Deutsch. Ende nach 1,5 Sekunden Stille oder 60 Sekunden. Die Stopptaste bricht die Aufnahme ab.';

  @override
  String get correctionSubmitted => 'Der Text wurde zur Korrektur gesendet.';

  @override
  String get simplificationSubmitted =>
      'Der Text wurde zur Vereinfachung gesendet.';

  @override
  String get textForCorrection => 'Text zum Korrigieren';

  @override
  String get textForSimplification => 'Text zum Vereinfachen';

  @override
  String get inputHint => 'Text schreiben oder einfügen';

  @override
  String get switchToCorrection => 'Zur Textkorrektur wechseln';

  @override
  String get switchToSimplification => 'Zur Textvereinfachung wechseln';

  @override
  String get clearText => 'Text löschen';

  @override
  String get stopPlayback => 'Vorlesen stoppen';

  @override
  String get readAloud => 'Text vorlesen';

  @override
  String get cancelRecording => 'Aufnahme abbrechen';

  @override
  String get simplifySpeech => 'Gesprochenes vereinfachen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get history => 'Verlauf';

  @override
  String get account => 'Konto';

  @override
  String get start => 'Start';

  @override
  String get contact => 'Kontakt';

  @override
  String get close => 'Schließen';

  @override
  String get continueAction => 'Weiter';

  @override
  String get correct => 'Korrigieren';

  @override
  String get correctHeading => 'Text korrigieren';

  @override
  String get correcting => 'Korrektur…';

  @override
  String get simplifying => 'Vereinfachung…';

  @override
  String get reading => 'Text wird gelesen…';

  @override
  String get camera => 'Kamera';

  @override
  String get preparing => 'Vorbereitung…';

  @override
  String get subscription => 'Abo';

  @override
  String get yesterday => 'Gestern';

  @override
  String get signedIn => 'Angemeldet.';

  @override
  String get googleAccountMethod => ' (Google-Konto)';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Telefonsprache';

  @override
  String get polish => 'Polnisch';

  @override
  String get english => 'Englisch (UK)';

  @override
  String get languageNotice =>
      'Die Sprache gilt für Menüs, Vereinfachung, Korrektur und Spracheingabe. Wähle die Sprache deines Textes. Sedno übersetzt keine Texte.';

  @override
  String get languageSaveFailed =>
      'Sprache konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String resetDaily(String time) {
    return 'Dein Limit wird täglich um $time erneuert.';
  }

  @override
  String resetAbout(String time) {
    return 'Dein Limit wird täglich um $time erneuert (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Dein Limit wird um $time erneuert.';
  }

  @override
  String get quotaUsed => 'Dein heutiges Limit ist aufgebraucht.';

  @override
  String get quotaOneSimplification => 'Noch 1 Vereinfachung verfügbar.';

  @override
  String get quotaOneUse => 'Noch 1 KI-Nutzung verfügbar.';

  @override
  String get quotaUsedDialog => 'Das Tageslimit ist erreicht.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Dein Limit wird um $time erneuert ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'in $hours Std. $minutes Min.';
  }

  @override
  String monthlyPrice(String price) {
    return '$price pro Monat';
  }

  @override
  String historyExpires(String date) {
    return 'Wird am $date gelöscht.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Text vom $date löschen';
  }

  @override
  String contactAddress(String email) {
    return 'Kontakt: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Angemeldet als $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'E-Mail-Adresse: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Zu bestätigende Adresse: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Erneut senden in $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Testzugang bis $date (Ortszeit).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal $horizontal %, vertikal $vertical %';
  }

  @override
  String welcomeName(String name) {
    return 'Willkommen bei $name';
  }

  @override
  String policyVersion(String date) {
    return 'Version: $date';
  }

  @override
  String get speechModelDownloading =>
      'Das Sprachmodell wird heruntergeladen. Versuche es später erneut.';

  @override
  String get speechLanguageUnsupported =>
      'Die Sprachsoftware dieses Telefons bietet diese Sprache nicht für lokale Diktate an. Du kannst Text eingeben oder die Kamera nutzen.';

  @override
  String get signInApple => 'Mit Apple anmelden';

  @override
  String get appleAccountMethod => 'Apple';

  @override
  String get signInCancelled => 'Anmeldung abgebrochen.';

  @override
  String get accountMethodConflict =>
      'Dieses Konto verwendet eine andere Anmeldemethode. Verwende deine bisherige Methode.';

  @override
  String get localSpeechUnavailable =>
      'Die lokale Spracherkennung ist für diese Sprache auf diesem Gerät nicht verfügbar.';

  @override
  String get localSpeechModelMissing =>
      'Installiere das lokale Sprachmodell in den Geräteeinstellungen.';

  @override
  String get deviceFeatureUnavailable =>
      'Diese Funktion ist auf diesem Gerät nicht verfügbar.';

  @override
  String get subscriptionOtherStore =>
      'Dieses Abo wurde in einem anderen Store gekauft. Verwalte es dort, wo du es gekauft hast.';

  @override
  String get storeOpenFailed =>
      'Die Aboeinstellungen konnten nicht geöffnet werden. Versuche es erneut.';

  @override
  String get appleManageSubscriptionNotice =>
      'Öffne App Store, um die Zahlung zu ändern oder das Abo zu kündigen.';

  @override
  String get appleManageSubscription => 'Abo in App Store verwalten';

  @override
  String get appleSubscriptionCancelNotice =>
      'Du kannst es jederzeit in App Store kündigen.';

  @override
  String get appleAccountDeleted =>
      'Konto und Daten wurden gelöscht. Kündige das Abo separat in App Store.';

  @override
  String get appleTesterHasSubscription =>
      'Du hast auch ein aktives Google-Play-Abo.';

  @override
  String get appleSubscriptionStillActive =>
      'Dein Google-Play-Abo bietet dir weiterhin ein höheres Limit.';

  @override
  String get appleInstallationRejected =>
      'Der Server konnte die Installation nicht prüfen. Versuche es erneut oder installiere Sedno über App Store.';

  @override
  String get appleSubscriptionPriceNotice =>
      'Den Abopreis siehst du unter Konto und in App Store.';

  @override
  String get privacyIosSupplementTitle =>
      'Zusätzliche Informationen für das iPhone';

  @override
  String get privacyIosSupplementBody =>
      'Die folgenden Verweise auf Android, Google Play und Play Integrity gelten nur für Android. Auf dem iPhone können Sie sich mit Apple anmelden und Ihre E-Mail-Adresse verbergen. Auch Firebase verarbeitet die Anmeldung. Apple rechnet im App Store gekaufte Abonnements ab; Sedno erhält keine Kartendaten. Das Löschen des Kontos kündigt kein Abonnement.\n\nApp Attest prüft die Echtheit der App, ohne Texte, Ergebnisse oder Fotos an Apple zu senden. Der Server speichert pseudonyme Installationsdaten und öffentliche Schlüssel. Prüfaufgaben gelten 5 Minuten, Schlüssel 90 Tage nach der letzten erfolgreichen Sitzungsprüfung. Kaufbenachrichtigungen werden 30 Tage gespeichert. Ein Serverauftrag entfernt abgelaufene Einträge. Kaufmetadaten bleiben bis zur Kontolöschung.\n\nDer Verlauf ist verschlüsselt, lokal, von Sicherungen ausgeschlossen und verfällt nach 7 Tagen. Fotos und Audio bleiben auf dem Gerät. Diktieren und Vorlesen funktionieren ausschließlich lokal, wenn Gerät und Sprache dies unterstützen. Erkannten Text senden Sie nach Zustimmung zum KI-Hinweis über Sedno an OpenAI.\n\nDie übrigen Angaben unten, darunter Verantwortlicher, Zwecke, Rechtsgrundlagen und OpenAI-Praktiken, gelten auch für das iPhone. Apple-Datenschutz: https://www.apple.com/legal/privacy/';

  @override
  String get linkApple => 'Apple-Konto verknüpfen';

  @override
  String get confirmAccountLink =>
      'Bestätigen Sie Ihr aktuelles Konto erneut. Wählen Sie dann ein Apple-Konto, um sich bei demselben Sedno-Konto anzumelden.';

  @override
  String get passwordToLink =>
      'Geben Sie das Passwort Ihres aktuellen Kontos ein, um es mit Apple zu verknüpfen.';

  @override
  String get linkGoogle => 'Google-Konto verknüpfen';

  @override
  String get confirmGoogleAccountLink =>
      'Bestätigen Sie Ihr aktuelles Konto erneut. Wählen Sie dann ein Google-Konto, um sich beim selben Sedno-Konto anzumelden.';

  @override
  String get passwordToLinkGoogle =>
      'Geben Sie das Passwort Ihres aktuellen Kontos ein, um Google zu verknüpfen.';
}
