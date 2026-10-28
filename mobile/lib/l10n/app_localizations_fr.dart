// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get restoreOriginal => 'Rétablir le texte original';

  @override
  String get userMenu => 'Menu utilisateur';

  @override
  String get speechNotRecognised => 'Aucune parole reconnue. Réessayez.';

  @override
  String get speechFailed => 'La reconnaissance vocale a échoué. Réessayez.';

  @override
  String get microphonePermission =>
      'Autorisez le microphone dans les paramètres de l’application.';

  @override
  String get speechRequirements =>
      'La reconnaissance locale nécessite Android 13 ou plus et un moteur vocal compatible.';

  @override
  String get speechModelMissing =>
      'Téléchargez le modèle vocal français dans les paramètres de reconnaissance vocale Android.';

  @override
  String get speechTimeout =>
      'La reconnaissance a pris trop de temps. Réessayez.';

  @override
  String get speechAndroidOnly =>
      'La reconnaissance locale est disponible sur Android 13 ou plus.';

  @override
  String get historyClearFailed =>
      'Impossible de supprimer tout l’historique. Réessayez.';

  @override
  String get deleteHistoryEntryTitle => 'Supprimer ce texte de l’historique ?';

  @override
  String get cannotUndo => 'Cette action est irréversible.';

  @override
  String get delete => 'Supprimer';

  @override
  String get historyEntryDeleted => 'Texte supprimé.';

  @override
  String get deleteHistoryTitle => 'Supprimer tout l’historique ?';

  @override
  String get deleteHistoryNotice =>
      'Tous les textes enregistrés seront supprimés de ce téléphone. Cette action est irréversible.';

  @override
  String get deleteAllHistory => 'Supprimer tout l’historique';

  @override
  String get historyDeleted => 'Historique supprimé.';

  @override
  String get historyLocalNotice =>
      'Les textes sont enregistrés uniquement sur ce téléphone.';

  @override
  String get historyRetentionNotice =>
      'Chaque texte est supprimé automatiquement après 7 jours.';

  @override
  String get historySignOutNotice =>
      'La déconnexion supprime tout l’historique.';

  @override
  String get deleteHistoryNow => 'Supprimer tout l’historique maintenant';

  @override
  String get deletingHistory => 'Suppression de l’historique';

  @override
  String get loadingHistory => 'Chargement de l’historique';

  @override
  String get historyLoadFailed => 'Impossible de charger l’historique.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get historyEmpty => 'Vous n’avez aucun texte enregistré.';

  @override
  String get historyEmptyNotice =>
      'Vos textes simplifiés ou corrigés apparaîtront ici.';

  @override
  String get correctedVersion => 'Version corrigée';

  @override
  String get simplifiedVersion => 'Version simple';

  @override
  String get originalText => 'Texte original';

  @override
  String get hideOriginal => 'Masquer l’original';

  @override
  String get showOriginal => 'Afficher l’original';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get readTextFailed => 'Impossible de lire le texte. Réessayez.';

  @override
  String get voiceMissing =>
      'Vérifiez qu’une voix française pour la lecture hors connexion est téléchargée sur le téléphone.';

  @override
  String get playbackAndroidOnly =>
      'La lecture à voix haute est disponible sur Android.';

  @override
  String get about => 'À propos';

  @override
  String get back => 'Retour';

  @override
  String get appPurpose => 'À quoi sert Sedno';

  @override
  String get appDescription =>
      'Sedno simplifie et corrige les textes dans les langues prises en charge.';

  @override
  String get appAudience =>
      'Pour les personnes malentendantes et celles qui ont du mal à comprendre les textes complexes.';

  @override
  String get appAge =>
      'L’application est destinée aux personnes de 13 ans et plus.';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get typingInstructions =>
      'Saisissez ou collez un texte. Choisissez Simplifier ou Corriger.';

  @override
  String get captureInstructions =>
      'En mode Simplifier, vous pouvez aussi photographier un texte ou le dicter.';

  @override
  String get captureSubmitInstructions =>
      'Après avoir sélectionné le texte sur la photo, choisissez Simplifier. Le texte dicté est simplifié automatiquement.';

  @override
  String get localMediaNotice =>
      'Les photos et le son restent sur le téléphone. Seul le texte est envoyé à l’IA.';

  @override
  String get speechModelRequirements =>
      'La dictée nécessite Android 13 ou plus et un modèle vocal français téléchargé.';

  @override
  String get playbackRequirements =>
      'En mode Corriger, le haut-parleur lit le texte. Une voix française téléchargée et utilisable hors connexion est nécessaire.';

  @override
  String get restoreInstructions =>
      'Le résultat remplace le texte dans le même champ. Touchez son titre ou Retour pour rétablir l’original.';

  @override
  String get inputLimitNotice =>
      'Le texte peut contenir 4000 caractères au maximum.';

  @override
  String get guestNotice => 'Vous pouvez commencer sans créer de compte.';

  @override
  String get dailyLimit => 'Limite quotidienne';

  @override
  String get freeAllowance => 'Sans abonnement : 5 textes par jour.';

  @override
  String get paidAllowance => 'Avec abonnement : 400 textes par jour.';

  @override
  String get sharedAllowance =>
      'La simplification et la correction partagent la même limite.';

  @override
  String get subscriptionPriceNotice =>
      'Le prix de l’abonnement apparaît dans Compte et Google Play.';

  @override
  String get important => 'Important';

  @override
  String get aiErrorNotice => 'L’IA peut faire des erreurs.';

  @override
  String get checkResult => 'Vérifiez le résultat avant de l’utiliser.';

  @override
  String get author => 'Auteur : Mariusz Bąbka';

  @override
  String get privacy => 'Confidentialité et données';

  @override
  String get websiteOpenFailed =>
      'Impossible d’ouvrir le site. Vérifiez votre navigateur.';

  @override
  String get website => 'Site de Sedno';

  @override
  String get photoNoText => 'Aucun texte détecté. Prenez une photo plus nette.';

  @override
  String get cameraPermission =>
      'Autorisez l’appareil photo dans les paramètres du téléphone.';

  @override
  String get cameraStartFailed =>
      'Impossible de démarrer l’appareil photo. Réessayez.';

  @override
  String get photoCaptureFailed => 'Impossible de prendre la photo. Réessayez.';

  @override
  String get selectText => 'Sélectionner le texte';

  @override
  String get cropInstructions =>
      'Déplacez les coins du cadre pour sélectionner le texte. ';

  @override
  String get cropWholePhotoNotice =>
      'Sans modification, le texte de toute la photo sera simplifié.';

  @override
  String get openingPhoto => 'Ouverture de la photo';

  @override
  String get simplify => 'Simplifier';

  @override
  String get cropTopLeft => 'Coin supérieur gauche du cadre';

  @override
  String get cropTopRight => 'Coin supérieur droit du cadre';

  @override
  String get cropBottomLeft => 'Coin inférieur gauche du cadre';

  @override
  String get cropBottomRight => 'Coin inférieur droit du cadre';

  @override
  String get smallerSelection => 'Sélection plus petite';

  @override
  String get largerSelection => 'Sélection plus grande';

  @override
  String get cropResizeHint =>
      'Augmentez pour réduire la sélection. Diminuez pour l’agrandir.';

  @override
  String get takeTextPhoto => 'Photographier un texte';

  @override
  String get startingCamera => 'Démarrage de l’appareil photo';

  @override
  String get takingPhoto => 'Prise de photo…';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get photoOpenFailed =>
      'Impossible d’ouvrir la photo. Prenez-en une autre.';

  @override
  String get photoPrepareFailed =>
      'Impossible de préparer la photo. Réessayez.';

  @override
  String get simplifyHeading => 'simplifier le texte';

  @override
  String get simplifiedText => 'Texte simplifié';

  @override
  String get correctedText => 'Texte corrigé';

  @override
  String get emptyText => 'Le texte ne peut pas être vide.';

  @override
  String get textTooLong =>
      'Le texte peut contenir 4000 caractères au maximum.';

  @override
  String get subscriptionActive => 'Votre abonnement est actif.';

  @override
  String get subscriptionAllowance =>
      'Vous pouvez simplifier jusqu’à 400 textes par jour.';

  @override
  String get manageSubscriptionNotice =>
      'Pour modifier le paiement ou annuler l’abonnement, ouvrez Google Play.';

  @override
  String get manageSubscription => 'Gérer l’abonnement dans Google Play';

  @override
  String get testerAccessNotice => 'Vous bénéficiez d’un accès test gratuit.';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get refreshAccess => 'Actualiser l’accès';

  @override
  String get subscriptionBenefits =>
      'Jusqu’à 400 textes par jour avec abonnement, 5 sans abonnement.';

  @override
  String get subscriptionSignInNotice =>
      'Connectez-vous à votre compte Sedno pour acheter ou restaurer un abonnement.';

  @override
  String get buySubscription => 'S’abonner';

  @override
  String get refreshSubscription => 'Actualiser l’abonnement';

  @override
  String get subscriptionRenewalNotice =>
      'L’abonnement est renouvelé automatiquement chaque mois.';

  @override
  String get subscriptionCancelNotice =>
      'Vous pouvez l’annuler à tout moment dans Google Play.';

  @override
  String get paymentReadFailed =>
      'Impossible de lire les paiements. Essayez de restaurer les achats.';

  @override
  String get signInBeforePurchase => 'Connectez-vous avant l’achat.';

  @override
  String get subscriptionAlreadyActive => 'Votre abonnement est déjà actif.';

  @override
  String get signInBeforeRestore =>
      'Connectez-vous avant de restaurer un achat.';

  @override
  String get purchasesChecked =>
      'Achats vérifiés. La confirmation peut prendre un moment.';

  @override
  String get playOpenFailed =>
      'Impossible d’ouvrir Google Play. Ouvrez le magasin, puis Paiements et abonnements → Abonnements.';

  @override
  String get paymentPending =>
      'Le paiement attend confirmation. Votre limite reste inchangée.';

  @override
  String get purchaseCancelled => 'Achat annulé.';

  @override
  String get purchaseFailed => 'L’achat de l’abonnement a échoué. Réessayez.';

  @override
  String get subscriptionInactive => 'Votre abonnement n’est pas actif.';

  @override
  String get subscriptionVerifyFailed =>
      'Impossible de confirmer l’abonnement. Connectez-vous, vérifiez la connexion et restaurez les achats.';

  @override
  String get subscriptionCheckFailed =>
      'Impossible de vérifier l’abonnement. Connectez-vous et réessayez.';

  @override
  String get hideConfirmedPassword => 'Masquer le mot de passe répété';

  @override
  String get showConfirmedPassword => 'Afficher le mot de passe répété';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get enterEmail => 'Saisissez votre adresse e-mail.';

  @override
  String get enterValidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String get passwordResetSent =>
      'Si un compte existe avec cette adresse, vous recevrez un lien de réinitialisation. Vérifiez aussi les courriers indésirables.';

  @override
  String get emailSendFailed => 'L’envoi de l’e-mail a échoué. Réessayez.';

  @override
  String get accountLoadFailed =>
      'Impossible de charger le compte ou de terminer la suppression des données. Réessayez.';

  @override
  String get verificationEmailSent =>
      'Un e-mail avec un lien a été envoyé. Vérifiez votre boîte de réception et les courriers indésirables.';

  @override
  String get emailNotVerified =>
      'L’adresse n’est pas encore confirmée. Cliquez sur le lien de l’e-mail et réessayez.';

  @override
  String get signInFailed =>
      'Connexion impossible. Vérifiez vos informations et réessayez.';

  @override
  String get signOutFailed => 'Déconnexion impossible. Réessayez.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountIdentity =>
      'Confirmez votre identité pour supprimer le compte.';

  @override
  String get password => 'Mot de passe';

  @override
  String get keepAccount => 'Conserver le compte';

  @override
  String get deleteAccountAndData => 'Supprimer le compte et les données';

  @override
  String get accountDeleted =>
      'Le compte et les données ont été supprimés. Annulez l’abonnement séparément dans Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Impossible de terminer la suppression. Réessayez.';

  @override
  String get emailAccountMethod => ' (e-mail et mot de passe)';

  @override
  String get finishDataCleanup =>
      'Actualiser le compte et terminer le nettoyage';

  @override
  String get accountNotConfigured => 'Les options du compte apparaîtront ici.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get emailVerified => 'Adresse e-mail confirmée';

  @override
  String get checkInbox => 'Vérifiez vos e-mails';

  @override
  String get finishAccountLinkNotice =>
      'Votre adresse est confirmée. Il reste à connecter le compte Sedno. Il est inutile de cliquer à nouveau sur le lien.';

  @override
  String get verifyEmailInstructions =>
      'Cliquez sur le lien de l’e-mail de Sedno pour terminer la création du compte. Vérifiez aussi les courriers indésirables. Revenez ensuite et choisissez « Vérifier la confirmation ».';

  @override
  String get guestWhileVerifying =>
      'En attendant, vous pouvez utiliser l’application sans compte.';

  @override
  String get finishSignIn => 'Terminer la connexion';

  @override
  String get checkVerification => 'Vérifier la confirmation';

  @override
  String get resendEmail => 'Renvoyer l’e-mail';

  @override
  String get signOutUseGuest => 'Se déconnecter et utiliser sans compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get newAccount => 'Nouveau compte';

  @override
  String get recoverAccess => 'Récupérer l’accès';

  @override
  String get guestSignInNotice =>
      'Vous pouvez utiliser l’application sans connexion.';

  @override
  String get signInGoogle => 'Se connecter avec Google';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get enterPassword => 'Saisissez votre mot de passe.';

  @override
  String get passwordMinLength => 'Utilisez au moins 6 caractères.';

  @override
  String get repeatPassword => 'Répéter le mot de passe';

  @override
  String get enterRepeatedPassword => 'Répétez votre mot de passe.';

  @override
  String get passwordMismatch => 'Les mots de passe doivent être identiques.';

  @override
  String get verificationEmailNotice =>
      'Un e-mail avec un lien de confirmation sera envoyé.';

  @override
  String get passwordResetInstructions =>
      'Saisissez l’adresse e-mail du compte. Vous recevrez un lien pour changer le mot de passe.';

  @override
  String get signInEmail => 'Se connecter par e-mail';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get sendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get createAccountLink => 'Pas de compte ? Créer un compte';

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get testerAccess => 'Accès test';

  @override
  String get testerAllowance =>
      'Vous pouvez traiter jusqu’à 400 textes par jour.';

  @override
  String get testerExpiryNotice =>
      'L’accès est gratuit et expire automatiquement.';

  @override
  String get testerHasSubscription =>
      'Vous avez aussi un abonnement Google Play actif.';

  @override
  String get testerExpired => 'L’accès test a expiré.';

  @override
  String get subscriptionStillActive =>
      'Votre abonnement Google Play vous donne toujours une limite supérieure.';

  @override
  String get freeLimitRestored =>
      'La limite gratuite de 5 textes par jour s’applique. L’utilisation du jour reste inchangée.';

  @override
  String get closeMenu => 'Fermer le menu';

  @override
  String get welcome => 'Bienvenue dans Sedno';

  @override
  String get inApp => 'Dans l’application';

  @override
  String get accountCreatedEmailFailed =>
      'Le compte a été créé, mais l’envoi de l’e-mail a échoué. Essayez de le renvoyer.';

  @override
  String get signInToVerify =>
      'Connectez-vous par e-mail pour confirmer votre adresse.';

  @override
  String get signInToCheckAccount =>
      'Reconnectez-vous pour vérifier l’état du compte.';

  @override
  String get weakPassword =>
      'Mot de passe trop faible. Utilisez au moins 6 caractères.';

  @override
  String get checkEmailAddress => 'Vérifiez l’adresse e-mail saisie.';

  @override
  String get emailAlreadyUsed =>
      'Cette adresse est déjà utilisée. Connectez-vous au compte existant.';

  @override
  String get tooManyAttempts =>
      'Trop de tentatives. Attendez un moment et réessayez.';

  @override
  String get checkInternet =>
      'Pas de connexion. Vérifiez Internet et réessayez.';

  @override
  String get chooseSameAccount =>
      'Choisissez le compte que vous souhaitez supprimer.';

  @override
  String get signInToDelete => 'Reconnectez-vous pour supprimer le compte.';

  @override
  String get invalidCredentials =>
      'Connexion impossible. Vérifiez l’adresse e-mail et le mot de passe.';

  @override
  String get actionFailed => 'Cette action a échoué. Réessayez.';

  @override
  String get accountLinkFailed =>
      'Impossible de connecter le compte Sedno. Vérifiez la connexion et réessayez.';

  @override
  String get passwordToDelete =>
      'Saisissez le mot de passe pour confirmer la suppression.';

  @override
  String get finishLocalDeletion =>
      'Terminez la suppression des données sur cet appareil.';

  @override
  String get installationRejected =>
      'Le serveur n’a pas pu vérifier l’installation. Réessayez ou installez Sedno depuis Google Play.';

  @override
  String get sessionStartFailed =>
      'Impossible de démarrer une session. Réessayez.';

  @override
  String get signInToLink => 'Reconnectez-vous pour associer le compte.';

  @override
  String get cannotLinkAccount => 'Impossible d’associer le compte. Réessayez.';

  @override
  String get signInAgain => 'Reconnectez-vous.';

  @override
  String get sessionExpiredSignIn => 'La session a expiré. Reconnectez-vous.';

  @override
  String get cannotDeleteAccount =>
      'Impossible de supprimer le compte. Réessayez.';

  @override
  String get cannotSignOut => 'Impossible de se déconnecter. Réessayez.';

  @override
  String get correctionUnavailable =>
      'La correction n’est pas encore disponible.';

  @override
  String get simplificationUnavailable =>
      'La simplification n’est pas encore disponible.';

  @override
  String get requestTimeout => 'Délai dépassé. Réessayez.';

  @override
  String get offline => 'Pas de connexion Internet. Réessayez.';

  @override
  String get sessionExpired =>
      'La session a expiré. Vérifiez le compte et réessayez.';

  @override
  String get quotaExhausted =>
      'La limite du jour est atteinte. Consultez l’heure de renouvellement.';

  @override
  String get serviceUnavailable =>
      'Service temporairement indisponible. Réessayez.';

  @override
  String get correctionRejected =>
      'Impossible de corriger ce texte. Vérifiez-le et réessayez.';

  @override
  String get simplificationRejected =>
      'Impossible de simplifier ce texte. Vérifiez-le et réessayez.';

  @override
  String get correctionFailed => 'La correction a échoué. Réessayez.';

  @override
  String get simplificationFailed => 'La simplification a échoué. Réessayez.';

  @override
  String get checkConnection => 'Vérifiez la connexion';

  @override
  String get quotaCheckFailed =>
      'Impossible de vérifier la limite. Vérifiez la connexion.';

  @override
  String get subscriptionInAccount =>
      'L’abonnement et son prix se trouvent dans Compte.';

  @override
  String get beforeCorrection => 'Avant de corriger le texte';

  @override
  String get beforeSimplification => 'Avant de simplifier le texte';

  @override
  String get acceptAndSend => 'J’ai compris, envoyer';

  @override
  String get cameraUnavailable => 'L’appareil photo sera bientôt disponible.';

  @override
  String get aiWarning => 'L’IA peut se tromper';

  @override
  String get listeningNotice =>
      'Écoute… Parlez français. Fin après 1,5 seconde de silence ou 60 secondes. Le bouton d’arrêt annule l’enregistrement.';

  @override
  String get correctionSubmitted => 'Le texte a été envoyé pour correction.';

  @override
  String get simplificationSubmitted =>
      'Le texte a été envoyé pour simplification.';

  @override
  String get textForCorrection => 'Texte à corriger';

  @override
  String get textForSimplification => 'Texte à simplifier';

  @override
  String get inputHint => 'Saisissez ou collez un texte';

  @override
  String get switchToCorrection => 'Passer à la correction';

  @override
  String get switchToSimplification => 'Passer à la simplification';

  @override
  String get clearText => 'Effacer le texte';

  @override
  String get stopPlayback => 'Arrêter la lecture';

  @override
  String get readAloud => 'Lire à voix haute';

  @override
  String get cancelRecording => 'Annuler l’enregistrement';

  @override
  String get simplifySpeech => 'Simplifier la parole';

  @override
  String get cancel => 'Annuler';

  @override
  String get history => 'Historique';

  @override
  String get account => 'Compte';

  @override
  String get start => 'Accueil';

  @override
  String get contact => 'Contact';

  @override
  String get close => 'Fermer';

  @override
  String get continueAction => 'Continuer';

  @override
  String get correct => 'Corriger';

  @override
  String get correctHeading => 'corriger le texte';

  @override
  String get correcting => 'Correction…';

  @override
  String get simplifying => 'Simplification…';

  @override
  String get reading => 'Lecture…';

  @override
  String get camera => 'Appareil photo';

  @override
  String get preparing => 'Préparation…';

  @override
  String get subscription => 'Abonnement';

  @override
  String get yesterday => 'Hier';

  @override
  String get signedIn => 'Connexion réussie.';

  @override
  String get googleAccountMethod => ' (compte Google)';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Langue du téléphone';

  @override
  String get polish => 'Polonais';

  @override
  String get english => 'Anglais (Royaume-Uni)';

  @override
  String get languageNotice =>
      'La langue s’applique aux menus, à la simplification, à la correction et à la parole. Choisissez la langue du texte. Sedno ne traduit pas les textes.';

  @override
  String get languageSaveFailed =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String resetDaily(String time) {
    return 'La limite est renouvelée chaque jour à $time.';
  }

  @override
  String resetAbout(String time) {
    return 'La limite est renouvelée chaque jour à $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'La limite sera renouvelée à $time.';
  }

  @override
  String get quotaUsed => 'Vous avez utilisé votre limite du jour.';

  @override
  String get quotaOneSimplification => 'Il reste 1 simplification.';

  @override
  String get quotaOneUse => 'Il reste 1 utilisation de l’IA.';

  @override
  String get quotaUsedDialog => 'Vous avez atteint la limite quotidienne.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'La limite sera renouvelée à $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'dans $hours h $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price par mois';
  }

  @override
  String historyExpires(String date) {
    return 'Suppression prévue le $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Supprimer le texte enregistré le $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contact : $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Connecté : $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Adresse e-mail : $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Adresse à confirmer : $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Accès test jusqu’au $date (heure locale).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal : $horizontal %, vertical : $vertical %';
  }

  @override
  String welcomeName(String name) {
    return 'Bienvenue dans $name';
  }

  @override
  String policyVersion(String date) {
    return 'Version : $date';
  }

  @override
  String get speechModelDownloading =>
      'Le modèle vocal est en cours de téléchargement. Réessayez plus tard.';

  @override
  String get speechLanguageUnsupported =>
      'Le moteur vocal de ce téléphone ne propose pas la dictée locale dans cette langue. Vous pouvez saisir le texte ou utiliser l’appareil photo.';

  @override
  String get signInApple => 'Se connecter avec Apple';

  @override
  String get appleAccountMethod => 'Apple';

  @override
  String get signInCancelled => 'Connexion annulée.';

  @override
  String get accountMethodConflict =>
      'Ce compte utilise une autre méthode de connexion. Utilisez votre méthode habituelle.';

  @override
  String get localSpeechUnavailable =>
      'La reconnaissance vocale locale est indisponible pour cette langue sur cet appareil.';

  @override
  String get localSpeechModelMissing =>
      'Installez le modèle vocal local de votre langue dans les réglages.';

  @override
  String get deviceFeatureUnavailable =>
      'Cette fonction est indisponible sur cet appareil.';

  @override
  String get subscriptionOtherStore =>
      'Cet abonnement a été acheté dans une autre boutique. Gérez-le dans la boutique où vous l’avez acheté.';

  @override
  String get storeOpenFailed =>
      'Impossible d’ouvrir les réglages de l’abonnement. Réessayez.';

  @override
  String get appleManageSubscriptionNotice =>
      'Pour modifier le paiement ou annuler l’abonnement, ouvrez App Store.';

  @override
  String get appleManageSubscription => 'Gérer l’abonnement dans App Store';

  @override
  String get appleSubscriptionCancelNotice =>
      'Vous pouvez l’annuler à tout moment dans App Store.';

  @override
  String get appleAccountDeleted =>
      'Le compte et les données ont été supprimés. Annulez l’abonnement séparément dans App Store.';

  @override
  String get appleTesterHasSubscription =>
      'Vous avez aussi un abonnement App Store actif.';

  @override
  String get appleSubscriptionStillActive =>
      'Votre abonnement App Store vous donne toujours une limite supérieure.';

  @override
  String get appleInstallationRejected =>
      'Le serveur n’a pas pu vérifier l’installation. Réessayez ou installez Sedno depuis App Store.';

  @override
  String get appleSubscriptionPriceNotice =>
      'Le prix de l’abonnement apparaît dans Compte et App Store.';

  @override
  String get privacyIosSupplementTitle =>
      'Informations complémentaires pour iPhone';

  @override
  String get privacyIosSupplementBody =>
      'Les références ci-dessous à Android, Google Play et Play Integrity concernent uniquement Android. Sur iPhone, vous pouvez vous connecter avec Apple et masquer votre adresse e-mail. Firebase gère aussi la connexion. Apple facture les abonnements achetés dans l’App Store ; Sedno ne reçoit pas les données de carte. Supprimer le compte n’annule pas l’abonnement.\n\nApp Attest vérifie l’authenticité de l’application sans transmettre à Apple les textes, résultats ou photos. Le serveur conserve des données pseudonymes d’installation et de clé publique. Les défis sont valables 5 minutes et les clés 90 jours après la dernière vérification de session réussie. Les notifications d’achat sont conservées 30 jours. Une tâche serveur supprime les données expirées. Les métadonnées d’achat restent jusqu’à la suppression du compte.\n\nL’historique est chiffré, local, exclu des sauvegardes et expire après 7 jours. Photos et audio restent sur l’appareil. Dictée et lecture vocale fonctionnent uniquement en local si l’appareil et la langue le permettent. Vous envoyez le texte reconnu à OpenAI via Sedno après avoir accepté l’avis sur l’IA.\n\nLes autres informations ci-dessous, dont le responsable, les finalités, les bases légales et les pratiques OpenAI, s’appliquent aussi à l’iPhone. Confidentialité Apple : https://www.apple.com/legal/privacy/';

  @override
  String get linkApple => 'Associer un compte Apple';

  @override
  String get confirmAccountLink =>
      'Confirmez à nouveau votre compte actuel. Choisissez ensuite un compte Apple pour accéder au même compte Sedno.';

  @override
  String get passwordToLink =>
      'Saisissez le mot de passe de votre compte actuel pour l’associer à Apple.';

  @override
  String get linkGoogle => 'Associer un compte Google';

  @override
  String get confirmGoogleAccountLink =>
      'Confirmez à nouveau votre compte actuel. Choisissez ensuite un compte Google pour vous connecter au même compte Sedno.';

  @override
  String get passwordToLinkGoogle =>
      'Saisissez le mot de passe de votre compte actuel pour associer Google.';
}
