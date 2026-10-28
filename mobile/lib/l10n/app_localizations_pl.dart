// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get restoreOriginal => 'Przywróć oryginalny tekst';

  @override
  String get userMenu => 'Menu użytkownika';

  @override
  String get speechNotRecognised => 'Nie rozpoznano mowy. Spróbuj ponownie.';

  @override
  String get speechFailed => 'Nie udało się rozpoznać mowy. Spróbuj ponownie.';

  @override
  String get microphonePermission =>
      'Aby użyć mowy, zezwól na dostęp do mikrofonu w ustawieniach aplikacji.';

  @override
  String get speechRequirements =>
      'Lokalne rozpoznawanie mowy wymaga Androida 13 lub nowszego i obsługującego je silnika mowy.';

  @override
  String get speechModelMissing =>
      'Brak lokalnego modelu języka polskiego. Pobierz go w ustawieniach rozpoznawania mowy Androida.';

  @override
  String get speechTimeout =>
      'Rozpoznawanie trwało zbyt długo. Spróbuj ponownie.';

  @override
  String get speechAndroidOnly =>
      'Lokalne rozpoznawanie mowy jest dostępne na Androidzie 13 lub nowszym.';

  @override
  String get historyClearFailed =>
      'Nie udało się usunąć całej historii. Spróbuj ponownie.';

  @override
  String get deleteHistoryEntryTitle => 'Usunąć ten tekst z historii?';

  @override
  String get cannotUndo => 'Tego nie można cofnąć.';

  @override
  String get delete => 'Usuń';

  @override
  String get historyEntryDeleted => 'Usunięto tekst.';

  @override
  String get deleteHistoryTitle => 'Usunąć całą historię?';

  @override
  String get deleteHistoryNotice =>
      'Wszystkie zapisane teksty zostaną usunięte z tego telefonu. Tego nie można cofnąć.';

  @override
  String get deleteAllHistory => 'Usuń całą historię';

  @override
  String get historyDeleted => 'Usunięto całą historię.';

  @override
  String get historyLocalNotice => 'Teksty są zapisane tylko na tym telefonie.';

  @override
  String get historyRetentionNotice => 'Każdy tekst usuwa się sam po 7 dniach.';

  @override
  String get historySignOutNotice => 'Wylogowanie usuwa całą historię.';

  @override
  String get deleteHistoryNow => 'Usuń całą historię teraz';

  @override
  String get deletingHistory => 'Usuwanie historii';

  @override
  String get loadingHistory => 'Wczytywanie historii';

  @override
  String get historyLoadFailed => 'Nie udało się wczytać historii.';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get historyEmpty => 'Nie masz jeszcze zapisanych tekstów.';

  @override
  String get historyEmptyNotice =>
      'Każdy uproszczony lub poprawiony tekst pojawi się tutaj.';

  @override
  String get correctedVersion => 'Wersja poprawiona';

  @override
  String get simplifiedVersion => 'Wersja prosta';

  @override
  String get originalText => 'Oryginalny tekst';

  @override
  String get hideOriginal => 'Ukryj oryginał';

  @override
  String get showOriginal => 'Pokaż oryginał';

  @override
  String get today => 'Dziś';

  @override
  String get readTextFailed =>
      'Nie udało się odczytać tekstu. Spróbuj ponownie.';

  @override
  String get voiceMissing =>
      'Nie można odczytać tekstu. Sprawdź, czy w ustawieniach telefonu jest pobrany polski głos do odczytu bez internetu.';

  @override
  String get playbackAndroidOnly =>
      'Odczyt tekstu jest dostępny na Androidzie.';

  @override
  String get about => 'O aplikacji';

  @override
  String get back => 'Wróć';

  @override
  String get appPurpose => 'Do czego służy';

  @override
  String get appDescription =>
      'Sedno upraszcza i poprawia teksty w obsługiwanych językach.';

  @override
  String get appAudience =>
      'Powstało dla osób słabosłyszących i osób, którym trudno zrozumieć złożony tekst.';

  @override
  String get appAge => 'Aplikacja jest dla osób od 13 lat.';

  @override
  String get howItWorks => 'Jak to działa';

  @override
  String get typingInstructions =>
      'Wpisz lub wklej tekst. Wybierz Uprość albo Popraw.';

  @override
  String get captureInstructions =>
      'W trybie Uprość możesz też zrobić zdjęcie tekstu lub powiedzieć go na głos.';

  @override
  String get captureSubmitInstructions =>
      'Po zaznaczeniu tekstu na zdjęciu wybierz Uprość. Po dyktowaniu tekst jest upraszczany automatycznie.';

  @override
  String get localMediaNotice =>
      'Zdjęcia i dźwięk zostają na telefonie. Do AI trafia tylko tekst.';

  @override
  String get speechModelRequirements =>
      'Mowa wymaga Androida 13 lub nowszego i pobranego polskiego modelu mowy.';

  @override
  String get playbackRequirements =>
      'W trybie Popraw głośnik czyta tekst na głos. Potrzebujesz pobranego polskiego głosu do odczytu bez internetu.';

  @override
  String get restoreInstructions =>
      'Wynik pojawia się w tym samym polu. Naciśnij jego nagłówek lub Wstecz, aby wrócić do oryginału.';

  @override
  String get inputLimitNotice => 'Tekst może mieć najwyżej 4000 znaków.';

  @override
  String get guestNotice => 'Możesz zacząć bez zakładania konta.';

  @override
  String get dailyLimit => 'Dzienny limit';

  @override
  String get freeAllowance => 'Bez subskrypcji: 5 tekstów dziennie.';

  @override
  String get paidAllowance => 'Z subskrypcją: 400 tekstów dziennie.';

  @override
  String get sharedAllowance =>
      'Upraszczanie i poprawianie korzystają ze wspólnego limitu.';

  @override
  String get subscriptionPriceNotice =>
      'Cenę subskrypcji zobaczysz w menu Konto i w Google Play.';

  @override
  String get important => 'Ważne';

  @override
  String get aiErrorNotice => 'AI może popełniać błędy.';

  @override
  String get checkResult => 'Sprawdź wynik, zanim go wykorzystasz.';

  @override
  String get author => 'Autor: Mariusz Bąbka';

  @override
  String get privacy => 'Prywatność i dane';

  @override
  String get websiteOpenFailed =>
      'Nie można otworzyć strony. Sprawdź przeglądarkę.';

  @override
  String get website => 'Strona internetowa Sedno';

  @override
  String get photoNoText => 'Nie wykryto tekstu. Zrób wyraźniejsze zdjęcie.';

  @override
  String get cameraPermission =>
      'Brak dostępu do aparatu. Zezwól na dostęp w ustawieniach telefonu.';

  @override
  String get cameraStartFailed =>
      'Nie udało się uruchomić aparatu. Spróbuj ponownie.';

  @override
  String get photoCaptureFailed =>
      'Nie udało się zrobić zdjęcia. Spróbuj ponownie.';

  @override
  String get selectText => 'Zaznacz tekst';

  @override
  String get cropInstructions => 'Przesuń rogi ramki, aby zaznaczyć tekst. ';

  @override
  String get cropWholePhotoNotice =>
      'Bez zmian uprościmy tekst z całego zdjęcia.';

  @override
  String get openingPhoto => 'Otwieranie zdjęcia';

  @override
  String get simplify => 'Uprość';

  @override
  String get cropTopLeft => 'Lewy górny róg ramki';

  @override
  String get cropTopRight => 'Prawy górny róg ramki';

  @override
  String get cropBottomLeft => 'Lewy dolny róg ramki';

  @override
  String get cropBottomRight => 'Prawy dolny róg ramki';

  @override
  String get smallerSelection => 'Mniejsze zaznaczenie';

  @override
  String get largerSelection => 'Większe zaznaczenie';

  @override
  String get cropResizeHint =>
      'Zwiększ, aby zmniejszyć zaznaczenie. Zmniejsz, aby powiększyć zaznaczenie.';

  @override
  String get takeTextPhoto => 'Zrób zdjęcie tekstu';

  @override
  String get startingCamera => 'Uruchamianie aparatu';

  @override
  String get takingPhoto => 'Robienie zdjęcia…';

  @override
  String get takePhoto => 'Zrób zdjęcie';

  @override
  String get photoOpenFailed =>
      'Nie udało się otworzyć zdjęcia. Zrób nowe zdjęcie.';

  @override
  String get photoPrepareFailed =>
      'Nie udało się przygotować zdjęcia. Spróbuj ponownie.';

  @override
  String get simplifyHeading => 'uprość tekst';

  @override
  String get simplifiedText => 'Uproszczony tekst';

  @override
  String get correctedText => 'Poprawiony tekst';

  @override
  String get emptyText => 'Tekst nie może być pusty.';

  @override
  String get textTooLong => 'Tekst może mieć maksymalnie 4000 znaków.';

  @override
  String get subscriptionActive => 'Subskrypcja jest aktywna.';

  @override
  String get subscriptionAllowance =>
      'Możesz uprościć do 400 tekstów dziennie.';

  @override
  String get manageSubscriptionNotice =>
      'Aby zmienić płatność lub anulować subskrypcję, przejdź do Google Play.';

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją w Google Play';

  @override
  String get testerAccessNotice =>
      'Korzystasz z bezpłatnego dostępu testerskiego.';

  @override
  String get restorePurchases => 'Przywróć zakupy';

  @override
  String get refreshAccess => 'Odśwież dostęp';

  @override
  String get subscriptionBenefits =>
      'Możesz uprościć do 400 tekstów dziennie (bez subskrypcji: 5).';

  @override
  String get subscriptionSignInNotice =>
      'Aby kupić lub przywrócić subskrypcję, zaloguj się na swoje konto Sedno.';

  @override
  String get buySubscription => 'Kup subskrypcję';

  @override
  String get refreshSubscription => 'Odśwież subskrypcję';

  @override
  String get subscriptionRenewalNotice =>
      'Subskrypcja odnawia się automatycznie co miesiąc.';

  @override
  String get subscriptionCancelNotice =>
      'Możesz ją anulować w każdej chwili w Google Play.';

  @override
  String get paymentReadFailed =>
      'Nie można odczytać płatności. Spróbuj przywrócić zakupy.';

  @override
  String get signInBeforePurchase => 'Zaloguj się przed zakupem.';

  @override
  String get subscriptionAlreadyActive => 'Subskrypcja jest już aktywna.';

  @override
  String get signInBeforeRestore => 'Zaloguj się przed przywróceniem zakupu.';

  @override
  String get purchasesChecked =>
      'Sprawdzono zakupy. Potwierdzenie może potrwać chwilę.';

  @override
  String get playOpenFailed =>
      'Nie można otworzyć Google Play. Otwórz sklep i wybierz Płatności i subskrypcje → Subskrypcje.';

  @override
  String get paymentPending =>
      'Płatność oczekuje na potwierdzenie. Limit pozostaje bez zmian.';

  @override
  String get purchaseCancelled => 'Zakup anulowano.';

  @override
  String get purchaseFailed =>
      'Nie udało się kupić subskrypcji. Spróbuj ponownie.';

  @override
  String get subscriptionInactive => 'Subskrypcja nie jest aktywna.';

  @override
  String get subscriptionVerifyFailed =>
      'Nie można potwierdzić subskrypcji. Zaloguj się, sprawdź połączenie i przywróć zakupy.';

  @override
  String get subscriptionCheckFailed =>
      'Nie można sprawdzić subskrypcji. Zaloguj się i spróbuj ponownie.';

  @override
  String get hideConfirmedPassword => 'Ukryj powtórzone hasło';

  @override
  String get showConfirmedPassword => 'Pokaż powtórzone hasło';

  @override
  String get hidePassword => 'Ukryj hasło';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get enterEmail => 'Wpisz adres e-mail.';

  @override
  String get enterValidEmail => 'Wpisz poprawny adres e-mail.';

  @override
  String get passwordResetSent =>
      'Jeśli konto z tym adresem istnieje, otrzymasz wiadomość z linkiem do zmiany hasła. Sprawdź też folder Spam.';

  @override
  String get emailSendFailed =>
      'Nie udało się wysłać wiadomości. Spróbuj ponownie.';

  @override
  String get accountLoadFailed =>
      'Nie udało się odczytać konta lub dokończyć usuwania danych. Spróbuj ponownie.';

  @override
  String get verificationEmailSent =>
      'Wysłaliśmy wiadomość z linkiem. Sprawdź pocztę i folder Spam.';

  @override
  String get emailNotVerified =>
      'Adres nie jest jeszcze potwierdzony. Kliknij link w wiadomości i spróbuj ponownie.';

  @override
  String get signInFailed =>
      'Nie udało się zalogować. Sprawdź dane i spróbuj ponownie.';

  @override
  String get signOutFailed => 'Nie udało się wylogować. Spróbuj ponownie.';

  @override
  String get deleteAccountTitle => 'Usunąć konto?';

  @override
  String get deleteAccountIdentity =>
      'Potwierdź swoją tożsamość, aby usunąć konto.';

  @override
  String get password => 'Hasło';

  @override
  String get keepAccount => 'Zachowaj konto';

  @override
  String get deleteAccountAndData => 'Usuń konto i dane';

  @override
  String get accountDeleted =>
      'Konto i dane zostały usunięte. Subskrypcję anuluj osobno w Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Nie udało się zakończyć usuwania. Spróbuj ponownie.';

  @override
  String get emailAccountMethod => ' (e-mail i hasło)';

  @override
  String get finishDataCleanup => 'Odśwież konto i dokończ czyszczenie';

  @override
  String get accountNotConfigured => 'Tutaj pojawią się opcje konta.';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get emailVerified => 'Adres e-mail potwierdzony';

  @override
  String get checkInbox => 'Sprawdź pocztę';

  @override
  String get finishAccountLinkNotice =>
      'Adres został potwierdzony. Pozostało połączenie z kontem Sedna. Nie musisz ponownie klikać linku w wiadomości.';

  @override
  String get verifyEmailInstructions =>
      'Aby dokończyć tworzenie konta, kliknij link w wiadomości od Sedna. Sprawdź też folder Spam. Potem wróć tutaj i wybierz „Sprawdź potwierdzenie”.';

  @override
  String get guestWhileVerifying =>
      'Do tego czasu możesz korzystać z aplikacji bez konta.';

  @override
  String get finishSignIn => 'Dokończ logowanie';

  @override
  String get checkVerification => 'Sprawdź potwierdzenie';

  @override
  String get resendEmail => 'Wyślij wiadomość ponownie';

  @override
  String get signOutUseGuest => 'Wyloguj się i korzystaj bez konta';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get newAccount => 'Nowe konto';

  @override
  String get recoverAccess => 'Odzyskaj dostęp';

  @override
  String get guestSignInNotice => 'Możesz korzystać z aplikacji bez logowania.';

  @override
  String get signInGoogle => 'Zaloguj przez Google';

  @override
  String get emailAddress => 'Adres e-mail';

  @override
  String get enterPassword => 'Wpisz hasło.';

  @override
  String get passwordMinLength => 'Użyj co najmniej 6 znaków.';

  @override
  String get repeatPassword => 'Powtórz hasło';

  @override
  String get enterRepeatedPassword => 'Powtórz hasło.';

  @override
  String get passwordMismatch => 'Hasła muszą być takie same.';

  @override
  String get verificationEmailNotice =>
      'Wyślemy wiadomość z linkiem do potwierdzenia adresu e-mail.';

  @override
  String get passwordResetInstructions =>
      'Wpisz adres e-mail swojego konta. Wyślemy link do zmiany hasła.';

  @override
  String get signInEmail => 'Zaloguj przez e-mail';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get sendResetLink => 'Wyślij link do zmiany hasła';

  @override
  String get forgotPassword => 'Nie pamiętam hasła';

  @override
  String get createAccountLink => 'Nie masz konta? Utwórz konto';

  @override
  String get backToSignIn => 'Wróć do logowania';

  @override
  String get testerAccess => 'Dostęp testerski';

  @override
  String get testerAllowance => 'Możesz przetworzyć do 400 tekstów dziennie.';

  @override
  String get testerExpiryNotice =>
      'Dostęp jest bezpłatny i wygaśnie automatycznie.';

  @override
  String get testerHasSubscription =>
      'Masz też aktywną subskrypcję Google Play.';

  @override
  String get testerExpired => 'Dostęp testerski wygasł.';

  @override
  String get subscriptionStillActive =>
      'Twoja subskrypcja Google Play nadal zapewnia większy limit.';

  @override
  String get freeLimitRestored =>
      'Obowiązuje darmowy limit 5 tekstów dziennie. Dzisiejsze użycie pozostaje bez zmian.';

  @override
  String get closeMenu => 'Zamknij menu';

  @override
  String get welcome => 'Witaj w Sedno';

  @override
  String get inApp => 'W aplikacji';

  @override
  String get accountCreatedEmailFailed =>
      'Konto zostało utworzone, ale nie udało się wysłać wiadomości. Spróbuj wysłać ją ponownie.';

  @override
  String get signInToVerify =>
      'Zaloguj się przez e-mail, aby potwierdzić adres.';

  @override
  String get signInToCheckAccount =>
      'Zaloguj się ponownie, aby sprawdzić stan konta.';

  @override
  String get weakPassword => 'Hasło jest za słabe. Użyj co najmniej 6 znaków.';

  @override
  String get checkEmailAddress =>
      'Sprawdź, czy adres e-mail jest wpisany poprawnie.';

  @override
  String get emailAlreadyUsed =>
      'Ten adres jest już używany. Zaloguj się do istniejącego konta.';

  @override
  String get tooManyAttempts =>
      'Za dużo prób. Odczekaj chwilę i spróbuj ponownie.';

  @override
  String get checkInternet =>
      'Brak połączenia. Sprawdź internet i spróbuj ponownie.';

  @override
  String get chooseSameAccount => 'Wybierz to samo konto, które chcesz usunąć.';

  @override
  String get signInToDelete => 'Zaloguj się ponownie, aby usunąć konto.';

  @override
  String get invalidCredentials =>
      'Nie udało się zalogować. Sprawdź adres e-mail i hasło.';

  @override
  String get actionFailed =>
      'Nie udało się wykonać tej czynności. Spróbuj ponownie.';

  @override
  String get accountLinkFailed =>
      'Nie udało się połączyć z kontem Sedna. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get passwordToDelete =>
      'Wpisz hasło, aby potwierdzić usunięcie konta.';

  @override
  String get finishLocalDeletion => 'Dokończ usuwanie danych na urządzeniu.';

  @override
  String get installationRejected =>
      'Serwer nie potwierdził instalacji aplikacji. Spróbuj ponownie lub zainstaluj Sedno z Google Play.';

  @override
  String get sessionStartFailed =>
      'Nie można rozpocząć sesji. Spróbuj ponownie.';

  @override
  String get signInToLink => 'Zaloguj się ponownie, aby połączyć konto.';

  @override
  String get cannotLinkAccount => 'Nie można połączyć konta. Spróbuj ponownie.';

  @override
  String get signInAgain => 'Zaloguj się ponownie.';

  @override
  String get sessionExpiredSignIn => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String get cannotDeleteAccount => 'Nie można usunąć konta. Spróbuj ponownie.';

  @override
  String get cannotSignOut => 'Nie można wylogować. Spróbuj ponownie.';

  @override
  String get correctionUnavailable =>
      'Poprawianie tekstu nie jest jeszcze dostępne.';

  @override
  String get simplificationUnavailable =>
      'Upraszczanie tekstu nie jest jeszcze dostępne.';

  @override
  String get requestTimeout =>
      'Przekroczono czas oczekiwania. Spróbuj ponownie.';

  @override
  String get offline => 'Brak połączenia z internetem. Spróbuj ponownie.';

  @override
  String get sessionExpired =>
      'Sesja wygasła. Sprawdź konto i spróbuj ponownie.';

  @override
  String get quotaExhausted =>
      'Dzisiejszy limit został wykorzystany. Sprawdź czas odnowienia.';

  @override
  String get serviceUnavailable =>
      'Usługa jest chwilowo niedostępna. Spróbuj ponownie.';

  @override
  String get correctionRejected =>
      'Nie można poprawić tego tekstu. Sprawdź dane i spróbuj ponownie.';

  @override
  String get simplificationRejected =>
      'Nie można uprościć tego tekstu. Sprawdź dane i spróbuj ponownie.';

  @override
  String get correctionFailed =>
      'Nie udało się poprawić tekstu. Spróbuj ponownie.';

  @override
  String get simplificationFailed =>
      'Nie udało się uprościć tekstu. Spróbuj ponownie.';

  @override
  String get checkConnection => 'Sprawdź połączenie';

  @override
  String get quotaCheckFailed =>
      'Nie można sprawdzić limitu. Sprawdź połączenie.';

  @override
  String get subscriptionInAccount =>
      'Subskrypcję i jej cenę znajdziesz w menu Konto.';

  @override
  String get beforeCorrection => 'Zanim poprawisz tekst';

  @override
  String get beforeSimplification => 'Zanim uprościsz tekst';

  @override
  String get acceptAndSend => 'Rozumiem, wyślij';

  @override
  String get cameraUnavailable => 'Aparat będzie dostępny wkrótce.';

  @override
  String get aiWarning => 'AI może się mylić';

  @override
  String get listeningNotice =>
      'Nasłuchiwanie… Mów po polsku. Koniec po 1,5 sekundy ciszy lub po 60 sekundach. Przycisk stop anuluje nagrywanie.';

  @override
  String get correctionSubmitted => 'Tekst został przekazany do poprawienia.';

  @override
  String get simplificationSubmitted =>
      'Tekst został przekazany do uproszczenia.';

  @override
  String get textForCorrection => 'Tekst do poprawienia';

  @override
  String get textForSimplification => 'Tekst do uproszczenia';

  @override
  String get inputHint => 'Wpisz lub wklej tekst';

  @override
  String get switchToCorrection => 'Przełącz na poprawianie tekstu';

  @override
  String get switchToSimplification => 'Przełącz na upraszczanie tekstu';

  @override
  String get clearText => 'Wyczyść tekst';

  @override
  String get stopPlayback => 'Zatrzymaj odczyt';

  @override
  String get readAloud => 'Odczytaj tekst';

  @override
  String get cancelRecording => 'Anuluj nagrywanie';

  @override
  String get simplifySpeech => 'Uprość mowę';

  @override
  String get cancel => 'Anuluj';

  @override
  String get history => 'Historia';

  @override
  String get account => 'Konto';

  @override
  String get start => 'Start';

  @override
  String get contact => 'Kontakt';

  @override
  String get close => 'Zamknij';

  @override
  String get continueAction => 'Dalej';

  @override
  String get correct => 'Popraw';

  @override
  String get correctHeading => 'popraw tekst';

  @override
  String get correcting => 'Poprawianie…';

  @override
  String get simplifying => 'Upraszczanie…';

  @override
  String get reading => 'Odczytywanie…';

  @override
  String get camera => 'Aparat';

  @override
  String get preparing => 'Przygotowywanie…';

  @override
  String get subscription => 'Subskrypcja';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get signedIn => 'Zalogowano.';

  @override
  String get googleAccountMethod => ' (konto Google)';

  @override
  String get language => 'Język';

  @override
  String get systemLanguage => 'Język telefonu';

  @override
  String get polish => 'Polski';

  @override
  String get english => 'Angielski (UK)';

  @override
  String get languageNotice =>
      'Język określa menu, upraszczanie, poprawianie i mowę. Wybierz język tekstu. Sedno nie służy do tłumaczenia.';

  @override
  String get languageSaveFailed =>
      'Nie udało się zapisać języka. Spróbuj ponownie.';

  @override
  String resetDaily(String time) {
    return 'Nowy limit codziennie o $time.';
  }

  @override
  String resetAbout(String time) {
    return 'Nowy limit codziennie o $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'Nowy limit o $time.';
  }

  @override
  String get quotaUsed => 'Dzisiejszy limit został wykorzystany.';

  @override
  String get quotaOneSimplification => 'Pozostało 1 uproszczenie.';

  @override
  String get quotaOneUse => 'Pozostało 1 użycie AI.';

  @override
  String get quotaUsedDialog => 'Wykorzystano dzienny limit.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'Nowy limit o $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'za $hours godz. $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price miesięcznie';
  }

  @override
  String historyExpires(String date) {
    return 'Zostanie usunięty $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Usuń tekst zapisany: $date';
  }

  @override
  String contactAddress(String email) {
    return 'Kontakt: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Zalogowano jako $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Adres e-mail: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Adres do potwierdzenia: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Wyślij ponownie za $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Dostęp testerski do $date (czas lokalny).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Poziomo $horizontal%, pionowo $vertical%';
  }

  @override
  String welcomeName(String name) {
    return 'Witaj w $name';
  }

  @override
  String policyVersion(String date) {
    return 'Wersja: $date';
  }

  @override
  String get speechModelDownloading =>
      'Model mowy jest pobierany. Spróbuj później.';

  @override
  String get speechLanguageUnsupported =>
      'Silnik mowy w tym telefonie nie obsługuje lokalnego dyktowania w tym języku. Możesz wpisać tekst lub użyć aparatu.';

  @override
  String get signInApple => 'Zaloguj się przez Apple';

  @override
  String get appleAccountMethod => 'Apple';

  @override
  String get signInCancelled => 'Logowanie anulowane.';

  @override
  String get accountMethodConflict =>
      'To konto używa innej metody logowania. Zaloguj się dotychczasową metodą.';

  @override
  String get localSpeechUnavailable =>
      'Lokalne rozpoznawanie mowy nie jest dostępne dla tego języka na tym urządzeniu.';

  @override
  String get localSpeechModelMissing =>
      'Zainstaluj lokalny model mowy wybranego języka w ustawieniach urządzenia.';

  @override
  String get deviceFeatureUnavailable =>
      'Ta funkcja nie jest dostępna na tym urządzeniu.';

  @override
  String get subscriptionOtherStore =>
      'Ta subskrypcja została kupiona w innym sklepie. Zarządzaj nią w sklepie, w którym ją kupiono.';

  @override
  String get storeOpenFailed =>
      'Nie można otworzyć ustawień subskrypcji. Spróbuj ponownie.';

  @override
  String get appleManageSubscriptionNotice =>
      'Aby zmienić płatność lub anulować subskrypcję, przejdź do App Store.';

  @override
  String get appleManageSubscription => 'Zarządzaj subskrypcją w App Store';

  @override
  String get appleSubscriptionCancelNotice =>
      'Możesz ją anulować w każdej chwili w App Store.';

  @override
  String get appleAccountDeleted =>
      'Konto i dane zostały usunięte. Subskrypcję anuluj osobno w App Store.';

  @override
  String get appleTesterHasSubscription =>
      'Masz też aktywną subskrypcję App Store.';

  @override
  String get appleSubscriptionStillActive =>
      'Twoja subskrypcja App Store nadal zapewnia większy limit.';

  @override
  String get appleInstallationRejected =>
      'Serwer nie potwierdził instalacji aplikacji. Spróbuj ponownie lub zainstaluj Sedno z App Store.';

  @override
  String get appleSubscriptionPriceNotice =>
      'Cenę subskrypcji zobaczysz w menu Konto i w App Store.';

  @override
  String get privacyIosSupplementTitle => 'Dodatkowe informacje dla iPhone’a';

  @override
  String get privacyIosSupplementBody =>
      'Odniesienia poniżej do Androida, Google Play i Play Integrity dotyczą wyłącznie Androida. Na iPhonie możesz zalogować się przez Apple z ukrytym adresem e-mail. Logowanie obsługuje także Firebase. Subskrypcje kupione w App Store rozlicza Apple; Sedno nie otrzymuje danych karty. Usunięcie konta nie anuluje subskrypcji.\n\nApp Attest potwierdza autentyczność aplikacji. Nie przekazuje Apple tekstu, wyniku ani zdjęć. Serwer zapisuje pseudonimowe dane instalacji i klucza publicznego. Wyzwania są ważne 5 minut, klucze 90 dni od ostatniej udanej weryfikacji sesji, a powiadomienia o zakupach przechowujemy 30 dni. Wygasłe rekordy usuwa zadanie serwera. Metadane zakupów przechowujemy do usunięcia konta.\n\nHistoria jest szyfrowana, lokalna, wyłączona z kopii zapasowych i wygasa po 7 dniach. Zdjęcia i dźwięk pozostają na urządzeniu. Dyktowanie i odczyt działają wyłącznie lokalnie, gdy urządzenie i język je obsługują. Rozpoznany tekst wysyłasz do OpenAI przez serwer Sedno po zaakceptowaniu komunikatu o AI.\n\nPozostałe informacje poniżej, w tym dane administratora, cele, podstawy i zasady OpenAI, dotyczą także iPhone’a. Zasady Apple: https://www.apple.com/legal/privacy/';

  @override
  String get linkApple => 'Połącz z Apple';

  @override
  String get confirmAccountLink =>
      'Ponownie potwierdź obecne konto. Następnie wybierz konto Apple, aby logować się do tego samego konta Sedno.';

  @override
  String get passwordToLink =>
      'Wpisz hasło obecnego konta, aby połączyć je z Apple.';

  @override
  String get linkGoogle => 'Połącz z Google';

  @override
  String get confirmGoogleAccountLink =>
      'Ponownie potwierdź obecne konto. Następnie wybierz konto Google, aby logować się do tego samego konta Sedno.';

  @override
  String get passwordToLinkGoogle =>
      'Wpisz hasło obecnego konta, aby połączyć je z Google.';
}
