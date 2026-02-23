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
      'No se encontró una cuenta con este correo o nickname. Verifica e inténtalo de nuevo, o regístrate.';

  @override
  String get authErrorWrongPassword =>
      'Contraseña incorrecta. Inténtalo de nuevo.';

  @override
  String get authErrorInvalidEmail =>
      'Por favor ingresa un correo electrónico válido.';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Ya existe una cuenta con este correo.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es muy débil. Usa una contraseña más fuerte.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get authErrorNetworkError =>
      'Sin conexión a internet. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get authErrorGeneric => 'Ocurrió un error. Inténtalo de nuevo.';

  @override
  String get authErrorInvalidCredentials =>
      'Correo/nickname o contraseña incorrectos. Verifica tus credenciales e inténtalo de nuevo.';

  @override
  String get connectionErrorTitle => 'Sin Conexión a Internet';

  @override
  String get connectionErrorMessage =>
      'Verifica tu conexión a internet e inténtalo de nuevo.';

  @override
  String get serverUnavailableTitle => 'Servidor No Disponible';

  @override
  String get serverUnavailableMessage =>
      'Nuestros servidores están temporalmente no disponibles. Inténtalo en unos momentos.';

  @override
  String get authenticationErrorTitle => 'Inicio de Sesión Fallido';

  @override
  String get dismiss => 'Cerrar';

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

  @override
  String get listenMe => '¡Escúchame!';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get changePasswordDescription =>
      'Por seguridad, verifica tu identidad antes de cambiar tu contraseña.';

  @override
  String get changePasswordCurrent => 'Contraseña Actual';

  @override
  String get changePasswordNew => 'Nueva Contraseña';

  @override
  String get changePasswordConfirm => 'Confirmar Nueva Contraseña';

  @override
  String get changePasswordEmailHint => 'Tu correo electrónico';

  @override
  String get changePasswordEmailConfirm =>
      'Confirma tu dirección de correo electrónico';

  @override
  String get changePasswordEmailMismatch =>
      'El correo no coincide con tu cuenta';

  @override
  String get changePasswordSuccess => 'Contraseña cambiada exitosamente';

  @override
  String get changePasswordWrongCurrent => 'La contraseña actual es incorrecta';

  @override
  String get changePasswordReauthRequired =>
      'Por favor cierra sesión e inicia sesión nuevamente antes de cambiar tu contraseña';

  @override
  String get changePasswordSubtitle => 'Actualiza la contraseña de tu cuenta';

  @override
  String get shop => 'Tienda';

  @override
  String get progress => 'Progreso';

  @override
  String get learn => 'Aprender';

  @override
  String get exitApp => '¿Salir de la App?';

  @override
  String get exitAppConfirmation =>
      '¿Estás seguro de que quieres salir de GreenGo?';

  @override
  String get exit => 'Salir';

  @override
  String get letsChat => '¡Hablemos!';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get helpAndSupport => 'Ayuda y Soporte';

  @override
  String get supportCenter => 'Centro de Soporte';

  @override
  String get supportCenterSubtitle =>
      'Obtener ayuda, reportar problemas, contáctanos';

  @override
  String get editInterests => 'Editar Intereses';

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max intereses seleccionados';
  }

  @override
  String selectAtLeastInterests(int count) {
    return 'Selecciona al menos $count intereses';
  }

  @override
  String get greatInterestsHelp =>
      '¡Genial! Tus intereses nos ayudan a encontrar mejores coincidencias';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Máximo $count intereses permitidos';
  }

  @override
  String get connectSocialAccounts => 'Conecta tus cuentas sociales';

  @override
  String get helpOthersFindYou =>
      'Ayuda a otros a encontrarte en redes sociales';

  @override
  String get socialProfilesTip =>
      'Tus perfiles sociales serán visibles en tu perfil de citas y ayudarán a otros a verificar tu identidad.';

  @override
  String get usernameOrProfileUrl => 'Nombre de usuario o URL del perfil';

  @override
  String get usernameWithoutAt => 'Nombre de usuario (sin @)';

  @override
  String get voiceIntroduction => 'Presentación de Voz';

  @override
  String get interestTravel => 'Viajes';

  @override
  String get interestPhotography => 'Fotografía';

  @override
  String get interestMusic => 'Música';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestCooking => 'Cocina';

  @override
  String get interestReading => 'Lectura';

  @override
  String get interestMovies => 'Películas';

  @override
  String get interestGaming => 'Videojuegos';

  @override
  String get interestArt => 'Arte';

  @override
  String get interestDance => 'Baile';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestHiking => 'Senderismo';

  @override
  String get interestSwimming => 'Natación';

  @override
  String get interestCycling => 'Ciclismo';

  @override
  String get interestRunning => 'Correr';

  @override
  String get interestSports => 'Deportes';

  @override
  String get interestFashion => 'Moda';

  @override
  String get interestTechnology => 'Tecnología';

  @override
  String get interestWriting => 'Escritura';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestWine => 'Vino';

  @override
  String get interestBeer => 'Cerveza';

  @override
  String get interestFood => 'Comida';

  @override
  String get interestVegetarian => 'Vegetariano';

  @override
  String get interestVegan => 'Vegano';

  @override
  String get interestPets => 'Mascotas';

  @override
  String get interestDogs => 'Perros';

  @override
  String get interestCats => 'Gatos';

  @override
  String get interestNature => 'Naturaleza';

  @override
  String get interestBeach => 'Playa';

  @override
  String get interestMountains => 'Montañas';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSkiing => 'Esquí';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestMeditation => 'Meditación';

  @override
  String get interestSpirituality => 'Espiritualidad';

  @override
  String get interestVolunteering => 'Voluntariado';

  @override
  String get interestEnvironment => 'Medio Ambiente';

  @override
  String get interestPolitics => 'Política';

  @override
  String get interestScience => 'Ciencia';

  @override
  String get interestHistory => 'Historia';

  @override
  String get interestLanguages => 'Idiomas';

  @override
  String get interestTeaching => 'Enseñanza';

  @override
  String get xTwitter => 'X (Twitter)';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Mensaje bloqueado: Contiene $violations. Por tu seguridad, no se permite compartir datos de contacto personales.';
  }

  @override
  String get chatReportMessage => 'Reportar Mensaje';

  @override
  String get chatWhyReportMessage => '¿Por qué reportas este mensaje?';

  @override
  String get chatReportReasonHarassment => 'Acoso o intimidación';

  @override
  String get chatReportReasonSpam => 'Spam o estafa';

  @override
  String get chatReportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get chatReportReasonPersonalInfo => 'Compartir información personal';

  @override
  String get chatReportReasonThreatening => 'Comportamiento amenazante';

  @override
  String get chatReportReasonFakeProfile => 'Perfil falso / Catfishing';

  @override
  String get chatReportReasonUnderage => 'Usuario menor de edad';

  @override
  String get chatReportReasonOther => 'Otro';

  @override
  String get chatMessageReported =>
      'Mensaje reportado. Lo revisaremos en breve.';

  @override
  String chatFailedToReportMessage(String error) {
    return 'Error al reportar mensaje: $error';
  }

  @override
  String get chatSendAttachment => 'Enviar Adjunto';

  @override
  String get chatAttachGallery => 'Galería';

  @override
  String get chatAttachCamera => 'Cámara';

  @override
  String get chatAttachVideo => 'Video';

  @override
  String get chatAttachRecord => 'Grabar';

  @override
  String chatFailedToPickImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Error al seleccionar video: $error';
  }

  @override
  String chatFailedToUploadImage(String error) {
    return 'Error al subir imagen: $error';
  }

  @override
  String get chatVideoTooLarge =>
      'Video demasiado grande. El tamaño máximo es 50MB.';

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Error al subir video: $error';
  }

  @override
  String get chatMediaLimitReached => 'Límite de medios alcanzado';

  @override
  String chatSayHiTo(String name) {
    return '¡Saluda a $name!';
  }

  @override
  String get chatSendMessageToStart =>
      'Envía un mensaje para iniciar la conversación';

  @override
  String get chatTyping => 'escribiendo...';

  @override
  String get chatDisableTranslation => 'Desactivar traducción';

  @override
  String get chatEnableTranslation => 'Activar traducción';

  @override
  String get chatTranslationEnabled => 'Traducción activada';

  @override
  String get chatTranslationDisabled => 'Traducción desactivada';

  @override
  String get chatUploading => 'Subiendo...';

  @override
  String get chatOptions => 'Opciones de Chat';

  @override
  String get chatDeleteForMe => 'Eliminar chat para mí';

  @override
  String get chatDeleteForBoth => 'Eliminar chat para ambos';

  @override
  String chatBlockUser(String name) {
    return 'Bloquear a $name';
  }

  @override
  String chatReportUser(String name) {
    return 'Reportar a $name';
  }

  @override
  String get chatDeleteChat => 'Eliminar Chat';

  @override
  String get chatDeleteChatForMeMessage =>
      'Esto eliminará el chat solo de tu dispositivo. La otra persona seguirá viendo los mensajes.';

  @override
  String get chatDeleteChatForEveryone => 'Eliminar Chat para Todos';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Esto eliminará todos los mensajes para ti y $name. Esta acción no se puede deshacer.';
  }

  @override
  String get chatDeleteForEveryone => 'Eliminar para Todos';

  @override
  String get chatBlockUserTitle => 'Bloquear Usuario';

  @override
  String chatBlockUserMessage(String name) {
    return '¿Estás seguro de que quieres bloquear a $name? Ya no podrán contactarte.';
  }

  @override
  String get chatBlock => 'Bloquear';

  @override
  String get chatCannotBlockAdmin => 'No puedes bloquear a un administrador.';

  @override
  String chatUserBlocked(String name) {
    return '$name ha sido bloqueado';
  }

  @override
  String get chatReportUserTitle => 'Reportar Usuario';

  @override
  String chatWhyReportUser(String name) {
    return '¿Por qué reportas a $name?';
  }

  @override
  String get chatCannotReportAdmin => 'No puedes reportar a un administrador.';

  @override
  String get chatUserReported =>
      'Usuario reportado. Revisaremos tu reporte en breve.';

  @override
  String chatReplyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get chatYou => 'Tú';

  @override
  String get chatUnableToForward => 'No se puede reenviar el mensaje';

  @override
  String get chatSearchByNameOrNickname => 'Buscar por nombre o @apodo';

  @override
  String get chatNoMessagesYet => 'No hay mensajes aún';

  @override
  String get chatStartSwipingToChat =>
      '¡Desliza y haz match para chatear con personas!';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageTranslated => 'Traducido';

  @override
  String get chatMessageStarred => 'Mensaje destacado';

  @override
  String get chatMessageUnstarred => 'Mensaje sin destacar';

  @override
  String get chatMessageOptions => 'Opciones de Mensaje';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatReplyToMessage => 'Responder a este mensaje';

  @override
  String get chatForward => 'Reenviar';

  @override
  String get chatForwardToChat => 'Reenviar a otro chat';

  @override
  String get chatStarMessage => 'Destacar Mensaje';

  @override
  String get chatUnstarMessage => 'Quitar Destacado';

  @override
  String get chatAddToStarred => 'Agregar a mensajes destacados';

  @override
  String get chatRemoveFromStarred => 'Quitar de mensajes destacados';

  @override
  String get chatReportInappropriate => 'Reportar contenido inapropiado';

  @override
  String get chatVideoPlayer => 'Reproductor de Video';

  @override
  String get chatFailedToLoadImage => 'Error al cargar imagen';

  @override
  String get chatLoadingVideo => 'Cargando video...';

  @override
  String get chatPreviewVideo => 'Vista previa de Video';

  @override
  String get chatPreviewImage => 'Vista previa de Imagen';

  @override
  String get chatAddCaption => 'Agregar descripción...';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSupportTitle => 'Soporte GreenGo';

  @override
  String get chatSupportStatusOpen => 'Abierto';

  @override
  String get chatSupportStatusPending => 'Pendiente';

  @override
  String get chatSupportStatusResolved => 'Resuelto';

  @override
  String get chatSupportStatusClosed => 'Cerrado';

  @override
  String get chatSupportStatusDefault => 'Soporte';

  @override
  String chatSupportAgent(String name) {
    return 'Agente: $name';
  }

  @override
  String get chatSupportWelcome => 'Bienvenido al Soporte';

  @override
  String get chatSupportStartMessage =>
      'Envía un mensaje para iniciar la conversación.\nNuestro equipo responderá lo antes posible.';

  @override
  String get chatSupportTicketStart => 'Inicio del Ticket';

  @override
  String get chatSupportTicketCreated => 'Ticket Creado';

  @override
  String get chatSupportErrorLoading => 'Error al cargar mensajes';

  @override
  String chatSupportFailedToSend(String error) {
    return 'Error al enviar mensaje: $error';
  }

  @override
  String get chatSupportTicketResolved => 'Este ticket ha sido resuelto';

  @override
  String get chatSupportReopenTicket =>
      '¿Necesitas más ayuda? Toca para reabrir';

  @override
  String get chatSupportTicketReopened =>
      'Ticket reabierto. Ya puedes enviar un mensaje.';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Error al reabrir ticket: $error';
  }

  @override
  String get chatSupportAddCaptionOptional =>
      'Agregar descripción (opcional)...';

  @override
  String get chatSupportTypeMessage => 'Escribe tu mensaje...';

  @override
  String get chatSupportAddAttachment => 'Agregar Adjunto';

  @override
  String get chatSupportTicketInfo => 'Información del Ticket';

  @override
  String get chatSupportSubject => 'Asunto';

  @override
  String get chatSupportCategory => 'Categoría';

  @override
  String get chatSupportStatus => 'Estado';

  @override
  String get chatSupportAgentLabel => 'Agente';

  @override
  String get chatSupportTicketId => 'ID del Ticket';

  @override
  String get chatSupportGeneralSupport => 'Soporte General';

  @override
  String get chatSupportGeneral => 'General';

  @override
  String get chatSupportWaitingAssignment => 'Esperando asignación';

  @override
  String get chatSupportClose => 'Cerrar';

  @override
  String get chatSupportJustNow => 'Ahora mismo';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'hace ${minutes}min';
  }

  @override
  String chatSupportHoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String chatSupportDaysAgo(int days) {
    return 'hace ${days}d';
  }

  @override
  String get nicknameSearchChat => 'Chat';

  @override
  String get filterNewMessages => 'Nuevos';

  @override
  String get filterNotReplied => 'Sin respuesta';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Directo';

  @override
  String get publicAlbum => 'Público';

  @override
  String get privateAlbum => 'Privado';

  @override
  String get shareAlbum => 'Compartir álbum';

  @override
  String get revokeAccess => 'Revocar acceso al álbum';

  @override
  String get albumNotShared => 'Álbum no compartido';

  @override
  String get grantAlbumAccess => 'Compartir mi álbum';

  @override
  String get albumOption => 'Álbum';

  @override
  String albumSharedMessage(String username) {
    return '$username compartió su álbum contigo';
  }

  @override
  String albumRevokedMessage(String username) {
    return '$username revocó el acceso al álbum';
  }

  @override
  String get sendCoins => 'Enviar monedas';

  @override
  String get recipientNickname => 'Apodo del destinatario';

  @override
  String get enterAmount => 'Ingresa la cantidad';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return '¿Enviar $amount monedas a @$nickname?';
  }

  @override
  String get coinsSent => '¡Monedas enviadas con éxito!';

  @override
  String get insufficientCoins => 'Monedas insuficientes';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get weight => 'Peso';

  @override
  String get aboutMeTitle => 'Sobre mí';

  @override
  String get travelerBadge => 'Viajero';

  @override
  String get travelerModeTitle => 'Modo Viajero';

  @override
  String get travelerModeDescription =>
      'Aparece en el feed de descubrimiento de otra ciudad durante 24 horas';

  @override
  String get travelerModeActive => 'Modo viajero activo';

  @override
  String travelerModeActivated(String city) {
    return '¡Modo viajero activado! Apareciendo en $city durante 24 horas.';
  }

  @override
  String get travelerModeDeactivated =>
      'Modo viajero desactivado. De vuelta a tu ubicación real.';

  @override
  String get selectTravelLocation => 'Seleccionar ubicación de viaje';

  @override
  String get searchCityPlaceholder => 'Buscar ciudad, dirección o lugar...';

  @override
  String get useCurrentGpsLocation => 'Usar mi ubicación GPS actual';

  @override
  String get confirmLocation => 'Confirmar ubicación';

  @override
  String get changeLocation => 'Cambiar ubicación';

  @override
  String get travelerLocationInfo =>
      'Aparecerás en los resultados de descubrimiento de esta ubicación durante 24 horas.';

  @override
  String get searchForCity => 'Busca una ciudad o usa el GPS';

  @override
  String get travelerSearchHint =>
      'Tu perfil aparecerá en el feed de descubrimiento de esa ubicación durante 24 horas con una insignia de Viajero.';

  @override
  String get incognitoMode => 'Modo Incógnito';

  @override
  String get incognitoModeDescription => 'Oculta tu perfil del descubrimiento';

  @override
  String get myUsage => 'Mi Uso';

  @override
  String get boostProfile => 'Impulsar Perfil';

  @override
  String get boostActivated => '¡Impulso activado por 30 minutos!';

  @override
  String get superLike => 'Super Like';

  @override
  String get undoSwipe => 'Deshacer Swipe';

  @override
  String freeActionsRemaining(int count) {
    return '$count acciones gratuitas restantes hoy';
  }

  @override
  String coinsRequired(int amount) {
    return '$amount monedas requeridas';
  }

  @override
  String get tierFree => 'Gratis';

  @override
  String get dailySwipeLimitReached =>
      'Límite diario de swipes alcanzado. ¡Mejora para más swipes!';

  @override
  String get noOthersToSee => 'No hay más personas para ver';

  @override
  String get checkBackLater =>
      'Vuelve más tarde para ver nuevas personas, o ajusta tus preferencias';

  @override
  String get adjustPreferences => 'Ajustar Preferencias';

  @override
  String get noPreviousProfile => 'No hay perfil anterior para deshacer';

  @override
  String get cantUndoMatched => 'No se puede deshacer — ¡ya hiciste match!';

  @override
  String showingProfiles(int count) {
    return '$count perfiles';
  }

  @override
  String seeMoreProfiles(int count) {
    return 'Ver $count más';
  }

  @override
  String coinsCost(int amount) {
    return '$amount monedas';
  }

  @override
  String get seeMoreProfilesTitle => 'Ver Más Perfiles';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Desbloquea $count perfiles más en la cuadrícula por $cost monedas.';
  }

  @override
  String get unlock => 'Desbloquear';

  @override
  String get buyCoins => 'Comprar Monedas';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Necesitas $amount monedas para desbloquear más perfiles.';
  }

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilidad';
  }

  @override
  String get youGotSuperLike => '¡Recibiste un Super Like!';

  @override
  String superLikedYou(String name) {
    return '¡$name te dio un Super Like!';
  }

  @override
  String get photoValidating => 'Validando foto...';

  @override
  String get photoNotAccepted => 'Foto no aceptada';

  @override
  String get photoMainNoFace =>
      'Tu foto principal debe mostrar tu rostro claramente. No se detectó ningún rostro en esta foto.';

  @override
  String get photoMainNotForward =>
      'Por favor, usa una foto donde tu rostro sea claramente visible y esté mirando hacia adelante.';

  @override
  String get photoExplicitNudity =>
      'Esta foto parece contener desnudez o contenido explícito. Todas las fotos en la app deben ser apropiadas y mostrar ropa completa.';

  @override
  String get photoExplicitContent =>
      'Esta foto puede contener contenido inapropiado. Las fotos en la app no deben mostrar desnudez, ropa interior ni contenido explícito.';

  @override
  String get photoTooMuchSkin =>
      'Esta foto muestra demasiada piel expuesta. Por favor, usa una foto donde estés vestido/a apropiadamente.';

  @override
  String get photoNotAllowedPublic =>
      'Esta foto no está permitida en ningún lugar de la app.';

  @override
  String get photoTooLarge =>
      'La foto es demasiado grande. El tamaño máximo es 10 MB.';

  @override
  String get photoMustHaveOne =>
      'Debes tener al menos una foto pública con tu rostro visible.';

  @override
  String get photoDeleteMainWarning =>
      'Esta es tu foto principal. La siguiente foto se convertirá en tu foto principal (debe mostrar tu rostro). ¿Continuar?';

  @override
  String get photoDeleteConfirm =>
      '¿Estás seguro/a de que deseas eliminar esta foto?';

  @override
  String get photoMaxPublic => 'Máximo 6 fotos públicas permitidas';

  @override
  String get photoMaxPrivate => 'Máximo 6 fotos privadas permitidas';

  @override
  String get membershipRequired => 'Membresía requerida';

  @override
  String get membershipRequiredDescription =>
      'Necesitas ser miembro de GreenGo para realizar esta acción.';

  @override
  String get yearlyMembership => 'Membresía anual';

  @override
  String get subscribeNow => 'Suscribirse ahora';

  @override
  String get maybeLater => 'Quizás más tarde';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopTabCoins => 'Monedas';

  @override
  String get shopTabMembership => 'Membresía';

  @override
  String get shopTabVideo => 'Video';

  @override
  String get shopUpgradeExperience => 'Mejora tu experiencia';

  @override
  String shopCurrentPlan(String tier) {
    return 'Plan actual: $tier';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expira: $date ($days días restantes)';
  }

  @override
  String shopExpired(String date) {
    return 'Expirado: $date';
  }

  @override
  String get shopMonthly => 'Mensual';

  @override
  String get shopYearly => 'Anual';

  @override
  String shopSavePercent(String percent) {
    return 'AHORRA $percent%';
  }

  @override
  String get shopUpgradeAndSave =>
      '¡Mejora y ahorra! Descuento en niveles superiores';

  @override
  String get shopBaseMembership => 'Membresía Base GreenGo';

  @override
  String get shopYearlyPlan => 'Suscripción anual';

  @override
  String get shopActive => 'ACTIVA';

  @override
  String get shopBaseMembershipDescription =>
      'Necesaria para deslizar, dar like, chatear e interactuar con otros usuarios.';

  @override
  String shopValidUntil(String date) {
    return 'Válida hasta $date';
  }

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Mejorar a $tier ($duration)';
  }

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Comprar $tier ($duration)';
  }

  @override
  String get shopOneYear => '1 Año';

  @override
  String get shopOneMonth => '1 Mes';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Ahorras $amount/mes al mejorar desde $tier';
  }

  @override
  String get shopDailyLikes => 'Likes diarios';

  @override
  String get shopSuperLikes => 'Super Likes';

  @override
  String get shopBoosts => 'Boosts';

  @override
  String get shopSeeWhoLikesYou => 'Ver quién te gusta';

  @override
  String get shopVipBadge => 'Insignia VIP';

  @override
  String get shopPriorityMatching => 'Coincidencia prioritaria';

  @override
  String get shopSendCoins => 'Enviar monedas';

  @override
  String get shopRecipientNickname => 'Nickname del destinatario';

  @override
  String get shopEnterAmount => 'Ingresa la cantidad';

  @override
  String get shopConfirmSend => 'Confirmar envío';

  @override
  String get shopSend => 'Enviar';

  @override
  String get shopUserNotFound => 'Usuario no encontrado';

  @override
  String get shopCannotSendToSelf => 'No puedes enviarte monedas a ti mismo';

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount monedas enviadas a @$nickname';
  }

  @override
  String get shopFailedToSendCoins => 'Error al enviar monedas';

  @override
  String get shopEnterBothFields => 'Ingresa el nickname y la cantidad';

  @override
  String get shopEnterValidAmount => 'Ingresa una cantidad válida';

  @override
  String get shopInsufficientCoins => 'Monedas insuficientes';

  @override
  String get shopYouHave => 'Tienes';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopUnlockPremium =>
      'Desbloquea funciones premium y mejora tu experiencia de citas';

  @override
  String get shopPopular => 'POPULAR';

  @override
  String get shopCoins => 'Monedas';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Comprar $coins monedas por $price';
  }

  @override
  String get shopComingSoon => 'Próximamente';

  @override
  String get shopVideoCoinsDescription =>
      '¡Mira videos cortos para ganar monedas gratis!\nEstá atento a esta emocionante función.';

  @override
  String get shopGetNotified => 'Recibir notificación';

  @override
  String get shopNotifyMessage =>
      'Te avisaremos cuando Video-Coins esté disponible';

  @override
  String get shopStoreNotAvailable =>
      'Tienda no disponible. Asegúrate de que Google Play esté instalado.';

  @override
  String get shopFailedToInitiate => 'No se pudo iniciar la compra';

  @override
  String get shopUnableToLoadPackages => 'No se pueden cargar los paquetes';

  @override
  String get shopRetry => 'Reintentar';

  @override
  String get shopCheckInternet =>
      'Asegúrate de tener conexión a internet\ny vuelve a intentarlo.';

  @override
  String shopMembershipActivated(String date) {
    return '¡Membresía GreenGo activada! +500 monedas de bono. Válida hasta $date.';
  }

  @override
  String get shopPreviousPurchaseFound =>
      'Compra anterior encontrada. Inténtalo de nuevo.';

  @override
  String get reuploadVerification => 'Volver a subir foto de verificación';

  @override
  String get reverificationTitle => 'Verificación de identidad';

  @override
  String get reverificationHeading => 'Necesitamos verificar tu identidad';

  @override
  String get reverificationDescription =>
      'Por favor, tómate un selfie claro para verificar tu identidad. Asegúrate de tener buena iluminación y que tu rostro sea visible.';

  @override
  String get reverificationReasonLabel => 'Motivo de la solicitud:';

  @override
  String get reverificationPhotoTips => 'Consejos para la foto';

  @override
  String get reverificationTipLighting =>
      'Buena iluminación — mira hacia la fuente de luz';

  @override
  String get reverificationTipCamera => 'Mira directamente a la cámara';

  @override
  String get reverificationTipNoAccessories =>
      'Sin gafas de sol, sombreros ni mascarillas';

  @override
  String get reverificationTipFullFace =>
      'Asegúrate de que tu rostro completo sea visible';

  @override
  String get reverificationRetakePhoto => 'Repetir foto';

  @override
  String get reverificationTapToSelfie => 'Toca para tomar un selfie';

  @override
  String get reverificationSubmit => 'Enviar para revisión';

  @override
  String get reverificationInfoText =>
      'Después de enviar, tu perfil estará en revisión. Obtendrás acceso una vez aprobado.';

  @override
  String get reverificationCameraError => 'No se pudo abrir la cámara';

  @override
  String get reverificationUploadFailed =>
      'Error al subir. Por favor, inténtalo de nuevo.';

  @override
  String get notificationDialogTitle => 'Mantente conectado';

  @override
  String get notificationDialogMessage =>
      'Activa las notificaciones para saber cuándo recibes matches, mensajes y super likes.';

  @override
  String get notificationDialogEnable => 'Activar';

  @override
  String get notificationDialogNotNow => 'Ahora no';

  @override
  String get discoveryFilterAll => 'Todos';

  @override
  String get discoveryFilterLiked => 'Me gusta';

  @override
  String get discoveryFilterSuperLiked => 'Super Like';

  @override
  String get discoveryFilterPassed => 'Rechazados';

  @override
  String get discoveryFilterSkipped => 'Omitidos';

  @override
  String get discoveryFilterMatches => 'Matches';

  @override
  String discoveryError(String error) {
    return 'Error: $error';
  }

  @override
  String get admin2faTitle => 'Verificación de Admin';

  @override
  String get admin2faSubtitle =>
      'Ingresa el código de 6 dígitos enviado a tu correo';

  @override
  String admin2faCodeSent(String email) {
    return 'Código enviado a $email';
  }

  @override
  String get admin2faVerify => 'Verificar';

  @override
  String get admin2faResend => 'Reenviar Código';

  @override
  String admin2faResendIn(String seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get admin2faInvalidCode => 'Código de verificación inválido';

  @override
  String get admin2faExpired => 'Código expirado. Solicita uno nuevo.';

  @override
  String get admin2faMaxAttempts =>
      'Demasiados intentos. Solicita un nuevo código.';

  @override
  String get admin2faSending => 'Enviando código...';

  @override
  String get admin2faSignOut => 'Cerrar Sesión';

  @override
  String get twoFaToggleTitle => 'Activar Autenticación 2FA';

  @override
  String get twoFaToggleSubtitle =>
      'Requerir verificación por código de email en cada inicio de sesión';

  @override
  String get twoFaEnabled => 'Autenticación 2FA activada';

  @override
  String get twoFaDisabled => 'Autenticación 2FA desactivada';
}
