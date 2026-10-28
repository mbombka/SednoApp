// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get restoreOriginal => 'Restaurar texto original';

  @override
  String get userMenu => 'Menú de usuario';

  @override
  String get speechNotRecognised =>
      'No se ha reconocido voz. Inténtalo de nuevo.';

  @override
  String get speechFailed =>
      'No se ha podido reconocer la voz. Inténtalo de nuevo.';

  @override
  String get microphonePermission =>
      'Permite el acceso al micrófono en los ajustes de la aplicación.';

  @override
  String get speechRequirements =>
      'El reconocimiento local requiere Android 13 o posterior y un motor de voz compatible.';

  @override
  String get speechModelMissing =>
      'Descarga el modelo de voz en español en los ajustes de reconocimiento de voz de Android.';

  @override
  String get speechTimeout =>
      'El reconocimiento ha tardado demasiado. Inténtalo de nuevo.';

  @override
  String get speechAndroidOnly =>
      'El reconocimiento local está disponible desde Android 13.';

  @override
  String get historyClearFailed =>
      'No se ha podido borrar todo el historial. Inténtalo de nuevo.';

  @override
  String get deleteHistoryEntryTitle => '¿Borrar este texto del historial?';

  @override
  String get cannotUndo => 'Esta acción no se puede deshacer.';

  @override
  String get delete => 'Borrar';

  @override
  String get historyEntryDeleted => 'Texto borrado.';

  @override
  String get deleteHistoryTitle => '¿Borrar todo el historial?';

  @override
  String get deleteHistoryNotice =>
      'Se borrarán todos los textos guardados en este teléfono. Esta acción no se puede deshacer.';

  @override
  String get deleteAllHistory => 'Borrar todo el historial';

  @override
  String get historyDeleted => 'Historial borrado.';

  @override
  String get historyLocalNotice =>
      'Los textos solo se guardan en este teléfono.';

  @override
  String get historyRetentionNotice =>
      'Cada texto se borra automáticamente después de 7 días.';

  @override
  String get historySignOutNotice => 'Cerrar sesión borra todo el historial.';

  @override
  String get deleteHistoryNow => 'Borrar todo el historial ahora';

  @override
  String get deletingHistory => 'Borrando historial';

  @override
  String get loadingHistory => 'Cargando historial';

  @override
  String get historyLoadFailed => 'No se ha podido cargar el historial.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get historyEmpty => 'Aún no tienes textos guardados.';

  @override
  String get historyEmptyNotice =>
      'Los textos simplificados o corregidos aparecerán aquí.';

  @override
  String get correctedVersion => 'Versión corregida';

  @override
  String get simplifiedVersion => 'Versión sencilla';

  @override
  String get originalText => 'Texto original';

  @override
  String get hideOriginal => 'Ocultar original';

  @override
  String get showOriginal => 'Mostrar original';

  @override
  String get today => 'Hoy';

  @override
  String get readTextFailed =>
      'No se ha podido leer el texto. Inténtalo de nuevo.';

  @override
  String get voiceMissing =>
      'Comprueba que has descargado una voz en español de España para leer sin Internet.';

  @override
  String get playbackAndroidOnly =>
      'La lectura en voz alta está disponible en Android.';

  @override
  String get about => 'Acerca de la aplicación';

  @override
  String get back => 'Atrás';

  @override
  String get appPurpose => 'Para qué sirve Sedno';

  @override
  String get appDescription =>
      'Sedno simplifica y corrige textos en los idiomas disponibles.';

  @override
  String get appAudience =>
      'Para personas con dificultades auditivas o para comprender textos complejos.';

  @override
  String get appAge => 'La aplicación es para personas de 13 años o más.';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get typingInstructions =>
      'Escribe o pega un texto. Elige Simplificar o Corregir.';

  @override
  String get captureInstructions =>
      'En el modo Simplificar también puedes fotografiar un texto o dictarlo.';

  @override
  String get captureSubmitInstructions =>
      'Selecciona el texto de la foto y elige Simplificar. El texto dictado se simplifica automáticamente.';

  @override
  String get localMediaNotice =>
      'Las fotos y el audio se quedan en el teléfono. Solo se envía el texto a la IA.';

  @override
  String get speechModelRequirements =>
      'El dictado requiere Android 13 o posterior y un modelo de voz en español descargado.';

  @override
  String get playbackRequirements =>
      'En el modo Corregir, el altavoz lee el texto. Necesitas una voz descargada en español de España que funcione sin Internet.';

  @override
  String get restoreInstructions =>
      'El resultado aparece en el mismo campo. Toca su título o Atrás para restaurar el original.';

  @override
  String get inputLimitNotice => 'El texto puede tener hasta 4000 caracteres.';

  @override
  String get guestNotice => 'Puedes empezar sin crear una cuenta.';

  @override
  String get dailyLimit => 'Límite diario';

  @override
  String get freeAllowance => 'Sin suscripción: 5 textos al día.';

  @override
  String get paidAllowance => 'Con suscripción: 400 textos al día.';

  @override
  String get sharedAllowance =>
      'Simplificar y corregir comparten el mismo límite.';

  @override
  String get subscriptionPriceNotice =>
      'Puedes ver el precio en Cuenta y en Google Play.';

  @override
  String get important => 'Importante';

  @override
  String get aiErrorNotice => 'La IA puede cometer errores.';

  @override
  String get checkResult => 'Comprueba el resultado antes de usarlo.';

  @override
  String get author => 'Autor: Mariusz Bąbka';

  @override
  String get privacy => 'Privacidad y datos';

  @override
  String get websiteOpenFailed =>
      'No se puede abrir la web. Comprueba el navegador.';

  @override
  String get website => 'Web de Sedno';

  @override
  String get photoNoText =>
      'No se ha detectado texto. Haz una foto más nítida.';

  @override
  String get cameraPermission =>
      'Permite el acceso a la cámara en los ajustes del teléfono.';

  @override
  String get cameraStartFailed =>
      'No se ha podido iniciar la cámara. Inténtalo de nuevo.';

  @override
  String get photoCaptureFailed =>
      'No se ha podido hacer la foto. Inténtalo de nuevo.';

  @override
  String get selectText => 'Seleccionar texto';

  @override
  String get cropInstructions =>
      'Mueve las esquinas del marco para seleccionar el texto. ';

  @override
  String get cropWholePhotoNotice =>
      'Si no lo cambias, se simplificará el texto de toda la foto.';

  @override
  String get openingPhoto => 'Abriendo foto';

  @override
  String get simplify => 'Simplificar';

  @override
  String get cropTopLeft => 'Esquina superior izquierda del marco';

  @override
  String get cropTopRight => 'Esquina superior derecha del marco';

  @override
  String get cropBottomLeft => 'Esquina inferior izquierda del marco';

  @override
  String get cropBottomRight => 'Esquina inferior derecha del marco';

  @override
  String get smallerSelection => 'Selección más pequeña';

  @override
  String get largerSelection => 'Selección más grande';

  @override
  String get cropResizeHint =>
      'Aumenta para reducir la selección. Disminuye para ampliarla.';

  @override
  String get takeTextPhoto => 'Fotografiar texto';

  @override
  String get startingCamera => 'Iniciando cámara';

  @override
  String get takingPhoto => 'Haciendo foto…';

  @override
  String get takePhoto => 'Hacer foto';

  @override
  String get photoOpenFailed => 'No se ha podido abrir la foto. Haz otra.';

  @override
  String get photoPrepareFailed =>
      'No se ha podido preparar la foto. Inténtalo de nuevo.';

  @override
  String get simplifyHeading => 'simplificar texto';

  @override
  String get simplifiedText => 'Texto simplificado';

  @override
  String get correctedText => 'Texto corregido';

  @override
  String get emptyText => 'El texto no puede estar vacío.';

  @override
  String get textTooLong => 'El texto puede tener hasta 4000 caracteres.';

  @override
  String get subscriptionActive => 'Tu suscripción está activa.';

  @override
  String get subscriptionAllowance =>
      'Puedes simplificar hasta 400 textos al día.';

  @override
  String get manageSubscriptionNotice =>
      'Para cambiar el pago o cancelar la suscripción, abre Google Play.';

  @override
  String get manageSubscription => 'Gestionar suscripción en Google Play';

  @override
  String get testerAccessNotice => 'Tienes acceso de prueba gratuito.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get refreshAccess => 'Actualizar acceso';

  @override
  String get subscriptionBenefits =>
      'Hasta 400 textos al día con suscripción y 5 sin ella.';

  @override
  String get subscriptionSignInNotice =>
      'Inicia sesión en Sedno para comprar o restaurar una suscripción.';

  @override
  String get buySubscription => 'Comprar suscripción';

  @override
  String get refreshSubscription => 'Actualizar suscripción';

  @override
  String get subscriptionRenewalNotice =>
      'La suscripción se renueva automáticamente cada mes.';

  @override
  String get subscriptionCancelNotice =>
      'Puedes cancelarla cuando quieras en Google Play.';

  @override
  String get paymentReadFailed =>
      'No se pueden leer los pagos. Prueba a restaurar las compras.';

  @override
  String get signInBeforePurchase => 'Inicia sesión antes de comprar.';

  @override
  String get subscriptionAlreadyActive => 'Tu suscripción ya está activa.';

  @override
  String get signInBeforeRestore =>
      'Inicia sesión antes de restaurar una compra.';

  @override
  String get purchasesChecked =>
      'Compras comprobadas. La confirmación puede tardar un momento.';

  @override
  String get playOpenFailed =>
      'No se puede abrir Google Play. Abre la tienda y elige Pagos y suscripciones → Suscripciones.';

  @override
  String get paymentPending =>
      'El pago está pendiente de confirmación. Tu límite no cambia.';

  @override
  String get purchaseCancelled => 'Compra cancelada.';

  @override
  String get purchaseFailed =>
      'No se ha podido comprar la suscripción. Inténtalo de nuevo.';

  @override
  String get subscriptionInactive => 'Tu suscripción no está activa.';

  @override
  String get subscriptionVerifyFailed =>
      'No se puede confirmar la suscripción. Inicia sesión, comprueba la conexión y restaura las compras.';

  @override
  String get subscriptionCheckFailed =>
      'No se puede comprobar la suscripción. Inicia sesión y reinténtalo.';

  @override
  String get hideConfirmedPassword => 'Ocultar contraseña repetida';

  @override
  String get showConfirmedPassword => 'Mostrar contraseña repetida';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get enterEmail => 'Introduce tu correo electrónico.';

  @override
  String get enterValidEmail => 'Introduce un correo electrónico válido.';

  @override
  String get passwordResetSent =>
      'Si existe una cuenta con esta dirección, recibirás un enlace para restablecer la contraseña. Revisa también el correo no deseado.';

  @override
  String get emailSendFailed =>
      'No se ha podido enviar el correo. Inténtalo de nuevo.';

  @override
  String get accountLoadFailed =>
      'No se ha podido cargar la cuenta o terminar de borrar los datos. Inténtalo de nuevo.';

  @override
  String get verificationEmailSent =>
      'Hemos enviado un correo con un enlace. Revisa la bandeja de entrada y el correo no deseado.';

  @override
  String get emailNotVerified =>
      'La dirección aún no está confirmada. Abre el enlace del correo y reinténtalo.';

  @override
  String get signInFailed =>
      'No se ha podido iniciar sesión. Comprueba los datos y reinténtalo.';

  @override
  String get signOutFailed =>
      'No se ha podido cerrar sesión. Inténtalo de nuevo.';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountIdentity =>
      'Confirma tu identidad para eliminar la cuenta.';

  @override
  String get password => 'Contraseña';

  @override
  String get keepAccount => 'Conservar cuenta';

  @override
  String get deleteAccountAndData => 'Eliminar cuenta y datos';

  @override
  String get accountDeleted =>
      'Se han eliminado la cuenta y los datos. Cancela la suscripción por separado en Google Play.';

  @override
  String get accountDeleteIncomplete =>
      'No se ha podido completar la eliminación. Inténtalo de nuevo.';

  @override
  String get emailAccountMethod => ' (correo y contraseña)';

  @override
  String get finishDataCleanup => 'Actualizar cuenta y terminar la limpieza';

  @override
  String get accountNotConfigured => 'Las opciones de cuenta aparecerán aquí.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get emailVerified => 'Correo confirmado';

  @override
  String get checkInbox => 'Revisa tu correo';

  @override
  String get finishAccountLinkNotice =>
      'La dirección está confirmada. Falta conectar la cuenta Sedno. No necesitas abrir de nuevo el enlace del correo.';

  @override
  String get verifyEmailInstructions =>
      'Para terminar de crear la cuenta, abre el enlace del correo de Sedno. Revisa también el correo no deseado. Después vuelve y elige «Comprobar confirmación».';

  @override
  String get guestWhileVerifying =>
      'Mientras tanto puedes usar la aplicación sin cuenta.';

  @override
  String get finishSignIn => 'Completar inicio de sesión';

  @override
  String get checkVerification => 'Comprobar confirmación';

  @override
  String get resendEmail => 'Volver a enviar correo';

  @override
  String get signOutUseGuest => 'Cerrar sesión y usar sin cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get newAccount => 'Nueva cuenta';

  @override
  String get recoverAccess => 'Recuperar acceso';

  @override
  String get guestSignInNotice =>
      'Puedes usar la aplicación sin iniciar sesión.';

  @override
  String get signInGoogle => 'Iniciar sesión con Google';

  @override
  String get emailAddress => 'Correo electrónico';

  @override
  String get enterPassword => 'Introduce tu contraseña.';

  @override
  String get passwordMinLength => 'Usa al menos 6 caracteres.';

  @override
  String get repeatPassword => 'Repetir contraseña';

  @override
  String get enterRepeatedPassword => 'Repite tu contraseña.';

  @override
  String get passwordMismatch => 'Las contraseñas deben coincidir.';

  @override
  String get verificationEmailNotice =>
      'Enviaremos un correo con un enlace para confirmar la dirección.';

  @override
  String get passwordResetInstructions =>
      'Introduce el correo de tu cuenta. Enviaremos un enlace para cambiar la contraseña.';

  @override
  String get signInEmail => 'Iniciar sesión con correo';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get sendResetLink => 'Enviar enlace para restablecer contraseña';

  @override
  String get forgotPassword => 'He olvidado la contraseña';

  @override
  String get createAccountLink => '¿No tienes cuenta? Crea una';

  @override
  String get backToSignIn => 'Volver al inicio de sesión';

  @override
  String get testerAccess => 'Acceso de prueba';

  @override
  String get testerAllowance => 'Puedes procesar hasta 400 textos al día.';

  @override
  String get testerExpiryNotice =>
      'El acceso es gratuito y caduca automáticamente.';

  @override
  String get testerHasSubscription =>
      'También tienes una suscripción activa de Google Play.';

  @override
  String get testerExpired => 'El acceso de prueba ha caducado.';

  @override
  String get subscriptionStillActive =>
      'Tu suscripción de Google Play sigue ofreciendo un límite mayor.';

  @override
  String get freeLimitRestored =>
      'Se aplica el límite gratuito de 5 textos al día. El uso de hoy no cambia.';

  @override
  String get closeMenu => 'Cerrar menú';

  @override
  String get welcome => 'Te damos la bienvenida a Sedno';

  @override
  String get inApp => 'En la aplicación';

  @override
  String get accountCreatedEmailFailed =>
      'La cuenta se ha creado, pero no se ha podido enviar el correo. Intenta enviarlo de nuevo.';

  @override
  String get signInToVerify =>
      'Inicia sesión con correo para confirmar la dirección.';

  @override
  String get signInToCheckAccount =>
      'Vuelve a iniciar sesión para comprobar la cuenta.';

  @override
  String get weakPassword =>
      'La contraseña es demasiado débil. Usa al menos 6 caracteres.';

  @override
  String get checkEmailAddress =>
      'Comprueba el correo electrónico introducido.';

  @override
  String get emailAlreadyUsed =>
      'Esta dirección ya está en uso. Inicia sesión en la cuenta existente.';

  @override
  String get tooManyAttempts =>
      'Demasiados intentos. Espera un momento y reinténtalo.';

  @override
  String get checkInternet => 'Sin conexión. Comprueba Internet y reinténtalo.';

  @override
  String get chooseSameAccount => 'Elige la cuenta que quieres eliminar.';

  @override
  String get signInToDelete =>
      'Vuelve a iniciar sesión para eliminar la cuenta.';

  @override
  String get invalidCredentials =>
      'No se ha podido iniciar sesión. Comprueba el correo y la contraseña.';

  @override
  String get actionFailed =>
      'No se ha podido realizar la acción. Inténtalo de nuevo.';

  @override
  String get accountLinkFailed =>
      'No se ha podido conectar la cuenta Sedno. Comprueba la conexión y reinténtalo.';

  @override
  String get passwordToDelete =>
      'Introduce la contraseña para confirmar la eliminación.';

  @override
  String get finishLocalDeletion =>
      'Termina de borrar los datos de este dispositivo.';

  @override
  String get installationRejected =>
      'El servidor no ha podido verificar la instalación. Reinténtalo o instala Sedno desde Google Play.';

  @override
  String get sessionStartFailed =>
      'No se puede iniciar una sesión. Inténtalo de nuevo.';

  @override
  String get signInToLink => 'Vuelve a iniciar sesión para vincular la cuenta.';

  @override
  String get cannotLinkAccount =>
      'No se puede vincular la cuenta. Inténtalo de nuevo.';

  @override
  String get signInAgain => 'Vuelve a iniciar sesión.';

  @override
  String get sessionExpiredSignIn =>
      'La sesión ha caducado. Vuelve a iniciarla.';

  @override
  String get cannotDeleteAccount =>
      'No se puede eliminar la cuenta. Inténtalo de nuevo.';

  @override
  String get cannotSignOut => 'No se puede cerrar sesión. Inténtalo de nuevo.';

  @override
  String get correctionUnavailable => 'La corrección aún no está disponible.';

  @override
  String get simplificationUnavailable =>
      'La simplificación aún no está disponible.';

  @override
  String get requestTimeout => 'Se ha agotado el tiempo. Inténtalo de nuevo.';

  @override
  String get offline => 'Sin conexión a Internet. Inténtalo de nuevo.';

  @override
  String get sessionExpired =>
      'La sesión ha caducado. Comprueba la cuenta y reinténtalo.';

  @override
  String get quotaExhausted =>
      'Has agotado el límite de hoy. Consulta la hora de renovación.';

  @override
  String get serviceUnavailable =>
      'Servicio no disponible temporalmente. Inténtalo de nuevo.';

  @override
  String get correctionRejected =>
      'No se puede corregir este texto. Revísalo y reinténtalo.';

  @override
  String get simplificationRejected =>
      'No se puede simplificar este texto. Revísalo y reinténtalo.';

  @override
  String get correctionFailed =>
      'No se ha podido corregir el texto. Inténtalo de nuevo.';

  @override
  String get simplificationFailed =>
      'No se ha podido simplificar el texto. Inténtalo de nuevo.';

  @override
  String get checkConnection => 'Comprueba la conexión';

  @override
  String get quotaCheckFailed =>
      'No se puede comprobar el límite. Comprueba la conexión.';

  @override
  String get subscriptionInAccount =>
      'La suscripción y su precio están en Cuenta.';

  @override
  String get beforeCorrection => 'Antes de corregir el texto';

  @override
  String get beforeSimplification => 'Antes de simplificar el texto';

  @override
  String get acceptAndSend => 'Entendido, enviar';

  @override
  String get cameraUnavailable => 'La cámara estará disponible pronto.';

  @override
  String get aiWarning => 'La IA puede equivocarse';

  @override
  String get listeningNotice =>
      'Escuchando… Habla español. Termina tras 1,5 segundos de silencio o 60 segundos. El botón de parada cancela la grabación.';

  @override
  String get correctionSubmitted => 'Texto enviado para corregir.';

  @override
  String get simplificationSubmitted => 'Texto enviado para simplificar.';

  @override
  String get textForCorrection => 'Texto para corregir';

  @override
  String get textForSimplification => 'Texto para simplificar';

  @override
  String get inputHint => 'Escribe o pega un texto';

  @override
  String get switchToCorrection => 'Cambiar a corrección';

  @override
  String get switchToSimplification => 'Cambiar a simplificación';

  @override
  String get clearText => 'Borrar texto';

  @override
  String get stopPlayback => 'Detener lectura';

  @override
  String get readAloud => 'Leer en voz alta';

  @override
  String get cancelRecording => 'Cancelar grabación';

  @override
  String get simplifySpeech => 'Simplificar voz';

  @override
  String get cancel => 'Cancelar';

  @override
  String get history => 'Historial';

  @override
  String get account => 'Cuenta';

  @override
  String get start => 'Inicio';

  @override
  String get contact => 'Contacto';

  @override
  String get close => 'Cerrar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get correct => 'Corregir';

  @override
  String get correctHeading => 'corregir texto';

  @override
  String get correcting => 'Corrigiendo…';

  @override
  String get simplifying => 'Simplificando…';

  @override
  String get reading => 'Leyendo…';

  @override
  String get camera => 'Cámara';

  @override
  String get preparing => 'Preparando…';

  @override
  String get subscription => 'Suscripción';

  @override
  String get yesterday => 'Ayer';

  @override
  String get signedIn => 'Sesión iniciada.';

  @override
  String get googleAccountMethod => ' (cuenta de Google)';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del teléfono';

  @override
  String get polish => 'Polaco';

  @override
  String get english => 'Inglés (Reino Unido)';

  @override
  String get languageNotice =>
      'El idioma se aplica a menús, simplificación, corrección y voz. Elige el idioma del texto. Sedno no traduce textos.';

  @override
  String get languageSaveFailed =>
      'No se ha podido guardar el idioma. Inténtalo de nuevo.';

  @override
  String resetDaily(String time) {
    return 'El límite se renueva cada día a las $time.';
  }

  @override
  String resetAbout(String time) {
    return 'El límite se renueva cada día a las $time (00:00 UTC).';
  }

  @override
  String resetAt(String time) {
    return 'El límite se renueva a las $time.';
  }

  @override
  String get quotaUsed => 'Has agotado el límite de hoy.';

  @override
  String get quotaOneSimplification => 'Queda 1 simplificación.';

  @override
  String get quotaOneUse => 'Queda 1 uso de IA.';

  @override
  String get quotaUsedDialog => 'Has agotado el límite diario.';

  @override
  String resetWithRemaining(String time, String remaining) {
    return 'El límite se renueva a las $time ($remaining).';
  }

  @override
  String timeRemaining(String hours, String minutes) {
    return 'dentro de $hours h y $minutes min';
  }

  @override
  String monthlyPrice(String price) {
    return '$price al mes';
  }

  @override
  String historyExpires(String date) {
    return 'Se borrará el $date.';
  }

  @override
  String deleteSavedText(String date) {
    return 'Borrar texto guardado el $date';
  }

  @override
  String contactAddress(String email) {
    return 'Contacto: $email';
  }

  @override
  String signedInAs(String email, String method) {
    return 'Sesión iniciada como $email$method';
  }

  @override
  String accountEmail(String email) {
    return 'Correo electrónico: $email';
  }

  @override
  String emailToVerify(String email) {
    return 'Dirección por confirmar: $email';
  }

  @override
  String resendAfter(String seconds) {
    return 'Volver a enviar en $seconds s';
  }

  @override
  String testerUntil(String date) {
    return 'Acceso de prueba hasta $date (hora local).';
  }

  @override
  String cropPosition(String horizontal, String vertical) {
    return 'Horizontal $horizontal %, vertical $vertical %';
  }

  @override
  String welcomeName(String name) {
    return 'Te damos la bienvenida a $name';
  }

  @override
  String policyVersion(String date) {
    return 'Versión: $date';
  }

  @override
  String get speechModelDownloading =>
      'Se está descargando el modelo de voz. Inténtalo más tarde.';

  @override
  String get speechLanguageUnsupported =>
      'El motor de voz de este teléfono no ofrece dictado local en este idioma. Puedes escribir o usar la cámara.';

  @override
  String get signInApple => 'Iniciar sesión con Apple';

  @override
  String get appleAccountMethod => 'Apple';

  @override
  String get signInCancelled => 'Inicio de sesión cancelado.';

  @override
  String get accountMethodConflict =>
      'Esta cuenta usa otro método de acceso. Usa tu método habitual.';

  @override
  String get localSpeechUnavailable =>
      'El reconocimiento de voz local no está disponible para este idioma en este dispositivo.';

  @override
  String get localSpeechModelMissing =>
      'Instala el modelo de voz local en los ajustes del dispositivo.';

  @override
  String get deviceFeatureUnavailable =>
      'Esta función no está disponible en este dispositivo.';

  @override
  String get subscriptionOtherStore =>
      'Esta suscripción se compró en otra tienda. Gestiónala en la tienda donde la compraste.';

  @override
  String get storeOpenFailed =>
      'No se pudo abrir la configuración de la suscripción. Inténtalo de nuevo.';

  @override
  String get appleManageSubscriptionNotice =>
      'Para cambiar el pago o cancelar la suscripción, abre App Store.';

  @override
  String get appleManageSubscription => 'Gestionar suscripción en App Store';

  @override
  String get appleSubscriptionCancelNotice =>
      'Puedes cancelarla cuando quieras en App Store.';

  @override
  String get appleAccountDeleted =>
      'Se han eliminado la cuenta y los datos. Cancela la suscripción por separado en App Store.';

  @override
  String get appleTesterHasSubscription =>
      'También tienes una suscripción activa de App Store.';

  @override
  String get appleSubscriptionStillActive =>
      'Tu suscripción de App Store sigue ofreciendo un límite mayor.';

  @override
  String get appleInstallationRejected =>
      'El servidor no ha podido verificar la instalación. Reinténtalo o instala Sedno desde App Store.';

  @override
  String get appleSubscriptionPriceNotice =>
      'Puedes ver el precio en Cuenta y en App Store.';

  @override
  String get privacyIosSupplementTitle => 'Información adicional para iPhone';

  @override
  String get privacyIosSupplementBody =>
      'Las referencias siguientes a Android, Google Play y Play Integrity se aplican solo a Android. En iPhone puedes iniciar sesión con Apple y ocultar tu correo electrónico. Firebase también gestiona el acceso. Apple cobra las suscripciones compradas en el App Store; Sedno no recibe datos de tarjeta. Eliminar la cuenta no cancela la suscripción.\n\nApp Attest verifica la autenticidad de la aplicación sin enviar a Apple textos, resultados ni fotos. El servidor guarda datos seudónimos de instalación y clave pública. Los desafíos son válidos durante 5 minutos y las claves durante 90 días desde la última verificación de sesión correcta. Las notificaciones de compra se conservan 30 días. Una tarea del servidor elimina los registros caducados. Los metadatos de compra se conservan hasta eliminar la cuenta.\n\nEl historial está cifrado, es local, queda excluido de las copias de seguridad y caduca a los 7 días. Las fotos y el audio permanecen en el dispositivo. El dictado y la lectura funcionan solo localmente, si el dispositivo y el idioma lo permiten. Envías el texto reconocido a OpenAI mediante Sedno tras aceptar el aviso sobre IA.\n\nLa información restante, incluidos responsable, fines, bases jurídicas y prácticas de OpenAI, también se aplica a iPhone. Privacidad de Apple: https://www.apple.com/legal/privacy/';

  @override
  String get linkApple => 'Vincular cuenta de Apple';

  @override
  String get confirmAccountLink =>
      'Confirma de nuevo tu cuenta actual. Después elige una cuenta de Apple para acceder a la misma cuenta de Sedno.';

  @override
  String get passwordToLink =>
      'Introduce la contraseña de tu cuenta actual para vincularla con Apple.';

  @override
  String get linkGoogle => 'Vincular cuenta de Google';

  @override
  String get confirmGoogleAccountLink =>
      'Confirma de nuevo tu cuenta actual. Después elige una cuenta de Google para iniciar sesión en la misma cuenta de Sedno.';

  @override
  String get passwordToLinkGoogle =>
      'Introduce la contraseña de tu cuenta actual para vincular Google.';
}
