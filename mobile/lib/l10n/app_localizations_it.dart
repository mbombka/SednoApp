// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get restoreOriginal => 'Ripristina il testo originale';

  @override
  String get userMenu => 'Menu utente';

  @override
  String get speechNotRecognised => 'Nessuna voce riconosciuta. Riprova.';

  @override
  String get speechFailed => 'Riconoscimento vocale non riuscito. Riprova.';

  @override
  String get microphonePermission =>
      'Consenti l’accesso al microfono nelle impostazioni dell’app.';

  @override
  String get speechRequirements =>
      'Il riconoscimento locale richiede Android 13 o successivo e un motore vocale compatibile.';

  @override
  String get speechModelMissing =>
      'Scarica il modello vocale italiano nelle impostazioni di riconoscimento vocale Android.';

  @override
  String get speechTimeout =>
      'Il riconoscimento ha richiesto troppo tempo. Riprova.';

  @override
  String get speechAndroidOnly =>
      'Il riconoscimento locale è disponibile da Android 13.';

  @override
  String get historyClearFailed =>
      'Impossibile eliminare tutta la cronologia. Riprova.';

  @override
  String get deleteHistoryEntryTitle =>
      'Eliminare questo testo dalla cronologia?';

  @override
  String get cannotUndo => 'L’azione non può essere annullata.';

  @override
  String get delete => 'Elimina';

  @override
  String get historyEntryDeleted => 'Testo eliminato.';

  @override
  String get deleteHistoryTitle => 'Eliminare tutta la cronologia?';

  @override
  String get deleteHistoryNotice =>
      'Tutti i testi salvati verranno eliminati da questo telefono. L’azione non può essere annullata.';

  @override
  String get deleteAllHistory => 'Elimina tutta la cronologia';

  @override
  String get historyDeleted => 'Cronologia eliminata.';

  @override
  String get historyLocalNotice =>
      'I testi sono salvati solo su questo telefono.';

  @override
  String get historyRetentionNotice =>
      'Ogni testo viene eliminato automaticamente dopo 7 giorni.';

  @override
  String get historySignOutNotice =>
      'Uscire dall’account elimina tutta la cronologia.';

  @override
  String get deleteHistoryNow => 'Elimina tutta la cronologia ora';

  @override
  String get deletingHistory => 'Eliminazione della cronologia';

  @override
  String get loadingHistory => 'Caricamento della cronologia';

  @override
  String get historyLoadFailed => 'Impossibile caricare la cronologia.';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get historyEmpty => 'Non hai ancora testi salvati.';

  @override
  String get historyEmptyNotice =>
      'I testi semplificati o corretti appariranno qui.';

  @override
  String get correctedVersion => 'Versione corretta';

  @override
  String get simplifiedVersion => 'Versione semplice';

  @override
  String get originalText => 'Testo originale';

  @override
  String get hideOriginal => 'Nascondi originale';

  @override
  String get showOriginal => 'Mostra originale';

  @override
  String get today => 'Oggi';

  @override
  String get readTextFailed => 'Impossibile leggere il testo. Riprova.';

  @override
  String get voiceMissing =>
      'Verifica che sul telefono sia scaricata una voce italiana per la lettura senza Internet.';

  @override
  String get playbackAndroidOnly =>
      'La lettura ad alta voce è disponibile su Android.';

  @override
  String get about => 'Informazioni';

  @override
  String get back => 'Indietro';

  @override
  String get appPurpose => 'A cosa serve Sedno';

  @override
  String get appDescription =>
      'Sedno semplifica e corregge testi nelle lingue supportate.';

  @override
  String get appAudience =>
      'Per persone con difficoltà uditive o che faticano a capire testi complessi.';

  @override
  String get appAge => 'L’app è destinata a persone dai 13 anni in su.';

  @override
  String get howItWorks => 'Come funziona';

  @override
  String get typingInstructions =>
      'Scrivi o incolla un testo. Scegli Semplifica o Correggi.';

  @override
  String get captureInstructions =>
      'In modalità Semplifica puoi anche fotografare il testo o dettarlo.';

  @override
  String get captureSubmitInstructions =>
      'Seleziona il testo nella foto e scegli Semplifica. Il testo dettato viene semplificato automaticamente.';

  @override
  String get localMediaNotice =>
      'Foto e audio restano sul telefono. Solo il testo viene inviato all’IA.';

  @override
  String get speechModelRequirements =>
      'La dettatura richiede Android 13 o successivo e un modello vocale italiano scaricato.';

  @override
  String get playbackRequirements =>
      'In modalità Correggi, l’altoparlante legge il testo. Serve una voce italiana scaricata che funzioni senza Internet.';

  @override
  String get restoreInstructions =>
      'Il risultato appare nello stesso campo. Tocca il titolo o Indietro per ripristinare l’originale.';

  @override
  String get inputLimitNotice =>
      'Il testo può contenere al massimo 4000 caratteri.';

  @override
  String get guestNotice => 'Puoi iniziare senza creare un account.';

  @override
  String get dailyLimit => 'Limite giornaliero';

  @override
  String get freeAllowance => 'Senza abbonamento: 5 testi al giorno.';

  @override
  String get paidAllowance => 'Con abbonamento: 400 testi al giorno.';

  @override
  String get sharedAllowance =>
      'Semplificazione e correzione condividono lo stesso limite.';

  @override
  String get subscriptionPriceNotice =>
      'Il prezzo dell’abbonamento è in Account e su Google Play.';

  @override
  String get important => 'Importante';

  @override
  String get aiErrorNotice => 'L’IA può commettere errori.';

  @override
  String get checkResult => 'Controlla il risultato prima di usarlo.';

  @override
  String get author => 'Autore: Mariusz Bąbka';

  @override
  String get privacy => 'Privacy e dati';

  @override
  String get websiteOpenFailed =>
      'Impossibile aprire il sito. Controlla il browser.';

  @override
  String get website => 'Sito di Sedno';

  @override
  String get photoNoText =>
      'Nessun testo rilevato. Scatta una foto più nitida.';

  @override
  String get cameraPermission =>
      'Consenti l’accesso alla fotocamera nelle impostazioni del telefono.';

  @override
  String get cameraStartFailed => 'Impossibile avviare la fotocamera. Riprova.';

  @override
  String get photoCaptureFailed => 'Impossibile scattare la foto. Riprova.';

  @override
  String get selectText => 'Seleziona il testo';

  @override
  String get cropInstructions =>
      'Sposta gli angoli del riquadro per selezionare il testo. ';

  @override
  String get cropWholePhotoNotice =>
      'Senza modifiche, verrà semplificato il testo dell’intera foto.';

  @override
  String get openingPhoto => 'Apertura della foto';

  @override
  String get simplify => 'Semplifica';

  @override
  String get cropTopLeft => 'Angolo superiore sinistro del riquadro';

  @override
  String get cropTopRight => 'Angolo superiore destro del riquadro';

  @override
  String get cropBottomLeft => 'Angolo inferiore sinistro del riquadro';

  @override
  String get cropBottomRight => 'Angolo inferiore destro del riquadro';

  @override
  String get smallerSelection => 'Selezione più piccola';

  @override
  String get largerSelection => 'Selezione più grande';

  @override
  String get cropResizeHint =>
      'Aumenta per ridurre la selezione. Diminuisci per ingrandirla.';

  @override
  String get takeTextPhoto => 'Fotografa un testo';

  @override
  String get startingCamera => 'Avvio della fotocamera';

  @override
  String get takingPhoto => 'Scatto della foto…';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get photoOpenFailed =>
      'Impossibile aprire la foto. Scattane una nuova.';

  @override
  String get photoPrepareFailed => 'Impossibile preparare la foto. Riprova.';

  @override
  String get simplifyHeading => 'semplifica testo';

  @override
  String get simplifiedText => 'Testo semplificato';

  @override
  String get correctedText => 'Testo corretto';

  @override
  String get emptyText => 'Il testo non può essere vuoto.';

  @override
  String get textTooLong => 'Il testo può contenere al massimo 4000 caratteri.';

  @override
  String get subscriptionActive => 'L’abbonamento è attivo.';

  @override
  String get subscriptionAllowance =>
      'Puoi semplificare fino a 400 testi al giorno.';

  @override
  String get manageSubscriptionNotice =>
      'Per modificare il pagamento o annullare l’abbonamento, apri Google Play.';

  @override
  String get manageSubscription => 'Gestisci abbonamento su Google Play';

  @override
  String get testerAccessNotice => 'Hai accesso gratuito come tester.';

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get refreshAccess => 'Aggiorna accesso';

  @override
  String get subscriptionBenefits =>
      'Fino a 400 testi al giorno con abbonamento, 5 senza.';

  @override
  String get subscriptionSignInNotice =>
      'Accedi al tuo account Sedno per acquistare o ripristinare un abbonamento.';

  @override
  String get buySubscription => 'Acquista abbonamento';

  @override
  String get refreshSubscription => 'Aggiorna abbonamento';

  @override
  String get subscriptionRenewalNotice =>
      'L’abbonamento si rinnova automaticamente ogni mese.';

  @override
  String get subscriptionCancelNotice =>
      'Puoi annullarlo in qualsiasi momento su Google Play.';

  @override
  String get paymentReadFailed =>
      'Impossibile leggere i pagamenti. Prova a ripristinare gli acquisti.';

  @override
  String get signInBeforePurchase => 'Accedi prima dell’acquisto.';

  @override
  String get subscriptionAlreadyActive => 'L’abbonamento è già attivo.';

  @override
  String get signInBeforeRestore => 'Accedi prima di ripristinare un acquisto.';

  @override
  String get purchasesChecked =>
      'Acquisti verificati. La conferma può richiedere un momento.';

  @override
  String get playOpenFailed =>
      'Impossibile aprire Google Play. Apri lo store e scegli Pagamenti e abbonamenti → Abbonamenti.';

  @override
  String get paymentPending =>
      'Il pagamento attende conferma. Il limite resta invariato.';

  @override
  String get purchaseCancelled => 'Acquisto annullato.';

  @override
  String get purchaseFailed =>
      'Acquisto dell’abbonamento non riuscito. Riprova.';

  @override
  String get subscriptionInactive => 'L’abbonamento non è attivo.';

  @override
  String get subscriptionVerifyFailed =>
      'Impossibile confermare l’abbonamento. Accedi, controlla la connessione e ripristina gli acquisti.';

  @override
  String get subscriptionCheckFailed =>
      'Impossibile verificare l’abbonamento. Accedi e riprova.';

  @override
  String get hideConfirmedPassword => 'Nascondi password ripetuta';

  @override
  String get showConfirmedPassword => 'Mostra password ripetuta';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get enterEmail => 'Inserisci l’indirizzo e-mail.';

  @override
  String get enterValidEmail => 'Inserisci un indirizzo e-mail valido.';

  @override
  String get passwordResetSent =>
      'Se esiste un account con questo indirizzo, riceverai un link per reimpostare la password. Controlla anche lo spam.';

  @override
  String get emailSendFailed => 'Invio dell’e-mail non riuscito. Riprova.';

  @override
  String get accountLoadFailed =>
      'Impossibile caricare l’account o completare l’eliminazione dei dati. Riprova.';

  @override
  String get verificationEmailSent =>
      'Abbiamo inviato un’e-mail con un link. Controlla la posta in arrivo e lo spam.';

  @override
  String get emailNotVerified =>
      'L’indirizzo non è ancora confermato. Apri il link nell’e-mail e riprova.';

  @override
  String get signInFailed =>
      'Accesso non riuscito. Controlla i dati e riprova.';

  @override
  String get signOutFailed => 'Uscita non riuscita. Riprova.';

  @override
  String get deleteAccountTitle => 'Eliminare l’account?';

  @override
  String get deleteAccountIdentity =>
      'Conferma la tua identità per eliminare l’account.';

  @override
  String get password => 'Password';

  @override
  String get keepAccount => 'Mantieni account';

  @override
  String get deleteAccountAndData => 'Elimina account e dati';

  @override
  String get accountDeleted =>
      'Account e dati eliminati. Annulla separatamente l’abbonamento su Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Impossibile completare l’eliminazione. Riprova.';

  @override
  String get emailAccountMethod => ' (e-mail e password)';

  @override
  String get finishDataCleanup => 'Aggiorna l’account e completa la pulizia';

  @override
  String get accountNotConfigured => 'Le opzioni dell’account appariranno qui.';

  @override
  String get signOut => 'Esci';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get emailVerified => 'Indirizzo e-mail confermato';

  @override
  String get checkInbox => 'Controlla la posta';

  @override
  String get finishAccountLinkNotice =>
      'L’indirizzo è confermato. Resta da collegare l’account Sedno. Non serve aprire di nuovo il link nell’e-mail.';

  @override
  String get verifyEmailInstructions =>
      'Apri il link nell’e-mail di Sedno per completare la creazione dell’account. Controlla anche lo spam. Poi torna qui e scegli «Verifica conferma».';

  @override
  String get guestWhileVerifying =>
      'Nel frattempo puoi usare l’app senza account.';

  @override
  String get finishSignIn => 'Completa accesso';

  @override
  String get checkVerification => 'Verifica conferma';

  @override
  String get resendEmail => 'Invia di nuovo l’e-mail';

  @override
  String get signOutUseGuest => 'Esci e usa senza account';

  @override
  String get signIn => 'Accedi';

  @override
  String get newAccount => 'Nuovo account';

  @override
  String get recoverAccess => 'Recupera accesso';

  @override
  String get guestSignInNotice => 'Puoi usare l’app senza accedere.';

  @override
  String get signInGoogle => 'Accedi con Google';

  @override
  String get emailAddress => 'Indirizzo e-mail';

  @override
  String get enterPassword => 'Inserisci la password.';

  @override
  String get passwordMinLength => 'Usa almeno 6 caratteri.';

  @override
  String get repeatPassword => 'Ripeti password';

  @override
  String get enterRepeatedPassword => 'Ripeti la password.';

  @override
  String get passwordMismatch => 'Le password devono coincidere.';

  @override
  String get verificationEmailNotice =>
      'Invieremo un’e-mail con un link per confermare l’indirizzo.';

  @override
  String get passwordResetInstructions =>
      'Inserisci l’e-mail del tuo account. Invieremo un link per cambiare la password.';

  @override
  String get signInEmail => 'Accedi con e-mail';

  @override
  String get createAccount => 'Crea account';

  @override
  String get sendResetLink => 'Invia link per reimpostare la password';

  @override
  String get forgotPassword => 'Password dimenticata';

  @override
  String get createAccountLink => 'Non hai un account? Crealo';

  @override
  String get backToSignIn => 'Torna all’accesso';

  @override
  String get testerAccess => 'Accesso tester';

  @override
  String get testerAllowance => 'Puoi elaborare fino a 400 testi al giorno.';

  @override
  String get testerExpiryNotice =>
      'L’accesso è gratuito e scade automaticamente.';

  @override
  String get testerHasSubscription =>
      'Hai anche un abbonamento Google Play attivo.';

  @override
  String get testerExpired => 'L’accesso tester è scaduto.';

  @override
  String get subscriptionStillActive =>
      'L’abbonamento Google Play continua a offrire un limite maggiore.';

  @override
  String get freeLimitRestored =>
      'Si applica il limite gratuito di 5 testi al giorno. L’utilizzo di oggi resta invariato.';

  @override
  String get closeMenu => 'Chiudi menu';

  @override
  String get welcome => 'Benvenuto in Sedno';

  @override
  String get inApp => 'Nell’app';

  @override
  String get accountCreatedEmailFailed =>
      'Account creato, ma invio dell’e-mail non riuscito. Prova a inviarla di nuovo.';

  @override
  String get signInToVerify => 'Accedi con e-mail per confermare l’indirizzo.';

  @override
  String get signInToCheckAccount =>
      'Accedi di nuovo per verificare lo stato dell’account.';

  @override
  String get weakPassword => 'Password troppo debole. Usa almeno 6 caratteri.';

  @override
  String get checkEmailAddress => 'Controlla l’indirizzo e-mail inserito.';

  @override
  String get emailAlreadyUsed =>
      'Questo indirizzo è già usato. Accedi all’account esistente.';

  @override
  String get tooManyAttempts =>
      'Troppi tentativi. Attendi un momento e riprova.';

  @override
  String get checkInternet =>
      'Nessuna connessione. Controlla Internet e riprova.';

  @override
  String get chooseSameAccount => 'Scegli l’account che vuoi eliminare.';

  @override
  String get signInToDelete => 'Accedi di nuovo per eliminare l’account.';

  @override
  String get invalidCredentials =>
      'Accesso non riuscito. Controlla e-mail e password.';

  @override
  String get actionFailed => 'Operazione non riuscita. Riprova.';

  @override
  String get accountLinkFailed =>
      'Impossibile collegare l’account Sedno. Controlla la connessione e riprova.';

  @override
  String get passwordToDelete =>
      'Inserisci la password per confermare l’eliminazione.';

  @override
  String get finishLocalDeletion =>
      'Completa l’eliminazione dei dati su questo dispositivo.';

  @override
  String get installationRejected =>
      'Il server non ha verificato l’installazione. Riprova o installa Sedno da Google Play.';

  @override
  String get sessionStartFailed => 'Impossibile avviare la sessione. Riprova.';

  @override
  String get signInToLink => 'Accedi di nuovo per collegare l’account.';

  @override
  String get cannotLinkAccount => 'Impossibile collegare l’account. Riprova.';

  @override
  String get signInAgain => 'Accedi di nuovo.';

  @override
  String get sessionExpiredSignIn => 'La sessione è scaduta. Accedi di nuovo.';

  @override
  String get cannotDeleteAccount => 'Impossibile eliminare l’account. Riprova.';

  @override
  String get cannotSignOut => 'Impossibile uscire. Riprova.';

  @override
  String get correctionUnavailable => 'La correzione non è ancora disponibile.';

  @override
  String get simplificationUnavailable =>
      'La semplificazione non è ancora disponibile.';

  @override
  String get requestTimeout => 'Tempo scaduto. Riprova.';

  @override
  String get offline => 'Nessuna connessione Internet. Riprova.';

  @override
  String get sessionExpired =>
      'La sessione è scaduta. Controlla l’account e riprova.';

  @override
  String get quotaExhausted =>
      'Hai esaurito il limite di oggi. Controlla l’orario di rinnovo.';

  @override
  String get serviceUnavailable =>
      'Servizio temporaneamente non disponibile. Riprova.';

  @override
  String get correctionRejected =>
      'Impossibile correggere questo testo. Controllalo e riprova.';

  @override
  String get simplificationRejected =>
      'Impossibile semplificare questo testo. Controllalo e riprova.';

  @override
  String get correctionFailed => 'Correzione non riuscita. Riprova.';

  @override
  String get simplificationFailed => 'Semplificazione non riuscita. Riprova.';

  @override
  String get checkConnection => 'Controlla la connessione';

  @override
  String get quotaCheckFailed =>
      'Impossibile verificare il limite. Controlla la connessione.';

  @override
  String get subscriptionInAccount => 'Abbonamento e prezzo sono in Account.';

  @override
  String get beforeCorrection => 'Prima di correggere il testo';

  @override
  String get beforeSimplification => 'Prima di semplificare il testo';

  @override
  String get acceptAndSend => 'Ho capito, invia';

  @override
  String get cameraUnavailable => 'La fotocamera sarà presto disponibile.';

  @override
  String get aiWarning => 'L’IA può sbagliare';

  @override
  String get listeningNotice =>
      'Ascolto… Parla italiano. Fine dopo 1,5 secondi di silenzio o 60 secondi. Il pulsante di arresto annulla la registrazione.';

  @override
  String get correctionSubmitted => 'Testo inviato per la correzione.';

  @override
  String get simplificationSubmitted => 'Testo inviato per la semplificazione.';

  @override
  String get textForCorrection => 'Testo da correggere';

  @override
  String get textForSimplification => 'Testo da semplificare';

  @override
  String get inputHint => 'Scrivi o incolla un testo';

  @override
  String get switchToCorrection => 'Passa alla correzione';

  @override
  String get switchToSimplification => 'Passa alla semplificazione';

  @override
  String get clearText => 'Cancella testo';

  @override
  String get stopPlayback => 'Interrompi lettura';

  @override
  String get readAloud => 'Leggi ad alta voce';

  @override
  String get cancelRecording => 'Annulla registrazione';

  @override
  String get simplifySpeech => 'Semplifica la voce';

  @override
  String get cancel => 'Annulla';

  @override
  String get history => 'Cronologia';

  @override
  String get account => 'Account';

  @override
  String get start => 'Inizio';

  @override
  String get contact => 'Contatti';

  @override
  String get close => 'Chiudi';

  @override
  String get continueAction => 'Continua';

  @override
  String get correct => 'Correggi';

  @override
  String get correctHeading => 'correggi testo';

  @override
  String get correcting => 'Correzione…';

  @override
  String get simplifying => 'Semplificazione…';

  @override
  String get reading => 'Lettura…';

  @override
  String get camera => 'Fotocamera';

  @override
  String get preparing => 'Preparazione…';

  @override
  String get subscription => 'Abbonamento';

  @override
  String get yesterday => 'Ieri';

  @override
  String get signedIn => 'Accesso effettuato.';

  @override
  String get googleAccountMethod => ' (account Google)';

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Lingua del telefono';

  @override
  String get polish => 'Polacco';

  @override
  String get english => 'Inglese (Regno Unito)';

  @override
  String get languageNotice =>
      'La lingua si applica a menu, semplificazione, correzione e voce. Scegli la lingua del testo. Sedno non traduce i testi.';

  @override
  String get languageSaveFailed => 'Impossibile salvare la lingua. Riprova.';

  @override
  String resetDaily(String time) {
    return 'Il limite si rinnova ogni giorno alle $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Il limite si rinnova ogni giorno alle $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Il limite si rinnova alle $time.';
  }

  @override
  String get quotaUsed => 'Hai esaurito il limite di oggi.';

  @override
  String get quotaOneSimplification => 'Resta 1 semplificazione.';

  @override
  String get quotaOneUse => 'Resta 1 utilizzo dell’IA.';

  @override
  String get quotaUsedDialog => 'Limite giornaliero esaurito.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Il limite si rinnova alle $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'tra $hours h e $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price al mese';
  }

  @override
  String historyExpires(String date) {
    return 'Verrà eliminato il $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Elimina il testo salvato il $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contatto: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Accesso come $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Indirizzo e-mail: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Indirizzo da confermare: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Invia di nuovo tra $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Accesso tester fino al $date (ora locale).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Orizzontale $horizontal%, verticale $vertical%';
  }

  @override
  String welcomeName(String name) {
    return 'Benvenuto in $name';
  }

  @override
  String policyVersion(String date) {
    return 'Versione: $date';
  }

  @override
  String get speechModelDownloading =>
      'Download del modello vocale in corso. Riprova più tardi.';

  @override
  String get speechLanguageUnsupported =>
      'Il motore vocale di questo telefono non offre la dettatura locale in questa lingua. Puoi scrivere o usare la fotocamera.';
}
