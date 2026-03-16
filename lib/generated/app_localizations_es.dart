// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get abandonGame => 'Abandonar Partida';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutMe => 'Sobre Mí';

  @override
  String get aboutMeTitle => 'Sobre mí';

  @override
  String get academicCategory => 'Académico';

  @override
  String get acceptPrivacyPolicy =>
      'He leído y acepto la Política de Privacidad';

  @override
  String get acceptProfiling =>
      'Consiento el perfilado para recomendaciones personalizadas';

  @override
  String get acceptTermsAndConditions =>
      'He leído y acepto los Términos y Condiciones';

  @override
  String get acceptThirdPartyData =>
      'Consiento compartir mis datos con terceros';

  @override
  String get accessGranted => '¡Acceso concedido!';

  @override
  String accessGrantedBody(Object tierName) {
    return '¡GreenGo ya está activo! Como $tierName, ahora tienes acceso completo a todas las funciones.';
  }

  @override
  String get accountApproved => 'Cuenta Aprobada';

  @override
  String get accountApprovedBody =>
      'Tu cuenta de GreenGo ha sido aprobada. ¡Bienvenido/a a la comunidad!';

  @override
  String get accountCreatedSuccess =>
      '¡Cuenta creada! Por favor revisa tu correo electrónico para verificar tu cuenta.';

  @override
  String get accountPendingApproval => 'Cuenta Pendiente de Aprobación';

  @override
  String get accountRejected => 'Cuenta Rechazada';

  @override
  String get accountSettings => 'Configuración de Cuenta';

  @override
  String get accountUnderReview => 'Cuenta en Revisión';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Logros';

  @override
  String get achievementsSubtitle => 'Ver tus insignias y progreso';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get addBio => 'Agregar biografía';

  @override
  String get addDealBreakerTitle => 'Agregar Criterio Excluyente';

  @override
  String get addPhoto => 'Añadir Foto';

  @override
  String get adjustPreferences => 'Ajustar Preferencias';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Código enviado a $email';
  }

  @override
  String get admin2faExpired => 'Código expirado. Solicita uno nuevo.';

  @override
  String get admin2faInvalidCode => 'Código de verificación inválido';

  @override
  String get admin2faMaxAttempts =>
      'Demasiados intentos. Solicita un nuevo código.';

  @override
  String get admin2faResend => 'Reenviar Código';

  @override
  String admin2faResendIn(String seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get admin2faSending => 'Enviando código...';

  @override
  String get admin2faSignOut => 'Cerrar Sesión';

  @override
  String get admin2faSubtitle =>
      'Ingresa el código de 6 dígitos enviado a tu correo';

  @override
  String get admin2faTitle => 'Verificación de Admin';

  @override
  String get admin2faVerify => 'Verificar';

  @override
  String get adminAccessDates => 'Fechas de acceso:';

  @override
  String get adminAccountLockedSuccessfully => 'Cuenta bloqueada correctamente';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Cuenta desbloqueada correctamente';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Las cuentas de admin no pueden ser eliminadas';

  @override
  String adminAchievementCount(Object count) {
    return '$count logros';
  }

  @override
  String get adminAchievementUpdated => 'Logro actualizado';

  @override
  String get adminAchievements => 'Logros';

  @override
  String get adminAchievementsSubtitle => 'Gestionar logros e insignias';

  @override
  String get adminActive => 'ACTIVO';

  @override
  String adminActiveCount(Object count) {
    return 'Activos ($count)';
  }

  @override
  String get adminActiveEvent => 'Evento activo';

  @override
  String get adminActiveUsers => 'Usuarios activos';

  @override
  String get adminAdd => 'Añadir';

  @override
  String get adminAddCoins => 'Añadir monedas';

  @override
  String get adminAddPackage => 'Añadir paquete';

  @override
  String get adminAddResolutionNote => 'Añadir nota de resolución...';

  @override
  String get adminAddSingleEmail => 'Añadir correo individual';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return '$amount monedas añadidas al usuario';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Añadido $date';
  }

  @override
  String get adminAdvancedFilters => 'Filtros avanzados';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age años - $gender';
  }

  @override
  String get adminAll => 'Todos';

  @override
  String get adminAllReports => 'Todos los reportes';

  @override
  String get adminAmount => 'Cantidad';

  @override
  String get adminAnalyticsAndReports => 'Análisis e informes';

  @override
  String get adminAppSettings => 'Configuración de la app';

  @override
  String get adminAppSettingsSubtitle =>
      'Configuración general de la aplicación';

  @override
  String get adminApproveSelected => 'Aprobar seleccionados';

  @override
  String get adminAssignToMe => 'Asignarme';

  @override
  String get adminAssigned => 'Asignado';

  @override
  String get adminAvailable => 'Disponible';

  @override
  String get adminBadge => 'Insignia';

  @override
  String get adminBaseCoins => 'Monedas base';

  @override
  String get adminBaseXp => 'XP base';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount monedas de bonificación';
  }

  @override
  String get adminBonusCoinsLabel => 'Monedas de bonificación';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes de bonificación';
  }

  @override
  String get adminBrowseProfilesAnonymously =>
      'Explorar perfiles de forma anónima';

  @override
  String get adminCanSendMedia => 'Puede enviar contenido multimedia';

  @override
  String adminChallengeCount(Object count) {
    return '$count desafíos';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'La creación de desafíos estará disponible próximamente.';

  @override
  String get adminChallenges => 'Desafíos';

  @override
  String get adminChangesSaved => 'Cambios guardados';

  @override
  String get adminChatWithReporter => 'Chatear con el denunciante';

  @override
  String get adminClear => 'Borrar';

  @override
  String get adminClosed => 'Cerrado';

  @override
  String get adminCoinAmount => 'Cantidad de monedas';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount monedas';
  }

  @override
  String get adminCoinCost => 'Coste en monedas';

  @override
  String get adminCoinManagement => 'Gestión de monedas';

  @override
  String get adminCoinManagementSubtitle =>
      'Gestionar paquetes de monedas y saldos de usuarios';

  @override
  String get adminCoinPackages => 'Paquetes de monedas';

  @override
  String get adminCoinReward => 'Recompensa en monedas';

  @override
  String adminComingSoon(Object route) {
    return '$route disponible próximamente';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configuraciones restablecidas a los valores predeterminados. Guarde para aplicar.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Configurar límites y funciones';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configurar recompensas de hitos para inicios de sesión consecutivos';

  @override
  String get adminCreateChallenge => 'Crear desafío';

  @override
  String get adminCreateEvent => 'Crear evento';

  @override
  String get adminCreateNewChallenge => 'Crear nuevo desafío';

  @override
  String get adminCreateSeasonalEvent => 'Crear evento de temporada';

  @override
  String get adminCsvFormat => 'Formato CSV:';

  @override
  String get adminCsvFormatDescription =>
      'Un correo por línea o valores separados por comas. Las comillas se eliminan automáticamente. Los correos inválidos se omiten.';

  @override
  String get adminCurrentBalance => 'Saldo actual';

  @override
  String get adminDailyChallenges => 'Desafíos diarios';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configurar desafíos diarios y recompensas';

  @override
  String get adminDailyLimits => 'Límites diarios';

  @override
  String get adminDailyLoginRewards =>
      'Recompensas de inicio de sesión diarias';

  @override
  String get adminDailyMessages => 'Mensajes diarios';

  @override
  String get adminDailySuperLikes => 'Conexiones Prioritarias diarias';

  @override
  String get adminDailySwipes => 'Swipes diarios';

  @override
  String get adminDashboard => 'Panel de administración';

  @override
  String get adminDate => 'Fecha';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return '¿Estás seguro de que quieres eliminar el paquete \"$amount monedas\"?';
  }

  @override
  String get adminDeletePackageTitle => '¿Eliminar paquete?';

  @override
  String get adminDescription => 'Descripción';

  @override
  String get adminDeselectAll => 'Deseleccionar todo';

  @override
  String get adminDisabled => 'Desactivado';

  @override
  String get adminDismiss => 'Descartar';

  @override
  String get adminDismissReport => 'Descartar reporte';

  @override
  String get adminDismissReportConfirm =>
      '¿Estás seguro de que quieres descartar este reporte?';

  @override
  String get adminEarlyAccessDate => '14 de marzo de 2026';

  @override
  String get adminEarlyAccessDates =>
      'Los usuarios en esta lista obtienen acceso el 14 de marzo de 2026.\nTodos los demás usuarios obtienen acceso el 14 de abril de 2026.';

  @override
  String get adminEarlyAccessInList => 'Acceso anticipado (en la lista)';

  @override
  String get adminEarlyAccessInfo => 'Información de acceso anticipado';

  @override
  String get adminEarlyAccessList => 'Lista de acceso anticipado';

  @override
  String get adminEarlyAccessProgram => 'Programa de acceso anticipado';

  @override
  String get adminEditAchievement => 'Editar logro';

  @override
  String adminEditItem(Object name) {
    return 'Editar $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Editar $name';
  }

  @override
  String get adminEditPackage => 'Editar paquete';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email añadido a la lista de acceso anticipado';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count correos';
  }

  @override
  String get adminEmailList => 'Lista de correos';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email eliminado de la lista de acceso anticipado';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Activar opciones de filtrado avanzado';

  @override
  String get adminEngagementReports => 'Informes de participación';

  @override
  String get adminEngagementReportsSubtitle =>
      'Ver estadísticas de coincidencias y mensajes';

  @override
  String get adminEnterEmailAddress => 'Introduce una dirección de correo';

  @override
  String get adminEnterValidAmount =>
      'Por favor, introduce una cantidad válida';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Por favor, introduce una cantidad de monedas y un precio válidos';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Error al añadir el correo: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Error al cargar el contexto: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Error al cargar los datos: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Error al abrir el chat: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Error al eliminar el correo: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Error: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Error al subir el archivo: $error';
  }

  @override
  String get adminErrors => 'Errores:';

  @override
  String get adminEventCreationComingSoon =>
      'La creación de eventos estará disponible próximamente.';

  @override
  String get adminEvents => 'Eventos';

  @override
  String adminFailedToSave(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get adminFeatures => 'Funciones';

  @override
  String get adminFilterByInterests => 'Filtrar por intereses';

  @override
  String get adminFilterBySpecificLocation =>
      'Filtrar por ubicación específica';

  @override
  String get adminFilterBySpokenLanguages => 'Filtrar por idiomas hablados';

  @override
  String get adminFilterByVerificationStatus =>
      'Filtrar por estado de verificación';

  @override
  String get adminFilterOptions => 'Opciones de filtro';

  @override
  String get adminGamification => 'Gamificación';

  @override
  String get adminGamificationAndRewards => 'Gamificación y recompensas';

  @override
  String get adminGeneralAccess => 'Acceso general';

  @override
  String get adminGeneralAccessDate => '14 de abril de 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Mayor prioridad = se muestra primero en el descubrimiento';

  @override
  String get adminImportResult => 'Resultado de importación';

  @override
  String get adminInProgress => 'En progreso';

  @override
  String get adminIncognitoMode => 'Modo incógnito';

  @override
  String get adminInterestFilter => 'Filtro de intereses';

  @override
  String get adminInvoices => 'Facturas';

  @override
  String get adminLanguageFilter => 'Filtro de idioma';

  @override
  String get adminLoading => 'Cargando...';

  @override
  String get adminLocationFilter => 'Filtro de ubicación';

  @override
  String get adminLockAccount => 'Bloquear cuenta';

  @override
  String adminLockAccountConfirm(Object userId) {
    return '¿Bloquear la cuenta del usuario $userId...?';
  }

  @override
  String get adminLockDuration => 'Duración del bloqueo';

  @override
  String adminLockReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String adminLockedCount(Object count) {
    return 'Bloqueados ($count)';
  }

  @override
  String adminLockedDate(Object date) {
    return 'Bloqueado: $date';
  }

  @override
  String get adminLoginStreakSystem => 'Sistema de rachas de inicio de sesión';

  @override
  String get adminLoginStreaks => 'Rachas de inicio de sesión';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configurar hitos de rachas y recompensas';

  @override
  String get adminManageAppSettings =>
      'Administra la configuración de tu aplicación GreenGo';

  @override
  String get adminMatchPriority => 'Prioridad de coincidencia';

  @override
  String get adminMatchingAndVisibility => 'Coincidencias y visibilidad';

  @override
  String get adminMessageContext => 'Contexto del mensaje (50 antes/después)';

  @override
  String get adminMilestoneUpdated => 'Hito actualizado';

  @override
  String adminMoreErrors(Object count) {
    return '... y $count errores más';
  }

  @override
  String get adminName => 'Nombre';

  @override
  String get adminNinetyDays => '90 días';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'No hay correos en la lista de acceso anticipado';

  @override
  String get adminNoInvoicesFound => 'No se encontraron facturas';

  @override
  String get adminNoLockedAccounts => 'No hay cuentas bloqueadas';

  @override
  String get adminNoMatchingEmailsFound =>
      'No se encontraron correos coincidentes';

  @override
  String get adminNoOrdersFound => 'No se encontraron pedidos';

  @override
  String get adminNoPendingReports => 'No hay reportes pendientes';

  @override
  String get adminNoReportsYet => 'Aún no hay reportes';

  @override
  String adminNoTickets(Object status) {
    return 'No hay tickets $status';
  }

  @override
  String get adminNoValidEmailsFound =>
      'No se encontraron direcciones de correo válidas en el archivo';

  @override
  String get adminNoVerificationHistory => 'Sin historial de verificación';

  @override
  String get adminOneDay => '1 día';

  @override
  String get adminOpen => 'Abierto';

  @override
  String adminOpenCount(Object count) {
    return 'Abiertos ($count)';
  }

  @override
  String get adminOpenTickets => 'Tickets abiertos';

  @override
  String get adminOrderDetails => 'Detalles del pedido';

  @override
  String get adminOrderId => 'ID de pedido';

  @override
  String get adminOrderRefunded => 'Pedido reembolsado';

  @override
  String get adminOrders => 'Pedidos';

  @override
  String get adminPackages => 'Paquetes';

  @override
  String get adminPanel => 'Panel de Admin';

  @override
  String get adminPayment => 'Pago';

  @override
  String get adminPending => 'Pendiente';

  @override
  String adminPendingCount(Object count) {
    return 'Pendientes ($count)';
  }

  @override
  String get adminPermanent => 'Permanente';

  @override
  String get adminPleaseEnterValidEmail =>
      'Por favor, introduce una dirección de correo válida';

  @override
  String get adminPriceUsd => 'Precio (USD)';

  @override
  String get adminProductIdIap => 'ID de producto (para IAP)';

  @override
  String get adminProfileVisitors => 'Visitantes del perfil';

  @override
  String get adminPromotional => 'Promocional';

  @override
  String get adminPromotionalPackage => 'Paquete promocional';

  @override
  String get adminPromotions => 'Promociones';

  @override
  String get adminPromotionsSubtitle =>
      'Gestionar ofertas especiales y promociones';

  @override
  String get adminProvideReason => 'Por favor, proporciona un motivo';

  @override
  String get adminReadReceipts => 'Confirmaciones de lectura';

  @override
  String get adminReason => 'Motivo';

  @override
  String adminReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String get adminReasonRequired => 'Motivo (obligatorio)';

  @override
  String get adminRefund => 'Reembolso';

  @override
  String get adminRemove => 'Eliminar';

  @override
  String get adminRemoveCoins => 'Eliminar monedas';

  @override
  String get adminRemoveEmail => 'Eliminar correo';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return '¿Estás seguro de que quieres eliminar \"$email\" de la lista de acceso anticipado?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return '$amount monedas eliminadas del usuario';
  }

  @override
  String get adminReportDismissed => 'Reporte descartado';

  @override
  String get adminReportFollowupStarted =>
      'Conversación de seguimiento del reporte iniciada';

  @override
  String get adminReportedMessage => 'Mensaje reportado:';

  @override
  String get adminReportedMessageMarker => '^ MENSAJE REPORTADO';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'ID de usuario reportado: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'ID del denunciante: $reporterId...';
  }

  @override
  String get adminReports => 'Reportes';

  @override
  String get adminReportsManagement => 'Gestión de reportes';

  @override
  String get adminRequestNewPhoto => 'Solicitar nueva foto';

  @override
  String get adminRequiredCount => 'Cantidad requerida';

  @override
  String adminRequiresCount(Object count) {
    return 'Requiere: $count';
  }

  @override
  String get adminReset => 'Restablecer';

  @override
  String get adminResetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get adminResetToDefaultsConfirm =>
      'Esto restablecerá todas las configuraciones de niveles a sus valores predeterminados. Esta acción no se puede deshacer.';

  @override
  String get adminResetToDefaultsTitle =>
      '¿Restablecer valores predeterminados?';

  @override
  String get adminResolutionNote => 'Nota de resolución';

  @override
  String get adminResolve => 'Resolver';

  @override
  String get adminResolved => 'Resuelto';

  @override
  String adminResolvedCount(Object count) {
    return 'Resueltos ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Análisis de ingresos';

  @override
  String get adminRevenueAnalyticsSubtitle =>
      'Seguimiento de compras e ingresos';

  @override
  String get adminReviewedBy => 'Revisado por';

  @override
  String get adminRewardAmount => 'Cantidad de recompensa';

  @override
  String get adminSaving => 'Guardando...';

  @override
  String get adminScheduledEvents => 'Eventos programados';

  @override
  String get adminSearchByUserIdOrEmail => 'Buscar por ID de usuario o correo';

  @override
  String get adminSearchEmails => 'Buscar correos...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Buscar un usuario para gestionar su saldo de monedas';

  @override
  String get adminSearchOrders => 'Buscar pedidos...';

  @override
  String get adminSeeWhenMessagesAreRead =>
      'Ver cuándo se leyeron los mensajes';

  @override
  String get adminSeeWhoVisitedProfile => 'Ver quién visitó el perfil';

  @override
  String get adminSelectAll => 'Seleccionar todo';

  @override
  String get adminSelectCsvFile => 'Seleccionar archivo CSV';

  @override
  String adminSelectedCount(Object count) {
    return '$count seleccionados';
  }

  @override
  String get adminSendImagesAndVideosInChat =>
      'Enviar imágenes y vídeos en el chat';

  @override
  String get adminSevenDays => '7 días';

  @override
  String get adminSpendItems => 'Artículos de gasto';

  @override
  String get adminStatistics => 'Estadísticas';

  @override
  String get adminStatus => 'Estado';

  @override
  String get adminStreakMilestones => 'Hitos de racha';

  @override
  String get adminStreakMultiplier => 'Multiplicador de racha';

  @override
  String get adminStreakMultiplierValue => '1,5x por día';

  @override
  String get adminStreaks => 'Rachas';

  @override
  String get adminSupport => 'Soporte';

  @override
  String get adminSupportAgents => 'Agentes de soporte';

  @override
  String get adminSupportAgentsSubtitle =>
      'Gestionar cuentas de agentes de soporte';

  @override
  String get adminSupportManagement => 'Gestión de soporte';

  @override
  String get adminSupportRequest => 'Solicitud de soporte';

  @override
  String get adminSupportTickets => 'Tickets de soporte';

  @override
  String get adminSupportTicketsSubtitle =>
      'Ver y gestionar conversaciones de soporte de usuarios';

  @override
  String get adminSystemConfiguration => 'Configuración del sistema';

  @override
  String get adminThirtyDays => '30 días';

  @override
  String get adminTicketAssignedToYou => 'Ticket asignado a ti';

  @override
  String get adminTicketAssignment => 'Asignación de tickets';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Asignar tickets a agentes de soporte';

  @override
  String get adminTicketClosed => 'Ticket cerrado';

  @override
  String get adminTicketResolved => 'Ticket resuelto';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Configuraciones de niveles guardadas correctamente';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Gestión de niveles';

  @override
  String get adminTierManagementSubtitle =>
      'Configurar límites y funciones de niveles';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Hoy';

  @override
  String get adminTotalMinutes => 'Minutos totales';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminUnassigned => 'Sin asignar';

  @override
  String get adminUnknown => 'Desconocido';

  @override
  String get adminUnlimited => 'Ilimitado';

  @override
  String get adminUnlock => 'Desbloquear';

  @override
  String get adminUnlockAccount => 'Desbloquear cuenta';

  @override
  String get adminUnlockAccountConfirm =>
      '¿Estás seguro de que quieres desbloquear esta cuenta?';

  @override
  String get adminUnresolved => 'Sin resolver';

  @override
  String get adminUploadCsvDescription =>
      'Subir un archivo CSV con direcciones de correo (una por línea o separadas por comas)';

  @override
  String get adminUploadCsvFile => 'Subir archivo CSV';

  @override
  String get adminUploading => 'Subiendo...';

  @override
  String get adminUseVideoCallingFeature => 'Usar la función de videollamada';

  @override
  String get adminUsedMinutes => 'Minutos usados';

  @override
  String get adminUser => 'Usuario';

  @override
  String get adminUserAnalytics => 'Análisis de usuarios';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Ver métricas de participación y crecimiento de usuarios';

  @override
  String get adminUserBalance => 'Saldo del usuario';

  @override
  String get adminUserId => 'ID de usuario';

  @override
  String adminUserIdLabel(Object userId) {
    return 'ID de usuario: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Usuario: $userId...';
  }

  @override
  String get adminUserManagement => 'Gestión de usuarios';

  @override
  String get adminUserModeration => 'Moderación de usuarios';

  @override
  String get adminUserModerationSubtitle =>
      'Gestionar bloqueos y suspensiones de usuarios';

  @override
  String get adminUserReports => 'Reportes de usuarios';

  @override
  String get adminUserReportsSubtitle =>
      'Revisar y gestionar reportes de usuarios';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Usuario: $senderId...';
  }

  @override
  String get adminUserVerifications => 'Verificaciones de usuarios';

  @override
  String get adminUserVerificationsSubtitle =>
      'Aprobar o rechazar solicitudes de verificación de usuarios';

  @override
  String get adminVerificationFilter => 'Filtro de verificación';

  @override
  String get adminVerifications => 'Verificaciones';

  @override
  String get adminVideoChat => 'Videochat';

  @override
  String get adminVideoCoinPackages => 'Paquetes de monedas de vídeo';

  @override
  String get adminVideoCoins => 'Monedas de vídeo';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes minutos';
  }

  @override
  String get adminViewContext => 'Ver contexto';

  @override
  String get adminViewDocument => 'Ver documento';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violación de las normas de la comunidad';

  @override
  String get adminWaiting => 'En espera';

  @override
  String adminWaitingCount(Object count) {
    return 'En espera ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Desafíos semanales';

  @override
  String get adminWelcome => 'Bienvenido, administrador';

  @override
  String get adminXpReward => 'Recompensa de XP';

  @override
  String get ageRange => 'Rango de Edad';

  @override
  String get aiCoachBenefitAllChapters =>
      'Todos los capítulos de aprendizaje desbloqueados';

  @override
  String get aiCoachBenefitFeedback =>
      'Correcciones de gramática y pronunciación en tiempo real';

  @override
  String get aiCoachBenefitPersonalized => 'Ruta de aprendizaje personalizada';

  @override
  String get aiCoachBenefitUnlimited =>
      'Práctica de conversación con IA ilimitada';

  @override
  String get aiCoachLabel => 'Coach IA';

  @override
  String get aiCoachTrialEnded =>
      'Tu prueba gratuita del Coach IA ha terminado.';

  @override
  String get aiCoachUpgradePrompt =>
      'Mejora a Silver, Gold o Platinum para desbloquear.';

  @override
  String get aiCoachUpgradeTitle => 'Mejora para Aprender Más';

  @override
  String get albumNotShared => 'Álbum no compartido';

  @override
  String get albumOption => 'Álbum';

  @override
  String albumRevokedMessage(String username) {
    return '$username revocó el acceso al álbum';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username compartió su álbum contigo';
  }

  @override
  String get allCategoriesFilter => 'Todas';

  @override
  String get allDealBreakersAdded =>
      'Todos los filtros eliminatorios han sido añadidos';

  @override
  String get allLanguagesFilter => 'Todos';

  @override
  String get allPlayersReady => 'Todos los jugadores están listos!';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get appLanguage => 'Idioma de la App';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubre Tu Pareja Perfecta';

  @override
  String get approveVerification => 'Aprobar';

  @override
  String get atLeast8Characters => 'Al menos 8 caracteres';

  @override
  String get atLeastOneNumber => 'Al menos un número';

  @override
  String get atLeastOneSpecialChar => 'Al menos un carácter especial';

  @override
  String get authAppleSignInComingSoon =>
      'Inicio de sesión con Apple disponible próximamente';

  @override
  String get authCancelVerification => '¿Cancelar verificación?';

  @override
  String get authCancelVerificationBody =>
      'Se cerrará tu sesión si cancelas la verificación.';

  @override
  String get authDisableInSettings =>
      'Puedes desactivar esto en Configuración > Seguridad';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Ya existe una cuenta con este correo.';

  @override
  String get authErrorGeneric => 'Ocurrió un error. Inténtalo de nuevo.';

  @override
  String get authErrorInvalidCredentials =>
      'Correo/nickname o contraseña incorrectos. Verifica tus credenciales e inténtalo de nuevo.';

  @override
  String get authErrorInvalidEmail =>
      'Por favor ingresa un correo electrónico válido.';

  @override
  String get authErrorNetworkError =>
      'Sin conexión a internet. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get authErrorUserNotFound =>
      'No se encontró una cuenta con este correo o nickname. Verifica e inténtalo de nuevo, o regístrate.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es muy débil. Usa una contraseña más fuerte.';

  @override
  String get authErrorWrongPassword =>
      'Contraseña incorrecta. Inténtalo de nuevo.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'No se pudo tomar la foto: $error';
  }

  @override
  String get authIdentityVerification => 'Verificación de identidad';

  @override
  String get authPleaseEnterEmail =>
      'Por favor, introduce tu correo electrónico';

  @override
  String get authRetakePhoto => 'Tomar otra foto';

  @override
  String get authSecurityStep =>
      'Este paso de seguridad adicional ayuda a proteger tu cuenta';

  @override
  String get authSelfieInstruction => 'Mira a la cámara y toca para capturar';

  @override
  String get authSignOut => 'Cerrar sesión';

  @override
  String get authSignOutInstead => 'Cerrar sesión en su lugar';

  @override
  String get authStay => 'Permanecer';

  @override
  String get authTakeSelfie => 'Tomar un selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Por favor, tómate un selfie para verificar tu identidad';

  @override
  String get authVerifyAndContinue => 'Verificar y continuar';

  @override
  String get authVerifyWithSelfie =>
      'Por favor, verifica tu identidad con un selfie';

  @override
  String authWelcomeBack(Object name) {
    return '¡Bienvenido/a de vuelta, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Inicio de Sesión Fallido';

  @override
  String get away => 'de distancia';

  @override
  String get awesome => '¡Genial!';

  @override
  String get backToLobby => 'Volver al Vestíbulo';

  @override
  String get badgeLocked => 'Bloqueado';

  @override
  String get badgeUnlocked => 'Desbloqueado';

  @override
  String get achievementUnlockedTitle => '¡LOGRO DESBLOQUEADO!';

  @override
  String get achievementUnlockedAwesome => '¡Genial!';

  @override
  String get achievementRarityCommon => 'COMÚN';

  @override
  String get achievementRarityUncommon => 'POCO COMÚN';

  @override
  String get achievementRarityRare => 'RARO';

  @override
  String get achievementRarityEpic => 'ÉPICO';

  @override
  String get achievementRarityLegendary => 'LEGENDARIO';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

  @override
  String get badges => 'Insignias';

  @override
  String get basic => 'Básico';

  @override
  String get basicInformation => 'Información Básica';

  @override
  String get betterPhotoRequested => 'Mejor foto solicitada';

  @override
  String get bio => 'Biografía';

  @override
  String get bioUpdatedMessage => 'Tu bio de perfil ha sido guardada';

  @override
  String get bioUpdatedTitle => '¡Bio Actualizada!';

  @override
  String get blindDateActivate => 'Activar Modo Cita a Ciegas';

  @override
  String get blindDateDeactivate => 'Desactivar';

  @override
  String get blindDateDeactivateMessage =>
      'Volverás al modo de descubrimiento normal.';

  @override
  String get blindDateDeactivateTitle => '¿Desactivar Modo Cita a Ciegas?';

  @override
  String get blindDateDeactivateTooltip => 'Desactivar Modo Cita a Ciegas';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Revelación instantánea por $cost monedas';
  }

  @override
  String get blindDateFeatureNoPhotos =>
      'Las fotos de perfil no son visibles al inicio';

  @override
  String get blindDateFeaturePersonality =>
      'Enfoque en personalidad e intereses';

  @override
  String get blindDateFeatureUnlock => 'Las fotos se desbloquean al chatear';

  @override
  String get blindDateGetCoins => 'Obtener Monedas';

  @override
  String get blindDateInstantReveal => 'Revelación Instantánea';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return '¿Revelar todas las fotos de esta coincidencia por $cost monedas?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Revelación instantánea ($cost monedas)';
  }

  @override
  String get blindDateInsufficientCoins => 'Monedas Insuficientes';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Necesitas $cost monedas para revelar las fotos al instante.';
  }

  @override
  String get blindDateInterests => 'Intereses';

  @override
  String blindDateKmAway(String distance) {
    return 'a $distance km';
  }

  @override
  String get blindDateLetsExchange => '¡Empieza a conectar!';

  @override
  String get blindDateMatchMessage =>
      '¡Os gustáis mutuamente! Empezad a chatear para revelar vuestras fotos.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total mensajes';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'faltan $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count mensajes hasta la revelación';
  }

  @override
  String get blindDateModeActivated => '¡Modo Cita a Ciegas activado!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Conecta por personalidad, no por apariencia.\nLas fotos se revelan después de $threshold mensajes.';
  }

  @override
  String get blindDateModeTitle => 'Modo Cita a Ciegas';

  @override
  String get blindDateMysteryPerson => 'Persona Misteriosa';

  @override
  String get blindDateNoCandidates => 'No hay candidatos disponibles';

  @override
  String get blindDateNoMatches => 'Aún no hay coincidencias';

  @override
  String blindDatePendingReveal(int count) {
    return 'Revelación Pendiente ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Progreso de Revelación de Fotos';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'Las fotos se revelan después de $threshold mensajes';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return '¡Fotos reveladas! $coinsSpent monedas gastadas.';
  }

  @override
  String get blindDatePhotosRevealedLabel => '¡Fotos reveladas!';

  @override
  String get blindDateReveal => 'Revelar';

  @override
  String blindDateRevealed(int count) {
    return 'Revelados ($count)';
  }

  @override
  String get blindDateRevealedMatch => 'Match Revelado';

  @override
  String get blindDateStartSwiping =>
      '¡Empieza a deslizar para encontrar tu cita a ciegas!';

  @override
  String get blindDateTabDiscover => 'Descubrir';

  @override
  String get blindDateTabMatches => 'Coincidencias';

  @override
  String get blindDateTitle => 'Cita a Ciegas';

  @override
  String get blindDateViewMatch => 'Ver Coincidencia';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonusCoins de bonificación!)';
  }

  @override
  String get boost => 'Impulso';

  @override
  String get boostActivated => '¡Impulso activado por 30 minutos!';

  @override
  String get boostNow => 'Impulsar Ahora';

  @override
  String get boostProfile => 'Impulsar Perfil';

  @override
  String get boosted => '¡IMPULSADO!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Paquete';

  @override
  String get businessCategory => 'Negocios';

  @override
  String get buyCoins => 'Comprar Monedas';

  @override
  String get buyCoinsBtnLabel => 'Comprar Monedas';

  @override
  String get buyPackBtn => 'Comprar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get cannotAccessFeature =>
      'Esta función está disponible después de que tu cuenta sea verificada.';

  @override
  String get cantUndoMatched => 'No se puede deshacer — ¡ya hiciste match!';

  @override
  String get casualCategory => 'Casual';

  @override
  String get casualDating => 'Citas casuales';

  @override
  String get categoryFlashcard => 'Tarjeta';

  @override
  String get categoryLearning => 'Aprendizaje';

  @override
  String get categoryMultilingual => 'Multilingüe';

  @override
  String get categoryName => 'Categoría';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Estacional';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryStreak => 'Racha';

  @override
  String get categoryTranslation => 'Traducción';

  @override
  String get challenges => 'Desafíos';

  @override
  String get changeLocation => 'Cambiar ubicación';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get changePasswordConfirm => 'Confirmar Nueva Contraseña';

  @override
  String get changePasswordCurrent => 'Contraseña Actual';

  @override
  String get changePasswordDescription =>
      'Por seguridad, verifica tu identidad antes de cambiar tu contraseña.';

  @override
  String get changePasswordEmailConfirm =>
      'Confirma tu dirección de correo electrónico';

  @override
  String get changePasswordEmailHint => 'Tu correo electrónico';

  @override
  String get changePasswordEmailMismatch =>
      'El correo no coincide con tu cuenta';

  @override
  String get changePasswordNew => 'Nueva Contraseña';

  @override
  String get changePasswordReauthRequired =>
      'Por favor cierra sesión e inicia sesión nuevamente antes de cambiar tu contraseña';

  @override
  String get changePasswordSubtitle => 'Actualiza la contraseña de tu cuenta';

  @override
  String get changePasswordSuccess => 'Contraseña cambiada exitosamente';

  @override
  String get changePasswordWrongCurrent => 'La contraseña actual es incorrecta';

  @override
  String get chatAddCaption => 'Agregar descripción...';

  @override
  String get chatAddToStarred => 'Agregar a mensajes destacados';

  @override
  String get chatAlreadyInYourLanguage => 'El mensaje ya está en tu idioma';

  @override
  String get chatAttachCamera => 'Cámara';

  @override
  String get chatAttachGallery => 'Galería';

  @override
  String get chatAttachRecord => 'Grabar';

  @override
  String get chatAttachVideo => 'Video';

  @override
  String get chatBlock => 'Bloquear';

  @override
  String chatBlockUser(String name) {
    return 'Bloquear a $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return '¿Estás seguro de que quieres bloquear a $name? Ya no podrán contactarte.';
  }

  @override
  String get chatBlockUserTitle => 'Bloquear Usuario';

  @override
  String get chatCannotBlockAdmin => 'No puedes bloquear a un administrador.';

  @override
  String get chatCannotReportAdmin => 'No puedes reportar a un administrador.';

  @override
  String get chatCategory => 'Categoría';

  @override
  String get chatCategoryAccount => 'Ayuda con la Cuenta';

  @override
  String get chatCategoryBilling => 'Facturación y Pagos';

  @override
  String get chatCategoryFeedback => 'Comentarios';

  @override
  String get chatCategoryGeneral => 'Pregunta General';

  @override
  String get chatCategorySafety => 'Preocupación de Seguridad';

  @override
  String get chatCategoryTechnical => 'Problema Técnico';

  @override
  String get chatCopy => 'Copiar';

  @override
  String get chatCreate => 'Crear';

  @override
  String get chatCreateSupportTicket => 'Crear Ticket de Soporte';

  @override
  String get chatCreateTicket => 'Crear Ticket';

  @override
  String chatDaysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String get chatDelete => 'Eliminar';

  @override
  String get chatDeleteChat => 'Eliminar Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Esto eliminará todos los mensajes para ti y $name. Esta acción no se puede deshacer.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Eliminar Chat para Todos';

  @override
  String get chatDeleteChatForMeMessage =>
      'Esto eliminará el chat solo de tu dispositivo. La otra persona seguirá viendo los mensajes.';

  @override
  String chatDeleteConversationWith(String name) {
    return '¿Eliminar conversación con $name?';
  }

  @override
  String get chatDeleteForBoth => 'Eliminar chat para ambos';

  @override
  String get chatDeleteForBothDescription =>
      'Esto eliminará permanentemente la conversación para ti y la otra persona.';

  @override
  String get chatDeleteForEveryone => 'Eliminar para Todos';

  @override
  String get chatDeleteForMe => 'Eliminar chat para mí';

  @override
  String get chatDeleteForMeDescription =>
      'Esto eliminará la conversación solo de tu lista de chats. La otra persona seguirá viéndola.';

  @override
  String get chatDeletedForBothMessage =>
      'Este chat ha sido eliminado permanentemente';

  @override
  String get chatDeletedForMeMessage =>
      'Este chat ha sido eliminado de tu bandeja';

  @override
  String get chatDeletedTitle => '¡Chat Eliminado!';

  @override
  String get chatDescriptionOptional => 'Descripción (Opcional)';

  @override
  String get chatDetailsHint => 'Proporciona más detalles sobre tu problema...';

  @override
  String get chatDisableTranslation => 'Desactivar traducción';

  @override
  String get chatEnableTranslation => 'Activar traducción';

  @override
  String get chatErrorLoadingTickets => 'Error al cargar los tickets';

  @override
  String get chatFailedToCreateTicket => 'Error al crear el ticket';

  @override
  String get chatFailedToForwardMessage => 'Error al reenviar el mensaje';

  @override
  String get chatFailedToLoadAlbum => 'Error al cargar el álbum';

  @override
  String get chatFailedToLoadConversations =>
      'Error al cargar las conversaciones';

  @override
  String get chatFailedToLoadImage => 'Error al cargar imagen';

  @override
  String get chatFailedToLoadVideo => 'Error al cargar el vídeo';

  @override
  String chatFailedToPickImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Error al seleccionar video: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Error al reportar mensaje: $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Error al revocar el acceso';

  @override
  String get chatFailedToSaveFlashcard => 'Error al guardar la tarjeta';

  @override
  String get chatFailedToShareAlbum => 'Error al compartir el álbum';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Error al subir imagen: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Error al subir video: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Consejos culturales y contexto';

  @override
  String get chatFeatureGrammar =>
      'Retroalimentación gramatical en tiempo real';

  @override
  String get chatFeatureVocabulary => 'Ejercicios de vocabulario';

  @override
  String get chatForward => 'Reenviar';

  @override
  String get chatForwardMessage => 'Reenviar Mensaje';

  @override
  String get chatForwardToChat => 'Reenviar a otro chat';

  @override
  String get chatGrammarSuggestion => 'Sugerencia gramatical';

  @override
  String chatHoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String get chatIcebreakers => 'Rompehielos';

  @override
  String chatIsTyping(String userName) {
    return '$userName está escribiendo';
  }

  @override
  String get chatJustNow => 'Ahora mismo';

  @override
  String get chatLanguagePickerHint =>
      'Elige el idioma en el que quieres leer esta conversación. Todos los mensajes serán traducidos para ti.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Idioma del chat establecido a $language';
  }

  @override
  String get chatLanguages => 'Idiomas';

  @override
  String get chatLearnThis => 'Aprender Esto';

  @override
  String get chatListen => 'Escuchar';

  @override
  String get chatLoadingVideo => 'Cargando video...';

  @override
  String get chatMaybeLater => 'Quizás más tarde';

  @override
  String get chatMediaLimitReached => 'Límite de medios alcanzado';

  @override
  String get chatMessage => 'Mensaje';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Mensaje bloqueado: Contiene $violations. Por tu seguridad, no se permite compartir datos de contacto personales.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Mensaje reenviado a $count conversación(es)';
  }

  @override
  String get chatMessageOptions => 'Opciones de Mensaje';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Mensaje reportado. Lo revisaremos en breve.';

  @override
  String get chatMessageStarred => 'Mensaje destacado';

  @override
  String get chatMessageTranslated => 'Traducido';

  @override
  String get chatMessageUnstarred => 'Mensaje sin destacar';

  @override
  String chatMinutesAgo(int count) {
    return 'hace ${count}min';
  }

  @override
  String get chatMySupportTickets => 'Mis Tickets de Soporte';

  @override
  String get chatNeedHelpCreateTicket =>
      '¿Necesitas ayuda? Crea un nuevo ticket.';

  @override
  String get chatNewTicket => 'Nuevo Ticket';

  @override
  String get chatNoConversationsToForward =>
      'No hay conversaciones para reenviar';

  @override
  String get chatNoMatchingConversations =>
      'No hay conversaciones coincidentes';

  @override
  String get chatNoMessagesToPractice => 'Aún no hay mensajes para practicar';

  @override
  String get chatNoMessagesYet => 'No hay mensajes aún';

  @override
  String get chatNoPrivatePhotos => 'No hay fotos privadas disponibles';

  @override
  String get chatNoSupportTickets => 'Sin Tickets de Soporte';

  @override
  String get chatOffline => 'Desconectado';

  @override
  String get chatOnline => 'En línea';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'En línea hace ${days}d';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'En línea hace ${hours}h';
  }

  @override
  String get chatOnlineJustNow => 'En línea ahora';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'En línea hace ${minutes}min';
  }

  @override
  String get chatOptions => 'Opciones de Chat';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name revocó el acceso al álbum';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name compartió su álbum privado';
  }

  @override
  String get chatPhoto => 'Foto';

  @override
  String get chatPhraseSaved => '¡Frase guardada en tu mazo de tarjetas!';

  @override
  String get chatPleaseEnterSubject => 'Por favor ingresa un asunto';

  @override
  String get chatPractice => 'Practicar';

  @override
  String get chatPracticeMode => 'Modo Práctica';

  @override
  String get chatPracticeTrialStarted =>
      '¡Prueba del modo práctica iniciada! Tienes 3 sesiones gratis.';

  @override
  String get chatPreviewImage => 'Vista previa de Imagen';

  @override
  String get chatPreviewVideo => 'Vista previa de Video';

  @override
  String get chatPronunciationChallenge => 'Desafío de pronunciación';

  @override
  String get chatPronunciationHint =>
      'Toca para escuchar y practica cada frase:';

  @override
  String get chatRemoveFromStarred => 'Quitar de mensajes destacados';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatReplyToMessage => 'Responder a este mensaje';

  @override
  String chatReplyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get chatReportInappropriate => 'Reportar contenido inapropiado';

  @override
  String get chatReportMessage => 'Reportar Mensaje';

  @override
  String get chatReportReasonFakeProfile => 'Perfil falso / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Acoso o intimidación';

  @override
  String get chatReportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get chatReportReasonOther => 'Otro';

  @override
  String get chatReportReasonPersonalInfo => 'Compartir información personal';

  @override
  String get chatReportReasonSpam => 'Spam o estafa';

  @override
  String get chatReportReasonThreatening => 'Comportamiento amenazante';

  @override
  String get chatReportReasonUnderage => 'Usuario menor de edad';

  @override
  String chatReportUser(String name) {
    return 'Reportar a $name';
  }

  @override
  String get chatReportUserTitle => 'Reportar Usuario';

  @override
  String get chatSafetyGotIt => 'Entendido';

  @override
  String get chatSafetySubtitle =>
      'Tu seguridad es nuestra prioridad. Ten en cuenta estos consejos.';

  @override
  String get chatSafetyTip => 'Consejo de Seguridad';

  @override
  String get chatSafetyTip1Description =>
      'No compartas tu dirección, número de teléfono o información financiera.';

  @override
  String get chatSafetyTip1Title => 'Mantén la Info Personal Privada';

  @override
  String get chatSafetyTip2Description =>
      'Nunca envíes dinero a alguien que no hayas conocido en persona.';

  @override
  String get chatSafetyTip2Title => 'Cuidado con Solicitudes de Dinero';

  @override
  String get chatSafetyTip3Description =>
      'Para primeros encuentros, elige siempre un lugar público y bien iluminado.';

  @override
  String get chatSafetyTip3Title => 'Reúnete en Lugares Públicos';

  @override
  String get chatSafetyTip4Description =>
      'Si algo no se siente bien, confía en tu instinto y termina la conversación.';

  @override
  String get chatSafetyTip4Title => 'Confía en Tu Instinto';

  @override
  String get chatSafetyTip5Description =>
      'Usa la función de reporte si alguien te hace sentir incómodo.';

  @override
  String get chatSafetyTip5Title => 'Reporta Comportamiento Sospechoso';

  @override
  String get chatSafetyTitle => 'Chatea de Forma Segura';

  @override
  String get chatSaving => 'Guardando...';

  @override
  String chatSayHiTo(String name) {
    return '¡Saluda a $name!';
  }

  @override
  String get chatScrollUpForOlder =>
      'Desliza hacia arriba para ver mensajes anteriores';

  @override
  String get chatSearchByNameOrNickname => 'Buscar por nombre o @apodo';

  @override
  String get chatSearchConversationsHint => 'Buscar conversaciones...';

  @override
  String get chatSelectPhotos => 'Seleccionar fotos para enviar';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSendAnyway => 'Enviar de todos modos';

  @override
  String get chatSendAttachment => 'Enviar Adjunto';

  @override
  String chatSendCount(int count) {
    return 'Enviar ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Envía un mensaje para iniciar la conversación';

  @override
  String get chatSendMessagesForTips =>
      '¡Envía mensajes para obtener consejos de idiomas!';

  @override
  String get chatSetNativeLanguage =>
      'Primero configura tu idioma nativo en ajustes';

  @override
  String get chatSettingCulturalTips => 'Consejos culturales';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Mostrar contexto cultural de modismos y expresiones';

  @override
  String get chatSettingDifficultyBadges => 'Insignias de dificultad';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Mostrar nivel MCER (A1-C2) en mensajes';

  @override
  String get chatSettingGrammarCheck => 'Revisión gramatical';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Revisar gramática antes de enviar mensajes';

  @override
  String get chatSettingLanguageFlags => 'Banderas de idioma';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Mostrar emoji de bandera junto al texto traducido y original';

  @override
  String get chatSettingPhraseOfDay => 'Frase del día';

  @override
  String get chatSettingPhraseOfDayDesc =>
      'Mostrar una frase diaria para practicar';

  @override
  String get chatSettingPronunciation => 'Pronunciación (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Doble toque para escuchar la pronunciación';

  @override
  String get chatSettingShowOriginal => 'Mostrar texto original';

  @override
  String get chatSettingShowOriginalDesc =>
      'Mostrar el mensaje original debajo de la traducción';

  @override
  String get chatSettingSmartReplies => 'Respuestas inteligentes';

  @override
  String get chatSettingSmartRepliesDesc =>
      'Sugerir respuestas en el idioma objetivo';

  @override
  String get chatSettingTtsTranslation => 'TTS lee traducción';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Leer el texto traducido en lugar del original';

  @override
  String get chatSettingWordBreakdown => 'Desglose de palabras';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Toca mensajes para traducción palabra por palabra';

  @override
  String get chatSettingXpBar => 'Barra de XP y racha';

  @override
  String get chatSettingXpBarDesc =>
      'Mostrar XP de sesión y progreso de palabras';

  @override
  String get chatSettingsSaveAllChats => 'Guardar para todos los chats';

  @override
  String get chatSettingsSaveThisChat => 'Guardar para este chat';

  @override
  String get chatSettingsSavedAllChats =>
      'Ajustes guardados para todos los chats';

  @override
  String get chatSettingsSavedThisChat => 'Ajustes guardados para este chat';

  @override
  String get chatSettingsSubtitle =>
      'Personaliza tu experiencia de aprendizaje en este chat';

  @override
  String get chatSettingsTitle => 'Ajustes del chat';

  @override
  String get chatSomeone => 'Alguien';

  @override
  String get chatStarMessage => 'Destacar Mensaje';

  @override
  String get chatStartSwipingToChat =>
      '¡Desliza y haz match para chatear con personas!';

  @override
  String get chatStatusAssigned => 'Asignado';

  @override
  String get chatStatusAwaitingReply => 'Esperando Respuesta';

  @override
  String get chatStatusClosed => 'Cerrado';

  @override
  String get chatStatusInProgress => 'En Progreso';

  @override
  String get chatStatusOpen => 'Abierto';

  @override
  String get chatStatusResolved => 'Resuelto';

  @override
  String chatStreak(int count) {
    return 'Racha: $count';
  }

  @override
  String get chatSubject => 'Asunto';

  @override
  String get chatSubjectHint => 'Breve descripción de tu problema';

  @override
  String get chatSupportAddAttachment => 'Agregar Adjunto';

  @override
  String get chatSupportAddCaptionOptional =>
      'Agregar descripción (opcional)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agente: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agente';

  @override
  String get chatSupportCategory => 'Categoría';

  @override
  String get chatSupportClose => 'Cerrar';

  @override
  String chatSupportDaysAgo(int days) {
    return 'hace ${days}d';
  }

  @override
  String get chatSupportErrorLoading => 'Error al cargar mensajes';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Error al reabrir ticket: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Error al enviar mensaje: $error';
  }

  @override
  String get chatSupportGeneral => 'General';

  @override
  String get chatSupportGeneralSupport => 'Soporte General';

  @override
  String chatSupportHoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String get chatSupportJustNow => 'Ahora mismo';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'hace ${minutes}min';
  }

  @override
  String get chatSupportReopenTicket =>
      '¿Necesitas más ayuda? Toca para reabrir';

  @override
  String get chatSupportStartMessage =>
      'Envía un mensaje para iniciar la conversación.\nNuestro equipo responderá lo antes posible.';

  @override
  String get chatSupportStatus => 'Estado';

  @override
  String get chatSupportStatusClosed => 'Cerrado';

  @override
  String get chatSupportStatusDefault => 'Soporte';

  @override
  String get chatSupportStatusOpen => 'Abierto';

  @override
  String get chatSupportStatusPending => 'Pendiente';

  @override
  String get chatSupportStatusResolved => 'Resuelto';

  @override
  String get chatSupportSubject => 'Asunto';

  @override
  String get chatSupportTicketCreated => 'Ticket Creado';

  @override
  String get chatSupportTicketId => 'ID del Ticket';

  @override
  String get chatSupportTicketInfo => 'Información del Ticket';

  @override
  String get chatSupportTicketReopened =>
      'Ticket reabierto. Ya puedes enviar un mensaje.';

  @override
  String get chatSupportTicketResolved => 'Este ticket ha sido resuelto';

  @override
  String get chatSupportTicketStart => 'Inicio del Ticket';

  @override
  String get chatSupportTitle => 'Soporte GreenGo';

  @override
  String get chatSupportTypeMessage => 'Escribe tu mensaje...';

  @override
  String get chatSupportWaitingAssignment => 'Esperando asignación';

  @override
  String get chatSupportWelcome => 'Bienvenido al Soporte';

  @override
  String get chatTapToView => 'Toca para ver';

  @override
  String get chatTapToViewAlbum => 'Toca para ver el álbum';

  @override
  String get chatTranslate => 'Traducir';

  @override
  String get chatTranslated => 'Traducido';

  @override
  String get chatTranslating => 'Traduciendo...';

  @override
  String get chatTranslationDisabled => 'Traducción desactivada';

  @override
  String get chatTranslationEnabled => 'Traducción activada';

  @override
  String get chatTranslationFailed => 'Traducción fallida. Inténtalo de nuevo.';

  @override
  String get chatTrialExpired => 'Tu prueba gratuita ha expirado.';

  @override
  String get chatTtsComingSoon => '¡Texto a voz próximamente!';

  @override
  String get chatTyping => 'escribiendo...';

  @override
  String get chatUnableToForward => 'No se puede reenviar el mensaje';

  @override
  String get chatUnknown => 'Desconocido';

  @override
  String get chatUnstarMessage => 'Quitar Destacado';

  @override
  String get chatUpgrade => 'Mejorar';

  @override
  String get chatUpgradePracticeMode =>
      'Mejora a Silver VIP o superior para seguir practicando idiomas en tus chats.';

  @override
  String get chatUploading => 'Subiendo...';

  @override
  String get chatUseCorrection => 'Usar corrección';

  @override
  String chatUserBlocked(String name) {
    return '$name ha sido bloqueado';
  }

  @override
  String get chatUserReported =>
      'Usuario reportado. Revisaremos tu reporte en breve.';

  @override
  String get chatVideo => 'Vídeo';

  @override
  String get chatVideoPlayer => 'Reproductor de Video';

  @override
  String get chatVideoTooLarge =>
      'Video demasiado grande. El tamaño máximo es 50MB.';

  @override
  String get chatWhyReportMessage => '¿Por qué reportas este mensaje?';

  @override
  String chatWhyReportUser(String name) {
    return '¿Por qué reportas a $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Chatear con $name';
  }

  @override
  String chatWords(int count) {
    return '$count palabras';
  }

  @override
  String get chatYou => 'Tú';

  @override
  String get chatYouRevokedAlbum => 'Revocaste el acceso al álbum';

  @override
  String get chatYouSharedAlbum => 'Compartiste tu álbum privado';

  @override
  String get chatYourLanguage => 'Tu idioma';

  @override
  String get checkBackLater =>
      'Vuelve más tarde para ver nuevas personas, o ajusta tus preferencias';

  @override
  String get chooseCorrectAnswer => 'Elige la respuesta correcta';

  @override
  String get chooseFromGallery => 'Elegir de la Galería';

  @override
  String get chooseGame => 'Elige un Juego';

  @override
  String get claimReward => 'Reclamar Recompensa';

  @override
  String get claimRewardBtn => 'Reclamar';

  @override
  String get clearFilters => 'Limpiar Filtros';

  @override
  String get close => 'Cerrar';

  @override
  String get coins => 'Monedas';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins monedas añadidas a tu cuenta$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Todas las Transacciones';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Monedas';
  }

  @override
  String coinsAmountVideoMinutes(Object amount) {
    return '$amount Minutos de Video';
  }

  @override
  String get coinsApply => 'Aplicar';

  @override
  String coinsBalance(Object balance) {
    return 'Saldo: $balance';
  }

  @override
  String coinsBonusCoins(Object amount) {
    return '+$amount monedas de bonificacion';
  }

  @override
  String get coinsCancelLabel => 'Cancelar';

  @override
  String get coinsConfirmPurchase => 'Confirmar Compra';

  @override
  String coinsCost(int amount) {
    return '$amount monedas';
  }

  @override
  String get coinsCreditsOnly => 'Solo Créditos';

  @override
  String get coinsDebitsOnly => 'Solo Débitos';

  @override
  String get coinsEnterReceiverId => 'Ingresa el ID del receptor';

  @override
  String coinsExpiring(Object count) {
    return '$count por vencer';
  }

  @override
  String get coinsFilterTransactions => 'Filtrar Transacciones';

  @override
  String coinsGiftAccepted(Object amount) {
    return '¡$amount monedas aceptadas!';
  }

  @override
  String get coinsGiftDeclined => 'Regalo rechazado';

  @override
  String get coinsGiftSendFailed => 'Error al enviar el regalo';

  @override
  String coinsGiftSent(Object amount) {
    return '¡Regalo de $amount monedas enviado!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Monedas insuficientes';

  @override
  String get coinsLabel => 'Monedas';

  @override
  String get coinsMessageLabel => 'Mensaje (opcional)';

  @override
  String get coinsMins => 'min';

  @override
  String get coinsNoTransactionsYet => 'Sin transacciones aun';

  @override
  String get coinsPendingGifts => 'Regalos Pendientes';

  @override
  String get coinsPopular => 'POPULAR';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Comprar $totalCoins monedas por $price?';
  }

  @override
  String get coinsPurchaseFailed => 'Compra fallida';

  @override
  String get coinsPurchaseLabel => 'Comprar';

  @override
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Comprar $totalMinutes minutos de video por $price?';
  }

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return '¡$totalCoins monedas compradas exitosamente!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return '¡$totalMinutes minutos de video comprados exitosamente!';
  }

  @override
  String get coinsReceiverIdLabel => 'ID del Receptor';

  @override
  String coinsRequired(int amount) {
    return '$amount monedas requeridas';
  }

  @override
  String get coinsRetry => 'Reintentar';

  @override
  String get coinsSelectAmount => 'Seleccionar Cantidad';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Enviar $amount Monedas';
  }

  @override
  String get coinsSendGift => 'Enviar Regalo';

  @override
  String get coinsSent => '¡Monedas enviadas con éxito!';

  @override
  String get coinsShareCoins => 'Comparte monedas con alguien especial';

  @override
  String get coinsShopLabel => 'Tienda';

  @override
  String get coinsTabCoins => 'Monedas';

  @override
  String get coinsTabGifts => 'Regalos';

  @override
  String get coinsTabVideoCoins => 'Monedas de Video';

  @override
  String get coinsToday => 'Hoy';

  @override
  String get coinsTransactionHistory => 'Historial de Transacciones';

  @override
  String get coinsTransactionsAppearHere =>
      'Tus transacciones de monedas apareceran aqui';

  @override
  String get coinsUnlockPremium => 'Desbloquea funciones premium';

  @override
  String get coinsVideoCallMatches => 'Videollamada con tus matches';

  @override
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minuto de videollamada';

  @override
  String get coinsVideoMin => 'Video Min';

  @override
  String get coinsVideoMinutes => 'Minutos de Video';

  @override
  String get coinsYesterday => 'Ayer';

  @override
  String get comingSoonLabel => 'Próximamente';

  @override
  String get communitiesAddTag => 'Agregar etiqueta';

  @override
  String get communitiesAdjustSearch =>
      'Intenta ajustar tu busqueda o filtros.';

  @override
  String get communitiesAllCommunities => 'Todas las Comunidades';

  @override
  String get communitiesAllFilter => 'Todas';

  @override
  String get communitiesAnyoneCanJoin => 'Cualquiera puede unirse';

  @override
  String get communitiesBeFirstToSay => 'Se el primero en decir algo!';

  @override
  String get communitiesCancelLabel => 'Cancelar';

  @override
  String get communitiesCityLabel => 'Ciudad';

  @override
  String get communitiesCityTipLabel => 'Consejo de Ciudad';

  @override
  String get communitiesCityTipUpper => 'CONSEJO DE CIUDAD';

  @override
  String get communitiesCommunityInfo => 'Info de Comunidad';

  @override
  String get communitiesCommunityName => 'Nombre de Comunidad';

  @override
  String get communitiesCommunityType => 'Tipo de Comunidad';

  @override
  String get communitiesCountryLabel => 'Pais';

  @override
  String get communitiesCreateAction => 'Crear';

  @override
  String get communitiesCreateCommunity => 'Crear Comunidad';

  @override
  String get communitiesCreateCommunityAction => 'Crear Comunidad';

  @override
  String get communitiesCreateLabel => 'Crear';

  @override
  String get communitiesCreateLanguageCircle => 'Crear Circulo de Idiomas';

  @override
  String get communitiesCreated => '¡Comunidad creada!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Creado por $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Creado';

  @override
  String get communitiesCulturalFactLabel => 'Dato Cultural';

  @override
  String get communitiesCulturalFactUpper => 'DATO CULTURAL';

  @override
  String get communitiesDescription => 'Descripcion';

  @override
  String get communitiesDescriptionHint => 'De que trata esta comunidad?';

  @override
  String get communitiesDescriptionLabel => 'Descripcion';

  @override
  String get communitiesDescriptionMinLength =>
      'La descripcion debe tener al menos 10 caracteres';

  @override
  String get communitiesDescriptionRequired =>
      'Por favor ingresa una descripcion';

  @override
  String get communitiesDiscoverCommunities => 'Descubrir Comunidades';

  @override
  String get communitiesEditLabel => 'Editar';

  @override
  String get communitiesGuide => 'Guia';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Solo con invitacion';

  @override
  String get communitiesJoinCommunity => 'Unirse a la Comunidad';

  @override
  String get communitiesJoinPrompt =>
      'Unete a comunidades para conectar con personas que comparten tus intereses e idiomas.';

  @override
  String get communitiesJoined => '¡Te uniste a la comunidad!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Los circulos de idiomas apareceran aqui cuando esten disponibles. Crea uno para empezar!';

  @override
  String get communitiesLanguageTipLabel => 'Consejo de Idioma';

  @override
  String get communitiesLanguageTipUpper => 'CONSEJO DE IDIOMA';

  @override
  String get communitiesLanguages => 'Idiomas';

  @override
  String get communitiesLanguagesLabel => 'Idiomas';

  @override
  String get communitiesLeaveCommunity => 'Abandonar Comunidad';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Estas seguro de que quieres abandonar \"$name\"?';
  }

  @override
  String get communitiesLeaveLabel => 'Abandonar';

  @override
  String get communitiesLeaveTitle => 'Abandonar Comunidad';

  @override
  String get communitiesLocation => 'Ubicacion';

  @override
  String get communitiesLocationLabel => 'Ubicacion';

  @override
  String communitiesMembersCount(Object count) {
    return '$count miembros';
  }

  @override
  String get communitiesMembersStatLabel => 'Miembros';

  @override
  String get communitiesMembersTitle => 'Miembros';

  @override
  String get communitiesNameHint => 'ej., Aprendices de Espanol Madrid';

  @override
  String get communitiesNameMinLength =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get communitiesNameRequired => 'Por favor ingresa un nombre';

  @override
  String get communitiesNoCommunities => 'Sin Comunidades Aun';

  @override
  String get communitiesNoCommunitiesFound => 'No se Encontraron Comunidades';

  @override
  String get communitiesNoLanguageCircles => 'Sin Circulos de Idiomas';

  @override
  String get communitiesNoMessagesYet => 'Sin mensajes aun';

  @override
  String get communitiesPreview => 'Vista Previa';

  @override
  String get communitiesPreviewSubtitle =>
      'Asi se vera tu comunidad para otros.';

  @override
  String get communitiesPrivate => 'Privada';

  @override
  String get communitiesPublic => 'Publica';

  @override
  String get communitiesRecommendedForYou => 'Recomendado para Ti';

  @override
  String get communitiesSearchHint => 'Buscar comunidades...';

  @override
  String get communitiesShareCityTip => 'Comparte un consejo de ciudad...';

  @override
  String get communitiesShareCulturalFact => 'Comparte un dato cultural...';

  @override
  String get communitiesShareLanguageTip => 'Comparte un consejo de idioma...';

  @override
  String get communitiesStats => 'Estadisticas';

  @override
  String get communitiesTabDiscover => 'Descubrir';

  @override
  String get communitiesTabLanguageCircles => 'Círculos de Idiomas';

  @override
  String get communitiesTabMyGroups => 'Mis Grupos';

  @override
  String get communitiesTags => 'Etiquetas';

  @override
  String get communitiesTagsLabel => 'Etiquetas';

  @override
  String get communitiesTextLabel => 'Texto';

  @override
  String get communitiesTitle => 'Comunidades';

  @override
  String get communitiesTypeAMessage => 'Escribe un mensaje...';

  @override
  String get communitiesUnableToLoad => 'No se pudo cargar la comunidad';

  @override
  String get compatibilityLabel => 'Compatibilidad';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compatible';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      '¡Completa logros para obtener insignias!';

  @override
  String get completeProfile => 'Completa Tu Perfil';

  @override
  String get complimentsCategory => 'Cumplidos';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get confirmLocation => 'Confirmar ubicación';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get confirmPasswordRequired => 'Por favor confirme su contraseña';

  @override
  String get connectSocialAccounts => 'Conecta tus cuentas sociales';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get connectionErrorMessage =>
      'Verifica tu conexión a internet e inténtalo de nuevo.';

  @override
  String get connectionErrorTitle => 'Sin Conexión a Internet';

  @override
  String get consentRequired => 'Consentimientos Obligatorios';

  @override
  String get consentRequiredError =>
      'Debes aceptar la Política de Privacidad y los Términos y Condiciones para registrarte';

  @override
  String get contactSupport => 'Contactar Soporte';

  @override
  String get continueLearningBtn => 'Continuar';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get conversationCategory => 'Conversación';

  @override
  String get correctAnswer => '¡Correcto!';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get culturalCategory => 'Cultural';

  @override
  String get culturalExchangeBeFirstTip =>
      '¡Sé el primero en compartir un consejo cultural!';

  @override
  String get culturalExchangeCategory => 'Categoría';

  @override
  String get culturalExchangeCommunityTips => 'Consejos de la comunidad';

  @override
  String get culturalExchangeCountry => 'País';

  @override
  String get culturalExchangeCountryHint => 'p. ej., Japón, Brasil, Francia';

  @override
  String get culturalExchangeCountrySpotlight => 'País destacado';

  @override
  String get culturalExchangeDailyInsight => 'Información cultural diaria';

  @override
  String get culturalExchangeDatingEtiquette => 'Etiqueta para citas';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Guía de etiqueta para citas';

  @override
  String get culturalExchangeLoadingCountries => 'Cargando países...';

  @override
  String get culturalExchangeNoTips => 'Aún no hay consejos';

  @override
  String get culturalExchangeShareCulturalTip =>
      'Compartir un consejo cultural';

  @override
  String get culturalExchangeShareTip => 'Compartir consejo';

  @override
  String get culturalExchangeSubmitTip => 'Enviar consejo';

  @override
  String get culturalExchangeTipTitle => 'Título';

  @override
  String get culturalExchangeTipTitleHint =>
      'Dale a tu consejo un título llamativo';

  @override
  String get culturalExchangeTitle => 'Intercambio cultural';

  @override
  String get culturalExchangeViewAll => 'Ver todo';

  @override
  String get culturalExchangeYourTip => 'Tu consejo';

  @override
  String get culturalExchangeYourTipHint =>
      'Comparte tu conocimiento cultural...';

  @override
  String get dailyChallengesSubtitle =>
      'Completa desafios para obtener recompensas';

  @override
  String get dailyChallengesTitle => 'Desafíos Diarios';

  @override
  String dailyLimitReached(int limit) {
    return 'Límite diario de $limit alcanzado';
  }

  @override
  String get dailyMessages => 'Mensajes Diarios';

  @override
  String get dailyRewardHeader => 'Recompensa Diaria';

  @override
  String get dailySwipeLimitReached =>
      'Límite diario de swipes alcanzado. ¡Mejora para más swipes!';

  @override
  String get dailySwipes => 'Deslizamientos Diarios';

  @override
  String get dataExportSentToEmail =>
      'Exportación de datos enviada a tu correo';

  @override
  String get dateOfBirth => 'Fecha de Nacimiento';

  @override
  String get datePlanningCategory => 'Planificar Cita';

  @override
  String get dateSchedulerAccept => 'Aceptar';

  @override
  String get dateSchedulerCancelConfirm =>
      '¿Estás seguro de que quieres cancelar esta cita?';

  @override
  String get dateSchedulerCancelTitle => 'Cancelar Cita';

  @override
  String get dateSchedulerConfirmed => '¡Cita confirmada!';

  @override
  String get dateSchedulerDecline => 'Rechazar';

  @override
  String get dateSchedulerEnterTitle => 'Por favor ingresa un título';

  @override
  String get dateSchedulerKeepDate => 'Mantener Cita';

  @override
  String get dateSchedulerNotesLabel => 'Notas (opcional)';

  @override
  String get dateSchedulerPlanningHint => 'ej., Café, Cena, Película...';

  @override
  String get dateSchedulerReasonLabel => 'Motivo (opcional)';

  @override
  String get dateSchedulerReschedule => 'Reprogramar';

  @override
  String get dateSchedulerRescheduleTitle => 'Reprogramar Cita';

  @override
  String get dateSchedulerSchedule => 'Programar';

  @override
  String get dateSchedulerScheduled => '¡Cita programada!';

  @override
  String get dateSchedulerTabPast => 'Pasadas';

  @override
  String get dateSchedulerTabPending => 'Pendientes';

  @override
  String get dateSchedulerTabUpcoming => 'Próximas';

  @override
  String get dateSchedulerTitle => 'Mis Citas';

  @override
  String get dateSchedulerWhatPlanning => '¿Qué estás planeando?';

  @override
  String dayNumber(int day) {
    return 'Día $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count días de racha';
  }

  @override
  String dayStreakLabel(int days) {
    return '¡Racha de $days Días!';
  }

  @override
  String get days => 'Días';

  @override
  String daysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get deleteAccountConfirmation =>
      '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y todos tus datos serán eliminados permanentemente.';

  @override
  String get details => 'Detalles';

  @override
  String get difficultyLabel => 'Dificultad';

  @override
  String directMessageCost(int cost) {
    return 'Los mensajes directos cuestan $cost monedas. Quieres comprar mas monedas?';
  }

  @override
  String get discover => 'Red';

  @override
  String discoveryError(String error) {
    return 'Error: $error';
  }

  @override
  String get discoveryFilterAll => 'Todos';

  @override
  String get discoveryFilterGuides => 'Guias';

  @override
  String get discoveryFilterLiked => 'Conectados';

  @override
  String get discoveryFilterMatches => 'Matches';

  @override
  String get discoveryFilterPassed => 'Rechazados';

  @override
  String get discoveryFilterSkipped => 'Explorados';

  @override
  String get discoveryFilterSuperLiked => 'Prioritario';

  @override
  String get discoveryFilterTravelers => 'Viajeros';

  @override
  String get discoveryPreferencesTitle => 'Preferencias de Descubrimiento';

  @override
  String get discoveryPreferencesTooltip => 'Preferencias de Descubrimiento';

  @override
  String get discoverySwitchToGrid => 'Cambiar a modo cuadrícula';

  @override
  String get discoverySwitchToSwipe => 'Cambiar a modo deslizar';

  @override
  String get dismiss => 'Cerrar';

  @override
  String get distance => 'Distancia';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Documento no disponible';

  @override
  String get documentNotAvailableDescription =>
      'Este documento aun no esta disponible en tu idioma.';

  @override
  String get done => 'Listo';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get download => 'Descargar';

  @override
  String downloadProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'Descargando $language...';
  }

  @override
  String get downloadingTranslationData => 'Descargando Datos de Traducción';

  @override
  String get edit => 'Editar';

  @override
  String get editInterests => 'Editar Intereses';

  @override
  String get editNickname => 'Editar Apodo';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get editVoiceComingSoon => 'Editar voz próximamente';

  @override
  String get education => 'Educación';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get emailInvalid => 'Por favor ingresa un correo electrónico válido';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get emergencyCategory => 'Emergencia';

  @override
  String get emptyStateErrorMessage =>
      'No pudimos cargar este contenido. Por favor inténtalo de nuevo.';

  @override
  String get emptyStateErrorTitle => 'Algo salió mal';

  @override
  String get emptyStateNoInternetMessage =>
      'Por favor revisa tu conexión a internet e inténtalo de nuevo.';

  @override
  String get emptyStateNoInternetTitle => 'Sin conexión';

  @override
  String get emptyStateNoLikesMessage =>
      '¡Completa tu perfil para recibir más likes!';

  @override
  String get emptyStateNoLikesTitle => 'Aún no hay likes';

  @override
  String get emptyStateNoMatchesMessage =>
      '¡Empieza a deslizar para encontrar tu pareja perfecta!';

  @override
  String get emptyStateNoMatchesTitle => 'Aún no hay coincidencias';

  @override
  String get emptyStateNoMessagesMessage =>
      'Cuando hagas match con alguien, podrás chatear aquí.';

  @override
  String get emptyStateNoMessagesTitle => 'Sin mensajes';

  @override
  String get emptyStateNoNotificationsMessage =>
      'No tienes notificaciones nuevas.';

  @override
  String get emptyStateNoNotificationsTitle => '¡Estás al día!';

  @override
  String get emptyStateNoResultsMessage =>
      'Intenta ajustar tu búsqueda o filtros.';

  @override
  String get emptyStateNoResultsTitle => 'Sin resultados';

  @override
  String get enableAutoTranslation => 'Activar Traducción Automática';

  @override
  String get enableNotifications => 'Habilitar Notificaciones';

  @override
  String get enterAmount => 'Ingresa la cantidad';

  @override
  String get enterNickname => 'Ingresa apodo';

  @override
  String get enterNicknameHint => 'Ingresa el apodo';

  @override
  String get enterNicknameToFind =>
      'Ingresa un apodo para encontrar a alguien directamente';

  @override
  String get enterRejectionReason => 'Ingresa la razón del rechazo';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get errorLoadingDocument => 'Error al cargar el documento';

  @override
  String get errorSearchingTryAgain => 'Error al buscar. Inténtalo de nuevo.';

  @override
  String get eventsAboutThisEvent => 'Sobre este evento';

  @override
  String get eventsApplyFilters => 'Aplicar Filtros';

  @override
  String get eventsAttendees => 'Asistentes';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max asistiendo';
  }

  @override
  String get eventsBeFirstToSay => 'Se el primero en decir algo!';

  @override
  String get eventsCategory => 'Categoria';

  @override
  String get eventsChatWithAttendees => 'Chatea con otros asistentes';

  @override
  String get eventsCheckBackLater =>
      'Vuelve mas tarde o crea tu propio evento!';

  @override
  String get eventsCreateEvent => 'Crear Evento';

  @override
  String get eventsCreatedSuccessfully => '¡Evento creado exitosamente!';

  @override
  String get eventsDateRange => 'Rango de Fechas';

  @override
  String get eventsDeleted => 'Evento eliminado';

  @override
  String get eventsDescription => 'Descripcion';

  @override
  String get eventsDistance => 'Distancia';

  @override
  String get eventsEndDateTime => 'Fecha y Hora de Fin';

  @override
  String get eventsErrorLoadingMessages => 'Error al cargar los mensajes';

  @override
  String get eventsEventFull => 'Evento Lleno';

  @override
  String get eventsEventTitle => 'Titulo del Evento';

  @override
  String get eventsFilterEvents => 'Filtrar Eventos';

  @override
  String get eventsFreeEvent => 'Evento Gratuito';

  @override
  String get eventsFreeLabel => 'GRATIS';

  @override
  String get eventsFullLabel => 'Lleno';

  @override
  String eventsGoing(Object count) {
    return '$count asistiran';
  }

  @override
  String get eventsGoingLabel => 'Ire';

  @override
  String get eventsGroupChatTooltip => 'Chat Grupal del Evento';

  @override
  String get eventsJoinEvent => 'Unirse al Evento';

  @override
  String get eventsJoinLabel => 'Unirse';

  @override
  String eventsKmAwayFormat(String km) {
    return 'a $km km';
  }

  @override
  String get eventsLanguageExchange => 'Intercambio de Idiomas';

  @override
  String get eventsLanguagePairs => 'Pares de Idiomas (ej., Espanol ↔ Ingles)';

  @override
  String eventsLanguages(String languages) {
    return 'Idiomas: $languages';
  }

  @override
  String get eventsLocation => 'Ubicacion';

  @override
  String eventsMAwayFormat(Object meters) {
    return 'a $meters m';
  }

  @override
  String get eventsMaxAttendees => 'Max. Asistentes';

  @override
  String get eventsNoAttendeesYet =>
      'Sin asistentes aun. Se el primero en unirte!';

  @override
  String get eventsNoEventsFound => 'No se encontraron eventos';

  @override
  String get eventsNoMessagesYet => 'Sin mensajes aun';

  @override
  String get eventsRequired => 'Requerido';

  @override
  String get eventsRsvpCancelled => 'Asistencia cancelada';

  @override
  String get eventsRsvpUpdated => 'Asistencia actualizada!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count lugares disponibles';
  }

  @override
  String get eventsStartDateTime => 'Fecha y Hora de Inicio';

  @override
  String get eventsTabMyEvents => 'Mis Eventos';

  @override
  String get eventsTabNearby => 'Cercanos';

  @override
  String get eventsTabUpcoming => 'Próximos';

  @override
  String get eventsThisMonth => 'Este Mes';

  @override
  String get eventsThisWeekFilter => 'Esta Semana';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get eventsToday => 'Hoy';

  @override
  String get eventsTypeAMessage => 'Escribe un mensaje...';

  @override
  String get exit => 'Salir';

  @override
  String get exitApp => '¿Salir de la App?';

  @override
  String get exitAppConfirmation =>
      '¿Estás seguro de que quieres salir de GreenGo?';

  @override
  String get exploreLanguages => 'Explorar Idiomas';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km de distancia';
  }

  @override
  String get exploreMapError => 'No se pudieron cargar los usuarios cercanos';

  @override
  String get exploreMapExpandRadius => 'Ampliar radio';

  @override
  String get exploreMapExpandRadiusHint =>
      'Intenta aumentar tu radio de búsqueda para encontrar más personas.';

  @override
  String get exploreMapNearbyUser => 'Usuario cercano';

  @override
  String get exploreMapNoOneNearby => 'Nadie cerca';

  @override
  String get exploreMapOnlineNow => 'En línea ahora';

  @override
  String get exploreMapPeopleNearYou => 'Personas cerca de ti';

  @override
  String get exploreMapRadius => 'Radio:';

  @override
  String get exploreMapVisible => 'Visible';

  @override
  String get exportMyDataGDPR => 'Exportar Mis Datos (GDPR)';

  @override
  String get exportingYourData => 'Exportando tus datos...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Extender ($cost monedas)';
  }

  @override
  String get extendTooltip => 'Extender';

  @override
  String failedToDownloadModel(String language) {
    return 'Error al descargar el modelo de $language';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Error al guardar preferencias';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Función no disponible en $tier';
  }

  @override
  String get fillCategories => 'Completa todas las categorías';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Directo';

  @override
  String get filterMessaged => 'Con Mensajes';

  @override
  String get filterNew => 'Nuevos';

  @override
  String get filterNewMessages => 'Nuevos';

  @override
  String get filterNotReplied => 'Sin respuesta';

  @override
  String filteredFromTotal(int total) {
    return 'Filtrado de $total';
  }

  @override
  String get filters => 'Filtros';

  @override
  String get finish => 'Finalizar';

  @override
  String get firstName => 'Nombre';

  @override
  String get firstTo30Wins => '¡El primero en llegar a 30 gana!';

  @override
  String get flashcardReviewLabel => 'Tarjetas';

  @override
  String get flirtyCategory => 'Coqueto';

  @override
  String get foodDiningCategory => 'Comida y Restaurantes';

  @override
  String get forgotPassword => '¿Olvidaste tu Contraseña?';

  @override
  String freeActionsRemaining(int count) {
    return '$count acciones gratuitas restantes hoy';
  }

  @override
  String get friendship => 'Amistad';

  @override
  String get gameAbandon => 'Abandonar';

  @override
  String get gameAbandonLoseMessage => 'Perderás esta partida si te vas ahora.';

  @override
  String get gameAbandonProgressMessage =>
      'Perderás tu progreso y volverás al lobby.';

  @override
  String get gameAbandonTitle => '¿Abandonar partida?';

  @override
  String get gameAbandonTooltip => 'Abandonar partida';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Escribe una palabra que empiece con \"$letter\"...';
  }

  @override
  String get gameCategoriesFilled => 'completada';

  @override
  String get gameCategoriesNewLetter => '¡Nueva Letra!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — empieza con \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill => '¡Toca una categoría para completarla!';

  @override
  String get gameCategoriesTimesUp =>
      '¡Se acabó el tiempo! Esperando la siguiente ronda...';

  @override
  String get gameCategoriesTitle => 'Categorías';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      '¡Palabra ya usada en otra categoría!';

  @override
  String get gameCategoryAnimals => 'Animales';

  @override
  String get gameCategoryClothing => 'Ropa';

  @override
  String get gameCategoryColors => 'Colores';

  @override
  String get gameCategoryCountries => 'Países';

  @override
  String get gameCategoryFood => 'Comida';

  @override
  String get gameCategoryNature => 'Naturaleza';

  @override
  String get gameCategoryProfessions => 'Profesiones';

  @override
  String get gameCategorySports => 'Deportes';

  @override
  String get gameCategoryTransport => 'Transporte';

  @override
  String get gameChainBreak => '¡CADENA ROTA!';

  @override
  String get gameChainNextMustStartWith =>
      'La siguiente palabra debe empezar con: ';

  @override
  String get gameChainNoWordsYet => '¡Aún no hay palabras!';

  @override
  String get gameChainStartWithAnyWord =>
      'Comienza la cadena con cualquier palabra';

  @override
  String get gameChainTitle => 'Cadena de Vocabulario';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Escribe una palabra que empiece con \"$letter\"...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Escribe una palabra para iniciar la cadena...';

  @override
  String gameChainWordsChained(int count) {
    return '$count palabras encadenadas';
  }

  @override
  String get gameCorrect => '¡Correcto!';

  @override
  String get gameDefaultPlayerName => 'Jugador';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff adelante';
  }

  @override
  String get gameGrammarDuelAnswered => 'Respondido';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff atrás';
  }

  @override
  String get gameGrammarDuelFast => '¡RÁPIDO!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'PREGUNTA DE GRAMÁTICA';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '¡+$points puntos!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return '¡x$count racha!';
  }

  @override
  String get gameGrammarDuelThinking => 'Pensando...';

  @override
  String get gameGrammarDuelTitle => 'Duelo de Gramática';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => '¡Respuesta incorrecta!';

  @override
  String get gameInvalidAnswer => '¡Inválido!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Portugués Brasileño';

  @override
  String get gameLanguageEnglish => 'Inglés';

  @override
  String get gameLanguageFrench => 'Francés';

  @override
  String get gameLanguageGerman => 'Alemán';

  @override
  String get gameLanguageItalian => 'Italiano';

  @override
  String get gameLanguageJapanese => 'Japonés';

  @override
  String get gameLanguagePortuguese => 'Portugués';

  @override
  String get gameLanguageSpanish => 'Español';

  @override
  String get gameLeave => 'Salir';

  @override
  String get gameOpponent => 'Oponente';

  @override
  String get gameOver => 'Fin del Juego';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Intento $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      '¡No puedes usar la palabra en tu pista!';

  @override
  String get gamePictureGuessClues => 'PISTAS';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count pista(s) enviada(s)';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return '¡Correcto! +$points puntos';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      '¡Correcto! Esperando a que termine la ronda...';

  @override
  String get gamePictureGuessDescriber => 'DESCRIPTOR';

  @override
  String get gamePictureGuessDescriberRules =>
      'Da pistas para que los demás adivinen. ¡Sin traducciones directas ni pistas de ortografía!';

  @override
  String get gamePictureGuessGuessTheWord => '¡Adivina la palabra!';

  @override
  String get gamePictureGuessGuessTheWordUpper => '¡ADIVINA LA PALABRA!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Sin más intentos — esperando a que termine la ronda';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Sin más intentos en esta ronda';

  @override
  String get gamePictureGuessTheWordWas => 'La palabra era:';

  @override
  String get gamePictureGuessTitle => 'Adivina la Imagen';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Escribe una pista (¡sin traducciones directas!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Escribe tu respuesta... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'Esperando pistas...';

  @override
  String get gamePictureGuessWaitingForOthers => 'Esperando a los demás...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Respuesta incorrecta: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => '¡Eres el DESCRIPTOR!';

  @override
  String get gamePictureGuessYourWord => 'TU PALABRA';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      '¡Respuesta enviada! Esperando a los demás...';

  @override
  String get gamePlayCategoriesHeader => 'CATEGORÍAS';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Categoría: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return '¡Correcto! +$points pts';
  }

  @override
  String get gamePlayDescribeThisWord => '¡DESCRIBE ESTA PALABRA!';

  @override
  String get gamePlayDescribeWordHint =>
      'Describe la palabra (¡no la digas!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name está describiendo una palabra...';
  }

  @override
  String get gamePlayDoNotSayWord => '¡No digas la palabra!';

  @override
  String get gamePlayGuessTheWord => 'ADIVINA LA PALABRA';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Incorrecto. La respuesta era \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'CLASIFICACIÓN';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Nombra una palabra en $language que empiece con \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Nombra una palabra en \"$category\" que empiece con \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'LA SIGUIENTE PALABRA DEBE EMPEZAR CON';

  @override
  String get gamePlayNoWordsStartChain =>
      'Aún no hay palabras — ¡inicia la cadena!';

  @override
  String get gamePlayPickLetterNameWord =>
      '¡Elige una letra y nombra una palabra!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name está eligiendo...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name está pensando...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Tema: $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'TRADUCE ESTA PALABRA';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Escribe una palabra que contenga \"$prompt\"...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Escribe una palabra que empiece con \"$prompt\"...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Escribe la traducción...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      '¡Escribe una palabra que contenga estas letras!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Escribe tu respuesta...';

  @override
  String get gamePlayTypeYourGuessBelow => '¡Escribe tu respuesta abajo!';

  @override
  String get gamePlayTypeYourGuessHint => 'Escribe tu respuesta...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Usa el chat para describir la palabra a los otros jugadores';

  @override
  String get gamePlayWaitingForOpponent => 'Esperando al oponente...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Palabra que empiece con \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Palabra que empiece con \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards => 'Tu turno — ¡voltea dos cartas!';

  @override
  String gamePlayersTurn(String name) {
    return 'Turno de $name';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points pts';
  }

  @override
  String get gamePositionFirst => '1.°';

  @override
  String gamePositionNth(int pos) {
    return '$pos.°';
  }

  @override
  String get gamePositionSecond => '2.°';

  @override
  String get gamePositionThird => '3.°';

  @override
  String get gameResultsBackToLobby => 'Volver al Lobby';

  @override
  String get gameResultsBaseXp => 'XP Base';

  @override
  String get gameResultsCoinsEarned => 'Monedas Ganadas';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Bonificación por Dificultad (Nv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'CLASIFICACIÓN FINAL';

  @override
  String get gameResultsGameOver => 'FIN DEL JUEGO';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'No tienes suficientes monedas (se requieren $amount)';
  }

  @override
  String get gameResultsPlayAgain => 'Jugar de Nuevo';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'RECOMPENSAS OBTENIDAS';

  @override
  String get gameResultsTotalXp => 'XP Total';

  @override
  String get gameResultsVictory => '¡VICTORIA!';

  @override
  String get gameResultsWhatYouLearned => 'LO QUE APRENDISTE';

  @override
  String get gameResultsWinner => 'Ganador';

  @override
  String get gameResultsWinnerBonus => 'Bonificación del Ganador';

  @override
  String get gameResultsYouWon => '¡Ganaste!';

  @override
  String gameRoundCounter(int current, int total) {
    return 'Ronda $current/$total';
  }

  @override
  String gameRoundNumber(int number) {
    return 'Ronda $number';
  }

  @override
  String gameScorePts(int score) {
    return '$score pts';
  }

  @override
  String get gameSnapsNoMatch => 'No coinciden';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total parejas encontradas';
  }

  @override
  String get gameSnapsTitle => 'Snaps de Idiomas';

  @override
  String get gameSnapsYourTurnFlipCards => 'TU TURNO — ¡Voltea 2 cartas!';

  @override
  String get gameSomeone => 'Alguien';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Nombra una palabra que empiece con \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel => '¡Elige una letra de la rueda!';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Elige una letra, nombra una palabra';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name perdió una vida';
  }

  @override
  String get gameTapplesTimeUp => '¡TIEMPO!';

  @override
  String get gameTapplesTitle => 'Tapples de Idiomas';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Palabra que empiece con \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount palabras usadas  •  $lettersCount letras restantes';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Correcto';

  @override
  String get gameTranslationRaceFirstTo30 => '¡El primero en llegar a 30 gana!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Carrera de Traducción';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Traduce al $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'Esperando a los demás... $answered/$total respondieron';
  }

  @override
  String get gameWaitForYourTurn => 'Espera tu turno...';

  @override
  String get gameWaiting => 'Esperando';

  @override
  String get gameWaitingCancelReady => 'Cancelar Listo';

  @override
  String get gameWaitingCountdownGo => '¡YA!';

  @override
  String get gameWaitingDisconnected => 'Desconectado';

  @override
  String get gameWaitingEllipsis => 'Esperando...';

  @override
  String get gameWaitingForPlayers => 'Esperando Jugadores...';

  @override
  String get gameWaitingGetReady => 'Prepárate...';

  @override
  String get gameWaitingHost => 'ANFITRIÓN';

  @override
  String get gameWaitingInviteCodeCopied => '¡Código de invitación copiado!';

  @override
  String get gameWaitingInviteCodeHeader => 'CÓDIGO DE INVITACIÓN';

  @override
  String get gameWaitingInvitePlayer => 'Invitar Jugador';

  @override
  String get gameWaitingLeaveRoom => 'Salir de la Sala';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Nivel $level';
  }

  @override
  String get gameWaitingNotReady => 'No Listo';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count no listos)';
  }

  @override
  String get gameWaitingPlayersHeader => 'JUGADORES';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count jugadores en la sala';
  }

  @override
  String get gameWaitingReady => 'Listo';

  @override
  String get gameWaitingReadyUp => 'Prepararse';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count rondas';
  }

  @override
  String get gameWaitingShareCode =>
      'Comparte este código con amigos para unirse';

  @override
  String get gameWaitingStartGame => 'Iniciar Partida';

  @override
  String get gameWordAlreadyUsed => '¡Palabra ya usada!';

  @override
  String get gameWordBombBoom => '¡BOOM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'La palabra debe contener \"$prompt\"';
  }

  @override
  String get gameWordBombReport => 'Reportar';

  @override
  String get gameWordBombReportContent =>
      'Reportar esta palabra como inválida o inapropiada.';

  @override
  String gameWordBombReportTitle(String word) {
    return '¿Reportar \"$word\"?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      '¡Se acabó el tiempo! Perdiste una vida.';

  @override
  String get gameWordBombTitle => 'Bomba de Palabras';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Escribe una palabra que contenga \"$prompt\"...';
  }

  @override
  String get gameWordBombUsedWords => 'Palabras Usadas';

  @override
  String get gameWordBombWordReported => 'Palabra reportada';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count palabras usadas';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'La palabra debe empezar con \"$letter\"';
  }

  @override
  String get gameWrong => 'Incorrecto';

  @override
  String get gameYou => 'Tú';

  @override
  String get gameYourTurn => '¡TU TURNO!';

  @override
  String get gamificationAchievements => 'Logros';

  @override
  String get gamificationAll => 'Todos';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '¡$name completado!';
  }

  @override
  String get gamificationClaim => 'Reclamar';

  @override
  String get gamificationClaimReward => 'Reclamar recompensa';

  @override
  String get gamificationCoinsAvailable => 'Monedas disponibles';

  @override
  String get gamificationDaily => 'Diario';

  @override
  String get gamificationDailyChallenges => 'Desafíos diarios';

  @override
  String get gamificationDayStreak => 'Racha de días';

  @override
  String get gamificationDone => 'Hecho';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Obtenido el $date';
  }

  @override
  String get gamificationEasy => 'Fácil';

  @override
  String get gamificationEngagement => 'Participación';

  @override
  String get gamificationEpic => 'Épico';

  @override
  String get gamificationExperiencePoints => 'Puntos de experiencia';

  @override
  String get gamificationGlobal => 'Global';

  @override
  String get gamificationHard => 'Difícil';

  @override
  String get gamificationLeaderboard => 'Tabla de clasificación';

  @override
  String gamificationLevel(Object level) {
    return 'Nivel $level';
  }

  @override
  String get gamificationLevelLabel => 'NIVEL';

  @override
  String gamificationLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'Cargando logros...';

  @override
  String get gamificationLoadingChallenges => 'Cargando desafíos...';

  @override
  String get gamificationLoadingRankings => 'Cargando clasificaciones...';

  @override
  String get gamificationMedium => 'Medio';

  @override
  String get gamificationMilestones => 'Hitos';

  @override
  String get gamificationMonthly => 'Mes';

  @override
  String get gamificationMyProgress => 'Mi progreso';

  @override
  String get gamificationNoAchievements => 'No se encontraron logros';

  @override
  String get gamificationNoAchievementsInCategory =>
      'No hay logros en esta categoría';

  @override
  String get gamificationNoChallenges => 'No hay desafíos disponibles';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'No hay desafíos $type disponibles';
  }

  @override
  String get gamificationNoLeaderboard => 'No hay datos de clasificación';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Miembro Premium';

  @override
  String get gamificationProgress => 'Progreso';

  @override
  String get gamificationRank => 'RANGO';

  @override
  String get gamificationRankLabel => 'Rango';

  @override
  String get gamificationRegional => 'Regional';

  @override
  String gamificationReward(Object amount, Object type) {
    return 'Recompensa: $amount $type';
  }

  @override
  String get gamificationSocial => 'Social';

  @override
  String get gamificationSpecial => 'Especial';

  @override
  String get gamificationTotal => 'Total';

  @override
  String get gamificationUnlocked => 'Desbloqueado';

  @override
  String get gamificationVerifiedUser => 'Usuario verificado';

  @override
  String get gamificationVipMember => 'Miembro VIP';

  @override
  String get gamificationWeekly => 'Semanal';

  @override
  String get gamificationXpAvailable => 'XP disponible';

  @override
  String get gamificationYearly => 'Ano';

  @override
  String get gamificationYourPosition => 'Tu posición';

  @override
  String get gender => 'Género';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get giftCategoryAll => 'Todos';

  @override
  String giftFromSender(Object name) {
    return 'De $name';
  }

  @override
  String get giftGetCoins => 'Obtener monedas';

  @override
  String get giftNoGiftsAvailable => 'No hay regalos disponibles';

  @override
  String get giftNoGiftsInCategory => 'No hay regalos en esta categoría';

  @override
  String get giftNoGiftsYet => 'Aún no hay regalos';

  @override
  String get giftNotEnoughCoins => 'Monedas insuficientes';

  @override
  String giftPriceCoins(Object price) {
    return '$price monedas';
  }

  @override
  String get giftReceivedGifts => 'Regalos recibidos';

  @override
  String get giftReceivedGiftsEmpty =>
      'Los regalos que recibas aparecerán aquí';

  @override
  String get giftSendGift => 'Enviar regalo';

  @override
  String giftSendGiftTo(Object name) {
    return 'Enviar regalo a $name';
  }

  @override
  String get giftSending => 'Enviando...';

  @override
  String giftSentTo(Object name) {
    return '¡Regalo enviado a $name!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Tienes $available monedas.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Necesitas $required monedas para este regalo.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Necesitas $shortfall monedas más.';
  }

  @override
  String get gold => 'Oro';

  @override
  String get grantAlbumAccess => 'Compartir mi álbum';

  @override
  String get greatInterestsHelp =>
      '¡Genial! Tus intereses nos ayudan a encontrar mejores coincidencias';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Saludos';

  @override
  String get guideBadge => 'Guia';

  @override
  String get height => 'Altura';

  @override
  String get helpAndSupport => 'Ayuda y Soporte';

  @override
  String get helpOthersFindYou =>
      'Ayuda a otros a encontrarte en redes sociales';

  @override
  String get hours => 'Horas';

  @override
  String get icebreakersCategoryCompliments => 'Cumplidos';

  @override
  String get icebreakersCategoryDateIdeas => 'Ideas para citas';

  @override
  String get icebreakersCategoryDeep => 'Profundo';

  @override
  String get icebreakersCategoryDreams => 'Sueños';

  @override
  String get icebreakersCategoryFood => 'Comida';

  @override
  String get icebreakersCategoryFunny => 'Divertido';

  @override
  String get icebreakersCategoryHobbies => 'Pasatiempos';

  @override
  String get icebreakersCategoryHypothetical => 'Hipotético';

  @override
  String get icebreakersCategoryMovies => 'Películas';

  @override
  String get icebreakersCategoryMusic => 'Música';

  @override
  String get icebreakersCategoryPersonality => 'Personalidad';

  @override
  String get icebreakersCategoryTravel => 'Viajes';

  @override
  String get icebreakersCategoryTwoTruths => 'Dos verdades';

  @override
  String get icebreakersCategoryWouldYouRather => 'Preferirías';

  @override
  String get icebreakersLabel => 'Rompehielos';

  @override
  String get icebreakersNoneInCategory =>
      'No hay rompehielos en esta categoría';

  @override
  String get icebreakersQuickAnswers => 'Respuestas rápidas:';

  @override
  String get icebreakersSendAnIcebreaker => 'Enviar un rompehielos';

  @override
  String icebreakersSendTo(Object name) {
    return 'Enviar a $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Enviar sin respuesta';

  @override
  String get icebreakersTitle => 'Rompehielos';

  @override
  String get idiomsCategory => 'Modismos';

  @override
  String get incognitoMode => 'Modo Incógnito';

  @override
  String get incognitoModeDescription => 'Oculta tu perfil del descubrimiento';

  @override
  String get incorrectAnswer => 'Incorrecto';

  @override
  String get infoUpdatedMessage => 'Tu información básica ha sido guardada';

  @override
  String get infoUpdatedTitle => '¡Info Actualizada!';

  @override
  String get insufficientCoins => 'Monedas insuficientes';

  @override
  String get insufficientCoinsTitle => 'Monedas Insuficientes';

  @override
  String get interestArt => 'Arte';

  @override
  String get interestBeach => 'Playa';

  @override
  String get interestBeer => 'Cerveza';

  @override
  String get interestBusiness => 'Negocios';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestCats => 'Gatos';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestCooking => 'Cocina';

  @override
  String get interestCycling => 'Ciclismo';

  @override
  String get interestDance => 'Baile';

  @override
  String get interestDancing => 'Baile';

  @override
  String get interestDogs => 'Perros';

  @override
  String get interestEntrepreneurship => 'Emprendimiento';

  @override
  String get interestEnvironment => 'Medio Ambiente';

  @override
  String get interestFashion => 'Moda';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Comida';

  @override
  String get interestGaming => 'Videojuegos';

  @override
  String get interestHiking => 'Senderismo';

  @override
  String get interestHistory => 'Historia';

  @override
  String get interestInvesting => 'Inversiones';

  @override
  String get interestLanguages => 'Idiomas';

  @override
  String get interestMeditation => 'Meditación';

  @override
  String get interestMountains => 'Montañas';

  @override
  String get interestMovies => 'Películas';

  @override
  String get interestMusic => 'Música';

  @override
  String get interestNature => 'Naturaleza';

  @override
  String get interestPets => 'Mascotas';

  @override
  String get interestPhotography => 'Fotografía';

  @override
  String get interestPoetry => 'Poesía';

  @override
  String get interestPolitics => 'Política';

  @override
  String get interestReading => 'Lectura';

  @override
  String get interestRunning => 'Correr';

  @override
  String get interestScience => 'Ciencia';

  @override
  String get interestSkiing => 'Esquí';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestSpirituality => 'Espiritualidad';

  @override
  String get interestSports => 'Deportes';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSwimming => 'Natación';

  @override
  String get interestTeaching => 'Enseñanza';

  @override
  String get interestTechnology => 'Tecnología';

  @override
  String get interestTravel => 'Viajes';

  @override
  String get interestVegan => 'Vegano';

  @override
  String get interestVegetarian => 'Vegetariano';

  @override
  String get interestVolunteering => 'Voluntariado';

  @override
  String get interestWine => 'Vino';

  @override
  String get interestWriting => 'Escritura';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Intereses';

  @override
  String interestsCount(int count) {
    return '$count intereses';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max intereses seleccionados';
  }

  @override
  String get interestsUpdatedMessage => 'Tus intereses han sido guardados';

  @override
  String get interestsUpdatedTitle => '¡Intereses Actualizados!';

  @override
  String get invalidWord => 'Palabra no válida';

  @override
  String get inviteCodeCopied => 'Código de invitación copiado!';

  @override
  String get inviteFriends => 'Invitar Amigos';

  @override
  String get itsAMatch => '¡Empieza a conectar!';

  @override
  String get joinMessage =>
      'Únete a GreenGoChat y encuentra tu pareja perfecta';

  @override
  String get keepSwiping => 'Seguir Deslizando';

  @override
  String get langMatchBadge => 'Idioma Compatible';

  @override
  String get language => 'Idioma';

  @override
  String languageChangedTo(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get languagePacksBtn => 'Paquetes de Idiomas';

  @override
  String get languagePacksShopTitle => 'Tienda de Paquetes de Idiomas';

  @override
  String get languagesToDownloadLabel => 'Idiomas a descargar:';

  @override
  String get lastName => 'Apellido';

  @override
  String get lastUpdated => 'Ultima actualizacion';

  @override
  String get leaderboardSubtitle => 'Ver clasificaciones globales y regionales';

  @override
  String get leaderboardTitle => 'Clasificación';

  @override
  String get learn => 'Aprender';

  @override
  String get learningAccuracy => 'Precisión';

  @override
  String get learningActiveThisWeek => 'Activo esta semana';

  @override
  String get learningAddLessonSection => 'Añadir sección de lección';

  @override
  String get learningAiConversationCoach => 'Coach de conversación AI';

  @override
  String get learningAllCategories => 'Todas las categorías';

  @override
  String get learningAllLessons => 'Todas las lecciones';

  @override
  String get learningAllLevels => 'Todos los niveles';

  @override
  String get learningAmount => 'Cantidad';

  @override
  String get learningAmountLabel => 'Cantidad';

  @override
  String get learningAnalytics => 'Análisis';

  @override
  String learningAnswer(Object answer) {
    return 'Respuesta: $answer';
  }

  @override
  String get learningApplyFilters => 'Aplicar filtros';

  @override
  String get learningAreasToImprove => 'Áreas de mejora';

  @override
  String get learningAvailableBalance => 'Saldo disponible';

  @override
  String get learningAverageRating => 'Calificación promedio';

  @override
  String get learningBeginnerProgress => 'Progreso de principiante';

  @override
  String get learningBonusCoins => 'Monedas de bonificación';

  @override
  String get learningCategory => 'Categoría';

  @override
  String get learningCategoryProgress => 'Progreso por categoría';

  @override
  String get learningCheck => 'Comprobar';

  @override
  String get learningCheckBackSoon => '¡Vuelve pronto!';

  @override
  String get learningCoachSessionCost =>
      '10 monedas/sesión  |  25 XP de recompensa';

  @override
  String get learningContinue => 'Continuar';

  @override
  String get learningCorrect => '¡Correcto!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Correcto: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'Respuesta correcta: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Respuestas correctas';

  @override
  String get learningCorrectLabel => 'Correcto';

  @override
  String get learningCorrections => 'Correcciones';

  @override
  String get learningCreateLesson => 'Crear lección';

  @override
  String get learningCreateNewLesson => 'Crear nueva lección';

  @override
  String get learningCustomPackTitleHint =>
      'ej., \"Saludos en español para citas\"';

  @override
  String get learningDescribeImage => 'Describe esta imagen';

  @override
  String get learningDescriptionHint => '¿Qué aprenderán los estudiantes?';

  @override
  String get learningDescriptionLabel => 'Descripción';

  @override
  String get learningDifficultyLevel => 'Nivel de dificultad';

  @override
  String get learningDone => 'Hecho';

  @override
  String get learningDraftSave => 'Guardar borrador';

  @override
  String get learningDraftSaved => '¡Borrador guardado!';

  @override
  String get learningEarned => 'Ganado';

  @override
  String get learningEdit => 'Editar';

  @override
  String get learningEndSession => 'Finalizar sesión';

  @override
  String get learningEndSessionBody =>
      'El progreso de tu sesión actual se perderá. ¿Deseas finalizar la sesión y ver tu puntuación primero?';

  @override
  String get learningEndSessionQuestion => '¿Finalizar sesión?';

  @override
  String get learningExit => 'Salir';

  @override
  String get learningFalse => 'Falso';

  @override
  String get learningFilterAll => 'Todos';

  @override
  String get learningFilterDraft => 'Borrador';

  @override
  String get learningFilterLessons => 'Filtrar lecciones';

  @override
  String get learningFilterPublished => 'Publicado';

  @override
  String get learningFilterUnderReview => 'En revisión';

  @override
  String get learningFluency => 'Fluidez';

  @override
  String get learningFree => 'GRATIS';

  @override
  String get learningGoBack => 'Volver';

  @override
  String get learningGoalCompleteLessons => 'Completar 5 lecciones';

  @override
  String get learningGoalEarnXp => 'Ganar 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Practicar 30 minutos';

  @override
  String get learningGrammar => 'Gramática';

  @override
  String get learningHint => 'Pista';

  @override
  String get learningLangBrazilianPortuguese => 'Portugués brasileño';

  @override
  String get learningLangEnglish => 'Inglés';

  @override
  String get learningLangFrench => 'Francés';

  @override
  String get learningLangGerman => 'Alemán';

  @override
  String get learningLangItalian => 'Italiano';

  @override
  String get learningLangPortuguese => 'Portugués';

  @override
  String get learningLangSpanish => 'Español';

  @override
  String get learningLanguagesSubtitle =>
      'Selecciona hasta 5 idiomas. Esto nos ayuda a conectarte con hablantes nativos y compañeros de aprendizaje.';

  @override
  String get learningLanguagesTitle => '¿Qué idiomas quieres aprender?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Idiomas para aprender ($count/5)';
  }

  @override
  String get learningLastMonth => 'Mes pasado';

  @override
  String learningLearnLanguage(Object language) {
    return 'Aprender $language';
  }

  @override
  String get learningLearned => 'Aprendido';

  @override
  String get learningLessonComplete => '¡Lección completada!';

  @override
  String get learningLessonCompleteUpper => '¡LECCIÓN COMPLETADA!';

  @override
  String get learningLessonContent => 'Contenido de la lección';

  @override
  String learningLessonNumber(Object number) {
    return 'Lección $number';
  }

  @override
  String get learningLessonSubmitted => '¡Lección enviada para revisión!';

  @override
  String get learningLessonTitle => 'Título de la lección';

  @override
  String get learningLessonTitleHint =>
      'p. ej., \"Saludos en español para citas\"';

  @override
  String get learningLessonTitleLabel => 'Título de la Lección';

  @override
  String get learningLessonsLabel => 'Lecciones';

  @override
  String get learningLetsStart => '¡Empecemos!';

  @override
  String get learningLevel => 'Nivel';

  @override
  String learningLevelBadge(Object level) {
    return 'NV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Nivel $level';
  }

  @override
  String get learningListen => 'Escuchar';

  @override
  String get learningListening => 'Escuchando...';

  @override
  String get learningLongPressForTranslation => 'Mantén pulsado para traducir';

  @override
  String get learningMessages => 'Mensajes';

  @override
  String get learningMessagesSent => 'Mensajes enviados';

  @override
  String get learningMinimumWithdrawal => 'Retiro mínimo: \$50.00';

  @override
  String get learningMonthlyEarnings => 'Ganancias mensuales';

  @override
  String get learningMyProgress => 'Mi progreso';

  @override
  String get learningNativeLabel => '(nativo)';

  @override
  String get learningNativeLanguage => 'Tu idioma nativo';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Necesitas al menos $threshold% para aprobar esta lección.';
  }

  @override
  String get learningNext => 'Siguiente';

  @override
  String get learningNoExercisesInSection =>
      'No hay ejercicios en esta sección';

  @override
  String get learningNoLessonsAvailable => 'Aún no hay lecciones disponibles';

  @override
  String get learningNoPacksFound => 'No se encontraron paquetes';

  @override
  String get learningNoQuestionsAvailable =>
      'Aún no hay preguntas disponibles.';

  @override
  String get learningNotQuite => 'No del todo';

  @override
  String get learningNotQuiteTitle => 'Casi...';

  @override
  String get learningOpenAiCoach => 'Abrir AI Coach';

  @override
  String learningPackFilter(Object category) {
    return 'Paquete: $category';
  }

  @override
  String get learningPackPurchased => '¡Pack comprado exitosamente!';

  @override
  String get learningPassageRevealed => 'Texto (revelado)';

  @override
  String get learningPathTitle => 'Ruta de Aprendizaje';

  @override
  String get learningPlaying => 'Reproduciendo...';

  @override
  String get learningPleaseEnterDescription =>
      'Por favor, introduce una descripción';

  @override
  String get learningPleaseEnterTitle => 'Por favor, introduce un título';

  @override
  String get learningPracticeAgain => 'Practicar de nuevo';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Lecciones publicadas';

  @override
  String get learningPurchased => 'Comprado';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Tus lecciones compradas aparecerán aquí';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count preguntas en esta lección';
  }

  @override
  String get learningQuickActions => 'Acciones rápidas';

  @override
  String get learningReadPassage => 'Lee el texto';

  @override
  String get learningRecentActivity => 'Actividad reciente';

  @override
  String get learningRecentMilestones => 'Hitos recientes';

  @override
  String get learningRecentTransactions => 'Transacciones recientes';

  @override
  String get learningRequired => 'Obligatorio';

  @override
  String get learningResponseRecorded => 'Respuesta registrada';

  @override
  String get learningReview => 'Revisión';

  @override
  String get learningSearchLanguages => 'Buscar idiomas...';

  @override
  String get learningSectionEditorComingSoon =>
      '¡Editor de secciones disponible próximamente!';

  @override
  String get learningSeeScore => 'Ver puntuación';

  @override
  String get learningSelectNativeLanguage => 'Selecciona tu idioma nativo';

  @override
  String get learningSelectScenario => 'Selecciona un escenario para empezar';

  @override
  String get learningSelectScenarioFirst =>
      'Selecciona un escenario primero...';

  @override
  String get learningSessionComplete => '¡Sesión completada!';

  @override
  String get learningSessionSummary => 'Resumen de la sesión';

  @override
  String get learningShowAll => 'Mostrar todo';

  @override
  String get learningShowPassageText => 'Mostrar texto del pasaje';

  @override
  String get learningSkip => 'Omitir';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return '¿Gastar $price monedas para desbloquear esta lección?';
  }

  @override
  String get learningStartFlashcards => 'Iniciar tarjetas';

  @override
  String get learningStartLesson => 'Iniciar lección';

  @override
  String get learningStartPractice => 'Iniciar práctica';

  @override
  String get learningStartQuiz => 'Iniciar quiz';

  @override
  String get learningStartingLesson => 'Iniciando lección...';

  @override
  String get learningStop => 'Detener';

  @override
  String get learningStreak => 'Racha';

  @override
  String get learningStrengths => 'Fortalezas';

  @override
  String get learningSubmit => 'Enviar';

  @override
  String get learningSubmitForReview => 'Enviar para revisión';

  @override
  String get learningSubmitForReviewBody =>
      'Tu lección será revisada por nuestro equipo antes de publicarse. Esto suele tardar 24-48 horas.';

  @override
  String get learningSubmitForReviewQuestion => '¿Enviar para revisión?';

  @override
  String get learningTabAllLessons => 'Todas las Lecciones';

  @override
  String get learningTabEarnings => 'Ganancias';

  @override
  String get learningTabFlashcards => 'Tarjetas';

  @override
  String get learningTabLessons => 'Lecciones';

  @override
  String get learningTabMyLessons => 'Mis lecciones';

  @override
  String get learningTabMyProgress => 'Mi Progreso';

  @override
  String get learningTabOverview => 'Resumen';

  @override
  String get learningTabPhrases => 'Frases';

  @override
  String get learningTabProgress => 'Progreso';

  @override
  String get learningTabPurchased => 'Compradas';

  @override
  String get learningTabQuizzes => 'Cuestionarios';

  @override
  String get learningTabStudents => 'Estudiantes';

  @override
  String get learningTapToContinue => 'Toca para continuar';

  @override
  String get learningTapToHearPassage => 'Toca para escuchar el texto';

  @override
  String get learningTapToListen => 'Toca para escuchar';

  @override
  String get learningTapToMatch => 'Toca los elementos para emparejarlos';

  @override
  String get learningTapToRevealTranslation =>
      'Toca para revelar la traducción';

  @override
  String get learningTapWordsToBuild =>
      'Toca las palabras de abajo para construir la oración';

  @override
  String get learningTargetLanguage => 'Idioma objetivo';

  @override
  String get learningTeacherDashboardTitle => 'Panel del profesor';

  @override
  String get learningTeacherTiers => 'Niveles de profesor';

  @override
  String get learningThisMonth => 'Este mes';

  @override
  String get learningTopPerformingStudents => 'Mejores estudiantes';

  @override
  String get learningTotalStudents => 'Total de estudiantes';

  @override
  String get learningTotalStudentsLabel => 'Total de estudiantes';

  @override
  String get learningTotalXp => 'XP total';

  @override
  String get learningTranslatePhrase => 'Traduce esta frase';

  @override
  String get learningTrue => 'Verdadero';

  @override
  String get learningTryAgain => 'Intentar de nuevo';

  @override
  String get learningTypeAnswerBelow => 'Escribe tu respuesta abajo';

  @override
  String get learningTypeAnswerHint => 'Escribe tu respuesta...';

  @override
  String get learningTypeDescriptionHint => 'Escribe tu descripción...';

  @override
  String get learningTypeMessageHint => 'Escribe tu mensaje...';

  @override
  String get learningTypeMissingWordHint => 'Escribe la palabra que falta...';

  @override
  String get learningTypeSentenceHint => 'Escribe la oración...';

  @override
  String get learningTypeTranslationHint => 'Escribe tu traducción...';

  @override
  String get learningTypeWhatYouHeardHint => 'Escribe lo que escuchaste...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unidad $unit - Lección $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unidad $number';
  }

  @override
  String get learningUnlock => 'Desbloquear';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Desbloquear por $price monedas';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Desbloquear por $price monedas';
  }

  @override
  String get learningUnlockLesson => 'Desbloquear lección';

  @override
  String get learningViewAll => 'Ver todo';

  @override
  String get learningViewAnalytics => 'Ver análisis';

  @override
  String get learningVocabulary => 'Vocabulario';

  @override
  String learningWeek(Object week) {
    return 'Semana $week';
  }

  @override
  String get learningWeeklyGoals => 'Metas semanales';

  @override
  String get learningWhatWillStudentsLearnHint =>
      '¿Qué aprenderán los estudiantes?';

  @override
  String get learningWhatYouWillLearn => 'Lo que aprenderás';

  @override
  String get learningWithdraw => 'Retirar';

  @override
  String get learningWithdrawFunds => 'Retirar fondos';

  @override
  String get learningWithdrawalSubmitted => '¡Solicitud de retiro enviada!';

  @override
  String get learningWordsAndPhrases => 'Palabras y frases';

  @override
  String get learningWriteAnswerFreely => 'Escribe tu respuesta libremente';

  @override
  String get learningWriteAnswerHint => 'Escribe tu respuesta...';

  @override
  String get learningXpEarned => 'XP ganado';

  @override
  String learningYourAnswer(Object answer) {
    return 'Tu respuesta: $answer';
  }

  @override
  String get learningYourScore => 'Tu puntuación';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lección';

  @override
  String get letsChat => '¡Hablemos!';

  @override
  String get letsExchange => '¡Empieza a conectar!';

  @override
  String get levelLabel => 'Nivel';

  @override
  String levelLabelN(String level) {
    return 'Nivel $level';
  }

  @override
  String get levelTitleEnthusiast => 'Entusiasta';

  @override
  String get levelTitleExpert => 'Experto';

  @override
  String get levelTitleExplorer => 'Explorador';

  @override
  String get levelTitleLegend => 'Leyenda';

  @override
  String get levelTitleMaster => 'Maestro';

  @override
  String get levelTitleNewcomer => 'Novato';

  @override
  String get levelTitleVeteran => 'Veterano';

  @override
  String get levelUp => '¡SUBISTE DE NIVEL!';

  @override
  String get levelUpCongratulations =>
      '¡Felicitaciones por alcanzar un nuevo nivel!';

  @override
  String get levelUpContinue => 'Continuar';

  @override
  String get levelUpRewards => 'RECOMPENSAS';

  @override
  String get levelUpTitle => '¡SUBISTE DE NIVEL!';

  @override
  String get levelUpVIPUnlocked => '¡Estado VIP Desbloqueado!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Alcanzaste el Nivel $level';
  }

  @override
  String get likes => 'Me Gusta';

  @override
  String get limitReachedTitle => 'Límite Alcanzado';

  @override
  String get listenMe => '¡Escúchame!';

  @override
  String get loading => 'Cargando...';

  @override
  String get loadingLabel => 'Cargando...';

  @override
  String get localGuideBadge => 'Guia Local';

  @override
  String get location => 'Ubicación';

  @override
  String get locationAndLanguages => 'Ubicación e Idiomas';

  @override
  String get locationError => 'Error de ubicación';

  @override
  String get locationNotFound => 'Ubicación no encontrada';

  @override
  String get locationNotFoundMessage =>
      'No pudimos determinar tu dirección. Inténtalo de nuevo o configura tu ubicación manualmente más tarde.';

  @override
  String get locationPermissionDenied => 'Permiso denegado';

  @override
  String get locationPermissionDeniedMessage =>
      'Se necesita permiso de ubicación para detectar tu ubicación actual. Por favor, concede el permiso para continuar.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permiso denegado permanentemente';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'El permiso de ubicación ha sido denegado permanentemente. Por favor, actívalo en la configuración de tu dispositivo para usar esta función.';

  @override
  String get locationRequestTimeout => 'Tiempo de espera agotado';

  @override
  String get locationRequestTimeoutMessage =>
      'La obtención de tu ubicación tardó demasiado. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get locationServicesDisabled => 'Servicios de ubicación desactivados';

  @override
  String get locationServicesDisabledMessage =>
      'Por favor, activa los servicios de ubicación en la configuración de tu dispositivo para usar esta función.';

  @override
  String get locationUnavailable =>
      'No se pudo obtener tu ubicación en este momento. Puedes configurarla manualmente más tarde en ajustes.';

  @override
  String get locationUnavailableTitle => 'Ubicación no disponible';

  @override
  String get locationUpdatedMessage =>
      'Tu configuración de ubicación ha sido guardada';

  @override
  String get locationUpdatedTitle => '¡Ubicación Actualizada!';

  @override
  String get logOut => 'Cerrar Sesión';

  @override
  String get logOutConfirmation =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get loginWithBiometrics => 'Iniciar Sesión con Biometría';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get longTermRelationship => 'Relación a largo plazo';

  @override
  String get lookingFor => 'Busca';

  @override
  String get lvl => 'NIV';

  @override
  String get manageCouponsTiersRules => 'Gestionar cupones, niveles y reglas';

  @override
  String get matchDetailsTitle => 'Detalles del Match';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Tu y $name quieren intercambiar idiomas!';
  }

  @override
  String get matchNotifKeepSwiping => 'Seguir Deslizando';

  @override
  String get matchNotifLetsChat => 'Hablemos!';

  @override
  String get matchNotifLetsExchange => '¡EMPIEZA A CONECTAR!';

  @override
  String get matchNotifViewProfile => 'Ver Perfil';

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilidad';
  }

  @override
  String matchedOnDate(String date) {
    return 'Match el $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Hiciste match con $name el $date';
  }

  @override
  String get matches => 'Coincidencias';

  @override
  String get matchesClearFilters => 'Limpiar Filtros';

  @override
  String matchesCount(int count) {
    return '$count coincidencias';
  }

  @override
  String get matchesFilterAll => 'Todos';

  @override
  String get matchesFilterMessaged => 'Con Mensajes';

  @override
  String get matchesFilterNew => 'Nuevos';

  @override
  String get matchesNoMatchesFound => 'No se encontraron matches';

  @override
  String get matchesNoMatchesYet => 'Sin matches aun';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered de $total matches';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered de $total coincidencias';
  }

  @override
  String get matchesStartSwiping =>
      'Empieza a deslizar para encontrar tus matches!';

  @override
  String get matchesTryDifferent => 'Intenta una busqueda o filtro diferente';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Máximo $count intereses permitidos';
  }

  @override
  String get maybeLater => 'Quizás Después';

  @override
  String get discoverWorldwideTitle => '¡Amplía tus horizontes!';

  @override
  String get discoverWorldwideMessage =>
      'Aún no hay muchas personas en tu zona, pero ¡GreenGo te conecta con personas de todo el mundo! Ve a Filtros y añade más países para descubrir personas increíbles de todo el planeta.';

  @override
  String get openFilters => 'Abrir Filtros';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return 'Membresía $tierName activa hasta $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => '¡Membresía Activada!';

  @override
  String get membershipAdvancedFilters => 'Filtros avanzados';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Membresía base';

  @override
  String get membershipBestValue =>
      '¡La mejor relación calidad-precio para un compromiso a largo plazo!';

  @override
  String get membershipBoostsMonth => 'Boosts/mes';

  @override
  String get membershipBuyTitle => 'Comprar membresía';

  @override
  String get membershipCouponCodeLabel => 'Código de Cupón *';

  @override
  String get membershipCouponHint => 'ej., GOLD2024';

  @override
  String get membershipCurrent => 'Membresía actual';

  @override
  String get membershipDailyLikes => 'Conexiones Diarias';

  @override
  String get membershipDailyMessagesLabel =>
      'Mensajes Diarios (vacío = ilimitado)';

  @override
  String get membershipDailySwipesLabel =>
      'Deslizamientos Diarios (vacío = ilimitado)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days días restantes';
  }

  @override
  String get membershipDurationLabel => 'Duración (días)';

  @override
  String get membershipEnterCouponHint => 'Ingresa el código de cupón';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Equivalente a $price/mes';
  }

  @override
  String get membershipErrorLoadingData => 'Error al cargar los datos';

  @override
  String membershipExpires(Object date) {
    return 'Expira: $date';
  }

  @override
  String get membershipExtendTitle => 'Extiende tu membresía';

  @override
  String get membershipFeatureComparison => 'Comparación de funciones';

  @override
  String get membershipGeneric => 'Membresía';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Modo incógnito';

  @override
  String get membershipLeaveEmptyLifetime => 'Dejar vacío para permanente';

  @override
  String get membershipLeaveEmptyUnlimited => 'Dejar vacío para ilimitado';

  @override
  String get membershipLowerThanCurrent => 'Inferior a tu nivel actual';

  @override
  String get membershipMaxUsesLabel => 'Usos Máximos';

  @override
  String get membershipMonthly => 'Membresías mensuales';

  @override
  String get membershipNameDescriptionLabel => 'Nombre/Descripción';

  @override
  String get membershipNoActive => 'Sin membresía activa';

  @override
  String get membershipNotesLabel => 'Notas';

  @override
  String get membershipOneMonth => '1 mes';

  @override
  String get membershipOneYear => '1 año';

  @override
  String get membershipPanel => 'Panel de Membresías';

  @override
  String get membershipPermanent => 'Permanente';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 MONEDAS';

  @override
  String get membershipPrioritySupport => 'Soporte prioritario';

  @override
  String get membershipReadReceipts => 'Confirmaciones de lectura';

  @override
  String get membershipRequired => 'Membresía requerida';

  @override
  String get membershipRequiredDescription =>
      'Necesitas ser miembro de GreenGo para realizar esta acción.';

  @override
  String get membershipExtendDescription =>
      'Tu membresía base está activa. Compra otro año para extender tu fecha de vencimiento.';

  @override
  String get membershipRewinds => 'Retrocesos';

  @override
  String membershipSavePercent(Object percent) {
    return 'AHORRA $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Ver quién conecta';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Compra una vez, disfruta de funciones premium durante 1 mes o 1 año';

  @override
  String get membershipSuperLikes => 'Conexiones Prioritarias';

  @override
  String get membershipSuperLikesLabel =>
      'Conexiones Prioritarias/Día (vacío = ilimitado)';

  @override
  String get membershipTerms =>
      'Compra única. La membresía se extenderá desde tu fecha de finalización actual.';

  @override
  String get membershipTermsExtended =>
      'Compra única. La membresía se extenderá desde tu fecha de finalización actual. Las compras de niveles superiores anulan los inferiores.';

  @override
  String get membershipTierLabel => 'Nivel de Membresía *';

  @override
  String membershipTierName(Object tierName) {
    return 'Membresía $tierName';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Membresías anuales (Ahorra hasta $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Tienes $tierName';
  }

  @override
  String get messages => 'Intercambios';

  @override
  String get minutes => 'Minutos';

  @override
  String moreAchievements(int count) {
    return '+$count más logros';
  }

  @override
  String get myBadges => 'Mis Insignias';

  @override
  String get myProgress => 'Mi Progreso';

  @override
  String get myUsage => 'Mi Uso';

  @override
  String get navLearn => 'Aprender';

  @override
  String get navPlay => 'Jugar';

  @override
  String get nearby => 'Cerca';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Necesitas $amount monedas para desbloquear más perfiles.';
  }

  @override
  String get newLabel => 'NUEVO';

  @override
  String get next => 'Siguiente';

  @override
  String nextLevelXp(String xp) {
    return 'Siguiente nivel en $xp XP';
  }

  @override
  String get nickname => 'Apodo';

  @override
  String get nicknameAlreadyTaken => 'Este apodo ya está en uso';

  @override
  String get nicknameCheckError => 'Error al verificar disponibilidad';

  @override
  String nicknameInfoText(String nickname) {
    return 'Tu apodo es único y puede usarse para encontrarte. Otros pueden buscarte usando @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Debe tener 3-20 caracteres';

  @override
  String get nicknameNoConsecutiveUnderscores =>
      'Sin guiones bajos consecutivos';

  @override
  String get nicknameNoReservedWords => 'No puede contener palabras reservadas';

  @override
  String get nicknameOnlyAlphanumeric => 'Solo letras, números y guiones bajos';

  @override
  String get nicknameRequirements =>
      '3-20 caracteres. Solo letras, números y guiones bajos.';

  @override
  String get nicknameRules => 'Reglas del Apodo';

  @override
  String get nicknameSearchChat => 'Chat';

  @override
  String get nicknameSearchError => 'Error al buscar. Intenta de nuevo.';

  @override
  String get nicknameSearchHelp => 'Ingresa un apodo para encontrar a alguien';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'No se encontro perfil con @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'Ese es tu propio perfil!';

  @override
  String get nicknameSearchTitle => 'Buscar por Apodo';

  @override
  String get nicknameSearchView => 'Ver';

  @override
  String get nicknameStartWithLetter => 'Comenzar con una letra';

  @override
  String get nicknameUpdatedMessage => 'Tu nuevo apodo ya está activo';

  @override
  String get nicknameUpdatedSuccess => 'Apodo actualizado con éxito';

  @override
  String get nicknameUpdatedTitle => '¡Apodo Actualizado!';

  @override
  String get no => 'No';

  @override
  String get noActiveGamesLabel => 'Sin juegos activos';

  @override
  String get noBadgesEarnedYet => 'Sin insignias obtenidas';

  @override
  String get noInternetConnection => 'Sin conexión a internet';

  @override
  String get noLanguagesYet => 'Aún no tienes idiomas. ¡Empieza a aprender!';

  @override
  String get noLeaderboardData => 'Aún no hay datos de clasificación';

  @override
  String get noMatchesFound => 'No se encontraron coincidencias';

  @override
  String get noMatchesYet => 'Sin coincidencias aún';

  @override
  String get noMessages => 'No hay mensajes aún';

  @override
  String get noMoreProfiles => 'No hay más perfiles para mostrar';

  @override
  String get noOthersToSee => 'No hay más personas para ver';

  @override
  String get noPendingVerifications => 'No hay verificaciones pendientes';

  @override
  String get noPhotoSubmitted => 'Ninguna foto enviada';

  @override
  String get noPreviousProfile => 'No hay perfil anterior para deshacer';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'No se encontró perfil con @$nickname';
  }

  @override
  String get noResults => 'Sin resultados';

  @override
  String get noSocialProfilesLinked => 'Sin perfiles sociales vinculados';

  @override
  String get noVoiceRecording => 'Sin grabación de voz';

  @override
  String get nodeAvailable => 'Disponible';

  @override
  String get nodeCompleted => 'Completado';

  @override
  String get nodeInProgress => 'En Progreso';

  @override
  String get nodeLocked => 'Bloqueado';

  @override
  String get notEnoughCoins => 'No hay suficientes monedas';

  @override
  String get notNow => 'Ahora No';

  @override
  String get notSet => 'No establecido';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Logro Desbloqueado: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Compraste exitosamente $amount monedas.';
  }

  @override
  String get notificationDialogEnable => 'Activar';

  @override
  String get notificationDialogMessage =>
      'Activa las notificaciones para saber cuándo recibes matches, mensajes y conexiones prioritarias.';

  @override
  String get notificationDialogNotNow => 'Ahora no';

  @override
  String get notificationDialogTitle => 'Mantente conectado';

  @override
  String get notificationEmailSubtitle =>
      'Recibir notificaciones por correo electrónico';

  @override
  String get notificationEmailTitle => 'Notificaciones por correo';

  @override
  String get notificationEnableQuietHours => 'Activar horas de silencio';

  @override
  String get notificationEndTime => 'Hora de fin';

  @override
  String get notificationMasterControls => 'Controles principales';

  @override
  String get notificationMatchExpiring => 'Match por expirar';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Cuando un match está por expirar';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname inició una conversación contigo.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Recibiste un me gusta de @$nickname';
  }

  @override
  String get notificationNewLikes => 'Nuevos likes';

  @override
  String get notificationNewLikesSubtitle => 'Cuando alguien te da like';

  @override
  String notificationNewMatch(String nickname) {
    return '¡Es un Match! Hiciste match con @$nickname. Comienza a chatear ahora.';
  }

  @override
  String get notificationNewMatches => 'Nuevos matches';

  @override
  String get notificationNewMatchesSubtitle => 'Cuando obtienes un nuevo match';

  @override
  String notificationNewMessage(String nickname) {
    return 'Nuevo mensaje de @$nickname';
  }

  @override
  String get notificationNewMessages => 'Nuevos mensajes';

  @override
  String get notificationNewMessagesSubtitle =>
      'Cuando alguien te envía un mensaje';

  @override
  String get notificationProfileViews => 'Visitas al perfil';

  @override
  String get notificationProfileViewsSubtitle => 'Cuando alguien ve tu perfil';

  @override
  String get notificationPromotional => 'Promocional';

  @override
  String get notificationPromotionalSubtitle =>
      'Consejos, ofertas y promociones';

  @override
  String get notificationPushSubtitle =>
      'Recibir notificaciones en este dispositivo';

  @override
  String get notificationPushTitle => 'Notificaciones push';

  @override
  String get notificationQuietHours => 'Horas de silencio';

  @override
  String get notificationQuietHoursDescription =>
      'Silenciar notificaciones en horarios específicos';

  @override
  String get notificationQuietHoursSubtitle =>
      'Silenciar notificaciones durante ciertas horas';

  @override
  String get notificationSettings => 'Configuración de Notificaciones';

  @override
  String get notificationSettingsTitle => 'Configuración de notificaciones';

  @override
  String get notificationSound => 'Sonido';

  @override
  String get notificationSoundSubtitle =>
      'Reproducir sonido para las notificaciones';

  @override
  String get notificationSoundVibration => 'Sonido y vibración';

  @override
  String get notificationStartTime => 'Hora de inicio';

  @override
  String notificationSuperLike(String nickname) {
    return 'Recibiste una conexión prioritaria de @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Conexiones Prioritarias';

  @override
  String get notificationSuperLikesSubtitle =>
      'Cuando alguien conecta prioritariamente contigo';

  @override
  String get notificationTypes => 'Tipos de notificación';

  @override
  String get notificationVibration => 'Vibración';

  @override
  String get notificationVibrationSubtitle => 'Vibrar para las notificaciones';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones';

  @override
  String get notificationsEmptySubtitle =>
      'Cuando recibas notificaciones, aparecerán aquí';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get occupation => 'Ocupación';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Añadir foto';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Añade fotos que muestren al verdadero tú';

  @override
  String get onboardingAiVerifiedDescription =>
      'Tus fotos son verificadas mediante AI para garantizar su autenticidad';

  @override
  String get onboardingAiVerifiedPhotos => 'Fotos verificadas por AI';

  @override
  String get onboardingBioHint =>
      'Cuéntanos sobre tus intereses, pasatiempos, qué buscas...';

  @override
  String get onboardingBioMinLength =>
      'La biografía debe tener al menos 50 caracteres';

  @override
  String get onboardingChooseFromGallery => 'Elegir de la galería';

  @override
  String get onboardingCompleteAllFields =>
      'Por favor, completa todos los campos';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingDateOfBirth => 'Fecha de nacimiento';

  @override
  String get onboardingDisplayName => 'Nombre visible';

  @override
  String get onboardingDisplayNameHint => '¿Cómo deberíamos llamarte?';

  @override
  String get onboardingEnterYourName => 'Por favor, introduce tu nombre';

  @override
  String get onboardingExpressYourself => 'Exprésate';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Escribe algo que represente quién eres';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'No se pudo seleccionar la imagen: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'No se pudo tomar la foto: $error';
  }

  @override
  String get onboardingGenderFemale => 'Femenino';

  @override
  String get onboardingGenderMale => 'Masculino';

  @override
  String get onboardingGenderNonBinary => 'No binario';

  @override
  String get onboardingGenderOther => 'Otro';

  @override
  String get onboardingHoldIdNextToFace =>
      'Sostiene tu documento de identidad junto a tu rostro';

  @override
  String get onboardingIdentifyAs => 'Me identifico como';

  @override
  String get onboardingInterestsHelpMatches =>
      'Tus intereses nos ayudan a encontrar mejores coincidencias para ti';

  @override
  String get onboardingInterestsSubtitle =>
      'Selecciona al menos 3 intereses (máx. 10)';

  @override
  String get onboardingLanguages => 'Idiomas';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 seleccionados';
  }

  @override
  String get onboardingLetsGetStarted => '¡Empecemos!';

  @override
  String get onboardingLocation => 'Ubicación';

  @override
  String get onboardingLocationLater =>
      'Puedes configurar tu ubicación más tarde en ajustes';

  @override
  String get onboardingMainPhoto => 'PRINCIPAL';

  @override
  String get onboardingMaxInterests => 'Puedes seleccionar hasta 10 intereses';

  @override
  String get onboardingMaxLanguages => 'Puedes seleccionar hasta 3 idiomas';

  @override
  String get onboardingMinInterests =>
      'Por favor, selecciona al menos 3 intereses';

  @override
  String get onboardingMinLanguage =>
      'Por favor, selecciona al menos un idioma';

  @override
  String get onboardingNameMinLength =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get onboardingNoLocationSelected => 'Ninguna ubicación seleccionada';

  @override
  String get onboardingOptional => 'Opcional';

  @override
  String get onboardingSelectFromPhotos => 'Seleccionar de tus fotos';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 seleccionados';
  }

  @override
  String get onboardingShowYourself => 'Muéstrate';

  @override
  String get onboardingTakePhoto => 'Tomar foto';

  @override
  String get onboardingTellUsAboutYourself => 'Cuéntanos un poco sobre ti';

  @override
  String get onboardingTipAuthentic => 'Sé auténtico y genuino';

  @override
  String get onboardingTipPassions => 'Comparte tus pasiones y pasatiempos';

  @override
  String get onboardingTipPositive => 'Mantén una actitud positiva';

  @override
  String get onboardingTipUnique => '¿Qué te hace único?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Por favor, sube al menos una foto';

  @override
  String get onboardingUseCurrentLocation => 'Usar ubicación actual';

  @override
  String get onboardingUseYourCamera => 'Usa tu cámara';

  @override
  String get onboardingWhereAreYou => '¿Dónde estás?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Configura tus idiomas preferidos y ubicación (opcional)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Por favor, escribe algo sobre ti';

  @override
  String get onboardingWritingTips => 'Consejos de escritura';

  @override
  String get onboardingYourInterests => 'Tus intereses';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Esta es una descarga única de aproximadamente ${size}MB.';
  }

  @override
  String get optionalConsents => 'Consentimientos Opcionales';

  @override
  String get orContinueWith => 'O continúa con';

  @override
  String get origin => 'Origen';

  @override
  String packFocusMode(String packName) {
    return 'Paquete: $packName';
  }

  @override
  String get password => 'Contraseña';

  @override
  String get passwordMustContain => 'La contraseña debe contener:';

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
  String get passwordMustContainUppercase =>
      'La contraseña debe contener al menos una letra mayúscula';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordStrengthFair => 'Regular';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get passwordStrengthVeryStrong => 'Muy Fuerte';

  @override
  String get passwordStrengthVeryWeak => 'Muy Débil';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordWeak =>
      'La contraseña debe contener mayúsculas, minúsculas, números y caracteres especiales';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get pendingVerifications => 'Verificaciones Pendientes';

  @override
  String get perMonth => '/mes';

  @override
  String get periodAllTime => 'Todo el Tiempo';

  @override
  String get periodMonthly => 'Este Mes';

  @override
  String get periodWeekly => 'Esta Semana';

  @override
  String get personalStatistics => 'Estadísticas personales';

  @override
  String get personalStatisticsSubtitle =>
      'Gráficos, metas y progreso de idiomas';

  @override
  String get personalStatsActivity => 'Actividad reciente';

  @override
  String get personalStatsChatStats => 'Estadísticas del chat';

  @override
  String get personalStatsConversations => 'Conversaciones';

  @override
  String get personalStatsGoalsAchieved => 'Metas alcanzadas';

  @override
  String get personalStatsLevel => 'Nivel';

  @override
  String get personalStatsLanguage => 'Idioma';

  @override
  String get personalStatsTotal => 'Total';

  @override
  String get personalStatsNextLevel => 'Siguiente nivel';

  @override
  String get personalStatsNoActivityYet => 'Aún no hay actividad registrada';

  @override
  String get personalStatsNoWordsYet =>
      'Empieza a chatear para descubrir nuevas palabras';

  @override
  String get personalStatsTotalMessages => 'Mensajes enviados';

  @override
  String get personalStatsWordsDiscovered => 'Palabras descubiertas';

  @override
  String get personalStatsWordsLearned => 'Palabras Aprendidas';

  @override
  String get personalStatsXpOverview => 'Resumen de XP';

  @override
  String get photoAddPhoto => 'Añadir foto';

  @override
  String get photoAddPrivateDescription =>
      'Añade fotos privadas que puedes compartir en el chat';

  @override
  String get photoAddPublicDescription =>
      'Añade fotos para completar tu perfil';

  @override
  String get photoAlreadyExistsInAlbum =>
      'La foto ya existe en el álbum de destino';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get photoDeleteConfirm =>
      '¿Estás seguro/a de que deseas eliminar esta foto?';

  @override
  String get photoDeleteMainWarning =>
      'Esta es tu foto principal. La siguiente foto se convertirá en tu foto principal (debe mostrar tu rostro). ¿Continuar?';

  @override
  String get photoExplicitContent =>
      'Esta foto puede contener contenido inapropiado. Las fotos en la app no deben mostrar desnudez, ropa interior ni contenido explícito.';

  @override
  String get photoExplicitNudity =>
      'Esta foto parece contener desnudez o contenido explícito. Todas las fotos en la app deben ser apropiadas y mostrar ropa completa.';

  @override
  String photoFailedPickImage(Object error) {
    return 'No se pudo seleccionar la imagen: $error';
  }

  @override
  String get photoLongPressReorder =>
      'Mantén pulsado y arrastra para reordenar';

  @override
  String get photoMainNoFace =>
      'Tu foto principal debe mostrar tu rostro claramente. No se detectó ningún rostro en esta foto.';

  @override
  String get photoMainNotForward =>
      'Por favor, usa una foto donde tu rostro sea claramente visible y esté mirando hacia adelante.';

  @override
  String get photoManagePhotos => 'Gestionar fotos';

  @override
  String get photoMaxPrivate => 'Máximo 6 fotos privadas permitidas';

  @override
  String get photoMaxPublic => 'Máximo 6 fotos públicas permitidas';

  @override
  String get photoMustHaveOne =>
      'Debes tener al menos una foto pública con tu rostro visible.';

  @override
  String get photoNoPhotos => 'Aún no hay fotos';

  @override
  String get photoNoPrivatePhotos => 'Aún no hay fotos privadas';

  @override
  String get photoNotAccepted => 'Foto no aceptada';

  @override
  String get photoNotAllowedPublic =>
      'Esta foto no está permitida en ningún lugar de la app.';

  @override
  String get photoPrimary => 'PRINCIPAL';

  @override
  String get photoPrivateShareInfo =>
      'Las fotos privadas se pueden compartir en el chat';

  @override
  String get photoTooLarge =>
      'La foto es demasiado grande. El tamaño máximo es 10 MB.';

  @override
  String get photoTooMuchSkin =>
      'Esta foto muestra demasiada piel expuesta. Por favor, usa una foto donde estés vestido/a apropiadamente.';

  @override
  String get photoUploadedMessage => 'Tu foto ha sido añadida a tu perfil';

  @override
  String get photoUploadedTitle => '¡Foto Subida!';

  @override
  String get photoValidating => 'Validando foto...';

  @override
  String get photos => 'Fotos';

  @override
  String photosCount(int count) {
    return '$count/6 fotos';
  }

  @override
  String photosPublicCount(int count) {
    return 'Fotos: $count publicas';
  }

  @override
  String photosPublicPrivateCount(int publicCount, int privateCount) {
    return 'Fotos: $publicCount publicas + $privateCount privadas';
  }

  @override
  String get photosUpdatedMessage => 'Tu galería de fotos ha sido guardada';

  @override
  String get photosUpdatedTitle => '¡Fotos Actualizadas!';

  @override
  String phrasesCount(String count) {
    return '$count frases';
  }

  @override
  String get phrasesLabel => 'frases';

  @override
  String get platinum => 'Platino';

  @override
  String get playAgain => 'Jugar de Nuevo';

  @override
  String playersRange(String min, String max) {
    return '$min-$max jugadores';
  }

  @override
  String get playing => 'Reproduciendo...';

  @override
  String playingCountLabel(String count) {
    return '$count jugando';
  }

  @override
  String get plusTaxes => '+ impuestos';

  @override
  String get preferenceAddCountry => 'Agregar Pais';

  @override
  String get preferenceLanguageFilter => 'Idioma';

  @override
  String get preferenceLanguageFilterDesc =>
      'Solo mostrar personas que hablen un idioma específico';

  @override
  String get preferenceAnyLanguage => 'Cualquier idioma';

  @override
  String get preferenceInterestFilter => 'Intereses';

  @override
  String get preferenceInterestFilterDesc =>
      'Solo mostrar personas que compartan tus intereses';

  @override
  String get preferenceNoInterestFilter =>
      'Sin filtro de intereses — mostrando todos';

  @override
  String get preferenceAddInterest => 'Agregar interés';

  @override
  String get preferenceSearchInterest => 'Buscar intereses...';

  @override
  String get preferenceNoInterestsFound => 'No se encontraron intereses';

  @override
  String get preferenceAddDealBreaker => 'Agregar Criterio Excluyente';

  @override
  String get preferenceAdvancedFilters => 'Filtros Avanzados';

  @override
  String get preferenceAgeRange => 'Rango de Edad';

  @override
  String get preferenceAllCountries => 'Todos los Paises';

  @override
  String get preferenceAllVerified =>
      'Todos los perfiles deben estar verificados';

  @override
  String get preferenceCountry => 'Pais';

  @override
  String get preferenceCountryDescription =>
      'Solo mostrar personas de paises especificos (dejar vacio para todos)';

  @override
  String get preferenceDealBreakers => 'Criterios Excluyentes';

  @override
  String get preferenceDealBreakersDesc =>
      'No me muestres perfiles con estas caracteristicas';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Todos';

  @override
  String get preferenceMaxDistance => 'Distancia Maxima';

  @override
  String get preferenceMen => 'Hombres';

  @override
  String get preferenceMostPopular => 'Mas Popular';

  @override
  String get preferenceNoCountriesFound => 'No se encontraron paises';

  @override
  String get preferenceNoCountryFilter =>
      'Sin filtro de pais - mostrando mundialmente';

  @override
  String get preferenceCountryRequired =>
      'Se debe seleccionar al menos un país';

  @override
  String get preferenceByUsers => 'Por usuarios';

  @override
  String get preferenceNoDealBreakers => 'Sin criterios excluyentes';

  @override
  String get preferenceNoDistanceLimit => 'Sin limite de distancia';

  @override
  String get preferenceOnlineNow => 'En Linea Ahora';

  @override
  String get preferenceOnlineNowDesc =>
      'Solo mostrar perfiles actualmente en linea';

  @override
  String get preferenceOnlyVerified => 'Solo mostrar perfiles verificados';

  @override
  String get preferenceOrientationDescription =>
      'Filtrar por orientacion (dejar todo sin marcar para mostrar todos)';

  @override
  String get preferenceRecentlyActive => 'Activos Recientemente';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Solo mostrar perfiles activos en los ultimos 7 dias';

  @override
  String get preferenceSave => 'Guardar';

  @override
  String get preferenceSelectCountry => 'Seleccionar Pais';

  @override
  String get preferenceSexualOrientation => 'Orientacion Sexual';

  @override
  String get preferenceShowMe => 'Mostrarme';

  @override
  String get preferenceUnlimited => 'Ilimitado';

  @override
  String preferenceUsersCount(int count) {
    return '$count usuarios';
  }

  @override
  String get preferenceWithin => 'Dentro de';

  @override
  String get preferenceWomen => 'Mujeres';

  @override
  String get preferencesSavedMessage =>
      'Tus preferencias de descubrimiento han sido actualizadas';

  @override
  String get preferencesSavedTitle => '¡Preferencias Guardadas!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Origen Principal';

  @override
  String get priorityConnectNotificationMessage =>
      '¡Alguien quiere conectar contigo!';

  @override
  String get priorityConnectNotificationTitle => 'Priority Connect!';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get privacySettings => 'Configuración de Privacidad';

  @override
  String get privateAlbum => 'Privado';

  @override
  String get privateRoom => 'Sala Privada';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Perfil';

  @override
  String get profileAboutMe => 'Sobre Mi';

  @override
  String get profileAccountDeletedSuccess => 'Cuenta eliminada correctamente.';

  @override
  String get profileActivate => 'Activar';

  @override
  String get profileActivateIncognito => '¿Activar incógnito?';

  @override
  String get profileActivateTravelerMode => '¿Activar modo viajero?';

  @override
  String get profileActivatingBoost => 'Activando boost...';

  @override
  String get profileActiveLabel => 'ACTIVO';

  @override
  String get profileAdditionalDetails => 'Detalles Adicionales';

  @override
  String profileAgeCannotChange(int age) {
    return 'Edad $age - No se puede cambiar (verificacion)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return '¡Perfil ya con boost! $minutes min restantes';
  }

  @override
  String get profileAuthenticationFailed => 'Error de autenticación';

  @override
  String profileBioMinLength(int min) {
    return 'La bio debe tener al menos $min caracteres';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Coste: $cost monedas';
  }

  @override
  String get profileBoostDescription =>
      '¡Tu perfil aparecerá en la parte superior del descubrimiento durante 30 minutos!';

  @override
  String get profileBoostNow => 'Impulsar ahora';

  @override
  String get profileBoostProfile => 'Impulsar perfil';

  @override
  String get profileBoostSubtitle => 'Sé visto primero durante 30 minutos';

  @override
  String get profileBoosted => '¡Perfil impulsado!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return '¡Perfil impulsado durante $minutes minutos!';
  }

  @override
  String get profileBuyCoins => 'Comprar monedas';

  @override
  String get profileCoinShop => 'Tienda de monedas';

  @override
  String get profileCoinShopSubtitle => 'Comprar monedas y membresía premium';

  @override
  String get profileConfirmYourPassword => 'Confirma tu contraseña';

  @override
  String get profileContinue => 'Continuar';

  @override
  String get profileDataExportSent =>
      'Exportación de datos enviada a tu correo';

  @override
  String get profileDateOfBirth => 'Fecha de Nacimiento';

  @override
  String get profileDeleteAccountWarning =>
      'Esta acción es permanente y no se puede deshacer. Todos tus datos, matches y mensajes serán eliminados. Por favor, introduce tu contraseña para confirmar.';

  @override
  String get profileDiscoveryRestarted =>
      '¡Descubrimiento reiniciado! Ahora puedes ver todos los perfiles de nuevo.';

  @override
  String get profileDisplayName => 'Nombre para Mostrar';

  @override
  String get profileDobInfo =>
      'Tu fecha de nacimiento no puede cambiarse por la verificacion de edad. Tu edad exacta es visible para los matches.';

  @override
  String get profileEditBasicInfo => 'Editar Info Basica';

  @override
  String get profileEditLocation => 'Editar Ubicacion e Idiomas';

  @override
  String get profileEditNickname => 'Editar Apodo';

  @override
  String get profileEducation => 'Educacion';

  @override
  String get profileEducationHint => 'ej. Licenciatura en Informatica';

  @override
  String get profileEnterNameHint => 'Ingresa tu nombre';

  @override
  String get profileEnterNicknameHint => 'Ingresa un apodo';

  @override
  String get profileEnterNicknameWith => 'Ingresa un apodo que comience con @';

  @override
  String get profileExportingData => 'Exportando tus datos...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Error al reiniciar el descubrimiento: $error';
  }

  @override
  String get profileFindUsers => 'Buscar Usuarios';

  @override
  String get profileGender => 'Genero';

  @override
  String get profileGetCoins => 'Obtener monedas';

  @override
  String get profileGetMembership => 'Obtener membresía GreenGo';

  @override
  String get profileGettingLocation => 'Obteniendo ubicacion...';

  @override
  String get profileGreengoMembership => 'Membresía GreenGo';

  @override
  String get profileHeightCm => 'Altura (cm)';

  @override
  String get profileIncognitoActivated =>
      '¡Modo incógnito activado por 24 horas!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'El modo incógnito cuesta $cost monedas por día.';
  }

  @override
  String get profileIncognitoDeactivated => 'Modo incógnito desactivado.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'El modo incógnito oculta tu perfil del descubrimiento durante 24 horas.\n\nCoste: $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Gratis con Platinum - Oculto del descubrimiento';

  @override
  String get profileIncognitoMode => 'Modo incógnito';

  @override
  String get profileInsufficientCoins => 'Monedas insuficientes';

  @override
  String profileInterestsCount(Object count) {
    return '$count intereses';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Cuéntanos sobre tus intereses, hobbies, lo que buscas...';

  @override
  String get profileLanguagesSectionTitle => 'Idiomas';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 idiomas seleccionados';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count perfil(es) vinculado(s)';
  }

  @override
  String profileLocationFailed(String error) {
    return 'No se pudo obtener la ubicacion: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Ubicacion';

  @override
  String get profileLookingFor => 'Busco';

  @override
  String get profileLookingForHint => 'ej. Relacion a largo plazo';

  @override
  String get profileMaxLanguagesAllowed => 'Maximo 3 idiomas permitidos';

  @override
  String get profileMembershipActive => 'Activa';

  @override
  String get profileMembershipExpired => 'Expirada';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Válida hasta $date';
  }

  @override
  String get profileMyUsage => 'Mi uso';

  @override
  String get profileMyUsageSubtitle => 'Ver tu uso diario y límites de nivel';

  @override
  String get profileNicknameAlreadyTaken => 'Este apodo ya esta en uso';

  @override
  String get profileNicknameCharRules =>
      '3-20 caracteres. Solo letras, numeros y guiones bajos.';

  @override
  String get profileNicknameCheckError => 'Error al verificar disponibilidad';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Tu apodo es unico y puede usarse para encontrarte. Otros pueden buscarte con @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Tu apodo es unico y puede usarse para encontrarte. Establece uno para que otros te descubran.';

  @override
  String get profileNicknameLabel => 'Apodo';

  @override
  String get profileNicknameRefresh => 'Actualizar';

  @override
  String get profileNicknameRule1 => 'Debe tener 3-20 caracteres';

  @override
  String get profileNicknameRule2 => 'Comenzar con una letra';

  @override
  String get profileNicknameRule3 => 'Solo letras, numeros y guiones bajos';

  @override
  String get profileNicknameRule4 => 'Sin guiones bajos consecutivos';

  @override
  String get profileNicknameRule5 => 'No puede contener palabras reservadas';

  @override
  String get profileNicknameRules => 'Reglas del Apodo';

  @override
  String get profileNicknameSuggestions => 'Sugerencias';

  @override
  String profileNoUsersFound(String query) {
    return 'No se encontraron usuarios para \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return '¡Monedas insuficientes! Necesitas $required, tienes $available';
  }

  @override
  String get profileOccupation => 'Ocupacion';

  @override
  String get profileOccupationHint => 'ej. Ingeniero de Software';

  @override
  String get profileOptionalDetails => 'Opcional - ayuda a otros a conocerte';

  @override
  String get profileOrientationPrivate =>
      'Esto es privado y no se muestra en tu perfil';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get profilePremiumFeatures => 'Funciones premium';

  @override
  String get profileProgressGrowth => 'Progreso y crecimiento';

  @override
  String get profileRestart => 'Reiniciar';

  @override
  String get profileRestartDiscovery => 'Reiniciar descubrimiento';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Esto borrará todos tus swipes (conexiones, rechazos, conexiones prioritarias) para que puedas redescubrir a todos desde cero.\n\nTus matches y chats NO se verán afectados.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Reiniciar descubrimiento';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Restablecer todos los swipes y empezar de nuevo';

  @override
  String get profileSearchByNickname => 'Buscar por @apodo';

  @override
  String get profileSearchByNicknameHint => 'Buscar por @apodo';

  @override
  String get profileSearchCityHint => 'Buscar ciudad, dirección o lugar...';

  @override
  String get profileSearchForUsers => 'Buscar usuarios por apodo';

  @override
  String get profileSearchLanguagesHint => 'Buscar idiomas...';

  @override
  String get profileSetLocationAndLanguage =>
      'Por favor establece ubicacion y selecciona al menos un idioma';

  @override
  String get profileSexualOrientation => 'Orientacion Sexual';

  @override
  String get profileStop => 'Detener';

  @override
  String get profileTellAboutYourselfHint => 'Cuéntale a la gente sobre ti...';

  @override
  String get profileTipAuthentic => 'Se autentico y genuino';

  @override
  String get profileTipHobbies => 'Menciona tus hobbies y pasiones';

  @override
  String get profileTipHumor => 'Agrega un toque de humor';

  @override
  String get profileTipPositive => 'Mantente positivo';

  @override
  String get profileTipsForGreatBio => 'Consejos para una gran bio';

  @override
  String profileTravelerActivated(Object city) {
    return '¡Modo viajero activado! Apareciendo en $city durante 24 horas.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'El modo viajero cuesta $cost monedas por día.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Modo viajero desactivado. De vuelta a tu ubicación real.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'El modo viajero te permite aparecer en el feed de descubrimiento de otra ciudad durante 24 horas.\n\nCoste: $cost';
  }

  @override
  String get profileTravelerMode => 'Modo viajero';

  @override
  String get profileTryDifferentNickname => 'Intenta con otro apodo';

  @override
  String get profileUnableToVerifyAccount => 'No se pudo verificar la cuenta';

  @override
  String get profileUpdateCurrentLocation => 'Actualizar Ubicacion Actual';

  @override
  String get profileUpdatedMessage => 'Tus cambios han sido guardados';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado con éxito';

  @override
  String get profileUpdatedTitle => '¡Perfil Actualizado!';

  @override
  String get profileWeightKg => 'Peso (kg)';

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
  String get profilingDescription =>
      'Permitir analizar tus preferencias para proporcionar mejores sugerencias de coincidencia';

  @override
  String get progress => 'Progreso';

  @override
  String get progressAchievements => 'Insignias';

  @override
  String get progressBadges => 'Insignias';

  @override
  String get progressChallenges => 'Desafíos';

  @override
  String get progressComparison => 'Comparacion de Progreso';

  @override
  String get progressCompleted => 'Completados';

  @override
  String get progressJourneyDescription =>
      'Ve tu viaje completo de citas y logros';

  @override
  String get progressLabel => 'Progreso';

  @override
  String get progressLeaderboard => 'Clasificación';

  @override
  String progressLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Resumen';

  @override
  String get progressRecentAchievements => 'Logros Recientes';

  @override
  String get progressSeeAll => 'Ver Todo';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressTodaysChallenges => 'Desafíos de Hoy';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressViewJourney => 'Ver Tu Viaje';

  @override
  String get publicAlbum => 'Público';

  @override
  String get purchaseSuccessfulTitle => '¡Compra Exitosa!';

  @override
  String get purchasedLabel => 'Comprado';

  @override
  String get quickPlay => 'Partida Rápida';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Leer Política de Privacidad';

  @override
  String get readTermsAndConditions => 'Leer Términos y Condiciones';

  @override
  String get readyButton => 'Listo';

  @override
  String get recipientNickname => 'Apodo del destinatario';

  @override
  String get recordVoice => 'Grabar Voz';

  @override
  String get refresh => 'Actualizar';

  @override
  String get register => 'Registrarse';

  @override
  String get rejectVerification => 'Rechazar';

  @override
  String rejectionReason(String reason) {
    return 'Razón: $reason';
  }

  @override
  String get rejectionReasonRequired =>
      'Por favor ingresa una razón para el rechazo';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $limitType restantes hoy';
  }

  @override
  String get reportSubmittedMessage =>
      'Gracias por ayudar a mantener segura nuestra comunidad';

  @override
  String get reportSubmittedTitle => '¡Reporte Enviado!';

  @override
  String get reportWord => 'Reportar Palabra';

  @override
  String get reportsPanel => 'Panel de Reportes';

  @override
  String get requestBetterPhoto => 'Solicitar Mejor Foto';

  @override
  String requiresTier(String tier) {
    return 'Requiere $tier';
  }

  @override
  String get resetPassword => 'Restablecer Contraseña';

  @override
  String get resetToDefault => 'Restablecer Valores';

  @override
  String get restartAppWizard => 'Reiniciar Asistente de la App';

  @override
  String get restartWizard => 'Reiniciar Asistente';

  @override
  String get restartWizardDialogContent =>
      'Esto reiniciará el asistente de configuración. Podrás actualizar la información de tu perfil paso a paso. Tus datos actuales serán preservados.';

  @override
  String get retakePhoto => 'Tomar de Nuevo';

  @override
  String get retry => 'Reintentar';

  @override
  String get reuploadVerification => 'Volver a subir foto de verificación';

  @override
  String get reverificationCameraError => 'No se pudo abrir la cámara';

  @override
  String get reverificationDescription =>
      'Por favor, tómate un selfie claro para verificar tu identidad. Asegúrate de tener buena iluminación y que tu rostro sea visible.';

  @override
  String get reverificationHeading => 'Necesitamos verificar tu identidad';

  @override
  String get reverificationInfoText =>
      'Después de enviar, tu perfil estará en revisión. Obtendrás acceso una vez aprobado.';

  @override
  String get reverificationPhotoTips => 'Consejos para la foto';

  @override
  String get reverificationReasonLabel => 'Motivo de la solicitud:';

  @override
  String get reverificationRetakePhoto => 'Repetir foto';

  @override
  String get reverificationSubmit => 'Enviar para revisión';

  @override
  String get reverificationTapToSelfie => 'Toca para tomar un selfie';

  @override
  String get reverificationTipCamera => 'Mira directamente a la cámara';

  @override
  String get reverificationTipFullFace =>
      'Asegúrate de que tu rostro completo sea visible';

  @override
  String get reverificationTipLighting =>
      'Buena iluminación — mira hacia la fuente de luz';

  @override
  String get reverificationTipNoAccessories =>
      'Sin gafas de sol, sombreros ni mascarillas';

  @override
  String get reverificationTitle => 'Verificación de identidad';

  @override
  String get reverificationUploadFailed =>
      'Error al subir. Por favor, inténtalo de nuevo.';

  @override
  String get reviewReportedMessages =>
      'Revisar mensajes reportados y gestionar cuentas';

  @override
  String get reviewUserVerifications => 'Revisar verificaciones de usuarios';

  @override
  String reviewedBy(String admin) {
    return 'Revisado por $admin';
  }

  @override
  String get revokeAccess => 'Revocar acceso al álbum';

  @override
  String get rewardsAndProgress => 'Recompensas y Progreso';

  @override
  String get romanticCategory => 'Romántico';

  @override
  String get roundTimer => 'Temporizador de Ronda';

  @override
  String roundXofY(String current, String total) {
    return 'Ronda $current/$total';
  }

  @override
  String get rounds => 'Rondas';

  @override
  String get safetyAdd => 'Añadir';

  @override
  String get safetyAddAtLeastOneContact =>
      'Por favor, añade al menos un contacto de emergencia';

  @override
  String get safetyAddEmergencyContact => 'Añadir contacto de emergencia';

  @override
  String get safetyAddEmergencyContacts => 'Añadir contactos de emergencia';

  @override
  String get safetyAdditionalDetailsHint => 'Detalles adicionales...';

  @override
  String get safetyCheckInDescription =>
      'Configura un check-in para tu cita. Te recordaremos que hagas check-in y alertaremos a tus contactos si no respondes.';

  @override
  String get safetyCheckInEvery => 'Check-in cada';

  @override
  String get safetyCheckInScheduled => '¡Check-in de cita programado!';

  @override
  String get safetyDateCheckIn => 'Check-in de cita';

  @override
  String get safetyDateTime => 'Fecha y hora';

  @override
  String get safetyEmergencyContacts => 'Contactos de emergencia';

  @override
  String get safetyEmergencyContactsHelp =>
      'Serán notificados si necesitas ayuda';

  @override
  String get safetyEmergencyContactsLocation =>
      'Los contactos de emergencia pueden ver tu ubicación';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 hora';

  @override
  String get safetyInterval2Hours => '2 horas';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Ubicación';

  @override
  String get safetyMeetingLocationHint => '¿Dónde se van a encontrar?';

  @override
  String get safetyMeetingWith => 'Reunión con';

  @override
  String get safetyNameLabel => 'Nombre';

  @override
  String get safetyNotesOptional => 'Notas (opcional)';

  @override
  String get safetyPhoneLabel => 'Número de Teléfono';

  @override
  String get safetyPleaseEnterLocation => 'Por favor, introduce una ubicación';

  @override
  String get safetyRelationshipFamily => 'Familia';

  @override
  String get safetyRelationshipFriend => 'Amigo/a';

  @override
  String get safetyRelationshipLabel => 'Relación';

  @override
  String get safetyRelationshipOther => 'Otro';

  @override
  String get safetyRelationshipPartner => 'Pareja';

  @override
  String get safetyRelationshipRoommate => 'Compañero/a de piso';

  @override
  String get safetyScheduleCheckIn => 'Programar check-in';

  @override
  String get safetyShareLiveLocation => 'Compartir ubicación en vivo';

  @override
  String get safetyStaySafe => 'Mantente seguro/a';

  @override
  String get save => 'Guardar';

  @override
  String get searchByNameOrNickname => 'Buscar por nombre o @apodo';

  @override
  String get searchByNickname => 'Buscar por Apodo';

  @override
  String get searchByNicknameTooltip => 'Buscar por apodo';

  @override
  String get searchCityPlaceholder => 'Buscar ciudad, dirección o lugar...';

  @override
  String get searchCountries => 'Buscar países...';

  @override
  String get searchCountryHint => 'Buscar país...';

  @override
  String get searchForCity => 'Busca una ciudad o usa el GPS';

  @override
  String get searchMessagesHint => 'Buscar mensajes...';

  @override
  String get secondChanceDescription =>
      '¡Mira los perfiles que pasaste y que les gustaste!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km de distancia';
  }

  @override
  String get secondChanceEmpty => 'No hay segundas oportunidades disponibles';

  @override
  String get secondChanceEmptySubtitle =>
      '¡Vuelve más tarde para más oportunidades!';

  @override
  String get secondChanceFindButton => 'Buscar segundas oportunidades';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max gratis';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Obtener ilimitadas ($cost)';
  }

  @override
  String get secondChanceLike => 'Like';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'Le gustaste hace $ago';
  }

  @override
  String get secondChanceMatchBody =>
      '¡Ambos se gustan! Inicia una conversación.';

  @override
  String get secondChanceMatchTitle => '¡Empieza a conectar!';

  @override
  String get secondChanceOutOf => 'Sin segundas oportunidades';

  @override
  String get secondChancePass => 'Pasar';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Has usado las $freePerDay segundas oportunidades gratuitas de hoy.\n\n¡Obtén ilimitadas por $cost monedas!';
  }

  @override
  String get secondChanceRefresh => 'Actualizar';

  @override
  String get secondChanceStartChat => 'Iniciar chat';

  @override
  String get secondChanceTitle => 'Segunda oportunidad';

  @override
  String get secondChanceUnlimited => 'Ilimitadas';

  @override
  String get secondChanceUnlimitedUnlocked =>
      '¡Segundas oportunidades ilimitadas desbloqueadas!';

  @override
  String get secondaryOrigin => 'Origen Secundario (opcional)';

  @override
  String get seconds => 'Segundos';

  @override
  String get secretAchievement => 'Logro Secreto';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get seeHowOthersViewProfile => 'Ve cómo otros ven tu perfil';

  @override
  String seeMoreProfiles(int count) {
    return 'Ver $count más';
  }

  @override
  String get seeMoreProfilesTitle => 'Ver Más Perfiles';

  @override
  String get seeProfile => 'Ver Perfil';

  @override
  String selectAtLeastInterests(int count) {
    return 'Selecciona al menos $count intereses';
  }

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get selectTravelLocation => 'Seleccionar ubicación de viaje';

  @override
  String get sendCoins => 'Enviar monedas';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return '¿Enviar $amount monedas a @$nickname?';
  }

  @override
  String get sendMedia => 'Enviar Media';

  @override
  String get sendMessage => 'Enviar Mensaje';

  @override
  String get serverUnavailableMessage =>
      'Nuestros servidores están temporalmente no disponibles. Inténtalo en unos momentos.';

  @override
  String get serverUnavailableTitle => 'Servidor No Disponible';

  @override
  String get setYourUniqueNickname => 'Establece tu apodo único';

  @override
  String get settings => 'Configuración';

  @override
  String get shareAlbum => 'Compartir álbum';

  @override
  String get shop => 'Tienda';

  @override
  String get shopActive => 'ACTIVA';

  @override
  String get shopAdvancedFilters => 'Filtros avanzados';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount monedas';
  }

  @override
  String get shopBadge => 'Insignia';

  @override
  String get shopBaseMembership => 'Membresía Base GreenGo';

  @override
  String get shopBaseMembershipDescription =>
      'Necesaria para deslizar, dar like, chatear e interactuar con otros usuarios.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus monedas de bonificación';
  }

  @override
  String get shopBoosts => 'Boosts';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Comprar $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf => 'No puedes enviarte monedas a ti mismo';

  @override
  String get shopCheckInternet =>
      'Asegúrate de tener conexión a internet\ny vuelve a intentarlo.';

  @override
  String get shopCoins => 'Monedas';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount monedas/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount monedas enviadas a @$nickname';
  }

  @override
  String get shopComingSoon => 'Próximamente';

  @override
  String get shopConfirmSend => 'Confirmar envío';

  @override
  String get shopCurrent => 'ACTUAL';

  @override
  String shopCurrentExpires(Object date) {
    return 'ACTUAL - Expira $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Plan actual: $tier';
  }

  @override
  String get shopDailyLikes => 'Conexiones Diarias';

  @override
  String shopDaysLeft(Object days) {
    return '${days}d restantes';
  }

  @override
  String get shopEnterAmount => 'Ingresa la cantidad';

  @override
  String get shopEnterBothFields => 'Ingresa el nickname y la cantidad';

  @override
  String get shopEnterValidAmount => 'Ingresa una cantidad válida';

  @override
  String shopExpired(String date) {
    return 'Expirado: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expira: $date ($days días restantes)';
  }

  @override
  String get shopFailedToInitiate => 'No se pudo iniciar la compra';

  @override
  String get shopFailedToSendCoins => 'Error al enviar monedas';

  @override
  String get shopGetNotified => 'Recibir notificación';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Modo incógnito';

  @override
  String get shopInsufficientCoins => 'Monedas insuficientes';

  @override
  String shopMembershipActivated(String date) {
    return '¡Membresía GreenGo activada! +500 monedas de bono. Válida hasta $date.';
  }

  @override
  String get shopMonthly => 'Mensual';

  @override
  String get shopNotifyMessage =>
      'Te avisaremos cuando Video-Coins esté disponible';

  @override
  String get shopOneMonth => '1 Mes';

  @override
  String get shopOneYear => '1 Año';

  @override
  String get shopPerMonth => '/mes';

  @override
  String get shopPerYear => '/año';

  @override
  String get shopPopular => 'POPULAR';

  @override
  String get shopPreviousPurchaseFound =>
      'Compra anterior encontrada. Inténtalo de nuevo.';

  @override
  String get shopPriorityMatching => 'Coincidencia prioritaria';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Comprar $coins monedas por $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Error de compra: $error';
  }

  @override
  String get shopReadReceipts => 'Confirmaciones de lectura';

  @override
  String get shopRecipientNickname => 'Nickname del destinatario';

  @override
  String get shopRetry => 'Reintentar';

  @override
  String shopSavePercent(String percent) {
    return 'AHORRA $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Ver quién conecta';

  @override
  String get shopSend => 'Enviar';

  @override
  String get shopSendCoins => 'Enviar monedas';

  @override
  String get shopStoreNotAvailable =>
      'Tienda no disponible. Revisa la configuración de tu dispositivo.';

  @override
  String get shopSuperLikes => 'Conexiones Prioritarias';

  @override
  String get shopTabCoins => 'Monedas';

  @override
  String shopTabError(Object tabName) {
    return 'Error en la pestaña $tabName';
  }

  @override
  String get shopTabMembership => 'Membresía';

  @override
  String get shopTabVideo => 'Video';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopTravelling => 'Viajando';

  @override
  String get shopUnableToLoadPackages => 'No se pueden cargar los paquetes';

  @override
  String get shopUnlimited => 'Ilimitado';

  @override
  String get shopUnlockPremium =>
      'Desbloquea funciones premium y mejora tu experiencia de citas';

  @override
  String get shopUpgradeAndSave =>
      '¡Mejora y ahorra! Descuento en niveles superiores';

  @override
  String get shopUpgradeExperience => 'Mejora tu experiencia';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Mejorar a $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Usuario no encontrado';

  @override
  String shopValidUntil(String date) {
    return 'Válida hasta $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      '¡Mira videos cortos para ganar monedas gratis!\nEstá atento a esta emocionante función.';

  @override
  String get shopVipBadge => 'Insignia VIP';

  @override
  String get shopYearly => 'Anual';

  @override
  String get shopYearlyPlan => 'Suscripción anual';

  @override
  String get shopYouHave => 'Tienes';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Ahorras $amount/mes al mejorar desde $tier';
  }

  @override
  String get shortTermRelationship => 'Relación a corto plazo';

  @override
  String showingProfiles(int count) {
    return '$count perfiles';
  }

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get signUp => 'Regístrate';

  @override
  String get silver => 'Plata';

  @override
  String get skip => 'Saltar';

  @override
  String get skipForNow => 'Saltar por Ahora';

  @override
  String get slangCategory => 'Jerga';

  @override
  String get socialConnectAccounts => 'Conecta tus cuentas sociales';

  @override
  String get socialHintUsername => 'Nombre de usuario (sin @)';

  @override
  String get socialHintUsernameOrUrl => 'Nombre de usuario o URL del perfil';

  @override
  String get socialLinksUpdatedMessage =>
      'Tus perfiles sociales han sido guardados';

  @override
  String get socialLinksUpdatedTitle => '¡Redes Sociales Actualizadas!';

  @override
  String get socialNotConnected => 'No conectado';

  @override
  String get socialProfiles => 'Perfiles Sociales';

  @override
  String get socialProfilesTip =>
      'Tus perfiles sociales serán visibles en tu perfil de citas y ayudarán a otros a verificar tu identidad.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get spotsAbout => 'Acerca de';

  @override
  String get spotsAddNewSpot => 'Añadir un nuevo lugar';

  @override
  String get spotsAddSpot => 'Añadir lugar';

  @override
  String spotsAddedBy(Object name) {
    return 'Añadido por $name';
  }

  @override
  String get spotsAll => 'Todos';

  @override
  String get spotsCategory => 'Categoría';

  @override
  String get spotsCouldNotLoad => 'No se pudieron cargar los lugares';

  @override
  String get spotsCouldNotLoadSpot => 'No se pudo cargar el lugar';

  @override
  String get spotsCreateSpot => 'Crear lugar';

  @override
  String get spotsCulturalSpots => 'Lugares culturales';

  @override
  String spotsDateDaysAgo(Object count) {
    return 'Hace $count días';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return 'Hace $count meses';
  }

  @override
  String get spotsDateToday => 'Hoy';

  @override
  String spotsDateWeeksAgo(Object count) {
    return 'Hace $count semanas';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return 'Hace $count años';
  }

  @override
  String get spotsDateYesterday => 'Ayer';

  @override
  String get spotsDescriptionLabel => 'Descripción';

  @override
  String get spotsNameLabel => 'Nombre del Lugar';

  @override
  String get spotsNoReviews =>
      'Aún no hay reseñas. ¡Sé el primero en escribir una!';

  @override
  String get spotsNoSpotsFound => 'No se encontraron lugares';

  @override
  String get spotsReviewAdded => '¡Reseña añadida!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Reseñas ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Comparte tu experiencia...';

  @override
  String get spotsSubmitReview => 'Enviar reseña';

  @override
  String get spotsWriteReview => 'Escribir una reseña';

  @override
  String get spotsYourRating => 'Tu calificación';

  @override
  String get standardTier => 'Estándar';

  @override
  String get startChat => 'Iniciar Chat';

  @override
  String get startConversation => 'Iniciar una conversación';

  @override
  String get startGame => 'Iniciar Partida';

  @override
  String get startLearning => 'Empezar a Aprender';

  @override
  String get startLessonBtn => 'Empezar Lección';

  @override
  String get startSwipingToFindMatches =>
      '¡Comienza a deslizar para encontrar tus coincidencias!';

  @override
  String get step => 'Paso';

  @override
  String get stepOf => 'de';

  @override
  String get storiesAddCaptionHint => 'Añadir una descripción...';

  @override
  String get storiesCreateStory => 'Crear historia';

  @override
  String storiesDaysAgo(Object count) {
    return 'Hace ${count}d';
  }

  @override
  String get storiesDisappearAfter24h =>
      'Tu historia desaparecerá después de 24 horas';

  @override
  String get storiesGallery => 'Galería';

  @override
  String storiesHoursAgo(Object count) {
    return 'Hace ${count}h';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return 'Hace ${count}min';
  }

  @override
  String get storiesNoActive => 'No hay historias activas';

  @override
  String get storiesNoStories => 'No hay historias disponibles';

  @override
  String get storiesPhoto => 'Foto';

  @override
  String get storiesPost => 'Publicar';

  @override
  String get storiesSendMessageHint => 'Enviar un mensaje...';

  @override
  String get storiesShareMoment => 'Comparte un momento';

  @override
  String get storiesVideo => 'Vídeo';

  @override
  String get storiesYourStory => 'Tu historia';

  @override
  String get streakActiveToday => 'Activo hoy';

  @override
  String get streakBonusHeader => '¡Bonificación por Racha!';

  @override
  String get streakInactive => '¡Empieza tu racha!';

  @override
  String get streakMessageIncredible => '¡Dedicación increíble!';

  @override
  String get streakMessageKeepItUp => '¡Sigue así!';

  @override
  String get streakMessageMomentum => '¡Ganando impulso!';

  @override
  String get streakMessageOneWeek => '¡Una semana cumplida!';

  @override
  String get streakMessageTwoWeeks => '¡Dos semanas seguidas!';

  @override
  String get submitAnswer => 'Enviar Respuesta';

  @override
  String get submitVerification => 'Enviar para Verificación';

  @override
  String submittedOn(String date) {
    return 'Enviado el $date';
  }

  @override
  String get subscribe => 'Suscribirse';

  @override
  String get subscribeNow => 'Suscribirse ahora';

  @override
  String get subscriptionExpired => 'Suscripción expirada';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Tu suscripción $tierName ha expirado. Has sido movido al nivel Free.\n\n¡Actualiza en cualquier momento para restaurar tus funciones premium!';
  }

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get superLike => 'Conexión Prioritaria';

  @override
  String superLikedYou(String name) {
    return '¡$name conectó prioritariamente contigo!';
  }

  @override
  String get superLikes => 'Conexiones Prioritarias';

  @override
  String get supportCenter => 'Centro de Soporte';

  @override
  String get supportCenterSubtitle =>
      'Obtener ayuda, reportar problemas, contáctanos';

  @override
  String get swipeIndicatorLike => 'CONECTAR';

  @override
  String get swipeIndicatorNope => 'PASAR';

  @override
  String get swipeIndicatorSkip => 'EXPLORAR';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITARIO';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get takeVerificationPhoto => 'Tomar Foto de Verificación';

  @override
  String get tapToContinue => 'Toca para continuar';

  @override
  String get targetLanguage => 'Idioma Objetivo';

  @override
  String get termsAndConditions => 'Términos y Condiciones';

  @override
  String get thatsYourOwnProfile => '¡Ese es tu propio perfil!';

  @override
  String get thirdPartyDataDescription =>
      'Permitir compartir datos anonimizados con socios para mejorar el servicio';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get tierFree => 'Gratis';

  @override
  String get timeRemaining => 'Tiempo restante';

  @override
  String get timeoutError => 'Tiempo de espera agotado';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% al Nivel $level';
  }

  @override
  String get today => 'hoy';

  @override
  String get totalXpLabel => 'XP Total';

  @override
  String get tourDiscoveryDescription =>
      'Desliza perfiles para encontrar tu match perfecto. Desliza a la derecha si te interesa, a la izquierda para pasar.';

  @override
  String get tourDiscoveryTitle => 'Descubre Matches';

  @override
  String get tourDone => 'Listo';

  @override
  String get tourLearnDescription =>
      'Estudia vocabulario, gramática y habilidades de conversación';

  @override
  String get tourLearnTitle => 'Aprende Idiomas';

  @override
  String get tourMatchesDescription =>
      '¡Ve a todos los que también les gustaste! Inicia conversaciones con tus matches mutuos.';

  @override
  String get tourMatchesTitle => 'Tus Matches';

  @override
  String get tourMessagesDescription =>
      'Chatea con tus matches aquí. Envía mensajes, fotos y notas de voz para conectar.';

  @override
  String get tourMessagesTitle => 'Mensajes';

  @override
  String get tourNext => 'Siguiente';

  @override
  String get tourPlayDescription =>
      'Desafía a otros en divertidos juegos de idiomas';

  @override
  String get tourPlayTitle => 'Juega';

  @override
  String get tourProfileDescription =>
      'Personaliza tu perfil, administra configuraciones y controla tu privacidad.';

  @override
  String get tourProfileTitle => 'Tu Perfil';

  @override
  String get tourProgressDescription =>
      '¡Gana insignias, completa desafíos y sube en la clasificación!';

  @override
  String get tourProgressTitle => 'Sigue Tu Progreso';

  @override
  String get tourShopDescription =>
      'Obtén monedas y funciones premium para mejorar tu experiencia.';

  @override
  String get tourShopTitle => 'Tienda y Monedas';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get trialWelcomeTitle => '¡Bienvenido a GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Estás usando la versión de prueba. Tu membresía base gratuita está activa hasta $expirationDate. ¡Disfruta explorando GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Empezar';

  @override
  String get translateWord => 'Traduce esta palabra';

  @override
  String get translationDownloadExplanation =>
      'Para activar la traducción automática de mensajes, necesitamos descargar datos de idiomas para uso sin conexión.';

  @override
  String get travelCategory => 'Viaje';

  @override
  String get travelLabel => 'Viaje';

  @override
  String get travelerAppearFor24Hours =>
      'Aparecerás en los resultados de descubrimiento de esta ubicación durante 24 horas.';

  @override
  String get travelerBadge => 'Viajero';

  @override
  String get travelerChangeLocation => 'Cambiar ubicación';

  @override
  String get travelerConfirmLocation => 'Confirmar ubicación';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'No se pudo obtener la ubicación: $error';
  }

  @override
  String get travelerGettingLocation => 'Obteniendo ubicación...';

  @override
  String travelerInCity(String city) {
    return 'En $city';
  }

  @override
  String get travelerLoadingAddress => 'Cargando dirección...';

  @override
  String get travelerLocationInfo =>
      'Aparecerás en los resultados de descubrimiento de esta ubicación durante 24 horas.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Permisos de ubicación denegados';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Permisos de ubicación denegados permanentemente';

  @override
  String get travelerLocationServicesDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String travelerModeActivated(String city) {
    return '¡Modo viajero activado! Apareciendo en $city durante 24 horas.';
  }

  @override
  String get travelerModeActive => 'Modo viajero activo';

  @override
  String get travelerModeDeactivated =>
      'Modo viajero desactivado. De vuelta a tu ubicación real.';

  @override
  String get travelerModeDescription =>
      'Aparece en el feed de descubrimiento de otra ciudad durante 24 horas';

  @override
  String get travelerModeTitle => 'Modo Viajero';

  @override
  String travelerNoResultsFor(Object query) {
    return 'No se encontraron resultados para \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Elegir en el mapa';

  @override
  String get travelerProfileAppearDescription =>
      'Tu perfil aparecerá en el feed de descubrimiento de esa ubicación durante 24 horas con una insignia de viajero.';

  @override
  String get travelerSearchHint =>
      'Tu perfil aparecerá en el feed de descubrimiento de esa ubicación durante 24 horas con una insignia de Viajero.';

  @override
  String get travelerSearchOrGps => 'Busca una ciudad o usa GPS';

  @override
  String get travelerSelectOnMap => 'Seleccionar en el mapa';

  @override
  String get travelerSelectThisLocation => 'Seleccionar esta ubicación';

  @override
  String get travelerSelectTravelLocation => 'Seleccionar ubicación de viaje';

  @override
  String get travelerTapOnMap => 'Toca el mapa para seleccionar una ubicación';

  @override
  String get travelerUseGps => 'Usar GPS';

  @override
  String get tryAgain => 'Intentar de Nuevo';

  @override
  String get tryDifferentSearchOrFilter =>
      'Prueba una búsqueda o filtro diferente';

  @override
  String get twoFaDisabled => 'Autenticación 2FA desactivada';

  @override
  String get twoFaEnabled => 'Autenticación 2FA activada';

  @override
  String get twoFaToggleSubtitle =>
      'Requerir verificación por código de email en cada inicio de sesión';

  @override
  String get twoFaToggleTitle => 'Activar Autenticación 2FA';

  @override
  String get typeMessage => 'Escribe un mensaje...';

  @override
  String get typeQuizzes => 'Quizzes';

  @override
  String get typeStreak => 'Racha';

  @override
  String typeWordStartingWith(String letter) {
    return 'Escribe una palabra que empiece con \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Palabras Aprendidas';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'No se puede cargar el perfil';

  @override
  String get unableToPlayVoiceIntro =>
      'No se pudo reproducir la introducción de voz';

  @override
  String get undoSwipe => 'Deshacer Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unidad $number';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get unlock => 'Desbloquear';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Desbloquea $count perfiles más en la cuadrícula por $cost monedas.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Estas seguro de que quieres deshacer el match con $name? Esto no se puede deshacer.';
  }

  @override
  String get unmatchLabel => 'Deshacer Match';

  @override
  String unmatchedWith(String name) {
    return 'Dejaste de ser match con $name';
  }

  @override
  String get upgrade => 'Mejorar';

  @override
  String get upgradeForEarlyAccess =>
      '¡Actualiza a Plata, Oro o Platino para acceso anticipado el 1 de marzo de 2026!';

  @override
  String get upgradeNow => 'Mejorar Ahora';

  @override
  String get upgradeToPremium => 'Actualizar a Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Mejora a $tier';
  }

  @override
  String get uploadPhoto => 'Subir Foto';

  @override
  String get uppercaseLowercase => 'Letras mayúsculas y minúsculas';

  @override
  String get useCurrentGpsLocation => 'Usar mi ubicación GPS actual';

  @override
  String get usedToday => 'Usados hoy';

  @override
  String get usedWords => 'Palabras Usadas';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName ha sido bloqueado';
  }

  @override
  String get userBlockedTitle => '¡Usuario Bloqueado!';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get usernameOrProfileUrl => 'Nombre de usuario o URL del perfil';

  @override
  String get usernameWithoutAt => 'Nombre de usuario (sin @)';

  @override
  String get verificationApproved => 'Verificación Aprobada';

  @override
  String get verificationApprovedMessage =>
      'Tu identidad ha sido verificada. Ahora tienes acceso completo a la app.';

  @override
  String get verificationApprovedSuccess =>
      'Verificación aprobada exitosamente';

  @override
  String get verificationDescription =>
      'Para garantizar la seguridad de nuestra comunidad, requerimos que todos los usuarios verifiquen su identidad. Toma una foto de ti mismo sosteniendo tu documento de identidad.';

  @override
  String get verificationHistory => 'Historial de Verificaciones';

  @override
  String get verificationInstructions =>
      'Sostén tu documento de identidad (pasaporte, licencia de conducir o DNI) junto a tu rostro y toma una foto clara.';

  @override
  String get verificationNeedsResubmission => 'Se Requiere Mejor Foto';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Necesitamos una foto más clara para la verificación. Por favor reenvía.';

  @override
  String get verificationPanel => 'Panel de Verificación';

  @override
  String get verificationPending => 'Verificación Pendiente';

  @override
  String get verificationPendingMessage =>
      'Tu cuenta está siendo verificada. Esto generalmente toma 24-48 horas. Serás notificado cuando la revisión esté completa.';

  @override
  String get verificationRejected => 'Verificación Rechazada';

  @override
  String get verificationRejectedMessage =>
      'Tu verificación fue rechazada. Por favor envía una nueva foto.';

  @override
  String get verificationRejectedSuccess => 'Verificación rechazada';

  @override
  String get verificationRequired => 'Verificación de Identidad Requerida';

  @override
  String get verificationSkipWarning =>
      'Puedes explorar la app, pero no podrás chatear o ver otros perfiles hasta que estés verificado.';

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
  String get verificationTips => 'Consejos para una verificación exitosa:';

  @override
  String get verificationTitle => 'Verifica Tu Identidad';

  @override
  String get verifyNow => 'Verificar Ahora';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit tags seleccionados';
  }

  @override
  String get vibeTagsGet5Tags => 'Obtener 5 tags';

  @override
  String get vibeTagsGetAccessTo => 'Obtener acceso a:';

  @override
  String get vibeTagsLimitReached => 'Límite de tags alcanzado';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Los usuarios gratuitos pueden seleccionar hasta $limit tags. ¡Actualiza a Premium para obtener 5 tags!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Has alcanzado tu máximo de $limit tags. Elimina uno para añadir otro.';
  }

  @override
  String get vibeTagsNoTags => 'No hay tags disponibles';

  @override
  String get vibeTagsPremiumFeature1 => '5 vibe tags en lugar de 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Tags premium exclusivos';

  @override
  String get vibeTagsPremiumFeature3 => 'Prioridad en resultados de búsqueda';

  @override
  String get vibeTagsPremiumFeature4 => '¡Y mucho más!';

  @override
  String get vibeTagsRemoveTag => 'Eliminar tag';

  @override
  String get vibeTagsSelectDescription =>
      'Selecciona tags que coincidan con tu estado de ánimo e intenciones actuales';

  @override
  String get vibeTagsSetTemporary => 'Establecer como tag temporal (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Muestra tu vibra';

  @override
  String get vibeTagsTemporaryDescription =>
      'Muestra esta vibra durante las próximas 24 horas';

  @override
  String get vibeTagsTemporaryTag => 'Tag temporal (24h)';

  @override
  String get vibeTagsTitle => 'Tu vibra';

  @override
  String get vibeTagsUpgradeToPremium => 'Actualizar a Premium';

  @override
  String get vibeTagsViewPlans => 'Ver planes';

  @override
  String get vibeTagsYourSelected => 'Tus tags seleccionados';

  @override
  String get videoCallCategory => 'Videollamada';

  @override
  String get view => 'Ver';

  @override
  String get viewAllChallenges => 'Ver Todos los Desafíos';

  @override
  String get viewAllLabel => 'Ver Todo';

  @override
  String get viewBadgesAchievementsLevel => 'Ver insignias, logros y nivel';

  @override
  String get viewMyProfile => 'Ver Mi Perfil';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'MIEMBRO ORO';

  @override
  String get vipPlatinumMember => 'PLATINO VIP';

  @override
  String get vipPremiumBenefitsActive => 'Beneficios Premium Activos';

  @override
  String get vipSilverMember => 'MIEMBRO PLATA';

  @override
  String get virtualGiftsAddMessageHint => 'Añadir un mensaje (opcional)';

  @override
  String get voiceDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar tu presentación de voz?';

  @override
  String get voiceDeleteRecording => 'Eliminar Grabación';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'No se pudo iniciar la grabación: $error';
  }

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'No se pudo subir la grabación: $error';
  }

  @override
  String get voiceIntro => 'Presentación de Voz';

  @override
  String get voiceIntroSaved => 'Presentación de voz guardada';

  @override
  String get voiceIntroShort => 'Intro de Voz';

  @override
  String get voiceIntroduction => 'Introducción de Voz';

  @override
  String get voiceIntroductionInfo =>
      'Las presentaciones de voz ayudan a otros a conocerte mejor. Este paso es opcional.';

  @override
  String get voiceIntroductionSubtitle =>
      'Graba un mensaje de voz corto (opcional)';

  @override
  String get voiceIntroductionTitle => 'Presentación de voz';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Se requiere permiso del micrófono';

  @override
  String get voiceRecordAgain => 'Grabar de Nuevo';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Graba una breve presentación de $seconds segundos para que otros escuchen tu personalidad.';
  }

  @override
  String get voiceRecorded => 'Voz grabada';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Grabando... (máx. $maxDuration segundos)';
  }

  @override
  String get voiceRecordingReady => 'Grabación lista';

  @override
  String get voiceRecordingSaved => 'Grabación guardada';

  @override
  String get voiceRecordingTips => 'Consejos de Grabación';

  @override
  String get voiceSavedMessage => 'Tu introducción de voz ha sido actualizada';

  @override
  String get voiceSavedTitle => '¡Voz Guardada!';

  @override
  String get voiceStandOutWithYourVoice => '¡Destaca con tu voz!';

  @override
  String get voiceTapToRecord => 'Toca para grabar';

  @override
  String get voiceTipBeYourself => 'Sé tú mismo y natural';

  @override
  String get voiceTipFindQuietPlace => 'Encuentra un lugar tranquilo';

  @override
  String get voiceTipKeepItShort => 'Mantenlo breve y dulce';

  @override
  String get voiceTipShareWhatMakesYouUnique => 'Comparte lo que te hace único';

  @override
  String get voiceUploadFailed => 'Error al subir la grabación de voz';

  @override
  String get voiceUploading => 'Subiendo...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic =>
      'Tu acceso comenzará el 15 de marzo de 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return '¡Como miembro $tier, tienes acceso anticipado el 1 de marzo de 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'Tu Fecha de Acceso';

  @override
  String waitingCountLabel(String count) {
    return '$count esperando';
  }

  @override
  String get waitingCountdownLabel => 'Cuenta regresiva para el lanzamiento';

  @override
  String get waitingCountdownSubtitle =>
      '¡Gracias por registrarte! GreenGo Chat se lanzará pronto. Prepárate para una experiencia exclusiva.';

  @override
  String get waitingCountdownTitle => 'Cuenta Regresiva para el Lanzamiento';

  @override
  String waitingDaysRemaining(int days) {
    return '$days días';
  }

  @override
  String get waitingEarlyAccessMember => 'Miembro de Acceso Anticipado';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Activa las notificaciones para ser el primero en saber cuándo puedes acceder a la app.';

  @override
  String get waitingEnableNotificationsTitle => 'Mantente actualizado';

  @override
  String get waitingExclusiveAccess => 'Tu fecha de acceso exclusivo';

  @override
  String get waitingForPlayers => 'Esperando jugadores...';

  @override
  String get waitingForVerification => 'Esperando verificación...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours horas';
  }

  @override
  String get waitingMessageApproved =>
      '¡Buenas noticias! Tu cuenta ha sido aprobada. Podrás acceder a GreenGoChat en la fecha indicada a continuación.';

  @override
  String get waitingMessagePending =>
      'Tu cuenta está pendiente de aprobación por nuestro equipo. Te notificaremos una vez que tu cuenta haya sido revisada.';

  @override
  String get waitingMessageRejected =>
      'Lamentablemente, tu cuenta no pudo ser aprobada en este momento. Por favor contacta a soporte para más información.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notificaciones habilitadas - ¡te avisaremos cuando puedas acceder a la app!';

  @override
  String get waitingProfileUnderReview => 'Perfil en revisión';

  @override
  String get waitingReviewMessage =>
      '¡La app ya está activa! Nuestro equipo está revisando tu perfil para garantizar la mejor experiencia para nuestra comunidad. Esto suele tardar 24-48 horas.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get waitingStayTuned =>
      '¡Mantente atento! Te notificaremos cuando sea hora de comenzar a conectar.';

  @override
  String get waitingStepActivation => 'Activación de cuenta';

  @override
  String get waitingStepRegistration => 'Registro completado';

  @override
  String get waitingStepReview => 'Revisión de perfil en progreso';

  @override
  String get waitingSubtitle => 'Tu cuenta ha sido creada exitosamente';

  @override
  String get waitingThankYouRegistration => '¡Gracias por registrarte!';

  @override
  String get waitingTitle => '¡Gracias por Registrarte!';

  @override
  String get weeklyChallengesTitle => 'Desafíos Semanales';

  @override
  String get weight => 'Peso';

  @override
  String get weightLabel => 'Peso';

  @override
  String get welcome => 'Bienvenido a GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Palabra ya usada';

  @override
  String get wordReported => 'Palabra reportada';

  @override
  String get xTwitter => 'X (Twitter)';

  @override
  String get xp => 'XP';

  @override
  String xpAmountLabel(String amount) {
    return '$amount XP';
  }

  @override
  String xpEarned(String amount) {
    return '$amount XP ganados';
  }

  @override
  String get xpLabel => 'XP';

  @override
  String xpProgressLabel(String current, String max) {
    return '$current / $max XP';
  }

  @override
  String xpRewardLabel(String xp) {
    return '+$xp XP';
  }

  @override
  String get yearlyMembership => 'Membresía anual — \$4.99/año';

  @override
  String yearsLabel(int age) {
    return '$age anos';
  }

  @override
  String get yes => 'Sí';

  @override
  String get yesterday => 'ayer';

  @override
  String youAndMatched(String name) {
    return 'Tú y $name se gustaron mutuamente';
  }

  @override
  String get youGotSuperLike => '¡Recibiste una Conexión Prioritaria!';

  @override
  String get youLabel => 'TU';

  @override
  String get youLose => 'Perdiste';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Hiciste match con $name el $date';
  }

  @override
  String get youWin => '¡Ganaste!';

  @override
  String get yourLanguages => 'Tus Idiomas';

  @override
  String get yourRankLabel => 'Tu Rango';

  @override
  String get yourTurn => '¡Tu Turno!';

  @override
  String get achievementBadges => 'Insignias de Logros';

  @override
  String get achievementBadgesSubtitle =>
      'Toca para seleccionar qué insignias mostrar en tu perfil (máx. 5)';

  @override
  String get noBadgesYet => '¡Desbloquea logros para ganar insignias!';

  @override
  String get guideTitle => 'Cómo funciona GreenGo';

  @override
  String get guideSwipeTitle => 'Deslizar perfiles';

  @override
  String get guideSwipeItem1 =>
      'Desliza a la derecha para Connect con alguien, desliza a la izquierda para Nope.';

  @override
  String get guideSwipeItem2 =>
      'Desliza hacia arriba para enviar un Priority Connect (usa monedas).';

  @override
  String get guideSwipeItem3 =>
      'Desliza hacia abajo para Explore Next y saltar un perfil por ahora.';

  @override
  String get guideSwipeItem4 =>
      'Puedes cambiar entre el modo deslizar y el modo cuadrícula usando el icono de alternar en la barra superior.';

  @override
  String get guideGridTitle => 'Vista de cuadrícula';

  @override
  String get guideGridItem1 =>
      'Explora perfiles en una vista de cuadrícula para una visión rápida.';

  @override
  String get guideGridItem2 =>
      'Toca una imagen de perfil para mostrar los cuatro botones de acción: Connect, Priority Connect, Nope y Explore Next.';

  @override
  String get guideGridItem3 =>
      'Mantén presionada una imagen de perfil para ver sus detalles sin abrir el perfil completo.';

  @override
  String get guideConnectionsTitle => 'Conectar con personas';

  @override
  String get guideConnectionsItem1 =>
      '¡Cuando dos personas hacen Connect mutuamente, es un match!';

  @override
  String get guideConnectionsItem2 =>
      'Después de hacer match, puedes empezar a chatear de inmediato.';

  @override
  String get guideConnectionsItem3 =>
      'Usa Priority Connect para destacar y aumentar tus posibilidades.';

  @override
  String get guideConnectionsItem4 =>
      'Consulta la pestaña de Intercambios para ver todos tus matches y conversaciones.';

  @override
  String get guideChatTitle => 'Chat y mensajería';

  @override
  String get guideChatItem1 => 'Envía mensajes de texto, fotos y notas de voz.';

  @override
  String get guideChatItem2 =>
      'Usa la función de traducción para chatear en diferentes idiomas.';

  @override
  String get guideChatItem3 =>
      'Abre los ajustes del chat para personalizar tu experiencia: activa la corrección gramatical, respuestas inteligentes, consejos culturales, desglose de palabras, ayuda con la pronunciación y más.';

  @override
  String get guideChatItem4 =>
      'Activa texto a voz para escuchar las traducciones, mostrar banderas de idiomas y hacer seguimiento de tus XP de aprendizaje de idiomas.';

  @override
  String get guideFiltersTitle => 'Filtros de descubrimiento';

  @override
  String get guideFiltersItem1 =>
      'Toca el icono de filtro para establecer tus preferencias: rango de edad, distancia, idiomas y más.';

  @override
  String get guideFiltersItem2 =>
      'El filtro de país es opcional. Cuando no hay ningún país seleccionado, verás las personas más cercanas en todo el mundo (hasta 500). Agrega países para limitar tu búsqueda a regiones específicas.';

  @override
  String get guideFiltersItem3 =>
      'Los filtros te ayudan a encontrar personas que coincidan con lo que buscas. Puedes ajustarlos en cualquier momento.';

  @override
  String get guideTravelTitle => 'Viajes y exploración';

  @override
  String get guideTravelItem1 =>
      'Activa el Modo Viajero para aparecer en el descubrimiento de una ciudad que planeas visitar durante 24 horas.';

  @override
  String get guideTravelItem2 =>
      'Los guías locales pueden ayudar a los viajeros a descubrir su ciudad y cultura.';

  @override
  String get guideTravelItem3 =>
      'Los compañeros de intercambio de idiomas se emparejan según lo que hablas y lo que quieres aprender.';

  @override
  String get guideMembershipTitle => 'Membresía básica';

  @override
  String get guideMembershipItem1 =>
      'Tu membresía básica te da acceso a todas las funciones principales: deslizar, chatear y hacer match.';

  @override
  String get guideMembershipItem2 =>
      'La membresía comienza con una prueba gratuita después de tu primer registro.';

  @override
  String get guideMembershipItem3 =>
      'Cuando tu membresía expire, puedes renovarla para seguir usando la aplicación.';

  @override
  String get guideTiersTitle => 'Niveles VIP (Plata, Oro, Platino)';

  @override
  String get guideTiersItem1 =>
      'Silver: Obtén más connects diarios, ve quién hizo Connect contigo y soporte prioritario.';

  @override
  String get guideTiersItem2 =>
      'Gold: Todo lo de Silver más connects ilimitados, filtros avanzados y confirmaciones de lectura.';

  @override
  String get guideTiersItem3 =>
      'Platino: Todo lo de Oro más impulso de perfil, mejores selecciones y funciones exclusivas.';

  @override
  String get guideTiersItem4 =>
      'Los niveles VIP son independientes de tu membresía básica y proporcionan beneficios adicionales.';

  @override
  String get guideCoinsTitle => 'Monedas';

  @override
  String get guideCoinsItem1 =>
      'Las monedas se usan para acciones premium. Estos son los costes:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 monedas  • Boost: 50 monedas  • Mensaje directo: 50 monedas';

  @override
  String get guideCoinsItem3 =>
      '• Incógnito: 30 monedas/día  • Viajero: 100 monedas/día';

  @override
  String get guideCoinsItem4 =>
      '• Escuchar (TTS): 5 monedas  • Ampliar cuadrícula: 10 monedas  • Coach de aprendizaje: 10 monedas/sesión';

  @override
  String get guideCoinsItem5 =>
      'Recibes 20 monedas gratis al día. Gana más con logros, clasificaciones y la Tienda.';

  @override
  String get guideLeaderboardTitle => 'Tabla de posiciones';

  @override
  String get guideLeaderboardItem1 =>
      'Compite con otros usuarios para subir en la tabla de posiciones y ganar recompensas.';

  @override
  String get guideLeaderboardItem2 =>
      'Gana puntos siendo activo, completando tu perfil e interactuando con otros.';

  @override
  String get guideSafetyTitle => 'Seguridad y privacidad';

  @override
  String get guideSafetyItem1 =>
      'Todas las fotos son verificadas por IA para garantizar perfiles auténticos.';

  @override
  String get guideSafetyItem2 =>
      'Puedes bloquear o reportar a cualquier usuario en cualquier momento desde su perfil.';

  @override
  String get guideSafetyItem3 =>
      'Tu información personal está protegida y nunca se comparte sin tu consentimiento.';

  @override
  String get firstStepsTitle => 'First Steps';

  @override
  String get firstStepsReview =>
      'Your documents will be reviewed within 24-48 hours after submission.';

  @override
  String get firstStepsStatusUpdate =>
      'The app needs approximately 15 minutes to update your current status after first login.';

  @override
  String get firstStepsSupportChat =>
      'You can contact support through chat or by opening a ticket directly.';

  @override
  String get showSupportUser => 'Show GreenGo Support';

  @override
  String get showSupportUserDescription =>
      'Show GreenGo Support user in discovery grid';

  @override
  String get randomMode => 'Random Mode';

  @override
  String get randomModeDescription =>
      'Discover random people from all over the world, sorted by distance. When off, only people close to you are shown.';

  @override
  String get yourProfile => 'You';
}
