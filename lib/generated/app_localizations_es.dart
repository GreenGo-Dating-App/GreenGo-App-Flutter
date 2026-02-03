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

  @override
  String get authErrorUserNotFound =>
      'No se encontró una cuenta con este correo electrónico. Por favor verifica tu correo o regístrate.';

  @override
  String get authErrorWrongPassword =>
      'Contraseña incorrecta. Por favor intenta de nuevo.';

  @override
  String get authErrorInvalidEmail =>
      'Por favor ingresa una dirección de correo electrónico válida.';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Ya existe una cuenta con este correo electrónico.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es muy débil. Por favor usa una contraseña más fuerte.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Por favor intenta más tarde.';

  @override
  String get authErrorNetworkError =>
      'Error de red. Por favor verifica tu conexión a internet.';

  @override
  String get authErrorGeneric =>
      'Ocurrió un error. Por favor intenta de nuevo.';

  @override
  String get authErrorInvalidCredentials =>
      'Correo electrónico o contraseña inválidos. Por favor intenta de nuevo.';

  @override
  String get accountCreatedSuccess =>
      '¡Cuenta creada! Por favor revisa tu correo electrónico para verificar tu cuenta.';

  @override
  String get levelUp => '¡SUBISTE DE NIVEL!';

  @override
  String get levelUpCongratulations =>
      '¡Felicitaciones por alcanzar un nuevo nivel!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Alcanzaste el Nivel $level';
  }

  @override
  String get levelUpRewards => 'RECOMPENSAS';

  @override
  String get levelUpContinue => 'Continuar';

  @override
  String get levelUpVIPUnlocked => '¡Estado VIP Desbloqueado!';

  @override
  String get chatSafetyTitle => 'Chatea de Forma Segura';

  @override
  String get chatSafetySubtitle =>
      'Tu seguridad es nuestra prioridad. Ten en cuenta estos consejos.';

  @override
  String get chatSafetyTip1Title => 'Mantén la Info Personal Privada';

  @override
  String get chatSafetyTip1Description =>
      'No compartas tu dirección, número de teléfono o información financiera.';

  @override
  String get chatSafetyTip2Title => 'Cuidado con Solicitudes de Dinero';

  @override
  String get chatSafetyTip2Description =>
      'Nunca envíes dinero a alguien que no hayas conocido en persona.';

  @override
  String get chatSafetyTip3Title => 'Reúnete en Lugares Públicos';

  @override
  String get chatSafetyTip3Description =>
      'Para primeros encuentros, elige siempre un lugar público y bien iluminado.';

  @override
  String get chatSafetyTip4Title => 'Confía en Tu Instinto';

  @override
  String get chatSafetyTip4Description =>
      'Si algo no se siente bien, confía en tu instinto y termina la conversación.';

  @override
  String get chatSafetyTip5Title => 'Reporta Comportamiento Sospechoso';

  @override
  String get chatSafetyTip5Description =>
      'Usa la función de reporte si alguien te hace sentir incómodo.';

  @override
  String get chatSafetyGotIt => 'Entendido';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get tourNext => 'Siguiente';

  @override
  String get tourDone => 'Listo';

  @override
  String get tourDiscoveryTitle => 'Descubre Matches';

  @override
  String get tourDiscoveryDescription =>
      'Desliza perfiles para encontrar tu match perfecto. Desliza a la derecha si te interesa, a la izquierda para pasar.';

  @override
  String get tourMatchesTitle => 'Tus Matches';

  @override
  String get tourMatchesDescription =>
      '¡Ve a todos los que también les gustaste! Inicia conversaciones con tus matches mutuos.';

  @override
  String get tourMessagesTitle => 'Mensajes';

  @override
  String get tourMessagesDescription =>
      'Chatea con tus matches aquí. Envía mensajes, fotos y notas de voz para conectar.';

  @override
  String get tourShopTitle => 'Tienda y Monedas';

  @override
  String get tourShopDescription =>
      'Obtén monedas y funciones premium para mejorar tu experiencia.';

  @override
  String get tourProgressTitle => 'Sigue Tu Progreso';

  @override
  String get tourProgressDescription =>
      '¡Gana insignias, completa desafíos y sube en la clasificación!';

  @override
  String get tourProfileTitle => 'Tu Perfil';

  @override
  String get tourProfileDescription =>
      'Personaliza tu perfil, administra configuraciones y controla tu privacidad.';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressOverview => 'Resumen';

  @override
  String get progressAchievements => 'Insignias';

  @override
  String get progressChallenges => 'Desafíos';

  @override
  String get progressLeaderboard => 'Clasificación';

  @override
  String progressLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String get progressBadges => 'Insignias';

  @override
  String get progressCompleted => 'Completados';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressRecentAchievements => 'Logros Recientes';

  @override
  String get progressTodaysChallenges => 'Desafíos de Hoy';

  @override
  String get progressSeeAll => 'Ver Todo';

  @override
  String get progressViewJourney => 'Ver Tu Viaje';

  @override
  String get progressJourneyDescription =>
      'Ve tu viaje completo de citas y logros';

  @override
  String get nickname => 'Apodo';

  @override
  String get editNickname => 'Editar Apodo';

  @override
  String get nicknameUpdatedSuccess => 'Apodo actualizado con éxito';

  @override
  String get nicknameAlreadyTaken => 'Este apodo ya está en uso';

  @override
  String get nicknameCheckError => 'Error al verificar disponibilidad';

  @override
  String nicknameInfoText(String nickname) {
    return 'Tu apodo es único y puede usarse para encontrarte. Otros pueden buscarte usando @$nickname';
  }

  @override
  String get enterNickname => 'Ingresa apodo';

  @override
  String get nicknameRequirements =>
      '3-20 caracteres. Solo letras, números y guiones bajos.';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get refresh => 'Actualizar';

  @override
  String get nicknameRules => 'Reglas del Apodo';

  @override
  String get nicknameMustBe3To20Chars => 'Debe tener 3-20 caracteres';

  @override
  String get nicknameStartWithLetter => 'Comenzar con una letra';

  @override
  String get nicknameOnlyAlphanumeric => 'Solo letras, números y guiones bajos';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Sin guiones bajos consecutivos';

  @override
  String get nicknameNoReservedWords => 'No puede contener palabras reservadas';

  @override
  String get setYourUniqueNickname => 'Establece tu apodo único';

  @override
  String get searchByNickname => 'Buscar por Apodo';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'No se encontró perfil con @$nickname';
  }

  @override
  String get thatsYourOwnProfile => '¡Ese es tu propio perfil!';

  @override
  String get errorSearchingTryAgain => 'Error al buscar. Inténtalo de nuevo.';

  @override
  String get enterNicknameToFind =>
      'Ingresa un apodo para encontrar a alguien directamente';

  @override
  String get view => 'Ver';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado con éxito';

  @override
  String get unableToLoadProfile => 'No se puede cargar el perfil';

  @override
  String get viewMyProfile => 'Ver Mi Perfil';

  @override
  String get seeHowOthersViewProfile => 'Ve cómo otros ven tu perfil';

  @override
  String photosCount(int count) {
    return '$count/6 fotos';
  }

  @override
  String get basicInformation => 'Información Básica';

  @override
  String get aboutMe => 'Sobre Mí';

  @override
  String get addBio => 'Agregar biografía';

  @override
  String interestsCount(int count) {
    return '$count intereses';
  }

  @override
  String get locationAndLanguages => 'Ubicación e Idiomas';

  @override
  String get voiceRecorded => 'Voz grabada';

  @override
  String get noVoiceRecording => 'Sin grabación de voz';

  @override
  String get socialProfiles => 'Perfiles Sociales';

  @override
  String get noSocialProfilesLinked => 'Sin perfiles sociales vinculados';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'es',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count perfil$_temp0 vinculado$_temp1';
  }

  @override
  String get appLanguage => 'Idioma de la App';

  @override
  String get rewardsAndProgress => 'Recompensas y Progreso';

  @override
  String get myProgress => 'Mi Progreso';

  @override
  String get viewBadgesAchievementsLevel => 'Ver insignias, logros y nivel';

  @override
  String get admin => 'Admin';

  @override
  String get verificationPanel => 'Panel de Verificación';

  @override
  String get reviewUserVerifications => 'Revisar verificaciones de usuarios';

  @override
  String get reportsPanel => 'Panel de Reportes';

  @override
  String get reviewReportedMessages =>
      'Revisar mensajes reportados y gestionar cuentas';

  @override
  String get membershipPanel => 'Panel de Membresías';

  @override
  String get manageCouponsTiersRules => 'Gestionar cupones, niveles y reglas';

  @override
  String get exportMyDataGDPR => 'Exportar Mis Datos (GDPR)';

  @override
  String get restartAppWizard => 'Reiniciar Asistente de la App';

  @override
  String languageChangedTo(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get deleteAccountConfirmation =>
      '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y todos tus datos serán eliminados permanentemente.';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Las cuentas de admin no pueden ser eliminadas';

  @override
  String get exportingYourData => 'Exportando tus datos...';

  @override
  String get dataExportSentToEmail =>
      'Exportación de datos enviada a tu correo';

  @override
  String get restartWizardDialogContent =>
      'Esto reiniciará el asistente de configuración. Podrás actualizar la información de tu perfil paso a paso. Tus datos actuales serán preservados.';

  @override
  String get restartWizard => 'Reiniciar Asistente';

  @override
  String get logOutConfirmation =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get editVoiceComingSoon => 'Editar voz próximamente';

  @override
  String get logOut => 'Cerrar Sesión';

  @override
  String get noMatchesYet => 'Sin coincidencias aún';

  @override
  String get startSwipingToFindMatches =>
      '¡Comienza a deslizar para encontrar tus coincidencias!';

  @override
  String get searchByNameOrNickname => 'Buscar por nombre o @apodo';

  @override
  String matchesCount(int count) {
    return '$count coincidencias';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered de $total coincidencias';
  }

  @override
  String get noMatchesFound => 'No se encontraron coincidencias';

  @override
  String get tryDifferentSearchOrFilter =>
      'Prueba una búsqueda o filtro diferente';

  @override
  String get clearFilters => 'Limpiar Filtros';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterNew => 'Nuevos';

  @override
  String get filterMessaged => 'Con Mensajes';

  @override
  String get about => 'Acerca de';

  @override
  String get lookingFor => 'Busca';

  @override
  String get details => 'Detalles';

  @override
  String get height => 'Altura';

  @override
  String get education => 'Educación';

  @override
  String get occupation => 'Ocupación';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Hiciste match con $name el $date';
  }

  @override
  String chatWithName(String name) {
    return 'Chatear con $name';
  }

  @override
  String get longTermRelationship => 'Relación a largo plazo';

  @override
  String get shortTermRelationship => 'Relación a corto plazo';

  @override
  String get friendship => 'Amistad';

  @override
  String get casualDating => 'Citas casuales';

  @override
  String get today => 'hoy';

  @override
  String get yesterday => 'ayer';

  @override
  String daysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String get lvl => 'NIV';

  @override
  String get xp => 'XP';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% al Nivel $level';
  }

  @override
  String get achievements => 'Logros';

  @override
  String get badges => 'Insignias';

  @override
  String get challenges => 'Desafíos';

  @override
  String get myBadges => 'Mis Insignias';

  @override
  String get noBadgesEarnedYet => 'Sin insignias obtenidas';

  @override
  String get completeAchievementsToEarnBadges =>
      '¡Completa logros para obtener insignias!';

  @override
  String moreAchievements(int count) {
    return '+$count más logros';
  }

  @override
  String get levelTitleLegend => 'Leyenda';

  @override
  String get levelTitleMaster => 'Maestro';

  @override
  String get levelTitleExpert => 'Experto';

  @override
  String get levelTitleVeteran => 'Veterano';

  @override
  String get levelTitleExplorer => 'Explorador';

  @override
  String get levelTitleEnthusiast => 'Entusiasta';

  @override
  String get levelTitleNewcomer => 'Novato';

  @override
  String notificationNewLike(String nickname) {
    return 'Recibiste un me gusta de @$nickname';
  }

  @override
  String notificationSuperLike(String nickname) {
    return 'Recibiste un super me gusta de @$nickname';
  }

  @override
  String notificationNewMatch(String nickname) {
    return '¡Es un Match! Hiciste match con @$nickname. Comienza a chatear ahora.';
  }

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname inició una conversación contigo.';
  }

  @override
  String notificationNewMessage(String nickname) {
    return 'Nuevo mensaje de @$nickname';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Compraste exitosamente $amount monedas.';
  }

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Logro Desbloqueado: $name';
  }

  @override
  String get voiceStandOutWithYourVoice => '¡Destaca con tu voz!';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Graba una breve presentación de $seconds segundos para que otros escuchen tu personalidad.';
  }

  @override
  String get voiceRecordingTips => 'Consejos de Grabación';

  @override
  String get voiceTipFindQuietPlace => 'Encuentra un lugar tranquilo';

  @override
  String get voiceTipBeYourself => 'Sé tú mismo y natural';

  @override
  String get voiceTipShareWhatMakesYouUnique => 'Comparte lo que te hace único';

  @override
  String get voiceTipKeepItShort => 'Mantenlo breve y dulce';

  @override
  String get voiceTapToRecord => 'Toca para grabar';

  @override
  String get voiceRecordingSaved => 'Grabación guardada';

  @override
  String get voiceRecordAgain => 'Grabar de Nuevo';

  @override
  String get voiceUploading => 'Subiendo...';

  @override
  String get voiceIntroSaved => 'Presentación de voz guardada';

  @override
  String get voiceUploadFailed => 'Error al subir la grabación de voz';

  @override
  String get voiceDeleteRecording => 'Eliminar Grabación';

  @override
  String get voiceDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar tu presentación de voz?';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Se requiere permiso del micrófono';
}
