// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubre Tu Pareja Perfecta';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu Contraseña?';

  @override
  String get resetPassword => 'Restablecer Contraseña';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get signUp => 'Regístrate';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

  @override
  String get orContinueWith => 'O continúa con';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get joinMessage =>
      'Únete a GreenGoChat y encuentra tu pareja perfecta';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get emailInvalid => 'Por favor ingresa un correo electrónico válido';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordWeak =>
      'La contraseña debe contener mayúsculas, minúsculas, números y caracteres especiales';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordMustContainUppercase =>
      'La contraseña debe contener al menos una letra mayúscula';

  @override
  String get passwordMustContainLowercase =>
      'La contraseña debe contener al menos una letra minúscula';

  @override
  String get passwordMustContainNumber =>
      'La contraseña debe contener al menos un número';

  @override
  String get passwordMustContainSpecialChar =>
      'La contraseña debe contener al menos un carácter especial';

  @override
  String get passwordStrengthVeryWeak => 'Muy Débil';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthFair => 'Regular';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get passwordStrengthVeryStrong => 'Muy Fuerte';

  @override
  String get passwordMustContain => 'La contraseña debe contener:';

  @override
  String get atLeast8Characters => 'Al menos 8 caracteres';

  @override
  String get uppercaseLowercase => 'Letras mayúsculas y minúsculas';

  @override
  String get atLeastOneNumber => 'Al menos un número';

  @override
  String get atLeastOneSpecialChar => 'Al menos un carácter especial';

  @override
  String get confirmPasswordRequired => 'Por favor confirme su contraseña';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get completeProfile => 'Completa Tu Perfil';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get dateOfBirth => 'Fecha de Nacimiento';

  @override
  String get gender => 'Género';

  @override
  String get bio => 'Biografía';

  @override
  String get interests => 'Intereses';

  @override
  String get photos => 'Fotos';

  @override
  String get addPhoto => 'Añadir Foto';

  @override
  String get uploadPhoto => 'Subir Foto';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get chooseFromGallery => 'Elegir de la Galería';

  @override
  String get location => 'Ubicación';

  @override
  String get language => 'Idioma';

  @override
  String get voiceIntro => 'Presentación de Voz';

  @override
  String get recordVoice => 'Grabar Voz';

  @override
  String get welcome => 'Bienvenido a GreenGoChat';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get finish => 'Finalizar';

  @override
  String get step => 'Paso';

  @override
  String get stepOf => 'de';

  @override
  String get discover => 'Descubrir';

  @override
  String get matches => 'Coincidencias';

  @override
  String get likes => 'Me Gusta';

  @override
  String get superLikes => 'Super Me Gusta';

  @override
  String get filters => 'Filtros';

  @override
  String get ageRange => 'Rango de Edad';

  @override
  String get distance => 'Distancia';

  @override
  String get noMoreProfiles => 'No hay más perfiles para mostrar';

  @override
  String get itsAMatch => '¡Es una Coincidencia!';

  @override
  String youAndMatched(String name) {
    return 'Tú y $name se gustaron mutuamente';
  }

  @override
  String get sendMessage => 'Enviar Mensaje';

  @override
  String get keepSwiping => 'Seguir Deslizando';

  @override
  String get messages => 'Mensajes';

  @override
  String get typeMessage => 'Escribe un mensaje...';

  @override
  String get noMessages => 'No hay mensajes aún';

  @override
  String get startConversation => 'Iniciar una conversación';

  @override
  String get settings => 'Configuración';

  @override
  String get accountSettings => 'Configuración de Cuenta';

  @override
  String get notificationSettings => 'Configuración de Notificaciones';

  @override
  String get privacySettings => 'Configuración de Privacidad';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get upgradeToPremium => 'Actualizar a Premium';

  @override
  String get basic => 'Básico';

  @override
  String get silver => 'Plata';

  @override
  String get gold => 'Oro';

  @override
  String get subscribe => 'Suscribirse';

  @override
  String get perMonth => '/mes';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get tryAgain => 'Intentar de Nuevo';

  @override
  String get noInternetConnection => 'Sin conexión a internet';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Listo';

  @override
  String get loading => 'Cargando...';

  @override
  String get ok => 'OK';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get loginWithBiometrics => 'Iniciar Sesión con Biometría';

  @override
  String get consentRequired => 'Consentimientos Obligatorios';

  @override
  String get optionalConsents => 'Consentimientos Opcionales';

  @override
  String get acceptPrivacyPolicy =>
      'He leído y acepto la Política de Privacidad';

  @override
  String get acceptTermsAndConditions =>
      'He leído y acepto los Términos y Condiciones';

  @override
  String get acceptProfiling =>
      'Consiento el perfilado para recomendaciones personalizadas';

  @override
  String get acceptThirdPartyData =>
      'Consiento compartir mis datos con terceros';

  @override
  String get readPrivacyPolicy => 'Leer Política de Privacidad';

  @override
  String get readTermsAndConditions => 'Leer Términos y Condiciones';

  @override
  String get profilingDescription =>
      'Permitir analizar tus preferencias para proporcionar mejores sugerencias de coincidencia';

  @override
  String get thirdPartyDataDescription =>
      'Permitir compartir datos anonimizados con socios para mejorar el servicio';

  @override
  String get consentRequiredError =>
      'Debes aceptar la Política de Privacidad y los Términos y Condiciones para registrarte';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get termsAndConditions => 'Términos y Condiciones';

  @override
  String get errorLoadingDocument => 'Error loading document';

  @override
  String get retry => 'Retry';

  @override
  String get documentNotAvailable => 'Document not available';

  @override
  String get documentNotAvailableDescription =>
      'This document is not available in your language yet.';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get verificationRequired => 'Verificación de Identidad Requerida';

  @override
  String get verificationTitle => 'Verifica Tu Identidad';

  @override
  String get verificationDescription =>
      'Para garantizar la seguridad de nuestra comunidad, requerimos que todos los usuarios verifiquen su identidad. Toma una foto de ti mismo sosteniendo tu documento de identidad.';

  @override
  String get verificationInstructions =>
      'Sostén tu documento de identidad (pasaporte, licencia de conducir o DNI) junto a tu rostro y toma una foto clara.';

  @override
  String get verificationTips => 'Consejos para una verificación exitosa:';

  @override
  String get verificationTip1 => 'Asegúrate de tener buena iluminación';

  @override
  String get verificationTip2 =>
      'Tu rostro y el documento deben ser claramente visibles';

  @override
  String get verificationTip3 =>
      'Sostén el documento junto a tu rostro, sin cubrirlo';

  @override
  String get verificationTip4 => 'El texto del documento debe ser legible';

  @override
  String get takeVerificationPhoto => 'Tomar Foto de Verificación';

  @override
  String get retakePhoto => 'Tomar de Nuevo';

  @override
  String get submitVerification => 'Enviar para Verificación';

  @override
  String get verificationPending => 'Verificación Pendiente';

  @override
  String get verificationPendingMessage =>
      'Tu cuenta está siendo verificada. Esto generalmente toma 24-48 horas. Serás notificado cuando la revisión esté completa.';

  @override
  String get verificationApproved => 'Verificación Aprobada';

  @override
  String get verificationApprovedMessage =>
      'Tu identidad ha sido verificada. Ahora tienes acceso completo a la app.';

  @override
  String get verificationRejected => 'Verificación Rechazada';

  @override
  String get verificationRejectedMessage =>
      'Tu verificación fue rechazada. Por favor envía una nueva foto.';

  @override
  String get verificationNeedsResubmission => 'Se Requiere Mejor Foto';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Necesitamos una foto más clara para la verificación. Por favor reenvía.';

  @override
  String rejectionReason(String reason) {
    return 'Razón: $reason';
  }

  @override
  String get accountUnderReview => 'Cuenta en Revisión';

  @override
  String get cannotAccessFeature =>
      'Esta función está disponible después de que tu cuenta sea verificada.';

  @override
  String get waitingForVerification => 'Esperando verificación...';

  @override
  String get verifyNow => 'Verificar Ahora';

  @override
  String get skipForNow => 'Saltar por Ahora';

  @override
  String get verificationSkipWarning =>
      'Puedes explorar la app, pero no podrás chatear o ver otros perfiles hasta que estés verificado.';

  @override
  String get adminPanel => 'Panel de Admin';

  @override
  String get pendingVerifications => 'Verificaciones Pendientes';

  @override
  String get verificationHistory => 'Historial de Verificaciones';

  @override
  String get approveVerification => 'Aprobar';

  @override
  String get rejectVerification => 'Rechazar';

  @override
  String get requestBetterPhoto => 'Solicitar Mejor Foto';

  @override
  String get enterRejectionReason => 'Ingresa la razón del rechazo';

  @override
  String get rejectionReasonRequired =>
      'Por favor ingresa una razón para el rechazo';

  @override
  String get verificationApprovedSuccess =>
      'Verificación aprobada exitosamente';

  @override
  String get verificationRejectedSuccess => 'Verificación rechazada';

  @override
  String get betterPhotoRequested => 'Mejor foto solicitada';

  @override
  String get noPhotoSubmitted => 'Ninguna foto enviada';

  @override
  String submittedOn(String date) {
    return 'Enviado el $date';
  }

  @override
  String reviewedBy(String admin) {
    return 'Revisado por $admin';
  }

  @override
  String get noPendingVerifications => 'No hay verificaciones pendientes';

  @override
  String get platinum => 'Platino';

  @override
  String get waitingTitle => '¡Gracias por Registrarte!';

  @override
  String get waitingSubtitle => 'Tu cuenta ha sido creada exitosamente';

  @override
  String get waitingMessagePending =>
      'Tu cuenta está pendiente de aprobación por nuestro equipo. Te notificaremos una vez que tu cuenta haya sido revisada.';

  @override
  String get waitingMessageApproved =>
      '¡Buenas noticias! Tu cuenta ha sido aprobada. Podrás acceder a GreenGoChat en la fecha indicada a continuación.';

  @override
  String get waitingMessageRejected =>
      'Lamentablemente, tu cuenta no pudo ser aprobada en este momento. Por favor contacta a soporte para más información.';

  @override
  String get waitingAccessDateTitle => 'Tu Fecha de Acceso';

  @override
  String waitingAccessDatePremium(String tier) {
    return '¡Como miembro $tier, tienes acceso anticipado el 1 de marzo de 2026!';
  }

  @override
  String get waitingAccessDateBasic =>
      'Tu acceso comenzará el 15 de marzo de 2026';

  @override
  String get waitingCountdownTitle => 'Cuenta Regresiva para el Lanzamiento';

  @override
  String waitingDaysRemaining(int days) {
    return '$days días';
  }

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours horas';
  }

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutos';
  }

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get accountPendingApproval => 'Cuenta Pendiente de Aprobación';

  @override
  String get accountApproved => 'Cuenta Aprobada';

  @override
  String get accountRejected => 'Cuenta Rechazada';

  @override
  String get upgradeForEarlyAccess =>
      '¡Actualiza a Plata, Oro o Platino para acceso anticipado el 1 de marzo de 2026!';

  @override
  String get waitingStayTuned =>
      '¡Mantente atento! Te notificaremos cuando sea hora de comenzar a conectar.';

  @override
  String get waitingNotificationEnabled =>
      'Notificaciones habilitadas - ¡te avisaremos cuando puedas acceder a la app!';

  @override
  String get enableNotifications => 'Habilitar Notificaciones';

  @override
  String get contactSupport => 'Contactar Soporte';

  @override
  String get waitingCountdownSubtitle =>
      '¡Gracias por registrarte! GreenGo Chat se lanzará pronto. Prepárate para una experiencia exclusiva.';

  @override
  String get waitingCountdownLabel => 'Cuenta regresiva para el lanzamiento';

  @override
  String get waitingEarlyAccessMember => 'Miembro de Acceso Anticipado';

  @override
  String get waitingExclusiveAccess => 'Tu fecha de acceso exclusivo';

  @override
  String get waitingProfileUnderReview => 'Perfil en revisión';

  @override
  String get waitingReviewMessage =>
      '¡La app ya está activa! Nuestro equipo está revisando tu perfil para garantizar la mejor experiencia para nuestra comunidad. Esto suele tardar 24-48 horas.';

  @override
  String get waitingStepRegistration => 'Registro completado';

  @override
  String get waitingStepReview => 'Revisión de perfil en progreso';

  @override
  String get waitingStepActivation => 'Activación de cuenta';

  @override
  String get waitingEnableNotificationsTitle => 'Mantente actualizado';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Activa las notificaciones para ser el primero en saber cuándo puedes acceder a la app.';

  @override
  String get waitingThankYouRegistration => '¡Gracias por registrarte!';

  @override
  String get days => 'Días';

  @override
  String get hours => 'Horas';

  @override
  String get minutes => 'Minutos';

  @override
  String get seconds => 'Segundos';

  @override
  String get vipPlatinumMember => 'PLATINO VIP';

  @override
  String get vipGoldMember => 'MIEMBRO ORO';

  @override
  String get vipSilverMember => 'MIEMBRO PLATA';

  @override
  String get vipPremiumBenefitsActive => 'Beneficios Premium Activos';
}
