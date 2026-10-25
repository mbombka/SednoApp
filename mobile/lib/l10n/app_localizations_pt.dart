// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get restoreOriginal => 'Repor o texto original';

  @override
  String get userMenu => 'Menu do utilizador';

  @override
  String get speechNotRecognised =>
      'Não foi reconhecida fala. Tenta novamente.';

  @override
  String get speechFailed =>
      'Não foi possível reconhecer a fala. Tenta novamente.';

  @override
  String get microphonePermission =>
      'Permite o acesso ao microfone nas definições da aplicação.';

  @override
  String get speechRequirements =>
      'O reconhecimento local exige Android 13 ou posterior e um motor de voz compatível.';

  @override
  String get speechModelMissing =>
      'Transfere o modelo de português de Portugal nas definições de reconhecimento de voz do Android.';

  @override
  String get speechTimeout =>
      'O reconhecimento demorou demasiado. Tenta novamente.';

  @override
  String get speechAndroidOnly =>
      'O reconhecimento local está disponível a partir do Android 13.';

  @override
  String get historyClearFailed =>
      'Não foi possível apagar todo o histórico. Tenta novamente.';

  @override
  String get deleteHistoryEntryTitle => 'Apagar este texto do histórico?';

  @override
  String get cannotUndo => 'Esta ação não pode ser anulada.';

  @override
  String get delete => 'Apagar';

  @override
  String get historyEntryDeleted => 'Texto apagado.';

  @override
  String get deleteHistoryTitle => 'Apagar todo o histórico?';

  @override
  String get deleteHistoryNotice =>
      'Todos os textos guardados serão apagados deste telemóvel. Esta ação não pode ser anulada.';

  @override
  String get deleteAllHistory => 'Apagar todo o histórico';

  @override
  String get historyDeleted => 'Histórico apagado.';

  @override
  String get historyLocalNotice =>
      'Os textos são guardados apenas neste telemóvel.';

  @override
  String get historyRetentionNotice =>
      'Cada texto é apagado automaticamente após 7 dias.';

  @override
  String get historySignOutNotice => 'Terminar sessão apaga todo o histórico.';

  @override
  String get deleteHistoryNow => 'Apagar todo o histórico agora';

  @override
  String get deletingHistory => 'A apagar o histórico';

  @override
  String get loadingHistory => 'A carregar o histórico';

  @override
  String get historyLoadFailed => 'Não foi possível carregar o histórico.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get historyEmpty => 'Ainda não tens textos guardados.';

  @override
  String get historyEmptyNotice =>
      'Os textos simplificados ou corrigidos aparecem aqui.';

  @override
  String get correctedVersion => 'Versão corrigida';

  @override
  String get simplifiedVersion => 'Versão simples';

  @override
  String get originalText => 'Texto original';

  @override
  String get hideOriginal => 'Ocultar original';

  @override
  String get showOriginal => 'Mostrar original';

  @override
  String get today => 'Hoje';

  @override
  String get readTextFailed => 'Não foi possível ler o texto. Tenta novamente.';

  @override
  String get voiceMissing =>
      'Verifica se transferiste uma voz de português de Portugal para leitura sem Internet.';

  @override
  String get playbackAndroidOnly =>
      'A leitura em voz alta está disponível no Android.';

  @override
  String get about => 'Sobre a aplicação';

  @override
  String get back => 'Voltar';

  @override
  String get appPurpose => 'Para que serve o Sedno';

  @override
  String get appDescription =>
      'O Sedno simplifica e corrige textos nos idiomas disponíveis.';

  @override
  String get appAudience =>
      'Para pessoas com dificuldades auditivas ou em compreender textos complexos.';

  @override
  String get appAge => 'A aplicação destina-se a pessoas com 13 anos ou mais.';

  @override
  String get howItWorks => 'Como funciona';

  @override
  String get typingInstructions =>
      'Escreve ou cola um texto. Escolhe Simplificar ou Corrigir.';

  @override
  String get captureInstructions =>
      'No modo Simplificar podes também fotografar um texto ou ditá-lo.';

  @override
  String get captureSubmitInstructions =>
      'Seleciona o texto na fotografia e escolhe Simplificar. O texto ditado é simplificado automaticamente.';

  @override
  String get localMediaNotice =>
      'As fotografias e o som ficam no telemóvel. Só o texto é enviado à IA.';

  @override
  String get speechModelRequirements =>
      'O ditado exige Android 13 ou posterior e um modelo de português de Portugal transferido.';

  @override
  String get playbackRequirements =>
      'No modo Corrigir, o altifalante lê o texto. É necessária uma voz de português de Portugal transferida que funcione sem Internet.';

  @override
  String get restoreInstructions =>
      'O resultado aparece no mesmo campo. Toca no título ou em Voltar para repor o original.';

  @override
  String get inputLimitNotice => 'O texto pode ter até 4000 caracteres.';

  @override
  String get guestNotice => 'Podes começar sem criar uma conta.';

  @override
  String get dailyLimit => 'Limite diário';

  @override
  String get freeAllowance => 'Sem subscrição: 5 textos por dia.';

  @override
  String get paidAllowance => 'Com subscrição: 400 textos por dia.';

  @override
  String get sharedAllowance =>
      'A simplificação e a correção partilham o mesmo limite.';

  @override
  String get subscriptionPriceNotice =>
      'O preço da subscrição está em Conta e no Google Play.';

  @override
  String get important => 'Importante';

  @override
  String get aiErrorNotice => 'A IA pode cometer erros.';

  @override
  String get checkResult => 'Verifica o resultado antes de o utilizares.';

  @override
  String get author => 'Autor: Mariusz Bąbka';

  @override
  String get privacy => 'Privacidade e dados';

  @override
  String get websiteOpenFailed =>
      'Não foi possível abrir o site. Verifica o navegador.';

  @override
  String get website => 'Site do Sedno';

  @override
  String get photoNoText =>
      'Não foi detetado texto. Tira uma fotografia mais nítida.';

  @override
  String get cameraPermission =>
      'Permite o acesso à câmara nas definições do telemóvel.';

  @override
  String get cameraStartFailed =>
      'Não foi possível iniciar a câmara. Tenta novamente.';

  @override
  String get photoCaptureFailed =>
      'Não foi possível tirar a fotografia. Tenta novamente.';

  @override
  String get selectText => 'Selecionar texto';

  @override
  String get cropInstructions =>
      'Move os cantos da moldura para selecionar o texto. ';

  @override
  String get cropWholePhotoNotice =>
      'Sem alterações, será simplificado o texto de toda a fotografia.';

  @override
  String get openingPhoto => 'A abrir a fotografia';

  @override
  String get simplify => 'Simplificar';

  @override
  String get cropTopLeft => 'Canto superior esquerdo da moldura';

  @override
  String get cropTopRight => 'Canto superior direito da moldura';

  @override
  String get cropBottomLeft => 'Canto inferior esquerdo da moldura';

  @override
  String get cropBottomRight => 'Canto inferior direito da moldura';

  @override
  String get smallerSelection => 'Seleção menor';

  @override
  String get largerSelection => 'Seleção maior';

  @override
  String get cropResizeHint =>
      'Aumenta para reduzir a seleção. Diminui para a ampliar.';

  @override
  String get takeTextPhoto => 'Fotografar texto';

  @override
  String get startingCamera => 'A iniciar a câmara';

  @override
  String get takingPhoto => 'A tirar a fotografia…';

  @override
  String get takePhoto => 'Tirar fotografia';

  @override
  String get photoOpenFailed =>
      'Não foi possível abrir a fotografia. Tira outra.';

  @override
  String get photoPrepareFailed =>
      'Não foi possível preparar a fotografia. Tenta novamente.';

  @override
  String get simplifyHeading => 'simplificar texto';

  @override
  String get simplifiedText => 'Texto simplificado';

  @override
  String get correctedText => 'Texto corrigido';

  @override
  String get emptyText => 'O texto não pode estar vazio.';

  @override
  String get textTooLong => 'O texto pode ter até 4000 caracteres.';

  @override
  String get subscriptionActive => 'A tua subscrição está ativa.';

  @override
  String get subscriptionAllowance =>
      'Podes simplificar até 400 textos por dia.';

  @override
  String get manageSubscriptionNotice =>
      'Para alterar o pagamento ou cancelar a subscrição, abre o Google Play.';

  @override
  String get manageSubscription => 'Gerir subscrição no Google Play';

  @override
  String get testerAccessNotice => 'Tens acesso de teste gratuito.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get refreshAccess => 'Atualizar acesso';

  @override
  String get subscriptionBenefits =>
      'Até 400 textos por dia com subscrição e 5 sem subscrição.';

  @override
  String get subscriptionSignInNotice =>
      'Inicia sessão no Sedno para comprar ou restaurar uma subscrição.';

  @override
  String get buySubscription => 'Comprar subscrição';

  @override
  String get refreshSubscription => 'Atualizar subscrição';

  @override
  String get subscriptionRenewalNotice =>
      'A subscrição renova-se automaticamente todos os meses.';

  @override
  String get subscriptionCancelNotice =>
      'Podes cancelá-la a qualquer momento no Google Play.';

  @override
  String get paymentReadFailed =>
      'Não foi possível ler os pagamentos. Tenta restaurar as compras.';

  @override
  String get signInBeforePurchase => 'Inicia sessão antes de comprar.';

  @override
  String get subscriptionAlreadyActive => 'A tua subscrição já está ativa.';

  @override
  String get signInBeforeRestore =>
      'Inicia sessão antes de restaurar uma compra.';

  @override
  String get purchasesChecked =>
      'Compras verificadas. A confirmação pode demorar um pouco.';

  @override
  String get playOpenFailed =>
      'Não foi possível abrir o Google Play. Abre a loja e escolhe Pagamentos e subscrições → Subscrições.';

  @override
  String get paymentPending =>
      'O pagamento aguarda confirmação. O limite não muda.';

  @override
  String get purchaseCancelled => 'Compra cancelada.';

  @override
  String get purchaseFailed =>
      'Não foi possível comprar a subscrição. Tenta novamente.';

  @override
  String get subscriptionInactive => 'A tua subscrição não está ativa.';

  @override
  String get subscriptionVerifyFailed =>
      'Não foi possível confirmar a subscrição. Inicia sessão, verifica a ligação e restaura as compras.';

  @override
  String get subscriptionCheckFailed =>
      'Não foi possível verificar a subscrição. Inicia sessão e tenta novamente.';

  @override
  String get hideConfirmedPassword => 'Ocultar palavra-passe repetida';

  @override
  String get showConfirmedPassword => 'Mostrar palavra-passe repetida';

  @override
  String get hidePassword => 'Ocultar palavra-passe';

  @override
  String get showPassword => 'Mostrar palavra-passe';

  @override
  String get enterEmail => 'Introduz o teu endereço de e-mail.';

  @override
  String get enterValidEmail => 'Introduz um endereço de e-mail válido.';

  @override
  String get passwordResetSent =>
      'Se existir uma conta com este endereço, receberás uma ligação para repor a palavra-passe. Verifica também o spam.';

  @override
  String get emailSendFailed =>
      'Não foi possível enviar o e-mail. Tenta novamente.';

  @override
  String get accountLoadFailed =>
      'Não foi possível carregar a conta ou concluir a eliminação dos dados. Tenta novamente.';

  @override
  String get verificationEmailSent =>
      'Enviámos um e-mail com uma ligação. Verifica a caixa de entrada e o spam.';

  @override
  String get emailNotVerified =>
      'O endereço ainda não está confirmado. Abre a ligação no e-mail e tenta novamente.';

  @override
  String get signInFailed =>
      'Não foi possível iniciar sessão. Verifica os dados e tenta novamente.';

  @override
  String get signOutFailed =>
      'Não foi possível terminar sessão. Tenta novamente.';

  @override
  String get deleteAccountTitle => 'Eliminar conta?';

  @override
  String get deleteAccountIdentity =>
      'Confirma a tua identidade para eliminar a conta.';

  @override
  String get password => 'Palavra-passe';

  @override
  String get keepAccount => 'Manter conta';

  @override
  String get deleteAccountAndData => 'Eliminar conta e dados';

  @override
  String get accountDeleted =>
      'A conta e os dados foram eliminados. Cancela a subscrição separadamente no Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'Não foi possível concluir a eliminação. Tenta novamente.';

  @override
  String get emailAccountMethod => ' (e-mail e palavra-passe)';

  @override
  String get finishDataCleanup => 'Atualizar conta e concluir limpeza';

  @override
  String get accountNotConfigured => 'As opções da conta aparecem aqui.';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get deleteAccount => 'Eliminar conta';

  @override
  String get emailVerified => 'Endereço de e-mail confirmado';

  @override
  String get checkInbox => 'Verifica o e-mail';

  @override
  String get finishAccountLinkNotice =>
      'O endereço está confirmado. Falta ligar a conta Sedno. Não precisas de abrir novamente a ligação no e-mail.';

  @override
  String get verifyEmailInstructions =>
      'Abre a ligação no e-mail do Sedno para concluir a criação da conta. Verifica também o spam. Depois volta aqui e escolhe «Verificar confirmação».';

  @override
  String get guestWhileVerifying =>
      'Entretanto, podes usar a aplicação sem conta.';

  @override
  String get finishSignIn => 'Concluir início de sessão';

  @override
  String get checkVerification => 'Verificar confirmação';

  @override
  String get resendEmail => 'Reenviar e-mail';

  @override
  String get signOutUseGuest => 'Terminar sessão e usar sem conta';

  @override
  String get signIn => 'Iniciar sessão';

  @override
  String get newAccount => 'Nova conta';

  @override
  String get recoverAccess => 'Recuperar acesso';

  @override
  String get guestSignInNotice => 'Podes usar a aplicação sem iniciar sessão.';

  @override
  String get signInGoogle => 'Iniciar sessão com Google';

  @override
  String get emailAddress => 'Endereço de e-mail';

  @override
  String get enterPassword => 'Introduz a palavra-passe.';

  @override
  String get passwordMinLength => 'Usa pelo menos 6 caracteres.';

  @override
  String get repeatPassword => 'Repetir palavra-passe';

  @override
  String get enterRepeatedPassword => 'Repete a palavra-passe.';

  @override
  String get passwordMismatch => 'As palavras-passe devem ser iguais.';

  @override
  String get verificationEmailNotice =>
      'Enviaremos um e-mail com uma ligação para confirmar o endereço.';

  @override
  String get passwordResetInstructions =>
      'Introduz o e-mail da conta. Enviaremos uma ligação para alterar a palavra-passe.';

  @override
  String get signInEmail => 'Iniciar sessão com e-mail';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get sendResetLink => 'Enviar ligação para repor palavra-passe';

  @override
  String get forgotPassword => 'Esqueci-me da palavra-passe';

  @override
  String get createAccountLink => 'Não tens conta? Cria uma';

  @override
  String get backToSignIn => 'Voltar ao início de sessão';

  @override
  String get testerAccess => 'Acesso de teste';

  @override
  String get testerAllowance => 'Podes processar até 400 textos por dia.';

  @override
  String get testerExpiryNotice =>
      'O acesso é gratuito e expira automaticamente.';

  @override
  String get testerHasSubscription =>
      'Também tens uma subscrição Google Play ativa.';

  @override
  String get testerExpired => 'O acesso de teste expirou.';

  @override
  String get subscriptionStillActive =>
      'A tua subscrição Google Play continua a oferecer um limite maior.';

  @override
  String get freeLimitRestored =>
      'Aplica-se o limite gratuito de 5 textos por dia. A utilização de hoje mantém-se.';

  @override
  String get closeMenu => 'Fechar menu';

  @override
  String get welcome => 'Bem-vindo ao Sedno';

  @override
  String get inApp => 'Na aplicação';

  @override
  String get accountCreatedEmailFailed =>
      'A conta foi criada, mas não foi possível enviar o e-mail. Tenta reenviá-lo.';

  @override
  String get signInToVerify =>
      'Inicia sessão com e-mail para confirmar o endereço.';

  @override
  String get signInToCheckAccount =>
      'Inicia sessão novamente para verificar a conta.';

  @override
  String get weakPassword =>
      'A palavra-passe é demasiado fraca. Usa pelo menos 6 caracteres.';

  @override
  String get checkEmailAddress => 'Verifica o endereço de e-mail introduzido.';

  @override
  String get emailAlreadyUsed =>
      'Este endereço já está a ser usado. Inicia sessão na conta existente.';

  @override
  String get tooManyAttempts =>
      'Demasiadas tentativas. Aguarda um pouco e tenta novamente.';

  @override
  String get checkInternet =>
      'Sem ligação. Verifica a Internet e tenta novamente.';

  @override
  String get chooseSameAccount => 'Escolhe a conta que queres eliminar.';

  @override
  String get signInToDelete => 'Inicia sessão novamente para eliminar a conta.';

  @override
  String get invalidCredentials =>
      'Não foi possível iniciar sessão. Verifica o e-mail e a palavra-passe.';

  @override
  String get actionFailed =>
      'Não foi possível concluir a ação. Tenta novamente.';

  @override
  String get accountLinkFailed =>
      'Não foi possível ligar a conta Sedno. Verifica a ligação e tenta novamente.';

  @override
  String get passwordToDelete =>
      'Introduz a palavra-passe para confirmar a eliminação.';

  @override
  String get finishLocalDeletion =>
      'Conclui a eliminação dos dados neste dispositivo.';

  @override
  String get installationRejected =>
      'O servidor não verificou a instalação. Tenta novamente ou instala o Sedno pelo Google Play.';

  @override
  String get sessionStartFailed =>
      'Não foi possível iniciar a sessão. Tenta novamente.';

  @override
  String get signInToLink => 'Inicia sessão novamente para associar a conta.';

  @override
  String get cannotLinkAccount =>
      'Não foi possível associar a conta. Tenta novamente.';

  @override
  String get signInAgain => 'Inicia sessão novamente.';

  @override
  String get sessionExpiredSignIn =>
      'A sessão expirou. Inicia sessão novamente.';

  @override
  String get cannotDeleteAccount =>
      'Não foi possível eliminar a conta. Tenta novamente.';

  @override
  String get cannotSignOut =>
      'Não foi possível terminar sessão. Tenta novamente.';

  @override
  String get correctionUnavailable => 'A correção ainda não está disponível.';

  @override
  String get simplificationUnavailable =>
      'A simplificação ainda não está disponível.';

  @override
  String get requestTimeout => 'O tempo de espera terminou. Tenta novamente.';

  @override
  String get offline => 'Sem ligação à Internet. Tenta novamente.';

  @override
  String get sessionExpired =>
      'A sessão expirou. Verifica a conta e tenta novamente.';

  @override
  String get quotaExhausted =>
      'Esgotaste o limite de hoje. Consulta a hora de renovação.';

  @override
  String get serviceUnavailable =>
      'Serviço temporariamente indisponível. Tenta novamente.';

  @override
  String get correctionRejected =>
      'Não é possível corrigir este texto. Verifica-o e tenta novamente.';

  @override
  String get simplificationRejected =>
      'Não é possível simplificar este texto. Verifica-o e tenta novamente.';

  @override
  String get correctionFailed =>
      'Não foi possível corrigir o texto. Tenta novamente.';

  @override
  String get simplificationFailed =>
      'Não foi possível simplificar o texto. Tenta novamente.';

  @override
  String get checkConnection => 'Verifica a ligação';

  @override
  String get quotaCheckFailed =>
      'Não é possível verificar o limite. Verifica a ligação.';

  @override
  String get subscriptionInAccount => 'A subscrição e o preço estão em Conta.';

  @override
  String get beforeCorrection => 'Antes de corrigir o texto';

  @override
  String get beforeSimplification => 'Antes de simplificar o texto';

  @override
  String get acceptAndSend => 'Compreendi, enviar';

  @override
  String get cameraUnavailable => 'A câmara estará disponível em breve.';

  @override
  String get aiWarning => 'A IA pode enganar-se';

  @override
  String get listeningNotice =>
      'A ouvir… Fala português. Termina após 1,5 segundos de silêncio ou 60 segundos. O botão de paragem cancela a gravação.';

  @override
  String get correctionSubmitted => 'O texto foi enviado para correção.';

  @override
  String get simplificationSubmitted =>
      'O texto foi enviado para simplificação.';

  @override
  String get textForCorrection => 'Texto para corrigir';

  @override
  String get textForSimplification => 'Texto para simplificar';

  @override
  String get inputHint => 'Escreve ou cola um texto';

  @override
  String get switchToCorrection => 'Mudar para correção';

  @override
  String get switchToSimplification => 'Mudar para simplificação';

  @override
  String get clearText => 'Limpar texto';

  @override
  String get stopPlayback => 'Parar leitura';

  @override
  String get readAloud => 'Ler em voz alta';

  @override
  String get cancelRecording => 'Cancelar gravação';

  @override
  String get simplifySpeech => 'Simplificar fala';

  @override
  String get cancel => 'Cancelar';

  @override
  String get history => 'Histórico';

  @override
  String get account => 'Conta';

  @override
  String get start => 'Início';

  @override
  String get contact => 'Contacto';

  @override
  String get close => 'Fechar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get correct => 'Corrigir';

  @override
  String get correctHeading => 'corrigir texto';

  @override
  String get correcting => 'A corrigir…';

  @override
  String get simplifying => 'A simplificar…';

  @override
  String get reading => 'A ler…';

  @override
  String get camera => 'Câmara';

  @override
  String get preparing => 'A preparar…';

  @override
  String get subscription => 'Subscrição';

  @override
  String get yesterday => 'Ontem';

  @override
  String get signedIn => 'Sessão iniciada.';

  @override
  String get googleAccountMethod => ' (conta Google)';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma do telemóvel';

  @override
  String get polish => 'Polaco';

  @override
  String get english => 'Inglês (Reino Unido)';

  @override
  String get languageNotice =>
      'O idioma aplica-se aos menus, à simplificação, à correção e à voz. Escolhe o idioma do texto. O Sedno não traduz textos.';

  @override
  String get languageSaveFailed =>
      'Não foi possível guardar o idioma. Tenta novamente.';

  @override
  String resetDaily(String time) {
    return 'O limite é renovado todos os dias às $time.';
  }

  @override
  String resetAbout(String time) {
    return 'O limite é renovado todos os dias às $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'O limite será renovado às $time.';
  }

  @override
  String get quotaUsed => 'Esgotaste o limite de hoje.';

  @override
  String get quotaOneSimplification => 'Resta 1 simplificação.';

  @override
  String get quotaOneUse => 'Resta 1 utilização da IA.';

  @override
  String get quotaUsedDialog => 'Esgotaste o limite diário.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'O limite será renovado às $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'daqui a $hours h e $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price por mês';
  }

  @override
  String historyExpires(String date) {
    return 'Será apagado em $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Apagar texto guardado em $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contacto: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Sessão iniciada como $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Endereço de e-mail: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Endereço a confirmar: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Reenviar daqui a $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Acesso de teste até $date (hora local).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal $horizontal%, vertical $vertical%';
  }

  @override
  String welcomeName(String name) {
    return 'Bem-vindo ao $name';
  }

  @override
  String policyVersion(String date) {
    return 'Versão: $date';
  }

  @override
  String get speechModelDownloading =>
      'O modelo de voz está a ser transferido. Tenta mais tarde.';

  @override
  String get speechLanguageUnsupported =>
      'O motor de voz deste telemóvel não oferece ditado local neste idioma. Podes escrever ou usar a câmara.';
}
