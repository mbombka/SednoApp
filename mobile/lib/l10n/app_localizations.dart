import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @restoreOriginal.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć oryginalny tekst'**
  String get restoreOriginal;

  /// No description provided for @userMenu.
  ///
  /// In pl, this message translates to:
  /// **'Menu użytkownika'**
  String get userMenu;

  /// No description provided for @speechNotRecognised.
  ///
  /// In pl, this message translates to:
  /// **'Nie rozpoznano mowy. Spróbuj ponownie.'**
  String get speechNotRecognised;

  /// No description provided for @speechFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się rozpoznać mowy. Spróbuj ponownie.'**
  String get speechFailed;

  /// No description provided for @microphonePermission.
  ///
  /// In pl, this message translates to:
  /// **'Aby użyć mowy, zezwól na dostęp do mikrofonu w ustawieniach aplikacji.'**
  String get microphonePermission;

  /// No description provided for @speechRequirements.
  ///
  /// In pl, this message translates to:
  /// **'Lokalne rozpoznawanie mowy wymaga Androida 13 lub nowszego i obsługującego je silnika mowy.'**
  String get speechRequirements;

  /// No description provided for @speechModelMissing.
  ///
  /// In pl, this message translates to:
  /// **'Brak lokalnego modelu języka polskiego. Pobierz go w ustawieniach rozpoznawania mowy Androida.'**
  String get speechModelMissing;

  /// No description provided for @speechTimeout.
  ///
  /// In pl, this message translates to:
  /// **'Rozpoznawanie trwało zbyt długo. Spróbuj ponownie.'**
  String get speechTimeout;

  /// No description provided for @speechAndroidOnly.
  ///
  /// In pl, this message translates to:
  /// **'Lokalne rozpoznawanie mowy jest dostępne na Androidzie 13 lub nowszym.'**
  String get speechAndroidOnly;

  /// No description provided for @historyClearFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się usunąć całej historii. Spróbuj ponownie.'**
  String get historyClearFailed;

  /// No description provided for @deleteHistoryEntryTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć ten tekst z historii?'**
  String get deleteHistoryEntryTitle;

  /// No description provided for @cannotUndo.
  ///
  /// In pl, this message translates to:
  /// **'Tego nie można cofnąć.'**
  String get cannotUndo;

  /// No description provided for @delete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get delete;

  /// No description provided for @historyEntryDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto tekst.'**
  String get historyEntryDeleted;

  /// No description provided for @deleteHistoryTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć całą historię?'**
  String get deleteHistoryTitle;

  /// No description provided for @deleteHistoryNotice.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie zapisane teksty zostaną usunięte z tego telefonu. Tego nie można cofnąć.'**
  String get deleteHistoryNotice;

  /// No description provided for @deleteAllHistory.
  ///
  /// In pl, this message translates to:
  /// **'Usuń całą historię'**
  String get deleteAllHistory;

  /// No description provided for @historyDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto całą historię.'**
  String get historyDeleted;

  /// No description provided for @historyLocalNotice.
  ///
  /// In pl, this message translates to:
  /// **'Teksty są zapisane tylko na tym telefonie.'**
  String get historyLocalNotice;

  /// No description provided for @historyRetentionNotice.
  ///
  /// In pl, this message translates to:
  /// **'Każdy tekst usuwa się sam po 7 dniach.'**
  String get historyRetentionNotice;

  /// No description provided for @historySignOutNotice.
  ///
  /// In pl, this message translates to:
  /// **'Wylogowanie usuwa całą historię.'**
  String get historySignOutNotice;

  /// No description provided for @deleteHistoryNow.
  ///
  /// In pl, this message translates to:
  /// **'Usuń całą historię teraz'**
  String get deleteHistoryNow;

  /// No description provided for @deletingHistory.
  ///
  /// In pl, this message translates to:
  /// **'Usuwanie historii'**
  String get deletingHistory;

  /// No description provided for @loadingHistory.
  ///
  /// In pl, this message translates to:
  /// **'Wczytywanie historii'**
  String get loadingHistory;

  /// No description provided for @historyLoadFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać historii.'**
  String get historyLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In pl, this message translates to:
  /// **'Spróbuj ponownie'**
  String get tryAgain;

  /// No description provided for @historyEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz jeszcze zapisanych tekstów.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyNotice.
  ///
  /// In pl, this message translates to:
  /// **'Każdy uproszczony lub poprawiony tekst pojawi się tutaj.'**
  String get historyEmptyNotice;

  /// No description provided for @correctedVersion.
  ///
  /// In pl, this message translates to:
  /// **'Wersja poprawiona'**
  String get correctedVersion;

  /// No description provided for @simplifiedVersion.
  ///
  /// In pl, this message translates to:
  /// **'Wersja prosta'**
  String get simplifiedVersion;

  /// No description provided for @originalText.
  ///
  /// In pl, this message translates to:
  /// **'Oryginalny tekst'**
  String get originalText;

  /// No description provided for @hideOriginal.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj oryginał'**
  String get hideOriginal;

  /// No description provided for @showOriginal.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż oryginał'**
  String get showOriginal;

  /// No description provided for @today.
  ///
  /// In pl, this message translates to:
  /// **'Dziś'**
  String get today;

  /// No description provided for @readTextFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się odczytać tekstu. Spróbuj ponownie.'**
  String get readTextFailed;

  /// No description provided for @voiceMissing.
  ///
  /// In pl, this message translates to:
  /// **'Nie można odczytać tekstu. Sprawdź, czy w ustawieniach telefonu jest pobrany polski głos do odczytu bez internetu.'**
  String get voiceMissing;

  /// No description provided for @playbackAndroidOnly.
  ///
  /// In pl, this message translates to:
  /// **'Odczyt tekstu jest dostępny na Androidzie.'**
  String get playbackAndroidOnly;

  /// No description provided for @about.
  ///
  /// In pl, this message translates to:
  /// **'O aplikacji'**
  String get about;

  /// No description provided for @back.
  ///
  /// In pl, this message translates to:
  /// **'Wróć'**
  String get back;

  /// No description provided for @appPurpose.
  ///
  /// In pl, this message translates to:
  /// **'Do czego służy'**
  String get appPurpose;

  /// No description provided for @appDescription.
  ///
  /// In pl, this message translates to:
  /// **'Sedno upraszcza i poprawia polskie i angielskie teksty.'**
  String get appDescription;

  /// No description provided for @appAudience.
  ///
  /// In pl, this message translates to:
  /// **'Powstało dla osób słabosłyszących i osób, którym trudno zrozumieć złożony tekst.'**
  String get appAudience;

  /// No description provided for @appAge.
  ///
  /// In pl, this message translates to:
  /// **'Aplikacja jest dla osób od 13 lat.'**
  String get appAge;

  /// No description provided for @howItWorks.
  ///
  /// In pl, this message translates to:
  /// **'Jak to działa'**
  String get howItWorks;

  /// No description provided for @typingInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz lub wklej tekst. Wybierz Uprość albo Popraw.'**
  String get typingInstructions;

  /// No description provided for @captureInstructions.
  ///
  /// In pl, this message translates to:
  /// **'W trybie Uprość możesz też zrobić zdjęcie tekstu lub powiedzieć go na głos.'**
  String get captureInstructions;

  /// No description provided for @captureSubmitInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Po zaznaczeniu tekstu na zdjęciu wybierz Uprość. Po dyktowaniu tekst jest upraszczany automatycznie.'**
  String get captureSubmitInstructions;

  /// No description provided for @localMediaNotice.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia i dźwięk zostają na telefonie. Do AI trafia tylko tekst.'**
  String get localMediaNotice;

  /// No description provided for @speechModelRequirements.
  ///
  /// In pl, this message translates to:
  /// **'Mowa wymaga Androida 13 lub nowszego i pobranego polskiego modelu mowy.'**
  String get speechModelRequirements;

  /// No description provided for @playbackRequirements.
  ///
  /// In pl, this message translates to:
  /// **'W trybie Popraw głośnik czyta tekst na głos. Potrzebujesz pobranego polskiego głosu do odczytu bez internetu.'**
  String get playbackRequirements;

  /// No description provided for @restoreInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Wynik pojawia się w tym samym polu. Naciśnij jego nagłówek lub Wstecz, aby wrócić do oryginału.'**
  String get restoreInstructions;

  /// No description provided for @inputLimitNotice.
  ///
  /// In pl, this message translates to:
  /// **'Tekst może mieć najwyżej 4000 znaków.'**
  String get inputLimitNotice;

  /// No description provided for @guestNotice.
  ///
  /// In pl, this message translates to:
  /// **'Możesz zacząć bez zakładania konta.'**
  String get guestNotice;

  /// No description provided for @dailyLimit.
  ///
  /// In pl, this message translates to:
  /// **'Dzienny limit'**
  String get dailyLimit;

  /// No description provided for @freeAllowance.
  ///
  /// In pl, this message translates to:
  /// **'Bez subskrypcji: 5 tekstów dziennie.'**
  String get freeAllowance;

  /// No description provided for @paidAllowance.
  ///
  /// In pl, this message translates to:
  /// **'Z subskrypcją: 400 tekstów dziennie.'**
  String get paidAllowance;

  /// No description provided for @sharedAllowance.
  ///
  /// In pl, this message translates to:
  /// **'Upraszczanie i poprawianie korzystają ze wspólnego limitu.'**
  String get sharedAllowance;

  /// No description provided for @subscriptionPriceNotice.
  ///
  /// In pl, this message translates to:
  /// **'Cenę subskrypcji zobaczysz w menu Konto i w Google Play.'**
  String get subscriptionPriceNotice;

  /// No description provided for @important.
  ///
  /// In pl, this message translates to:
  /// **'Ważne'**
  String get important;

  /// No description provided for @aiErrorNotice.
  ///
  /// In pl, this message translates to:
  /// **'AI może popełniać błędy.'**
  String get aiErrorNotice;

  /// No description provided for @checkResult.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź wynik, zanim go wykorzystasz.'**
  String get checkResult;

  /// No description provided for @author.
  ///
  /// In pl, this message translates to:
  /// **'Autor: Mariusz Bąbka'**
  String get author;

  /// No description provided for @privacy.
  ///
  /// In pl, this message translates to:
  /// **'Prywatność i dane'**
  String get privacy;

  /// No description provided for @websiteOpenFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można otworzyć strony. Sprawdź przeglądarkę.'**
  String get websiteOpenFailed;

  /// No description provided for @website.
  ///
  /// In pl, this message translates to:
  /// **'Strona internetowa Sedno'**
  String get website;

  /// No description provided for @photoNoText.
  ///
  /// In pl, this message translates to:
  /// **'Nie wykryto tekstu. Zrób wyraźniejsze zdjęcie.'**
  String get photoNoText;

  /// No description provided for @cameraPermission.
  ///
  /// In pl, this message translates to:
  /// **'Brak dostępu do aparatu. Zezwól na dostęp w ustawieniach telefonu.'**
  String get cameraPermission;

  /// No description provided for @cameraStartFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się uruchomić aparatu. Spróbuj ponownie.'**
  String get cameraStartFailed;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zrobić zdjęcia. Spróbuj ponownie.'**
  String get photoCaptureFailed;

  /// No description provided for @selectText.
  ///
  /// In pl, this message translates to:
  /// **'Zaznacz tekst'**
  String get selectText;

  /// No description provided for @cropInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Przesuń rogi ramki, aby zaznaczyć tekst. '**
  String get cropInstructions;

  /// No description provided for @cropWholePhotoNotice.
  ///
  /// In pl, this message translates to:
  /// **'Bez zmian uprościmy tekst z całego zdjęcia.'**
  String get cropWholePhotoNotice;

  /// No description provided for @openingPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Otwieranie zdjęcia'**
  String get openingPhoto;

  /// No description provided for @simplify.
  ///
  /// In pl, this message translates to:
  /// **'Uprość'**
  String get simplify;

  /// No description provided for @cropTopLeft.
  ///
  /// In pl, this message translates to:
  /// **'Lewy górny róg ramki'**
  String get cropTopLeft;

  /// No description provided for @cropTopRight.
  ///
  /// In pl, this message translates to:
  /// **'Prawy górny róg ramki'**
  String get cropTopRight;

  /// No description provided for @cropBottomLeft.
  ///
  /// In pl, this message translates to:
  /// **'Lewy dolny róg ramki'**
  String get cropBottomLeft;

  /// No description provided for @cropBottomRight.
  ///
  /// In pl, this message translates to:
  /// **'Prawy dolny róg ramki'**
  String get cropBottomRight;

  /// No description provided for @smallerSelection.
  ///
  /// In pl, this message translates to:
  /// **'Mniejsze zaznaczenie'**
  String get smallerSelection;

  /// No description provided for @largerSelection.
  ///
  /// In pl, this message translates to:
  /// **'Większe zaznaczenie'**
  String get largerSelection;

  /// No description provided for @cropResizeHint.
  ///
  /// In pl, this message translates to:
  /// **'Zwiększ, aby zmniejszyć zaznaczenie. Zmniejsz, aby powiększyć zaznaczenie.'**
  String get cropResizeHint;

  /// No description provided for @takeTextPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Zrób zdjęcie tekstu'**
  String get takeTextPhoto;

  /// No description provided for @startingCamera.
  ///
  /// In pl, this message translates to:
  /// **'Uruchamianie aparatu'**
  String get startingCamera;

  /// No description provided for @takingPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Robienie zdjęcia…'**
  String get takingPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In pl, this message translates to:
  /// **'Zrób zdjęcie'**
  String get takePhoto;

  /// No description provided for @photoOpenFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się otworzyć zdjęcia. Zrób nowe zdjęcie.'**
  String get photoOpenFailed;

  /// No description provided for @photoPrepareFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się przygotować zdjęcia. Spróbuj ponownie.'**
  String get photoPrepareFailed;

  /// No description provided for @simplifyHeading.
  ///
  /// In pl, this message translates to:
  /// **'uprość tekst'**
  String get simplifyHeading;

  /// No description provided for @simplifiedText.
  ///
  /// In pl, this message translates to:
  /// **'Uproszczony tekst'**
  String get simplifiedText;

  /// No description provided for @correctedText.
  ///
  /// In pl, this message translates to:
  /// **'Poprawiony tekst'**
  String get correctedText;

  /// No description provided for @emptyText.
  ///
  /// In pl, this message translates to:
  /// **'Tekst nie może być pusty.'**
  String get emptyText;

  /// No description provided for @textTooLong.
  ///
  /// In pl, this message translates to:
  /// **'Tekst może mieć maksymalnie 4000 znaków.'**
  String get textTooLong;

  /// No description provided for @subscriptionActive.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja jest aktywna.'**
  String get subscriptionActive;

  /// No description provided for @subscriptionAllowance.
  ///
  /// In pl, this message translates to:
  /// **'Możesz uprościć do 400 tekstów dziennie.'**
  String get subscriptionAllowance;

  /// No description provided for @manageSubscriptionNotice.
  ///
  /// In pl, this message translates to:
  /// **'Aby zmienić płatność lub anulować subskrypcję, przejdź do Google Play.'**
  String get manageSubscriptionNotice;

  /// No description provided for @manageSubscription.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj subskrypcją w Google Play'**
  String get manageSubscription;

  /// No description provided for @testerAccessNotice.
  ///
  /// In pl, this message translates to:
  /// **'Korzystasz z bezpłatnego dostępu testerskiego.'**
  String get testerAccessNotice;

  /// No description provided for @restorePurchases.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć zakupy'**
  String get restorePurchases;

  /// No description provided for @refreshAccess.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież dostęp'**
  String get refreshAccess;

  /// No description provided for @subscriptionBenefits.
  ///
  /// In pl, this message translates to:
  /// **'Możesz uprościć do 400 tekstów dziennie (bez subskrypcji: 5).'**
  String get subscriptionBenefits;

  /// No description provided for @subscriptionSignInNotice.
  ///
  /// In pl, this message translates to:
  /// **'Aby kupić lub przywrócić subskrypcję, zaloguj się na swoje konto Sedno.'**
  String get subscriptionSignInNotice;

  /// No description provided for @buySubscription.
  ///
  /// In pl, this message translates to:
  /// **'Kup subskrypcję'**
  String get buySubscription;

  /// No description provided for @refreshSubscription.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież subskrypcję'**
  String get refreshSubscription;

  /// No description provided for @subscriptionRenewalNotice.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja odnawia się automatycznie co miesiąc.'**
  String get subscriptionRenewalNotice;

  /// No description provided for @subscriptionCancelNotice.
  ///
  /// In pl, this message translates to:
  /// **'Możesz ją anulować w każdej chwili w Google Play.'**
  String get subscriptionCancelNotice;

  /// No description provided for @paymentReadFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można odczytać płatności. Spróbuj przywrócić zakupy.'**
  String get paymentReadFailed;

  /// No description provided for @signInBeforePurchase.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się przed zakupem.'**
  String get signInBeforePurchase;

  /// No description provided for @subscriptionAlreadyActive.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja jest już aktywna.'**
  String get subscriptionAlreadyActive;

  /// No description provided for @signInBeforeRestore.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się przed przywróceniem zakupu.'**
  String get signInBeforeRestore;

  /// No description provided for @purchasesChecked.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdzono zakupy. Potwierdzenie może potrwać chwilę.'**
  String get purchasesChecked;

  /// No description provided for @playOpenFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można otworzyć Google Play. Otwórz sklep i wybierz Płatności i subskrypcje → Subskrypcje.'**
  String get playOpenFailed;

  /// No description provided for @paymentPending.
  ///
  /// In pl, this message translates to:
  /// **'Płatność oczekuje na potwierdzenie. Limit pozostaje bez zmian.'**
  String get paymentPending;

  /// No description provided for @purchaseCancelled.
  ///
  /// In pl, this message translates to:
  /// **'Zakup anulowano.'**
  String get purchaseCancelled;

  /// No description provided for @purchaseFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się kupić subskrypcji. Spróbuj ponownie.'**
  String get purchaseFailed;

  /// No description provided for @subscriptionInactive.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja nie jest aktywna.'**
  String get subscriptionInactive;

  /// No description provided for @subscriptionVerifyFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można potwierdzić subskrypcji. Zaloguj się, sprawdź połączenie i przywróć zakupy.'**
  String get subscriptionVerifyFailed;

  /// No description provided for @subscriptionCheckFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można sprawdzić subskrypcji. Zaloguj się i spróbuj ponownie.'**
  String get subscriptionCheckFailed;

  /// No description provided for @hideConfirmedPassword.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj powtórzone hasło'**
  String get hideConfirmedPassword;

  /// No description provided for @showConfirmedPassword.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż powtórzone hasło'**
  String get showConfirmedPassword;

  /// No description provided for @hidePassword.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj hasło'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż hasło'**
  String get showPassword;

  /// No description provided for @enterEmail.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz adres e-mail.'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz poprawny adres e-mail.'**
  String get enterValidEmail;

  /// No description provided for @passwordResetSent.
  ///
  /// In pl, this message translates to:
  /// **'Jeśli konto z tym adresem istnieje, otrzymasz wiadomość z linkiem do zmiany hasła. Sprawdź też folder Spam.'**
  String get passwordResetSent;

  /// No description provided for @emailSendFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wysłać wiadomości. Spróbuj ponownie.'**
  String get emailSendFailed;

  /// No description provided for @accountLoadFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się odczytać konta lub dokończyć usuwania danych. Spróbuj ponownie.'**
  String get accountLoadFailed;

  /// No description provided for @verificationEmailSent.
  ///
  /// In pl, this message translates to:
  /// **'Wysłaliśmy wiadomość z linkiem. Sprawdź pocztę i folder Spam.'**
  String get verificationEmailSent;

  /// No description provided for @emailNotVerified.
  ///
  /// In pl, this message translates to:
  /// **'Adres nie jest jeszcze potwierdzony. Kliknij link w wiadomości i spróbuj ponownie.'**
  String get emailNotVerified;

  /// No description provided for @signInFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zalogować. Sprawdź dane i spróbuj ponownie.'**
  String get signInFailed;

  /// No description provided for @signOutFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wylogować. Spróbuj ponownie.'**
  String get signOutFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć konto?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountIdentity.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź swoją tożsamość, aby usunąć konto.'**
  String get deleteAccountIdentity;

  /// No description provided for @password.
  ///
  /// In pl, this message translates to:
  /// **'Hasło'**
  String get password;

  /// No description provided for @keepAccount.
  ///
  /// In pl, this message translates to:
  /// **'Zachowaj konto'**
  String get keepAccount;

  /// No description provided for @deleteAccountAndData.
  ///
  /// In pl, this message translates to:
  /// **'Usuń konto i dane'**
  String get deleteAccountAndData;

  /// No description provided for @accountDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Konto i dane zostały usunięte. Subskrypcję anuluj osobno w Google Play.'**
  String get accountDeleted;

  /// No description provided for @accountDeleteIncomplete.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zakończyć usuwania. Spróbuj ponownie.'**
  String get accountDeleteIncomplete;

  /// No description provided for @emailAccountMethod.
  ///
  /// In pl, this message translates to:
  /// **' (e-mail i hasło)'**
  String get emailAccountMethod;

  /// No description provided for @finishDataCleanup.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież konto i dokończ czyszczenie'**
  String get finishDataCleanup;

  /// No description provided for @accountNotConfigured.
  ///
  /// In pl, this message translates to:
  /// **'Tutaj pojawią się opcje konta.'**
  String get accountNotConfigured;

  /// No description provided for @signOut.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj się'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In pl, this message translates to:
  /// **'Usuń konto'**
  String get deleteAccount;

  /// No description provided for @emailVerified.
  ///
  /// In pl, this message translates to:
  /// **'Adres e-mail potwierdzony'**
  String get emailVerified;

  /// No description provided for @checkInbox.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź pocztę'**
  String get checkInbox;

  /// No description provided for @finishAccountLinkNotice.
  ///
  /// In pl, this message translates to:
  /// **'Adres został potwierdzony. Pozostało połączenie z kontem Sedna. Nie musisz ponownie klikać linku w wiadomości.'**
  String get finishAccountLinkNotice;

  /// No description provided for @verifyEmailInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Aby dokończyć tworzenie konta, kliknij link w wiadomości od Sedna. Sprawdź też folder Spam. Potem wróć tutaj i wybierz „Sprawdź potwierdzenie”.'**
  String get verifyEmailInstructions;

  /// No description provided for @guestWhileVerifying.
  ///
  /// In pl, this message translates to:
  /// **'Do tego czasu możesz korzystać z aplikacji bez konta.'**
  String get guestWhileVerifying;

  /// No description provided for @finishSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Dokończ logowanie'**
  String get finishSignIn;

  /// No description provided for @checkVerification.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź potwierdzenie'**
  String get checkVerification;

  /// No description provided for @resendEmail.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij wiadomość ponownie'**
  String get resendEmail;

  /// No description provided for @signOutUseGuest.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj się i korzystaj bez konta'**
  String get signOutUseGuest;

  /// No description provided for @signIn.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get signIn;

  /// No description provided for @newAccount.
  ///
  /// In pl, this message translates to:
  /// **'Nowe konto'**
  String get newAccount;

  /// No description provided for @recoverAccess.
  ///
  /// In pl, this message translates to:
  /// **'Odzyskaj dostęp'**
  String get recoverAccess;

  /// No description provided for @guestSignInNotice.
  ///
  /// In pl, this message translates to:
  /// **'Możesz korzystać z aplikacji bez logowania.'**
  String get guestSignInNotice;

  /// No description provided for @signInGoogle.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj przez Google'**
  String get signInGoogle;

  /// No description provided for @emailAddress.
  ///
  /// In pl, this message translates to:
  /// **'Adres e-mail'**
  String get emailAddress;

  /// No description provided for @enterPassword.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz hasło.'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In pl, this message translates to:
  /// **'Użyj co najmniej 6 znaków.'**
  String get passwordMinLength;

  /// No description provided for @repeatPassword.
  ///
  /// In pl, this message translates to:
  /// **'Powtórz hasło'**
  String get repeatPassword;

  /// No description provided for @enterRepeatedPassword.
  ///
  /// In pl, this message translates to:
  /// **'Powtórz hasło.'**
  String get enterRepeatedPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Hasła muszą być takie same.'**
  String get passwordMismatch;

  /// No description provided for @verificationEmailNotice.
  ///
  /// In pl, this message translates to:
  /// **'Wyślemy wiadomość z linkiem do potwierdzenia adresu e-mail.'**
  String get verificationEmailNotice;

  /// No description provided for @passwordResetInstructions.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz adres e-mail swojego konta. Wyślemy link do zmiany hasła.'**
  String get passwordResetInstructions;

  /// No description provided for @signInEmail.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj przez e-mail'**
  String get signInEmail;

  /// No description provided for @createAccount.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz konto'**
  String get createAccount;

  /// No description provided for @sendResetLink.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij link do zmiany hasła'**
  String get sendResetLink;

  /// No description provided for @forgotPassword.
  ///
  /// In pl, this message translates to:
  /// **'Nie pamiętam hasła'**
  String get forgotPassword;

  /// No description provided for @createAccountLink.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz konta? Utwórz konto'**
  String get createAccountLink;

  /// No description provided for @backToSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Wróć do logowania'**
  String get backToSignIn;

  /// No description provided for @testerAccess.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp testerski'**
  String get testerAccess;

  /// No description provided for @testerAllowance.
  ///
  /// In pl, this message translates to:
  /// **'Możesz przetworzyć do 400 tekstów dziennie.'**
  String get testerAllowance;

  /// No description provided for @testerExpiryNotice.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp jest bezpłatny i wygaśnie automatycznie.'**
  String get testerExpiryNotice;

  /// No description provided for @testerHasSubscription.
  ///
  /// In pl, this message translates to:
  /// **'Masz też aktywną subskrypcję Google Play.'**
  String get testerHasSubscription;

  /// No description provided for @testerExpired.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp testerski wygasł.'**
  String get testerExpired;

  /// No description provided for @subscriptionStillActive.
  ///
  /// In pl, this message translates to:
  /// **'Twoja subskrypcja Google Play nadal zapewnia większy limit.'**
  String get subscriptionStillActive;

  /// No description provided for @freeLimitRestored.
  ///
  /// In pl, this message translates to:
  /// **'Obowiązuje darmowy limit 5 tekstów dziennie. Dzisiejsze użycie pozostaje bez zmian.'**
  String get freeLimitRestored;

  /// No description provided for @closeMenu.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij menu'**
  String get closeMenu;

  /// No description provided for @welcome.
  ///
  /// In pl, this message translates to:
  /// **'Witaj w Sedno'**
  String get welcome;

  /// No description provided for @inApp.
  ///
  /// In pl, this message translates to:
  /// **'W aplikacji'**
  String get inApp;

  /// No description provided for @accountCreatedEmailFailed.
  ///
  /// In pl, this message translates to:
  /// **'Konto zostało utworzone, ale nie udało się wysłać wiadomości. Spróbuj wysłać ją ponownie.'**
  String get accountCreatedEmailFailed;

  /// No description provided for @signInToVerify.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się przez e-mail, aby potwierdzić adres.'**
  String get signInToVerify;

  /// No description provided for @signInToCheckAccount.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się ponownie, aby sprawdzić stan konta.'**
  String get signInToCheckAccount;

  /// No description provided for @weakPassword.
  ///
  /// In pl, this message translates to:
  /// **'Hasło jest za słabe. Użyj co najmniej 6 znaków.'**
  String get weakPassword;

  /// No description provided for @checkEmailAddress.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź, czy adres e-mail jest wpisany poprawnie.'**
  String get checkEmailAddress;

  /// No description provided for @emailAlreadyUsed.
  ///
  /// In pl, this message translates to:
  /// **'Ten adres jest już używany. Zaloguj się do istniejącego konta.'**
  String get emailAlreadyUsed;

  /// No description provided for @tooManyAttempts.
  ///
  /// In pl, this message translates to:
  /// **'Za dużo prób. Odczekaj chwilę i spróbuj ponownie.'**
  String get tooManyAttempts;

  /// No description provided for @checkInternet.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia. Sprawdź internet i spróbuj ponownie.'**
  String get checkInternet;

  /// No description provided for @chooseSameAccount.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz to samo konto, które chcesz usunąć.'**
  String get chooseSameAccount;

  /// No description provided for @signInToDelete.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się ponownie, aby usunąć konto.'**
  String get signInToDelete;

  /// No description provided for @invalidCredentials.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zalogować. Sprawdź adres e-mail i hasło.'**
  String get invalidCredentials;

  /// No description provided for @actionFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wykonać tej czynności. Spróbuj ponownie.'**
  String get actionFailed;

  /// No description provided for @accountLinkFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się połączyć z kontem Sedna. Sprawdź połączenie i spróbuj ponownie.'**
  String get accountLinkFailed;

  /// No description provided for @passwordToDelete.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz hasło, aby potwierdzić usunięcie konta.'**
  String get passwordToDelete;

  /// No description provided for @finishLocalDeletion.
  ///
  /// In pl, this message translates to:
  /// **'Dokończ usuwanie danych na urządzeniu.'**
  String get finishLocalDeletion;

  /// No description provided for @installationRejected.
  ///
  /// In pl, this message translates to:
  /// **'Serwer nie potwierdził instalacji aplikacji. Spróbuj ponownie lub zainstaluj Sedno z Google Play.'**
  String get installationRejected;

  /// No description provided for @sessionStartFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można rozpocząć sesji. Spróbuj ponownie.'**
  String get sessionStartFailed;

  /// No description provided for @signInToLink.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się ponownie, aby połączyć konto.'**
  String get signInToLink;

  /// No description provided for @cannotLinkAccount.
  ///
  /// In pl, this message translates to:
  /// **'Nie można połączyć konta. Spróbuj ponownie.'**
  String get cannotLinkAccount;

  /// No description provided for @signInAgain.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się ponownie.'**
  String get signInAgain;

  /// No description provided for @sessionExpiredSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Sesja wygasła. Zaloguj się ponownie.'**
  String get sessionExpiredSignIn;

  /// No description provided for @cannotDeleteAccount.
  ///
  /// In pl, this message translates to:
  /// **'Nie można usunąć konta. Spróbuj ponownie.'**
  String get cannotDeleteAccount;

  /// No description provided for @cannotSignOut.
  ///
  /// In pl, this message translates to:
  /// **'Nie można wylogować. Spróbuj ponownie.'**
  String get cannotSignOut;

  /// No description provided for @correctionUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Poprawianie tekstu nie jest jeszcze dostępne.'**
  String get correctionUnavailable;

  /// No description provided for @simplificationUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Upraszczanie tekstu nie jest jeszcze dostępne.'**
  String get simplificationUnavailable;

  /// No description provided for @requestTimeout.
  ///
  /// In pl, this message translates to:
  /// **'Przekroczono czas oczekiwania. Spróbuj ponownie.'**
  String get requestTimeout;

  /// No description provided for @offline.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia z internetem. Spróbuj ponownie.'**
  String get offline;

  /// No description provided for @sessionExpired.
  ///
  /// In pl, this message translates to:
  /// **'Sesja wygasła. Sprawdź konto i spróbuj ponownie.'**
  String get sessionExpired;

  /// No description provided for @quotaExhausted.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiejszy limit został wykorzystany. Sprawdź czas odnowienia.'**
  String get quotaExhausted;

  /// No description provided for @serviceUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Usługa jest chwilowo niedostępna. Spróbuj ponownie.'**
  String get serviceUnavailable;

  /// No description provided for @correctionRejected.
  ///
  /// In pl, this message translates to:
  /// **'Nie można poprawić tego tekstu. Sprawdź dane i spróbuj ponownie.'**
  String get correctionRejected;

  /// No description provided for @simplificationRejected.
  ///
  /// In pl, this message translates to:
  /// **'Nie można uprościć tego tekstu. Sprawdź dane i spróbuj ponownie.'**
  String get simplificationRejected;

  /// No description provided for @correctionFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się poprawić tekstu. Spróbuj ponownie.'**
  String get correctionFailed;

  /// No description provided for @simplificationFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się uprościć tekstu. Spróbuj ponownie.'**
  String get simplificationFailed;

  /// No description provided for @checkConnection.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź połączenie'**
  String get checkConnection;

  /// No description provided for @quotaCheckFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie można sprawdzić limitu. Sprawdź połączenie.'**
  String get quotaCheckFailed;

  /// No description provided for @subscriptionInAccount.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcję i jej cenę znajdziesz w menu Konto.'**
  String get subscriptionInAccount;

  /// No description provided for @beforeCorrection.
  ///
  /// In pl, this message translates to:
  /// **'Zanim poprawisz tekst'**
  String get beforeCorrection;

  /// No description provided for @beforeSimplification.
  ///
  /// In pl, this message translates to:
  /// **'Zanim uprościsz tekst'**
  String get beforeSimplification;

  /// No description provided for @acceptAndSend.
  ///
  /// In pl, this message translates to:
  /// **'Rozumiem, wyślij'**
  String get acceptAndSend;

  /// No description provided for @cameraUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Aparat będzie dostępny wkrótce.'**
  String get cameraUnavailable;

  /// No description provided for @aiWarning.
  ///
  /// In pl, this message translates to:
  /// **'AI może się mylić'**
  String get aiWarning;

  /// No description provided for @listeningNotice.
  ///
  /// In pl, this message translates to:
  /// **'Nasłuchiwanie… Mów po polsku. Koniec po 1,5 sekundy ciszy lub po 60 sekundach. Przycisk stop anuluje nagrywanie.'**
  String get listeningNotice;

  /// No description provided for @correctionSubmitted.
  ///
  /// In pl, this message translates to:
  /// **'Tekst został przekazany do poprawienia.'**
  String get correctionSubmitted;

  /// No description provided for @simplificationSubmitted.
  ///
  /// In pl, this message translates to:
  /// **'Tekst został przekazany do uproszczenia.'**
  String get simplificationSubmitted;

  /// No description provided for @textForCorrection.
  ///
  /// In pl, this message translates to:
  /// **'Tekst do poprawienia'**
  String get textForCorrection;

  /// No description provided for @textForSimplification.
  ///
  /// In pl, this message translates to:
  /// **'Tekst do uproszczenia'**
  String get textForSimplification;

  /// No description provided for @inputHint.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz lub wklej tekst'**
  String get inputHint;

  /// No description provided for @switchToCorrection.
  ///
  /// In pl, this message translates to:
  /// **'Przełącz na poprawianie tekstu'**
  String get switchToCorrection;

  /// No description provided for @switchToSimplification.
  ///
  /// In pl, this message translates to:
  /// **'Przełącz na upraszczanie tekstu'**
  String get switchToSimplification;

  /// No description provided for @clearText.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść tekst'**
  String get clearText;

  /// No description provided for @stopPlayback.
  ///
  /// In pl, this message translates to:
  /// **'Zatrzymaj odczyt'**
  String get stopPlayback;

  /// No description provided for @readAloud.
  ///
  /// In pl, this message translates to:
  /// **'Odczytaj tekst'**
  String get readAloud;

  /// No description provided for @cancelRecording.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj nagrywanie'**
  String get cancelRecording;

  /// No description provided for @simplifySpeech.
  ///
  /// In pl, this message translates to:
  /// **'Uprość mowę'**
  String get simplifySpeech;

  /// No description provided for @cancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get cancel;

  /// No description provided for @history.
  ///
  /// In pl, this message translates to:
  /// **'Historia'**
  String get history;

  /// No description provided for @account.
  ///
  /// In pl, this message translates to:
  /// **'Konto'**
  String get account;

  /// No description provided for @start.
  ///
  /// In pl, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @contact.
  ///
  /// In pl, this message translates to:
  /// **'Kontakt'**
  String get contact;

  /// No description provided for @close.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get close;

  /// No description provided for @continueAction.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get continueAction;

  /// No description provided for @correct.
  ///
  /// In pl, this message translates to:
  /// **'Popraw'**
  String get correct;

  /// No description provided for @correctHeading.
  ///
  /// In pl, this message translates to:
  /// **'popraw tekst'**
  String get correctHeading;

  /// No description provided for @correcting.
  ///
  /// In pl, this message translates to:
  /// **'Poprawianie…'**
  String get correcting;

  /// No description provided for @simplifying.
  ///
  /// In pl, this message translates to:
  /// **'Upraszczanie…'**
  String get simplifying;

  /// No description provided for @reading.
  ///
  /// In pl, this message translates to:
  /// **'Odczytywanie…'**
  String get reading;

  /// No description provided for @camera.
  ///
  /// In pl, this message translates to:
  /// **'Aparat'**
  String get camera;

  /// No description provided for @preparing.
  ///
  /// In pl, this message translates to:
  /// **'Przygotowywanie…'**
  String get preparing;

  /// No description provided for @subscription.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja'**
  String get subscription;

  /// No description provided for @yesterday.
  ///
  /// In pl, this message translates to:
  /// **'Wczoraj'**
  String get yesterday;

  /// No description provided for @signedIn.
  ///
  /// In pl, this message translates to:
  /// **'Zalogowano.'**
  String get signedIn;

  /// No description provided for @googleAccountMethod.
  ///
  /// In pl, this message translates to:
  /// **' (konto Google)'**
  String get googleAccountMethod;

  /// No description provided for @language.
  ///
  /// In pl, this message translates to:
  /// **'Język'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In pl, this message translates to:
  /// **'Język telefonu'**
  String get systemLanguage;

  /// No description provided for @polish.
  ///
  /// In pl, this message translates to:
  /// **'Polski'**
  String get polish;

  /// No description provided for @english.
  ///
  /// In pl, this message translates to:
  /// **'Angielski (UK)'**
  String get english;

  /// No description provided for @languageNotice.
  ///
  /// In pl, this message translates to:
  /// **'Język określa menu, upraszczanie, poprawianie i mowę. Wybierz język tekstu. Sedno nie służy do tłumaczenia.'**
  String get languageNotice;

  /// No description provided for @languageSaveFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zapisać języka. Spróbuj ponownie.'**
  String get languageSaveFailed;

  /// No description provided for @resetDaily.
  ///
  /// In pl, this message translates to:
  /// **'Nowy limit codziennie o {time}.'**
  String resetDaily(String time);

  /// No description provided for @resetAbout.
  ///
  /// In pl, this message translates to:
  /// **'Nowy limit codziennie o {time} (00:00 UTC).'**
  String resetAbout(String time);

  /// No description provided for @resetAt.
  ///
  /// In pl, this message translates to:
  /// **'Nowy limit o {time}.'**
  String resetAt(String time);

  /// No description provided for @quotaUsed.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiejszy limit został wykorzystany.'**
  String get quotaUsed;

  /// No description provided for @quotaOneSimplification.
  ///
  /// In pl, this message translates to:
  /// **'Pozostało 1 uproszczenie.'**
  String get quotaOneSimplification;

  /// No description provided for @quotaOneUse.
  ///
  /// In pl, this message translates to:
  /// **'Pozostało 1 użycie AI.'**
  String get quotaOneUse;

  /// No description provided for @quotaUsedDialog.
  ///
  /// In pl, this message translates to:
  /// **'Wykorzystano dzienny limit.'**
  String get quotaUsedDialog;

  /// No description provided for @resetWithRemaining.
  ///
  /// In pl, this message translates to:
  /// **'Nowy limit o {time} ({remaining}).'**
  String resetWithRemaining(String time, String remaining);

  /// No description provided for @timeRemaining.
  ///
  /// In pl, this message translates to:
  /// **'za {hours} godz. {minutes} min'**
  String timeRemaining(String hours, String minutes);

  /// No description provided for @monthlyPrice.
  ///
  /// In pl, this message translates to:
  /// **'{price} miesięcznie'**
  String monthlyPrice(String price);

  /// No description provided for @historyExpires.
  ///
  /// In pl, this message translates to:
  /// **'Zostanie usunięty {date}.'**
  String historyExpires(String date);

  /// No description provided for @deleteSavedText.
  ///
  /// In pl, this message translates to:
  /// **'Usuń tekst zapisany: {date}'**
  String deleteSavedText(String date);

  /// No description provided for @contactAddress.
  ///
  /// In pl, this message translates to:
  /// **'Kontakt: {email}'**
  String contactAddress(String email);

  /// No description provided for @signedInAs.
  ///
  /// In pl, this message translates to:
  /// **'Zalogowano jako {email}{method}'**
  String signedInAs(String email, String method);

  /// No description provided for @accountEmail.
  ///
  /// In pl, this message translates to:
  /// **'Adres e-mail: {email}'**
  String accountEmail(String email);

  /// No description provided for @emailToVerify.
  ///
  /// In pl, this message translates to:
  /// **'Adres do potwierdzenia: {email}'**
  String emailToVerify(String email);

  /// No description provided for @resendAfter.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij ponownie za {seconds} s'**
  String resendAfter(String seconds);

  /// No description provided for @testerUntil.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp testerski do {date} (czas lokalny).'**
  String testerUntil(String date);

  /// No description provided for @cropPosition.
  ///
  /// In pl, this message translates to:
  /// **'Poziomo {horizontal}%, pionowo {vertical}%'**
  String cropPosition(String horizontal, String vertical);

  /// No description provided for @welcomeName.
  ///
  /// In pl, this message translates to:
  /// **'Witaj w {name}'**
  String welcomeName(String name);

  /// No description provided for @policyVersion.
  ///
  /// In pl, this message translates to:
  /// **'Wersja: {date}'**
  String policyVersion(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
