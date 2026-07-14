// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get culturalPassportTitle => 'Passaporte Cultural';

  @override
  String get culturalPassportSubtitle =>
      'Carimbos que colecionas das culturas, idiomas e eventos que exploras';

  @override
  String get passportSectionCountries => 'Países';

  @override
  String get passportSectionLanguages => 'Idiomas';

  @override
  String get passportSectionEvents => 'Eventos';

  @override
  String get passportLoading => 'A carregar o teu passaporte…';

  @override
  String get passportEarned => 'Conquistado';

  @override
  String get passportLocked => 'Bloqueado';

  @override
  String get passportEmpty =>
      'Começa a conversar, aprender idiomas e participar em eventos para ganhares os teus primeiros carimbos.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries países · $languages idiomas · $events eventos';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% explorado';
  }

  @override
  String get passportEventDating => 'Encontros';

  @override
  String get passportEventSocial => 'Social';

  @override
  String get passportEventSports => 'Desporto';

  @override
  String get passportEventFood => 'Comida';

  @override
  String get passportEventNightlife => 'Vida noturna';

  @override
  String get passportEventOutdoor => 'Ar livre';

  @override
  String get passportEventArts => 'Artes';

  @override
  String get passportEventGaming => 'Jogos';

  @override
  String get passportEventTravel => 'Viagens';

  @override
  String get passportEventWellness => 'Bem-estar';

  @override
  String get passportEventLanguageExchange => 'Intercâmbio de idiomas';

  @override
  String get passportEventOther => 'Outro';

  @override
  String get tourGotIt => 'Entendido';

  @override
  String get tourWelcomeTitle => 'Bem-vindo ao GreenGo!';

  @override
  String get tourWelcomeDesc =>
      'Esta é a tua grelha de Descoberta: pessoas reais perto de ti, ordenadas por distância. Vamos aprender os gestos que tornam o GreenGo rápido de usar.';

  @override
  String get tourCardTapTitle => 'Toca num cartão';

  @override
  String get tourCardTapDesc =>
      'Toca no centro de um cartão para abrir o menu de ações: gostar, super like ou ver o perfil completo.';

  @override
  String get tourCardEdgeTitle => 'Percorre as fotos';

  @override
  String get tourCardEdgeDesc =>
      'Toca na margem esquerda ou direita de um cartão para percorrer as fotos da pessoa sem sair da grelha.';

  @override
  String get tourCardHoldTitle => 'Mantém para pré-visualizar';

  @override
  String get tourCardHoldDesc =>
      'Mantém um cartão premido para ver as fotos em ecrã inteiro.';

  @override
  String get tourRefreshTitle => 'Puxa para atualizar';

  @override
  String get tourRefreshDesc =>
      'Arrasta a grelha para baixo em qualquer altura para carregar as pessoas mais recentes perto de ti.';

  @override
  String get tourModeToggleTitle => 'Modo swipe';

  @override
  String get tourModeToggleDesc =>
      'Toca aqui para alternar entre grelha e modo swipe. No modo swipe: desliza para a direita para gostar, para a esquerda para passar, para cima para super like.';

  @override
  String get tourGlobeTitle => 'Explora o globo';

  @override
  String get tourGlobeDesc =>
      'Abre o globo 3D para descobrir pessoas de todo o mundo, não apenas por perto.';

  @override
  String get tourSearchTitle => 'Procura por alcunha';

  @override
  String get tourSearchDesc =>
      'Sabes quem procuras? Encontra pessoas diretamente pela alcunha.';

  @override
  String get tourPrefsTitle => 'Filtros de descoberta';

  @override
  String get tourPrefsDesc =>
      'Ajusta quem descobres: distância, idade, idiomas, país e mais.';

  @override
  String get tourCoinsTitle => 'As tuas moedas';

  @override
  String get tourCoinsDesc =>
      'Recebes moedas grátis todos os dias. Toca no teu saldo em qualquer altura para abrir a Loja.';

  @override
  String get tourHelpTitle => 'Precisas de relembrar?';

  @override
  String get tourHelpDesc =>
      'O guia da app está aqui — incluindo este tutorial, que podes repetir quando quiseres.';

  @override
  String get tourNavMessagesTitle => 'Mensagens';

  @override
  String get tourNavMessagesDesc =>
      'Conversa sem barreiras de idioma: mantém uma mensagem premida para a traduzir, toca duas vezes para a ouvir.';

  @override
  String get tourNavLeaderboardTitle => 'Classificação';

  @override
  String get tourNavLeaderboardDesc =>
      'Ganha XP e distintivos enquanto te ligas, conversas e aprendes. Vê a tua posição.';

  @override
  String get tourNavShopTitle => 'Loja';

  @override
  String get tourNavShopDesc =>
      'Pacotes de moedas e subscrições para desbloquear mais do GreenGo.';

  @override
  String get tourNavProfileTitle => 'O teu perfil';

  @override
  String get tourNavProfileDesc =>
      'Completa o teu perfil e a verificação para seres descoberto por mais pessoas.';

  @override
  String get tourFinishTitle => 'Tudo pronto!';

  @override
  String get tourFinishDesc =>
      'Diverte-te a descobrir novas pessoas e culturas. Podes repetir este tutorial em qualquer altura a partir do guia (ícone ?).';

  @override
  String get tourSwipeHintTitle => 'Desliza para te ligares';

  @override
  String get tourSwipeHintLike => 'Gosto';

  @override
  String get tourSwipeHintPass => 'Passar';

  @override
  String get tourSwipeHintSuper => 'Super like';

  @override
  String get tourChatHoldTitle => 'Mantém uma mensagem';

  @override
  String get tourChatHoldDesc =>
      'Mantém qualquer mensagem premida para a traduzir, copiar ou reencaminhar.';

  @override
  String get tourChatDoubleTapTitle => 'Ouve a mensagem';

  @override
  String get tourChatDoubleTapDesc =>
      'Toca duas vezes numa mensagem recebida para ouvir a pronúncia.';

  @override
  String get tourChatLanguageTitle => 'Idiomas e aprendizagem';

  @override
  String get tourChatLanguageDesc =>
      'Abre o menu de tradução para ferramentas de idioma: definições de tradução, prática de pronúncia e funções de aprendizagem.';

  @override
  String get tourChatSettingsTitle => 'Opções da conversa';

  @override
  String get tourChatSettingsDesc =>
      'Gere esta conversa: definições da conversa, eliminar, bloquear ou denunciar.';

  @override
  String get tourDetailDoubleTapTitle => 'Gosta de uma foto';

  @override
  String get tourDetailDoubleTapDesc =>
      'Toca duas vezes em qualquer foto para gostar dela.';

  @override
  String get tourStoryHoldHint => 'Mantém premido para pausar';

  @override
  String get guideReplayTour => 'Repetir tutorial';

  @override
  String get abandonGame => 'Abandonar Jogo';

  @override
  String get about => 'Sobre';

  @override
  String get aboutMe => 'Sobre Mim';

  @override
  String get aboutMeTitle => 'Sobre mim';

  @override
  String get academicCategory => 'Académico';

  @override
  String get acceptPrivacyPolicy => 'Li e aceito a Política de Privacidade';

  @override
  String get acceptProfiling =>
      'Consinto com o perfilamento para recomendações personalizadas';

  @override
  String get acceptTermsAndConditions => 'Li e aceito os Termos e Condições';

  @override
  String get acceptThirdPartyData =>
      'Consinto com o compartilhamento dos meus dados com terceiros';

  @override
  String get accessGranted => 'Acesso Concedido!';

  @override
  String accessGrantedBody(Object tierName) {
    return 'O GreenGo está agora ativo! Como $tierName, tem agora acesso total a todas as funcionalidades.';
  }

  @override
  String get accountApproved => 'Conta Aprovada';

  @override
  String get accountApprovedBody =>
      'A sua conta GreenGo foi aprovada. Bem-vindo à comunidade!';

  @override
  String get accountCreatedSuccess =>
      'Conta criada! Por favor verifique o seu email para validar a sua conta.';

  @override
  String get accountPendingApproval => 'Conta Pendente de Aprovação';

  @override
  String get accountRejected => 'Conta Rejeitada';

  @override
  String get accountSettings => 'Definições da Conta';

  @override
  String get accountUnderReview => 'Conta em Revisão';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Conquistas';

  @override
  String get achievementsSubtitle => 'Ver os teus emblemas e progresso';

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String get addBio => 'Adicionar biografia';

  @override
  String get addDealBreakerTitle => 'Adicionar Criterio Eliminatorio';

  @override
  String get addPhoto => 'Adicionar Foto';

  @override
  String get adjustPreferences => 'Ajustar Preferências';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Código enviado para $email';
  }

  @override
  String get admin2faExpired => 'Código expirado. Solicite um novo.';

  @override
  String get admin2faInvalidCode => 'Código de verificação inválido';

  @override
  String get admin2faMaxAttempts =>
      'Demasiadas tentativas. Solicite um novo código.';

  @override
  String get admin2faResend => 'Reenviar Código';

  @override
  String admin2faResendIn(String seconds) {
    return 'Reenviar em ${seconds}s';
  }

  @override
  String get admin2faSending => 'A enviar código...';

  @override
  String get admin2faSignOut => 'Sair';

  @override
  String get admin2faSubtitle =>
      'Introduza o código de 6 dígitos enviado para o seu email';

  @override
  String get admin2faTitle => 'Verificação Admin';

  @override
  String get admin2faVerify => 'Verificar';

  @override
  String get adminAccessDates => 'Datas de Acesso:';

  @override
  String get adminAccountLockedSuccessfully => 'Conta bloqueada com sucesso';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Conta desbloqueada com sucesso';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Contas admin não podem ser eliminadas';

  @override
  String adminAchievementCount(Object count) {
    return '$count conquistas';
  }

  @override
  String get adminAchievementUpdated => 'Conquista atualizada';

  @override
  String get adminAchievements => 'Conquistas';

  @override
  String get adminAchievementsSubtitle => 'Gerir conquistas e distintivos';

  @override
  String get adminActive => 'ATIVO';

  @override
  String adminActiveCount(Object count) {
    return 'Ativos ($count)';
  }

  @override
  String get adminActiveEvent => 'Evento Ativo';

  @override
  String get adminActiveUsers => 'Utilizadores Ativos';

  @override
  String get adminAdd => 'Adicionar';

  @override
  String get adminAddCoins => 'Adicionar Moedas';

  @override
  String get adminAddPackage => 'Adicionar Pacote';

  @override
  String get adminAddResolutionNote => 'Adicionar nota de resolução...';

  @override
  String get adminAddSingleEmail => 'Adicionar Email Individual';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return 'Adicionadas $amount moedas ao utilizador';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Adicionado $date';
  }

  @override
  String get adminAdvancedFilters => 'Filtros Avançados';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age anos - $gender';
  }

  @override
  String get adminAll => 'Todos';

  @override
  String get adminAllReports => 'Todos os Relatórios';

  @override
  String get adminAmount => 'Montante';

  @override
  String get adminAnalyticsAndReports => 'Análise e Relatórios';

  @override
  String get adminAppSettings => 'Definições da Aplicação';

  @override
  String get adminAppSettingsSubtitle => 'Definições gerais da aplicação';

  @override
  String get adminApproveSelected => 'Aprovar Selecionados';

  @override
  String get adminAssignToMe => 'Atribuir a mim';

  @override
  String get adminAssigned => 'Atribuído';

  @override
  String get adminAvailable => 'Disponível';

  @override
  String get adminBadge => 'Distintivo';

  @override
  String get adminBaseCoins => 'Moedas Base';

  @override
  String get adminBaseXp => 'XP Base';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount moedas bónus';
  }

  @override
  String get adminBonusCoinsLabel => 'Moedas Bónus';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes bónus';
  }

  @override
  String get adminBrowseProfilesAnonymously => 'Navegar em perfis anonimamente';

  @override
  String get adminCanSendMedia => 'Pode Enviar Multimédia';

  @override
  String adminChallengeCount(Object count) {
    return '$count desafios';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Interface de criação de desafios em breve.';

  @override
  String get adminChallenges => 'Desafios';

  @override
  String get adminChangesSaved => 'Alterações guardadas';

  @override
  String get adminChatWithReporter => 'Conversar com o Denunciante';

  @override
  String get adminClear => 'Limpar';

  @override
  String get adminClosed => 'Fechado';

  @override
  String get adminCoinAmount => 'Montante de Moedas';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount Moedas';
  }

  @override
  String get adminCoinCost => 'Custo em Moedas';

  @override
  String get adminCoinManagement => 'Gestão de Moedas';

  @override
  String get adminCoinManagementSubtitle =>
      'Gerir pacotes de moedas e saldos de utilizadores';

  @override
  String get adminCoinPackages => 'Pacotes de Moedas';

  @override
  String get adminCoinReward => 'Recompensa em Moedas';

  @override
  String adminComingSoon(Object route) {
    return '$route em breve';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configurações repostas para valores predefinidos. Guarde para aplicar.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Configurar limites e funcionalidades';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configurar recompensas de marco para logins consecutivos';

  @override
  String get adminCreateChallenge => 'Criar Desafio';

  @override
  String get adminCreateEvent => 'Criar Evento';

  @override
  String get adminCreateNewChallenge => 'Criar Novo Desafio';

  @override
  String get adminCreateSeasonalEvent => 'Criar Evento Sazonal';

  @override
  String get adminCsvFormat => 'Formato CSV:';

  @override
  String get adminCsvFormatDescription =>
      'Um email por linha, ou valores separados por vírgula. As aspas são removidas automaticamente. Emails inválidos são ignorados.';

  @override
  String get adminCurrentBalance => 'Saldo Atual';

  @override
  String get adminDailyChallenges => 'Desafios Diários';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configurar desafios diários e recompensas';

  @override
  String get adminDailyLimits => 'Limites Diários';

  @override
  String get adminDailyLoginRewards => 'Recompensas de Login Diário';

  @override
  String get adminDailyMessages => 'Mensagens Diárias';

  @override
  String get adminDailySuperLikes => 'Conexões Prioritárias Diárias';

  @override
  String get adminDailySwipes => 'Swipes Diários';

  @override
  String get adminDashboard => 'Painel de Administração';

  @override
  String get adminDate => 'Data';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Tem a certeza de que quer eliminar o pacote \"$amount Moedas\"?';
  }

  @override
  String get adminDeletePackageTitle => 'Eliminar Pacote?';

  @override
  String get adminDescription => 'Descrição';

  @override
  String get adminDeselectAll => 'Desselecionar todos';

  @override
  String get adminDisabled => 'Desativado';

  @override
  String get adminDismiss => 'Ignorar';

  @override
  String get adminDismissReport => 'Ignorar Denúncia';

  @override
  String get adminDismissReportConfirm =>
      'Tem a certeza de que quer ignorar esta denúncia?';

  @override
  String get adminEarlyAccessDate => '14 de março de 2026';

  @override
  String get adminEarlyAccessDates =>
      'Os utilizadores nesta lista obtêm acesso a 14 de março de 2026.';

  @override
  String get adminEarlyAccessInList => 'Acesso Antecipado (na lista)';

  @override
  String get adminEarlyAccessInfo => 'Informação de Acesso Antecipado';

  @override
  String get adminEarlyAccessList => 'Lista de Acesso Antecipado';

  @override
  String get adminEarlyAccessProgram => 'Programa de Acesso Antecipado';

  @override
  String get adminEditAchievement => 'Editar Conquista';

  @override
  String adminEditItem(Object name) {
    return 'Editar $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Editar $name';
  }

  @override
  String get adminEditPackage => 'Editar Pacote';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email adicionado à lista de acesso antecipado';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count emails';
  }

  @override
  String get adminEmailList => 'Lista de Emails';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email removido da lista de acesso antecipado';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Ativar opções de filtragem avançada';

  @override
  String get adminEngagementReports => 'Relatórios de Interação';

  @override
  String get adminEngagementReportsSubtitle =>
      'Ver estatísticas de compatibilidade e mensagens';

  @override
  String get adminEnterEmailAddress => 'Introduzir endereço de email';

  @override
  String get adminEnterValidAmount => 'Por favor, introduza um montante válido';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Por favor, introduza montante de moedas e preço válidos';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Erro ao adicionar email: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Erro ao carregar contexto: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Erro ao carregar dados: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Erro ao abrir conversa: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Erro ao remover email: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Erro: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Erro ao carregar ficheiro: $error';
  }

  @override
  String get adminErrors => 'Erros:';

  @override
  String get adminEventCreationComingSoon =>
      'Interface de criação de eventos em breve.';

  @override
  String get adminEvents => 'Eventos';

  @override
  String adminFailedToSave(Object error) {
    return 'Falha ao guardar: $error';
  }

  @override
  String get adminFeatures => 'Funcionalidades';

  @override
  String get adminFilterByInterests => 'Filtrar por interesses';

  @override
  String get adminFilterBySpecificLocation =>
      'Filtrar por localização específica';

  @override
  String get adminFilterBySpokenLanguages => 'Filtrar por idiomas falados';

  @override
  String get adminFilterByVerificationStatus =>
      'Filtrar por estado de verificação';

  @override
  String get adminFilterOptions => 'Opções de Filtro';

  @override
  String get adminGamification => 'Gamificação';

  @override
  String get adminGamificationAndRewards => 'Gamificação e Recompensas';

  @override
  String get adminGeneralAccess => 'Acesso Geral';

  @override
  String get adminGeneralAccessDate => '14 de abril de 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Prioridade mais alta = mostrado primeiro na descoberta';

  @override
  String get adminImportResult => 'Resultado da Importação';

  @override
  String get adminInProgress => 'Em Curso';

  @override
  String get adminIncognitoMode => 'Modo Incógnito';

  @override
  String get adminInterestFilter => 'Filtro de Interesses';

  @override
  String get adminInvoices => 'Faturas';

  @override
  String get adminLanguageFilter => 'Filtro de Idioma';

  @override
  String get adminLoading => 'A carregar...';

  @override
  String get adminLocationFilter => 'Filtro de Localização';

  @override
  String get adminLockAccount => 'Bloquear Conta';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Bloquear conta do utilizador $userId...?';
  }

  @override
  String get adminLockDuration => 'Duração do Bloqueio';

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
  String get adminLoginStreakSystem => 'Sistema de Sequência de Login';

  @override
  String get adminLoginStreaks => 'Sequências de Login';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configurar marcos de sequência e recompensas';

  @override
  String get adminManageAppSettings =>
      'Gerir as definições da aplicação GreenGo';

  @override
  String get adminMatchPriority => 'Prioridade de Compatibilidade';

  @override
  String get adminMatchingAndVisibility => 'Compatibilidade e Visibilidade';

  @override
  String get adminMessageContext => 'Contexto da Mensagem (50 antes/depois)';

  @override
  String get adminMilestoneUpdated => 'Marco atualizado';

  @override
  String adminMoreErrors(Object count) {
    return '... e mais $count erros';
  }

  @override
  String get adminName => 'Nome';

  @override
  String get adminNinetyDays => '90 dias';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'Nenhum email na lista de acesso antecipado';

  @override
  String get adminNoInvoicesFound => 'Nenhuma fatura encontrada';

  @override
  String get adminNoLockedAccounts => 'Nenhuma conta bloqueada';

  @override
  String get adminNoMatchingEmailsFound =>
      'Nenhum email correspondente encontrado';

  @override
  String get adminNoOrdersFound => 'Nenhuma encomenda encontrada';

  @override
  String get adminNoPendingReports => 'Nenhuma denúncia pendente';

  @override
  String get adminNoReportsYet => 'Sem denúncias ainda';

  @override
  String adminNoTickets(Object status) {
    return 'Sem tickets $status';
  }

  @override
  String get adminNoValidEmailsFound =>
      'Nenhum endereço de email válido encontrado no ficheiro';

  @override
  String get adminNoVerificationHistory => 'Sem histórico de verificação';

  @override
  String get adminOneDay => '1 dia';

  @override
  String get adminOpen => 'Aberto';

  @override
  String adminOpenCount(Object count) {
    return 'Abertos ($count)';
  }

  @override
  String get adminOpenTickets => 'Tickets Abertos';

  @override
  String get adminOrderDetails => 'Detalhes da Encomenda';

  @override
  String get adminOrderId => 'ID da Encomenda';

  @override
  String get adminOrderRefunded => 'Encomenda reembolsada';

  @override
  String get adminOrders => 'Encomendas';

  @override
  String get adminPackages => 'Pacotes';

  @override
  String get adminPanel => 'Painel Admin';

  @override
  String get adminPayment => 'Pagamento';

  @override
  String get adminPending => 'Pendente';

  @override
  String adminPendingCount(Object count) {
    return 'Pendentes ($count)';
  }

  @override
  String get adminPermanent => 'Permanente';

  @override
  String get adminPleaseEnterValidEmail =>
      'Por favor, introduza um endereço de email válido';

  @override
  String get adminPriceUsd => 'Preço (USD)';

  @override
  String get adminProductIdIap => 'ID do Produto (para IAP)';

  @override
  String get adminProfileVisitors => 'Visitantes do Perfil';

  @override
  String get adminPromotional => 'Promocional';

  @override
  String get adminPromotionalPackage => 'Pacote Promocional';

  @override
  String get adminPromotions => 'Promoções';

  @override
  String get adminPromotionsSubtitle => 'Gerir ofertas especiais e promoções';

  @override
  String get adminProvideReason => 'Por favor, forneça um motivo';

  @override
  String get adminReadReceipts => 'Confirmação de Leitura';

  @override
  String get adminReason => 'Motivo';

  @override
  String adminReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String get adminReasonRequired => 'Motivo (obrigatório)';

  @override
  String get adminRefund => 'Reembolso';

  @override
  String get adminRemove => 'Remover';

  @override
  String get adminRemoveCoins => 'Remover Moedas';

  @override
  String get adminRemoveEmail => 'Remover Email';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Tem a certeza de que quer remover \"$email\" da lista de acesso antecipado?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return 'Removidas $amount moedas do utilizador';
  }

  @override
  String get adminReportDismissed => 'Denúncia ignorada';

  @override
  String get adminReportFollowupStarted =>
      'Conversa de acompanhamento da denúncia iniciada';

  @override
  String get adminReportedMessage => 'Mensagem Denunciada:';

  @override
  String get adminReportedMessageMarker => '^ MENSAGEM DENUNCIADA';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'ID do Utilizador Denunciado: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'ID do Denunciante: $reporterId...';
  }

  @override
  String get adminReports => 'Denúncias';

  @override
  String get adminReportsManagement => 'Gestão de Denúncias';

  @override
  String get adminRequestNewPhoto => 'Solicitar Nova Foto';

  @override
  String get adminRequiredCount => 'Contagem Necessária';

  @override
  String adminRequiresCount(Object count) {
    return 'Requer: $count';
  }

  @override
  String get adminReset => 'Repor';

  @override
  String get adminResetToDefaults => 'Repor Valores Predefinidos';

  @override
  String get adminResetToDefaultsConfirm =>
      'Isto irá repor todas as configurações de nível para os valores predefinidos. Esta ação não pode ser revertida.';

  @override
  String get adminResetToDefaultsTitle => 'Repor Valores Predefinidos?';

  @override
  String get adminResolutionNote => 'Nota de Resolução';

  @override
  String get adminResolve => 'Resolver';

  @override
  String get adminResolved => 'Resolvido';

  @override
  String adminResolvedCount(Object count) {
    return 'Resolvidos ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Análise de Receitas';

  @override
  String get adminRevenueAnalyticsSubtitle => 'Acompanhar compras e receitas';

  @override
  String get adminReviewedBy => 'Revisto Por';

  @override
  String get adminRewardAmount => 'Montante da Recompensa';

  @override
  String get adminSaving => 'A guardar...';

  @override
  String get adminScheduledEvents => 'Eventos Agendados';

  @override
  String get adminSearchByUserIdOrEmail =>
      'Pesquisar por ID de utilizador ou email';

  @override
  String get adminSearchEmails => 'Pesquisar emails...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Pesquisar utilizador para gerir o saldo de moedas';

  @override
  String get adminSearchOrders => 'Pesquisar encomendas...';

  @override
  String get adminSeeWhenMessagesAreRead => 'Ver quando as mensagens são lidas';

  @override
  String get adminSeeWhoVisitedProfile => 'Ver quem visitou o perfil';

  @override
  String get adminSelectAll => 'Selecionar todos';

  @override
  String get adminSelectCsvFile => 'Selecionar Ficheiro CSV';

  @override
  String adminSelectedCount(Object count) {
    return '$count selecionados';
  }

  @override
  String get adminSendImagesAndVideosInChat =>
      'Enviar imagens e vídeos na conversa';

  @override
  String get adminSevenDays => '7 dias';

  @override
  String get adminSpendItems => 'Itens de Gasto';

  @override
  String get adminStatistics => 'Estatísticas';

  @override
  String get adminStatus => 'Estado';

  @override
  String get adminStreakMilestones => 'Marcos de Sequência';

  @override
  String get adminStreakMultiplier => 'Multiplicador de Sequência';

  @override
  String get adminStreakMultiplierValue => '1,5x por dia';

  @override
  String get adminStreaks => 'Sequências';

  @override
  String get adminSupport => 'Suporte';

  @override
  String get adminSupportAgents => 'Agentes de Suporte';

  @override
  String get adminSupportAgentsSubtitle => 'Gerir contas de agentes de suporte';

  @override
  String get adminSupportManagement => 'Gestão de Suporte';

  @override
  String get adminSupportRequest => 'Pedido de Suporte';

  @override
  String get adminSupportTickets => 'Tickets de Suporte';

  @override
  String get adminSupportTicketsSubtitle =>
      'Ver e gerir conversas de suporte de utilizadores';

  @override
  String get adminSystemConfiguration => 'Configuração do Sistema';

  @override
  String get adminThirtyDays => '30 dias';

  @override
  String get adminTicketAssignedToYou => 'Ticket atribuído a si';

  @override
  String get adminTicketAssignment => 'Atribuição de Tickets';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Atribuir tickets a agentes de suporte';

  @override
  String get adminTicketClosed => 'Ticket fechado';

  @override
  String get adminTicketResolved => 'Ticket resolvido';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Configurações de nível guardadas com sucesso';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Gestão de Níveis';

  @override
  String get adminTierManagementSubtitle =>
      'Configurar limites e funcionalidades de nível';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Hoje';

  @override
  String get adminTotalMinutes => 'Total de Minutos';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminUnassigned => 'Não Atribuído';

  @override
  String get adminUnknown => 'Desconhecido';

  @override
  String get adminUnlimited => 'Ilimitado';

  @override
  String get adminUnlock => 'Desbloquear';

  @override
  String get adminUnlockAccount => 'Desbloquear Conta';

  @override
  String get adminUnlockAccountConfirm =>
      'Tem a certeza de que quer desbloquear esta conta?';

  @override
  String get adminUnresolved => 'Não Resolvido';

  @override
  String get adminUploadCsvDescription =>
      'Carregar ficheiro CSV com endereços de email (um por linha ou separados por vírgula)';

  @override
  String get adminUploadCsvFile => 'Carregar Ficheiro CSV';

  @override
  String get adminUploading => 'A carregar...';

  @override
  String get adminUseVideoCallingFeature =>
      'Usar funcionalidade de videochamada';

  @override
  String get adminUsedMinutes => 'Minutos Usados';

  @override
  String get adminUser => 'Utilizador';

  @override
  String get adminUserAnalytics => 'Análise de Utilizadores';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Ver métricas de interação e crescimento de utilizadores';

  @override
  String get adminUserBalance => 'Saldo do Utilizador';

  @override
  String get adminUserId => 'ID do Utilizador';

  @override
  String adminUserIdLabel(Object userId) {
    return 'ID do Utilizador: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Utilizador: $userId...';
  }

  @override
  String get adminUserManagement => 'Gestão de Utilizadores';

  @override
  String get adminUserModeration => 'Moderação de Utilizadores';

  @override
  String get adminUserModerationSubtitle =>
      'Gerir suspensões e banimentos de utilizadores';

  @override
  String get adminUserReports => 'Denúncias de Utilizadores';

  @override
  String get adminUserReportsSubtitle =>
      'Rever e tratar denúncias de utilizadores';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Utilizador: $senderId...';
  }

  @override
  String get adminUserVerifications => 'Verificações de Utilizadores';

  @override
  String get adminUserVerificationsSubtitle =>
      'Aprovar ou rejeitar pedidos de verificação de utilizadores';

  @override
  String get adminVerificationFilter => 'Filtro de Verificação';

  @override
  String get adminVerifications => 'Verificações';

  @override
  String get adminVideoChat => 'Videochamada';

  @override
  String get adminVideoCoinPackages => 'Pacotes de Moedas de Vídeo';

  @override
  String get adminVideoCoins => 'Moedas de Vídeo';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes Minutos';
  }

  @override
  String get adminViewContext => 'Ver Contexto';

  @override
  String get adminViewDocument => 'Ver Documento';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violação das diretrizes da comunidade';

  @override
  String get adminWaiting => 'Em Espera';

  @override
  String adminWaitingCount(Object count) {
    return 'Em Espera ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Desafios Semanais';

  @override
  String get adminWelcome => 'Bem-vindo, Admin';

  @override
  String get adminXpReward => 'Recompensa de XP';

  @override
  String get ageRange => 'Faixa Etária';

  @override
  String get aiCoachBenefitAllChapters =>
      'Todos os capítulos de aprendizagem desbloqueados';

  @override
  String get aiCoachBenefitFeedback =>
      'Feedback de gramática e pronúncia em tempo real';

  @override
  String get aiCoachBenefitPersonalized =>
      'Percurso de aprendizagem personalizado';

  @override
  String get aiCoachBenefitUnlimited =>
      'Prática ilimitada de conversação com IA';

  @override
  String get aiCoachLabel => 'Coach IA';

  @override
  String get aiCoachTrialEnded =>
      'O teu período de teste do Treinador IA terminou.';

  @override
  String get aiCoachUpgradePrompt =>
      'Atualiza para Prata, Ouro ou Platina para desbloquear.';

  @override
  String get aiCoachUpgradeTitle => 'Atualiza para Aprender Mais';

  @override
  String get albumNotShared => 'Álbum não partilhado';

  @override
  String get albumOption => 'Álbum';

  @override
  String albumRevokedMessage(String username) {
    return '$username revogou o acesso ao álbum';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username partilhou o álbum contigo';
  }

  @override
  String get allCategoriesFilter => 'Todas';

  @override
  String get allDealBreakersAdded =>
      'Todos os critérios eliminatórios foram adicionados';

  @override
  String get allLanguagesFilter => 'Todas';

  @override
  String get allPlayersReady => 'Todos os jogadores estão prontos!';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get appLanguage => 'Idioma da App';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubra o Seu Par Perfeito';

  @override
  String get approveVerification => 'Aprovar';

  @override
  String get atLeast8Characters => 'Pelo menos 8 caracteres';

  @override
  String get atLeastOneNumber => 'Pelo menos um número';

  @override
  String get atLeastOneSpecialChar => 'Pelo menos um carácter especial';

  @override
  String get authAppleSignInComingSoon => 'Início de sessão com Apple em breve';

  @override
  String get authCancelVerification => 'Cancelar Verificação?';

  @override
  String get authCancelVerificationBody =>
      'A sua sessão será encerrada se cancelar a verificação.';

  @override
  String get authDisableInSettings =>
      'Pode desativar isto em Definições > Segurança';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Já existe uma conta com este e-mail.';

  @override
  String get authErrorGeneric => 'Ocorreu um erro. Tenta novamente.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail/nickname ou palavra-passe incorretos. Verifica as tuas credenciais e tenta novamente.';

  @override
  String get authErrorInvalidEmail =>
      'Por favor introduz um endereço de e-mail válido.';

  @override
  String get authErrorNetworkError =>
      'Sem ligação à internet. Verifica a tua ligação e tenta novamente.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiadas tentativas. Tenta novamente mais tarde.';

  @override
  String get authErrorUserNotFound =>
      'Nenhuma conta encontrada com este e-mail ou nickname. Verifica e tenta novamente, ou regista-te.';

  @override
  String get authErrorWeakPassword =>
      'A palavra-passe é muito fraca. Usa uma palavra-passe mais forte.';

  @override
  String get authErrorWrongPassword => 'Palavra-passe errada. Tenta novamente.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Falha ao tirar foto: $error';
  }

  @override
  String get authIdentityVerification => 'Verificação de Identidade';

  @override
  String get authPleaseEnterEmail => 'Por favor, introduza o seu email';

  @override
  String get authRetakePhoto => 'Tirar Foto Novamente';

  @override
  String get authSecurityStep =>
      'Este passo de segurança extra ajuda a proteger a sua conta';

  @override
  String get authSelfieInstruction =>
      'Olhe para a câmara e toque para capturar';

  @override
  String get authSignOut => 'Terminar Sessão';

  @override
  String get authSignOutInstead => 'Terminar sessão em vez disso';

  @override
  String get authStay => 'Ficar';

  @override
  String get authTakeSelfie => 'Tirar uma Selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Por favor, tire uma selfie para verificar a sua identidade';

  @override
  String get authVerifyAndContinue => 'Verificar e Continuar';

  @override
  String get authVerifyWithSelfie =>
      'Por favor, verifique a sua identidade com uma selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Bem-vindo de volta, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Falha no Início de Sessão';

  @override
  String get away => 'de distância';

  @override
  String get awesome => 'Fantástico!';

  @override
  String get backToLobby => 'Voltar ao Lobby';

  @override
  String get badgeLocked => 'Bloqueado';

  @override
  String get badgeUnlocked => 'Desbloqueado';

  @override
  String get achievementUnlockedTitle => 'CONQUISTA DESBLOQUEADA!';

  @override
  String get achievementUnlockedAwesome => 'Incrível!';

  @override
  String get achievementRarityCommon => 'COMUM';

  @override
  String get achievementRarityUncommon => 'INCOMUM';

  @override
  String get achievementRarityRare => 'RARO';

  @override
  String get achievementRarityEpic => 'ÉPICO';

  @override
  String get achievementRarityLegendary => 'LENDÁRIO';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

  @override
  String get badges => 'Emblemas';

  @override
  String get basic => 'Básico';

  @override
  String get basicInformation => 'Informações Básicas';

  @override
  String get betterPhotoRequested => 'Foto melhor solicitada';

  @override
  String get bio => 'Biografia';

  @override
  String get bioUpdatedMessage => 'A bio do teu perfil foi guardada';

  @override
  String get bioUpdatedTitle => 'Bio Atualizada!';

  @override
  String get blindDateActivate => 'Ativar Modo Encontro às Cegas';

  @override
  String get blindDateDeactivate => 'Desativar';

  @override
  String get blindDateDeactivateMessage =>
      'Vais voltar ao modo de descoberta normal.';

  @override
  String get blindDateDeactivateTitle => 'Desativar Modo Encontro às Cegas?';

  @override
  String get blindDateDeactivateTooltip => 'Desativar Modo Encontro às Cegas';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Revelação instantânea por $cost moedas';
  }

  @override
  String get blindDateFeatureNoPhotos =>
      'Fotos do perfil não visíveis inicialmente';

  @override
  String get blindDateFeaturePersonality =>
      'Foco na personalidade e interesses';

  @override
  String get blindDateFeatureUnlock => 'Fotos desbloqueadas após conversarem';

  @override
  String get blindDateGetCoins => 'Obter Moedas';

  @override
  String get blindDateInstantReveal => 'Revelação Instantânea';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Revelar todas as fotos desta correspondência por $cost moedas?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Revelação instantânea ($cost moedas)';
  }

  @override
  String get blindDateInsufficientCoins => 'Moedas Insuficientes';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Precisas de $cost moedas para revelar fotos instantaneamente.';
  }

  @override
  String get blindDateInterests => 'Interesses';

  @override
  String blindDateKmAway(String distance) {
    return 'a $distance km';
  }

  @override
  String get blindDateLetsExchange => 'Comece a conectar!';

  @override
  String get blindDateMatchMessage =>
      'Vocês gostaram um do outro! Comecem a conversar para revelar as fotos.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total mensagens';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'faltam $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count mensagens até à revelação';
  }

  @override
  String get blindDateModeActivated => 'Modo Encontro às Cegas ativado!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Encontra alguém pela personalidade, não pela aparência.\nAs fotos são reveladas após $threshold mensagens.';
  }

  @override
  String get blindDateModeTitle => 'Modo Encontro às Cegas';

  @override
  String get blindDateMysteryPerson => 'Pessoa Mistério';

  @override
  String get blindDateNoCandidates => 'Sem candidatos disponíveis';

  @override
  String get blindDateNoMatches => 'Sem correspondências ainda';

  @override
  String blindDatePendingReveal(int count) {
    return 'Revelação Pendente ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Progresso da Revelação de Fotos';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'As fotos revelam-se após $threshold mensagens';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Fotos reveladas! $coinsSpent moedas gastas.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Fotos reveladas!';

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
      'Começa a deslizar para encontrar o teu encontro às cegas!';

  @override
  String get blindDateTabDiscover => 'Descobrir';

  @override
  String get blindDateTabMatches => 'Correspondências';

  @override
  String get blindDateTitle => 'Encontro às Cegas';

  @override
  String get blindDateViewMatch => 'Ver Correspondência';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonusCoins de bónus!)';
  }

  @override
  String get boost => 'Impulso';

  @override
  String get boostActivated => 'Impulso ativado por 30 minutos!';

  @override
  String get boostNow => 'Impulsionar Agora';

  @override
  String get boostProfile => 'Impulsionar Perfil';

  @override
  String get boosted => 'IMPULSIONADO!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Pacote';

  @override
  String get businessCategory => 'Negócios';

  @override
  String get buyCoins => 'Comprar Moedas';

  @override
  String get buyCoinsBtnLabel => 'Comprar Moedas';

  @override
  String get buyPackBtn => 'Comprar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get cannotAccessFeature =>
      'Esta funcionalidade está disponível após a verificação da sua conta.';

  @override
  String get cantUndoMatched => 'Não é possível desfazer — já fizeste match!';

  @override
  String get casualCategory => 'Casual';

  @override
  String get casualDating => 'Encontros casuais';

  @override
  String get categoryFlashcard => 'Cartão';

  @override
  String get categoryLearning => 'Aprendizagem';

  @override
  String get categoryMultilingual => 'Multilingue';

  @override
  String get categoryName => 'Categoria';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Sazonal';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryStreak => 'Série';

  @override
  String get categoryTranslation => 'Tradução';

  @override
  String get challenges => 'Desafios';

  @override
  String get changeLocation => 'Alterar localização';

  @override
  String get changePassword => 'Alterar Palavra-passe';

  @override
  String get changePasswordConfirm => 'Confirmar Nova Palavra-passe';

  @override
  String get changePasswordCurrent => 'Palavra-passe Atual';

  @override
  String get changePasswordDescription =>
      'Por segurança, verifica a tua identidade antes de alterar a palavra-passe.';

  @override
  String get changePasswordEmailConfirm => 'Confirma o teu endereço de email';

  @override
  String get changePasswordEmailHint => 'O teu email';

  @override
  String get changePasswordEmailMismatch =>
      'O email não corresponde à tua conta';

  @override
  String get changePasswordNew => 'Nova Palavra-passe';

  @override
  String get changePasswordReauthRequired =>
      'Por favor, termina a sessão e inicia sessão novamente antes de alterar a palavra-passe';

  @override
  String get changePasswordSubtitle => 'Atualiza a palavra-passe da tua conta';

  @override
  String get changePasswordSuccess => 'Palavra-passe alterada com sucesso';

  @override
  String get changePasswordWrongCurrent =>
      'A palavra-passe atual está incorreta';

  @override
  String get chatAddCaption => 'Adicionar legenda...';

  @override
  String get chatAddToStarred => 'Adicionar às mensagens favoritas';

  @override
  String get chatAlreadyInYourLanguage => 'A mensagem já está no teu idioma';

  @override
  String get chatAttachCamera => 'Câmara';

  @override
  String get chatAttachGallery => 'Galeria';

  @override
  String get chatAttachRecord => 'Gravar';

  @override
  String get chatAttachVideo => 'Vídeo';

  @override
  String get chatBlock => 'Bloquear';

  @override
  String chatBlockUser(String name) {
    return 'Bloquear $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Tens a certeza de que queres bloquear $name? Não poderão contactar-te novamente.';
  }

  @override
  String get chatBlockUserTitle => 'Bloquear Utilizador';

  @override
  String get chatCannotBlockAdmin => 'Não podes bloquear um administrador.';

  @override
  String get chatCannotReportAdmin => 'Não podes denunciar um administrador.';

  @override
  String get chatCategory => 'Categoria';

  @override
  String get chatCategoryAccount => 'Ajuda da Conta';

  @override
  String get chatCategoryBilling => 'Faturação e Pagamentos';

  @override
  String get chatCategoryFeedback => 'Feedback';

  @override
  String get chatCategoryGeneral => 'Questão Geral';

  @override
  String get chatCategorySafety => 'Preocupação de Segurança';

  @override
  String get chatCategoryTechnical => 'Problema Técnico';

  @override
  String get chatCopy => 'Copiar';

  @override
  String get chatCreate => 'Criar';

  @override
  String get chatCreateSupportTicket => 'Criar Ticket de Suporte';

  @override
  String get chatCreateTicket => 'Criar Ticket';

  @override
  String chatDaysAgo(int count) {
    return 'há ${count}d';
  }

  @override
  String get chatDelete => 'Eliminar';

  @override
  String get chatDeleteChat => 'Eliminar Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Isto eliminará todas as mensagens para ti e $name. Esta ação não pode ser desfeita.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Eliminar Chat para Todos';

  @override
  String get chatDeleteChatForMeMessage =>
      'Isto eliminará o chat apenas do teu dispositivo. A outra pessoa continuará a ver as mensagens.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Eliminar conversa com $name?';
  }

  @override
  String get chatDeleteForBoth => 'Eliminar chat para ambos';

  @override
  String get chatDeleteForBothDescription =>
      'Isto eliminará permanentemente a conversa para ti e para a outra pessoa.';

  @override
  String get chatDeleteForEveryone => 'Eliminar para Todos';

  @override
  String get chatDeleteForMe => 'Eliminar chat para mim';

  @override
  String get chatDeleteForMeDescription =>
      'Isto eliminará a conversa apenas da tua lista de chats. A outra pessoa continuará a vê-la.';

  @override
  String get chatDeletedForBothMessage =>
      'Este chat foi permanentemente removido';

  @override
  String get chatDeletedForMeMessage =>
      'Este chat foi removido da tua caixa de entrada';

  @override
  String get chatDeletedTitle => 'Chat Eliminado!';

  @override
  String get chatDescriptionOptional => 'Descrição (Opcional)';

  @override
  String get chatDetailsHint => 'Fornece mais detalhes sobre o teu problema...';

  @override
  String get chatDisableTranslation => 'Desativar tradução';

  @override
  String get chatEnableTranslation => 'Ativar tradução';

  @override
  String get chatErrorLoadingTickets => 'Erro ao carregar os tickets';

  @override
  String get chatFailedToCreateTicket => 'Falha ao criar ticket';

  @override
  String get chatFailedToForwardMessage => 'Falha ao reencaminhar mensagem';

  @override
  String get chatFailedToLoadAlbum => 'Falha ao carregar álbum';

  @override
  String get chatFailedToLoadConversations => 'Falha ao carregar conversas';

  @override
  String get chatFailedToLoadImage => 'Falha ao carregar imagem';

  @override
  String get chatFailedToLoadVideo => 'Falha ao carregar o vídeo';

  @override
  String chatFailedToPickImage(String error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Falha ao selecionar vídeo: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Falha ao denunciar mensagem: $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Falha ao revogar acesso';

  @override
  String get chatFailedToSaveFlashcard => 'Falha ao guardar o cartão';

  @override
  String get chatFailedToShareAlbum => 'Falha ao partilhar álbum';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Falha ao carregar imagem: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Falha ao carregar vídeo: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Dicas culturais e contexto';

  @override
  String get chatFeatureGrammar => 'Feedback gramatical em tempo real';

  @override
  String get chatFeatureVocabulary => 'Exercícios de vocabulário';

  @override
  String get chatForward => 'Reencaminhar';

  @override
  String get chatForwardMessage => 'Reencaminhar Mensagem';

  @override
  String get chatForwardToChat => 'Reencaminhar para outro chat';

  @override
  String get chatGrammarSuggestion => 'Sugestão gramatical';

  @override
  String chatHoursAgo(int count) {
    return 'há ${count}h';
  }

  @override
  String get chatIcebreakers => 'Quebra-gelos';

  @override
  String chatIsTyping(String userName) {
    return '$userName está a escrever';
  }

  @override
  String get chatJustNow => 'Agora mesmo';

  @override
  String get chatLanguagePickerHint =>
      'Escolha o idioma em que deseja ler esta conversa. Todas as mensagens serão traduzidas para si.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Idioma do chat definido para $language';
  }

  @override
  String get chatLanguages => 'Idiomas';

  @override
  String get chatLearnThis => 'Aprender Isto';

  @override
  String get chatListen => 'Ouvir';

  @override
  String get chatLoadingVideo => 'A carregar vídeo...';

  @override
  String get chatMaybeLater => 'Talvez mais tarde';

  @override
  String get chatMediaLimitReached => 'Limite de media atingido';

  @override
  String get chatMessage => 'Mensagem';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Mensagem bloqueada: Contém $violations. Para a tua segurança, partilhar dados de contacto pessoais não é permitido.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Mensagem reencaminhada para $count conversa(s)';
  }

  @override
  String get chatMessageOptions => 'Opções da Mensagem';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Mensagem denunciada. Iremos analisá-la em breve.';

  @override
  String get chatMessageStarred => 'Mensagem marcada como favorita';

  @override
  String get chatMessageTranslated => 'Traduzido';

  @override
  String get chatMessageUnstarred => 'Mensagem removida dos favoritos';

  @override
  String chatMinutesAgo(int count) {
    return 'há ${count}min';
  }

  @override
  String get chatMySupportTickets => 'Os Meus Tickets de Suporte';

  @override
  String get chatNeedHelpCreateTicket =>
      'Precisa de ajuda? Crie um novo ticket.';

  @override
  String get chatNewTicket => 'Novo Ticket';

  @override
  String get chatNoConversationsToForward => 'Sem conversas para reencaminhar';

  @override
  String get chatNoMatchingConversations => 'Sem conversas correspondentes';

  @override
  String get chatNoMessagesToPractice => 'Ainda não há mensagens para praticar';

  @override
  String get chatNoMessagesYet => 'Ainda sem mensagens';

  @override
  String get chatNoPrivatePhotos => 'Sem fotos privadas disponíveis';

  @override
  String get chatNoSupportTickets => 'Sem Tickets de Suporte';

  @override
  String get chatOffline => 'Offline';

  @override
  String get chatOnline => 'Online';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'Online há ${days}d';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'Online há ${hours}h';
  }

  @override
  String get chatOnlineJustNow => 'Online agora';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'Online há ${minutes}min';
  }

  @override
  String get chatOptions => 'Opções do Chat';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name revogou o acesso ao álbum';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name partilhou o seu álbum privado';
  }

  @override
  String get chatPhoto => 'Foto';

  @override
  String get chatPhraseSaved => 'Frase guardada no teu baralho de cartões!';

  @override
  String get chatPleaseEnterSubject => 'Por favor, introduz um assunto';

  @override
  String get chatPractice => 'Praticar';

  @override
  String get chatPracticeMode => 'Modo Prática';

  @override
  String get chatPracticeTrialStarted =>
      'Teste do modo prática iniciado! Tens 3 sessões grátis.';

  @override
  String get chatPreviewImage => 'Pré-visualização de Imagem';

  @override
  String get chatPreviewVideo => 'Pré-visualização de Vídeo';

  @override
  String get chatPronunciationChallenge => 'Desafio de pronúncia';

  @override
  String get chatPronunciationHint => 'Toque para ouvir e pratique cada frase:';

  @override
  String get chatRemoveFromStarred => 'Remover das mensagens favoritas';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatReplyToMessage => 'Responder a esta mensagem';

  @override
  String chatReplyingTo(String name) {
    return 'A responder a $name';
  }

  @override
  String get chatReportInappropriate => 'Denunciar conteúdo inapropriado';

  @override
  String get chatReportMessage => 'Denunciar Mensagem';

  @override
  String get chatReportReasonFakeProfile => 'Perfil falso / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Assédio ou bullying';

  @override
  String get chatReportReasonInappropriate => 'Conteúdo inapropriado';

  @override
  String get chatReportReasonOther => 'Outro';

  @override
  String get chatReportReasonPersonalInfo => 'Partilha de informações pessoais';

  @override
  String get chatReportReasonSpam => 'Spam ou burla';

  @override
  String get chatReportReasonThreatening => 'Comportamento ameaçador';

  @override
  String get chatReportReasonUnderage => 'Utilizador menor de idade';

  @override
  String chatReportUser(String name) {
    return 'Denunciar $name';
  }

  @override
  String get chatReportUserTitle => 'Denunciar Utilizador';

  @override
  String chatSeeExchangeDetails(String name) {
    return 'Ver Detalhes da Troca com $name';
  }

  @override
  String get chatSafetyGotIt => 'Entendido';

  @override
  String get chatSafetySubtitle =>
      'A tua segurança é a nossa prioridade. Tem em mente estas dicas.';

  @override
  String get chatSafetyTip => 'Dica de Segurança';

  @override
  String get chatSafetyTip1Description =>
      'Não partilhes morada, número de telefone ou informações financeiras.';

  @override
  String get chatSafetyTip1Title => 'Mantém a Info Pessoal Privada';

  @override
  String get chatSafetyTip2Description =>
      'Nunca envies dinheiro a alguém que não conheceste pessoalmente.';

  @override
  String get chatSafetyTip2Title => 'Cuidado com Pedidos de Dinheiro';

  @override
  String get chatSafetyTip3Description =>
      'Para primeiros encontros, escolhe sempre um local público e bem iluminado.';

  @override
  String get chatSafetyTip3Title => 'Encontra-te em Locais Públicos';

  @override
  String get chatSafetyTip4Description =>
      'Se algo não te parecer bem, confia no teu instinto e termina a conversa.';

  @override
  String get chatSafetyTip4Title => 'Confia no Teu Instinto';

  @override
  String get chatSafetyTip5Description =>
      'Usa a função de denúncia se alguém te deixar desconfortável.';

  @override
  String get chatSafetyTip5Title => 'Denuncia Comportamentos Suspeitos';

  @override
  String get chatSafetyTitle => 'Conversa em Segurança';

  @override
  String get chatSaving => 'A guardar...';

  @override
  String chatSayHiTo(String name) {
    return 'Diz olá a $name!';
  }

  @override
  String get chatScrollUpForOlder =>
      'Deslize para cima para mensagens mais antigas';

  @override
  String get chatSearchByNameOrNickname => 'Pesquisar por nome ou @alcunha';

  @override
  String get chatSearchConversationsHint => 'Pesquisar conversas...';

  @override
  String get chatSelectPhotos => 'Selecionar fotos para enviar';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSendAnyway => 'Enviar mesmo assim';

  @override
  String get chatSendAttachment => 'Enviar Anexo';

  @override
  String chatSendCount(int count) {
    return 'Enviar ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Envia uma mensagem para iniciar a conversa';

  @override
  String get chatSendMessagesForTips =>
      'Envia mensagens para receber dicas de idiomas!';

  @override
  String get chatSetNativeLanguage =>
      'Define primeiro a tua língua nativa nas definições';

  @override
  String get chatSettingCulturalTips => 'Dicas culturais';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Mostrar contexto cultural de expressões idiomáticas';

  @override
  String get chatSettingDifficultyBadges => 'Distintivos de dificuldade';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Mostrar nível QECR (A1-C2) nas mensagens';

  @override
  String get chatSettingGrammarCheck => 'Verificação gramatical';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Verificar gramática antes de enviar';

  @override
  String get chatSettingLanguageFlags => 'Bandeiras de idioma';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Mostrar emoji de bandeira junto ao texto traduzido e original';

  @override
  String get chatSettingPhraseOfDay => 'Frase do dia';

  @override
  String get chatSettingPhraseOfDayDesc =>
      'Mostrar uma frase diária para praticar';

  @override
  String get chatSettingPronunciation => 'Pronúncia (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Duplo toque para ouvir a pronúncia';

  @override
  String get chatSettingShowOriginal => 'Mostrar texto original';

  @override
  String get chatSettingShowOriginalDesc =>
      'Mostrar a mensagem original abaixo da tradução';

  @override
  String get chatSettingSmartReplies => 'Respostas inteligentes';

  @override
  String get chatSettingSmartRepliesDesc => 'Sugerir respostas no idioma alvo';

  @override
  String get chatSettingTtsTranslation => 'TTS lê tradução';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Ler o texto traduzido em vez do original';

  @override
  String get chatSettingWordBreakdown => 'Decomposição de palavras';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Toque nas mensagens para tradução palavra por palavra';

  @override
  String get chatSettingXpBar => 'Barra de XP e série';

  @override
  String get chatSettingXpBarDesc =>
      'Mostrar XP da sessão e progresso de palavras';

  @override
  String get chatSettingsSaveAllChats => 'Guardar para todos os chats';

  @override
  String get chatSettingsSaveThisChat => 'Guardar para este chat';

  @override
  String get chatSettingsSavedAllChats =>
      'Definições guardadas para todos os chats';

  @override
  String get chatSettingsSavedThisChat => 'Definições guardadas para este chat';

  @override
  String get chatSettingsSubtitle =>
      'Personalize a sua experiência de aprendizagem neste chat';

  @override
  String get chatSettingsTitle => 'Definições do chat';

  @override
  String get chatSomeone => 'Alguém';

  @override
  String get chatStarMessage => 'Marcar como Favorita';

  @override
  String get chatStartSwipingToChat =>
      'Desliza e faz match para conversar com pessoas!';

  @override
  String get chatStatusAssigned => 'Atribuído';

  @override
  String get chatStatusAwaitingReply => 'A aguardar resposta';

  @override
  String get chatStatusClosed => 'Fechado';

  @override
  String get chatStatusInProgress => 'Em Progresso';

  @override
  String get chatStatusOpen => 'Aberto';

  @override
  String get chatStatusResolved => 'Resolvido';

  @override
  String chatStreak(int count) {
    return 'Série: $count';
  }

  @override
  String get chatSubject => 'Assunto';

  @override
  String get chatSubjectHint => 'Breve descrição do teu problema';

  @override
  String get chatSupportAddAttachment => 'Adicionar Anexo';

  @override
  String get chatSupportAddCaptionOptional => 'Adicionar legenda (opcional)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agente: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agente';

  @override
  String get chatSupportCategory => 'Categoria';

  @override
  String get chatSupportClose => 'Fechar';

  @override
  String chatSupportDaysAgo(int days) {
    return 'há ${days}d';
  }

  @override
  String get chatSupportErrorLoading => 'Erro ao carregar mensagens';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Falha ao reabrir ticket: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Falha ao enviar mensagem: $error';
  }

  @override
  String get chatSupportGeneral => 'Geral';

  @override
  String get chatSupportGeneralSupport => 'Suporte Geral';

  @override
  String chatSupportHoursAgo(int hours) {
    return 'há ${hours}h';
  }

  @override
  String get chatSupportJustNow => 'Agora mesmo';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'há ${minutes}min';
  }

  @override
  String get chatSupportReopenTicket =>
      'Precisas de mais ajuda? Toca para reabrir';

  @override
  String get chatSupportStartMessage =>
      'Envia uma mensagem para iniciar a conversa.\nA nossa equipa responderá o mais breve possível.';

  @override
  String get chatSupportStatus => 'Estado';

  @override
  String get chatSupportStatusClosed => 'Fechado';

  @override
  String get chatSupportStatusDefault => 'Suporte';

  @override
  String get chatSupportStatusOpen => 'Aberto';

  @override
  String get chatSupportStatusPending => 'Pendente';

  @override
  String get chatSupportStatusResolved => 'Resolvido';

  @override
  String get chatSupportSubject => 'Assunto';

  @override
  String get chatSupportTicketCreated => 'Ticket Criado';

  @override
  String get chatSupportTicketId => 'ID do Ticket';

  @override
  String get chatSupportTicketInfo => 'Informações do Ticket';

  @override
  String get chatSupportTicketReopened =>
      'Ticket reaberto. Podes enviar uma mensagem agora.';

  @override
  String get chatSupportTicketResolved => 'Este ticket foi resolvido';

  @override
  String get chatSupportTicketStart => 'Início do Ticket';

  @override
  String get chatSupportTitle => 'Suporte GreenGo';

  @override
  String get chatSupportTypeMessage => 'Escreve a tua mensagem...';

  @override
  String get chatSupportWaitingAssignment => 'A aguardar atribuição';

  @override
  String get chatSupportWelcome => 'Bem-vindo ao Suporte';

  @override
  String get chatTapToView => 'Toque para ver';

  @override
  String get chatTapToViewAlbum => 'Toque para ver o álbum';

  @override
  String get chatTranslate => 'Traduzir';

  @override
  String get chatTranslated => 'Traduzido';

  @override
  String get chatTranslating => 'A traduzir...';

  @override
  String get chatTranslationDisabled => 'Tradução desativada';

  @override
  String get chatTranslationEnabled => 'Tradução ativada';

  @override
  String get chatTranslationFailed => 'Tradução falhou. Tenta novamente.';

  @override
  String get chatTrialExpired => 'O teu teste gratuito expirou.';

  @override
  String get chatTtsComingSoon => 'Texto para fala em breve!';

  @override
  String get chatTyping => 'a escrever...';

  @override
  String get chatUnableToForward => 'Não é possível reencaminhar a mensagem';

  @override
  String get chatUnknown => 'Desconhecido';

  @override
  String get chatUnstarMessage => 'Remover dos Favoritos';

  @override
  String get chatUpgrade => 'Atualizar';

  @override
  String get chatUpgradePracticeMode =>
      'Atualiza para Silver VIP ou superior para continuar a praticar idiomas nos teus chats.';

  @override
  String get chatUploading => 'A carregar...';

  @override
  String get chatUseCorrection => 'Usar correção';

  @override
  String chatUserBlocked(String name) {
    return '$name foi bloqueado';
  }

  @override
  String get chatUserReported =>
      'Utilizador denunciado. Iremos analisar a tua denúncia em breve.';

  @override
  String get chatVideo => 'Vídeo';

  @override
  String get chatVideoPlayer => 'Leitor de Vídeo';

  @override
  String get chatVideoTooLarge =>
      'Vídeo demasiado grande. O tamanho máximo é 50MB.';

  @override
  String get chatWhyReportMessage => 'Porque denuncias esta mensagem?';

  @override
  String chatWhyReportUser(String name) {
    return 'Porque denuncias $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Conversar com $name';
  }

  @override
  String chatWords(int count) {
    return '$count palavras';
  }

  @override
  String get chatYou => 'Tu';

  @override
  String get chatYouRevokedAlbum => 'Revogaste o acesso ao álbum';

  @override
  String get chatYouSharedAlbum => 'Partilhaste o teu álbum privado';

  @override
  String get chatYourLanguage => 'O seu idioma';

  @override
  String get checkBackLater =>
      'Volte mais tarde para novas pessoas, ou ajuste as suas preferências';

  @override
  String get chooseCorrectAnswer => 'Escolhe a resposta correta';

  @override
  String get chooseFromGallery => 'Escolher da Galeria';

  @override
  String get chooseGame => 'Escolher um Jogo';

  @override
  String get claimReward => 'Reclamar Recompensa';

  @override
  String get claimRewardBtn => 'Resgatar';

  @override
  String get clearFilters => 'Limpar Filtros';

  @override
  String get close => 'Fechar';

  @override
  String get coins => 'Moedas';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins moedas adicionadas à tua conta$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Todas as Transações';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Moedas';
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
    return '+$amount moedas bonus';
  }

  @override
  String get coinsCancelLabel => 'Cancelar';

  @override
  String get coinsConfirmPurchase => 'Confirmar Compra';

  @override
  String coinsCost(int amount) {
    return '$amount moedas';
  }

  @override
  String get coinsCreditsOnly => 'Apenas Créditos';

  @override
  String get coinsDebitsOnly => 'Apenas Débitos';

  @override
  String get coinsEnterReceiverId => 'Introduz o ID do destinatário';

  @override
  String coinsExpiring(Object count) {
    return '$count a expirar';
  }

  @override
  String get coinsFilterTransactions => 'Filtrar Transações';

  @override
  String coinsGiftAccepted(Object amount) {
    return '$amount moedas aceites!';
  }

  @override
  String get coinsGiftDeclined => 'Presente recusado';

  @override
  String get coinsGiftSendFailed => 'Falha ao enviar presente';

  @override
  String coinsGiftSent(Object amount) {
    return 'Presente de $amount moedas enviado!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Moedas insuficientes';

  @override
  String get coinsLabel => 'Moedas';

  @override
  String get coinsMessageLabel => 'Mensagem (opcional)';

  @override
  String get coinsMins => 'min';

  @override
  String get coinsNoTransactionsYet => 'Sem transacoes ainda';

  @override
  String get coinsPendingGifts => 'Presentes Pendentes';

  @override
  String get coinsPopular => 'POPULAR';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Comprar $totalCoins moedas por $price?';
  }

  @override
  String get coinsPurchaseFailed => 'Compra falhada';

  @override
  String get coinsPurchaseLabel => 'Comprar';

  @override
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Comprar $totalMinutes minutos de video por $price?';
  }

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return 'Compra de $totalCoins moedas efetuada com sucesso!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return 'Compra de $totalMinutes minutos de vídeo efetuada com sucesso!';
  }

  @override
  String get coinsReceiverIdLabel => 'ID do Destinatário';

  @override
  String coinsRequired(int amount) {
    return '$amount moedas necessárias';
  }

  @override
  String get coinsRetry => 'Tentar novamente';

  @override
  String get coinsSelectAmount => 'Selecionar Quantia';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Enviar $amount Moedas';
  }

  @override
  String get coinsSendGift => 'Enviar Presente';

  @override
  String get coinsSent => 'Moedas enviadas com sucesso!';

  @override
  String get coinsShareCoins => 'Partilha moedas com alguem especial';

  @override
  String get coinsShopLabel => 'Loja';

  @override
  String get coinsTabCoins => 'Moedas';

  @override
  String get coinsTabGifts => 'Presentes';

  @override
  String get coinsTabVideoCoins => 'Moedas de Vídeo';

  @override
  String get coinsToday => 'Hoje';

  @override
  String get coinsTransactionHistory => 'Histórico de Transações';

  @override
  String get coinsTransactionsAppearHere =>
      'As tuas transacoes de moedas aparecerao aqui';

  @override
  String get coinsUnlockPremium => 'Desbloquear funcionalidades premium';

  @override
  String get coinsVideoCallMatches => 'Videochamada com os teus matchs';

  @override
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minuto de videochamada';

  @override
  String get coinsVideoMin => 'Min Video';

  @override
  String get coinsVideoMinutes => 'Minutos de Video';

  @override
  String get coinsYesterday => 'Ontem';

  @override
  String get comingSoonLabel => 'Em Breve';

  @override
  String get communitiesAddTag => 'Adicionar tag';

  @override
  String get communitiesAdjustSearch =>
      'Tenta ajustar a tua pesquisa ou filtros.';

  @override
  String get communitiesAllCommunities => 'Todas as Comunidades';

  @override
  String get communitiesAllFilter => 'Todas';

  @override
  String get communitiesAnyoneCanJoin => 'Qualquer pessoa pode aderir';

  @override
  String get communitiesBeFirstToSay => 'Se o primeiro a dizer algo!';

  @override
  String get communitiesCancelLabel => 'Cancelar';

  @override
  String get communitiesCityLabel => 'Cidade';

  @override
  String get communitiesCityTipLabel => 'Dica da Cidade';

  @override
  String get communitiesCityTipUpper => 'DICA DA CIDADE';

  @override
  String get communitiesCommunityInfo => 'Info da Comunidade';

  @override
  String get communitiesCommunityName => 'Nome da Comunidade';

  @override
  String get communitiesCommunityType => 'Tipo de Comunidade';

  @override
  String get communitiesCountryLabel => 'Pais';

  @override
  String get communitiesCreateAction => 'Criar';

  @override
  String get communitiesCreateCommunity => 'Criar Comunidade';

  @override
  String get communitiesCreateCommunityAction => 'Criar Comunidade';

  @override
  String get communitiesCreateLabel => 'Criar';

  @override
  String get communitiesCreateLanguageCircle => 'Criar Circulo Linguistico';

  @override
  String get communitiesCreated => 'Comunidade criada!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Criado por $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Criado';

  @override
  String get communitiesCulturalFactLabel => 'Facto Cultural';

  @override
  String get communitiesCulturalFactUpper => 'FACTO CULTURAL';

  @override
  String get communitiesDescription => 'Descricao';

  @override
  String get communitiesDescriptionHint => 'Sobre o que e esta comunidade?';

  @override
  String get communitiesDescriptionLabel => 'Descricao';

  @override
  String get communitiesDescriptionMinLength =>
      'A descricao deve ter pelo menos 10 caracteres';

  @override
  String get communitiesDescriptionRequired => 'Por favor insere uma descricao';

  @override
  String get communitiesDiscoverCommunities => 'Descobrir Comunidades';

  @override
  String get communitiesEditLabel => 'Editar';

  @override
  String get communitiesGuide => 'Guia';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Apenas com convite';

  @override
  String get communitiesJoinCommunity => 'Aderir a Comunidade';

  @override
  String get communitiesJoinPrompt =>
      'Adere a comunidades para te ligares a pessoas com os mesmos interesses e idiomas.';

  @override
  String get communitiesJoined => 'Entrou na comunidade!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Os circulos linguisticos aparecerao aqui quando disponiveis. Cria um para comecar!';

  @override
  String get communitiesLanguageTipLabel => 'Dica de Idioma';

  @override
  String get communitiesLanguageTipUpper => 'DICA DE IDIOMA';

  @override
  String get communitiesLanguages => 'Idiomas';

  @override
  String get communitiesLanguagesLabel => 'Idiomas';

  @override
  String get communitiesLeaveCommunity => 'Sair da Comunidade';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Tens a certeza de que queres sair de \"$name\"?';
  }

  @override
  String get communitiesLeaveLabel => 'Sair';

  @override
  String get communitiesLeaveTitle => 'Sair da Comunidade';

  @override
  String get communitiesLocation => 'Localizacao';

  @override
  String get communitiesLocationLabel => 'Localizacao';

  @override
  String communitiesMembersCount(Object count) {
    return '$count membros';
  }

  @override
  String get communitiesMembersStatLabel => 'Membros';

  @override
  String get communitiesMembersTitle => 'Membros';

  @override
  String get communitiesNameHint => 'ex., Aprendizes de Espanhol Lisboa';

  @override
  String get communitiesNameMinLength =>
      'O nome deve ter pelo menos 3 caracteres';

  @override
  String get communitiesNameRequired => 'Por favor insere um nome';

  @override
  String get communitiesNoCommunities => 'Sem Comunidades Ainda';

  @override
  String get communitiesNoCommunitiesFound => 'Nenhuma Comunidade Encontrada';

  @override
  String get communitiesNoLanguageCircles => 'Sem Circulos Linguisticos';

  @override
  String get communitiesNoMessagesYet => 'Sem mensagens ainda';

  @override
  String get communitiesPreview => 'Pre-visualizacao';

  @override
  String get communitiesPreviewSubtitle =>
      'E assim que a tua comunidade aparecera para outros.';

  @override
  String get communitiesPrivate => 'Privada';

  @override
  String get communitiesPublic => 'Publica';

  @override
  String get communitiesRecommendedForYou => 'Recomendado para Ti';

  @override
  String get communitiesSearchHint => 'Pesquisar comunidades...';

  @override
  String get communitiesShareCityTip => 'Partilha uma dica da cidade...';

  @override
  String get communitiesShareCulturalFact => 'Partilha um facto cultural...';

  @override
  String get communitiesShareLanguageTip => 'Partilha uma dica de idioma...';

  @override
  String get communitiesStats => 'Estatisticas';

  @override
  String get communitiesTabDiscover => 'Descobrir';

  @override
  String get communitiesTabLanguageCircles => 'Círculos Linguísticos';

  @override
  String get communitiesTabMyGroups => 'Os Meus Grupos';

  @override
  String get communitiesTags => 'Tags';

  @override
  String get communitiesTagsLabel => 'Tags';

  @override
  String get communitiesTextLabel => 'Texto';

  @override
  String get communitiesTitle => 'Comunidades';

  @override
  String get communitiesTypeAMessage => 'Escreve uma mensagem...';

  @override
  String get communitiesUnableToLoad =>
      'Nao foi possivel carregar a comunidade';

  @override
  String get compatibilityLabel => 'Compatibilidade';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compativel';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Completa conquistas para obter emblemas!';

  @override
  String get completeProfile => 'Complete o Seu Perfil';

  @override
  String get complimentsCategory => 'Elogios';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get confirmLocation => 'Confirmar localização';

  @override
  String get confirmPassword => 'Confirmar Palavra-passe';

  @override
  String get confirmPasswordRequired =>
      'Por favor confirme a sua palavra-passe';

  @override
  String get connectSocialAccounts => 'Liga as tuas contas sociais';

  @override
  String get connectionError => 'Erro de ligação';

  @override
  String get connectionErrorMessage =>
      'Verifica a tua ligação à internet e tenta novamente.';

  @override
  String get connectionErrorTitle => 'Sem Ligação à Internet';

  @override
  String get consentRequired => 'Consentimentos Obrigatórios';

  @override
  String get consentRequiredError =>
      'Você deve aceitar a Política de Privacidade e os Termos e Condições para se registrar';

  @override
  String get contactSupport => 'Contactar Suporte';

  @override
  String get continueLearningBtn => 'Continuar';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get continueWithFacebook => 'Continuar com Facebook';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get conversationCategory => 'Conversação';

  @override
  String get correctAnswer => 'Correto!';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get culturalCategory => 'Cultural';

  @override
  String get culturalExchangeBeFirstTip =>
      'Seja o primeiro a partilhar uma dica cultural!';

  @override
  String get culturalExchangeCategory => 'Categoria';

  @override
  String get culturalExchangeCommunityTips => 'Dicas da Comunidade';

  @override
  String get culturalExchangeCountry => 'País';

  @override
  String get culturalExchangeCountryHint => 'ex., Japão, Brasil, França';

  @override
  String get culturalExchangeCountrySpotlight => 'Destaque de País';

  @override
  String get culturalExchangeDailyInsight => 'Conhecimento Cultural Diário';

  @override
  String get culturalExchangeDatingEtiquette => 'Etiqueta de Encontros';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Guia de Etiqueta de Encontros';

  @override
  String get culturalExchangeLoadingCountries => 'A carregar países...';

  @override
  String get culturalExchangeNoTips => 'Sem dicas ainda';

  @override
  String get culturalExchangeShareCulturalTip => 'Partilhar uma Dica Cultural';

  @override
  String get culturalExchangeShareTip => 'Partilhar uma Dica';

  @override
  String get culturalExchangeSubmitTip => 'Submeter Dica';

  @override
  String get culturalExchangeTipTitle => 'Título';

  @override
  String get culturalExchangeTipTitleHint =>
      'Dê à sua dica um título apelativo';

  @override
  String get culturalExchangeTitle => 'Intercâmbio Cultural';

  @override
  String get culturalExchangeViewAll => 'Ver Todos';

  @override
  String get culturalExchangeYourTip => 'A Sua Dica';

  @override
  String get culturalExchangeYourTipHint =>
      'Partilhe o seu conhecimento cultural...';

  @override
  String get dailyChallengesSubtitle =>
      'Completa desafios para obter recompensas';

  @override
  String get dailyChallengesTitle => 'Desafios Diários';

  @override
  String dailyLimitReached(int limit) {
    return 'Limite diário de $limit atingido';
  }

  @override
  String get dailyMessages => 'Mensagens Diárias';

  @override
  String get dailyRewardHeader => 'Recompensa Diária';

  @override
  String get dailySwipeLimitReached =>
      'Limite diário de swipes atingido. Atualize para mais swipes!';

  @override
  String get dailySwipes => 'Swipes Diários';

  @override
  String get dataExportSentToEmail =>
      'Exportação de dados enviada para o teu email';

  @override
  String get dateOfBirth => 'Data de Nascimento';

  @override
  String get datePlanningCategory => 'Planear Encontro';

  @override
  String get dateSchedulerAccept => 'Aceitar';

  @override
  String get dateSchedulerCancelConfirm =>
      'Tens a certeza de que queres cancelar este encontro?';

  @override
  String get dateSchedulerCancelTitle => 'Cancelar Encontro';

  @override
  String get dateSchedulerConfirmed => 'Encontro confirmado!';

  @override
  String get dateSchedulerDecline => 'Recusar';

  @override
  String get dateSchedulerEnterTitle => 'Por favor, introduz um título';

  @override
  String get dateSchedulerKeepDate => 'Manter Encontro';

  @override
  String get dateSchedulerNotesLabel => 'Notas (opcional)';

  @override
  String get dateSchedulerPlanningHint => 'ex., Café, Jantar, Cinema...';

  @override
  String get dateSchedulerReasonLabel => 'Motivo (opcional)';

  @override
  String get dateSchedulerReschedule => 'Reagendar';

  @override
  String get dateSchedulerRescheduleTitle => 'Reagendar Encontro';

  @override
  String get dateSchedulerSchedule => 'Agendar';

  @override
  String get dateSchedulerScheduled => 'Encontro agendado!';

  @override
  String get dateSchedulerTabPast => 'Passados';

  @override
  String get dateSchedulerTabPending => 'Pendentes';

  @override
  String get dateSchedulerTabUpcoming => 'Próximos';

  @override
  String get dateSchedulerTitle => 'Os Meus Encontros';

  @override
  String get dateSchedulerWhatPlanning => 'O que estás a planear?';

  @override
  String dayNumber(int day) {
    return 'Dia $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count dias consecutivos';
  }

  @override
  String dayStreakLabel(int days) {
    return 'Sequência de $days Dias!';
  }

  @override
  String get days => 'Dias';

  @override
  String daysAgo(int count) {
    return 'há $count dias';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Eliminar Conta';

  @override
  String get deleteAccountConfirmation =>
      'Tens a certeza de que queres eliminar a tua conta? Esta ação não pode ser desfeita e todos os teus dados serão eliminados permanentemente.';

  @override
  String get details => 'Detalhes';

  @override
  String get difficultyLabel => 'Dificuldade';

  @override
  String directMessageCost(int cost) {
    return 'Mensagens diretas custam $cost moedas. Queres comprar mais moedas?';
  }

  @override
  String get discover => 'Rede';

  @override
  String discoveryError(String error) {
    return 'Erro: $error';
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
  String get discoveryFilterPassed => 'Recusados';

  @override
  String get discoveryFilterSkipped => 'Explorados';

  @override
  String get discoveryFilterSuperLiked => 'Prioritário';

  @override
  String get discoveryFilterNetwork => 'Minha Rede';

  @override
  String get discoveryFilterTravelers => 'Viajantes';

  @override
  String get discoveryLimitReached => 'Atingiste o teu limite de descoberta';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Gasta $coins moedas para ver mais';
  }

  @override
  String get discoveryPreferencesTitle => 'Preferencias de Descoberta';

  @override
  String get discoveryPreferencesTooltip => 'Preferências de Descoberta';

  @override
  String get discoverySwitchToGrid => 'Mudar para modo de grelha';

  @override
  String get discoverySwitchToSwipe => 'Mudar para modo de deslizar';

  @override
  String get dismiss => 'Fechar';

  @override
  String get distance => 'Distância';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Documento nao disponivel';

  @override
  String get documentNotAvailableDescription =>
      'Este documento ainda nao esta disponivel no teu idioma.';

  @override
  String get done => 'Concluído';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get download => 'Transferir';

  @override
  String downloadProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'A transferir $language...';
  }

  @override
  String get downloadingTranslationData => 'A Transferir Dados de Tradução';

  @override
  String get edit => 'Editar';

  @override
  String get editInterests => 'Editar Interesses';

  @override
  String get editNickname => 'Editar Alcunha';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get editVoiceComingSoon => 'Editar voz em breve';

  @override
  String get education => 'Educação';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Por favor introduza um email válido';

  @override
  String get emailRequired => 'Email é obrigatório';

  @override
  String get emergencyCategory => 'Emergência';

  @override
  String get emptyStateErrorMessage =>
      'Não conseguimos carregar este conteúdo. Tenta novamente.';

  @override
  String get emptyStateErrorTitle => 'Algo correu mal';

  @override
  String get emptyStateNoInternetMessage =>
      'Verifica a tua ligação à internet e tenta novamente.';

  @override
  String get emptyStateNoInternetTitle => 'Sem ligação';

  @override
  String get emptyStateNoLikesMessage =>
      'Completa o teu perfil para receberes mais gostos!';

  @override
  String get emptyStateNoLikesTitle => 'Sem gostos ainda';

  @override
  String get emptyStateNoMatchesMessage =>
      'Começa a deslizar para encontrar o teu par perfeito!';

  @override
  String get emptyStateNoMatchesTitle => 'Sem correspondências ainda';

  @override
  String get emptyStateNoMessagesMessage =>
      'Quando tiveres uma correspondência, podes começar a conversar aqui.';

  @override
  String get emptyStateNoMessagesTitle => 'Sem mensagens';

  @override
  String get emptyStateNoNotificationsMessage => 'Não tens notificações novas.';

  @override
  String get emptyStateNoNotificationsTitle => 'Tudo em dia!';

  @override
  String get emptyStateNoResultsMessage =>
      'Tenta ajustar a tua pesquisa ou filtros.';

  @override
  String get emptyStateNoResultsTitle => 'Sem resultados';

  @override
  String get enableAutoTranslation => 'Ativar Tradução Automática';

  @override
  String get enableNotifications => 'Ativar Notificações';

  @override
  String get enterAmount => 'Introduzir montante';

  @override
  String get enterNickname => 'Introduz alcunha';

  @override
  String get enterNicknameHint => 'Introduz a alcunha';

  @override
  String get enterNicknameToFind =>
      'Introduz uma alcunha para encontrar alguém diretamente';

  @override
  String get enterRejectionReason => 'Introduza o motivo da rejeição';

  @override
  String error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get errorLoadingDocument => 'Erro ao carregar o documento';

  @override
  String get errorSearchingTryAgain => 'Erro na pesquisa. Tenta novamente.';

  @override
  String get eventsAboutThisEvent => 'Sobre este evento';

  @override
  String get eventsApplyFilters => 'Aplicar Filtros';

  @override
  String get eventsAttendees => 'Participantes';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max a participar';
  }

  @override
  String get eventsBeFirstToSay => 'Se o primeiro a dizer algo!';

  @override
  String get eventsCategory => 'Categoria';

  @override
  String get eventsChatWithAttendees => 'Conversa com outros participantes';

  @override
  String get eventsCheckBackLater =>
      'Volta mais tarde ou cria o teu proprio evento!';

  @override
  String get eventsCreateEvent => 'Criar Evento';

  @override
  String get eventsCreatedSuccessfully => 'Evento criado com sucesso!';

  @override
  String get eventsDateRange => 'Intervalo de Datas';

  @override
  String get eventsDeleted => 'Evento eliminado';

  @override
  String get eventsDescription => 'Descricao';

  @override
  String get eventsDistance => 'Distancia';

  @override
  String get eventsEndDateTime => 'Data e Hora de Fim';

  @override
  String get eventsErrorLoadingMessages => 'Erro ao carregar mensagens';

  @override
  String get eventsEventFull => 'Evento Lotado';

  @override
  String get eventsEventTitle => 'Titulo do Evento';

  @override
  String get eventsFilterEvents => 'Filtrar Eventos';

  @override
  String get eventsFreeEvent => 'Evento Gratuito';

  @override
  String get eventsFreeLabel => 'GRATUITO';

  @override
  String get eventsFullLabel => 'Lotado';

  @override
  String eventsGoing(Object count) {
    return '$count vao participar';
  }

  @override
  String get eventsGoingLabel => 'Vou';

  @override
  String get eventsGroupChatTooltip => 'Chat de Grupo do Evento';

  @override
  String get eventsJoinEvent => 'Aderir ao Evento';

  @override
  String get eventsJoinLabel => 'Aderir';

  @override
  String eventsKmAwayFormat(String km) {
    return 'a $km km';
  }

  @override
  String get eventsLanguageExchange => 'Intercambio Linguistico';

  @override
  String get eventsLanguagePairs => 'Pares de Idiomas (ex., Espanhol ↔ Ingles)';

  @override
  String eventsLanguages(String languages) {
    return 'Idiomas: $languages';
  }

  @override
  String get eventsLocation => 'Localizacao';

  @override
  String eventsMAwayFormat(Object meters) {
    return 'a $meters m';
  }

  @override
  String get eventsMaxAttendees => 'Max. Participantes';

  @override
  String get eventsNoAttendeesYet => 'Sem participantes ainda. Se o primeiro!';

  @override
  String get eventsNoEventsFound => 'Nenhum evento encontrado';

  @override
  String get eventsNoMessagesYet => 'Sem mensagens ainda';

  @override
  String get eventsRequired => 'Obrigatorio';

  @override
  String get eventsRsvpCancelled => 'Participacao cancelada';

  @override
  String get eventsRsvpUpdated => 'Participacao atualizada!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count lugares disponiveis';
  }

  @override
  String get eventsStartDateTime => 'Data e Hora de Inicio';

  @override
  String get eventsTabMyEvents => 'Os Meus Eventos';

  @override
  String get eventsTabExperiences => 'Experiências';

  @override
  String get eventsTabAttractions => 'Atrações';

  @override
  String get eventsTabCommunity => 'Comunidade';

  @override
  String get eventsDeleteEvent => 'Eliminar evento';

  @override
  String get eventsDeleteConfirmBody =>
      'Tem a certeza de que quer eliminar este evento? Não pode ser anulado.';

  @override
  String get eventsBook => 'Reservar';

  @override
  String get eventsFromPrice => 'desde';

  @override
  String get eventsTabNearby => 'Perto';

  @override
  String get eventsTabUpcoming => 'Próximos';

  @override
  String get eventsThisMonth => 'Este Mês';

  @override
  String get eventsDateUntil => 'Até';

  @override
  String get eventsDateFrom => 'A partir de';

  @override
  String get eventsCustomRange => 'Intervalo personalizado';

  @override
  String get eventsDateAnyTime => 'A qualquer momento';

  @override
  String get eventsThisWeekFilter => 'Esta Semana';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get eventsAndPlacesTitle => 'Eventos e lugares';

  @override
  String get eventsCategoryAll => 'Todos';

  @override
  String attractionVisitWebsite(String host) {
    return 'Abrir $host';
  }

  @override
  String get attractionVisitWikidata => 'Abrir wikidata.org';

  @override
  String get attractionOpenInMaps => 'Abrir no Maps';

  @override
  String get attractionOpenLink => 'Abrir link';

  @override
  String get attractionOpenWebsite => 'Abrir site oficial';

  @override
  String get attractionShareChat => 'Compartilhar no chat';

  @override
  String get attractionShareGroup => 'Compartilhar no grupo';

  @override
  String get attractionDescribedAt => 'Saiba mais';

  @override
  String get attractionReport => 'Denunciar evento';

  @override
  String get attractionReportConfirm =>
      'Denunciar este item como inadequado ou incorreto?';

  @override
  String get eventsToday => 'Hoje';

  @override
  String get eventsTypeAMessage => 'Escreve uma mensagem...';

  @override
  String get exit => 'Sair';

  @override
  String get exitApp => 'Sair da App?';

  @override
  String get exitAppConfirmation =>
      'Tens a certeza de que queres sair do GreenGo?';

  @override
  String get exploreLanguages => 'Explorar Línguas';

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get communityTabTitle => 'Comunidade';

  @override
  String exploreHeadline(String city) {
    return 'Explorar $city';
  }

  @override
  String get exploreSubtitle =>
      'Experiências culturais e parceiros de idiomas perto de ti';

  @override
  String get explorePracticeLanguage => 'Praticar um idioma';

  @override
  String get exploreNetworkDiscovery => 'Descoberta de Rede';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'Pessoas com quem te ligares em $country';
  }

  @override
  String get exploreSeeAll => 'Ver tudo';

  @override
  String get exploreHappeningThisWeek => 'A acontecer esta semana';

  @override
  String get exploreHappeningToday => 'Hoje';

  @override
  String get exploreJoin => 'Participar';

  @override
  String get exploreFeatured => 'Experiência em destaque';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'fala $speaks · a aprender $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'fala $language';
  }

  @override
  String get exploreAroundYou => 'Pessoas perto de ti';

  @override
  String get exploreSameInterests => 'Pessoas com os teus interesses';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'Pessoas que falam $language';
  }

  @override
  String get exploreCommunityEventsNearby =>
      'Eventos da comunidade perto de ti';

  @override
  String get exploreNoPartners =>
      'Ainda não há parceiros de idiomas por perto — volta em breve.';

  @override
  String get exploreNoEvents =>
      'Ainda não há experiências para mostrar — volta em breve.';

  @override
  String get exploreNoCommunities =>
      'Ainda não há comunidades para aderir — volta em breve.';

  @override
  String exploreGoingCount(int count) {
    return '$count a participar';
  }

  @override
  String get exploreFeaturedEvents => 'Eventos em destaque';

  @override
  String get exploreFeaturedAttractions => 'Atrações em destaque';

  @override
  String get exploreMyNextEvents => 'Os meus próximos eventos';

  @override
  String get exploreCommunitiesTitle => 'Comunidades para aderir';

  @override
  String exploreMembersCount(int count) {
    return '$count membros';
  }

  @override
  String get exploreCountrySpotlight => 'País em destaque';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get greetingNight => 'Boa madrugada';

  @override
  String get statCoins => 'Moedas';

  @override
  String get statTier => 'Nível';

  @override
  String get statCountries => 'Países';

  @override
  String get statPeople => 'Pessoas';

  @override
  String get networkWorldMap => 'Rede Mundial';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return 'a $distance km';
  }

  @override
  String get connectAction => 'Conectar';

  @override
  String get connectError =>
      'Não foi possível iniciar a conversa. Tenta novamente.';

  @override
  String get sayHiAction => 'Dizer olá';

  @override
  String get newConnectionLabel => 'Nova ligação';

  @override
  String get connectionsTitle => 'Ligações';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km de distância';
  }

  @override
  String get exploreMapError =>
      'Não foi possível carregar utilizadores próximos';

  @override
  String get exploreMapExpandRadius => 'Expandir Raio';

  @override
  String get exploreMapExpandRadiusHint =>
      'Tente aumentar o raio de pesquisa para encontrar mais pessoas.';

  @override
  String get exploreMapNearbyUser => 'Utilizador Próximo';

  @override
  String get exploreMapNoOneNearby => 'Ninguém por perto';

  @override
  String get exploreMapOnlineNow => 'Online agora';

  @override
  String get exploreMapPeopleNearYou => 'Pessoas Perto de Si';

  @override
  String get exploreMapRadius => 'Raio:';

  @override
  String get exploreMapVisible => 'Visível';

  @override
  String get exportMyDataGDPR => 'Exportar os Meus Dados (RGPD)';

  @override
  String get exportingYourData => 'A exportar os teus dados...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Prolongar ($cost moedas)';
  }

  @override
  String get extendTooltip => 'Prolongar';

  @override
  String failedToDownloadModel(String language) {
    return 'Falha ao transferir o modelo de $language';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Falha ao guardar preferências';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Funcionalidade não disponível no plano $tier';
  }

  @override
  String get fillCategories => 'Preenche todas as categorias';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direto';

  @override
  String get filterMessaged => 'Com Mensagens';

  @override
  String get filterNew => 'Novos';

  @override
  String get filterNewMessages => 'Novas';

  @override
  String get filterNotReplied => 'Não lido';

  @override
  String filteredFromTotal(int total) {
    return 'Filtrado de $total';
  }

  @override
  String get filters => 'Filtros';

  @override
  String get finish => 'Terminar';

  @override
  String get firstName => 'Primeiro Nome';

  @override
  String get firstTo30Wins => 'O primeiro a chegar a 30 ganha!';

  @override
  String get flashcardReviewLabel => 'Cartões';

  @override
  String get flirtyCategory => 'Sedutor';

  @override
  String get foodDiningCategory => 'Comida e Restauração';

  @override
  String get forgotPassword => 'Esqueceu a Palavra-passe?';

  @override
  String freeActionsRemaining(int count) {
    return '$count ações gratuitas restantes hoje';
  }

  @override
  String get friendship => 'Amizade';

  @override
  String get gameAbandon => 'Abandonar';

  @override
  String get gameAbandonLoseMessage => 'Vais perder este jogo se saíres agora.';

  @override
  String get gameAbandonProgressMessage =>
      'Vais perder o teu progresso e voltar ao lobby.';

  @override
  String get gameAbandonTitle => 'Abandonar Jogo?';

  @override
  String get gameAbandonTooltip => 'Abandonar Jogo';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Escreve uma palavra que comece com \"$letter\"...';
  }

  @override
  String get gameCategoriesFilled => 'preenchido';

  @override
  String get gameCategoriesNewLetter => 'Nova Letra!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — começa com \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill => 'Toca numa categoria para preenchê-la!';

  @override
  String get gameCategoriesTimesUp =>
      'Tempo esgotado! A aguardar a próxima ronda...';

  @override
  String get gameCategoriesTitle => 'Categorias';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Palavra já usada noutra categoria!';

  @override
  String get gameCategoryAnimals => 'Animais';

  @override
  String get gameCategoryClothing => 'Vestuário';

  @override
  String get gameCategoryColors => 'Cores';

  @override
  String get gameCategoryCountries => 'Países';

  @override
  String get gameCategoryFood => 'Comida';

  @override
  String get gameCategoryNature => 'Natureza';

  @override
  String get gameCategoryProfessions => 'Profissões';

  @override
  String get gameCategorySports => 'Desportos';

  @override
  String get gameCategoryTransport => 'Transportes';

  @override
  String get gameChainBreak => 'CADEIA PARTIDA!';

  @override
  String get gameChainNextMustStartWith =>
      'A próxima palavra deve começar com: ';

  @override
  String get gameChainNoWordsYet => 'Ainda sem palavras!';

  @override
  String get gameChainStartWithAnyWord =>
      'Começa a cadeia com qualquer palavra';

  @override
  String get gameChainTitle => 'Cadeia de Vocabulário';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Escreve uma palavra que comece com \"$letter\"...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Escreve uma palavra para iniciar a cadeia...';

  @override
  String gameChainWordsChained(int count) {
    return '$count palavras encadeadas';
  }

  @override
  String get gameCorrect => 'Correto!';

  @override
  String get gameDefaultPlayerName => 'Jogador';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff à frente';
  }

  @override
  String get gameGrammarDuelAnswered => 'Respondeu';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff atrás';
  }

  @override
  String get gameGrammarDuelFast => 'RÁPIDO!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'QUESTÃO DE GRAMÁTICA';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points pontos!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count seguidas!';
  }

  @override
  String get gameGrammarDuelThinking => 'A pensar...';

  @override
  String get gameGrammarDuelTitle => 'Duelo de Gramática';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Resposta errada!';

  @override
  String get gameInvalidAnswer => 'Inválido!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Português do Brasil';

  @override
  String get gameLanguageEnglish => 'Inglês';

  @override
  String get gameLanguageFrench => 'Francês';

  @override
  String get gameLanguageGerman => 'Alemão';

  @override
  String get gameLanguageItalian => 'Italiano';

  @override
  String get gameLanguageJapanese => 'Japonês';

  @override
  String get gameLanguagePortuguese => 'Português';

  @override
  String get gameLanguageSpanish => 'Espanhol';

  @override
  String get gameLeave => 'Sair';

  @override
  String get gameOpponent => 'Adversário';

  @override
  String get gameOver => 'Fim do Jogo';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Tentativa $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'Não podes usar a própria palavra na tua pista!';

  @override
  String get gamePictureGuessClues => 'PISTAS';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count pista(s) enviada(s)';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Correto! +$points pontos';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Correto! A aguardar o fim da ronda...';

  @override
  String get gamePictureGuessDescriber => 'DESCRITOR';

  @override
  String get gamePictureGuessDescriberRules =>
      'Dá pistas para ajudar os outros a adivinhar. Sem traduções diretas nem dicas de ortografia!';

  @override
  String get gamePictureGuessGuessTheWord => 'Adivinha a palavra!';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'ADIVINHA A PALAVRA!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Sem mais tentativas — a aguardar o fim da ronda';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Sem mais tentativas nesta ronda';

  @override
  String get gamePictureGuessTheWordWas => 'A palavra era:';

  @override
  String get gamePictureGuessTitle => 'Adivinhar pela Imagem';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Escreve uma pista (sem traduções diretas!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Escreve a tua resposta... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'A aguardar pistas...';

  @override
  String get gamePictureGuessWaitingForOthers => 'A aguardar os outros...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Resposta errada: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'Tu és o DESCRITOR!';

  @override
  String get gamePictureGuessYourWord => 'A TUA PALAVRA';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Resposta enviada! A aguardar os outros...';

  @override
  String get gamePlayCategoriesHeader => 'CATEGORIAS';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Categoria: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Correto! +$points pts';
  }

  @override
  String get gamePlayDescribeThisWord => 'DESCREVE ESTA PALAVRA!';

  @override
  String get gamePlayDescribeWordHint => 'Descreve a palavra (não a digas!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name está a descrever uma palavra...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Não digas a própria palavra!';

  @override
  String get gamePlayGuessTheWord => 'ADIVINHA A PALAVRA';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Incorreto. A resposta era \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'CLASSIFICAÇÃO';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Diz uma palavra em $language que comece com \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Diz uma palavra em \"$category\" que comece com \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'A PRÓXIMA PALAVRA DEVE COMEÇAR COM';

  @override
  String get gamePlayNoWordsStartChain =>
      'Ainda sem palavras — começa a cadeia!';

  @override
  String get gamePlayPickLetterNameWord =>
      'Escolhe uma letra e diz uma palavra!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name está a escolher...';
  }

  @override
  String gamePlayPlayerIsThinking(String name) {
    return '$name está a pensar...';
  }

  @override
  String gamePlayThemeLabel(String theme) {
    return 'Tema: $theme';
  }

  @override
  String get gamePlayTranslateThisWord => 'TRADUZ ESTA PALAVRA';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Escreve uma palavra que contenha \"$prompt\"...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Escreve uma palavra que comece com \"$prompt\"...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Escreve a tradução...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Escreve uma palavra que contenha estas letras!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Escreve a tua resposta...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Escreve a tua resposta abaixo!';

  @override
  String get gamePlayTypeYourGuessHint => 'Escreve a tua resposta...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Usa o chat para descrever a palavra aos outros jogadores';

  @override
  String get gamePlayWaitingForOpponent => 'A aguardar o adversário...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Palavra que comece com \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Palavra que comece com \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards => 'A tua vez — vira duas cartas!';

  @override
  String gamePlayersTurn(String name) {
    return 'Vez de $name';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points pts';
  }

  @override
  String get gamePositionFirst => '1.º';

  @override
  String gamePositionNth(int pos) {
    return '$pos.º';
  }

  @override
  String get gamePositionSecond => '2.º';

  @override
  String get gamePositionThird => '3.º';

  @override
  String get gameResultsBackToLobby => 'Voltar ao Lobby';

  @override
  String get gameResultsBaseXp => 'XP Base';

  @override
  String get gameResultsCoinsEarned => 'Moedas Ganhas';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Bónus de Dificuldade (Nv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'CLASSIFICAÇÃO FINAL';

  @override
  String get gameResultsGameOver => 'FIM DE JOGO';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Moedas insuficientes ($amount necessárias)';
  }

  @override
  String get gameResultsPlayAgain => 'Jogar Novamente';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'RECOMPENSAS OBTIDAS';

  @override
  String get gameResultsTotalXp => 'XP Total';

  @override
  String get gameResultsVictory => 'VITÓRIA!';

  @override
  String get gameResultsWhatYouLearned => 'O QUE APRENDESTE';

  @override
  String get gameResultsWinner => 'Vencedor';

  @override
  String get gameResultsWinnerBonus => 'Bónus de Vencedor';

  @override
  String get gameResultsYouWon => 'Ganhaste!';

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
  String get gameSnapsNoMatch => 'Sem correspondência';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total pares encontrados';
  }

  @override
  String get gameSnapsTitle => 'Language Snaps';

  @override
  String get gameSnapsYourTurnFlipCards => 'A TUA VEZ — Vira 2 cartas!';

  @override
  String get gameSomeone => 'Alguém';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Diz uma palavra que comece com \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel => 'Escolhe uma letra da roda!';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Escolhe uma letra, diz uma palavra';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name perdeu uma vida';
  }

  @override
  String get gameTapplesTimeUp => 'TEMPO ESGOTADO!';

  @override
  String get gameTapplesTitle => 'Language Tapples';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Palavra que comece com \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount palavras usadas  •  $lettersCount letras restantes';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Correto';

  @override
  String get gameTranslationRaceFirstTo30 => 'O primeiro a chegar a 30 ganha!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Corrida de Tradução';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Traduz para $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'A aguardar os outros... $answered/$total responderam';
  }

  @override
  String get gameWaitForYourTurn => 'Espera pela tua vez...';

  @override
  String get gameWaiting => 'A aguardar';

  @override
  String get gameWaitingCancelReady => 'Cancelar Pronto';

  @override
  String get gameWaitingCountdownGo => 'VAI!';

  @override
  String get gameWaitingDisconnected => 'Desligado';

  @override
  String get gameWaitingEllipsis => 'A aguardar...';

  @override
  String get gameWaitingForPlayers => 'À Espera de Jogadores...';

  @override
  String get gameWaitingGetReady => 'Prepara-te...';

  @override
  String get gameWaitingHost => 'ANFITRIÃO';

  @override
  String get gameWaitingInviteCodeCopied => 'Código de convite copiado!';

  @override
  String get gameWaitingInviteCodeHeader => 'CÓDIGO DE CONVITE';

  @override
  String get gameWaitingInvitePlayer => 'Convidar Jogador';

  @override
  String get gameWaitingLeaveRoom => 'Sair da Sala';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Nível $level';
  }

  @override
  String get gameWaitingNotReady => 'Não Pronto';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count não prontos)';
  }

  @override
  String get gameWaitingPlayersHeader => 'JOGADORES';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count jogadores na sala';
  }

  @override
  String get gameWaitingReady => 'Pronto';

  @override
  String get gameWaitingReadyUp => 'Ficar Pronto';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count rondas';
  }

  @override
  String get gameWaitingShareCode =>
      'Partilha este código com amigos para se juntarem';

  @override
  String get gameWaitingStartGame => 'Iniciar Jogo';

  @override
  String get gameWordAlreadyUsed => 'Palavra já utilizada!';

  @override
  String get gameWordBombBoom => 'BOOM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'A palavra deve conter \"$prompt\"';
  }

  @override
  String get gameWordBombReport => 'Denunciar';

  @override
  String get gameWordBombReportContent =>
      'Denunciar esta palavra como inválida ou inadequada.';

  @override
  String gameWordBombReportTitle(String word) {
    return 'Denunciar \"$word\"?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      'O tempo esgotou! Perdeste uma vida.';

  @override
  String get gameWordBombTitle => 'Bomba de Palavras';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Escreve uma palavra que contenha \"$prompt\"...';
  }

  @override
  String get gameWordBombUsedWords => 'Palavras Usadas';

  @override
  String get gameWordBombWordReported => 'Palavra denunciada';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count palavras usadas';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'A palavra deve começar com \"$letter\"';
  }

  @override
  String get gameWrong => 'Errado';

  @override
  String get gameYou => 'Tu';

  @override
  String get gameYourTurn => 'A TUA VEZ!';

  @override
  String get gamificationAchievements => 'Conquistas';

  @override
  String get gamificationAll => 'Todos';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name concluído!';
  }

  @override
  String get gamificationClaim => 'Reclamar';

  @override
  String get gamificationClaimReward => 'Reclamar Recompensa';

  @override
  String get gamificationCoinsAvailable => 'Moedas Disponíveis';

  @override
  String get gamificationDaily => 'Diário';

  @override
  String get gamificationDailyChallenges => 'Desafios Diários';

  @override
  String get gamificationDayStreak => 'Dias Consecutivos';

  @override
  String get gamificationDone => 'Concluído';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Ganho em $date';
  }

  @override
  String get gamificationEasy => 'Fácil';

  @override
  String get gamificationEngagement => 'Interação';

  @override
  String get gamificationEpic => 'Épico';

  @override
  String get gamificationExperiencePoints => 'Pontos de Experiência';

  @override
  String get gamificationGlobal => 'Global';

  @override
  String get gamificationHard => 'Difícil';

  @override
  String get gamificationLeaderboard => 'Classificação';

  @override
  String gamificationLevel(Object level) {
    return 'Nível $level';
  }

  @override
  String get gamificationLevelLabel => 'NÍVEL';

  @override
  String gamificationLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'A carregar conquistas...';

  @override
  String get gamificationLoadingChallenges => 'A carregar desafios...';

  @override
  String get gamificationLoadingRankings => 'A carregar classificações...';

  @override
  String get gamificationMedium => 'Médio';

  @override
  String get gamificationMilestones => 'Marcos';

  @override
  String get gamificationMonthly => 'Mes';

  @override
  String get gamificationMyProgress => 'O Meu Progresso';

  @override
  String get gamificationNoAchievements => 'Nenhuma conquista encontrada';

  @override
  String get gamificationNoAchievementsInCategory =>
      'Nenhuma conquista nesta categoria';

  @override
  String get gamificationNoChallenges => 'Nenhum desafio disponível';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'Nenhum desafio $type disponível';
  }

  @override
  String get gamificationNoLeaderboard => 'Sem dados de classificação';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Membro Premium';

  @override
  String get gamificationProgress => 'Progresso';

  @override
  String get gamificationRank => 'POSIÇÃO';

  @override
  String get gamificationRankLabel => 'Posição';

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
  String get gamificationVerifiedUser => 'Utilizador Verificado';

  @override
  String get gamificationVipMember => 'Membro VIP';

  @override
  String get gamificationWeekly => 'Semanal';

  @override
  String get gamificationXpAvailable => 'XP Disponível';

  @override
  String get gamificationYearly => 'Ano';

  @override
  String get gamificationYourPosition => 'A Sua Posição';

  @override
  String get gender => 'Género';

  @override
  String get getStarted => 'Começar';

  @override
  String get giftCategoryAll => 'Todos';

  @override
  String giftFromSender(Object name) {
    return 'De $name';
  }

  @override
  String get giftGetCoins => 'Obter Moedas';

  @override
  String get giftNoGiftsAvailable => 'Nenhum presente disponível';

  @override
  String get giftNoGiftsInCategory => 'Nenhum presente nesta categoria';

  @override
  String get giftNoGiftsYet => 'Sem presentes ainda';

  @override
  String get giftNotEnoughCoins => 'Moedas Insuficientes';

  @override
  String giftPriceCoins(Object price) {
    return '$price moedas';
  }

  @override
  String get giftReceivedGifts => 'Presentes Recebidos';

  @override
  String get giftReceivedGiftsEmpty =>
      'Os presentes que receber aparecerão aqui';

  @override
  String get giftSendGift => 'Enviar Presente';

  @override
  String giftSendGiftTo(Object name) {
    return 'Enviar Presente para $name';
  }

  @override
  String get giftSending => 'A enviar...';

  @override
  String giftSentTo(Object name) {
    return 'Presente enviado para $name!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Tem $available moedas.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Precisa de $required moedas para este presente.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Precisa de mais $shortfall moedas.';
  }

  @override
  String get gold => 'Ouro';

  @override
  String get grantAlbumAccess => 'Partilhar meu álbum';

  @override
  String get greatInterestsHelp =>
      'Ótimo! Os teus interesses ajudam-nos a encontrar melhores matches';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Saudações';

  @override
  String get guideBadge => 'Guia';

  @override
  String get height => 'Altura';

  @override
  String get helpAndSupport => 'Ajuda e Suporte';

  @override
  String get helpOthersFindYou =>
      'Ajuda outros a encontrar-te nas redes sociais';

  @override
  String get hours => 'Horas';

  @override
  String get icebreakersCategoryCompliments => 'Elogios';

  @override
  String get icebreakersCategoryDateIdeas => 'Ideias para Encontros';

  @override
  String get icebreakersCategoryDeep => 'Profundo';

  @override
  String get icebreakersCategoryDreams => 'Sonhos';

  @override
  String get icebreakersCategoryFood => 'Comida';

  @override
  String get icebreakersCategoryFunny => 'Divertido';

  @override
  String get icebreakersCategoryHobbies => 'Passatempos';

  @override
  String get icebreakersCategoryHypothetical => 'Hipotético';

  @override
  String get icebreakersCategoryMovies => 'Filmes';

  @override
  String get icebreakersCategoryMusic => 'Música';

  @override
  String get icebreakersCategoryPersonality => 'Personalidade';

  @override
  String get icebreakersCategoryTravel => 'Viagens';

  @override
  String get icebreakersCategoryTwoTruths => 'Duas Verdades';

  @override
  String get icebreakersCategoryWouldYouRather => 'O Que Preferes';

  @override
  String get icebreakersLabel => 'Quebra-gelo';

  @override
  String get icebreakersNoneInCategory => 'Nenhum quebra-gelo nesta categoria';

  @override
  String get icebreakersQuickAnswers => 'Respostas rápidas:';

  @override
  String get icebreakersSendAnIcebreaker => 'Enviar um quebra-gelo';

  @override
  String icebreakersSendTo(Object name) {
    return 'Enviar para $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Enviar sem resposta';

  @override
  String get icebreakersTitle => 'Quebra-gelos';

  @override
  String get idiomsCategory => 'Expressões Idiomáticas';

  @override
  String get incognitoMode => 'Modo Incógnito';

  @override
  String get incognitoModeDescription => 'Ocultar o seu perfil da descoberta';

  @override
  String get incorrectAnswer => 'Incorreto';

  @override
  String get infoUpdatedMessage =>
      'As tuas informações básicas foram guardadas';

  @override
  String get infoUpdatedTitle => 'Informações Atualizadas!';

  @override
  String get insufficientCoins => 'Moedas insuficientes';

  @override
  String get insufficientCoinsTitle => 'Moedas Insuficientes';

  @override
  String get interestArt => 'Arte';

  @override
  String get interestBeach => 'Praia';

  @override
  String get interestBeer => 'Cerveja';

  @override
  String get interestBusiness => 'Negócios';

  @override
  String get interestCamping => 'Campismo';

  @override
  String get interestCats => 'Gatos';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestCooking => 'Culinária';

  @override
  String get interestCycling => 'Ciclismo';

  @override
  String get interestDance => 'Dança';

  @override
  String get interestDancing => 'Dança';

  @override
  String get interestDogs => 'Cães';

  @override
  String get interestEntrepreneurship => 'Empreendedorismo';

  @override
  String get interestEnvironment => 'Ambiente';

  @override
  String get interestFashion => 'Moda';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Comida';

  @override
  String get interestGaming => 'Videojogos';

  @override
  String get interestHiking => 'Caminhadas';

  @override
  String get interestHistory => 'História';

  @override
  String get interestInvesting => 'Investimento';

  @override
  String get interestLanguages => 'Línguas';

  @override
  String get interestMeditation => 'Meditação';

  @override
  String get interestMountains => 'Montanhas';

  @override
  String get interestMovies => 'Filmes';

  @override
  String get interestMusic => 'Música';

  @override
  String get interestNature => 'Natureza';

  @override
  String get interestPets => 'Animais de estimação';

  @override
  String get interestPhotography => 'Fotografia';

  @override
  String get interestPoetry => 'Poesia';

  @override
  String get interestPolitics => 'Política';

  @override
  String get interestReading => 'Leitura';

  @override
  String get interestRunning => 'Corrida';

  @override
  String get interestScience => 'Ciência';

  @override
  String get interestSkiing => 'Esqui';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestSpirituality => 'Espiritualidade';

  @override
  String get interestSports => 'Desporto';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSwimming => 'Natação';

  @override
  String get interestTeaching => 'Ensino';

  @override
  String get interestTechnology => 'Tecnologia';

  @override
  String get interestTravel => 'Viagens';

  @override
  String get interestVegan => 'Vegano';

  @override
  String get interestVegetarian => 'Vegetariano';

  @override
  String get interestVolunteering => 'Voluntariado';

  @override
  String get interestWine => 'Vinho';

  @override
  String get interestWriting => 'Escrita';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Interesses';

  @override
  String interestsCount(int count) {
    return '$count interesses';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max interesses selecionados';
  }

  @override
  String get interestsUpdatedMessage => 'Os teus interesses foram guardados';

  @override
  String get interestsUpdatedTitle => 'Interesses Atualizados!';

  @override
  String get invalidWord => 'Palavra inválida';

  @override
  String get inviteCodeCopied => 'Código de convite copiado!';

  @override
  String get inviteFriends => 'Convidar Amigos';

  @override
  String get itsAMatch => 'Comece a conectar!';

  @override
  String get joinMessage =>
      'Junte-se ao GreenGoChat e encontre o seu par perfeito';

  @override
  String get keepSwiping => 'Continuar a Deslizar';

  @override
  String get langMatchBadge => 'Idioma Compativel';

  @override
  String get language => 'Idioma';

  @override
  String languageChangedTo(String language) {
    return 'Idioma alterado para $language';
  }

  @override
  String get languagePacksBtn => 'Pacotes de Línguas';

  @override
  String get languagePacksShopTitle => 'Loja de Pacotes de Línguas';

  @override
  String get languagesToDownloadLabel => 'Idiomas a transferir:';

  @override
  String get lastName => 'Apelido';

  @override
  String get lastUpdated => 'Ultima atualizacao';

  @override
  String get leaderboardSubtitle => 'Classificacoes globais e regionais';

  @override
  String get leaderboardTitle => 'Classificação';

  @override
  String get learn => 'Aprender';

  @override
  String get learningAccuracy => 'Precisão';

  @override
  String get learningActiveThisWeek => 'Ativo Esta Semana';

  @override
  String get learningAddLessonSection => 'Adicionar Secção de Lição';

  @override
  String get learningAiConversationCoach => 'Coach de Conversação IA';

  @override
  String get learningAllCategories => 'Todas as Categorias';

  @override
  String get learningAllLessons => 'Todas as Lições';

  @override
  String get learningAllLevels => 'Todos os Níveis';

  @override
  String get learningAmount => 'Montante';

  @override
  String get learningAmountLabel => 'Montante';

  @override
  String get learningAnalytics => 'Análise';

  @override
  String learningAnswer(Object answer) {
    return 'Resposta: $answer';
  }

  @override
  String get learningApplyFilters => 'Aplicar Filtros';

  @override
  String get learningAreasToImprove => 'Áreas a Melhorar';

  @override
  String get learningAvailableBalance => 'Saldo Disponível';

  @override
  String get learningAverageRating => 'Classificação Média';

  @override
  String get learningBeginnerProgress => 'Progresso de Iniciante';

  @override
  String get learningBonusCoins => 'Moedas Bónus';

  @override
  String get learningCategory => 'Categoria';

  @override
  String get learningCategoryProgress => 'Progresso por Categoria';

  @override
  String get learningCheck => 'Verificar';

  @override
  String get learningCheckBackSoon => 'Volte em breve!';

  @override
  String get learningCoachSessionCost =>
      '10 moedas/sessão  |  25 XP de recompensa';

  @override
  String get learningContinue => 'Continuar';

  @override
  String get learningCorrect => 'Correto!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Correto: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Respostas Corretas';

  @override
  String get learningCorrectLabel => 'Correto';

  @override
  String get learningCorrections => 'Correções';

  @override
  String get learningCreateLesson => 'Criar Lição';

  @override
  String get learningCreateNewLesson => 'Criar Nova Lição';

  @override
  String get learningCustomPackTitleHint =>
      'ex., \"Cumprimentos em Espanhol para Encontros\"';

  @override
  String get learningDescribeImage => 'Descreva esta imagem';

  @override
  String get learningDescriptionHint => 'O que os alunos vão aprender?';

  @override
  String get learningDescriptionLabel => 'Descrição';

  @override
  String get learningDifficultyLevel => 'Nível de Dificuldade';

  @override
  String get learningDone => 'Concluído';

  @override
  String get learningDraftSave => 'Guardar Rascunho';

  @override
  String get learningDraftSaved => 'Rascunho guardado!';

  @override
  String get learningEarned => 'Ganho';

  @override
  String get learningEdit => 'Editar';

  @override
  String get learningEndSession => 'Terminar Sessão';

  @override
  String get learningEndSessionBody =>
      'O progresso da sessão atual será perdido. Deseja terminar a sessão e ver a pontuação primeiro?';

  @override
  String get learningEndSessionQuestion => 'Terminar Sessão?';

  @override
  String get learningExit => 'Sair';

  @override
  String get learningFalse => 'Falso';

  @override
  String get learningFilterAll => 'Todos';

  @override
  String get learningFilterDraft => 'Rascunho';

  @override
  String get learningFilterLessons => 'Filtrar Lições';

  @override
  String get learningFilterPublished => 'Publicado';

  @override
  String get learningFilterUnderReview => 'Em Revisão';

  @override
  String get learningFluency => 'Fluência';

  @override
  String get learningFree => 'FREE';

  @override
  String get learningGoBack => 'Voltar';

  @override
  String get learningGoalCompleteLessons => 'Completar 5 lições';

  @override
  String get learningGoalEarnXp => 'Ganhar 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Praticar 30 minutos';

  @override
  String get learningGrammar => 'Gramática';

  @override
  String get learningHint => 'Dica';

  @override
  String get learningLangBrazilianPortuguese => 'Português do Brasil';

  @override
  String get learningLangEnglish => 'Inglês';

  @override
  String get learningLangFrench => 'Francês';

  @override
  String get learningLangGerman => 'Alemão';

  @override
  String get learningLangItalian => 'Italiano';

  @override
  String get learningLangPortuguese => 'Português';

  @override
  String get learningLangSpanish => 'Espanhol';

  @override
  String get learningLanguagesSubtitle =>
      'Selecione até 5 idiomas. Isto ajuda-nos a ligá-lo a falantes nativos e parceiros de aprendizagem.';

  @override
  String get learningLanguagesTitle => 'Que idiomas quer aprender?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Idiomas para aprender ($count/5)';
  }

  @override
  String get learningLastMonth => 'Mês Passado';

  @override
  String learningLearnLanguage(Object language) {
    return 'Aprender $language';
  }

  @override
  String get learningLearned => 'Aprendido';

  @override
  String get learningLessonComplete => 'Lição Concluída!';

  @override
  String get learningLessonCompleteUpper => 'LIÇÃO CONCLUÍDA!';

  @override
  String get learningLessonContent => 'Conteúdo da Lição';

  @override
  String learningLessonNumber(Object number) {
    return 'Lição $number';
  }

  @override
  String get learningLessonSubmitted => 'Lição submetida para revisão!';

  @override
  String get learningLessonTitle => 'Título da Lição';

  @override
  String get learningLessonTitleHint =>
      'ex., \"Saudações em Espanhol para Encontros\"';

  @override
  String get learningLessonTitleLabel => 'Título da Lição';

  @override
  String get learningLessonsLabel => 'Lições';

  @override
  String get learningLetsStart => 'Vamos Começar!';

  @override
  String get learningLevel => 'Nível';

  @override
  String learningLevelBadge(Object level) {
    return 'NV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Nível $level';
  }

  @override
  String get learningListen => 'Ouvir';

  @override
  String get learningListening => 'A ouvir...';

  @override
  String get learningLongPressForTranslation => 'Pressão longa para tradução';

  @override
  String get learningMessages => 'Mensagens';

  @override
  String get learningMessagesSent => 'Mensagens enviadas';

  @override
  String get learningMinimumWithdrawal => 'Levantamento mínimo: \$50,00';

  @override
  String get learningMonthlyEarnings => 'Ganhos Mensais';

  @override
  String get learningMyProgress => 'O Meu Progresso';

  @override
  String get learningNativeLabel => '(nativo)';

  @override
  String get learningNativeLanguage => 'A sua língua nativa';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Precisa de pelo menos $threshold% para passar nesta lição.';
  }

  @override
  String get learningNext => 'Seguinte';

  @override
  String get learningNoExercisesInSection => 'Sem exercícios nesta secção';

  @override
  String get learningNoLessonsAvailable => 'Nenhuma lição disponível ainda';

  @override
  String get learningNoPacksFound => 'Nenhum pacote encontrado';

  @override
  String get learningNoQuestionsAvailable =>
      'Nenhuma pergunta disponível ainda.';

  @override
  String get learningNotQuite => 'Não exatamente';

  @override
  String get learningNotQuiteTitle => 'Quase Lá...';

  @override
  String get learningOpenAiCoach => 'Abrir Coach IA';

  @override
  String learningPackFilter(Object category) {
    return 'Pacote: $category';
  }

  @override
  String get learningPackPurchased => 'Pacote comprado com sucesso!';

  @override
  String get learningPassageRevealed => 'Passagem (revelada)';

  @override
  String get learningPathTitle => 'Percurso de Aprendizagem';

  @override
  String get learningPlaying => 'A reproduzir...';

  @override
  String get learningPleaseEnterDescription =>
      'Por favor, introduza uma descrição';

  @override
  String get learningPleaseEnterTitle => 'Por favor, introduza um título';

  @override
  String get learningPracticeAgain => 'Praticar Novamente';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Lições Publicadas';

  @override
  String get learningPurchased => 'Comprado';

  @override
  String get learningPurchasedLessonsEmpty =>
      'As suas lições compradas aparecerão aqui';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count perguntas nesta lição';
  }

  @override
  String get learningQuickActions => 'Ações Rápidas';

  @override
  String get learningReadPassage => 'Leia a passagem';

  @override
  String get learningRecentActivity => 'Atividade Recente';

  @override
  String get learningRecentMilestones => 'Marcos Recentes';

  @override
  String get learningRecentTransactions => 'Transações Recentes';

  @override
  String get learningRequired => 'Obrigatório';

  @override
  String get learningResponseRecorded => 'Resposta registada';

  @override
  String get learningReview => 'Revisão';

  @override
  String get learningSearchLanguages => 'Pesquisar idiomas...';

  @override
  String get learningSectionEditorComingSoon => 'Editor de secções em breve!';

  @override
  String get learningSeeScore => 'Ver Pontuação';

  @override
  String get learningSelectNativeLanguage => 'Selecione a sua língua nativa';

  @override
  String get learningSelectScenario => 'Selecione um cenário para começar';

  @override
  String get learningSelectScenarioFirst => 'Selecione um cenário primeiro...';

  @override
  String get learningSessionComplete => 'Sessão Concluída!';

  @override
  String get learningSessionSummary => 'Resumo da Sessão';

  @override
  String get learningShowAll => 'Mostrar Todos';

  @override
  String get learningShowPassageText => 'Mostrar texto da passagem';

  @override
  String get learningSkip => 'Saltar';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return 'Gastar $price moedas para desbloquear esta lição?';
  }

  @override
  String get learningStartFlashcards => 'Iniciar Cartões';

  @override
  String get learningStartLesson => 'Iniciar Lição';

  @override
  String get learningStartPractice => 'Iniciar Prática';

  @override
  String get learningStartQuiz => 'Iniciar Questionário';

  @override
  String get learningStartingLesson => 'A iniciar lição...';

  @override
  String get learningStop => 'Parar';

  @override
  String get learningStreak => 'Sequência';

  @override
  String get learningStrengths => 'Pontos Fortes';

  @override
  String get learningSubmit => 'Submeter';

  @override
  String get learningSubmitForReview => 'Submeter para Revisão';

  @override
  String get learningSubmitForReviewBody =>
      'A sua lição será revista pela nossa equipa antes de ficar disponível. Isto demora normalmente 24-48 horas.';

  @override
  String get learningSubmitForReviewQuestion => 'Submeter para Revisão?';

  @override
  String get learningTabAllLessons => 'Todas as Lições';

  @override
  String get learningTabEarnings => 'Ganhos';

  @override
  String get learningTabFlashcards => 'Cartões';

  @override
  String get learningTabLessons => 'Lições';

  @override
  String get learningTabMyLessons => 'As Minhas Lições';

  @override
  String get learningTabMyProgress => 'O Meu Progresso';

  @override
  String get learningTabOverview => 'Resumo';

  @override
  String get learningTabPhrases => 'Frases';

  @override
  String get learningTabProgress => 'Progresso';

  @override
  String get learningTabPurchased => 'Comprados';

  @override
  String get learningTabQuizzes => 'Questionários';

  @override
  String get learningTabStudents => 'Alunos';

  @override
  String get learningTapToContinue => 'Toque para continuar';

  @override
  String get learningTapToHearPassage => 'Toque para ouvir a passagem';

  @override
  String get learningTapToListen => 'Toque para ouvir';

  @override
  String get learningTapToMatch => 'Toque nos itens para combiná-los';

  @override
  String get learningTapToRevealTranslation => 'Toque para revelar tradução';

  @override
  String get learningTapWordsToBuild =>
      'Toque nas palavras abaixo para construir a frase';

  @override
  String get learningTargetLanguage => 'Idioma Alvo';

  @override
  String get learningTeacherDashboardTitle => 'Painel do Professor';

  @override
  String get learningTeacherTiers => 'Níveis de Professor';

  @override
  String get learningThisMonth => 'Este Mês';

  @override
  String get learningTopPerformingStudents => 'Melhores Alunos';

  @override
  String get learningTotalStudents => 'Total de Alunos';

  @override
  String get learningTotalStudentsLabel => 'Total de Alunos';

  @override
  String get learningTotalXp => 'XP Total';

  @override
  String get learningTranslatePhrase => 'Traduza esta frase';

  @override
  String get learningTrue => 'Verdadeiro';

  @override
  String get learningTryAgain => 'Tentar Novamente';

  @override
  String get learningTypeAnswerBelow => 'Escreva a sua resposta abaixo';

  @override
  String get learningTypeAnswerHint => 'Escreva a sua resposta...';

  @override
  String get learningTypeDescriptionHint => 'Escreve a tua descrição...';

  @override
  String get learningTypeMessageHint => 'Escreva a sua mensagem...';

  @override
  String get learningTypeMissingWordHint => 'Escreve a palavra em falta...';

  @override
  String get learningTypeSentenceHint => 'Escreva a frase...';

  @override
  String get learningTypeTranslationHint => 'Escreve a tua tradução...';

  @override
  String get learningTypeWhatYouHeardHint => 'Escreve o que ouviste...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unidade $unit - Lição $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unidade $number';
  }

  @override
  String get learningUnlock => 'Desbloquear';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Desbloquear por $price Moedas';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Desbloquear por $price moedas';
  }

  @override
  String get learningUnlockLesson => 'Desbloquear Lição';

  @override
  String get learningViewAll => 'Ver Todos';

  @override
  String get learningViewAnalytics => 'Ver Análise';

  @override
  String get learningVocabulary => 'Vocabulário';

  @override
  String learningWeek(Object week) {
    return 'Semana $week';
  }

  @override
  String get learningWeeklyGoals => 'Objetivos Semanais';

  @override
  String get learningWhatWillStudentsLearnHint =>
      'O que vão os alunos aprender?';

  @override
  String get learningWhatYouWillLearn => 'O que vai aprender';

  @override
  String get learningWithdraw => 'Levantar';

  @override
  String get learningWithdrawFunds => 'Levantar Fundos';

  @override
  String get learningWithdrawalSubmitted => 'Pedido de levantamento submetido!';

  @override
  String get learningWordsAndPhrases => 'Palavras e Frases';

  @override
  String get learningWriteAnswerFreely => 'Escreve a tua resposta livremente';

  @override
  String get learningWriteAnswerHint => 'Escreve a tua resposta...';

  @override
  String get learningXpEarned => 'XP Ganho';

  @override
  String learningYourAnswer(Object answer) {
    return 'A sua resposta: $answer';
  }

  @override
  String get learningYourScore => 'A Sua Pontuação';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lição';

  @override
  String get letsChat => 'Vamos conversar!';

  @override
  String get letsExchange => 'Comece a conectar!';

  @override
  String get levelLabel => 'Nivel';

  @override
  String levelLabelN(String level) {
    return 'Nível $level';
  }

  @override
  String get levelTitleEnthusiast => 'Entusiasta';

  @override
  String get levelTitleExpert => 'Especialista';

  @override
  String get levelTitleExplorer => 'Explorador';

  @override
  String get levelTitleLegend => 'Lenda';

  @override
  String get levelTitleMaster => 'Mestre';

  @override
  String get levelTitleNewcomer => 'Novato';

  @override
  String get levelTitleVeteran => 'Veterano';

  @override
  String get levelUp => 'SUBIU DE NÍVEL!';

  @override
  String get levelUpCongratulations => 'Parabéns por alcançar um novo nível!';

  @override
  String get levelUpContinue => 'Continuar';

  @override
  String get levelUpRewards => 'RECOMPENSAS';

  @override
  String get levelUpTitle => 'SUBIU DE NÍVEL!';

  @override
  String get levelUpVIPUnlocked => 'Estado VIP Desbloqueado!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Alcançaste o Nível $level';
  }

  @override
  String get likes => 'Gostos';

  @override
  String get limitReachedTitle => 'Limite Atingido';

  @override
  String get listenMe => 'Ouve-me!';

  @override
  String get loading => 'A carregar...';

  @override
  String get loadingLabel => 'A carregar...';

  @override
  String get localGuideBadge => 'Guia Local';

  @override
  String get location => 'Localização';

  @override
  String get locationAndLanguages => 'Localização e Idiomas';

  @override
  String get locationError => 'Erro de Localização';

  @override
  String get locationNotFound => 'Localização Não Encontrada';

  @override
  String get locationNotFoundMessage =>
      'Não foi possível determinar o seu endereço. Por favor, tente novamente ou defina a sua localização manualmente mais tarde.';

  @override
  String get locationPermissionDenied => 'Permissão Negada';

  @override
  String get locationPermissionDeniedMessage =>
      'A permissão de localização é necessária para detetar a sua localização atual. Por favor, conceda permissão para continuar.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permissão Permanentemente Negada';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'A permissão de localização foi permanentemente negada. Por favor, ative-a nas definições do seu dispositivo para usar esta funcionalidade.';

  @override
  String get locationRequestTimeout => 'Tempo de Pedido Esgotado';

  @override
  String get locationRequestTimeoutMessage =>
      'A obtenção da sua localização demorou demasiado. Por favor, verifique a sua ligação e tente novamente.';

  @override
  String get locationServicesDisabled => 'Serviços de Localização Desativados';

  @override
  String get locationServicesDisabledMessage =>
      'Por favor, ative os serviços de localização nas definições do seu dispositivo para usar esta funcionalidade.';

  @override
  String get locationUnavailable =>
      'Não é possível obter a sua localização de momento. Pode defini-la manualmente mais tarde nas definições.';

  @override
  String get locationUnavailableTitle => 'Localização Indisponível';

  @override
  String get locationUpdatedMessage =>
      'As tuas definições de localização foram guardadas';

  @override
  String get locationUpdatedTitle => 'Localização Atualizada!';

  @override
  String get logOut => 'Sair';

  @override
  String get logOutConfirmation => 'Tens a certeza de que queres sair?';

  @override
  String get login => 'Entrar';

  @override
  String get loginWithBiometrics => 'Entrar com Biometria';

  @override
  String get logout => 'Sair';

  @override
  String get longTermRelationship => 'Relação a longo prazo';

  @override
  String get lookingFor => 'Procura';

  @override
  String get lvl => 'NIV';

  @override
  String get manageCouponsTiersRules => 'Gerir cupões, níveis e regras';

  @override
  String get matchDetailsTitle => 'Detalhes da Troca';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Tu e $name querem trocar idiomas!';
  }

  @override
  String get matchNotifKeepSwiping => 'Continuar a Deslizar';

  @override
  String get matchNotifLetsChat => 'Vamos conversar!';

  @override
  String get matchNotifLetsExchange => 'COMECE A CONECTAR!';

  @override
  String get matchNotifViewProfile => 'Ver Perfil';

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilidade';
  }

  @override
  String matchedOnDate(String date) {
    return 'Match em $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Fizeste match com $name em $date';
  }

  @override
  String get matches => 'Correspondências';

  @override
  String get matchesClearFilters => 'Limpar Filtros';

  @override
  String matchesCount(int count) {
    return '$count correspondências';
  }

  @override
  String get matchesFilterAll => 'Todos';

  @override
  String get matchesFilterMessaged => 'Com Mensagens';

  @override
  String get matchesFilterNew => 'Novos';

  @override
  String get matchesNoMatchesFound => 'Nenhum match encontrado';

  @override
  String get matchesNoMatchesYet => 'Sem matchs ainda';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered de $total matchs';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered de $total correspondências';
  }

  @override
  String get matchesStartSwiping =>
      'Comeca a deslizar para encontrar os teus matchs!';

  @override
  String get matchesTryDifferent => 'Tenta uma pesquisa ou filtro diferente';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Máximo de $count interesses permitidos';
  }

  @override
  String get maybeLater => 'Talvez Mais Tarde';

  @override
  String get discoverWorldwideTitle => 'Expanda os seus horizontes!';

  @override
  String get discoverWorldwideMessage =>
      'Ainda não há muitas pessoas na sua zona, mas o GreenGo conecta-o com pessoas de todo o mundo! Vá aos Filtros e adicione mais países para descobrir pessoas incríveis de todos os cantos do globo.';

  @override
  String get openFilters => 'Abrir Filtros';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return 'Subscrição $tierName ativa até $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Subscrição Ativada!';

  @override
  String get membershipAdvancedFilters => 'Filtros Avançados';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Subscrição Base';

  @override
  String get membershipBestValue =>
      'Melhor valor para compromisso a longo prazo!';

  @override
  String get membershipBoostsMonth => 'Impulsos/mês';

  @override
  String get membershipBuyTitle => 'Comprar Subscrição';

  @override
  String get membershipCouponCodeLabel => 'Código de Cupão *';

  @override
  String get membershipCouponHint => 'ex., GOLD2024';

  @override
  String get membershipCurrent => 'Subscrição Atual';

  @override
  String get membershipDailyLikes => 'Conexões Diárias';

  @override
  String get membershipDailyMessagesLabel =>
      'Mensagens Diárias (vazio = ilimitadas)';

  @override
  String get membershipDailySwipesLabel =>
      'Swipes Diários (vazio = ilimitados)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days dias restantes';
  }

  @override
  String get membershipDurationLabel => 'Duração (dias)';

  @override
  String get membershipEnterCouponHint => 'Introduz o código de cupão';

  @override
  String get couponRedeemTitle => 'Resgatar código de cupom';

  @override
  String get couponApplyButton => 'Aplicar';

  @override
  String get couponAppliedSuccess => 'Cupom aplicado';

  @override
  String get couponNotValid => 'Cupom inválido';

  @override
  String get freeBaseWeekInfo =>
      'Sem cupom? Você ganha 1 semana de Base grátis!';

  @override
  String get couponRedeemSubtitle =>
      'Introduz o teu código para melhorar a tua subscrição ou obter moedas grátis';

  @override
  String get couponRedeemButton => 'Resgatar Cupão';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Resgatado: $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'Este código de cupão não é válido';

  @override
  String get couponErrorExpired => 'Este cupão expirou';

  @override
  String get couponErrorMaxUsesReached =>
      'Este cupão atingiu o limite de utilizações';

  @override
  String get couponErrorEmailMismatch =>
      'Este cupão está restrito a uma conta diferente';

  @override
  String get couponErrorAlreadyRedeemed => 'Já utilizaste este cupão';

  @override
  String get couponErrorDisabled => 'Este cupão já não está ativo';

  @override
  String get couponErrorGeneric =>
      'Não foi possível resgatar o cupão. Tenta novamente.';

  @override
  String get registerCouponLabel => 'Código de cupom (opcional)';

  @override
  String get registerCouponHint => 'Insira um código de cupom';

  @override
  String get welcomeGrantTitle => 'Bem-vindo ao GreenGo!';

  @override
  String get welcomeGrantDismiss => 'Entendido';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Equivalente a $price/mês';
  }

  @override
  String get membershipErrorLoadingData => 'Erro ao carregar dados';

  @override
  String membershipExpires(Object date) {
    return 'Expira: $date';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get subscriptionAutoRenewInfo =>
      'As subscrições renovam-se automaticamente, salvo cancelamento até 24 horas antes do fim do período atual. Faça a gestão ou cancele a qualquer momento nas definições da sua conta na loja.';

  @override
  String get purchasesRestored => 'Compras restauradas.';

  @override
  String get membershipExtendTitle => 'Prolongar a tua subscrição';

  @override
  String get membershipFeatureComparison => 'Comparação de Funcionalidades';

  @override
  String get membershipGeneric => 'Subscrição';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Modo Incógnito';

  @override
  String get membershipLeaveEmptyLifetime => 'Deixar vazio para vitalício';

  @override
  String get membershipLeaveEmptyUnlimited => 'Deixar vazio para ilimitado';

  @override
  String get membershipLowerThanCurrent => 'Inferior ao seu nível atual';

  @override
  String get membershipMaxUsesLabel => 'Utilizações Máximas';

  @override
  String get membershipMonthly => 'Subscrições Mensais';

  @override
  String get membershipNameDescriptionLabel => 'Nome/Descrição';

  @override
  String get membershipActive => 'Ativo';

  @override
  String get membershipNoActive => 'Sem subscrição ativa';

  @override
  String get membershipNotesLabel => 'Notas';

  @override
  String get membershipOneMonth => '1 mês';

  @override
  String get membershipOneYear => '1 ano';

  @override
  String get membershipPanel => 'Painel de Subscrições';

  @override
  String get membershipPermanent => 'Permanente';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 COINS';

  @override
  String get membershipPrioritySupport => 'Suporte Prioritário';

  @override
  String get membershipReadReceipts => 'Confirmação de Leitura';

  @override
  String get membershipRequired => 'Subscrição necessária';

  @override
  String get membershipRequiredDescription =>
      'Precisas de ser membro do GreenGo para realizar esta ação.';

  @override
  String get membershipExtendDescription =>
      'A tua subscrição base está ativa. Compra mais um ano para prolongar a data de expiração.';

  @override
  String get membershipRewinds => 'Rewinds';

  @override
  String membershipSavePercent(Object percent) {
    return 'POUPE $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Ver quem conecta';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Compre uma vez, desfrute de funcionalidades premium por 1 mês ou 1 ano';

  @override
  String get membershipSuperLikes => 'Conexões Prioritárias';

  @override
  String get membershipSuperLikesLabel =>
      'Conexões Prioritárias/Dia (vazio = ilimitados)';

  @override
  String get membershipTerms =>
      'Compra única. A subscrição será prolongada a partir da sua data de término atual.';

  @override
  String get membershipTermsExtended =>
      'Compra única. A subscrição será prolongada a partir da sua data de término atual. Compras de nível superior substituem níveis inferiores.';

  @override
  String get membershipTierLabel => 'Nível de Subscrição *';

  @override
  String membershipTierName(Object tierName) {
    return 'Subscrição $tierName';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Subscrições Anuais (Poupe até $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Tem $tierName';
  }

  @override
  String get messages => 'Trocas';

  @override
  String get minutes => 'Minutos';

  @override
  String moreAchievements(int count) {
    return '+$count mais conquistas';
  }

  @override
  String get myBadges => 'Os Meus Emblemas';

  @override
  String get myProgress => 'O Meu Progresso';

  @override
  String get myUsage => 'O Meu Uso';

  @override
  String get navLearn => 'Aprender';

  @override
  String get navPlay => 'Jogar';

  @override
  String get nearby => 'Perto';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Precisas de $amount moedas para desbloquear mais perfis.';
  }

  @override
  String get newLabel => 'NOVO';

  @override
  String get next => 'Seguinte';

  @override
  String nextLevelXp(String xp) {
    return 'Próximo nível em $xp XP';
  }

  @override
  String get nickname => 'Alcunha';

  @override
  String get nicknameAlreadyTaken => 'Esta alcunha já está em uso';

  @override
  String get nicknameCheckError => 'Erro ao verificar disponibilidade';

  @override
  String nicknameInfoText(String nickname) {
    return 'A tua alcunha é única e pode ser usada para te encontrar. Outros podem procurar-te usando @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Deve ter 3-20 caracteres';

  @override
  String get nicknameNoConsecutiveUnderscores => 'Sem underscores consecutivos';

  @override
  String get nicknameNoReservedWords => 'Não pode conter palavras reservadas';

  @override
  String get nicknameOnlyAlphanumeric => 'Apenas letras, números e underscores';

  @override
  String get nicknameRequirements =>
      '3-20 caracteres. Apenas letras, números e underscores.';

  @override
  String get nicknameRules => 'Regras da Alcunha';

  @override
  String get nicknameSearchChat => 'Conversar';

  @override
  String get nicknameSearchError => 'Erro na pesquisa. Tenta novamente.';

  @override
  String get nicknameSearchHelp => 'Insere um nickname para encontrar alguem';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'Nenhum perfil encontrado com @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'Esse e o teu proprio perfil!';

  @override
  String get nicknameSearchTitle => 'Pesquisar por Nickname';

  @override
  String get nicknameSearchView => 'Ver';

  @override
  String nicknameSearchActionNope(String nickname) {
    return 'Acabaste de selecionar \"Não\" para @$nickname';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'Acabaste de selecionar \"Saltar\" para @$nickname';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'Acabaste de selecionar \"Conexão Prioritária\" para @$nickname';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'Acabaste de selecionar \"Vamos Conectar\" para @$nickname';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'É um match com @$nickname!';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'Atingiste o teu limite de $action. Tenta novamente mais tarde.';
  }

  @override
  String get nicknameStartWithLetter => 'Começar com uma letra';

  @override
  String get nicknameUpdatedMessage => 'A tua nova alcunha já está ativa';

  @override
  String get nicknameUpdatedSuccess => 'Alcunha atualizada com sucesso';

  @override
  String get nicknameUpdatedTitle => 'Alcunha Atualizada!';

  @override
  String get no => 'Não';

  @override
  String get noActiveGamesLabel => 'Nenhum jogo ativo';

  @override
  String get noBadgesEarnedYet => 'Nenhum emblema obtido';

  @override
  String get noInternetConnection => 'Sem ligação à internet';

  @override
  String get noLanguagesYet => 'Ainda sem línguas. Comece a aprender!';

  @override
  String get noLeaderboardData => 'Ainda sem dados de classificação';

  @override
  String get noMatchesFound => 'Nenhuma correspondência encontrada';

  @override
  String get noMatchesYet => 'Ainda sem correspondências';

  @override
  String get noMessages => 'Ainda sem mensagens';

  @override
  String get noMoreProfiles => 'Não há mais perfis para mostrar';

  @override
  String get noOthersToSee => 'Não há mais pessoas para ver';

  @override
  String get noPendingVerifications => 'Sem verificações pendentes';

  @override
  String get noPhotoSubmitted => 'Nenhuma foto enviada';

  @override
  String get noPreviousProfile => 'Nenhum perfil anterior para voltar';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Nenhum perfil encontrado com @$nickname';
  }

  @override
  String get noResults => 'Sem resultados';

  @override
  String get noSocialProfilesLinked => 'Nenhum perfil social ligado';

  @override
  String get noVoiceRecording => 'Sem gravação de voz';

  @override
  String get nodeAvailable => 'Disponível';

  @override
  String get nodeCompleted => 'Concluído';

  @override
  String get nodeInProgress => 'Em Progresso';

  @override
  String get nodeLocked => 'Bloqueado';

  @override
  String get notEnoughCoins => 'Moedas insuficientes';

  @override
  String get notNow => 'Agora Não';

  @override
  String get notSet => 'Não definido';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Conquista Desbloqueada: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Compraste com sucesso $amount moedas.';
  }

  @override
  String get notificationDialogEnable => 'Ativar';

  @override
  String get notificationDialogMessage =>
      'Ativa as notificações para saberes quando recebes matches, mensagens e conexões prioritárias.';

  @override
  String get notificationDialogNotNow => 'Agora não';

  @override
  String get notificationDialogTitle => 'Mantém-te ligado';

  @override
  String get notificationEmailSubtitle => 'Receber notificações por email';

  @override
  String get notificationEmailTitle => 'Notificações por Email';

  @override
  String get notificationEnableQuietHours => 'Ativar Horas de Silêncio';

  @override
  String get notificationEndTime => 'Hora de Fim';

  @override
  String get notificationMasterControls => 'Controlos Principais';

  @override
  String get notificationMatchExpiring => 'Compatibilidade a Expirar';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Quando uma compatibilidade está prestes a expirar';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname iniciou uma conversa contigo.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Recebeste um gosto de @$nickname';
  }

  @override
  String get notificationNewLikes => 'Novos Likes';

  @override
  String get notificationNewLikesSubtitle => 'Quando alguém gosta de si';

  @override
  String notificationNewMatch(String nickname) {
    return 'É um Match! Fizeste match com @$nickname. Começa a conversar agora.';
  }

  @override
  String get notificationNewMatches => 'Novas Compatibilidades';

  @override
  String get notificationNewMatchesSubtitle =>
      'Quando obtém uma nova compatibilidade';

  @override
  String notificationNewMessage(String nickname) {
    return 'Nova mensagem de @$nickname';
  }

  @override
  String get notificationNewMessages => 'Novas Mensagens';

  @override
  String get notificationNewMessagesSubtitle =>
      'Quando alguém lhe envia uma mensagem';

  @override
  String get notificationProfileViews => 'Visualizações do Perfil';

  @override
  String get notificationProfileViewsSubtitle =>
      'Quando alguém vê o seu perfil';

  @override
  String get notificationPromotional => 'Promocional';

  @override
  String get notificationPromotionalSubtitle => 'Dicas, ofertas e promoções';

  @override
  String get notificationPushSubtitle =>
      'Receber notificações neste dispositivo';

  @override
  String get notificationPushTitle => 'Notificações Push';

  @override
  String get notificationQuietHours => 'Horas de Silêncio';

  @override
  String get notificationQuietHoursDescription =>
      'Silenciar notificações entre horários definidos';

  @override
  String get notificationQuietHoursSubtitle =>
      'Silenciar notificações durante determinadas horas';

  @override
  String get notificationSettings => 'Definições de Notificações';

  @override
  String get notificationSettingsTitle => 'Definições de Notificações';

  @override
  String get notificationSound => 'Som';

  @override
  String get notificationSoundSubtitle => 'Reproduzir som para notificações';

  @override
  String get notificationSoundVibration => 'Som e Vibração';

  @override
  String get notificationStartTime => 'Hora de Início';

  @override
  String notificationSuperLike(String nickname) {
    return 'Recebeste uma conexão prioritária de @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Conexões Prioritárias';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quando alguém conecta prioritariamente consigo';

  @override
  String get notificationTypes => 'Tipos de Notificação';

  @override
  String get notificationVibration => 'Vibração';

  @override
  String get notificationVibrationSubtitle => 'Vibrar para notificações';

  @override
  String get notificationsEmpty => 'Sem notificações ainda';

  @override
  String get notificationsEmptySubtitle =>
      'Quando receber notificações, aparecerão aqui';

  @override
  String get notificationsMarkAllRead => 'Marcar tudo como lido';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get occupation => 'Profissão';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Adicionar Foto';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Adicione fotos que representem o verdadeiro você';

  @override
  String get onboardingAiVerifiedDescription =>
      'As suas fotos são verificadas usando IA para garantir autenticidade';

  @override
  String get onboardingAiVerifiedPhotos => 'Fotos Verificadas por IA';

  @override
  String get onboardingBioHint =>
      'Fale-nos dos seus interesses, passatempos, o que procura...';

  @override
  String get onboardingBioMinLength =>
      'A bio deve ter pelo menos 50 caracteres';

  @override
  String get onboardingChooseFromGallery => 'Escolher da Galeria';

  @override
  String get onboardingCompleteAllFields =>
      'Por favor, preencha todos os campos';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingDateOfBirth => 'Data de Nascimento';

  @override
  String get onboardingDisplayName => 'Nome de Apresentação';

  @override
  String get onboardingDisplayNameHint => 'Como devemos chamá-lo?';

  @override
  String get onboardingEnterYourName => 'Por favor, introduza o seu nome';

  @override
  String get onboardingExpressYourself => 'Expresse-se';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Escreva algo que capture quem é';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Falha ao tirar foto: $error';
  }

  @override
  String get onboardingGenderFemale => 'Feminino';

  @override
  String get onboardingGenderMale => 'Masculino';

  @override
  String get onboardingGenderNonBinary => 'Não-binário';

  @override
  String get onboardingGenderOther => 'Outro';

  @override
  String get onboardingHoldIdNextToFace =>
      'Segure o seu documento junto ao rosto';

  @override
  String get onboardingIdentifyAs => 'Identifico-me como';

  @override
  String get onboardingInterestsHelpMatches =>
      'Os seus interesses ajudam-nos a encontrar melhores compatibilidades para si';

  @override
  String get onboardingInterestsSubtitle =>
      'Selecione pelo menos 3 interesses (máx. 10)';

  @override
  String get onboardingLanguages => 'Idiomas';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 selecionados';
  }

  @override
  String get onboardingLetsGetStarted => 'Vamos começar';

  @override
  String get onboardingLocation => 'Localização';

  @override
  String get onboardingLocationLater =>
      'Pode definir a sua localização mais tarde nas definições';

  @override
  String get onboardingMainPhoto => 'PRINCIPAL';

  @override
  String get onboardingMaxInterests => 'Pode selecionar até 10 interesses';

  @override
  String get onboardingMaxLanguages => 'Pode selecionar até 3 idiomas';

  @override
  String get onboardingMinInterests =>
      'Por favor, selecione pelo menos 3 interesses';

  @override
  String get onboardingMinLanguage =>
      'Por favor, selecione pelo menos um idioma';

  @override
  String get onboardingMinLocation => 'Define a tua localização para continuar';

  @override
  String get onboardingNameMinLength =>
      'O nome deve ter pelo menos 2 caracteres';

  @override
  String get onboardingNoLocationSelected => 'Nenhuma localização selecionada';

  @override
  String get onboardingOptional => 'Opcional';

  @override
  String get onboardingSelectFromPhotos => 'Selecionar das suas fotos';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 selecionados';
  }

  @override
  String get onboardingShowYourself => 'Mostre-se';

  @override
  String get onboardingTakePhoto => 'Tirar Foto';

  @override
  String get onboardingTellUsAboutYourself => 'Fale-nos um pouco sobre si';

  @override
  String get onboardingTipAuthentic => 'Seja autêntico e genuíno';

  @override
  String get onboardingTipPassions => 'Partilhe as suas paixões e passatempos';

  @override
  String get onboardingTipPositive => 'Mantenha-se positivo';

  @override
  String get onboardingTipUnique => 'O que o torna único?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Por favor, carregue pelo menos uma foto';

  @override
  String get onboardingUseCurrentLocation => 'Usar Localização Atual';

  @override
  String get onboardingUseYourCamera => 'Usar a sua câmara';

  @override
  String get onboardingWhereAreYou => 'Onde está?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Defina os seus idiomas e localização preferidos (opcional)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Por favor, escreva algo sobre si';

  @override
  String get onboardingWritingTips => 'Dicas de escrita';

  @override
  String get onboardingYourInterests => 'Os seus interesses';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Esta transferência única tem aproximadamente ${size}MB.';
  }

  @override
  String get optionalConsents => 'Consentimentos Opcionais';

  @override
  String get orContinueWith => 'Ou continue com';

  @override
  String get origin => 'Origem';

  @override
  String packFocusMode(String packName) {
    return 'Pacote: $packName';
  }

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordMustContain => 'A palavra-passe deve conter:';

  @override
  String get passwordMustContainLowercase =>
      'A palavra-passe deve conter pelo menos uma letra minúscula';

  @override
  String get passwordMustContainNumber =>
      'A palavra-passe deve conter pelo menos um número';

  @override
  String get passwordMustContainSpecialChar =>
      'A palavra-passe deve conter pelo menos um carácter especial';

  @override
  String get passwordMustContainUppercase =>
      'A palavra-passe deve conter pelo menos uma letra maiúscula';

  @override
  String get passwordRequired => 'Palavra-passe é obrigatória';

  @override
  String get passwordStrengthFair => 'Razoável';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordStrengthVeryStrong => 'Muito Forte';

  @override
  String get passwordStrengthVeryWeak => 'Muito Fraca';

  @override
  String get passwordStrengthWeak => 'Fraca';

  @override
  String get passwordTooShort =>
      'A palavra-passe deve ter pelo menos 8 caracteres';

  @override
  String get passwordWeak =>
      'A palavra-passe deve conter maiúsculas, minúsculas, números e caracteres especiais';

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não coincidem';

  @override
  String get pendingVerifications => 'Verificações Pendentes';

  @override
  String get perMonth => '/mês';

  @override
  String get periodAllTime => 'Todo o Tempo';

  @override
  String get periodMonthly => 'Este Mês';

  @override
  String get periodWeekly => 'Esta Semana';

  @override
  String get personalStatistics => 'Estatísticas pessoais';

  @override
  String get personalStatisticsSubtitle =>
      'Gráficos, objetivos e progresso linguístico';

  @override
  String get personalStatsActivity => 'Atividade recente';

  @override
  String get personalStatsChatStats => 'Estatísticas do chat';

  @override
  String get personalStatsConversations => 'Conversas';

  @override
  String get personalStatsGoalsAchieved => 'Objetivos alcançados';

  @override
  String get personalStatsLevel => 'Nível';

  @override
  String get personalStatsLanguage => 'Idioma';

  @override
  String get personalStatsTotal => 'Total';

  @override
  String get personalStatsNextLevel => 'Próximo nível';

  @override
  String get personalStatsNoActivityYet => 'Nenhuma atividade registada';

  @override
  String get personalStatsNoWordsYet =>
      'Comece a conversar para descobrir novas palavras';

  @override
  String get personalStatsTotalMessages => 'Mensagens enviadas';

  @override
  String get personalStatsWordsDiscovered => 'Palavras descobertas';

  @override
  String get personalStatsWordsLearned => 'Palavras Aprendidas';

  @override
  String get personalStatsXpOverview => 'Resumo de XP';

  @override
  String get photoAddPhoto => 'Adicionar Foto';

  @override
  String get photoAddPrivateDescription =>
      'Adicione fotos privadas que pode partilhar na conversa';

  @override
  String get photoAddPublicDescription =>
      'Adicione fotos para completar o seu perfil';

  @override
  String get photoAlreadyExistsInAlbum =>
      'A foto já existe no álbum de destino';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get photoDeleteConfirm =>
      'Tens a certeza de que queres eliminar esta foto?';

  @override
  String get photoDeleteMainWarning =>
      'Esta é a tua foto principal. A próxima foto passará a ser a tua foto principal (deve mostrar o teu rosto). Continuar?';

  @override
  String get photoExplicitContent =>
      'Esta foto pode conter conteúdo inapropriado. As fotos na app não devem mostrar nudez, roupa interior ou conteúdo explícito.';

  @override
  String get photoExplicitNudity =>
      'Esta foto parece conter nudez ou conteúdo explícito. Todas as fotos na app devem ser apropriadas e com roupa adequada.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String get photoLongPressReorder => 'Pressão longa e arraste para reordenar';

  @override
  String get photoMainNoFace =>
      'A tua foto principal deve mostrar o teu rosto claramente. Não foi detetado nenhum rosto nesta foto.';

  @override
  String get photoMainNotForward =>
      'Por favor, usa uma foto em que o teu rosto esteja claramente visível e virado para a frente.';

  @override
  String get photoManagePhotos => 'Gerir Fotos';

  @override
  String get photoMaxPrivate => 'Máximo de 6 fotos privadas permitidas';

  @override
  String get photoMaxPublic => 'Máximo de 6 fotos públicas permitidas';

  @override
  String get photoMustHaveOne =>
      'Deves ter pelo menos uma foto pública com o teu rosto visível.';

  @override
  String get photoNoPhotos => 'Sem fotos ainda';

  @override
  String get photoNoPrivatePhotos => 'Sem fotos privadas ainda';

  @override
  String get photoNotAccepted => 'Foto não aceite';

  @override
  String get photoNotAllowedPublic =>
      'Esta foto não é permitida em nenhum lugar da app.';

  @override
  String get photoPrimary => 'PRINCIPAL';

  @override
  String get photoPrivateShareInfo =>
      'As fotos privadas podem ser partilhadas na conversa';

  @override
  String get photoTooLarge =>
      'A foto é demasiado grande. O tamanho máximo é 10 MB.';

  @override
  String get photoTooMuchSkin =>
      'Esta foto mostra demasiada pele exposta. Por favor, usa uma foto em que estejas vestido/a de forma apropriada.';

  @override
  String get photoUploadedMessage => 'A tua foto foi adicionada ao perfil';

  @override
  String get photoUploadedTitle => 'Foto Carregada!';

  @override
  String get photoValidating => 'A validar foto...';

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
  String get photosUpdatedMessage => 'A tua galeria de fotos foi guardada';

  @override
  String get photosUpdatedTitle => 'Fotos Atualizadas!';

  @override
  String phrasesCount(String count) {
    return '$count frases';
  }

  @override
  String get phrasesLabel => 'frases';

  @override
  String get platinum => 'Platina';

  @override
  String get playAgain => 'Jogar Novamente';

  @override
  String playersRange(String min, String max) {
    return '$min-$max jogadores';
  }

  @override
  String get playing => 'A reproduzir...';

  @override
  String playingCountLabel(String count) {
    return '$count jogando';
  }

  @override
  String get plusTaxes => '+ impostos';

  @override
  String get preferenceAddCountry => 'Adicionar Pais';

  @override
  String get preferenceLanguageFilter => 'Idioma';

  @override
  String get preferenceLanguageFilterDesc =>
      'Mostrar apenas pessoas que falam um idioma específico';

  @override
  String get preferenceAnyLanguage => 'Qualquer idioma';

  @override
  String get preferenceInterestFilter => 'Interesses';

  @override
  String get preferenceInterestFilterDesc =>
      'Mostrar apenas pessoas que partilham os seus interesses';

  @override
  String get preferenceNoInterestFilter =>
      'Sem filtro de interesses — a mostrar todos';

  @override
  String get preferenceAddInterest => 'Adicionar interesse';

  @override
  String get preferenceSearchInterest => 'Pesquisar interesses...';

  @override
  String get preferenceNoInterestsFound => 'Nenhum interesse encontrado';

  @override
  String get preferenceAddDealBreaker => 'Adicionar Criterio Eliminatorio';

  @override
  String get preferenceAdvancedFilters => 'Filtros Avancados';

  @override
  String get preferenceAgeRange => 'Faixa Etaria';

  @override
  String get preferenceAllCountries => 'Todos os Paises';

  @override
  String get preferenceAllVerified => 'Todos os perfis devem ser verificados';

  @override
  String get preferenceCountry => 'Pais';

  @override
  String get preferenceCountryDescription =>
      'Mostrar apenas pessoas de paises especificos (deixar vazio para todos)';

  @override
  String get preferenceDealBreakers => 'Criterios Eliminatorios';

  @override
  String get preferenceDealBreakersDesc =>
      'Nunca me mostres perfis com estas caracteristicas';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Todos';

  @override
  String get preferenceMaxDistance => 'Distancia Maxima';

  @override
  String get preferenceMen => 'Homens';

  @override
  String get preferenceMostPopular => 'Mais Popular';

  @override
  String get preferenceNoCountriesFound => 'Nenhum pais encontrado';

  @override
  String get preferenceNoCountryFilter =>
      'Sem filtro de pais - a mostrar mundialmente';

  @override
  String get preferenceCountryRequired =>
      'Pelo menos um país deve ser selecionado';

  @override
  String get preferenceByUsers => 'Por utilizadores';

  @override
  String get preferenceNoDealBreakers =>
      'Nenhum criterio eliminatorio definido';

  @override
  String get preferenceNoDistanceLimit => 'Sem limite de distancia';

  @override
  String get preferenceOnlineNow => 'Online Agora';

  @override
  String get preferenceOnlineNowDesc =>
      'Mostrar apenas perfis atualmente online';

  @override
  String get preferenceOnlyVerified => 'Mostrar apenas perfis verificados';

  @override
  String get preferenceOrientationDescription =>
      'Filtrar por orientacao (deixar tudo desmarcado para mostrar todos)';

  @override
  String get preferenceRecentlyActive => 'Ativos Recentemente';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Mostrar apenas perfis ativos nos ultimos 7 dias';

  @override
  String get preferenceSave => 'Guardar';

  @override
  String get preferenceSelectCountry => 'Selecionar Pais';

  @override
  String get preferenceSexualOrientation => 'Orientacao Sexual';

  @override
  String get preferenceShowMe => 'Mostrar-me';

  @override
  String get preferenceUnlimited => 'Ilimitado';

  @override
  String preferenceUsersCount(int count) {
    return '$count utilizadores';
  }

  @override
  String get preferenceWithin => 'Dentro de';

  @override
  String get preferenceWomen => 'Mulheres';

  @override
  String get preferencesSavedMessage =>
      'As tuas preferências de descoberta foram atualizadas';

  @override
  String get preferencesSavedTitle => 'Preferências Guardadas!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Origem Principal';

  @override
  String get priorityConnectNotificationMessage =>
      'Alguém quer se conectar com você!';

  @override
  String get priorityConnectNotificationTitle => 'Priority Connect!';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get privacySettings => 'Definições de Privacidade';

  @override
  String get privateAlbum => 'Privado';

  @override
  String get privateRoom => 'Sala Privada';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Perfil';

  @override
  String get profileAboutMe => 'Sobre Mim';

  @override
  String get profileAccountDeletedSuccess => 'Conta eliminada com sucesso.';

  @override
  String get profileActivate => 'Ativar';

  @override
  String get profileActivateIncognito => 'Ativar Incógnito?';

  @override
  String get profileActivateTravelerMode => 'Ativar Modo Viajante?';

  @override
  String get profileActivatingBoost => 'A ativar impulso...';

  @override
  String get profileActiveLabel => 'ATIVO';

  @override
  String get profileAdditionalDetails => 'Detalhes Adicionais';

  @override
  String profileAgeCannotChange(int age) {
    return 'Idade $age - Nao pode ser alterada (verificacao)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Perfil já impulsionado! ${minutes}m restantes';
  }

  @override
  String get profileAuthenticationFailed => 'Autenticação falhou';

  @override
  String profileBioMinLength(int min) {
    return 'A bio deve ter pelo menos $min caracteres';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Custo: $cost moedas';
  }

  @override
  String get profileBoostDescription =>
      'O seu perfil aparecerá no topo da descoberta por 30 minutos!';

  @override
  String get profileBoostNow => 'Impulsionar Agora';

  @override
  String get profileBoostProfile => 'Impulsionar Perfil';

  @override
  String get profileBoostSubtitle => 'Seja visto primeiro por 30 minutos';

  @override
  String get profileBoosted => 'Perfil Impulsionado!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Perfil impulsionado por $minutes minutos!';
  }

  @override
  String get profileBuyCoins => 'Comprar Moedas';

  @override
  String get profileCoinShop => 'Loja de Moedas';

  @override
  String get profileCoinShopSubtitle => 'Comprar moedas e subscrição premium';

  @override
  String get profileConfirmYourPassword => 'Confirme a Sua Palavra-passe';

  @override
  String get profileContinue => 'Continuar';

  @override
  String get profileDataExportSent =>
      'Exportação de dados enviada para o seu email';

  @override
  String get profileDateOfBirth => 'Data de Nascimento';

  @override
  String get profileDeleteAccountWarning =>
      'Esta ação é permanente e não pode ser revertida. Todos os seus dados, compatibilidades e mensagens serão eliminados. Por favor, introduza a sua palavra-passe para confirmar.';

  @override
  String get profileDiscoveryRestarted =>
      'Descoberta reiniciada! Agora pode ver todos os perfis novamente.';

  @override
  String get profileDisplayName => 'Nome de Exibicao';

  @override
  String get profileDobInfo =>
      'A tua data de nascimento nao pode ser alterada para verificacao de idade. A tua idade exata e visivel para os matchs.';

  @override
  String get profileEditBasicInfo => 'Editar Info Basica';

  @override
  String get profileEditLocation => 'Editar Localizacao e Idiomas';

  @override
  String get profileEditNickname => 'Editar Nickname';

  @override
  String get profileEducation => 'Educacao';

  @override
  String get profileEducationHint => 'ex. Licenciatura em Informatica';

  @override
  String get profileEnterNameHint => 'Introduz o teu nome';

  @override
  String get profileEnterNicknameHint => 'Introduz a alcunha';

  @override
  String get profileEnterNicknameWith => 'Insere um nickname que comece com @';

  @override
  String get profileExportingData => 'A exportar os seus dados...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Falha ao reiniciar descoberta: $error';
  }

  @override
  String get profileFindUsers => 'Encontrar Utilizadores';

  @override
  String get profileGender => 'Genero';

  @override
  String get profileGetCoins => 'Obter Moedas';

  @override
  String get profileGetMembership => 'Obter Subscrição GreenGo';

  @override
  String get profileGettingLocation => 'A obter localizacao...';

  @override
  String get profileGreengoMembership => 'Subscrição GreenGo';

  @override
  String get profileHeightCm => 'Altura (cm)';

  @override
  String get profileIncognitoActivated =>
      'Modo incógnito ativado por 24 horas!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'O modo incógnito custa $cost moedas por dia.';
  }

  @override
  String get profileIncognitoDeactivated => 'Modo incógnito desativado.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'O modo incógnito oculta o seu perfil da descoberta por 24 horas.';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Grátis com Platinum - Oculto da descoberta';

  @override
  String get profileIncognitoMode => 'Modo Incógnito';

  @override
  String get profileInsufficientCoins => 'Moedas Insuficientes';

  @override
  String profileInterestsCount(Object count) {
    return '$count interesses';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Conta-nos sobre os teus interesses, passatempos, o que procuras...';

  @override
  String get profileLanguagesSectionTitle => 'Idiomas';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 idiomas selecionados';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count perfil(s) associado(s)';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Nao foi possivel obter a localizacao: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Localizacao';

  @override
  String get profileLookingFor => 'Procuro';

  @override
  String get profileLookingForHint => 'ex. Relacao a longo prazo';

  @override
  String get profileMaxLanguagesAllowed => 'Maximo 3 idiomas permitidos';

  @override
  String get profileMembershipActive => 'Ativo';

  @override
  String get profileMembershipExpired => 'Expirado';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Válido até $date';
  }

  @override
  String get profileMyUsage => 'A Minha Utilização';

  @override
  String get profileMyUsageSubtitle =>
      'Ver a sua utilização diária e limites de nível';

  @override
  String get profileNicknameAlreadyTaken => 'Este nickname ja esta em uso';

  @override
  String get profileNicknameCharRules =>
      '3-20 caracteres. Apenas letras, numeros e underscores.';

  @override
  String get profileNicknameCheckError => 'Erro ao verificar disponibilidade';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'O teu nickname e unico e pode ser usado para te encontrar. Outros podem procurar-te com @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'O teu nickname e unico e pode ser usado para te encontrar. Define um para que outros te descubram.';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNicknameRefresh => 'Atualizar';

  @override
  String get profileNicknameRule1 => 'Deve ter 3-20 caracteres';

  @override
  String get profileNicknameRule2 => 'Comecar com uma letra';

  @override
  String get profileNicknameRule3 => 'Apenas letras, numeros e underscores';

  @override
  String get profileNicknameRule4 => 'Sem underscores consecutivos';

  @override
  String get profileNicknameRule5 => 'Nao pode conter palavras reservadas';

  @override
  String get profileNicknameRules => 'Regras do Nickname';

  @override
  String get profileNicknameSuggestions => 'Sugestoes';

  @override
  String profileNoUsersFound(String query) {
    return 'Nenhum utilizador encontrado para \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Moedas insuficientes! Necessita de $required, tem $available';
  }

  @override
  String get profileOccupation => 'Profissao';

  @override
  String get profileOccupationHint => 'ex. Engenheiro de Software';

  @override
  String get profileOptionalDetails => 'Opcional - ajuda outros a conhecer-te';

  @override
  String get profileOrientationPrivate =>
      'Isto e privado e nao e mostrado no teu perfil';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get profilePremiumFeatures => 'Funcionalidades Premium';

  @override
  String get profileProgressGrowth => 'Progresso e crescimento';

  @override
  String get profileRestart => 'Reiniciar';

  @override
  String get profileRestartDiscovery => 'Reiniciar Descoberta';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Isto irá apagar todos os seus swipes (conexões, rejeições, conexões prioritárias) para que possa redescobrir todos do início.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Reiniciar Descoberta';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Repor todos os swipes e começar de novo';

  @override
  String get profileSearchByNickname => 'Pesquisar por @nickname';

  @override
  String get profileSearchByNicknameHint => 'Pesquisar por @alcunha';

  @override
  String get profileSearchCityHint => 'Pesquisar cidade, morada ou local...';

  @override
  String get profileSearchForUsers => 'Pesquisar utilizadores por nickname';

  @override
  String get profileSearchLanguagesHint => 'Pesquisar idiomas...';

  @override
  String get profileSetLocationAndLanguage =>
      'Define a localizacao e seleciona pelo menos um idioma';

  @override
  String get profileSexualOrientation => 'Orientacao Sexual';

  @override
  String get profileStop => 'Parar';

  @override
  String get profileTellAboutYourselfHint => 'Conta às pessoas sobre ti...';

  @override
  String get profileTipAuthentic => 'Se autentico e genuino';

  @override
  String get profileTipHobbies => 'Menciona os teus hobbies e paixoes';

  @override
  String get profileTipHumor => 'Adiciona um toque de humor';

  @override
  String get profileTipPositive => 'Mantem-te positivo';

  @override
  String get profileTipsForGreatBio => 'Dicas para uma otima bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Modo viajante ativado! A aparecer em $city por 24 horas.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'O modo viajante custa $cost moedas por dia.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Modo viajante desativado. De volta à sua localização real.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'O modo viajante permite-lhe aparecer no feed de descoberta de outra cidade por 24 horas.';
  }

  @override
  String get profileTravelerMode => 'Modo Viajante';

  @override
  String get profileTryDifferentNickname => 'Tenta um nickname diferente';

  @override
  String get profileUnableToVerifyAccount =>
      'Não foi possível verificar a conta';

  @override
  String get profileUpdateCurrentLocation => 'Atualizar Localizacao Atual';

  @override
  String get profileUpdatedMessage => 'As tuas alterações foram guardadas';

  @override
  String get profileUpdatedSuccess => 'Perfil atualizado com sucesso';

  @override
  String get profileUpdatedTitle => 'Perfil Atualizado!';

  @override
  String get profileWeightKg => 'Peso (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count perfil$_temp0 ligado$_temp1';
  }

  @override
  String get profilingDescription =>
      'Permitir a análise das suas preferências para fornecer melhores sugestões de correspondência';

  @override
  String get progress => 'Progresso';

  @override
  String get progressAchievements => 'Emblemas';

  @override
  String get progressBadges => 'Emblemas';

  @override
  String get progressChallenges => 'Desafios';

  @override
  String get progressComparison => 'Comparacao de Progresso';

  @override
  String get progressCompleted => 'Concluídos';

  @override
  String get progressJourneyDescription =>
      'Vê o teu percurso completo de encontros e conquistas';

  @override
  String get progressLabel => 'Progresso';

  @override
  String get progressLeaderboard => 'Classificação';

  @override
  String progressLevel(int level) {
    return 'Nível $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Visão Geral';

  @override
  String get progressRecentAchievements => 'Conquistas Recentes';

  @override
  String get progressSeeAll => 'Ver Tudo';

  @override
  String get progressTitle => 'Progresso';

  @override
  String get progressTodaysChallenges => 'Desafios de Hoje';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressViewJourney => 'Ver o Teu Percurso';

  @override
  String get publicAlbum => 'Público';

  @override
  String get purchaseSuccessfulTitle => 'Compra Efetuada!';

  @override
  String get purchasedLabel => 'Comprado';

  @override
  String get quickPlay => 'Jogo Rápido';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Ler Política de Privacidade';

  @override
  String get readTermsAndConditions => 'Ler Termos e Condições';

  @override
  String get readyButton => 'Pronto';

  @override
  String get recipientNickname => 'Apelido do destinatário';

  @override
  String get recordVoice => 'Gravar Voz';

  @override
  String get refresh => 'Atualizar';

  @override
  String get register => 'Registar';

  @override
  String get rejectVerification => 'Rejeitar';

  @override
  String rejectionReason(String reason) {
    return 'Razão: $reason';
  }

  @override
  String get rejectionReasonRequired =>
      'Por favor introduza um motivo para a rejeição';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $limitType restantes hoje';
  }

  @override
  String get reportSubmittedMessage =>
      'Obrigado por ajudares a manter a nossa comunidade segura';

  @override
  String get reportSubmittedTitle => 'Denúncia Enviada!';

  @override
  String get reportWord => 'Reportar Palavra';

  @override
  String get reportsPanel => 'Painel de Denúncias';

  @override
  String get requestBetterPhoto => 'Solicitar Foto Melhor';

  @override
  String requiresTier(String tier) {
    return 'Requer $tier';
  }

  @override
  String get resetPassword => 'Redefinir Palavra-passe';

  @override
  String get resetToDefault => 'Repor Predefinições';

  @override
  String get restartAppWizard => 'Reiniciar Assistente da App';

  @override
  String get restartWizard => 'Reiniciar Assistente';

  @override
  String get restartWizardDialogContent =>
      'Isto irá reiniciar o assistente de configuração. Poderás atualizar as informações do teu perfil passo a passo. Os teus dados atuais serão preservados.';

  @override
  String get retakePhoto => 'Tirar Novamente';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get reuploadVerification => 'Reenviar foto de verificação';

  @override
  String get reverificationCameraError => 'Não foi possível abrir a câmara';

  @override
  String get reverificationDescription =>
      'Tira uma selfie clara para verificarmos a tua identidade. Certifica-te de que tens boa iluminação e que o teu rosto está bem visível.';

  @override
  String get reverificationHeading => 'Precisamos verificar a tua identidade';

  @override
  String get reverificationInfoText =>
      'Após o envio, o teu perfil ficará em revisão. Terás acesso após a aprovação.';

  @override
  String get reverificationPhotoTips => 'Dicas para a foto';

  @override
  String get reverificationReasonLabel => 'Motivo do pedido:';

  @override
  String get reverificationRetakePhoto => 'Repetir foto';

  @override
  String get reverificationSubmit => 'Enviar para revisão';

  @override
  String get reverificationTapToSelfie => 'Toca para tirar uma selfie';

  @override
  String get reverificationTipCamera => 'Olha diretamente para a câmara';

  @override
  String get reverificationTipFullFace =>
      'Certifica-te de que o teu rosto está totalmente visível';

  @override
  String get reverificationTipLighting =>
      'Boa iluminação — vira-te para a fonte de luz';

  @override
  String get reverificationTipNoAccessories =>
      'Sem óculos de sol, chapéus ou máscaras';

  @override
  String get reverificationTitle => 'Verificação de identidade';

  @override
  String get reverificationUploadFailed => 'Falha no envio. Tenta novamente.';

  @override
  String get reviewReportedMessages =>
      'Rever mensagens denunciadas e gerir contas';

  @override
  String get reviewUserVerifications => 'Rever verificações de utilizadores';

  @override
  String reviewedBy(String admin) {
    return 'Revisto por $admin';
  }

  @override
  String get revokeAccess => 'Revogar acesso ao álbum';

  @override
  String get rewardsAndProgress => 'Recompensas e Progresso';

  @override
  String get romanticCategory => 'Romântico';

  @override
  String get roundTimer => 'Temporizador de Ronda';

  @override
  String roundXofY(String current, String total) {
    return 'Ronda $current/$total';
  }

  @override
  String get rounds => 'Rondas';

  @override
  String get safetyAdd => 'Adicionar';

  @override
  String get safetyAddAtLeastOneContact =>
      'Por favor, adicione pelo menos um contacto de emergência';

  @override
  String get safetyAddEmergencyContact => 'Adicionar Contacto de Emergência';

  @override
  String get safetyAddEmergencyContacts => 'Adicionar contactos de emergência';

  @override
  String get safetyAdditionalDetailsHint => 'Detalhes adicionais...';

  @override
  String get safetyCheckInDescription =>
      'Configure um check-in para o seu encontro. Vamos lembrá-lo de fazer check-in e alertar os seus contactos se não responder.';

  @override
  String get safetyCheckInEvery => 'Check-in a cada';

  @override
  String get safetyCheckInScheduled => 'Check-in de encontro agendado!';

  @override
  String get safetyDateCheckIn => 'Check-In de Encontro';

  @override
  String get safetyDateTime => 'Data e Hora';

  @override
  String get safetyEmergencyContacts => 'Contactos de Emergência';

  @override
  String get safetyEmergencyContactsHelp =>
      'Serão notificados se precisar de ajuda';

  @override
  String get safetyEmergencyContactsLocation =>
      'Os contactos de emergência podem ver a sua localização';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 hora';

  @override
  String get safetyInterval2Hours => '2 horas';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Localização';

  @override
  String get safetyMeetingLocationHint => 'Onde vão encontrar-se?';

  @override
  String get safetyMeetingWith => 'Encontro com';

  @override
  String get safetyNameLabel => 'Nome';

  @override
  String get safetyNotesOptional => 'Notas (Opcional)';

  @override
  String get safetyPhoneLabel => 'Número de Telefone';

  @override
  String get safetyPleaseEnterLocation =>
      'Por favor, introduza uma localização';

  @override
  String get safetyRelationshipFamily => 'Família';

  @override
  String get safetyRelationshipFriend => 'Amigo';

  @override
  String get safetyRelationshipLabel => 'Relação';

  @override
  String get safetyRelationshipOther => 'Outro';

  @override
  String get safetyRelationshipPartner => 'Parceiro';

  @override
  String get safetyRelationshipRoommate => 'Colega de Casa';

  @override
  String get safetyScheduleCheckIn => 'Agendar Check-In';

  @override
  String get safetyShareLiveLocation => 'Partilhar localização em tempo real';

  @override
  String get safetyStaySafe => 'Mantenha-se Seguro';

  @override
  String get save => 'Guardar';

  @override
  String get searchByNameOrNickname => 'Pesquisar por nome ou @alcunha';

  @override
  String get searchByNickname => 'Pesquisar por Alcunha';

  @override
  String get searchByNicknameTooltip => 'Pesquisar por alcunha';

  @override
  String get searchCityPlaceholder => 'Pesquisar cidade, endereço ou local...';

  @override
  String get searchCountries => 'Pesquisar países...';

  @override
  String get searchCountryHint => 'Pesquisar país...';

  @override
  String get searchForCity => 'Pesquise uma cidade ou use o GPS';

  @override
  String get searchMessagesHint => 'Pesquisar mensagens...';

  @override
  String get secondChanceDescription =>
      'Veja perfis que passou e que realmente gostaram de si!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km de distância';
  }

  @override
  String get secondChanceEmpty => 'Sem segundas oportunidades disponíveis';

  @override
  String get secondChanceEmptySubtitle =>
      'Volte mais tarde para mais oportunidades!';

  @override
  String get secondChanceFindButton => 'Encontrar Segundas Oportunidades';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max grátis';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Obter Ilimitado ($cost)';
  }

  @override
  String get secondChanceLike => 'Gostar';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'Gostaram de si $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'Vocês gostam um do outro! Inicie uma conversa.';

  @override
  String get secondChanceMatchTitle => 'Comece a conectar!';

  @override
  String get secondChanceOutOf => 'Sem Segundas Oportunidades';

  @override
  String get secondChancePass => 'Passar';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Usou todas as $freePerDay segundas oportunidades grátis de hoje.';
  }

  @override
  String get secondChanceRefresh => 'Atualizar';

  @override
  String get secondChanceStartChat => 'Iniciar Conversa';

  @override
  String get secondChanceTitle => 'Segunda Oportunidade';

  @override
  String get secondChanceUnlimited => 'Ilimitado';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Segundas oportunidades ilimitadas desbloqueadas!';

  @override
  String get secondaryOrigin => 'Origem Secundária (opcional)';

  @override
  String get seconds => 'Segundos';

  @override
  String get secretAchievement => 'Conquista Secreta';

  @override
  String get seeAll => 'Ver Todos';

  @override
  String get seeHowOthersViewProfile => 'Vê como outros veem o teu perfil';

  @override
  String seeMoreProfiles(int count) {
    return 'Ver mais $count';
  }

  @override
  String get seeMoreProfilesTitle => 'Ver Mais Perfis';

  @override
  String get seeProfile => 'Ver Perfil';

  @override
  String selectAtLeastInterests(int count) {
    return 'Seleciona pelo menos $count interesses';
  }

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get selectTravelLocation => 'Selecionar local de viagem';

  @override
  String get sendCoins => 'Enviar moedas';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Enviar $amount moedas para @$nickname?';
  }

  @override
  String get sendMedia => 'Enviar Média';

  @override
  String get sendMessage => 'Enviar Mensagem';

  @override
  String get serverUnavailableMessage =>
      'Os nossos servidores estão temporariamente indisponíveis. Tenta novamente dentro de momentos.';

  @override
  String get serverUnavailableTitle => 'Servidor Indisponível';

  @override
  String get setYourUniqueNickname => 'Define a tua alcunha única';

  @override
  String get settings => 'Definições';

  @override
  String get shareAlbum => 'Partilhar álbum';

  @override
  String get shop => 'Loja';

  @override
  String get shopActive => 'ATIVA';

  @override
  String get shopAdvancedFilters => 'Filtros Avançados';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount moedas';
  }

  @override
  String get shopBadge => 'Distintivo';

  @override
  String get shopBaseMembership => 'Subscrição Base GreenGo';

  @override
  String get shopBaseMembershipDescription =>
      'Necessária para deslizar, gostar, conversar e interagir com outros utilizadores.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus moedas bónus';
  }

  @override
  String get shopBoosts => 'Boosts';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Comprar $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf => 'Não podes enviar moedas para ti mesmo';

  @override
  String get shopCheckInternet =>
      'Certifica-te de que tens ligação à internet\ne tenta novamente.';

  @override
  String get shopCoins => 'Moedas';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount moedas/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount moedas enviadas para @$nickname';
  }

  @override
  String get shopComingSoon => 'Em breve';

  @override
  String get shopConfirmSend => 'Confirmar envio';

  @override
  String get shopCurrent => 'ATUAL';

  @override
  String shopCurrentExpires(Object date) {
    return 'ATUAL - Expira $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Plano atual: $tier';
  }

  @override
  String get shopDailyLikes => 'Conexões Diárias';

  @override
  String shopDaysLeft(Object days) {
    return '${days}d restantes';
  }

  @override
  String get shopEnterAmount => 'Introduz o montante';

  @override
  String get shopEnterBothFields => 'Introduz o nickname e o montante';

  @override
  String get shopEnterValidAmount => 'Introduz um montante válido';

  @override
  String shopExpired(String date) {
    return 'Expirado: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expira: $date ($days dias restantes)';
  }

  @override
  String get shopFailedToInitiate => 'Não foi possível iniciar a compra';

  @override
  String get shopFailedToSendCoins => 'Falha ao enviar moedas';

  @override
  String get shopGetNotified => 'Receber notificação';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Modo Incógnito';

  @override
  String get shopInsufficientCoins => 'Moedas insuficientes';

  @override
  String shopMembershipActivated(String date) {
    return 'Subscrição GreenGo ativada! +500 moedas bónus. Válida até $date.';
  }

  @override
  String get shopMonthly => 'Mensal';

  @override
  String get shopNotifyMessage =>
      'Avisamos-te quando os Video-Coins estiverem disponíveis';

  @override
  String get shopOneMonth => '1 Mês';

  @override
  String get shopOneYear => '1 Ano';

  @override
  String get shopPerMonth => '/mês';

  @override
  String get shopPerYear => '/ano';

  @override
  String get shopPopular => 'POPULAR';

  @override
  String get shopPreviousPurchaseFound =>
      'Compra anterior encontrada. Tenta novamente.';

  @override
  String get shopPriorityMatching => 'Matching prioritário';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Comprar $coins moedas por $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Erro de compra: $error';
  }

  @override
  String get shopReadReceipts => 'Confirmação de Leitura';

  @override
  String get shopRecipientNickname => 'Nickname do destinatário';

  @override
  String get shopRetry => 'Tentar novamente';

  @override
  String shopSavePercent(String percent) {
    return 'POUPA $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Ver quem conecta';

  @override
  String get shopSend => 'Enviar';

  @override
  String get shopSendCoins => 'Enviar moedas';

  @override
  String get shopStoreNotAvailable =>
      'Loja indisponível. Verifica as definições do dispositivo.';

  @override
  String get shopSuperLikes => 'Conexões Prioritárias';

  @override
  String get shopTabCoins => 'Moedas';

  @override
  String shopTabError(Object tabName) {
    return 'Erro no separador $tabName';
  }

  @override
  String get shopTabMembership => 'Subscrição';

  @override
  String get shopTabVideo => 'Vídeo';

  @override
  String get shopTitle => 'Loja';

  @override
  String get shopTravelling => 'A Viajar';

  @override
  String get shopUnableToLoadPackages => 'Não é possível carregar os pacotes';

  @override
  String get shopUnlimited => 'Ilimitado';

  @override
  String get shopUnlockPremium =>
      'Desbloqueia funcionalidades premium e melhora a tua experiência de encontros';

  @override
  String get shopUpgradeAndSave =>
      'Melhora e poupa! Desconto nos níveis superiores';

  @override
  String get shopUpgradeExperience => 'Melhora a tua experiência';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Melhorar para $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Utilizador não encontrado';

  @override
  String shopValidUntil(String date) {
    return 'Válida até $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Vê vídeos curtos para ganhar moedas grátis!\nFica atento a esta funcionalidade entusiasmante.';

  @override
  String get shopVipBadge => 'Distintivo VIP';

  @override
  String get shopYearly => 'Anual';

  @override
  String get shopYearlyPlan => 'Subscrição anual';

  @override
  String get shopYouHave => 'Tens';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Poupas $amount/mês ao melhorar de $tier';
  }

  @override
  String get shortTermRelationship => 'Relação a curto prazo';

  @override
  String showingProfiles(int count) {
    return '$count perfis';
  }

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signUp => 'Inscrever-se';

  @override
  String get silver => 'Prata';

  @override
  String get skip => 'Saltar';

  @override
  String get skipForNow => 'Saltar por Agora';

  @override
  String get slangCategory => 'Calão';

  @override
  String get socialConnectAccounts => 'Ligar as suas contas sociais';

  @override
  String get socialHintUsername => 'Nome de utilizador (sem @)';

  @override
  String get socialHintUsernameOrUrl => 'Nome de utilizador ou URL do perfil';

  @override
  String get socialLinksUpdatedMessage =>
      'Os teus perfis sociais foram guardados';

  @override
  String get socialLinksUpdatedTitle => 'Redes Sociais Atualizadas!';

  @override
  String get socialNotConnected => 'Não ligado';

  @override
  String get socialProfiles => 'Perfis Sociais';

  @override
  String get socialProfilesTip =>
      'Os teus perfis sociais serão visíveis no teu perfil de encontros e ajudarão outros a verificar a tua identidade.';

  @override
  String get somethingWentWrong => 'Algo correu mal';

  @override
  String get spotsAbout => 'Sobre';

  @override
  String get spotsAddNewSpot => 'Adicionar um Novo Local';

  @override
  String get spotsAddSpot => 'Adicionar um Local';

  @override
  String spotsAddedBy(Object name) {
    return 'Adicionado por $name';
  }

  @override
  String get spotsAll => 'Todos';

  @override
  String get spotsCategory => 'Categoria';

  @override
  String get spotsCouldNotLoad => 'Não foi possível carregar locais';

  @override
  String get spotsCouldNotLoadSpot => 'Não foi possível carregar local';

  @override
  String get spotsCreateSpot => 'Criar Local';

  @override
  String get spotsCulturalSpots => 'Locais Culturais';

  @override
  String spotsDateDaysAgo(Object count) {
    return 'Há $count dias';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return 'Há $count meses';
  }

  @override
  String get spotsDateToday => 'Hoje';

  @override
  String spotsDateWeeksAgo(Object count) {
    return 'Há $count semanas';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return 'Há $count anos';
  }

  @override
  String get spotsDateYesterday => 'Ontem';

  @override
  String get spotsDescriptionLabel => 'Descrição';

  @override
  String get spotsNameLabel => 'Nome do Local';

  @override
  String get spotsNoReviews =>
      'Sem avaliações ainda. Seja o primeiro a escrever uma!';

  @override
  String get spotsNoSpotsFound => 'Nenhum local encontrado';

  @override
  String get spotsReviewAdded => 'Avaliação adicionada!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Avaliações ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Partilha a tua experiência...';

  @override
  String get spotsSubmitReview => 'Submeter Avaliação';

  @override
  String get spotsWriteReview => 'Escrever uma Avaliação';

  @override
  String get spotsYourRating => 'A Sua Classificação';

  @override
  String get standardTier => 'Standard';

  @override
  String get startChat => 'Iniciar Chat';

  @override
  String get startConversation => 'Iniciar uma conversação';

  @override
  String get startGame => 'Iniciar Jogo';

  @override
  String get startLearning => 'Começar a Aprender';

  @override
  String get startLessonBtn => 'Iniciar Lição';

  @override
  String get startSwipingToFindMatches =>
      'Começa a deslizar para encontrar as tuas correspondências!';

  @override
  String get step => 'Passo';

  @override
  String get stepOf => 'de';

  @override
  String get storiesAddCaptionHint => 'Adicionar legenda...';

  @override
  String get storiesCreateStory => 'Criar História';

  @override
  String storiesDaysAgo(Object count) {
    return 'Há ${count}d';
  }

  @override
  String get storiesDisappearAfter24h =>
      'A sua história desaparecerá após 24 horas';

  @override
  String get storiesGallery => 'Galeria';

  @override
  String storiesHoursAgo(Object count) {
    return 'Há ${count}h';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return 'Há ${count}m';
  }

  @override
  String get storiesNoActive => 'Sem histórias ativas';

  @override
  String get storiesNoStories => 'Sem histórias disponíveis';

  @override
  String get storiesPhoto => 'Foto';

  @override
  String get storiesPost => 'Publicar';

  @override
  String get storiesSendMessageHint => 'Enviar uma mensagem...';

  @override
  String get storiesShareMoment => 'Partilhar um momento';

  @override
  String get storiesVideo => 'Vídeo';

  @override
  String get storiesYourStory => 'A Sua História';

  @override
  String get streakActiveToday => 'Ativo hoje';

  @override
  String get streakBonusHeader => 'Bónus de Sequência!';

  @override
  String get streakInactive => 'Comece a sua série!';

  @override
  String get streakMessageIncredible => 'Dedicação incrível!';

  @override
  String get streakMessageKeepItUp => 'Continua assim!';

  @override
  String get streakMessageMomentum => 'A ganhar ritmo!';

  @override
  String get streakMessageOneWeek => 'Marco de uma semana!';

  @override
  String get streakMessageTwoWeeks => 'Duas semanas seguidas!';

  @override
  String get submitAnswer => 'Enviar Resposta';

  @override
  String get submitVerification => 'Enviar para Verificação';

  @override
  String submittedOn(String date) {
    return 'Enviado em $date';
  }

  @override
  String get subscribe => 'Subscrever';

  @override
  String get subscribeNow => 'Subscrever agora';

  @override
  String get subscriptionExpired => 'Subscrição Expirada';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'A sua subscrição $tierName expirou. Foi movido para o nível Grátis.';
  }

  @override
  String get suggestions => 'Sugestões';

  @override
  String get superLike => 'Conexão Prioritária';

  @override
  String superLikedYou(String name) {
    return '$name conectou-se prioritariamente contigo!';
  }

  @override
  String get superLikes => 'Conexões Prioritárias';

  @override
  String get supportCenter => 'Centro de Suporte';

  @override
  String get supportCenterSubtitle =>
      'Obter ajuda, reportar problemas, contacta-nos';

  @override
  String get swipeIndicatorLike => 'CONECTAR';

  @override
  String get swipeIndicatorNope => 'PASSAR';

  @override
  String get swipeIndicatorSkip => 'EXPLORAR';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITARIO';

  @override
  String get takePhoto => 'Tirar Foto';

  @override
  String get takeVerificationPhoto => 'Tirar Foto de Verificação';

  @override
  String get tapToContinue => 'Toque para continuar';

  @override
  String get targetLanguage => 'Língua Alvo';

  @override
  String get termsAndConditions => 'Termos e Condições';

  @override
  String get thatsYourOwnProfile => 'Esse é o teu próprio perfil!';

  @override
  String get thirdPartyDataDescription =>
      'Permitir o compartilhamento de dados anonimizados com parceiros para melhoria do serviço';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get tierFree => 'Grátis';

  @override
  String get timeRemaining => 'Tempo restante';

  @override
  String get timeoutError => 'Pedido expirou';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% para Nível $level';
  }

  @override
  String get today => 'hoje';

  @override
  String get totalXpLabel => 'XP Total';

  @override
  String get tourDiscoveryDescription =>
      'Desliza perfis para encontrar o teu match perfeito. Desliza para a direita se interessado, para a esquerda para passar.';

  @override
  String get tourDiscoveryTitle => 'Descobre Matches';

  @override
  String get tourDone => 'Concluído';

  @override
  String get tourLearnDescription =>
      'Estuda vocabulário, gramática e competências de conversação';

  @override
  String get tourLearnTitle => 'Aprende Línguas';

  @override
  String get tourMatchesDescription =>
      'Vê todos os que também gostaram de ti! Começa conversas com os teus matches mútuos.';

  @override
  String get tourMatchesTitle => 'Os Teus Matches';

  @override
  String get tourMessagesDescription =>
      'Conversa com os teus matches aqui. Envia mensagens, fotos e notas de voz para te conectares.';

  @override
  String get tourMessagesTitle => 'Mensagens';

  @override
  String get tourNext => 'Seguinte';

  @override
  String get tourPlayDescription =>
      'Desafia outros em jogos de línguas divertidos';

  @override
  String get tourPlayTitle => 'Joga';

  @override
  String get tourProfileDescription =>
      'Personaliza o teu perfil, gere definições e controla a tua privacidade.';

  @override
  String get tourProfileTitle => 'O Teu Perfil';

  @override
  String get tourProgressDescription =>
      'Ganha emblemas, completa desafios e sobe na classificação!';

  @override
  String get tourProgressTitle => 'Acompanha o Progresso';

  @override
  String get tourShopDescription =>
      'Obtém moedas e funcionalidades premium para melhorar a tua experiência.';

  @override
  String get tourShopTitle => 'Loja e Moedas';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get trialWelcomeTitle => 'Bem-vindo ao GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Estás a utilizar a versão de teste. A tua subscrição base gratuita está ativa até $expirationDate. Diverte-te a explorar o GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Começar';

  @override
  String get translateWord => 'Traduz esta palavra';

  @override
  String get translationDownloadExplanation =>
      'Para ativar a tradução automática de mensagens, precisamos de transferir dados linguísticos para uso offline.';

  @override
  String get travelCategory => 'Viagem';

  @override
  String get travelLabel => 'Viagem';

  @override
  String get travelerAppearFor24Hours =>
      'Aparecerá nos resultados de descoberta para esta localização por 24 horas.';

  @override
  String get travelerBadge => 'Viajante';

  @override
  String get travelerChangeLocation => 'Alterar localização';

  @override
  String get travelerConfirmLocation => 'Confirmar Localização';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Falha ao obter localização: $error';
  }

  @override
  String get travelerGettingLocation => 'A obter localização...';

  @override
  String travelerInCity(String city) {
    return 'Em $city';
  }

  @override
  String get travelerLoadingAddress => 'A carregar endereço...';

  @override
  String get travelerLocationInfo =>
      'Aparecerá nos resultados de descoberta para esta localização durante 24 horas.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Permissões de localização negadas';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Permissões de localização permanentemente negadas';

  @override
  String get travelerLocationServicesDisabled =>
      'Os serviços de localização estão desativados';

  @override
  String travelerModeActivated(String city) {
    return 'Modo viajante ativado! A aparecer em $city durante 24 horas.';
  }

  @override
  String get travelerModeActive => 'Modo viajante ativo';

  @override
  String get travelerModeDeactivated =>
      'Modo viajante desativado. De volta à sua localização real.';

  @override
  String get travelerModeDescription =>
      'Apareça no feed de descoberta de outra cidade durante 24 horas';

  @override
  String get travelerModeTitle => 'Modo Viajante';

  @override
  String travelerNoResultsFor(Object query) {
    return 'Nenhum resultado encontrado para \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Escolher no Mapa';

  @override
  String get travelerProfileAppearDescription =>
      'O seu perfil aparecerá no feed de descoberta dessa localização por 24 horas com um distintivo de Viajante.';

  @override
  String get travelerSearchHint =>
      'O seu perfil aparecerá no feed de descoberta dessa localização durante 24 horas com um distintivo de Viajante.';

  @override
  String get travelerSearchOrGps => 'Pesquisar uma cidade ou usar GPS';

  @override
  String get travelerSelectOnMap => 'Selecionar no Mapa';

  @override
  String get travelerSelectThisLocation => 'Selecionar Esta Localização';

  @override
  String get travelerSelectTravelLocation => 'Selecionar Localização de Viagem';

  @override
  String get travelerTapOnMap =>
      'Toque no mapa para selecionar uma localização';

  @override
  String get travelerUseGps => 'Usar GPS';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get tryDifferentSearchOrFilter =>
      'Tenta uma pesquisa ou filtro diferente';

  @override
  String get twoFaDisabled => 'Autenticação 2FA desativada';

  @override
  String get twoFaEnabled => 'Autenticação 2FA ativada';

  @override
  String get twoFaToggleSubtitle =>
      'Exigir verificação por código de email em cada login';

  @override
  String get twoFaToggleTitle => 'Ativar Autenticação 2FA';

  @override
  String get typeMessage => 'Escreva uma mensagem...';

  @override
  String get typeQuizzes => 'Quizzes';

  @override
  String get typeStreak => 'Série';

  @override
  String typeWordStartingWith(String letter) {
    return 'Escreve uma palavra que comece com \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Palavras Aprendidas';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Não foi possível carregar o perfil';

  @override
  String get unableToPlayVoiceIntro =>
      'Não foi possível reproduzir a introdução de voz';

  @override
  String get undoSwipe => 'Desfazer Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unidade $number';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get unlock => 'Desbloquear';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Desbloqueia mais $count perfis na grelha por $cost moedas.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Tens a certeza de que queres desfazer o match com $name? Isto nao pode ser desfeito.';
  }

  @override
  String get unmatchLabel => 'Desfazer Match';

  @override
  String unmatchedWith(String name) {
    return 'Correspondência com $name desfeita';
  }

  @override
  String get upgrade => 'Atualizar';

  @override
  String get upgradeForEarlyAccess =>
      'Atualize para Prata, Ouro ou Platina para acesso antecipado a 1 de março de 2026!';

  @override
  String get upgradeNow => 'Atualizar Agora';

  @override
  String get upgradeToPremium => 'Atualizar para Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Atualizar para $tier';
  }

  @override
  String get uploadPhoto => 'Carregar Foto';

  @override
  String get uppercaseLowercase => 'Letras maiúsculas e minúsculas';

  @override
  String get useCurrentGpsLocation => 'Usar a minha localização GPS atual';

  @override
  String get usedToday => 'Usado hoje';

  @override
  String get usedWords => 'Palavras Usadas';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName foi bloqueado';
  }

  @override
  String get userBlockedTitle => 'Utilizador Bloqueado!';

  @override
  String get userNotFound => 'Utilizador não encontrado';

  @override
  String get usernameOrProfileUrl => 'Nome de utilizador ou URL do perfil';

  @override
  String get usernameWithoutAt => 'Nome de utilizador (sem @)';

  @override
  String get verificationApproved => 'Verificação Aprovada';

  @override
  String get verificationApprovedMessage =>
      'A sua identidade foi verificada. Agora tem acesso completo à app.';

  @override
  String get verificationApprovedSuccess => 'Verificação aprovada com sucesso';

  @override
  String get verificationDescription =>
      'Para garantir a segurança da nossa comunidade, exigimos que todos os utilizadores verifiquem a sua identidade. Tire uma foto sua segurando o seu documento de identidade.';

  @override
  String get verificationHistory => 'Histórico de Verificações';

  @override
  String get verificationInstructions =>
      'Segure o seu documento de identidade (passaporte, carta de condução ou bilhete de identidade) junto ao rosto e tire uma foto clara.';

  @override
  String get verificationNeedsResubmission => 'Foto Melhor Necessária';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Precisamos de uma foto mais clara para verificação. Por favor reenvie.';

  @override
  String get verificationPanel => 'Painel de Verificação';

  @override
  String get verificationPending => 'Verificação Pendente';

  @override
  String get verificationPendingMessage =>
      'A sua conta está a ser verificada. Isto geralmente demora 24-48 horas. Será notificado quando a revisão estiver completa.';

  @override
  String get verificationRejected => 'Verificação Rejeitada';

  @override
  String get verificationRejectedMessage =>
      'A sua verificação foi rejeitada. Por favor envie uma nova foto.';

  @override
  String get verificationRejectedSuccess => 'Verificação rejeitada';

  @override
  String get verificationRequired => 'Verificação de Identidade Necessária';

  @override
  String get verificationSkipWarning =>
      'Pode explorar a app, mas não poderá conversar ou ver outros perfis até estar verificado.';

  @override
  String get verificationTip1 => 'Certifique-se de ter boa iluminação';

  @override
  String get verificationTip2 =>
      'O seu rosto e o documento devem estar claramente visíveis';

  @override
  String get verificationTip3 =>
      'Segure o documento junto ao rosto, sem o cobrir';

  @override
  String get verificationTip4 => 'O texto do documento deve estar legível';

  @override
  String get verificationTips => 'Dicas para uma verificação bem-sucedida:';

  @override
  String get verificationTitle => 'Verifique Sua Identidade';

  @override
  String get verificationPrivacyTitle => 'Os teus dados estão seguros connosco';

  @override
  String get verificationPrivacyEncryption =>
      'Todos os documentos são cifrados com encriptação ponto a ponto. Nem os engenheiros do GreenGo conseguem aceder aos teus dados.';

  @override
  String get verificationPrivacyAccess =>
      'As tuas informações só podem ser acedidas mediante o teu pedido pessoal através de canais oficiais ou email.';

  @override
  String get verificationPrivacySafety =>
      'Este passo é essencial para proteger todos os membros. Convidamos-te a denunciar qualquer comportamento suspeito e deixar o GreenGo agir.';

  @override
  String get verificationPrivacyReporting =>
      'Se algo acontecer, denuncia-o imediatamente. O GreenGo irá investigar e agir para manter a comunidade segura.';

  @override
  String get verificationChooseMethod => 'Escolhe o teu método de verificação';

  @override
  String get verificationMethodPhoto => 'Documento de Identificação';

  @override
  String get verificationMethodPhotoDesc =>
      'Tira uma foto a segurar o teu documento junto ao rosto';

  @override
  String get verificationMethodPhone => 'Número de Telefone';

  @override
  String get verificationMethodPhoneDesc =>
      'Verifica através de um código SMS enviado para o teu telefone';

  @override
  String get verificationPhoneTitle => 'Verificação por Telefone';

  @override
  String get verificationPhoneSubtitle =>
      'Introduz o teu número de telefone para receberes um código de verificação por SMS';

  @override
  String get verificationPhoneLabel => 'Número de telefone';

  @override
  String get verificationPhoneHint => '+351 912 345 678';

  @override
  String get verificationSendCode => 'Enviar Código';

  @override
  String get verificationEnterCode =>
      'Introduz o código de 6 dígitos enviado para o teu telefone';

  @override
  String get verificationCodeLabel => 'Código de verificação';

  @override
  String get verificationVerifyCode => 'Verificar Código';

  @override
  String get verificationPhoneSuccess =>
      'Número de telefone verificado com sucesso!';

  @override
  String get verificationPhoneResponsibility =>
      'Ao verificares com o teu número de telefone, reconheces que o titular deste número é pessoalmente responsável por todas as ações realizadas nesta conta.';

  @override
  String get verificationResendCode => 'Reenviar código';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Código enviado para $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Falha ao verificar o número de telefone. Tenta novamente.';

  @override
  String get verificationInvalidCode =>
      'Código inválido. Verifica e tenta novamente.';

  @override
  String get verificationOr => 'ou';

  @override
  String get verifyNow => 'Verificar Agora';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit etiquetas selecionadas';
  }

  @override
  String get vibeTagsGet5Tags => 'Obter 5 etiquetas';

  @override
  String get vibeTagsGetAccessTo => 'Obter acesso a:';

  @override
  String get vibeTagsLimitReached => 'Limite de Etiquetas Atingido';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Utilizadores grátis podem selecionar até $limit etiquetas. Atualize para Premium para 5 etiquetas!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Atingiu o máximo de $limit etiquetas. Remova uma para adicionar outra.';
  }

  @override
  String get vibeTagsNoTags => 'Sem etiquetas disponíveis';

  @override
  String get vibeTagsPremiumFeature1 => '5 etiquetas de vibe em vez de 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Etiquetas premium exclusivas';

  @override
  String get vibeTagsPremiumFeature3 => 'Prioridade nos resultados de pesquisa';

  @override
  String get vibeTagsPremiumFeature4 => 'E muito mais!';

  @override
  String get vibeTagsRemoveTag => 'Remover etiqueta';

  @override
  String get vibeTagsSelectDescription =>
      'Selecione etiquetas que correspondam ao seu humor e intenções atuais';

  @override
  String get vibeTagsSetTemporary => 'Definir como etiqueta temporária (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Mostre a sua vibe';

  @override
  String get vibeTagsTemporaryDescription =>
      'Mostrar esta vibe nas próximas 24 horas';

  @override
  String get vibeTagsTemporaryTag => 'Etiqueta Temporária (24h)';

  @override
  String get vibeTagsTitle => 'A Sua Vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Atualizar para Premium';

  @override
  String get vibeTagsViewPlans => 'Ver Planos';

  @override
  String get vibeTagsYourSelected => 'As Suas Etiquetas Selecionadas';

  @override
  String get videoCallCategory => 'Videochamada';

  @override
  String get view => 'Ver';

  @override
  String get viewAllChallenges => 'Ver Todos os Desafios';

  @override
  String get viewAllLabel => 'Ver Tudo';

  @override
  String get viewBadgesAchievementsLevel => 'Ver emblemas, conquistas e nível';

  @override
  String get viewMyProfile => 'Ver o Meu Perfil';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'MEMBRO OURO';

  @override
  String get vipPlatinumMember => 'PLATINA VIP';

  @override
  String get vipPremiumBenefitsActive => 'Benefícios Premium Ativos';

  @override
  String get vipSilverMember => 'MEMBRO PRATA';

  @override
  String get virtualGiftsAddMessageHint => 'Adicionar mensagem (opcional)';

  @override
  String get voiceDeleteConfirm =>
      'Tens a certeza de que queres eliminar a tua apresentação de voz?';

  @override
  String get voiceDeleteRecording => 'Eliminar Gravação';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Falha ao iniciar gravação: $error';
  }

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Falha ao carregar gravação: $error';
  }

  @override
  String get voiceIntro => 'Apresentação de Voz';

  @override
  String get voiceIntroSaved => 'Apresentação de voz guardada';

  @override
  String get voiceIntroShort => 'Intro de Voz';

  @override
  String get voiceIntroduction => 'Introdução de Voz';

  @override
  String get voiceIntroductionInfo =>
      'As apresentações por voz ajudam os outros a conhecê-lo melhor. Este passo é opcional.';

  @override
  String get voiceIntroductionSubtitle =>
      'Gravar uma mensagem de voz curta (opcional)';

  @override
  String get voiceIntroductionTitle => 'Apresentação por voz';

  @override
  String get voiceMicrophonePermissionRequired =>
      'É necessária permissão do microfone';

  @override
  String get voiceMessageTooShort =>
      'Mantenha pressionado para gravar, solte para enviar';

  @override
  String get voiceSlideToCancel => '‹ Deslize para cancelar';

  @override
  String get voiceReleaseToCancel => 'Solte para cancelar';

  @override
  String get voiceFailedToSend => 'Falha ao enviar mensagem de voz';

  @override
  String get voiceRecordAgain => 'Gravar Novamente';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Grava uma breve apresentação de $seconds segundos para que outros oiçam a tua personalidade.';
  }

  @override
  String get voiceRecorded => 'Voz gravada';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'A gravar... (máx. $maxDuration segundos)';
  }

  @override
  String get voiceRecordingReady => 'Gravação pronta';

  @override
  String get voiceRecordingSaved => 'Gravação guardada';

  @override
  String get voiceRecordingTips => 'Dicas de Gravação';

  @override
  String get voiceSavedMessage => 'A tua introdução de voz foi atualizada';

  @override
  String get voiceSavedTitle => 'Voz Guardada!';

  @override
  String get voiceStandOutWithYourVoice => 'Destaca-te com a tua voz!';

  @override
  String get voiceTapToRecord => 'Toca para gravar';

  @override
  String get voiceTipBeYourself => 'Sê tu mesmo e natural';

  @override
  String get voiceTipFindQuietPlace => 'Encontra um lugar sossegado';

  @override
  String get voiceTipKeepItShort => 'Mantém breve e simples';

  @override
  String get voiceTipShareWhatMakesYouUnique => 'Partilha o que te torna único';

  @override
  String get voiceUploadFailed => 'Falha ao carregar gravação de voz';

  @override
  String get voiceUploading => 'A carregar...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic =>
      'O seu acesso começará a 15 de março de 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'Como membro $tier, tem acesso antecipado a 1 de março de 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'A Sua Data de Acesso';

  @override
  String waitingCountLabel(String count) {
    return '$count esperando';
  }

  @override
  String get waitingCountdownLabel => 'A sua data de lançamento';

  @override
  String get waitingCountdownSubtitle =>
      'Obrigado pelo registo! O GreenGo Chat será lançado em breve. Prepare-se para uma experiência exclusiva.';

  @override
  String get waitingCountdownTitle => 'Contagem Decrescente para o Lançamento';

  @override
  String waitingDaysRemaining(int days) {
    return '$days dias';
  }

  @override
  String get waitingEarlyAccessMember => 'Membro de Acesso Antecipado';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Ative as notificações para ser o primeiro a saber quando pode aceder à app.';

  @override
  String get waitingEnableNotificationsTitle => 'Mantenha-se atualizado';

  @override
  String get waitingExclusiveAccess => 'Tempo até poder usar a app';

  @override
  String get waitingGeneralLaunchDate => 'Data de lançamento geral';

  @override
  String get waitingYourAccessDate => 'A sua data de acesso';

  @override
  String get waitingForPlayers => 'À espera de jogadores...';

  @override
  String get waitingForVerification => 'A aguardar verificação...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours horas';
  }

  @override
  String get waitingMessageApproved =>
      'Ótimas notícias! A sua conta foi aprovada. Poderá aceder ao GreenGoChat na data indicada abaixo.';

  @override
  String get waitingMessagePending =>
      'A sua conta está pendente de aprovação pela nossa equipa. Iremos notificá-lo assim que a sua conta for revista.';

  @override
  String get waitingMessageRejected =>
      'Infelizmente, a sua conta não pôde ser aprovada de momento. Por favor contacte o suporte para mais informações.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notificações ativadas - iremos avisá-lo quando puder aceder à aplicação!';

  @override
  String get waitingProfileUnderReview => 'Perfil em análise';

  @override
  String get waitingReviewMessage =>
      'A app já está online! A nossa equipa está a analisar o seu perfil para garantir a melhor experiência para a nossa comunidade. Isto geralmente demora 24-48 horas.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get waitingStayTuned =>
      'Fique atento! Iremos notificá-lo quando for hora de começar a conectar-se.';

  @override
  String get waitingStepActivation => 'Ativação de conta';

  @override
  String get waitingStepRegistration => 'Registo concluído';

  @override
  String get waitingStepReview => 'Análise de perfil em progresso';

  @override
  String get waitingSubtitle => 'A sua conta foi criada com sucesso';

  @override
  String get waitingThankYouRegistration => 'Obrigado pelo registo!';

  @override
  String get waitingTitle => 'Obrigado por se Registar!';

  @override
  String get weeklyChallengesTitle => 'Desafios Semanais';

  @override
  String get weight => 'Peso';

  @override
  String get weightLabel => 'Peso';

  @override
  String get welcome => 'Bem-vindo ao GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Palavra já utilizada';

  @override
  String get wordReported => 'Palavra reportada';

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
    return '$amount XP ganhos';
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
  String get yearlyMembership => 'Subscrição anual';

  @override
  String yearsLabel(int age) {
    return '$age anos';
  }

  @override
  String get yes => 'Sim';

  @override
  String get yesterday => 'ontem';

  @override
  String youAndMatched(String name) {
    return 'Você e $name gostaram um do outro';
  }

  @override
  String get youGotSuperLike => 'Recebeste uma Conexão Prioritária!';

  @override
  String get youLabel => 'TU';

  @override
  String get youLose => 'Perdeste';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Fizeste match com $name em $date';
  }

  @override
  String get youWin => 'Ganhaste!';

  @override
  String get yourLanguages => 'As Suas Línguas';

  @override
  String get yourRankLabel => 'A Sua Posição';

  @override
  String get yourTurn => 'A Tua Vez!';

  @override
  String get achievementBadges => 'Distintivos de Conquistas';

  @override
  String get achievementBadgesSubtitle =>
      'Toque para selecionar quais distintivos exibir no seu perfil (máx. 5)';

  @override
  String get noBadgesYet => 'Desbloqueie conquistas para ganhar distintivos!';

  @override
  String get guideTitle => 'Como funciona o GreenGo';

  @override
  String get guideSwipeTitle => 'Deslizar perfis';

  @override
  String get guideSwipeItem1 =>
      'Deslize para a direita para Connect com alguém, deslize para a esquerda para Nope.';

  @override
  String get guideSwipeItem2 =>
      'Deslize para cima para enviar um Priority Connect (usa moedas).';

  @override
  String get guideSwipeItem3 =>
      'Deslize para baixo para Explore Next e salte um perfil por agora.';

  @override
  String get guideSwipeItem4 =>
      'Pode alternar entre o modo deslizar e o modo grelha utilizando o ícone de alternância na barra superior.';

  @override
  String get guideGridTitle => 'Vista em grelha';

  @override
  String get guideGridItem1 =>
      'Navegue pelos perfis numa disposição em grelha para uma visão rápida.';

  @override
  String get guideGridItem2 =>
      'Toque numa imagem de perfil para revelar os quatro botões de ação: Connect, Priority Connect, Nope e Explore Next.';

  @override
  String get guideGridItem3 =>
      'Mantenha premida uma imagem de perfil para ver os detalhes sem abrir o perfil completo.';

  @override
  String get guideConnectionsTitle => 'Conectar-se com pessoas';

  @override
  String get guideConnectionsItem1 =>
      'Quando duas pessoas fazem Connect uma com a outra, é um match!';

  @override
  String get guideConnectionsItem2 =>
      'Após o match, pode começar a conversar de imediato.';

  @override
  String get guideConnectionsItem3 =>
      'Use Priority Connect para se destacar e aumentar as suas possibilidades.';

  @override
  String get guideConnectionsItem4 =>
      'Consulte o separador de Trocas para ver todos os seus matches e conversas.';

  @override
  String get guideChatTitle => 'Chat e mensagens';

  @override
  String get guideChatItem1 =>
      'Envie mensagens de texto, fotos e notas de voz.';

  @override
  String get guideChatItem2 =>
      'Use a funcionalidade de tradução para conversar em diferentes idiomas.';

  @override
  String get guideChatItem3 =>
      'Abra as definições do chat para personalizar a sua experiência: ative a verificação gramatical, respostas inteligentes, dicas culturais, decomposição de palavras, ajuda na pronúncia e mais.';

  @override
  String get guideChatItem4 =>
      'Ative a conversão de texto em voz para ouvir as traduções, mostrar bandeiras de idiomas e acompanhar os seus XP de aprendizagem de idiomas.';

  @override
  String get guideFiltersTitle => 'Filtros de descoberta';

  @override
  String get guideFiltersItem1 =>
      'Toque no ícone de filtro para definir as suas preferências: faixa etária, distância, idiomas e mais.';

  @override
  String get guideFiltersItem2 =>
      'Modo Aleatório: ative este interruptor para descobrir pessoas aleatórias de todo o mundo. Cada atualização mostra-lhe um novo conjunto de perfis. Quando o Modo Aleatório está desativado, apenas são mostradas pessoas perto de si. Também pode selecionar países específicos para restringir a sua pesquisa.';

  @override
  String get guideFiltersItem3 =>
      'Os filtros ajudam-no a encontrar pessoas que correspondam ao que procura. Pode ajustá-los a qualquer momento.';

  @override
  String get guideTravelTitle => 'Viagens e exploração';

  @override
  String get guideTravelItem1 =>
      'Ative o Modo Viajante para aparecer na descoberta de uma cidade que planeia visitar durante 24 horas.';

  @override
  String get guideTravelItem2 =>
      'Os guias locais podem ajudar os viajantes a descobrir a sua cidade e cultura.';

  @override
  String get guideTravelItem3 =>
      'Os parceiros de intercâmbio linguístico são emparelhados com base no que fala e no que quer aprender.';

  @override
  String get guideMembershipTitle => 'Subscrição base';

  @override
  String get guideMembershipItem1 =>
      'A sua subscrição base dá-lhe acesso a todas as funcionalidades principais: deslizar, conversar e fazer match.';

  @override
  String get guideMembershipItem2 =>
      'A subscrição começa com um período experimental gratuito após o primeiro registo.';

  @override
  String get guideMembershipItem3 =>
      'Quando a sua subscrição expirar, pode renová-la para continuar a usar a aplicação.';

  @override
  String get guideTiersTitle => 'Níveis VIP (Prata, Ouro, Platina)';

  @override
  String get guideTiersItem1 =>
      'Prata: Obtenha mais connects diários, veja quem fez Connect consigo e suporte prioritário.';

  @override
  String get guideTiersItem2 =>
      'Ouro: Tudo o que está em Prata mais connects ilimitados, filtros avançados e confirmações de leitura.';

  @override
  String get guideTiersItem3 =>
      'Platina: Tudo o que está em Ouro mais impulso de perfil, melhores escolhas e funcionalidades exclusivas.';

  @override
  String get guideTiersItem4 =>
      'Os níveis VIP são independentes da sua subscrição base e proporcionam vantagens adicionais.';

  @override
  String get guideCoinsTitle => 'Moedas';

  @override
  String get guideCoinsItem1 =>
      'As moedas são usadas para ações premium. Aqui estão os custos:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 moedas  • Boost: 50 moedas  • Mensagem direta: 2/dia grátis, depois 50 moedas';

  @override
  String get guideCoinsItem3 =>
      '• Incógnito: 30 moedas/dia  • Viajante: 100 moedas/dia';

  @override
  String get guideCoinsItem4 =>
      '• Ouvir (TTS): 5 moedas  • Extensão da grelha: 10 moedas  • Coach de aprendizagem: 10 moedas/sessão';

  @override
  String get guideCoinsItem5 =>
      'Recebe 20 moedas grátis por dia. Ganhe mais com conquistas, classificações e a Loja.';

  @override
  String get guideLeaderboardTitle => 'Tabela de líderes';

  @override
  String get guideLeaderboardItem1 =>
      'Compita com outros utilizadores para subir na tabela de líderes e ganhar recompensas.';

  @override
  String get guideLeaderboardItem2 =>
      'Ganhe pontos sendo ativo, completando o seu perfil e interagindo com os outros.';

  @override
  String get guideGridFiltersTitle => 'Filtros de grelha';

  @override
  String get guideGridFiltersItem1 =>
      'No modo grelha, use os chips de filtro no topo para restringir perfis.';

  @override
  String get guideGridFiltersItem2 =>
      'Todos: Mostra todos no seu grupo de descoberta.';

  @override
  String get guideGridFiltersItem3 =>
      'Conectados: Pessoas a quem enviou um pedido de conexão.';

  @override
  String get guideGridFiltersItem4 =>
      'Prioritário: Pessoas a quem enviou uma Conexão Prioritária.';

  @override
  String get guideGridFiltersItem5 => 'Recusados: Pessoas que escolheu passar.';

  @override
  String get guideGridFiltersItem6 =>
      'Viajantes: Pessoas com o Modo Viajante ativo, visitando uma cidade perto de si.';

  @override
  String get guideExchangesTitle => 'Trocas (Chat)';

  @override
  String get guideExchangesItem1 =>
      'As Trocas são onde estão todas as suas conversas. Encontra-as no menu inferior.';

  @override
  String get guideExchangesItem2 =>
      'O distintivo vermelho no ícone Trocas mostra o número de conversas com mensagens não lidas ou aprovações pendentes.';

  @override
  String get guideExchangesItem3 =>
      'Use os filtros para organizar os seus chats: Todos, Novos, Sem resposta, Favoritos, A aprovar, Match e Pesquisa.';

  @override
  String get guideExchangesItem4 =>
      'Novos mostra conversas com novas mensagens não lidas. Sem resposta mostra mensagens às quais ainda não respondeu.';

  @override
  String get guideExchangesItem5 =>
      'Por aprovar mostra pedidos de Conexão Prioritária à espera da sua decisão. Aceite ou recuse diretamente da lista.';

  @override
  String get guideExchangesItem6 =>
      'As conversas não lidas são destacadas com texto a negrito e um efeito dourado brilhante para as encontrar facilmente.';

  @override
  String get guideExchangesItem7 =>
      'Toque numa conversa para abrir o chat. Uma vez aberta, é marcada como lida e a contagem do distintivo diminui.';

  @override
  String get guideExchangesItem8 =>
      'Pressione longamente uma conversa para mais opções. Use o ícone de estrela para adicionar um chat aos seus Favoritos.';

  @override
  String get guideExchangesItem9 =>
      'Cada conversa mostra as bandeiras de idioma do outro utilizador, para saber que línguas fala.';

  @override
  String get guideGroupsTitle => 'Grupos (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Cria um grupo para conversar com várias pessoas ao mesmo tempo sobre um interesse ou idioma em comum.';

  @override
  String get guideGroupsItem2 =>
      'Os administradores podem renomear o grupo, mudar a foto e adicionar ou remover membros.';

  @override
  String get guideGroupsItem3 =>
      'Convida pessoas pelo seu apelido nas informações do grupo.';

  @override
  String get guideGroupsItem4 =>
      'Adiciona as tuas próprias tags privadas a um grupo nas informações do grupo e filtra a tua lista de grupos por tag — só tu vês as tuas tags.';

  @override
  String get guideGroupsItem5 => 'Sai ou denuncia um grupo a qualquer momento.';

  @override
  String get guideEventsTitle => 'Eventos';

  @override
  String get guideEventsItem1 =>
      'Descobre eventos perto de ti — festas, visitas a museus, encontros de idiomas e passeios pela cidade.';

  @override
  String get guideEventsItem2 =>
      'Explora experiências e atrações selecionadas, ou cria o teu próprio evento com fotos, localização e data.';

  @override
  String get guideEventsItem3 =>
      'Marca eventos como Vou participar ou Interessado e encontra-os no separador Vou participar.';

  @override
  String get guideEventsItem4 =>
      'Cada evento tem o seu próprio chat; os organizadores podem enviar anúncios a todos os participantes.';

  @override
  String get guideEventsItem5 =>
      'Partilha qualquer evento numa conversa privada ou num grupo.';

  @override
  String get guideEventsItem6 =>
      'Explora eventos de todo o mundo no mapa, por localização.';

  @override
  String get guideSafetyTitle => 'Segurança e privacidade';

  @override
  String get guideSafetyItem1 =>
      'Todas as fotos são verificadas por IA para garantir perfis autênticos.';

  @override
  String get guideSafetyItem2 =>
      'Pode bloquear ou denunciar qualquer utilizador a qualquer momento a partir do seu perfil.';

  @override
  String get guideSafetyItem3 =>
      'As suas informações pessoais estão protegidas e nunca são partilhadas sem o seu consentimento.';

  @override
  String get firstStepsTitle => 'Primeiros Passos';

  @override
  String get firstStepsReview =>
      'Os teus documentos serão analisados no prazo de 24-48 horas após a submissão.';

  @override
  String get firstStepsStatusUpdate =>
      'A aplicação precisa de cerca de 15 minutos para atualizar o teu estado atual após o primeiro início de sessão.';

  @override
  String get firstStepsSupportChat =>
      'Podes contactar o suporte através da conversa ou abrindo um ticket diretamente.';

  @override
  String get showSupportUser => 'Mostrar Suporte GreenGo';

  @override
  String get showSupportUserDescription =>
      'Mostrar o utilizador Suporte GreenGo na grelha de descoberta';

  @override
  String get preferenceShowMyNetwork => 'Minha Rede';

  @override
  String get preferenceShowMyNetworkDesc =>
      'Mostrar apenas pessoas na sua rede (matches e Priority Connect aceitos).';

  @override
  String get randomMode => 'Modo Aleatório';

  @override
  String get randomModeDescription =>
      'Descobre pessoas aleatórias de todo o mundo, ordenadas por distância. Quando desativado, apenas são mostradas pessoas perto de ti.';

  @override
  String get yourProfile => 'Tu';

  @override
  String get loadingMsg1 => 'À procura de perfis incríveis por todo o mundo...';

  @override
  String get loadingMsg2 => 'A conectar corações através dos continentes...';

  @override
  String get loadingMsg3 => 'A descobrir pessoas incríveis perto de si...';

  @override
  String get loadingMsg4 =>
      'A preparar as suas correspondências personalizadas...';

  @override
  String get loadingMsg5 => 'A explorar perfis de todos os cantos do mundo...';

  @override
  String get loadingMsg6 =>
      'A encontrar pessoas que partilham os seus interesses...';

  @override
  String get loadingMsg7 => 'A configurar a sua experiência de descoberta...';

  @override
  String get loadingMsg8 => 'A carregar perfis bonitos só para si...';

  @override
  String get loadingMsg9 => 'À procura da sua correspondência perfeita...';

  @override
  String get loadingMsg10 => 'A aproximar o mundo de si...';

  @override
  String get loadingMsg11 =>
      'A selecionar perfis com base nas suas preferências...';

  @override
  String get loadingMsg12 => 'Quase lá! As coisas boas levam um momento...';

  @override
  String get loadingMsg13 => 'A conectá-lo a um mundo de possibilidades...';

  @override
  String get loadingMsg14 =>
      'A encontrar as melhores correspondências na sua área...';

  @override
  String get loadingMsg15 => 'A desbloquear novas conexões à sua volta...';

  @override
  String get loadingMsg16 =>
      'A sua próxima grande conversa está a um swipe de distância...';

  @override
  String get loadingMsg17 => 'A reunir perfis de todo o mundo...';

  @override
  String get loadingMsg18 => 'A preparar algo especial para si...';

  @override
  String get loadingMsg19 => 'A garantir que tudo está perfeito...';

  @override
  String get loadingMsg20 =>
      'O amor não conhece fronteiras, e nós também não...';

  @override
  String get loadingMsg21 => 'A aquecer o seu feed de descoberta...';

  @override
  String get loadingMsg22 =>
      'A analisar o globo em busca de pessoas interessantes...';

  @override
  String get loadingMsg23 => 'As grandes conexões começam aqui...';

  @override
  String get loadingMsg24 => 'A sua aventura está prestes a começar...';

  @override
  String get filterFavorites => 'Favoritos';

  @override
  String get filterToApprove => 'Para aprovar';

  @override
  String get priorityConnectAccept => 'Aceitar';

  @override
  String get priorityConnectReject => 'Rejeitar';

  @override
  String get priorityConnectPending => 'Aprovação pendente';

  @override
  String get membershipTrialTitle => 'Comece o seu teste grátis!';

  @override
  String get membershipTrialSubtitle =>
      '7 dias grátis, depois renova anualmente';

  @override
  String get membershipTrialFeature1 => 'Swipes e conexões ilimitadas';

  @override
  String get membershipTrialFeature2 => '500 moedas bónus na ativação';

  @override
  String get membershipTrialFeature3 =>
      'Acesso total a todas as funcionalidades';

  @override
  String get membershipTrialCta => 'Iniciar teste de 7 dias';

  @override
  String get membershipTrialFooter =>
      'Cancele a qualquer momento durante o teste. Sem cobrança até ao dia 8.';

  @override
  String get membershipTrialBadge => 'GRÁTIS POR 7 DIAS';

  @override
  String get globeMyNetwork => 'A Minha Rede';

  @override
  String get globeMyWorldMap => 'O meu mapa do mundo';

  @override
  String get globeLayerContacts => 'A minha comunidade';

  @override
  String get globeLayerExperiences => 'Experiências';

  @override
  String get globeYou => 'Tu';

  @override
  String get globeConnections => 'Ligações';

  @override
  String get globeTraveler => 'Viajante';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ligações',
      one: 'ligação',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ligações',
      one: 'ligação',
    );
    return '$count $_temp0 aqui';
  }

  @override
  String get globeThisIsYou => 'És tu!';

  @override
  String globeTravelingTo(String country) {
    return 'A viajar para $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'Ainda sem ligações em $country';
  }

  @override
  String get globeNoConnectionsHint =>
      'Continua a ligar-te para encontrar pessoas aqui!';

  @override
  String get globeProfile => 'Perfil';

  @override
  String get globeChat => 'Conversa';

  @override
  String get globeViewProfileTooltip => 'Ver Perfil';

  @override
  String get globeOpenChatTooltip => 'Abrir Conversa';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'Sem ligações em $country';
  }

  @override
  String get discoverabilityExact => 'Exata';

  @override
  String get discoverabilityExactDesc =>
      'Marcador na tua localização exata (<1km)';

  @override
  String get discoverabilityApproximate => 'Aproximada';

  @override
  String get discoverabilityApproximateDesc =>
      'Marcador na tua região (grelha de ~50km, predefinição)';

  @override
  String get discoverabilityCountry => 'País';

  @override
  String get discoverabilityCountryDesc => 'Marcador algures no teu país';

  @override
  String get discoverabilityHidden => 'Oculta';

  @override
  String get discoverabilityHiddenDesc => 'Não visível no Mapa';

  @override
  String get discoverabilityTitle => 'Visibilidade no Globo';

  @override
  String get discoverabilityInfo =>
      'As tuas ligações veem-te sempre no Mapa, independentemente desta definição.';

  @override
  String get discoverabilityChangedExact => 'Localização definida como exata';

  @override
  String get discoverabilityChangedApproximate =>
      'Localização definida como aproximada';

  @override
  String get discoverabilityChangedCountry =>
      'Localização definida ao nível do país';

  @override
  String get discoverabilityChangedHidden => 'Estás agora oculto do mapa';

  @override
  String get onboardingExitTitle => 'Sair do registo?';

  @override
  String get onboardingExitMessage =>
      'A sua sessão será terminada. Pode concluir a configuração do perfil no próximo início de sessão.';

  @override
  String get onboardingExitConfirm => 'Terminar sessão';

  @override
  String get onboardingExitCancel => 'Cancelar';

  @override
  String get loginEmailOrNickname => 'Email / Alcunha';

  @override
  String get paymentVerifying => 'A verificar o seu pagamento...';

  @override
  String get paymentSuccess => 'Pagamento bem-sucedido!';

  @override
  String get paymentSuccessMessage =>
      'A sua compra foi creditada na sua conta.';

  @override
  String get paymentPending => 'A processar pagamento';

  @override
  String get paymentPendingMessage =>
      'O seu pagamento está a ser processado. Pode demorar alguns minutos a aparecer.';

  @override
  String get paymentCancelled => 'Pagamento cancelado';

  @override
  String get paymentCancelledMessage =>
      'O seu pagamento foi cancelado. Não foram efetuadas cobranças.';

  @override
  String get continueToApp => 'Continuar';

  @override
  String get webCheckoutOpening => 'A abrir o pagamento seguro…';

  @override
  String get webCheckoutWaiting =>
      'Conclui o teu pagamento no novo separador. Esta janela será atualizada automaticamente quando terminar.';

  @override
  String get webCheckoutTimeout =>
      'Ainda não conseguimos confirmar o teu pagamento. Se o concluíste, o teu saldo será atualizado em breve.';

  @override
  String get webCheckoutFailed =>
      'Não foi possível iniciar o pagamento. Tenta novamente.';

  @override
  String get groupNewGroup => 'Novo grupo';

  @override
  String get groupCreate => 'Criar';

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String groupSelectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get groupInviteByNickname => 'Convidar por alcunha';

  @override
  String get groupAddMembers => 'Adicionar membros';

  @override
  String get groupTtsReadTranslated => 'Ler a tradução em voz alta';

  @override
  String get groupTtsReadTranslatedHint =>
      'Toque duas vezes numa mensagem para ouvi-la. Ligado = o seu idioma, Desligado = original.';

  @override
  String get ttsNotEnoughCoins =>
      'Moedas insuficientes para TTS (são necessárias 5)';

  @override
  String get groupRemoveMember => 'Remover membro';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Remover $name deste grupo?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name removido';
  }

  @override
  String groupAddSelected(int count) {
    return 'Adicionar $count selecionados';
  }

  @override
  String get groupNicknameHint => 'Introduza uma alcunha';

  @override
  String get groupNoContacts => 'Ainda não há contactos para adicionar';

  @override
  String get groupNoOneFound => 'Ninguém encontrado com essa alcunha';

  @override
  String get groupAlreadyAdded => 'Já adicionado';

  @override
  String groupAddedCount(int count) {
    return '$count adicionados';
  }

  @override
  String get groupSearchFailed => 'A pesquisa falhou';

  @override
  String get groupInfo => 'Informações do grupo';

  @override
  String groupMembersCount(int count) {
    return '$count membros';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'Tu';

  @override
  String get groupLeave => 'Sair do grupo';

  @override
  String get groupLeaveConfirmTitle => 'Sair do grupo?';

  @override
  String get groupLeaveConfirmBody =>
      'Deixarás de receber mensagens deste grupo.';

  @override
  String get groupCancel => 'Cancelar';

  @override
  String get groupLeaveAction => 'Sair';

  @override
  String get groupReport => 'Denunciar grupo';

  @override
  String get groupReportConfirmBody =>
      'Denunciar este grupo à nossa equipa de segurança?';

  @override
  String get groupReportAction => 'Denunciar';

  @override
  String get groupReportSubmitted => 'Denúncia enviada';

  @override
  String get groupMessageHint => 'Mensagem…';

  @override
  String get groupSayHello => 'Diz olá ao grupo 👋';

  @override
  String get groupLoadError => 'Não foi possível carregar este grupo';

  @override
  String get chatLocation => 'Localização';

  @override
  String get chatShareLocation => 'Partilhar localização';

  @override
  String get chatLocationDenied =>
      'É necessária a permissão de localização para partilhar a tua posição';

  @override
  String get chatOpenInMaps => 'Abrir no Maps';

  @override
  String get eventsSearchHint => 'Pesquisar por país, cidade ou nome';

  @override
  String get eventsSortPopular => 'Popular';

  @override
  String get eventsViewList => 'Vista de lista';

  @override
  String get eventsViewGrid => 'Vista de grelha';

  @override
  String get eventViewEvent => 'Ver evento';

  @override
  String get eventLoadError => 'Não foi possível carregar este evento';

  @override
  String get eventShare => 'Partilhar evento';

  @override
  String get eventShared => 'Evento partilhado';

  @override
  String get eventShareEmpty => 'Ainda não há chats ou grupos para partilhar';

  @override
  String get eventsUnlimitedAttendees => 'Participantes ilimitados';

  @override
  String get eventsPrivateEvent => 'Evento privado';

  @override
  String get eventsExternalLinks => 'Ligações';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Adicionar ligação';

  @override
  String get tierLimitTitle => 'Faz upgrade para criar mais';

  @override
  String tierLimitEventsBody(int max) {
    return 'O teu plano permite $max eventos. Faz upgrade para criar mais.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'O teu plano permite $max grupos. Faz upgrade para criar mais.';
  }

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get profileRankingSubtitle => 'Ver a classificação global';

  @override
  String get eventBroadcastTooltip => 'Transmitir a todos';

  @override
  String get eventBroadcastHint => 'Anúncio para todos os participantes…';

  @override
  String get eventBroadcastLabel => 'Anúncio';

  @override
  String get eventsFeatured => 'Destaque';

  @override
  String get eventsInsufficientCoins => 'Moedas insuficientes';

  @override
  String get eventsConfirmAction => 'Confirmar';

  @override
  String get eventsBoost => 'Destacar';

  @override
  String get eventsBoosted => 'Evento destacado!';

  @override
  String eventsJoinForCoins(int cost) {
    return 'Participar neste evento por $cost moedas?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Destacar este evento por $cost moedas durante 7 dias?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Até $count membros por grupo';
  }

  @override
  String get eventsPriceHint => 'Preço (1–1000)';

  @override
  String get eventsPriceRange => 'Introduz um preço entre 1 e 1000';

  @override
  String get eventsLinkLabelHint => 'Rótulo (opcional)';

  @override
  String get eventsPickLocation => 'Escolher local';

  @override
  String get eventsSearchAddress => 'Procurar morada';

  @override
  String get eventsUseThisLocation => 'Usar este local';

  @override
  String get eventsEditEvent => 'Editar evento';

  @override
  String get groupEditName => 'Editar nome do grupo';

  @override
  String get groupChangePhoto => 'Alterar foto do grupo';

  @override
  String get groupUploadingPhoto => 'Enviando foto…';

  @override
  String get groupPhotoUpdated => 'Foto do grupo atualizada';

  @override
  String get groupPhotoUpdateFailed => 'Falha ao atualizar a foto do grupo';

  @override
  String get eventTextProhibited =>
      'O título ou a descrição contém linguagem proibida e não pode ser usado';

  @override
  String get groupSearchHint => 'Pesquisar grupos';

  @override
  String get groupNoSearchResults => 'Nenhum grupo encontrado';

  @override
  String get groupMyTags => 'As minhas tags';

  @override
  String get groupMyTagsSubtitle => 'Privadas — só tu as vês';

  @override
  String get groupNoTagsYet => 'Ainda sem tags';

  @override
  String get groupTagsEditTitle => 'Editar as minhas tags';

  @override
  String get groupAddTagHint => 'Adicionar uma tag';

  @override
  String get groupTagsSave => 'Guardar';

  @override
  String get groupTagsSaved => 'Tags guardadas';

  @override
  String get groupTagsSaveFailed => 'Não foi possível guardar as tags';

  @override
  String get groupTagsLimitReached => 'Limite de tags atingido';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tags para $name';
  }

  @override
  String get groupTranslationSettings => 'Tradução';

  @override
  String get groupTranslateMessages => 'Traduzir mensagens';

  @override
  String get groupShowOriginal => 'Mostrar texto original';

  @override
  String get eventsTabLiveEvents => 'Eventos ao vivo';

  @override
  String get globeLayerLiveEvents => 'Eventos ao vivo';

  @override
  String get eventsSortBy => 'Ordenar por';

  @override
  String get eventsSortDistance => 'Distância';

  @override
  String get eventsSortStars => 'Estrelas';

  @override
  String get eventsSortReviews => 'Avaliações';

  @override
  String get eventsSortDate => 'Data';

  @override
  String get catMuseums => 'Museus';

  @override
  String get catSights => 'Pontos turísticos';

  @override
  String get catParks => 'Parques';

  @override
  String get catNationalParks => 'Parques nacionais';

  @override
  String get catThemeParks => 'Parques temáticos';

  @override
  String get catTours => 'Passeios e turismo';

  @override
  String get catCulture => 'Cultura e museus';

  @override
  String get catFoodDrink => 'Comida e bebida';

  @override
  String get catCruises => 'Cruzeiros e água';

  @override
  String get catNature => 'Natureza e ar livre';

  @override
  String get catDayTrips => 'Passeios de um dia';

  @override
  String get catTickets => 'Ingressos e passes';

  @override
  String get catOther => 'Outros';

  @override
  String get eventsUnlimited => 'Ilimitado';

  @override
  String get eventsTabGoing => 'Vou';

  @override
  String get globeLayerCommunityEvents => 'Eventos da comunidade';

  @override
  String get webMapUnavailableTitle =>
      'Mapa interativo disponível na aplicação móvel';

  @override
  String get webMapUnavailableBody =>
      'Pesquisa um endereço para definir a tua localização.';

  @override
  String get webLocationPickerTitle => 'Escolhe a tua localização';

  @override
  String get webLocationSearchHint => 'Pesquisar cidade ou endereço';

  @override
  String get webLocationConfirm => 'Usar esta localização';

  @override
  String get webLocationTapHint => 'Toca no mapa para colocar um marcador';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'Podes atualizar a tua localização uma vez por mês na web. Próxima atualização disponível em $date.';
  }

  @override
  String get eventMyTicket => 'O meu bilhete';

  @override
  String get eventScanCheckIn => 'Digitalizar / Check-in';

  @override
  String get eventAttendance => 'Presença';

  @override
  String get eventCheckedIn => 'Check-in feito';

  @override
  String get eventNotCheckedIn => 'Ainda não chegou';

  @override
  String get eventGuestsAllowedLabel =>
      'Convidados permitidos por participante';

  @override
  String get eventBringGuests => 'Levar convidados';

  @override
  String get eventInvalidTicket => 'Bilhete inválido para este evento';

  @override
  String get eventScanInstructions =>
      'Aponta a câmara para o código QR de um participante';

  @override
  String get eventTotalHeadcount => 'Total de presentes';

  @override
  String get eventCameraPermission =>
      'É necessária permissão da câmara para digitalizar';

  @override
  String get eventTicketSubtitle => 'Mostra este QR à entrada';

  @override
  String eventGuestCount(int count, int max) {
    return '$count de $max convidados';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name fez check-in';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name já fez check-in';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count convidados';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'Atingiste o teu limite diário de $limit novas ligações. Faz upgrade para te ligares a mais pessoas!';
  }

  @override
  String get boostFeatureName => 'Impulso de Perfil';

  @override
  String get boostRequiresTierDescription =>
      'Os impulsos de perfil são um benefício de subscrição paga. Faz upgrade do teu plano para impulsionar o teu perfil e seres visto por mais pessoas.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'Já usaste todos os $limit impulsos de perfil incluídos no teu plano este mês. Faz upgrade para mais.';
  }

  @override
  String get travelModeFeatureName => 'Modo Viajante';

  @override
  String get travelModeRequiresTierDescription =>
      'O Modo Viajante permite-te aparecer no feed de descoberta de outra cidade. Faz upgrade do teu plano para o desbloquear.';

  @override
  String get exploreRecommended => 'Recomendado para ti';

  @override
  String get businessAccountTitle => 'Conta empresarial';

  @override
  String get becomeBusiness => 'Tornar-te uma empresa';

  @override
  String get businessProfileLabel => 'Perfil empresarial';

  @override
  String get businessCategoryLabel => 'Categoria da empresa';

  @override
  String get businessCategoryHint => 'Selecione uma categoria';

  @override
  String get businessVerifiedLabel => 'Empresa verificada';

  @override
  String get featureThisEvent => 'Destacar este evento';

  @override
  String featureEventCostLabel(int cost) {
    return 'Destacar este evento · $cost moedas';
  }

  @override
  String featureEventActive(String date) {
    return 'Em destaque até $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Destacar este evento por $cost moedas?';
  }

  @override
  String get referralTitle => 'Convidar amigos';

  @override
  String get referralInviteFriends => 'Convidar amigos';

  @override
  String get referralYourCode => 'O teu código de referência';

  @override
  String get referralShareCta => 'Partilhar';

  @override
  String get referralShareMessage => 'Junta-te a mim no GreenGo!';

  @override
  String get referralRewardEarned => 'Moedas ganhas';

  @override
  String get referralCountLabel => 'Amigos convidados';

  @override
  String get referralHowItWorks =>
      'Partilha o teu código — quando um amigo se junta com ele, ganham ambos moedas.';

  @override
  String get streakTitle => 'Sequência';

  @override
  String get streakDaysLabel => 'dias de sequência';

  @override
  String get streakKeepGoing => 'Continua assim!';

  @override
  String get missionsTitle => 'Missões';

  @override
  String get missionsSubtitle => 'Completa missões para ganhar moedas';

  @override
  String get missionProgressLabel => 'Progresso';

  @override
  String get missionRewardLabel => 'Recompensa';

  @override
  String get missionCompleteLabel => 'Concluída';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Descobre culturas, pratica idiomas, encontra eventos locais e conhece pessoas perto de ti — sem barreiras linguísticas.';

  @override
  String get onboardingPickInterests => 'O que adoras?';

  @override
  String get onboardingPickLanguages => 'Idiomas que falas';

  @override
  String get savedSearchesTitle => 'Pesquisas guardadas';

  @override
  String get saveThisSearch => 'Guardar esta pesquisa';

  @override
  String get savedSearchSaved => 'Pesquisa guardada';

  @override
  String get savedSearchRun => 'Executar';

  @override
  String get savedSearchEmpty => 'Ainda sem pesquisas guardadas';

  @override
  String get savedSearchAlertsToggle => 'Alertas';

  @override
  String get exploreFeaturedCommunity => 'Eventos da comunidade em destaque';

  @override
  String get notificationMarkAllRead => 'Marcar tudo como lido';

  @override
  String get analyticsTitle => 'Estatísticas';

  @override
  String get analyticsPlatinumOnly =>
      'As estatísticas são uma funcionalidade Platinum.';

  @override
  String get analyticsEventsHosted => 'Eventos organizados';

  @override
  String get analyticsTotalAttendees => 'Total de participantes';

  @override
  String get analyticsReach => 'Alcance';

  @override
  String get analyticsUpgradeCta => 'Faz upgrade para Platinum';

  @override
  String get safetyVerifiedBadge => 'Verificado';

  @override
  String get safetyReportUser => 'Denunciar';

  @override
  String get safetyBlockUser => 'Bloquear';

  @override
  String get safetyCheckInTitle => 'Check-in de segurança';

  @override
  String get safetyCheckInArrived => 'Cheguei em segurança';

  @override
  String get safetyCheckInDone => 'Fizeste check-in em segurança';

  @override
  String get guidelinesTitle => 'Diretrizes da comunidade';

  @override
  String get guidelinesAccept => 'Concordo';

  @override
  String get guidelinesBody =>
      'O GreenGo é uma comunidade intercultural para descoberta, intercâmbio de idiomas, eventos locais e amizade. Sê respeitoso e acolhedor com pessoas de todas as culturas. Isto não é uma app de encontros. Não são permitidos assédio, discurso de ódio, spam nem conteúdo explícito. Denuncia tudo o que não pertença aqui.';

  @override
  String get businessSectionTitle => 'Empresa';

  @override
  String get businessSectionSubtitle => 'Ferramentas para o teu negócio';

  @override
  String get businessHubAccount => 'Conta empresarial';

  @override
  String get businessHubAnalytics => 'Estatísticas';

  @override
  String get businessHubFeatured => 'Destaques';

  @override
  String get becomeBusinessAction => 'Tornar-te uma';

  @override
  String get becomeBusinessPermanentHint =>
      'Upgrade único. Não pode ser revertido.';

  @override
  String get becomeBusinessConfirmTitle => 'Tornar-te numa conta empresarial?';

  @override
  String get becomeBusinessConfirmMessage =>
      'Isto é permanente — a tua conta torna-se uma conta empresarial pública e não pode ser revertida.';

  @override
  String get becomeBusinessConfirmAction => 'Tornar permanente';

  @override
  String get becomeBusinessSuccess =>
      'A tua conta é agora uma conta empresarial.';

  @override
  String get becomeBusinessError =>
      'Não foi possível alterar a tua conta. Tenta novamente.';

  @override
  String get businessAccountActive => 'Conta empresarial ativa (permanente)';

  @override
  String get businessRequiresPlatinum =>
      'As contas empresariais são uma funcionalidade Platinum. Faz upgrade para desbloquear a tua montra, seguidores e captação de contactos.';

  @override
  String get viewStorefront => 'Ver montra';

  @override
  String get requestVerification => 'Pedir verificação';

  @override
  String get requestVerificationPending => 'Verificação pendente';

  @override
  String get requestVerificationTitle => 'Pedir verificação';

  @override
  String get verifyBusinessNameLabel => 'Nome da empresa';

  @override
  String get verifyLegalNameLabel => 'Nome legal';

  @override
  String get verifyLegalNameHint => 'Razao social registrada';

  @override
  String get verifyPhoneLabel => 'Numero de telefone';

  @override
  String get verifyPhoneHint => '+55 11 91234-5678';

  @override
  String get verifySendCode => 'Enviar codigo';

  @override
  String get verifyResendCode => 'Reenviar';

  @override
  String get verifyEnterCodeLabel => 'Codigo de 6 digitos';

  @override
  String get verifyConfirmCode => 'Verificar';

  @override
  String get verifyPhoneVerified => 'Telefone verificado';

  @override
  String get verifyOwnerDocumentLabel =>
      'Documento de identidade do proprietario';

  @override
  String get verifyUploadDocument => 'Enviar documento';

  @override
  String get verifyDocumentUploaded => 'Documento enviado';

  @override
  String get verifyDocumentUploadError =>
      'Nao foi possivel enviar o documento. Tente novamente.';

  @override
  String get verifyWebsiteLabel => 'Site (opcional)';

  @override
  String get verifyWebsiteHint => 'https://exemplo.com';

  @override
  String get verifyNotesLabel => 'Notas (opcional)';

  @override
  String get verifyMissingFields =>
      'Preencha todos os campos obrigatorios e verifique seu telefone.';

  @override
  String get requestVerificationMessage =>
      'Conta-nos um pouco sobre o teu negócio para o podermos verificar. A nossa equipa irá rever o teu pedido.';

  @override
  String get requestVerificationNoteHint =>
      'Adiciona uma nota (site, morada, tudo o que nos ajude a verificar-te)';

  @override
  String get requestVerificationSubmitted => 'Pedido de verificação enviado.';

  @override
  String get requestVerificationError =>
      'Não foi possível enviar o teu pedido. Tenta novamente.';

  @override
  String get submit => 'Enviar';

  @override
  String get businessVerifiedBadgeTooltip => 'Empresa verificada';

  @override
  String get businessLinks => 'Ligações';

  @override
  String get businessOpeningHours => 'Horário de funcionamento';

  @override
  String get businessHoursNotProvided =>
      'Horário de funcionamento não fornecido';

  @override
  String get businessGallery => 'Galeria';

  @override
  String get businessUpcomingEvents => 'Próximos eventos';

  @override
  String get businessNoUpcomingEvents => 'Ainda não há próximos eventos.';

  @override
  String get businessCommunities => 'Comunidades';

  @override
  String get businessNoCommunities => 'Ainda não há comunidades.';

  @override
  String get businessContact => 'Contacto';

  @override
  String get businessFollow => 'Seguir';

  @override
  String get businessFollowing => 'A seguir';

  @override
  String get businessFollowError =>
      'Não foi possível atualizar o seguir. Tenta novamente.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seguidores',
      one: '1 seguidor',
      zero: 'Sem seguidores',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
      zero: 'Sem membros',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Verificações de Empresas';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Rever e aprovar distintivos de empresa verificada';

  @override
  String get adminApproveBusinessVerification => 'Aprovar';

  @override
  String get adminRejectBusinessVerification =>
      'Rejeitar Verificação de Empresa';

  @override
  String get adminBusinessRejectReasonHint => 'Motivo da rejeição (opcional)';

  @override
  String get adminBusinessApproved => 'Empresa verificada';

  @override
  String get adminBusinessRejected => 'Verificação de empresa rejeitada';

  @override
  String get adminNoPendingBusinessVerifications =>
      'Nenhuma verificação de empresa pendente';

  @override
  String get adminAccessDenied => 'Acesso negado. Apenas administradores.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'A tua empresa está verificada';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'A tua empresa mostra agora o distintivo de verificação dourado.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Enviado $date';
  }

  @override
  String get communitiesSponsored => 'Patrocinado';

  @override
  String get communitiesSponsorThisCommunity => 'Patrocinar esta comunidade';

  @override
  String get communitiesSponsorSubtitle =>
      'Fixa uma promoção no topo para os membros';

  @override
  String get communitiesSponsorFeatureName => 'Patrocínio de comunidade';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Patrocinar uma comunidade e fixar uma promoção é uma funcionalidade empresarial Platinum.';

  @override
  String get communitiesEditSponsorship => 'Editar patrocínio e promoção';

  @override
  String get communitiesMarkAsSponsored => 'Marcar como patrocinado';

  @override
  String get communitiesPromoTitleLabel => 'Título da promoção';

  @override
  String get communitiesPromoTitleHint =>
      'ex. 20% de desconto este fim de semana';

  @override
  String get communitiesPromoBodyLabel => 'Mensagem da promoção';

  @override
  String get communitiesPromoBodyHint => 'Fala aos membros sobre a tua oferta';

  @override
  String get communitiesPromoImageLabel => 'URL da imagem (opcional)';

  @override
  String get communitiesPromoLinkEventLabel =>
      'ID do evento associado (opcional)';

  @override
  String get communitiesPromoLinkUrlLabel => 'URL do link (opcional)';

  @override
  String get communitiesPromoTitleRequired =>
      'Introduz um título para a promoção';

  @override
  String get communitiesSaveSponsorship => 'Guardar';

  @override
  String get communitiesRemovePromo => 'Remover promoção';

  @override
  String get exploreSearchTooltip => 'Pesquisar';

  @override
  String get exploreQrTooltip => 'Os meus códigos QR';

  @override
  String get universalSearchTitle => 'Pesquisar';

  @override
  String get universalSearchHint => 'Pesquisar pessoas e eventos';

  @override
  String get universalSearchTabPeople => 'Pessoas';

  @override
  String get universalSearchTabEvents => 'Eventos';

  @override
  String get universalSearchEmptyPrompt =>
      'Encontra pessoas para conversar e eventos para participar';

  @override
  String get universalSearchNoPeople => 'Nenhuma pessoa encontrada';

  @override
  String get universalSearchNoEvents => 'Nenhum evento encontrado';

  @override
  String get qrHubTitle => 'Códigos QR';

  @override
  String get qrHubTabMyTickets => 'Os meus bilhetes';

  @override
  String get qrHubTabScan => 'Digitalizar';

  @override
  String get qrHubNoTickets =>
      'Ainda não há bilhetes futuros. Participa num evento para obteres o teu código QR.';

  @override
  String get qrHubTicketHint =>
      'Toca num bilhete para abrir o seu código QR completo';

  @override
  String get qrHubScanInstructions =>
      'Aponta a câmara para um código QR do GreenGo';

  @override
  String get qrHubInvalidCode => 'Este não é um código GreenGo válido';

  @override
  String get qrHubJoinedEvent => 'Vais participar! A abrir o evento…';

  @override
  String get eventsRepeats => 'Repete';

  @override
  String get eventsRepeatNone => 'Não repete';

  @override
  String get eventsRepeatDaily => 'Diariamente';

  @override
  String get eventsRepeatWeekly => 'Semanalmente';

  @override
  String get eventsRepeatMonthly => 'Mensalmente';

  @override
  String get eventsRepeatInterval => 'A cada';

  @override
  String get eventsRepeatCount => 'Ocorrências';

  @override
  String get eventsRecurringLabel => 'Recorrente';

  @override
  String get eventsCancelSeries => 'Cancelar toda a série';

  @override
  String get eventsCancelSeriesConfirm =>
      'Cancelar todas as ocorrências futuras deste evento recorrente?';

  @override
  String get eventsSeriesCancelled => 'Série cancelada';

  @override
  String get eventsSeriesCancelError => 'Não foi possível cancelar a série';

  @override
  String get eventsSaveAsDraft => 'Guardar como rascunho';

  @override
  String get eventsSchedule => 'Agendar';

  @override
  String get eventsStatusDraft => 'Rascunho';

  @override
  String get eventsStatusScheduled => 'Agendado';

  @override
  String get eventsStatusCancelled => 'Cancelado';

  @override
  String eventsScheduledForDate(String date) {
    return 'Agendado para $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Até $max ocorrências';
  }

  @override
  String get eventsTicketTiers => 'Tipos de bilhete';

  @override
  String get eventsAddTier => 'Adicionar tipo';

  @override
  String get eventsTierName => 'Nome do tipo';

  @override
  String get eventsTierPriceCoins => 'Preço (moedas, 0 = grátis)';

  @override
  String get eventsTierCapacity => 'Capacidade (0 = ilimitado)';

  @override
  String get eventsFreeTier => 'Grátis';

  @override
  String get eventsSelectTier => 'Seleciona um bilhete';

  @override
  String get eventsJoinWaitlist => 'Entrar na lista de espera';

  @override
  String get eventsOnWaitlist => 'Na lista de espera';

  @override
  String eventsWaitlistPosition(int position) {
    return 'És o #$position na lista de espera';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins moedas';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity lugares';
  }

  @override
  String get eventsRsvpError => 'Não foi possível atualizar a tua confirmação';

  @override
  String get shareProfileTooltip => 'Partilhar perfil';

  @override
  String shareProfileMessage(String link) {
    return 'Fala comigo no GreenGo: $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Vê este evento no GreenGo: $link';
  }

  @override
  String get guidelinesSubtitle =>
      'Uma breve introdução à forma como nos ligamos aqui';

  @override
  String get guidelinesWelcomeTitle => 'Bem-vindo entre culturas';

  @override
  String get guidelinesWelcomeDesc =>
      'Conhece pessoas de todo o lado e partilha o teu mundo com abertura.';

  @override
  String get guidelinesRespectTitle => 'Respeita toda a gente';

  @override
  String get guidelinesRespectDesc =>
      'Simpatia e curiosidade primeiro — trata os outros como gostarias de ser tratado.';

  @override
  String get guidelinesAuthenticTitle => 'Sê autêntico';

  @override
  String get guidelinesAuthenticDesc =>
      'O GreenGo é para ligações culturais genuínas — não é uma app de encontros.';

  @override
  String get guidelinesSafetyTitle => 'Sem assédio nem ódio';

  @override
  String get guidelinesSafetyDesc =>
      'Assédio, discurso de ódio e ameaças não têm lugar aqui.';

  @override
  String get guidelinesNoSpamTitle => 'Sem spam nem conteúdo explícito';

  @override
  String get guidelinesNoSpamDesc =>
      'Mantém tudo limpo — sem spam, burlas ou conteúdo sexual.';

  @override
  String get guidelinesReportTitle => 'Denuncia o que estiver errado';

  @override
  String get guidelinesReportDesc =>
      'Vês algo estranho? Denuncia e a nossa equipa vai analisar.';

  @override
  String get businessNewBadge => 'NOVO';

  @override
  String get businessLeadsTitle => 'Contactos';

  @override
  String get businessLeadsEmpty =>
      'Ainda não há contactos. As pessoas que te contactam ou guardam os teus eventos aparecem aqui.';

  @override
  String get businessLeadContact => 'Contactou-te';

  @override
  String get businessLeadSavedEvent => 'Guardou o teu evento';

  @override
  String get eventTicketWhen => 'Quando';

  @override
  String get eventTicketVenue => 'Local';

  @override
  String get eventTicketWhere => 'Onde';

  @override
  String get eventTicketGuestsLabel => 'Convidados';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admite $count pessoas',
      one: 'Admite 1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Partilhar evento';

  @override
  String get promoteTitle => 'Promover';

  @override
  String get promoteSubtitle => 'Aumenta a tua visibilidade com GreenGoCoins';

  @override
  String get promoteBusinessOption => 'Promover negócio';

  @override
  String get promoteBusinessDesc => 'Destaca a tua montra no topo do Explorar';

  @override
  String get promoteEventsOption => 'Promover um evento';

  @override
  String get promoteEventsDesc => 'Destaca um dos teus eventos na descoberta';

  @override
  String get promoteChooseDuration => 'Escolhe uma duração';

  @override
  String get promoteNotActive => 'Sem promoção ativa';

  @override
  String get promoteConfirmTitle => 'Confirmar promoção';

  @override
  String get promoteConfirmCta => 'Promover';

  @override
  String get promoteCancel => 'Cancelar';

  @override
  String get promoteSelectEvent => 'Seleciona um evento para destacar';

  @override
  String get promoteNoEvents => 'Não tens eventos futuros para destacar';

  @override
  String get promoteEventAlreadyFeatured => 'Já em destaque';

  @override
  String get promoteSuccess => 'Promoção ativa!';

  @override
  String get promoteError => 'Algo correu mal. Tenta novamente.';

  @override
  String get promoteInsufficientCoins => 'Moedas insuficientes';

  @override
  String get promoteInsufficientCoinsBody =>
      'Não tens moedas suficientes para esta promoção. Carrega para continuar.';

  @override
  String get promoteGetCoins => 'Obter moedas';

  @override
  String promoteDurationDays(int days) {
    return '$days dias';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost moedas';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Promovido até $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Promover o teu negócio durante $days dias por $cost moedas?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Destacar este evento durante $days dias por $cost moedas?';
  }

  @override
  String get audienceSectionTitle => 'Estatísticas do público';

  @override
  String get audiencePrivacyNote =>
      'Agregado e anonimizado — grupos pequenos são ocultados para proteger a privacidade.';

  @override
  String get audienceNotEnoughData =>
      'Ainda não há dados suficientes para mostrar isto protegendo a privacidade.';

  @override
  String get audienceAgeTitle => 'Distribuição por idade';

  @override
  String get audienceCountriesTitle => 'Principais países';

  @override
  String get audienceInterestsTitle => 'Principais interesses';

  @override
  String get eventAnalyticsTitle => 'Estatísticas do evento';

  @override
  String get eventAnalyticsGoing => 'Confirmados';

  @override
  String get eventAnalyticsWaitlist => 'Lista de espera';

  @override
  String get eventAnalyticsCheckedIn => 'Check-in feito';

  @override
  String get eventAnalyticsCheckInRate => 'Taxa de check-in';

  @override
  String get eventAnalyticsTierBreakdown => 'Tipos de bilhete';

  @override
  String get businessEventsTitle => 'Gerir os meus eventos';

  @override
  String get businessEventsEmpty => 'Ainda não criaste nenhum evento.';

  @override
  String get businessEventsAnalytics => 'Estatísticas';

  @override
  String get businessEventsCancelTitle => 'Cancelar evento';

  @override
  String get businessEventsCancelMessage =>
      'Cancelar este evento? Os participantes serão notificados e será removido.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Cancelar todas as ocorrências desta série recorrente?';

  @override
  String get businessEventsCancelConfirm => 'Cancelar evento';

  @override
  String get businessEventsCancelled => 'Evento cancelado';

  @override
  String get businessPausedTitle => 'Negócio em pausa';

  @override
  String get businessPausedSubtitle =>
      'As funcionalidades de negócio estão em pausa porque a tua subscrição Platinum expirou. Renova o Platinum para restaurar a tua montra, estatísticas, contactos e promoções.';

  @override
  String get businessReactivate => 'Renovar Platinum';

  @override
  String get eventsBoostChooseDuration => 'Escolhe a duração do impulso';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'O impulso termina em $time';
  }

  @override
  String get eventBoostEnded => 'Impulso terminado';

  @override
  String get eventsBuyCoins => 'Comprar moedas';

  @override
  String get eventsBuyCoinsPrompt =>
      'Não tens moedas suficientes. Queres comprar mais?';

  @override
  String get messageTooLong => 'As mensagens podem ter até 4096 caracteres.';

  @override
  String get exploreBusinessesNearYou => 'Negócios perto de ti';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Avalia este negócio';

  @override
  String get businessRatingError =>
      'Não foi possível guardar a tua avaliação. Tenta novamente.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Avaliar com $stars estrelas';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Avaliado $avg em 5, $count avaliações';
  }

  @override
  String get editStorefront => 'Editar montra';

  @override
  String get editStorefrontSubtitle =>
      'Gere a tua galeria, horários, ligações e informações';

  @override
  String get storefrontGallerySubtitle =>
      'Mostra o teu espaço, produtos ou equipa';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Define os teus dias e horários de funcionamento';

  @override
  String get storefrontDescriptionHint => 'Fala às pessoas sobre o teu negócio';

  @override
  String get storefrontCategoryHint => 'ex. Restaurante, Café, Museu';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Adicionar ligação';

  @override
  String get storefrontAddImage => 'Adicionar imagem';

  @override
  String get storefrontSaved => 'Montra atualizada';

  @override
  String get analyticsEventViews => 'Visualizações do evento';

  @override
  String get analyticsCommunityReach => 'Alcance na comunidade';

  @override
  String get analyticsChatsInvolved => 'Conversas envolvidas';

  @override
  String get eventAnalyticsViews => 'Visualizações';

  @override
  String get businessHubScanner => 'Leitor rápido';

  @override
  String get businessHubScannerSubtitle =>
      'Lê bilhetes para dar entrada aos participantes';

  @override
  String get businessHubFollowers => 'Seguidores';

  @override
  String get businessHubFollowersSubtitle => 'Vê quem segue o teu negócio';

  @override
  String get businessFollowersTitle => 'Seguidores';

  @override
  String get businessNoFollowers =>
      'Ainda sem seguidores. Partilha a tua montra para aumentar a tua audiência.';

  @override
  String get membershipRequiredTitle => 'Subscrição necessária';

  @override
  String get membershipRequiredBody =>
      'Precisas de uma subscrição ativa para fazer isto. Renova para continuar.';

  @override
  String get renewMembership => 'Renovar subscrição';

  @override
  String get extraEventTitle => 'Evento extra';

  @override
  String extraEventBody(int cost) {
    return 'Atingiste o teu limite de eventos gratuitos. Criar um evento extra por $cost moedas?';
  }

  @override
  String get accountBannedTitle => 'Conta banida permanentemente';

  @override
  String get accountBannedBody =>
      'Esta conta foi banida permanentemente por violar a nossa política de conteúdo. Esta decisão é final.';

  @override
  String get adminBanPermanently => 'Banir permanentemente';

  @override
  String get adminBanConfirm => 'Banir esta conta permanentemente?';

  @override
  String get adminBanConfirmBody =>
      'Isto bane permanentemente a conta e bloqueia todo o acesso. Não pode ser revertido.';

  @override
  String get adminBanReasonHint => 'Motivo (ex. nudez na galeria)';

  @override
  String get adminBanned => 'Conta banida permanentemente';

  @override
  String get storefrontFeaturedImage => 'Featured image';

  @override
  String get storefrontFeaturedImageSubtitle =>
      'The hero banner shown at the top of your storefront.';

  @override
  String get storefrontAddFeaturedImage => 'Add featured image';

  @override
  String get storefrontProfileImage => 'Profile image';

  @override
  String get storefrontProfileImageSubtitle =>
      'Your avatar, shown next to your business name.';

  @override
  String get storefrontAddProfileImage => 'Add profile image';

  @override
  String get storefrontReplaceProfileImage => 'Replace profile image';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get culturalPassportTitle => 'Passaporte Cultural';

  @override
  String get culturalPassportSubtitle =>
      'Carimbos que você coleciona das culturas, idiomas e eventos que explora';

  @override
  String get passportSectionCountries => 'Países';

  @override
  String get passportSectionLanguages => 'Idiomas';

  @override
  String get passportSectionEvents => 'Eventos';

  @override
  String get passportLoading => 'Carregando seu passaporte…';

  @override
  String get passportEarned => 'Conquistado';

  @override
  String get passportLocked => 'Bloqueado';

  @override
  String get passportEmpty =>
      'Comece a conversar, aprender idiomas e participar de eventos para ganhar seus primeiros carimbos.';

  @override
  String passportProgressSummary(int countries, int languages, int events) {
    return '$countries países · $languages idiomas · $events eventos';
  }

  @override
  String passportOverallProgress(int percent) {
    return '$percent% explorado';
  }

  @override
  String get passportEventDating => 'Encontros';

  @override
  String get passportEventSocial => 'Social';

  @override
  String get passportEventSports => 'Esportes';

  @override
  String get passportEventFood => 'Comida';

  @override
  String get passportEventNightlife => 'Vida noturna';

  @override
  String get passportEventOutdoor => 'Ao ar livre';

  @override
  String get passportEventArts => 'Artes';

  @override
  String get passportEventGaming => 'Jogos';

  @override
  String get passportEventTravel => 'Viagens';

  @override
  String get passportEventWellness => 'Bem-estar';

  @override
  String get passportEventLanguageExchange => 'Intercâmbio de idiomas';

  @override
  String get passportEventOther => 'Outro';

  @override
  String get tourGotIt => 'Entendi';

  @override
  String get tourWelcomeTitle => 'Bem-vindo ao GreenGo!';

  @override
  String get tourWelcomeDesc =>
      'Esta é a sua grade de Descoberta: pessoas reais perto de você, ordenadas por distância. Vamos aprender os gestos que tornam o GreenGo rápido de usar.';

  @override
  String get tourCardTapTitle => 'Toque em um cartão';

  @override
  String get tourCardTapDesc =>
      'Toque no centro de um cartão para abrir o menu de ações: curtir, super curtir ou ver o perfil completo.';

  @override
  String get tourCardEdgeTitle => 'Veja as fotos';

  @override
  String get tourCardEdgeDesc =>
      'Toque na borda esquerda ou direita de um cartão para passar as fotos da pessoa sem sair da grade.';

  @override
  String get tourCardHoldTitle => 'Segure para visualizar';

  @override
  String get tourCardHoldDesc =>
      'Mantenha um cartão pressionado para ver as fotos em tela cheia.';

  @override
  String get tourRefreshTitle => 'Puxe para atualizar';

  @override
  String get tourRefreshDesc =>
      'Arraste a grade para baixo a qualquer momento para carregar as pessoas mais recentes perto de você.';

  @override
  String get tourModeToggleTitle => 'Modo swipe';

  @override
  String get tourModeToggleDesc =>
      'Toque aqui para alternar entre grade e modo swipe. No modo swipe: deslize para a direita para curtir, para a esquerda para passar, para cima para super curtir.';

  @override
  String get tourGlobeTitle => 'Explore o globo';

  @override
  String get tourGlobeDesc =>
      'Abra o globo 3D para descobrir pessoas do mundo todo, não apenas por perto.';

  @override
  String get tourSearchTitle => 'Busque por apelido';

  @override
  String get tourSearchDesc =>
      'Sabe quem está procurando? Encontre pessoas diretamente pelo apelido.';

  @override
  String get tourPrefsTitle => 'Filtros de descoberta';

  @override
  String get tourPrefsDesc =>
      'Ajuste quem você descobre: distância, idade, idiomas, país e mais.';

  @override
  String get tourCoinsTitle => 'Suas moedas';

  @override
  String get tourCoinsDesc =>
      'Você recebe moedas grátis todos os dias. Toque no seu saldo a qualquer momento para abrir a Loja.';

  @override
  String get tourHelpTitle => 'Precisa relembrar?';

  @override
  String get tourHelpDesc =>
      'O guia do app fica aqui — incluindo este tutorial, que você pode repetir quando quiser.';

  @override
  String get tourNavMessagesTitle => 'Mensagens';

  @override
  String get tourNavMessagesDesc =>
      'Converse sem barreiras de idioma: segure uma mensagem para traduzi-la, toque duas vezes para ouvi-la.';

  @override
  String get tourNavLeaderboardTitle => 'Ranking';

  @override
  String get tourNavLeaderboardDesc =>
      'Ganhe XP e medalhas enquanto se conecta, conversa e aprende. Veja sua posição.';

  @override
  String get tourNavShopTitle => 'Loja';

  @override
  String get tourNavShopDesc =>
      'Pacotes de moedas e assinaturas para desbloquear mais do GreenGo.';

  @override
  String get tourNavProfileTitle => 'Seu perfil';

  @override
  String get tourNavProfileDesc =>
      'Complete seu perfil e a verificação para ser descoberto por mais pessoas.';

  @override
  String get tourFinishTitle => 'Tudo pronto!';

  @override
  String get tourFinishDesc =>
      'Divirta-se descobrindo novas pessoas e culturas. Você pode repetir este tutorial a qualquer momento no guia (ícone ?).';

  @override
  String get tourSwipeHintTitle => 'Deslize para se conectar';

  @override
  String get tourSwipeHintLike => 'Curtir';

  @override
  String get tourSwipeHintPass => 'Passar';

  @override
  String get tourSwipeHintSuper => 'Super curtir';

  @override
  String get tourChatHoldTitle => 'Segure uma mensagem';

  @override
  String get tourChatHoldDesc =>
      'Mantenha qualquer mensagem pressionada para traduzir, copiar ou encaminhar.';

  @override
  String get tourChatDoubleTapTitle => 'Ouça a mensagem';

  @override
  String get tourChatDoubleTapDesc =>
      'Toque duas vezes em uma mensagem recebida para ouvir a pronúncia.';

  @override
  String get tourChatLanguageTitle => 'Idiomas e aprendizado';

  @override
  String get tourChatLanguageDesc =>
      'Abra o menu de tradução para ferramentas de idioma: configurações de tradução, prática de pronúncia e recursos de aprendizado.';

  @override
  String get tourChatSettingsTitle => 'Opções da conversa';

  @override
  String get tourChatSettingsDesc =>
      'Gerencie esta conversa: configurações da conversa, excluir, bloquear ou denunciar.';

  @override
  String get tourDetailDoubleTapTitle => 'Curta uma foto';

  @override
  String get tourDetailDoubleTapDesc =>
      'Toque duas vezes em qualquer foto para curti-la.';

  @override
  String get tourStoryHoldHint => 'Segure para pausar';

  @override
  String get guideReplayTour => 'Repetir tutorial';

  @override
  String get abandonGame => 'Abandonar Jogo';

  @override
  String get about => 'Sobre';

  @override
  String get aboutMe => 'Sobre Mim';

  @override
  String get aboutMeTitle => 'Sobre mim';

  @override
  String get academicCategory => 'Acadêmico';

  @override
  String get acceptPrivacyPolicy => 'Li e aceito a Política de Privacidade';

  @override
  String get acceptProfiling =>
      'Consinto com o perfilamento para recomendações personalizadas';

  @override
  String get acceptTermsAndConditions => 'Li e aceito os Termos e Condições';

  @override
  String get acceptThirdPartyData =>
      'Consinto com o compartilhamento dos meus dados com terceiros';

  @override
  String get accessGranted => 'Acesso Concedido!';

  @override
  String accessGrantedBody(Object tierName) {
    return 'O GreenGo está ativo! Como $tierName, você agora tem acesso total a todas as funcionalidades.';
  }

  @override
  String get accountApproved => 'Conta Aprovada';

  @override
  String get accountApprovedBody =>
      'Sua conta GreenGo foi aprovada. Bem-vindo à comunidade!';

  @override
  String get accountCreatedSuccess =>
      'Conta criada! Por favor verifique seu e-mail para validar sua conta.';

  @override
  String get accountPendingApproval => 'Conta Pendente de Aprovação';

  @override
  String get accountRejected => 'Conta Rejeitada';

  @override
  String get accountSettings => 'Configurações da Conta';

  @override
  String get accountUnderReview => 'Conta em Revisão';

  @override
  String achievementProgressLabel(String current, String total) {
    return '$current/$total';
  }

  @override
  String get achievements => 'Conquistas';

  @override
  String get achievementsSubtitle => 'Veja suas conquistas e progresso';

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String get addBio => 'Adicionar biografia';

  @override
  String get addDealBreakerTitle => 'Adicionar Criterio Eliminatorio';

  @override
  String get addPhoto => 'Adicionar Foto';

  @override
  String get adjustPreferences => 'Ajustar Preferências';

  @override
  String get admin => 'Admin';

  @override
  String admin2faCodeSent(String email) {
    return 'Código enviado para $email';
  }

  @override
  String get admin2faExpired => 'Código expirado. Solicite um novo.';

  @override
  String get admin2faInvalidCode => 'Código de verificação inválido';

  @override
  String get admin2faMaxAttempts =>
      'Muitas tentativas. Solicite um novo código.';

  @override
  String get admin2faResend => 'Reenviar Código';

  @override
  String admin2faResendIn(String seconds) {
    return 'Reenviar em ${seconds}s';
  }

  @override
  String get admin2faSending => 'Enviando código...';

  @override
  String get admin2faSignOut => 'Sair';

  @override
  String get admin2faSubtitle =>
      'Digite o código de 6 dígitos enviado para seu email';

  @override
  String get admin2faTitle => 'Verificação Admin';

  @override
  String get admin2faVerify => 'Verificar';

  @override
  String get adminAccessDates => 'Datas de Acesso:';

  @override
  String get adminAccountLockedSuccessfully => 'Conta bloqueada com sucesso';

  @override
  String get adminAccountUnlockedSuccessfully =>
      'Conta desbloqueada com sucesso';

  @override
  String get adminAccountsCannotBeDeleted =>
      'Contas admin não podem ser excluídas';

  @override
  String adminAchievementCount(Object count) {
    return '$count conquistas';
  }

  @override
  String get adminAchievementUpdated => 'Conquista atualizada';

  @override
  String get adminAchievements => 'Conquistas';

  @override
  String get adminAchievementsSubtitle => 'Gerenciar conquistas e distintivos';

  @override
  String get adminActive => 'ATIVO';

  @override
  String adminActiveCount(Object count) {
    return 'Ativos ($count)';
  }

  @override
  String get adminActiveEvent => 'Evento Ativo';

  @override
  String get adminActiveUsers => 'Usuários Ativos';

  @override
  String get adminAdd => 'Adicionar';

  @override
  String get adminAddCoins => 'Adicionar Moedas';

  @override
  String get adminAddPackage => 'Adicionar Pacote';

  @override
  String get adminAddResolutionNote => 'Adicionar nota de resolução...';

  @override
  String get adminAddSingleEmail => 'Adicionar Email Individual';

  @override
  String adminAddedCoinsToUser(Object amount) {
    return 'Adicionadas $amount moedas ao usuário';
  }

  @override
  String adminAddedDate(Object date) {
    return 'Adicionado $date';
  }

  @override
  String get adminAdvancedFilters => 'Filtros Avançados';

  @override
  String adminAgeAndGender(Object age, Object gender) {
    return '$age anos - $gender';
  }

  @override
  String get adminAll => 'Todos';

  @override
  String get adminAllReports => 'Todos os Relatórios';

  @override
  String get adminAmount => 'Valor';

  @override
  String get adminAnalyticsAndReports => 'Análise e Relatórios';

  @override
  String get adminAppSettings => 'Configurações do Aplicativo';

  @override
  String get adminAppSettingsSubtitle => 'Configurações gerais do aplicativo';

  @override
  String get adminApproveSelected => 'Aprovar Selecionados';

  @override
  String get adminAssignToMe => 'Atribuir a mim';

  @override
  String get adminAssigned => 'Atribuído';

  @override
  String get adminAvailable => 'Disponível';

  @override
  String get adminBadge => 'Distintivo';

  @override
  String get adminBaseCoins => 'Moedas Base';

  @override
  String get adminBaseXp => 'XP Base';

  @override
  String adminBonusCoins(Object amount) {
    return '+$amount moedas bônus';
  }

  @override
  String get adminBonusCoinsLabel => 'Moedas Bônus';

  @override
  String adminBonusMinutes(Object minutes) {
    return '+$minutes bônus';
  }

  @override
  String get adminBrowseProfilesAnonymously => 'Navegar em perfis anonimamente';

  @override
  String get adminCanSendMedia => 'Pode Enviar Mídia';

  @override
  String adminChallengeCount(Object count) {
    return '$count desafios';
  }

  @override
  String get adminChallengeCreationComingSoon =>
      'Interface de criação de desafios em breve.';

  @override
  String get adminChallenges => 'Desafios';

  @override
  String get adminChangesSaved => 'Alterações salvas';

  @override
  String get adminChatWithReporter => 'Conversar com o Denunciante';

  @override
  String get adminClear => 'Limpar';

  @override
  String get adminClosed => 'Fechado';

  @override
  String get adminCoinAmount => 'Valor de Moedas';

  @override
  String adminCoinAmountLabel(Object amount) {
    return '$amount Moedas';
  }

  @override
  String get adminCoinCost => 'Custo em Moedas';

  @override
  String get adminCoinManagement => 'Gerenciamento de Moedas';

  @override
  String get adminCoinManagementSubtitle =>
      'Gerenciar pacotes de moedas e saldos de usuários';

  @override
  String get adminCoinPackages => 'Pacotes de Moedas';

  @override
  String get adminCoinReward => 'Recompensa em Moedas';

  @override
  String adminComingSoon(Object route) {
    return '$route em breve';
  }

  @override
  String get adminConfigurationsResetToDefaults =>
      'Configurações redefinidas para padrão. Salve para aplicar.';

  @override
  String get adminConfigureLimitsAndFeatures =>
      'Configurar limites e funcionalidades';

  @override
  String get adminConfigureMilestoneRewards =>
      'Configurar recompensas de marco para logins consecutivos';

  @override
  String get adminCreateChallenge => 'Criar Desafio';

  @override
  String get adminCreateEvent => 'Criar Evento';

  @override
  String get adminCreateNewChallenge => 'Criar Novo Desafio';

  @override
  String get adminCreateSeasonalEvent => 'Criar Evento Sazonal';

  @override
  String get adminCsvFormat => 'Formato CSV:';

  @override
  String get adminCsvFormatDescription =>
      'Um email por linha, ou valores separados por vírgula. As aspas são removidas automaticamente. Emails inválidos são ignorados.';

  @override
  String get adminCurrentBalance => 'Saldo Atual';

  @override
  String get adminDailyChallenges => 'Desafios Diários';

  @override
  String get adminDailyChallengesSubtitle =>
      'Configurar desafios diários e recompensas';

  @override
  String get adminDailyLimits => 'Limites Diários';

  @override
  String get adminDailyLoginRewards => 'Recompensas de Login Diário';

  @override
  String get adminDailyMessages => 'Mensagens Diárias';

  @override
  String get adminDailySuperLikes => 'Conexões Prioritárias Diárias';

  @override
  String get adminDailySwipes => 'Swipes Diários';

  @override
  String get adminDashboard => 'Painel de Administração';

  @override
  String get adminDate => 'Data';

  @override
  String adminDeletePackageConfirm(Object amount) {
    return 'Tem certeza que deseja excluir o pacote \"$amount Moedas\"?';
  }

  @override
  String get adminDeletePackageTitle => 'Excluir Pacote?';

  @override
  String get adminDescription => 'Descrição';

  @override
  String get adminDeselectAll => 'Desmarcar todos';

  @override
  String get adminDisabled => 'Desativado';

  @override
  String get adminDismiss => 'Ignorar';

  @override
  String get adminDismissReport => 'Ignorar Denúncia';

  @override
  String get adminDismissReportConfirm =>
      'Tem certeza que deseja ignorar esta denúncia?';

  @override
  String get adminEarlyAccessDate => '14 de março de 2026';

  @override
  String get adminEarlyAccessDates =>
      'Os usuários nesta lista obtêm acesso em 14 de março de 2026.';

  @override
  String get adminEarlyAccessInList => 'Acesso Antecipado (na lista)';

  @override
  String get adminEarlyAccessInfo => 'Informação de Acesso Antecipado';

  @override
  String get adminEarlyAccessList => 'Lista de Acesso Antecipado';

  @override
  String get adminEarlyAccessProgram => 'Programa de Acesso Antecipado';

  @override
  String get adminEditAchievement => 'Editar Conquista';

  @override
  String adminEditItem(Object name) {
    return 'Editar $name';
  }

  @override
  String adminEditMilestone(Object name) {
    return 'Editar $name';
  }

  @override
  String get adminEditPackage => 'Editar Pacote';

  @override
  String adminEmailAddedToEarlyAccess(Object email) {
    return '$email adicionado à lista de acesso antecipado';
  }

  @override
  String adminEmailCount(Object count) {
    return '$count emails';
  }

  @override
  String get adminEmailList => 'Lista de Emails';

  @override
  String adminEmailRemovedFromEarlyAccess(Object email) {
    return '$email removido da lista de acesso antecipado';
  }

  @override
  String get adminEnableAdvancedFilteringOptions =>
      'Ativar opções de filtragem avançada';

  @override
  String get adminEngagementReports => 'Relatórios de Engajamento';

  @override
  String get adminEngagementReportsSubtitle =>
      'Ver estatísticas de compatibilidade e mensagens';

  @override
  String get adminEnterEmailAddress => 'Inserir endereço de email';

  @override
  String get adminEnterValidAmount => 'Por favor, insira um valor válido';

  @override
  String get adminEnterValidCoinAmountAndPrice =>
      'Por favor, insira valor de moedas e preço válidos';

  @override
  String adminErrorAddingEmail(Object error) {
    return 'Erro ao adicionar email: $error';
  }

  @override
  String adminErrorLoadingContext(Object error) {
    return 'Erro ao carregar contexto: $error';
  }

  @override
  String adminErrorLoadingData(Object error) {
    return 'Erro ao carregar dados: $error';
  }

  @override
  String adminErrorOpeningChat(Object error) {
    return 'Erro ao abrir conversa: $error';
  }

  @override
  String adminErrorRemovingEmail(Object error) {
    return 'Erro ao remover email: $error';
  }

  @override
  String adminErrorSnapshot(Object error) {
    return 'Erro: $error';
  }

  @override
  String adminErrorUploadingFile(Object error) {
    return 'Erro ao carregar arquivo: $error';
  }

  @override
  String get adminErrors => 'Erros:';

  @override
  String get adminEventCreationComingSoon =>
      'Interface de criação de eventos em breve.';

  @override
  String get adminEvents => 'Eventos';

  @override
  String adminFailedToSave(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get adminFeatures => 'Funcionalidades';

  @override
  String get adminFilterByInterests => 'Filtrar por interesses';

  @override
  String get adminFilterBySpecificLocation =>
      'Filtrar por localização específica';

  @override
  String get adminFilterBySpokenLanguages => 'Filtrar por idiomas falados';

  @override
  String get adminFilterByVerificationStatus =>
      'Filtrar por status de verificação';

  @override
  String get adminFilterOptions => 'Opções de Filtro';

  @override
  String get adminGamification => 'Gamificação';

  @override
  String get adminGamificationAndRewards => 'Gamificação e Recompensas';

  @override
  String get adminGeneralAccess => 'Acesso Geral';

  @override
  String get adminGeneralAccessDate => '14 de abril de 2026';

  @override
  String get adminHigherPriorityDescription =>
      'Prioridade mais alta = mostrado primeiro na descoberta';

  @override
  String get adminImportResult => 'Resultado da Importação';

  @override
  String get adminInProgress => 'Em Andamento';

  @override
  String get adminIncognitoMode => 'Modo Incógnito';

  @override
  String get adminInterestFilter => 'Filtro de Interesses';

  @override
  String get adminInvoices => 'Faturas';

  @override
  String get adminLanguageFilter => 'Filtro de Idioma';

  @override
  String get adminLoading => 'Carregando...';

  @override
  String get adminLocationFilter => 'Filtro de Localização';

  @override
  String get adminLockAccount => 'Bloquear Conta';

  @override
  String adminLockAccountConfirm(Object userId) {
    return 'Bloquear conta do usuário $userId...?';
  }

  @override
  String get adminLockDuration => 'Duração do Bloqueio';

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
  String get adminLoginStreakSystem => 'Sistema de Sequência de Login';

  @override
  String get adminLoginStreaks => 'Sequências de Login';

  @override
  String get adminLoginStreaksSubtitle =>
      'Configurar marcos de sequência e recompensas';

  @override
  String get adminManageAppSettings =>
      'Gerenciar as configurações do aplicativo GreenGo';

  @override
  String get adminMatchPriority => 'Prioridade de Compatibilidade';

  @override
  String get adminMatchingAndVisibility => 'Compatibilidade e Visibilidade';

  @override
  String get adminMessageContext => 'Contexto da Mensagem (50 antes/depois)';

  @override
  String get adminMilestoneUpdated => 'Marco atualizado';

  @override
  String adminMoreErrors(Object count) {
    return '... e mais $count erros';
  }

  @override
  String get adminName => 'Nome';

  @override
  String get adminNinetyDays => '90 dias';

  @override
  String get adminNoEmailsInEarlyAccessList =>
      'Nenhum email na lista de acesso antecipado';

  @override
  String get adminNoInvoicesFound => 'Nenhuma fatura encontrada';

  @override
  String get adminNoLockedAccounts => 'Nenhuma conta bloqueada';

  @override
  String get adminNoMatchingEmailsFound =>
      'Nenhum email correspondente encontrado';

  @override
  String get adminNoOrdersFound => 'Nenhum pedido encontrado';

  @override
  String get adminNoPendingReports => 'Nenhuma denúncia pendente';

  @override
  String get adminNoReportsYet => 'Sem denúncias ainda';

  @override
  String adminNoTickets(Object status) {
    return 'Sem tickets $status';
  }

  @override
  String get adminNoValidEmailsFound =>
      'Nenhum endereço de email válido encontrado no arquivo';

  @override
  String get adminNoVerificationHistory => 'Sem histórico de verificação';

  @override
  String get adminOneDay => '1 dia';

  @override
  String get adminOpen => 'Aberto';

  @override
  String adminOpenCount(Object count) {
    return 'Abertos ($count)';
  }

  @override
  String get adminOpenTickets => 'Tickets Abertos';

  @override
  String get adminOrderDetails => 'Detalhes do Pedido';

  @override
  String get adminOrderId => 'ID do Pedido';

  @override
  String get adminOrderRefunded => 'Pedido reembolsado';

  @override
  String get adminOrders => 'Pedidos';

  @override
  String get adminPackages => 'Pacotes';

  @override
  String get adminPanel => 'Painel Admin';

  @override
  String get adminPayment => 'Pagamento';

  @override
  String get adminPending => 'Pendente';

  @override
  String adminPendingCount(Object count) {
    return 'Pendentes ($count)';
  }

  @override
  String get adminPermanent => 'Permanente';

  @override
  String get adminPleaseEnterValidEmail =>
      'Por favor, insira um endereço de email válido';

  @override
  String get adminPriceUsd => 'Preço (USD)';

  @override
  String get adminProductIdIap => 'ID do Produto (para IAP)';

  @override
  String get adminProfileVisitors => 'Visitantes do Perfil';

  @override
  String get adminPromotional => 'Promocional';

  @override
  String get adminPromotionalPackage => 'Pacote Promocional';

  @override
  String get adminPromotions => 'Promoções';

  @override
  String get adminPromotionsSubtitle =>
      'Gerenciar ofertas especiais e promoções';

  @override
  String get adminProvideReason => 'Por favor, forneça um motivo';

  @override
  String get adminReadReceipts => 'Confirmação de Leitura';

  @override
  String get adminReason => 'Motivo';

  @override
  String adminReasonLabel(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String get adminReasonRequired => 'Motivo (obrigatório)';

  @override
  String get adminRefund => 'Reembolso';

  @override
  String get adminRemove => 'Remover';

  @override
  String get adminRemoveCoins => 'Remover Moedas';

  @override
  String get adminRemoveEmail => 'Remover Email';

  @override
  String adminRemoveEmailConfirm(Object email) {
    return 'Tem certeza que deseja remover \"$email\" da lista de acesso antecipado?';
  }

  @override
  String adminRemovedCoinsFromUser(Object amount) {
    return 'Removidas $amount moedas do usuário';
  }

  @override
  String get adminReportDismissed => 'Denúncia ignorada';

  @override
  String get adminReportFollowupStarted =>
      'Conversa de acompanhamento da denúncia iniciada';

  @override
  String get adminReportedMessage => 'Mensagem Denunciada:';

  @override
  String get adminReportedMessageMarker => '^ MENSAGEM DENUNCIADA';

  @override
  String adminReportedUserIdShort(Object userId) {
    return 'ID do Usuário Denunciado: $userId...';
  }

  @override
  String adminReporterIdShort(Object reporterId) {
    return 'ID do Denunciante: $reporterId...';
  }

  @override
  String get adminReports => 'Denúncias';

  @override
  String get adminReportsManagement => 'Gerenciamento de Denúncias';

  @override
  String get adminRequestNewPhoto => 'Solicitar Nova Foto';

  @override
  String get adminRequiredCount => 'Contagem Necessária';

  @override
  String adminRequiresCount(Object count) {
    return 'Requer: $count';
  }

  @override
  String get adminReset => 'Redefinir';

  @override
  String get adminResetToDefaults => 'Redefinir para Padrão';

  @override
  String get adminResetToDefaultsConfirm =>
      'Isto irá redefinir todas as configurações de nível para os valores padrão. Esta ação não pode ser desfeita.';

  @override
  String get adminResetToDefaultsTitle => 'Redefinir para Padrão?';

  @override
  String get adminResolutionNote => 'Nota de Resolução';

  @override
  String get adminResolve => 'Resolver';

  @override
  String get adminResolved => 'Resolvido';

  @override
  String adminResolvedCount(Object count) {
    return 'Resolvidos ($count)';
  }

  @override
  String get adminRevenueAnalytics => 'Análise de Receitas';

  @override
  String get adminRevenueAnalyticsSubtitle => 'Acompanhar compras e receitas';

  @override
  String get adminReviewedBy => 'Revisado Por';

  @override
  String get adminRewardAmount => 'Valor da Recompensa';

  @override
  String get adminSaving => 'Salvando...';

  @override
  String get adminScheduledEvents => 'Eventos Agendados';

  @override
  String get adminSearchByUserIdOrEmail =>
      'Pesquisar por ID de usuário ou email';

  @override
  String get adminSearchEmails => 'Pesquisar emails...';

  @override
  String get adminSearchForUserCoinBalance =>
      'Pesquisar usuário para gerenciar o saldo de moedas';

  @override
  String get adminSearchOrders => 'Pesquisar pedidos...';

  @override
  String get adminSeeWhenMessagesAreRead => 'Ver quando as mensagens são lidas';

  @override
  String get adminSeeWhoVisitedProfile => 'Ver quem visitou o perfil';

  @override
  String get adminSelectAll => 'Selecionar todos';

  @override
  String get adminSelectCsvFile => 'Selecionar Arquivo CSV';

  @override
  String adminSelectedCount(Object count) {
    return '$count selecionados';
  }

  @override
  String get adminSendImagesAndVideosInChat =>
      'Enviar imagens e vídeos no chat';

  @override
  String get adminSevenDays => '7 dias';

  @override
  String get adminSpendItems => 'Itens de Gasto';

  @override
  String get adminStatistics => 'Estatísticas';

  @override
  String get adminStatus => 'Status';

  @override
  String get adminStreakMilestones => 'Marcos de Sequência';

  @override
  String get adminStreakMultiplier => 'Multiplicador de Sequência';

  @override
  String get adminStreakMultiplierValue => '1,5x por dia';

  @override
  String get adminStreaks => 'Sequências';

  @override
  String get adminSupport => 'Suporte';

  @override
  String get adminSupportAgents => 'Agentes de Suporte';

  @override
  String get adminSupportAgentsSubtitle =>
      'Gerenciar contas de agentes de suporte';

  @override
  String get adminSupportManagement => 'Gerenciamento de Suporte';

  @override
  String get adminSupportRequest => 'Pedido de Suporte';

  @override
  String get adminSupportTickets => 'Tickets de Suporte';

  @override
  String get adminSupportTicketsSubtitle =>
      'Ver e gerenciar conversas de suporte de usuários';

  @override
  String get adminSystemConfiguration => 'Configuração do Sistema';

  @override
  String get adminThirtyDays => '30 dias';

  @override
  String get adminTicketAssignedToYou => 'Ticket atribuído a você';

  @override
  String get adminTicketAssignment => 'Atribuição de Tickets';

  @override
  String get adminTicketAssignmentSubtitle =>
      'Atribuir tickets a agentes de suporte';

  @override
  String get adminTicketClosed => 'Ticket fechado';

  @override
  String get adminTicketResolved => 'Ticket resolvido';

  @override
  String get adminTierConfigsSavedSuccessfully =>
      'Configurações de nível salvas com sucesso';

  @override
  String get adminTierFree => 'FREE';

  @override
  String get adminTierGold => 'GOLD';

  @override
  String get adminTierManagement => 'Gerenciamento de Níveis';

  @override
  String get adminTierManagementSubtitle =>
      'Configurar limites e funcionalidades de nível';

  @override
  String get adminTierPlatinum => 'PLATINUM';

  @override
  String get adminTierSilver => 'SILVER';

  @override
  String get adminToday => 'Hoje';

  @override
  String get adminTotalMinutes => 'Total de Minutos';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminUnassigned => 'Não Atribuído';

  @override
  String get adminUnknown => 'Desconhecido';

  @override
  String get adminUnlimited => 'Ilimitado';

  @override
  String get adminUnlock => 'Desbloquear';

  @override
  String get adminUnlockAccount => 'Desbloquear Conta';

  @override
  String get adminUnlockAccountConfirm =>
      'Tem certeza que deseja desbloquear esta conta?';

  @override
  String get adminUnresolved => 'Não Resolvido';

  @override
  String get adminUploadCsvDescription =>
      'Carregar arquivo CSV com endereços de email (um por linha ou separados por vírgula)';

  @override
  String get adminUploadCsvFile => 'Carregar Arquivo CSV';

  @override
  String get adminUploading => 'Carregando...';

  @override
  String get adminUseVideoCallingFeature =>
      'Usar funcionalidade de videochamada';

  @override
  String get adminUsedMinutes => 'Minutos Usados';

  @override
  String get adminUser => 'Usuário';

  @override
  String get adminUserAnalytics => 'Análise de Usuários';

  @override
  String get adminUserAnalyticsSubtitle =>
      'Ver métricas de engajamento e crescimento de usuários';

  @override
  String get adminUserBalance => 'Saldo do Usuário';

  @override
  String get adminUserId => 'ID do Usuário';

  @override
  String adminUserIdLabel(Object userId) {
    return 'ID do Usuário: $userId';
  }

  @override
  String adminUserIdShort(Object userId) {
    return 'Usuário: $userId...';
  }

  @override
  String get adminUserManagement => 'Gerenciamento de Usuários';

  @override
  String get adminUserModeration => 'Moderação de Usuários';

  @override
  String get adminUserModerationSubtitle =>
      'Gerenciar suspensões e banimentos de usuários';

  @override
  String get adminUserReports => 'Denúncias de Usuários';

  @override
  String get adminUserReportsSubtitle =>
      'Revisar e tratar denúncias de usuários';

  @override
  String adminUserSenderIdShort(Object senderId) {
    return 'Usuário: $senderId...';
  }

  @override
  String get adminUserVerifications => 'Verificações de Usuários';

  @override
  String get adminUserVerificationsSubtitle =>
      'Aprovar ou rejeitar pedidos de verificação de usuários';

  @override
  String get adminVerificationFilter => 'Filtro de Verificação';

  @override
  String get adminVerifications => 'Verificações';

  @override
  String get adminVideoChat => 'Videochamada';

  @override
  String get adminVideoCoinPackages => 'Pacotes de Moedas de Vídeo';

  @override
  String get adminVideoCoins => 'Moedas de Vídeo';

  @override
  String adminVideoMinutesLabel(Object minutes) {
    return '$minutes Minutos';
  }

  @override
  String get adminViewContext => 'Ver Contexto';

  @override
  String get adminViewDocument => 'Ver Documento';

  @override
  String get adminViolationOfCommunityGuidelines =>
      'Violação das diretrizes da comunidade';

  @override
  String get adminWaiting => 'Em Espera';

  @override
  String adminWaitingCount(Object count) {
    return 'Em Espera ($count)';
  }

  @override
  String get adminWeeklyChallenges => 'Desafios Semanais';

  @override
  String get adminWelcome => 'Bem-vindo, Admin';

  @override
  String get adminXpReward => 'Recompensa de XP';

  @override
  String get ageRange => 'Faixa Etária';

  @override
  String get aiCoachBenefitAllChapters =>
      'Todos os capítulos de aprendizado desbloqueados';

  @override
  String get aiCoachBenefitFeedback =>
      'Feedback em tempo real de gramática e pronúncia';

  @override
  String get aiCoachBenefitPersonalized =>
      'Caminho de aprendizado personalizado';

  @override
  String get aiCoachBenefitUnlimited =>
      'Prática ilimitada de conversação com IA';

  @override
  String get aiCoachLabel => 'Coach IA';

  @override
  String get aiCoachTrialEnded =>
      'Seu período de teste grátis do Coach IA acabou.';

  @override
  String get aiCoachUpgradePrompt =>
      'Faça upgrade para Prata, Ouro ou Platina para desbloquear.';

  @override
  String get aiCoachUpgradeTitle => 'Faça Upgrade para Aprender Mais';

  @override
  String get albumNotShared => 'Álbum não compartilhado';

  @override
  String get albumOption => 'Álbum';

  @override
  String albumRevokedMessage(String username) {
    return '$username revogou o acesso ao álbum';
  }

  @override
  String albumSharedMessage(String username) {
    return '$username compartilhou o álbum com você';
  }

  @override
  String get allCategoriesFilter => 'Todas';

  @override
  String get allDealBreakersAdded =>
      'Todos os critérios eliminatórios foram adicionados';

  @override
  String get allLanguagesFilter => 'Todos';

  @override
  String get allPlayersReady => 'Todos os jogadores estão prontos!';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get appLanguage => 'Idioma do App';

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubra Seu Par Perfeito';

  @override
  String get approveVerification => 'Aprovar';

  @override
  String get atLeast8Characters => 'Pelo menos 8 caracteres';

  @override
  String get atLeastOneNumber => 'Pelo menos um número';

  @override
  String get atLeastOneSpecialChar => 'Pelo menos um caractere especial';

  @override
  String get authAppleSignInComingSoon => 'Login com Apple em breve';

  @override
  String get authCancelVerification => 'Cancelar Verificação?';

  @override
  String get authCancelVerificationBody =>
      'Sua sessão será encerrada se cancelar a verificação.';

  @override
  String get authDisableInSettings =>
      'Você pode desativar isto em Configurações > Segurança';

  @override
  String get authErrorEmailAlreadyInUse =>
      'Já existe uma conta com este e-mail.';

  @override
  String get authErrorGeneric => 'Ocorreu um erro. Tente novamente.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail/nickname ou senha incorretos. Verifique suas credenciais e tente novamente.';

  @override
  String get authErrorInvalidEmail =>
      'Por favor insira um endereço de e-mail válido.';

  @override
  String get authErrorNetworkError =>
      'Sem conexão com a internet. Verifique sua conexão e tente novamente.';

  @override
  String get authErrorTooManyRequests =>
      'Muitas tentativas. Tente novamente mais tarde.';

  @override
  String get authErrorUserNotFound =>
      'Nenhuma conta encontrada com este e-mail ou nickname. Verifique e tente novamente, ou cadastre-se.';

  @override
  String get authErrorWeakPassword =>
      'A senha é muito fraca. Use uma senha mais forte.';

  @override
  String get authErrorWrongPassword => 'Senha incorreta. Tente novamente.';

  @override
  String authFailedToTakePhoto(Object error) {
    return 'Falha ao tirar foto: $error';
  }

  @override
  String get authIdentityVerification => 'Verificação de Identidade';

  @override
  String get authPleaseEnterEmail => 'Por favor, insira seu email';

  @override
  String get authRetakePhoto => 'Tirar Foto Novamente';

  @override
  String get authSecurityStep =>
      'Este passo de segurança extra ajuda a proteger sua conta';

  @override
  String get authSelfieInstruction =>
      'Olhe para a câmera e toque para capturar';

  @override
  String get authSignOut => 'Sair';

  @override
  String get authSignOutInstead => 'Sair em vez disso';

  @override
  String get authStay => 'Ficar';

  @override
  String get authTakeSelfie => 'Tirar uma Selfie';

  @override
  String get authTakeSelfieToVerify =>
      'Por favor, tire uma selfie para verificar sua identidade';

  @override
  String get authVerifyAndContinue => 'Verificar e Continuar';

  @override
  String get authVerifyWithSelfie =>
      'Por favor, verifique sua identidade com uma selfie';

  @override
  String authWelcomeBack(Object name) {
    return 'Bem-vindo de volta, $name!';
  }

  @override
  String get authenticationErrorTitle => 'Falha no Login';

  @override
  String get away => 'de distância';

  @override
  String get awesome => 'Incrível!';

  @override
  String get backToLobby => 'Voltar ao Lobby';

  @override
  String get badgeLocked => 'Bloqueado';

  @override
  String get badgeUnlocked => 'Desbloqueado';

  @override
  String get achievementUnlockedTitle => 'CONQUISTA DESBLOQUEADA!';

  @override
  String get achievementUnlockedAwesome => 'Incrível!';

  @override
  String get achievementRarityCommon => 'COMUM';

  @override
  String get achievementRarityUncommon => 'INCOMUM';

  @override
  String get achievementRarityRare => 'RARO';

  @override
  String get achievementRarityEpic => 'ÉPICO';

  @override
  String get achievementRarityLegendary => 'LENDÁRIO';

  @override
  String achievementRewardLabel(int amount, String type) {
    return '+$amount $type';
  }

  @override
  String get badges => 'Emblemas';

  @override
  String get basic => 'Básico';

  @override
  String get basicInformation => 'Informações Básicas';

  @override
  String get betterPhotoRequested => 'Foto melhor solicitada';

  @override
  String get bio => 'Biografia';

  @override
  String get bioUpdatedMessage => 'A bio do seu perfil foi salva';

  @override
  String get bioUpdatedTitle => 'Bio Atualizada!';

  @override
  String get blindDateActivate => 'Ativar Modo Encontro às Cegas';

  @override
  String get blindDateDeactivate => 'Desativar';

  @override
  String get blindDateDeactivateMessage =>
      'Você voltará ao modo de descoberta normal.';

  @override
  String get blindDateDeactivateTitle => 'Desativar Modo Encontro às Cegas?';

  @override
  String get blindDateDeactivateTooltip => 'Desativar Modo Encontro às Cegas';

  @override
  String blindDateFeatureInstantReveal(int cost) {
    return 'Revelação instantânea por $cost moedas';
  }

  @override
  String get blindDateFeatureNoPhotos =>
      'Fotos do perfil não visíveis inicialmente';

  @override
  String get blindDateFeaturePersonality =>
      'Foco na personalidade e interesses';

  @override
  String get blindDateFeatureUnlock => 'Fotos desbloqueadas após conversar';

  @override
  String get blindDateGetCoins => 'Obter Moedas';

  @override
  String get blindDateInstantReveal => 'Revelação Instantânea';

  @override
  String blindDateInstantRevealMessage(int cost) {
    return 'Revelar todas as fotos deste match por $cost moedas?';
  }

  @override
  String blindDateInstantRevealTooltip(int cost) {
    return 'Revelação instantânea ($cost moedas)';
  }

  @override
  String get blindDateInsufficientCoins => 'Moedas Insuficientes';

  @override
  String blindDateInsufficientCoinsMessage(int cost) {
    return 'Você precisa de $cost moedas para revelar fotos instantaneamente.';
  }

  @override
  String get blindDateInterests => 'Interesses';

  @override
  String blindDateKmAway(String distance) {
    return 'a $distance km';
  }

  @override
  String get blindDateLetsExchange => 'Comece a conectar!';

  @override
  String get blindDateMatchMessage =>
      'Vocês curtiram um ao outro! Comecem a conversar para revelar as fotos.';

  @override
  String blindDateMessageProgress(int current, int total) {
    return '$current / $total mensagens';
  }

  @override
  String blindDateMessagesToGo(int count) {
    return 'faltam $count';
  }

  @override
  String blindDateMessagesUntilReveal(int count) {
    return '$count mensagens até a revelação';
  }

  @override
  String get blindDateModeActivated => 'Modo Encontro às Cegas ativado!';

  @override
  String blindDateModeDescription(int threshold) {
    return 'Combine com base na personalidade, não na aparência.\nFotos são reveladas após $threshold mensagens.';
  }

  @override
  String get blindDateModeTitle => 'Modo Encontro às Cegas';

  @override
  String get blindDateMysteryPerson => 'Pessoa Misteriosa';

  @override
  String get blindDateNoCandidates => 'Nenhum candidato disponível';

  @override
  String get blindDateNoMatches => 'Nenhum match ainda';

  @override
  String blindDatePendingReveal(int count) {
    return 'Revelação Pendente ($count)';
  }

  @override
  String get blindDatePhotoRevealProgress => 'Progresso da Revelação de Fotos';

  @override
  String blindDatePhotosRevealHint(int threshold) {
    return 'As fotos são reveladas após $threshold mensagens';
  }

  @override
  String blindDatePhotosRevealed(int coinsSpent) {
    return 'Fotos reveladas! $coinsSpent moedas gastas.';
  }

  @override
  String get blindDatePhotosRevealedLabel => 'Fotos reveladas!';

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
      'Comece a deslizar para encontrar seu encontro às cegas!';

  @override
  String get blindDateTabDiscover => 'Descobrir';

  @override
  String get blindDateTabMatches => 'Matches';

  @override
  String get blindDateTitle => 'Encontro às Cegas';

  @override
  String get blindDateViewMatch => 'Ver Match';

  @override
  String bonusCoinsText(int bonus, Object bonusCoins) {
    return ' (+$bonus de bônus!)';
  }

  @override
  String get boost => 'Impulso';

  @override
  String get boostActivated => 'Impulso ativado por 30 minutos!';

  @override
  String get boostNow => 'Impulsionar Agora';

  @override
  String get boostProfile => 'Impulsionar Perfil';

  @override
  String get boosted => 'IMPULSIONADO!';

  @override
  String boostsRemainingCount(int count) {
    return 'x$count';
  }

  @override
  String get bundleTier => 'Pacote';

  @override
  String get businessCategory => 'Negócios';

  @override
  String get buyCoins => 'Comprar Moedas';

  @override
  String get buyCoinsBtnLabel => 'Comprar Moedas';

  @override
  String get buyPackBtn => 'Comprar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get cannotAccessFeature =>
      'Esta funcionalidade está disponível após a verificação da sua conta.';

  @override
  String get cantUndoMatched =>
      'Não é possível desfazer — vocês já deram match!';

  @override
  String get casualCategory => 'Casual';

  @override
  String get casualDating => 'Encontros casuais';

  @override
  String get categoryFlashcard => 'Flashcard';

  @override
  String get categoryLearning => 'Aprendizado';

  @override
  String get categoryMultilingual => 'Multilíngue';

  @override
  String get categoryName => 'Categoria';

  @override
  String get categoryQuiz => 'Quiz';

  @override
  String get categorySeasonal => 'Sazonal';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryStreak => 'Sequência';

  @override
  String get categoryTranslation => 'Tradução';

  @override
  String get challenges => 'Desafios';

  @override
  String get changeLocation => 'Alterar localização';

  @override
  String get changePassword => 'Alterar Senha';

  @override
  String get changePasswordConfirm => 'Confirmar Nova Senha';

  @override
  String get changePasswordCurrent => 'Senha Atual';

  @override
  String get changePasswordDescription =>
      'Por segurança, verifique sua identidade antes de alterar sua senha.';

  @override
  String get changePasswordEmailConfirm => 'Confirme seu endereço de email';

  @override
  String get changePasswordEmailHint => 'Seu email';

  @override
  String get changePasswordEmailMismatch =>
      'O email não corresponde à sua conta';

  @override
  String get changePasswordNew => 'Nova Senha';

  @override
  String get changePasswordReauthRequired =>
      'Por favor, saia e entre novamente antes de alterar sua senha';

  @override
  String get changePasswordSubtitle => 'Atualize a senha da sua conta';

  @override
  String get changePasswordSuccess => 'Senha alterada com sucesso';

  @override
  String get changePasswordWrongCurrent => 'A senha atual está incorreta';

  @override
  String get chatAddCaption => 'Adicionar legenda...';

  @override
  String get chatAddToStarred => 'Adicionar às mensagens favoritas';

  @override
  String get chatAlreadyInYourLanguage => 'A mensagem já está no seu idioma';

  @override
  String get chatAttachCamera => 'Câmera';

  @override
  String get chatAttachGallery => 'Galeria';

  @override
  String get chatAttachRecord => 'Gravar';

  @override
  String get chatAttachVideo => 'Vídeo';

  @override
  String get chatBlock => 'Bloquear';

  @override
  String chatBlockUser(String name) {
    return 'Bloquear $name';
  }

  @override
  String chatBlockUserMessage(String name) {
    return 'Tem certeza de que deseja bloquear $name? Eles não poderão mais entrar em contato com você.';
  }

  @override
  String get chatBlockUserTitle => 'Bloquear Usuário';

  @override
  String get chatCannotBlockAdmin => 'Você não pode bloquear um administrador.';

  @override
  String get chatCannotReportAdmin =>
      'Você não pode denunciar um administrador.';

  @override
  String get chatCategory => 'Categoria';

  @override
  String get chatCategoryAccount => 'Ajuda da Conta';

  @override
  String get chatCategoryBilling => 'Cobranças e Pagamentos';

  @override
  String get chatCategoryFeedback => 'Feedback';

  @override
  String get chatCategoryGeneral => 'Pergunta Geral';

  @override
  String get chatCategorySafety => 'Preocupação de Segurança';

  @override
  String get chatCategoryTechnical => 'Problema Técnico';

  @override
  String get chatCopy => 'Copiar';

  @override
  String get chatCreate => 'Criar';

  @override
  String get chatCreateSupportTicket => 'Criar Chamado de Suporte';

  @override
  String get chatCreateTicket => 'Criar Chamado';

  @override
  String chatDaysAgo(int count) {
    return 'há ${count}d';
  }

  @override
  String get chatDelete => 'Excluir';

  @override
  String get chatDeleteChat => 'Excluir Chat';

  @override
  String chatDeleteChatForBothMessage(String name) {
    return 'Isso excluirá todas as mensagens para você e $name. Esta ação não pode ser desfeita.';
  }

  @override
  String get chatDeleteChatForEveryone => 'Excluir Chat para Todos';

  @override
  String get chatDeleteChatForMeMessage =>
      'Isso excluirá o chat apenas do seu dispositivo. A outra pessoa ainda verá as mensagens.';

  @override
  String chatDeleteConversationWith(String name) {
    return 'Excluir conversa com $name?';
  }

  @override
  String get chatDeleteForBoth => 'Excluir chat para ambos';

  @override
  String get chatDeleteForBothDescription =>
      'Isso excluirá permanentemente a conversa para você e a outra pessoa.';

  @override
  String get chatDeleteForEveryone => 'Excluir para Todos';

  @override
  String get chatDeleteForMe => 'Excluir chat para mim';

  @override
  String get chatDeleteForMeDescription =>
      'Isso excluirá a conversa apenas da sua lista de chats. A outra pessoa ainda a verá.';

  @override
  String get chatDeletedForBothMessage =>
      'Este chat foi removido permanentemente';

  @override
  String get chatDeletedForMeMessage =>
      'Este chat foi removido da sua caixa de entrada';

  @override
  String get chatDeletedTitle => 'Chat Excluído!';

  @override
  String get chatDescriptionOptional => 'Descrição (Opcional)';

  @override
  String get chatDetailsHint => 'Forneça mais detalhes sobre seu problema...';

  @override
  String get chatDisableTranslation => 'Desativar tradução';

  @override
  String get chatEnableTranslation => 'Ativar tradução';

  @override
  String get chatErrorLoadingTickets => 'Erro ao carregar os chamados';

  @override
  String get chatFailedToCreateTicket => 'Falha ao criar chamado';

  @override
  String get chatFailedToForwardMessage => 'Falha ao encaminhar mensagem';

  @override
  String get chatFailedToLoadAlbum => 'Falha ao carregar álbum';

  @override
  String get chatFailedToLoadConversations => 'Falha ao carregar conversas';

  @override
  String get chatFailedToLoadImage => 'Falha ao carregar imagem';

  @override
  String get chatFailedToLoadVideo => 'Falha ao carregar o vídeo';

  @override
  String chatFailedToPickImage(String error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String chatFailedToPickVideo(String error) {
    return 'Falha ao selecionar vídeo: $error';
  }

  @override
  String chatFailedToReportMessage(String error) {
    return 'Falha ao denunciar mensagem: $error';
  }

  @override
  String get chatFailedToRevokeAccess => 'Falha ao revogar acesso';

  @override
  String get chatFailedToSaveFlashcard => 'Falha ao salvar o cartão';

  @override
  String get chatFailedToShareAlbum => 'Falha ao compartilhar álbum';

  @override
  String chatFailedToUploadImage(String error) {
    return 'Falha ao enviar imagem: $error';
  }

  @override
  String chatFailedToUploadVideo(String error) {
    return 'Falha ao enviar vídeo: $error';
  }

  @override
  String get chatFeatureCulturalTips => 'Dicas culturais e contexto';

  @override
  String get chatFeatureGrammar => 'Feedback gramatical em tempo real';

  @override
  String get chatFeatureVocabulary => 'Exercícios de vocabulário';

  @override
  String get chatForward => 'Encaminhar';

  @override
  String get chatForwardMessage => 'Encaminhar Mensagem';

  @override
  String get chatForwardToChat => 'Encaminhar para outro chat';

  @override
  String get chatGrammarSuggestion => 'Sugestão gramatical';

  @override
  String chatHoursAgo(int count) {
    return 'há ${count}h';
  }

  @override
  String get chatIcebreakers => 'Quebra-gelos';

  @override
  String chatIsTyping(String userName) {
    return '$userName está digitando';
  }

  @override
  String get chatJustNow => 'Agora mesmo';

  @override
  String get chatLanguagePickerHint =>
      'Escolha o idioma em que deseja ler esta conversa. Todas as mensagens serão traduzidas para você.';

  @override
  String chatLanguageSetTo(String language) {
    return 'Idioma do chat definido para $language';
  }

  @override
  String get chatLanguages => 'Idiomas';

  @override
  String get chatLearnThis => 'Aprender Isto';

  @override
  String get chatListen => 'Ouvir';

  @override
  String get chatLoadingVideo => 'Carregando vídeo...';

  @override
  String get chatMaybeLater => 'Talvez depois';

  @override
  String get chatMediaLimitReached => 'Limite de mídia atingido';

  @override
  String get chatMessage => 'Mensagem';

  @override
  String chatMessageBlockedContains(String violations) {
    return 'Mensagem bloqueada: Contém $violations. Para sua segurança, compartilhar dados de contato pessoais não é permitido.';
  }

  @override
  String chatMessageForwarded(int count) {
    return 'Mensagem encaminhada para $count conversa(s)';
  }

  @override
  String get chatMessageOptions => 'Opções da Mensagem';

  @override
  String get chatMessageOriginal => 'Original';

  @override
  String get chatMessageReported =>
      'Mensagem denunciada. Analisaremos em breve.';

  @override
  String get chatMessageStarred => 'Mensagem favoritada';

  @override
  String get chatMessageTranslated => 'Traduzido';

  @override
  String get chatMessageUnstarred => 'Mensagem removida dos favoritos';

  @override
  String chatMinutesAgo(int count) {
    return 'há ${count}min';
  }

  @override
  String get chatMySupportTickets => 'Meus Chamados de Suporte';

  @override
  String get chatNeedHelpCreateTicket =>
      'Precisa de ajuda? Crie um novo chamado.';

  @override
  String get chatNewTicket => 'Novo Chamado';

  @override
  String get chatNoConversationsToForward => 'Sem conversas para encaminhar';

  @override
  String get chatNoMatchingConversations => 'Nenhuma conversa encontrada';

  @override
  String get chatNoMessagesToPractice => 'Ainda não há mensagens para praticar';

  @override
  String get chatNoMessagesYet => 'Ainda sem mensagens';

  @override
  String get chatNoPrivatePhotos => 'Nenhuma foto privada disponível';

  @override
  String get chatNoSupportTickets => 'Sem Chamados de Suporte';

  @override
  String get chatOffline => 'Offline';

  @override
  String get chatOnline => 'Online';

  @override
  String chatOnlineDaysAgo(int days) {
    return 'Online há ${days}d';
  }

  @override
  String chatOnlineHoursAgo(int hours) {
    return 'Online há ${hours}h';
  }

  @override
  String get chatOnlineJustNow => 'Online agora';

  @override
  String chatOnlineMinutesAgo(int minutes) {
    return 'Online há ${minutes}min';
  }

  @override
  String get chatOptions => 'Opções do Chat';

  @override
  String chatOtherRevokedAlbum(String name) {
    return '$name revogou o acesso ao álbum';
  }

  @override
  String chatOtherSharedAlbum(String name) {
    return '$name compartilhou seu álbum privado';
  }

  @override
  String get chatPhoto => 'Foto';

  @override
  String get chatPhraseSaved => 'Frase salva no seu baralho de cartões!';

  @override
  String get chatPleaseEnterSubject => 'Por favor, insira um assunto';

  @override
  String get chatPractice => 'Praticar';

  @override
  String get chatPracticeMode => 'Modo Prática';

  @override
  String get chatPracticeTrialStarted =>
      'Teste do modo prática iniciado! Você tem 3 sessões grátis.';

  @override
  String get chatPreviewImage => 'Pré-visualização de Imagem';

  @override
  String get chatPreviewVideo => 'Pré-visualização de Vídeo';

  @override
  String get chatPronunciationChallenge => 'Desafio de pronúncia';

  @override
  String get chatPronunciationHint => 'Toque para ouvir e pratique cada frase:';

  @override
  String get chatRemoveFromStarred => 'Remover das mensagens favoritas';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatReplyToMessage => 'Responder a esta mensagem';

  @override
  String chatReplyingTo(String name) {
    return 'Respondendo a $name';
  }

  @override
  String get chatReportInappropriate => 'Denunciar conteúdo inapropriado';

  @override
  String get chatReportMessage => 'Denunciar Mensagem';

  @override
  String get chatReportReasonFakeProfile => 'Perfil falso / Catfishing';

  @override
  String get chatReportReasonHarassment => 'Assédio ou bullying';

  @override
  String get chatReportReasonInappropriate => 'Conteúdo inapropriado';

  @override
  String get chatReportReasonOther => 'Outro';

  @override
  String get chatReportReasonPersonalInfo =>
      'Compartilhamento de informações pessoais';

  @override
  String get chatReportReasonSpam => 'Spam ou golpe';

  @override
  String get chatReportReasonThreatening => 'Comportamento ameaçador';

  @override
  String get chatReportReasonUnderage => 'Usuário menor de idade';

  @override
  String chatReportUser(String name) {
    return 'Denunciar $name';
  }

  @override
  String get chatReportUserTitle => 'Denunciar Usuário';

  @override
  String chatSeeExchangeDetails(String name) {
    return 'Ver Detalhes da Troca com $name';
  }

  @override
  String get chatSafetyGotIt => 'Entendi';

  @override
  String get chatSafetySubtitle =>
      'Sua segurança é nossa prioridade. Tenha em mente essas dicas.';

  @override
  String get chatSafetyTip => 'Dica de Segurança';

  @override
  String get chatSafetyTip1Description =>
      'Não compartilhe endereço, número de telefone ou informações financeiras.';

  @override
  String get chatSafetyTip1Title => 'Mantenha Infos Pessoais Privadas';

  @override
  String get chatSafetyTip2Description =>
      'Nunca envie dinheiro para alguém que você não conheceu pessoalmente.';

  @override
  String get chatSafetyTip2Title => 'Cuidado com Pedidos de Dinheiro';

  @override
  String get chatSafetyTip3Description =>
      'Para primeiros encontros, sempre escolha um local público e bem iluminado.';

  @override
  String get chatSafetyTip3Title => 'Encontre-se em Locais Públicos';

  @override
  String get chatSafetyTip4Description =>
      'Se algo parecer errado, confie no seu instinto e encerre a conversa.';

  @override
  String get chatSafetyTip4Title => 'Confie no Seu Instinto';

  @override
  String get chatSafetyTip5Description =>
      'Use a função de denúncia se alguém deixar você desconfortável.';

  @override
  String get chatSafetyTip5Title => 'Denuncie Comportamento Suspeito';

  @override
  String get chatSafetyTitle => 'Converse com Segurança';

  @override
  String get chatSaving => 'Salvando...';

  @override
  String chatSayHiTo(String name) {
    return 'Diga oi para $name!';
  }

  @override
  String get chatScrollUpForOlder =>
      'Deslize para cima para mensagens mais antigas';

  @override
  String get chatSearchByNameOrNickname => 'Buscar por nome ou @apelido';

  @override
  String get chatSearchConversationsHint => 'Pesquisar conversas...';

  @override
  String get chatSelectPhotos => 'Selecionar fotos para enviar';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSendAnyway => 'Enviar mesmo assim';

  @override
  String get chatSendAttachment => 'Enviar Anexo';

  @override
  String chatSendCount(int count) {
    return 'Enviar ($count)';
  }

  @override
  String get chatSendMessageToStart =>
      'Envie uma mensagem para iniciar a conversa';

  @override
  String get chatSendMessagesForTips =>
      'Envie mensagens para receber dicas de idiomas!';

  @override
  String get chatSetNativeLanguage =>
      'Defina primeiro seu idioma nativo nas configurações';

  @override
  String get chatSettingCulturalTips => 'Dicas culturais';

  @override
  String get chatSettingCulturalTipsDesc =>
      'Mostrar contexto cultural de expressões idiomáticas';

  @override
  String get chatSettingDifficultyBadges => 'Distintivos de dificuldade';

  @override
  String get chatSettingDifficultyBadgesDesc =>
      'Mostrar nível QECR (A1-C2) nas mensagens';

  @override
  String get chatSettingGrammarCheck => 'Verificação gramatical';

  @override
  String get chatSettingGrammarCheckDesc =>
      'Verificar gramática antes de enviar';

  @override
  String get chatSettingLanguageFlags => 'Bandeiras de idioma';

  @override
  String get chatSettingLanguageFlagsDesc =>
      'Mostrar emoji de bandeira junto ao texto traduzido e original';

  @override
  String get chatSettingPhraseOfDay => 'Frase do dia';

  @override
  String get chatSettingPhraseOfDayDesc =>
      'Mostrar uma frase diária para praticar';

  @override
  String get chatSettingPronunciation => 'Pronúncia (TTS)';

  @override
  String get chatSettingPronunciationDesc =>
      'Toque duplo para ouvir a pronúncia';

  @override
  String get chatSettingShowOriginal => 'Mostrar texto original';

  @override
  String get chatSettingShowOriginalDesc =>
      'Mostrar a mensagem original abaixo da tradução';

  @override
  String get chatSettingSmartReplies => 'Respostas inteligentes';

  @override
  String get chatSettingSmartRepliesDesc => 'Sugerir respostas no idioma alvo';

  @override
  String get chatSettingTtsTranslation => 'TTS lê tradução';

  @override
  String get chatSettingTtsTranslationDesc =>
      'Ler o texto traduzido em vez do original';

  @override
  String get chatSettingWordBreakdown => 'Decomposição de palavras';

  @override
  String get chatSettingWordBreakdownDesc =>
      'Toque nas mensagens para tradução palavra por palavra';

  @override
  String get chatSettingXpBar => 'Barra de XP e sequência';

  @override
  String get chatSettingXpBarDesc =>
      'Mostrar XP da sessão e progresso de palavras';

  @override
  String get chatSettingsSaveAllChats => 'Salvar para todos os chats';

  @override
  String get chatSettingsSaveThisChat => 'Salvar para este chat';

  @override
  String get chatSettingsSavedAllChats =>
      'Configurações salvas para todos os chats';

  @override
  String get chatSettingsSavedThisChat => 'Configurações salvas para este chat';

  @override
  String get chatSettingsSubtitle =>
      'Personalize sua experiência de aprendizagem neste chat';

  @override
  String get chatSettingsTitle => 'Configurações do chat';

  @override
  String get chatSomeone => 'Alguém';

  @override
  String get chatStarMessage => 'Favoritar Mensagem';

  @override
  String get chatStartSwipingToChat =>
      'Deslize e dê match para conversar com pessoas!';

  @override
  String get chatStatusAssigned => 'Atribuído';

  @override
  String get chatStatusAwaitingReply => 'Aguardando Resposta';

  @override
  String get chatStatusClosed => 'Fechado';

  @override
  String get chatStatusInProgress => 'Em Andamento';

  @override
  String get chatStatusOpen => 'Aberto';

  @override
  String get chatStatusResolved => 'Resolvido';

  @override
  String chatStreak(int count) {
    return 'Sequência: $count';
  }

  @override
  String get chatSubject => 'Assunto';

  @override
  String get chatSubjectHint => 'Breve descrição do seu problema';

  @override
  String get chatSupportAddAttachment => 'Adicionar Anexo';

  @override
  String get chatSupportAddCaptionOptional => 'Adicionar legenda (opcional)...';

  @override
  String chatSupportAgent(String name) {
    return 'Agente: $name';
  }

  @override
  String get chatSupportAgentLabel => 'Agente';

  @override
  String get chatSupportCategory => 'Categoria';

  @override
  String get chatSupportClose => 'Fechar';

  @override
  String chatSupportDaysAgo(int days) {
    return 'há ${days}d';
  }

  @override
  String get chatSupportErrorLoading => 'Erro ao carregar mensagens';

  @override
  String chatSupportFailedToReopen(String error) {
    return 'Falha ao reabrir ticket: $error';
  }

  @override
  String chatSupportFailedToSend(String error) {
    return 'Falha ao enviar mensagem: $error';
  }

  @override
  String get chatSupportGeneral => 'Geral';

  @override
  String get chatSupportGeneralSupport => 'Suporte Geral';

  @override
  String chatSupportHoursAgo(int hours) {
    return 'há ${hours}h';
  }

  @override
  String get chatSupportJustNow => 'Agora mesmo';

  @override
  String chatSupportMinutesAgo(int minutes) {
    return 'há ${minutes}min';
  }

  @override
  String get chatSupportReopenTicket =>
      'Precisa de mais ajuda? Toque para reabrir';

  @override
  String get chatSupportStartMessage =>
      'Envie uma mensagem para iniciar a conversa.\nNossa equipe responderá o mais breve possível.';

  @override
  String get chatSupportStatus => 'Status';

  @override
  String get chatSupportStatusClosed => 'Fechado';

  @override
  String get chatSupportStatusDefault => 'Suporte';

  @override
  String get chatSupportStatusOpen => 'Aberto';

  @override
  String get chatSupportStatusPending => 'Pendente';

  @override
  String get chatSupportStatusResolved => 'Resolvido';

  @override
  String get chatSupportSubject => 'Assunto';

  @override
  String get chatSupportTicketCreated => 'Ticket Criado';

  @override
  String get chatSupportTicketId => 'ID do Ticket';

  @override
  String get chatSupportTicketInfo => 'Informações do Ticket';

  @override
  String get chatSupportTicketReopened =>
      'Ticket reaberto. Você pode enviar uma mensagem agora.';

  @override
  String get chatSupportTicketResolved => 'Este ticket foi resolvido';

  @override
  String get chatSupportTicketStart => 'Início do Ticket';

  @override
  String get chatSupportTitle => 'Suporte GreenGo';

  @override
  String get chatSupportTypeMessage => 'Digite sua mensagem...';

  @override
  String get chatSupportWaitingAssignment => 'Aguardando atribuição';

  @override
  String get chatSupportWelcome => 'Bem-vindo ao Suporte';

  @override
  String get chatTapToView => 'Toque para ver';

  @override
  String get chatTapToViewAlbum => 'Toque para ver o álbum';

  @override
  String get chatTranslate => 'Traduzir';

  @override
  String get chatTranslated => 'Traduzido';

  @override
  String get chatTranslating => 'Traduzindo...';

  @override
  String get chatTranslationDisabled => 'Tradução desativada';

  @override
  String get chatTranslationEnabled => 'Tradução ativada';

  @override
  String get chatTranslationFailed => 'Tradução falhou. Tente novamente.';

  @override
  String get chatTrialExpired => 'Seu teste gratuito expirou.';

  @override
  String get chatTtsComingSoon => 'Texto para fala em breve!';

  @override
  String get chatTyping => 'digitando...';

  @override
  String get chatUnableToForward => 'Não é possível encaminhar a mensagem';

  @override
  String get chatUnknown => 'Desconhecido';

  @override
  String get chatUnstarMessage => 'Desfavoritar Mensagem';

  @override
  String get chatUpgrade => 'Atualizar';

  @override
  String get chatUpgradePracticeMode =>
      'Atualize para Silver VIP ou superior para continuar praticando idiomas nos seus chats.';

  @override
  String get chatUploading => 'Enviando...';

  @override
  String get chatUseCorrection => 'Usar correção';

  @override
  String chatUserBlocked(String name) {
    return '$name foi bloqueado';
  }

  @override
  String get chatUserReported =>
      'Usuário denunciado. Analisaremos sua denúncia em breve.';

  @override
  String get chatVideo => 'Vídeo';

  @override
  String get chatVideoPlayer => 'Reprodutor de Vídeo';

  @override
  String get chatVideoTooLarge =>
      'Vídeo muito grande. O tamanho máximo é 50MB.';

  @override
  String get chatWhyReportMessage =>
      'Por que você está denunciando esta mensagem?';

  @override
  String chatWhyReportUser(String name) {
    return 'Por que você está denunciando $name?';
  }

  @override
  String chatWithName(String name) {
    return 'Conversar com $name';
  }

  @override
  String chatWords(int count) {
    return '$count palavras';
  }

  @override
  String get chatYou => 'Você';

  @override
  String get chatYouRevokedAlbum => 'Você revogou o acesso ao álbum';

  @override
  String get chatYouSharedAlbum => 'Você compartilhou seu álbum privado';

  @override
  String get chatYourLanguage => 'Seu idioma';

  @override
  String get checkBackLater =>
      'Volte mais tarde para novas pessoas, ou ajuste suas preferências';

  @override
  String get chooseCorrectAnswer => 'Escolha a resposta correta';

  @override
  String get chooseFromGallery => 'Escolher da Galeria';

  @override
  String get chooseGame => 'Escolha um Jogo';

  @override
  String get claimReward => 'Resgatar Recompensa';

  @override
  String get claimRewardBtn => 'Resgatar';

  @override
  String get clearFilters => 'Limpar Filtros';

  @override
  String get close => 'Fechar';

  @override
  String get coins => 'Moedas';

  @override
  String coinsAddedMessage(int totalCoins, String bonusText) {
    return '$totalCoins moedas adicionadas à sua conta$bonusText';
  }

  @override
  String get coinsAllTransactions => 'Todas as Transações';

  @override
  String coinsAmountCoins(Object amount) {
    return '$amount Moedas';
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
    return '+$amount moedas bonus';
  }

  @override
  String get coinsCancelLabel => 'Cancelar';

  @override
  String get coinsConfirmPurchase => 'Confirmar Compra';

  @override
  String coinsCost(int amount) {
    return '$amount moedas';
  }

  @override
  String get coinsCreditsOnly => 'Apenas Créditos';

  @override
  String get coinsDebitsOnly => 'Apenas Débitos';

  @override
  String get coinsEnterReceiverId => 'Insira o ID do destinatário';

  @override
  String coinsExpiring(Object count) {
    return '$count expirando';
  }

  @override
  String get coinsFilterTransactions => 'Filtrar Transações';

  @override
  String coinsGiftAccepted(Object amount) {
    return '$amount moedas aceitas!';
  }

  @override
  String get coinsGiftDeclined => 'Presente recusado';

  @override
  String get coinsGiftSendFailed => 'Falha ao enviar presente';

  @override
  String coinsGiftSent(Object amount) {
    return 'Presente de $amount moedas enviado!';
  }

  @override
  String get coinsGreenGoCoins => 'GreenGoCoins';

  @override
  String get coinsInsufficientCoins => 'Moedas insuficientes';

  @override
  String get coinsLabel => 'Moedas';

  @override
  String get coinsMessageLabel => 'Mensagem (opcional)';

  @override
  String get coinsMins => 'min';

  @override
  String get coinsNoTransactionsYet => 'Nenhuma transacao ainda';

  @override
  String get coinsPendingGifts => 'Presentes Pendentes';

  @override
  String get coinsPopular => 'POPULAR';

  @override
  String coinsPurchaseCoinsQuestion(Object totalCoins, String price) {
    return 'Comprar $totalCoins moedas por $price?';
  }

  @override
  String get coinsPurchaseFailed => 'Falha na compra';

  @override
  String get coinsPurchaseLabel => 'Comprar';

  @override
  String coinsPurchaseMinutesQuestion(Object totalMinutes, String price) {
    return 'Comprar $totalMinutes minutos de video por $price?';
  }

  @override
  String coinsPurchasedCoins(Object totalCoins) {
    return 'Compra de $totalCoins moedas realizada com sucesso!';
  }

  @override
  String coinsPurchasedMinutes(Object totalMinutes) {
    return 'Compra de $totalMinutes minutos de vídeo realizada com sucesso!';
  }

  @override
  String get coinsReceiverIdLabel => 'ID do Destinatário';

  @override
  String coinsRequired(int amount) {
    return '$amount moedas necessárias';
  }

  @override
  String get coinsRetry => 'Tentar novamente';

  @override
  String get coinsSelectAmount => 'Selecionar Quantidade';

  @override
  String coinsSendCoinsAmount(Object amount) {
    return 'Enviar $amount Moedas';
  }

  @override
  String get coinsSendGift => 'Enviar Presente';

  @override
  String get coinsSent => 'Moedas enviadas com sucesso!';

  @override
  String get coinsShareCoins => 'Compartilhe moedas com alguem especial';

  @override
  String get coinsShopLabel => 'Loja';

  @override
  String get coinsTabCoins => 'Moedas';

  @override
  String get coinsTabGifts => 'Presentes';

  @override
  String get coinsTabVideoCoins => 'Moedas de Vídeo';

  @override
  String get coinsToday => 'Hoje';

  @override
  String get coinsTransactionHistory => 'Histórico de Transações';

  @override
  String get coinsTransactionsAppearHere =>
      'Suas transacoes de moedas aparecerao aqui';

  @override
  String get coinsUnlockPremium => 'Desbloqueie funcionalidades premium';

  @override
  String get coinsVideoCallMatches => 'Videochamada com seus matches';

  @override
  String get coinsVideoCoinInfo => '1 Video Coin = 1 minuto de videochamada';

  @override
  String get coinsVideoMin => 'Min Video';

  @override
  String get coinsVideoMinutes => 'Minutos de Video';

  @override
  String get coinsYesterday => 'Ontem';

  @override
  String get comingSoonLabel => 'Em Breve';

  @override
  String get communitiesAddTag => 'Adicionar tag';

  @override
  String get communitiesAdjustSearch =>
      'Tente ajustar sua pesquisa ou filtros.';

  @override
  String get communitiesAllCommunities => 'Todas as Comunidades';

  @override
  String get communitiesAllFilter => 'Todas';

  @override
  String get communitiesAnyoneCanJoin => 'Qualquer pessoa pode entrar';

  @override
  String get communitiesBeFirstToSay => 'Seja o primeiro a dizer algo!';

  @override
  String get communitiesCancelLabel => 'Cancelar';

  @override
  String get communitiesCityLabel => 'Cidade';

  @override
  String get communitiesCityTipLabel => 'Dica da Cidade';

  @override
  String get communitiesCityTipUpper => 'DICA DA CIDADE';

  @override
  String get communitiesCommunityInfo => 'Info da Comunidade';

  @override
  String get communitiesCommunityName => 'Nome da Comunidade';

  @override
  String get communitiesCommunityType => 'Tipo de Comunidade';

  @override
  String get communitiesCountryLabel => 'Pais';

  @override
  String get communitiesCreateAction => 'Criar';

  @override
  String get communitiesCreateCommunity => 'Criar Comunidade';

  @override
  String get communitiesCreateCommunityAction => 'Criar Comunidade';

  @override
  String get communitiesCreateLabel => 'Criar';

  @override
  String get communitiesCreateLanguageCircle => 'Criar Circulo Linguistico';

  @override
  String get communitiesCreated => 'Comunidade criada!';

  @override
  String communitiesCreatedBy(String name) {
    return 'Criado por $name';
  }

  @override
  String get communitiesCreatedStatLabel => 'Criado';

  @override
  String get communitiesCulturalFactLabel => 'Fato Cultural';

  @override
  String get communitiesCulturalFactUpper => 'FATO CULTURAL';

  @override
  String get communitiesDescription => 'Descricao';

  @override
  String get communitiesDescriptionHint => 'Sobre o que e essa comunidade?';

  @override
  String get communitiesDescriptionLabel => 'Descricao';

  @override
  String get communitiesDescriptionMinLength =>
      'A descricao deve ter pelo menos 10 caracteres';

  @override
  String get communitiesDescriptionRequired => 'Por favor insira uma descricao';

  @override
  String get communitiesDiscoverCommunities => 'Descobrir Comunidades';

  @override
  String get communitiesEditLabel => 'Editar';

  @override
  String get communitiesGuide => 'Guia';

  @override
  String get communitiesInfoUpper => 'INFO';

  @override
  String get communitiesInviteOnly => 'Apenas com convite';

  @override
  String get communitiesJoinCommunity => 'Entrar na Comunidade';

  @override
  String get communitiesJoinPrompt =>
      'Entre em comunidades para se conectar com pessoas que compartilham seus interesses e idiomas.';

  @override
  String get communitiesJoined => 'Entrou na comunidade!';

  @override
  String get communitiesLanguageCirclesPrompt =>
      'Os circulos linguisticos aparecerao aqui quando disponiveis. Crie um para comecar!';

  @override
  String get communitiesLanguageTipLabel => 'Dica de Idioma';

  @override
  String get communitiesLanguageTipUpper => 'DICA DE IDIOMA';

  @override
  String get communitiesLanguages => 'Idiomas';

  @override
  String get communitiesLanguagesLabel => 'Idiomas';

  @override
  String get communitiesLeaveCommunity => 'Sair da Comunidade';

  @override
  String communitiesLeaveConfirm(String name) {
    return 'Tem certeza de que deseja sair de \"$name\"?';
  }

  @override
  String get communitiesLeaveLabel => 'Sair';

  @override
  String get communitiesLeaveTitle => 'Sair da Comunidade';

  @override
  String get communitiesLocation => 'Localizacao';

  @override
  String get communitiesLocationLabel => 'Localizacao';

  @override
  String communitiesMembersCount(Object count) {
    return '$count membros';
  }

  @override
  String get communitiesMembersStatLabel => 'Membros';

  @override
  String get communitiesMembersTitle => 'Membros';

  @override
  String get communitiesNameHint => 'ex., Aprendizes de Espanhol Sao Paulo';

  @override
  String get communitiesNameMinLength =>
      'O nome deve ter pelo menos 3 caracteres';

  @override
  String get communitiesNameRequired => 'Por favor insira um nome';

  @override
  String get communitiesNoCommunities => 'Sem Comunidades Ainda';

  @override
  String get communitiesNoCommunitiesFound => 'Nenhuma Comunidade Encontrada';

  @override
  String get communitiesNoLanguageCircles => 'Sem Circulos Linguisticos';

  @override
  String get communitiesNoMessagesYet => 'Sem mensagens ainda';

  @override
  String get communitiesPreview => 'Pre-visualizacao';

  @override
  String get communitiesPreviewSubtitle =>
      'E assim que sua comunidade vai aparecer para os outros.';

  @override
  String get communitiesPrivate => 'Privada';

  @override
  String get communitiesPublic => 'Publica';

  @override
  String get communitiesRecommendedForYou => 'Recomendado para Voce';

  @override
  String get communitiesSearchHint => 'Pesquisar comunidades...';

  @override
  String get communitiesShareCityTip => 'Compartilhe uma dica da cidade...';

  @override
  String get communitiesShareCulturalFact => 'Compartilhe um fato cultural...';

  @override
  String get communitiesShareLanguageTip => 'Compartilhe uma dica de idioma...';

  @override
  String get communitiesStats => 'Estatisticas';

  @override
  String get communitiesTabDiscover => 'Descobrir';

  @override
  String get communitiesTabLanguageCircles => 'Círculos de Idiomas';

  @override
  String get communitiesTabMyGroups => 'Meus Grupos';

  @override
  String get communitiesTags => 'Tags';

  @override
  String get communitiesTagsLabel => 'Tags';

  @override
  String get communitiesTextLabel => 'Texto';

  @override
  String get communitiesTitle => 'Comunidades';

  @override
  String get communitiesTypeAMessage => 'Digite uma mensagem...';

  @override
  String get communitiesUnableToLoad =>
      'Nao foi possivel carregar a comunidade';

  @override
  String get compatibilityLabel => 'Compatibilidade';

  @override
  String compatiblePercent(String percent) {
    return '$percent% compativel';
  }

  @override
  String get completeAchievementsToEarnBadges =>
      'Complete conquistas para ganhar emblemas!';

  @override
  String get completeProfile => 'Complete Seu Perfil';

  @override
  String get complimentsCategory => 'Elogios';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get confirmLocation => 'Confirmar localização';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get confirmPasswordRequired => 'Por favor, confirme sua senha';

  @override
  String get connectSocialAccounts => 'Conecte suas contas sociais';

  @override
  String get connectionError => 'Erro de conexão';

  @override
  String get connectionErrorMessage =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get connectionErrorTitle => 'Sem Conexão com a Internet';

  @override
  String get consentRequired => 'Consentimentos Obrigatórios';

  @override
  String get consentRequiredError =>
      'Você deve aceitar a Política de Privacidade e os Termos e Condições para se registrar';

  @override
  String get contactSupport => 'Contatar Suporte';

  @override
  String get continueLearningBtn => 'Continuar';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get continueWithFacebook => 'Continuar com Facebook';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get conversationCategory => 'Conversação';

  @override
  String get correctAnswer => 'Correto!';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get culturalCategory => 'Cultural';

  @override
  String get culturalExchangeBeFirstTip =>
      'Seja o primeiro a compartilhar uma dica cultural!';

  @override
  String get culturalExchangeCategory => 'Categoria';

  @override
  String get culturalExchangeCommunityTips => 'Dicas da Comunidade';

  @override
  String get culturalExchangeCountry => 'País';

  @override
  String get culturalExchangeCountryHint => 'ex., Japão, Brasil, França';

  @override
  String get culturalExchangeCountrySpotlight => 'Destaque de País';

  @override
  String get culturalExchangeDailyInsight => 'Conhecimento Cultural Diário';

  @override
  String get culturalExchangeDatingEtiquette => 'Etiqueta de Encontros';

  @override
  String get culturalExchangeDatingEtiquetteGuide =>
      'Guia de Etiqueta de Encontros';

  @override
  String get culturalExchangeLoadingCountries => 'Carregando países...';

  @override
  String get culturalExchangeNoTips => 'Sem dicas ainda';

  @override
  String get culturalExchangeShareCulturalTip =>
      'Compartilhar uma Dica Cultural';

  @override
  String get culturalExchangeShareTip => 'Compartilhar uma Dica';

  @override
  String get culturalExchangeSubmitTip => 'Enviar Dica';

  @override
  String get culturalExchangeTipTitle => 'Título';

  @override
  String get culturalExchangeTipTitleHint => 'Dê à sua dica um título atraente';

  @override
  String get culturalExchangeTitle => 'Intercâmbio Cultural';

  @override
  String get culturalExchangeViewAll => 'Ver Todos';

  @override
  String get culturalExchangeYourTip => 'Sua Dica';

  @override
  String get culturalExchangeYourTipHint =>
      'Compartilhe seu conhecimento cultural...';

  @override
  String get dailyChallengesSubtitle =>
      'Complete desafios para ganhar recompensas';

  @override
  String get dailyChallengesTitle => 'Desafios Diários';

  @override
  String dailyLimitReached(int limit) {
    return 'Limite diário de $limit atingido';
  }

  @override
  String get dailyMessages => 'Mensagens Diárias';

  @override
  String get dailyRewardHeader => 'Recompensa Diária';

  @override
  String get dailySwipeLimitReached =>
      'Limite diário de swipes atingido. Atualize para mais swipes!';

  @override
  String get dailySwipes => 'Swipes Diários';

  @override
  String get dataExportSentToEmail =>
      'Exportação de dados enviada para seu e-mail';

  @override
  String get dateOfBirth => 'Data de Nascimento';

  @override
  String get datePlanningCategory => 'Planejar Encontro';

  @override
  String get dateSchedulerAccept => 'Aceitar';

  @override
  String get dateSchedulerCancelConfirm =>
      'Tem certeza de que deseja cancelar este encontro?';

  @override
  String get dateSchedulerCancelTitle => 'Cancelar Encontro';

  @override
  String get dateSchedulerConfirmed => 'Encontro confirmado!';

  @override
  String get dateSchedulerDecline => 'Recusar';

  @override
  String get dateSchedulerEnterTitle => 'Por favor, insira um título';

  @override
  String get dateSchedulerKeepDate => 'Manter Encontro';

  @override
  String get dateSchedulerNotesLabel => 'Observações (opcional)';

  @override
  String get dateSchedulerPlanningHint => 'ex: Café, Jantar, Cinema...';

  @override
  String get dateSchedulerReasonLabel => 'Motivo (opcional)';

  @override
  String get dateSchedulerReschedule => 'Reagendar';

  @override
  String get dateSchedulerRescheduleTitle => 'Reagendar Encontro';

  @override
  String get dateSchedulerSchedule => 'Agendar';

  @override
  String get dateSchedulerScheduled => 'Encontro agendado!';

  @override
  String get dateSchedulerTabPast => 'Anteriores';

  @override
  String get dateSchedulerTabPending => 'Pendentes';

  @override
  String get dateSchedulerTabUpcoming => 'Próximos';

  @override
  String get dateSchedulerTitle => 'Meus Encontros';

  @override
  String get dateSchedulerWhatPlanning => 'O que você está planejando?';

  @override
  String dayNumber(int day) {
    return 'Dia $day';
  }

  @override
  String dayStreakCount(String count) {
    return '$count dias de sequência';
  }

  @override
  String dayStreakLabel(int days) {
    return 'Sequência de $days Dias!';
  }

  @override
  String get days => 'Dias';

  @override
  String daysAgo(int count) {
    return 'há $count dias';
  }

  @override
  String get delete => 'Excluir';

  @override
  String get deleteAccount => 'Excluir Conta';

  @override
  String get deleteAccountConfirmation =>
      'Você tem certeza de que quer excluir sua conta? Esta ação não pode ser desfeita e todos os seus dados serão excluídos permanentemente.';

  @override
  String get details => 'Detalhes';

  @override
  String get difficultyLabel => 'Dificuldade';

  @override
  String directMessageCost(int cost) {
    return 'Mensagens diretas custam $cost moedas. Deseja comprar mais moedas?';
  }

  @override
  String get discover => 'Rede';

  @override
  String discoveryError(String error) {
    return 'Erro: $error';
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
  String get discoveryFilterPassed => 'Recusados';

  @override
  String get discoveryFilterSkipped => 'Explorados';

  @override
  String get discoveryFilterSuperLiked => 'Prioritário';

  @override
  String get discoveryFilterNetwork => 'Minha Rede';

  @override
  String get discoveryFilterTravelers => 'Viajantes';

  @override
  String get discoveryLimitReached => 'Você atingiu seu limite de descobertas';

  @override
  String discoverySeeMoreCoins(int coins) {
    return 'Gaste $coins moedas para ver mais';
  }

  @override
  String get discoveryPreferencesTitle => 'Preferencias de Descoberta';

  @override
  String get discoveryPreferencesTooltip => 'Preferências de Descoberta';

  @override
  String get discoverySwitchToGrid => 'Mudar para modo de grade';

  @override
  String get discoverySwitchToSwipe => 'Mudar para modo de deslizar';

  @override
  String get dismiss => 'Fechar';

  @override
  String get distance => 'Distância';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get documentNotAvailable => 'Documento não disponível';

  @override
  String get documentNotAvailableDescription =>
      'Este documento ainda não está disponível no seu idioma.';

  @override
  String get done => 'Concluído';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get download => 'Baixar';

  @override
  String downloadProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String downloadingLanguage(String language) {
    return 'Baixando $language...';
  }

  @override
  String get downloadingTranslationData => 'Baixando Dados de Tradução';

  @override
  String get edit => 'Editar';

  @override
  String get editInterests => 'Editar Interesses';

  @override
  String get editNickname => 'Editar Apelido';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get editVoiceComingSoon => 'Editar voz em breve';

  @override
  String get education => 'Educação';

  @override
  String get email => 'E-mail';

  @override
  String get emailInvalid => 'Por favor insira um e-mail válido';

  @override
  String get emailRequired => 'E-mail é obrigatório';

  @override
  String get emergencyCategory => 'Emergência';

  @override
  String get emptyStateErrorMessage =>
      'Não conseguimos carregar este conteúdo. Tente novamente.';

  @override
  String get emptyStateErrorTitle => 'Algo deu errado';

  @override
  String get emptyStateNoInternetMessage =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get emptyStateNoInternetTitle => 'Sem conexão';

  @override
  String get emptyStateNoLikesMessage =>
      'Complete seu perfil para receber mais curtidas!';

  @override
  String get emptyStateNoLikesTitle => 'Nenhuma curtida ainda';

  @override
  String get emptyStateNoMatchesMessage =>
      'Comece a deslizar para encontrar seu par perfeito!';

  @override
  String get emptyStateNoMatchesTitle => 'Nenhum match ainda';

  @override
  String get emptyStateNoMessagesMessage =>
      'Quando você combinar com alguém, poderá começar a conversar aqui.';

  @override
  String get emptyStateNoMessagesTitle => 'Nenhuma mensagem';

  @override
  String get emptyStateNoNotificationsMessage =>
      'Você não tem nenhuma notificação nova.';

  @override
  String get emptyStateNoNotificationsTitle => 'Tudo em dia!';

  @override
  String get emptyStateNoResultsMessage =>
      'Tente ajustar sua busca ou filtros.';

  @override
  String get emptyStateNoResultsTitle => 'Nenhum resultado encontrado';

  @override
  String get enableAutoTranslation => 'Ativar Tradução Automática';

  @override
  String get enableNotifications => 'Ativar Notificações';

  @override
  String get enterAmount => 'Inserir valor';

  @override
  String get enterNickname => 'Digite o apelido';

  @override
  String get enterNicknameHint => 'Insira o apelido';

  @override
  String get enterNicknameToFind =>
      'Digite um apelido para encontrar alguém diretamente';

  @override
  String get enterRejectionReason => 'Introduza o motivo da rejeição';

  @override
  String error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get errorLoadingDocument => 'Erro ao carregar documento';

  @override
  String get errorSearchingTryAgain => 'Erro na busca. Tente novamente.';

  @override
  String get eventsAboutThisEvent => 'Sobre este evento';

  @override
  String get eventsApplyFilters => 'Aplicar Filtros';

  @override
  String get eventsAttendees => 'Participantes';

  @override
  String eventsAttending(Object going, Object max) {
    return '$going / $max participando';
  }

  @override
  String get eventsBeFirstToSay => 'Seja o primeiro a dizer algo!';

  @override
  String get eventsCategory => 'Categoria';

  @override
  String get eventsChatWithAttendees => 'Converse com outros participantes';

  @override
  String get eventsCheckBackLater =>
      'Volte mais tarde ou crie seu proprio evento!';

  @override
  String get eventsCreateEvent => 'Criar Evento';

  @override
  String get eventsCreatedSuccessfully => 'Evento criado com sucesso!';

  @override
  String get eventsDateRange => 'Intervalo de Datas';

  @override
  String get eventsDeleted => 'Evento excluído';

  @override
  String get eventsDescription => 'Descricao';

  @override
  String get eventsDistance => 'Distancia';

  @override
  String get eventsEndDateTime => 'Data e Hora de Termino';

  @override
  String get eventsErrorLoadingMessages => 'Erro ao carregar mensagens';

  @override
  String get eventsEventFull => 'Evento Lotado';

  @override
  String get eventsEventTitle => 'Titulo do Evento';

  @override
  String get eventsFilterEvents => 'Filtrar Eventos';

  @override
  String get eventsFreeEvent => 'Evento Gratuito';

  @override
  String get eventsFreeLabel => 'GRATUITO';

  @override
  String get eventsFullLabel => 'Lotado';

  @override
  String eventsGoing(Object count) {
    return '$count vao participar';
  }

  @override
  String get eventsGoingLabel => 'Vou';

  @override
  String get eventsGroupChatTooltip => 'Chat do Grupo do Evento';

  @override
  String get eventsJoinEvent => 'Participar do Evento';

  @override
  String get eventsJoinLabel => 'Participar';

  @override
  String eventsKmAwayFormat(String km) {
    return 'a $km km';
  }

  @override
  String get eventsLanguageExchange => 'Intercambio Linguistico';

  @override
  String get eventsLanguagePairs => 'Pares de Idiomas (ex., Espanhol ↔ Ingles)';

  @override
  String eventsLanguages(String languages) {
    return 'Idiomas: $languages';
  }

  @override
  String get eventsLocation => 'Localizacao';

  @override
  String eventsMAwayFormat(Object meters) {
    return 'a $meters m';
  }

  @override
  String get eventsMaxAttendees => 'Max. Participantes';

  @override
  String get eventsNoAttendeesYet =>
      'Nenhum participante ainda. Seja o primeiro!';

  @override
  String get eventsNoEventsFound => 'Nenhum evento encontrado';

  @override
  String get eventsNoMessagesYet => 'Sem mensagens ainda';

  @override
  String get eventsRequired => 'Obrigatorio';

  @override
  String get eventsRsvpCancelled => 'Participacao cancelada';

  @override
  String get eventsRsvpUpdated => 'Participacao atualizada!';

  @override
  String eventsSpotsLeft(Object count) {
    return '$count vagas disponiveis';
  }

  @override
  String get eventsStartDateTime => 'Data e Hora de Inicio';

  @override
  String get eventsTabMyEvents => 'Meus Eventos';

  @override
  String get eventsTabExperiences => 'Experiências';

  @override
  String get eventsTabAttractions => 'Atrações';

  @override
  String get eventsTabCommunity => 'Comunidade';

  @override
  String get eventsDeleteEvent => 'Excluir evento';

  @override
  String get eventsDeleteConfirmBody =>
      'Tem certeza de que deseja excluir este evento? Isso não pode ser desfeito.';

  @override
  String get eventsBook => 'Reservar';

  @override
  String get eventsFromPrice => 'a partir de';

  @override
  String get eventsTabNearby => 'Perto';

  @override
  String get eventsTabUpcoming => 'Próximos';

  @override
  String get eventsThisMonth => 'Este Mês';

  @override
  String get eventsDateUntil => 'Até';

  @override
  String get eventsDateFrom => 'A partir de';

  @override
  String get eventsCustomRange => 'Intervalo personalizado';

  @override
  String get eventsDateAnyTime => 'A qualquer momento';

  @override
  String get eventsThisWeekFilter => 'Esta Semana';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get eventsAndPlacesTitle => 'Eventos e lugares';

  @override
  String get eventsCategoryAll => 'Todos';

  @override
  String attractionVisitWebsite(String host) {
    return 'Abrir $host';
  }

  @override
  String get attractionVisitWikidata => 'Abrir wikidata.org';

  @override
  String get attractionOpenInMaps => 'Abrir no Maps';

  @override
  String get attractionOpenLink => 'Abrir link';

  @override
  String get attractionOpenWebsite => 'Abrir site oficial';

  @override
  String get attractionShareChat => 'Compartilhar no chat';

  @override
  String get attractionShareGroup => 'Compartilhar no grupo';

  @override
  String get attractionDescribedAt => 'Saiba mais';

  @override
  String get attractionReport => 'Denunciar evento';

  @override
  String get attractionReportConfirm =>
      'Denunciar este item como inadequado ou incorreto?';

  @override
  String get eventsToday => 'Hoje';

  @override
  String get eventsTypeAMessage => 'Digite uma mensagem...';

  @override
  String get exit => 'Sair';

  @override
  String get exitApp => 'Sair do App?';

  @override
  String get exitAppConfirmation =>
      'Tem certeza de que deseja sair do GreenGo?';

  @override
  String get exploreLanguages => 'Explorar Idiomas';

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get communityTabTitle => 'Comunidade';

  @override
  String exploreHeadline(String city) {
    return 'Explore $city';
  }

  @override
  String get exploreSubtitle =>
      'Experiências culturais e parceiros de idioma perto de você';

  @override
  String get explorePracticeLanguage => 'Pratique um idioma';

  @override
  String get exploreNetworkDiscovery => 'Descoberta de Rede';

  @override
  String exploreNetworkDiscoverySubtitle(String country) {
    return 'Pessoas para se conectar em $country';
  }

  @override
  String get exploreSeeAll => 'Ver tudo';

  @override
  String get exploreHappeningThisWeek => 'Acontecendo esta semana';

  @override
  String get exploreHappeningToday => 'Hoje';

  @override
  String get exploreJoin => 'Participar';

  @override
  String get exploreFeatured => 'Experiência em destaque';

  @override
  String exploreSpeaksLearning(String speaks, String learning) {
    return 'fala $speaks · aprendendo $learning';
  }

  @override
  String exploreSpeaks(String language) {
    return 'fala $language';
  }

  @override
  String get exploreAroundYou => 'Pessoas perto de você';

  @override
  String get exploreSameInterests => 'Pessoas com os seus interesses';

  @override
  String exploreSpeaksLanguage(String language) {
    return 'Pessoas que falam $language';
  }

  @override
  String get exploreCommunityEventsNearby =>
      'Eventos da comunidade perto de você';

  @override
  String get exploreNoPartners =>
      'Ainda não há parceiros de idioma por perto — volte em breve.';

  @override
  String get exploreNoEvents =>
      'Ainda não há experiências para mostrar — volte em breve.';

  @override
  String get exploreNoCommunities =>
      'Ainda não há comunidades para participar — volte em breve.';

  @override
  String exploreGoingCount(int count) {
    return '$count confirmados';
  }

  @override
  String get exploreFeaturedEvents => 'Eventos em destaque';

  @override
  String get exploreFeaturedAttractions => 'Atrações em destaque';

  @override
  String get exploreMyNextEvents => 'Meus próximos eventos';

  @override
  String get exploreCommunitiesTitle => 'Comunidades para participar';

  @override
  String exploreMembersCount(int count) {
    return '$count membros';
  }

  @override
  String get exploreCountrySpotlight => 'País em destaque';

  @override
  String get greetingMorning => 'Bom dia';

  @override
  String get greetingAfternoon => 'Boa tarde';

  @override
  String get greetingEvening => 'Boa noite';

  @override
  String get greetingNight => 'Boa madrugada';

  @override
  String get statCoins => 'Moedas';

  @override
  String get statTier => 'Nível';

  @override
  String get statCountries => 'Países';

  @override
  String get statPeople => 'Pessoas';

  @override
  String get networkWorldMap => 'Rede Mundial';

  @override
  String networkDiscoveryDistanceKm(String distance) {
    return 'a $distance km';
  }

  @override
  String get connectAction => 'Conectar';

  @override
  String get connectError =>
      'Não foi possível iniciar a conversa. Tente novamente.';

  @override
  String get sayHiAction => 'Dizer oi';

  @override
  String get newConnectionLabel => 'Nova conexão';

  @override
  String get connectionsTitle => 'Conexões';

  @override
  String exploreMapDistanceAway(Object distance) {
    return '~$distance km de distância';
  }

  @override
  String get exploreMapError => 'Não foi possível carregar usuários próximos';

  @override
  String get exploreMapExpandRadius => 'Expandir Raio';

  @override
  String get exploreMapExpandRadiusHint =>
      'Tente aumentar o raio de pesquisa para encontrar mais pessoas.';

  @override
  String get exploreMapNearbyUser => 'Usuário Próximo';

  @override
  String get exploreMapNoOneNearby => 'Ninguém por perto';

  @override
  String get exploreMapOnlineNow => 'Online agora';

  @override
  String get exploreMapPeopleNearYou => 'Pessoas Perto de Você';

  @override
  String get exploreMapRadius => 'Raio:';

  @override
  String get exploreMapVisible => 'Visível';

  @override
  String get exportMyDataGDPR => 'Exportar Meus Dados (LGPD)';

  @override
  String get exportingYourData => 'Exportando seus dados...';

  @override
  String extendCoinsLabel(int cost) {
    return 'Estender ($cost moedas)';
  }

  @override
  String get extendTooltip => 'Estender';

  @override
  String failedToDownloadModel(String language) {
    return 'Falha ao baixar o modelo de $language';
  }

  @override
  String failedToSavePreferences(String error) {
    return 'Falha ao salvar preferências: $error';
  }

  @override
  String featureNotAvailableOnTier(String tier) {
    return 'Recurso não disponível no plano $tier';
  }

  @override
  String get fillCategories => 'Preencha todas as categorias';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterFromMatch => 'Match';

  @override
  String get filterFromSearch => 'Direto';

  @override
  String get filterMessaged => 'Com Mensagens';

  @override
  String get filterNew => 'Novos';

  @override
  String get filterNewMessages => 'Novas';

  @override
  String get filterNotReplied => 'Não lido';

  @override
  String filteredFromTotal(int total) {
    return 'Filtrado de $total';
  }

  @override
  String get filters => 'Filtros';

  @override
  String get finish => 'Finalizar';

  @override
  String get firstName => 'Primeiro Nome';

  @override
  String get firstTo30Wins => 'O primeiro a chegar a 30 vence!';

  @override
  String get flashcardReviewLabel => 'Flashcards';

  @override
  String get flirtyCategory => 'Paquera';

  @override
  String get foodDiningCategory => 'Comida e Restaurante';

  @override
  String get forgotPassword => 'Esqueceu a Senha?';

  @override
  String freeActionsRemaining(int count) {
    return '$count ações gratuitas restantes hoje';
  }

  @override
  String get friendship => 'Amizade';

  @override
  String get gameAbandon => 'Abandonar';

  @override
  String get gameAbandonLoseMessage => 'Você perderá este jogo se sair agora.';

  @override
  String get gameAbandonProgressMessage =>
      'Você perderá seu progresso e voltará ao lobby.';

  @override
  String get gameAbandonTitle => 'Abandonar Jogo?';

  @override
  String get gameAbandonTooltip => 'Abandonar Jogo';

  @override
  String gameCategoriesEnterWordHint(String letter) {
    return 'Digite uma palavra que começa com \"$letter\"...';
  }

  @override
  String get gameCategoriesFilled => 'preenchida';

  @override
  String get gameCategoriesNewLetter => 'Nova Letra!';

  @override
  String gameCategoriesStartsWith(String category, String letter) {
    return '$category — começa com \"$letter\"';
  }

  @override
  String get gameCategoriesTapToFill =>
      'Toque em uma categoria para preencher!';

  @override
  String get gameCategoriesTimesUp =>
      'Tempo esgotado! Aguardando a próxima rodada...';

  @override
  String get gameCategoriesTitle => 'Categorias';

  @override
  String get gameCategoriesWordAlreadyUsedInCategory =>
      'Palavra já usada em outra categoria!';

  @override
  String get gameCategoryAnimals => 'Animais';

  @override
  String get gameCategoryClothing => 'Roupas';

  @override
  String get gameCategoryColors => 'Cores';

  @override
  String get gameCategoryCountries => 'Países';

  @override
  String get gameCategoryFood => 'Comida';

  @override
  String get gameCategoryNature => 'Natureza';

  @override
  String get gameCategoryProfessions => 'Profissões';

  @override
  String get gameCategorySports => 'Esportes';

  @override
  String get gameCategoryTransport => 'Transporte';

  @override
  String get gameChainBreak => 'CORRENTE QUEBRADA!';

  @override
  String get gameChainNextMustStartWith =>
      'A próxima palavra deve começar com: ';

  @override
  String get gameChainNoWordsYet => 'Nenhuma palavra ainda!';

  @override
  String get gameChainStartWithAnyWord =>
      'Comece a corrente com qualquer palavra';

  @override
  String get gameChainTitle => 'Corrente de Vocabulário';

  @override
  String gameChainTypeStartingWithHint(String letter) {
    return 'Digite uma palavra que começa com \"$letter\"...';
  }

  @override
  String get gameChainTypeToStartHint =>
      'Digite uma palavra para começar a corrente...';

  @override
  String gameChainWordsChained(int count) {
    return '$count palavras encadeadas';
  }

  @override
  String get gameCorrect => 'Correto!';

  @override
  String get gameDefaultPlayerName => 'Jogador';

  @override
  String gameGrammarDuelAheadBy(int diff) {
    return '+$diff à frente';
  }

  @override
  String get gameGrammarDuelAnswered => 'Respondeu';

  @override
  String gameGrammarDuelBehindBy(int diff) {
    return '$diff atrás';
  }

  @override
  String get gameGrammarDuelFast => 'RÁPIDO!';

  @override
  String get gameGrammarDuelGrammarQuestion => 'QUESTÃO DE GRAMÁTICA';

  @override
  String gameGrammarDuelPlusPoints(int points) {
    return '+$points pontos!';
  }

  @override
  String gameGrammarDuelStreakCount(int count) {
    return 'x$count sequência!';
  }

  @override
  String get gameGrammarDuelThinking => 'Pensando...';

  @override
  String get gameGrammarDuelTitle => 'Duelo de Gramática';

  @override
  String get gameGrammarDuelVersus => 'VS';

  @override
  String get gameGrammarDuelWrongAnswer => 'Resposta errada!';

  @override
  String get gameInvalidAnswer => 'Inválido!';

  @override
  String get gameLanguageBrazilianPortuguese => 'Português Brasileiro';

  @override
  String get gameLanguageEnglish => 'Inglês';

  @override
  String get gameLanguageFrench => 'Francês';

  @override
  String get gameLanguageGerman => 'Alemão';

  @override
  String get gameLanguageItalian => 'Italiano';

  @override
  String get gameLanguageJapanese => 'Japonês';

  @override
  String get gameLanguagePortuguese => 'Português';

  @override
  String get gameLanguageSpanish => 'Espanhol';

  @override
  String get gameLeave => 'Sair';

  @override
  String get gameOpponent => 'Oponente';

  @override
  String get gameOver => 'Fim de Jogo';

  @override
  String gamePictureGuessAttemptCounter(int current, int max) {
    return 'Tentativa $current/$max';
  }

  @override
  String get gamePictureGuessCantUseWord =>
      'Você não pode usar a própria palavra na sua dica!';

  @override
  String get gamePictureGuessClues => 'DICAS';

  @override
  String gamePictureGuessCluesSent(int count) {
    return '$count dica(s) enviada(s)';
  }

  @override
  String gamePictureGuessCorrectPoints(int points) {
    return 'Correto! +$points pontos';
  }

  @override
  String get gamePictureGuessCorrectWaiting =>
      'Correto! Aguardando o fim da rodada...';

  @override
  String get gamePictureGuessDescriber => 'DESCRITOR';

  @override
  String get gamePictureGuessDescriberRules =>
      'Dê dicas para ajudar os outros a adivinhar. Sem traduções diretas ou dicas de ortografia!';

  @override
  String get gamePictureGuessGuessTheWord => 'Adivinhe a palavra!';

  @override
  String get gamePictureGuessGuessTheWordUpper => 'ADIVINHE A PALAVRA!';

  @override
  String get gamePictureGuessNoMoreAttempts =>
      'Sem mais tentativas — aguardando o fim da rodada';

  @override
  String get gamePictureGuessNoMoreAttemptsRound =>
      'Sem mais tentativas nesta rodada';

  @override
  String get gamePictureGuessTheWordWas => 'A palavra era:';

  @override
  String get gamePictureGuessTitle => 'Adivinhe pela Imagem';

  @override
  String get gamePictureGuessTypeClueHint =>
      'Digite uma dica (sem traduções diretas!)...';

  @override
  String gamePictureGuessTypeGuessHint(int current, int max) {
    return 'Digite sua resposta... ($current/$max)';
  }

  @override
  String get gamePictureGuessWaitingForClues => 'Aguardando dicas...';

  @override
  String get gamePictureGuessWaitingForOthers => 'Aguardando os outros...';

  @override
  String gamePictureGuessWrongGuess(String guess) {
    return 'Resposta errada: \"$guess\"';
  }

  @override
  String get gamePictureGuessYouAreDescriber => 'Você é o DESCRITOR!';

  @override
  String get gamePictureGuessYourWord => 'SUA PALAVRA';

  @override
  String get gamePlayAnswerSubmittedWaiting =>
      'Resposta enviada! Aguardando os outros...';

  @override
  String get gamePlayCategoriesHeader => 'CATEGORIAS';

  @override
  String gamePlayCategoryLabel(String category) {
    return 'Categoria: $category';
  }

  @override
  String gamePlayCorrectPlusPts(int points) {
    return 'Correto! +$points pts';
  }

  @override
  String get gamePlayDescribeThisWord => 'DESCREVA ESTA PALAVRA!';

  @override
  String get gamePlayDescribeWordHint =>
      'Descreva a palavra (não diga ela!)...';

  @override
  String gamePlayDescriberIsDescribing(String name) {
    return '$name está descrevendo uma palavra...';
  }

  @override
  String get gamePlayDoNotSayWord => 'Não diga a própria palavra!';

  @override
  String get gamePlayGuessTheWord => 'ADIVINHE A PALAVRA';

  @override
  String gamePlayIncorrectAnswerWas(String answer) {
    return 'Incorreto. A resposta era \"$answer\"';
  }

  @override
  String get gamePlayLeaderboard => 'CLASSIFICAÇÃO';

  @override
  String gamePlayNameLanguageWordStartingWith(String language, String letter) {
    return 'Diga uma palavra em $language que começa com \"$letter\"';
  }

  @override
  String gamePlayNameWordInCategory(String category, String letter) {
    return 'Diga uma palavra em \"$category\" que começa com \"$letter\"';
  }

  @override
  String get gamePlayNextWordMustStartWith =>
      'A PRÓXIMA PALAVRA DEVE COMEÇAR COM';

  @override
  String get gamePlayNoWordsStartChain =>
      'Nenhuma palavra ainda - comece a corrente!';

  @override
  String get gamePlayPickLetterNameWord =>
      'Escolha uma letra e diga uma palavra!';

  @override
  String gamePlayPlayerIsChoosing(String name) {
    return '$name está escolhendo...';
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
  String get gamePlayTranslateThisWord => 'TRADUZA ESTA PALAVRA';

  @override
  String gamePlayTypeContainingHint(String prompt) {
    return 'Digite uma palavra que contenha \"$prompt\"...';
  }

  @override
  String gamePlayTypeStartingWithHint(String prompt) {
    return 'Digite uma palavra que começa com \"$prompt\"...';
  }

  @override
  String get gamePlayTypeTranslationHint => 'Digite a tradução...';

  @override
  String get gamePlayTypeWordContainingLetters =>
      'Digite uma palavra que contenha estas letras!';

  @override
  String get gamePlayTypeYourAnswerHint => 'Digite sua resposta...';

  @override
  String get gamePlayTypeYourGuessBelow => 'Digite sua resposta abaixo!';

  @override
  String get gamePlayTypeYourGuessHint => 'Digite sua resposta...';

  @override
  String get gamePlayUseChatToDescribe =>
      'Use o chat para descrever a palavra para os outros jogadores';

  @override
  String get gamePlayWaitingForOpponent => 'Aguardando oponente...';

  @override
  String gamePlayWordStartingWithLetterHint(String letter) {
    return 'Palavra que começa com \"$letter\"...';
  }

  @override
  String gamePlayWordStartingWithPromptHint(String prompt) {
    return 'Palavra que começa com \"$prompt\"...';
  }

  @override
  String get gamePlayYourTurnFlipCards => 'Sua vez - vire duas cartas!';

  @override
  String gamePlayersTurn(String name) {
    return 'Vez de $name';
  }

  @override
  String gamePlusPts(int points) {
    return '+$points pts';
  }

  @override
  String get gamePositionFirst => '1º';

  @override
  String gamePositionNth(int pos) {
    return '$posº';
  }

  @override
  String get gamePositionSecond => '2º';

  @override
  String get gamePositionThird => '3º';

  @override
  String get gameResultsBackToLobby => 'Voltar ao Lobby';

  @override
  String get gameResultsBaseXp => 'XP Base';

  @override
  String get gameResultsCoinsEarned => 'Moedas Ganhas';

  @override
  String gameResultsDifficultyBonus(int level) {
    return 'Bônus de Dificuldade (Nv.$level)';
  }

  @override
  String get gameResultsFinalStandings => 'CLASSIFICAÇÃO FINAL';

  @override
  String get gameResultsGameOver => 'FIM DE JOGO';

  @override
  String gameResultsNotEnoughCoins(int amount) {
    return 'Moedas insuficientes ($amount necessárias)';
  }

  @override
  String get gameResultsPlayAgain => 'Jogar Novamente';

  @override
  String gameResultsPlusXp(int amount) {
    return '+$amount XP';
  }

  @override
  String get gameResultsRewardsEarned => 'RECOMPENSAS GANHAS';

  @override
  String get gameResultsTotalXp => 'XP Total';

  @override
  String get gameResultsVictory => 'VITÓRIA!';

  @override
  String get gameResultsWhatYouLearned => 'O QUE VOCÊ APRENDEU';

  @override
  String get gameResultsWinner => 'Vencedor';

  @override
  String get gameResultsWinnerBonus => 'Bônus do Vencedor';

  @override
  String get gameResultsYouWon => 'Você venceu!';

  @override
  String gameRoundCounter(int current, int total) {
    return 'Rodada $current/$total';
  }

  @override
  String gameRoundNumber(int number) {
    return 'Rodada $number';
  }

  @override
  String gameScorePts(int score) {
    return '$score pts';
  }

  @override
  String get gameSnapsNoMatch => 'Sem combinação';

  @override
  String gameSnapsPairsFound(int matched, int total) {
    return '$matched / $total pares encontrados';
  }

  @override
  String get gameSnapsTitle => 'Snaps de Idiomas';

  @override
  String get gameSnapsYourTurnFlipCards => 'SUA VEZ — Vire 2 cartas!';

  @override
  String get gameSomeone => 'Alguém';

  @override
  String gameTapplesNameWordStartingWith(String letter) {
    return 'Diga uma palavra que começa com \"$letter\"';
  }

  @override
  String get gameTapplesPickLetterFromWheel => 'Escolha uma letra da roda!';

  @override
  String get gameTapplesPickLetterNameWord =>
      'Escolha uma letra, diga uma palavra';

  @override
  String gameTapplesPlayerLostLife(String name) {
    return '$name perdeu uma vida';
  }

  @override
  String get gameTapplesTimeUp => 'TEMPO ESGOTADO!';

  @override
  String get gameTapplesTitle => 'Tapples de Idiomas';

  @override
  String gameTapplesWordStartingWithHint(String letter) {
    return 'Palavra que começa com \"$letter\"...';
  }

  @override
  String gameTapplesWordsUsedLettersLeft(int wordsCount, int lettersCount) {
    return '$wordsCount palavras usadas  •  $lettersCount letras restantes';
  }

  @override
  String get gameTranslationRaceCheckCorrect => 'Correto';

  @override
  String get gameTranslationRaceFirstTo30 => 'O primeiro a chegar a 30 vence!';

  @override
  String gameTranslationRaceRoundShort(int current, int total) {
    return 'R$current/$total';
  }

  @override
  String get gameTranslationRaceTitle => 'Corrida de Tradução';

  @override
  String gameTranslationRaceTranslateTo(String language) {
    return 'Traduza para $language';
  }

  @override
  String gameTranslationRaceWaitingForOthers(int answered, int total) {
    return 'Aguardando os outros... $answered/$total responderam';
  }

  @override
  String get gameWaitForYourTurn => 'Aguarde sua vez...';

  @override
  String get gameWaiting => 'Aguardando';

  @override
  String get gameWaitingCancelReady => 'Cancelar Pronto';

  @override
  String get gameWaitingCountdownGo => 'VAI!';

  @override
  String get gameWaitingDisconnected => 'Desconectado';

  @override
  String get gameWaitingEllipsis => 'Aguardando...';

  @override
  String get gameWaitingForPlayers => 'Aguardando Jogadores...';

  @override
  String get gameWaitingGetReady => 'Preparem-se...';

  @override
  String get gameWaitingHost => 'ANFITRIÃO';

  @override
  String get gameWaitingInviteCodeCopied => 'Código de convite copiado!';

  @override
  String get gameWaitingInviteCodeHeader => 'CÓDIGO DE CONVITE';

  @override
  String get gameWaitingInvitePlayer => 'Convidar Jogador';

  @override
  String get gameWaitingLeaveRoom => 'Sair da Sala';

  @override
  String gameWaitingLevelNumber(int level) {
    return 'Nível $level';
  }

  @override
  String get gameWaitingNotReady => 'Não Pronto';

  @override
  String gameWaitingNotReadyCount(int count) {
    return '($count não prontos)';
  }

  @override
  String get gameWaitingPlayersHeader => 'JOGADORES';

  @override
  String gameWaitingPlayersInRoom(int count) {
    return '$count jogadores na sala';
  }

  @override
  String get gameWaitingReady => 'Pronto';

  @override
  String get gameWaitingReadyUp => 'Ficar Pronto';

  @override
  String gameWaitingRoundsCount(int count) {
    return '$count rodadas';
  }

  @override
  String get gameWaitingShareCode =>
      'Compartilhe este código com amigos para entrar';

  @override
  String get gameWaitingStartGame => 'Iniciar Jogo';

  @override
  String get gameWordAlreadyUsed => 'Palavra já utilizada!';

  @override
  String get gameWordBombBoom => 'BOOM!';

  @override
  String gameWordBombMustContain(String prompt) {
    return 'A palavra deve conter \"$prompt\"';
  }

  @override
  String get gameWordBombReport => 'Denunciar';

  @override
  String get gameWordBombReportContent =>
      'Denunciar esta palavra como inválida ou inapropriada.';

  @override
  String gameWordBombReportTitle(String word) {
    return 'Denunciar \"$word\"?';
  }

  @override
  String get gameWordBombTimeRanOutLostLife =>
      'Tempo esgotado! Você perdeu uma vida.';

  @override
  String get gameWordBombTitle => 'Bomba de Palavras';

  @override
  String gameWordBombTypeContainingHint(String prompt) {
    return 'Digite uma palavra que contenha \"$prompt\"...';
  }

  @override
  String get gameWordBombUsedWords => 'Palavras Usadas';

  @override
  String get gameWordBombWordReported => 'Palavra denunciada';

  @override
  String gameWordBombWordsUsedCount(int count) {
    return '$count palavras usadas';
  }

  @override
  String gameWordMustStartWith(String letter) {
    return 'A palavra deve começar com \"$letter\"';
  }

  @override
  String get gameWrong => 'Errado';

  @override
  String get gameYou => 'Você';

  @override
  String get gameYourTurn => 'SUA VEZ!';

  @override
  String get gamificationAchievements => 'Conquistas';

  @override
  String get gamificationAll => 'Todos';

  @override
  String gamificationChallengeCompleted(Object name) {
    return '$name concluído!';
  }

  @override
  String get gamificationClaim => 'Resgatar';

  @override
  String get gamificationClaimReward => 'Resgatar Recompensa';

  @override
  String get gamificationCoinsAvailable => 'Moedas Disponíveis';

  @override
  String get gamificationDaily => 'Diário';

  @override
  String get gamificationDailyChallenges => 'Desafios Diários';

  @override
  String get gamificationDayStreak => 'Dias Consecutivos';

  @override
  String get gamificationDone => 'Concluído';

  @override
  String gamificationEarnedOn(Object date) {
    return 'Ganho em $date';
  }

  @override
  String get gamificationEasy => 'Fácil';

  @override
  String get gamificationEngagement => 'Engajamento';

  @override
  String get gamificationEpic => 'Épico';

  @override
  String get gamificationExperiencePoints => 'Pontos de Experiência';

  @override
  String get gamificationGlobal => 'Global';

  @override
  String get gamificationHard => 'Difícil';

  @override
  String get gamificationLeaderboard => 'Ranking';

  @override
  String gamificationLevel(Object level) {
    return 'Nível $level';
  }

  @override
  String get gamificationLevelLabel => 'NÍVEL';

  @override
  String gamificationLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get gamificationLoadingAchievements => 'Carregando conquistas...';

  @override
  String get gamificationLoadingChallenges => 'Carregando desafios...';

  @override
  String get gamificationLoadingRankings => 'Carregando rankings...';

  @override
  String get gamificationMedium => 'Médio';

  @override
  String get gamificationMilestones => 'Marcos';

  @override
  String get gamificationMonthly => 'Mes';

  @override
  String get gamificationMyProgress => 'Meu Progresso';

  @override
  String get gamificationNoAchievements => 'Nenhuma conquista encontrada';

  @override
  String get gamificationNoAchievementsInCategory =>
      'Nenhuma conquista nesta categoria';

  @override
  String get gamificationNoChallenges => 'Nenhum desafio disponível';

  @override
  String gamificationNoChallengesType(Object type) {
    return 'Nenhum desafio $type disponível';
  }

  @override
  String get gamificationNoLeaderboard => 'Sem dados de ranking';

  @override
  String get gamificationPremium => 'Premium';

  @override
  String get gamificationPremiumMember => 'Membro Premium';

  @override
  String get gamificationProgress => 'Progresso';

  @override
  String get gamificationRank => 'POSIÇÃO';

  @override
  String get gamificationRankLabel => 'Posição';

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
  String get gamificationVerifiedUser => 'Usuário Verificado';

  @override
  String get gamificationVipMember => 'Membro VIP';

  @override
  String get gamificationWeekly => 'Semanal';

  @override
  String get gamificationXpAvailable => 'XP Disponível';

  @override
  String get gamificationYearly => 'Ano';

  @override
  String get gamificationYourPosition => 'Sua Posição';

  @override
  String get gender => 'Gênero';

  @override
  String get getStarted => 'Começar';

  @override
  String get giftCategoryAll => 'Todos';

  @override
  String giftFromSender(Object name) {
    return 'De $name';
  }

  @override
  String get giftGetCoins => 'Obter Moedas';

  @override
  String get giftNoGiftsAvailable => 'Nenhum presente disponível';

  @override
  String get giftNoGiftsInCategory => 'Nenhum presente nesta categoria';

  @override
  String get giftNoGiftsYet => 'Sem presentes ainda';

  @override
  String get giftNotEnoughCoins => 'Moedas Insuficientes';

  @override
  String giftPriceCoins(Object price) {
    return '$price moedas';
  }

  @override
  String get giftReceivedGifts => 'Presentes Recebidos';

  @override
  String get giftReceivedGiftsEmpty =>
      'Os presentes que você receber aparecerão aqui';

  @override
  String get giftSendGift => 'Enviar Presente';

  @override
  String giftSendGiftTo(Object name) {
    return 'Enviar Presente para $name';
  }

  @override
  String get giftSending => 'Enviando...';

  @override
  String giftSentTo(Object name) {
    return 'Presente enviado para $name!';
  }

  @override
  String giftYouHaveCoins(Object available) {
    return 'Você tem $available moedas.';
  }

  @override
  String giftYouNeedCoins(Object required) {
    return 'Você precisa de $required moedas para este presente.';
  }

  @override
  String giftYouNeedMoreCoins(Object shortfall) {
    return 'Você precisa de mais $shortfall moedas.';
  }

  @override
  String get gold => 'Ouro';

  @override
  String get grantAlbumAccess => 'Compartilhar meu álbum';

  @override
  String get greatInterestsHelp =>
      'Ótimo! Seus interesses nos ajudam a encontrar melhores combinações';

  @override
  String get greengoLearn => 'GreenGo Learn';

  @override
  String get greengoPlay => 'GreenGo Play';

  @override
  String get greengoXpLabel => 'GreenGoXP';

  @override
  String get greetingsCategory => 'Saudações';

  @override
  String get guideBadge => 'Guia';

  @override
  String get height => 'Altura';

  @override
  String get helpAndSupport => 'Ajuda e Suporte';

  @override
  String get helpOthersFindYou =>
      'Ajude outros a te encontrar nas redes sociais';

  @override
  String get hours => 'Horas';

  @override
  String get icebreakersCategoryCompliments => 'Elogios';

  @override
  String get icebreakersCategoryDateIdeas => 'Ideias para Encontros';

  @override
  String get icebreakersCategoryDeep => 'Profundo';

  @override
  String get icebreakersCategoryDreams => 'Sonhos';

  @override
  String get icebreakersCategoryFood => 'Comida';

  @override
  String get icebreakersCategoryFunny => 'Divertido';

  @override
  String get icebreakersCategoryHobbies => 'Hobbies';

  @override
  String get icebreakersCategoryHypothetical => 'Hipotético';

  @override
  String get icebreakersCategoryMovies => 'Filmes';

  @override
  String get icebreakersCategoryMusic => 'Música';

  @override
  String get icebreakersCategoryPersonality => 'Personalidade';

  @override
  String get icebreakersCategoryTravel => 'Viagens';

  @override
  String get icebreakersCategoryTwoTruths => 'Duas Verdades';

  @override
  String get icebreakersCategoryWouldYouRather => 'O Que Você Prefere';

  @override
  String get icebreakersLabel => 'Quebra-gelo';

  @override
  String get icebreakersNoneInCategory => 'Nenhum quebra-gelo nesta categoria';

  @override
  String get icebreakersQuickAnswers => 'Respostas rápidas:';

  @override
  String get icebreakersSendAnIcebreaker => 'Enviar um quebra-gelo';

  @override
  String icebreakersSendTo(Object name) {
    return 'Enviar para $name';
  }

  @override
  String get icebreakersSendWithoutAnswer => 'Enviar sem resposta';

  @override
  String get icebreakersTitle => 'Quebra-gelos';

  @override
  String get idiomsCategory => 'Expressões Idiomáticas';

  @override
  String get incognitoMode => 'Modo Incógnito';

  @override
  String get incognitoModeDescription => 'Ocultar seu perfil da descoberta';

  @override
  String get incorrectAnswer => 'Incorreto';

  @override
  String get infoUpdatedMessage => 'Suas informações básicas foram salvas';

  @override
  String get infoUpdatedTitle => 'Informações Atualizadas!';

  @override
  String get insufficientCoins => 'Moedas insuficientes';

  @override
  String get insufficientCoinsTitle => 'Moedas Insuficientes';

  @override
  String get interestArt => 'Arte';

  @override
  String get interestBeach => 'Praia';

  @override
  String get interestBeer => 'Cerveja';

  @override
  String get interestBusiness => 'Negócios';

  @override
  String get interestCamping => 'Acampamento';

  @override
  String get interestCats => 'Gatos';

  @override
  String get interestCoffee => 'Café';

  @override
  String get interestCooking => 'Culinária';

  @override
  String get interestCycling => 'Ciclismo';

  @override
  String get interestDance => 'Dança';

  @override
  String get interestDancing => 'Dança';

  @override
  String get interestDogs => 'Cachorros';

  @override
  String get interestEntrepreneurship => 'Empreendedorismo';

  @override
  String get interestEnvironment => 'Meio Ambiente';

  @override
  String get interestFashion => 'Moda';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFood => 'Comida';

  @override
  String get interestGaming => 'Jogos';

  @override
  String get interestHiking => 'Trilhas';

  @override
  String get interestHistory => 'História';

  @override
  String get interestInvesting => 'Investimento';

  @override
  String get interestLanguages => 'Idiomas';

  @override
  String get interestMeditation => 'Meditação';

  @override
  String get interestMountains => 'Montanhas';

  @override
  String get interestMovies => 'Filmes';

  @override
  String get interestMusic => 'Música';

  @override
  String get interestNature => 'Natureza';

  @override
  String get interestPets => 'Animais de estimação';

  @override
  String get interestPhotography => 'Fotografia';

  @override
  String get interestPoetry => 'Poesia';

  @override
  String get interestPolitics => 'Política';

  @override
  String get interestReading => 'Leitura';

  @override
  String get interestRunning => 'Corrida';

  @override
  String get interestScience => 'Ciência';

  @override
  String get interestSkiing => 'Esqui';

  @override
  String get interestSnowboarding => 'Snowboard';

  @override
  String get interestSpirituality => 'Espiritualidade';

  @override
  String get interestSports => 'Esportes';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSwimming => 'Natação';

  @override
  String get interestTeaching => 'Ensino';

  @override
  String get interestTechnology => 'Tecnologia';

  @override
  String get interestTravel => 'Viagens';

  @override
  String get interestVegan => 'Vegano';

  @override
  String get interestVegetarian => 'Vegetariano';

  @override
  String get interestVolunteering => 'Voluntariado';

  @override
  String get interestWine => 'Vinho';

  @override
  String get interestWriting => 'Escrita';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interests => 'Interesses';

  @override
  String interestsCount(int count) {
    return '$count interesses';
  }

  @override
  String interestsSelectedCount(int selected, int max) {
    return '$selected/$max interesses selecionados';
  }

  @override
  String get interestsUpdatedMessage => 'Seus interesses foram salvos';

  @override
  String get interestsUpdatedTitle => 'Interesses Atualizados!';

  @override
  String get invalidWord => 'Palavra inválida';

  @override
  String get inviteCodeCopied => 'Código de convite copiado!';

  @override
  String get inviteFriends => 'Convidar Amigos';

  @override
  String get itsAMatch => 'Comece a conectar!';

  @override
  String get joinMessage =>
      'Junte-se ao GreenGoChat e encontre seu par perfeito';

  @override
  String get keepSwiping => 'Continuar Deslizando';

  @override
  String get langMatchBadge => 'Idioma Compativel';

  @override
  String get language => 'Idioma';

  @override
  String languageChangedTo(String language) {
    return 'Idioma alterado para $language';
  }

  @override
  String get languagePacksBtn => 'Pacotes de Idiomas';

  @override
  String get languagePacksShopTitle => 'Loja de Pacotes de Idiomas';

  @override
  String get languagesToDownloadLabel => 'Idiomas para baixar:';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get lastUpdated => 'Última atualização';

  @override
  String get leaderboardSubtitle => 'Classificacoes globais e regionais';

  @override
  String get leaderboardTitle => 'Ranking';

  @override
  String get learn => 'Aprender';

  @override
  String get learningAccuracy => 'Precisão';

  @override
  String get learningActiveThisWeek => 'Ativo Esta Semana';

  @override
  String get learningAddLessonSection => 'Adicionar Seção de Lição';

  @override
  String get learningAiConversationCoach => 'Coach de Conversação IA';

  @override
  String get learningAllCategories => 'Todas as Categorias';

  @override
  String get learningAllLessons => 'Todas as Lições';

  @override
  String get learningAllLevels => 'Todos os Níveis';

  @override
  String get learningAmount => 'Valor';

  @override
  String get learningAmountLabel => 'Valor';

  @override
  String get learningAnalytics => 'Análise';

  @override
  String learningAnswer(Object answer) {
    return 'Resposta: $answer';
  }

  @override
  String get learningApplyFilters => 'Aplicar Filtros';

  @override
  String get learningAreasToImprove => 'Áreas a Melhorar';

  @override
  String get learningAvailableBalance => 'Saldo Disponível';

  @override
  String get learningAverageRating => 'Avaliação Média';

  @override
  String get learningBeginnerProgress => 'Progresso de Iniciante';

  @override
  String get learningBonusCoins => 'Moedas Bônus';

  @override
  String get learningCategory => 'Categoria';

  @override
  String get learningCategoryProgress => 'Progresso por Categoria';

  @override
  String get learningCheck => 'Verificar';

  @override
  String get learningCheckBackSoon => 'Volte em breve!';

  @override
  String get learningCoachSessionCost =>
      '10 moedas/sessão  |  25 XP de recompensa';

  @override
  String get learningContinue => 'Continuar';

  @override
  String get learningCorrect => 'Correto!';

  @override
  String learningCorrectAnswer(Object answer) {
    return 'Correto: $answer';
  }

  @override
  String learningCorrectAnswerIs(Object answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String get learningCorrectAnswers => 'Respostas Corretas';

  @override
  String get learningCorrectLabel => 'Correto';

  @override
  String get learningCorrections => 'Correções';

  @override
  String get learningCreateLesson => 'Criar Lição';

  @override
  String get learningCreateNewLesson => 'Criar Nova Lição';

  @override
  String get learningCustomPackTitleHint =>
      'ex: \"Cumprimentos em Espanhol para Encontros\"';

  @override
  String get learningDescribeImage => 'Descreva esta imagem';

  @override
  String get learningDescriptionHint => 'O que os alunos vão aprender?';

  @override
  String get learningDescriptionLabel => 'Descrição';

  @override
  String get learningDifficultyLevel => 'Nível de Dificuldade';

  @override
  String get learningDone => 'Concluído';

  @override
  String get learningDraftSave => 'Salvar Rascunho';

  @override
  String get learningDraftSaved => 'Rascunho salvo!';

  @override
  String get learningEarned => 'Ganho';

  @override
  String get learningEdit => 'Editar';

  @override
  String get learningEndSession => 'Encerrar Sessão';

  @override
  String get learningEndSessionBody =>
      'O progresso da sessão atual será perdido. Deseja encerrar a sessão e ver a pontuação primeiro?';

  @override
  String get learningEndSessionQuestion => 'Encerrar Sessão?';

  @override
  String get learningExit => 'Sair';

  @override
  String get learningFalse => 'Falso';

  @override
  String get learningFilterAll => 'Todos';

  @override
  String get learningFilterDraft => 'Rascunho';

  @override
  String get learningFilterLessons => 'Filtrar Lições';

  @override
  String get learningFilterPublished => 'Publicado';

  @override
  String get learningFilterUnderReview => 'Em Revisão';

  @override
  String get learningFluency => 'Fluência';

  @override
  String get learningFree => 'FREE';

  @override
  String get learningGoBack => 'Voltar';

  @override
  String get learningGoalCompleteLessons => 'Completar 5 lições';

  @override
  String get learningGoalEarnXp => 'Ganhar 500 XP';

  @override
  String get learningGoalPracticeMinutes => 'Praticar 30 minutos';

  @override
  String get learningGrammar => 'Gramática';

  @override
  String get learningHint => 'Dica';

  @override
  String get learningLangBrazilianPortuguese => 'Português do Brasil';

  @override
  String get learningLangEnglish => 'Inglês';

  @override
  String get learningLangFrench => 'Francês';

  @override
  String get learningLangGerman => 'Alemão';

  @override
  String get learningLangItalian => 'Italiano';

  @override
  String get learningLangPortuguese => 'Português';

  @override
  String get learningLangSpanish => 'Espanhol';

  @override
  String get learningLanguagesSubtitle =>
      'Selecione até 5 idiomas. Isto nos ajuda a conectá-lo com falantes nativos e parceiros de aprendizagem.';

  @override
  String get learningLanguagesTitle => 'Quais idiomas você quer aprender?';

  @override
  String learningLanguagesToLearn(Object count) {
    return 'Idiomas para aprender ($count/5)';
  }

  @override
  String get learningLastMonth => 'Mês Passado';

  @override
  String learningLearnLanguage(Object language) {
    return 'Aprender $language';
  }

  @override
  String get learningLearned => 'Aprendido';

  @override
  String get learningLessonComplete => 'Lição Concluída!';

  @override
  String get learningLessonCompleteUpper => 'LIÇÃO CONCLUÍDA!';

  @override
  String get learningLessonContent => 'Conteúdo da Lição';

  @override
  String learningLessonNumber(Object number) {
    return 'Lição $number';
  }

  @override
  String get learningLessonSubmitted => 'Lição enviada para revisão!';

  @override
  String get learningLessonTitle => 'Título da Lição';

  @override
  String get learningLessonTitleHint =>
      'ex., \"Saudações em Espanhol para Encontros\"';

  @override
  String get learningLessonTitleLabel => 'Título da Lição';

  @override
  String get learningLessonsLabel => 'Lições';

  @override
  String get learningLetsStart => 'Vamos Começar!';

  @override
  String get learningLevel => 'Nível';

  @override
  String learningLevelBadge(Object level) {
    return 'NV $level';
  }

  @override
  String learningLevelRequired(Object level) {
    return 'Nível $level';
  }

  @override
  String get learningListen => 'Ouvir';

  @override
  String get learningListening => 'Ouvindo...';

  @override
  String get learningLongPressForTranslation =>
      'Pressione e segure para tradução';

  @override
  String get learningMessages => 'Mensagens';

  @override
  String get learningMessagesSent => 'Mensagens enviadas';

  @override
  String get learningMinimumWithdrawal => 'Saque mínimo: \$50,00';

  @override
  String get learningMonthlyEarnings => 'Ganhos Mensais';

  @override
  String get learningMyProgress => 'Meu Progresso';

  @override
  String get learningNativeLabel => '(nativo)';

  @override
  String get learningNativeLanguage => 'Sua língua nativa';

  @override
  String learningNeedMinPercent(Object threshold) {
    return 'Você precisa de pelo menos $threshold% para passar nesta lição.';
  }

  @override
  String get learningNext => 'Próximo';

  @override
  String get learningNoExercisesInSection => 'Sem exercícios nesta seção';

  @override
  String get learningNoLessonsAvailable => 'Nenhuma lição disponível ainda';

  @override
  String get learningNoPacksFound => 'Nenhum pacote encontrado';

  @override
  String get learningNoQuestionsAvailable =>
      'Nenhuma pergunta disponível ainda.';

  @override
  String get learningNotQuite => 'Não exatamente';

  @override
  String get learningNotQuiteTitle => 'Quase Lá...';

  @override
  String get learningOpenAiCoach => 'Abrir Coach IA';

  @override
  String learningPackFilter(Object category) {
    return 'Pacote: $category';
  }

  @override
  String get learningPackPurchased => 'Pacote comprado com sucesso!';

  @override
  String get learningPassageRevealed => 'Passagem (revelada)';

  @override
  String get learningPathTitle => 'Trilha de Aprendizado';

  @override
  String get learningPlaying => 'Reproduzindo...';

  @override
  String get learningPleaseEnterDescription =>
      'Por favor, insira uma descrição';

  @override
  String get learningPleaseEnterTitle => 'Por favor, insira um título';

  @override
  String get learningPracticeAgain => 'Praticar Novamente';

  @override
  String get learningPro => 'PRO';

  @override
  String get learningPublishedLessons => 'Lições Publicadas';

  @override
  String get learningPurchased => 'Comprado';

  @override
  String get learningPurchasedLessonsEmpty =>
      'Suas lições compradas aparecerão aqui';

  @override
  String learningQuestionsInLesson(Object count) {
    return '$count perguntas nesta lição';
  }

  @override
  String get learningQuickActions => 'Ações Rápidas';

  @override
  String get learningReadPassage => 'Leia a passagem';

  @override
  String get learningRecentActivity => 'Atividade Recente';

  @override
  String get learningRecentMilestones => 'Marcos Recentes';

  @override
  String get learningRecentTransactions => 'Transações Recentes';

  @override
  String get learningRequired => 'Obrigatório';

  @override
  String get learningResponseRecorded => 'Resposta registrada';

  @override
  String get learningReview => 'Revisão';

  @override
  String get learningSearchLanguages => 'Pesquisar idiomas...';

  @override
  String get learningSectionEditorComingSoon => 'Editor de seções em breve!';

  @override
  String get learningSeeScore => 'Ver Pontuação';

  @override
  String get learningSelectNativeLanguage => 'Selecione sua língua nativa';

  @override
  String get learningSelectScenario => 'Selecione um cenário para começar';

  @override
  String get learningSelectScenarioFirst => 'Selecione um cenário primeiro...';

  @override
  String get learningSessionComplete => 'Sessão Concluída!';

  @override
  String get learningSessionSummary => 'Resumo da Sessão';

  @override
  String get learningShowAll => 'Mostrar Todos';

  @override
  String get learningShowPassageText => 'Mostrar texto da passagem';

  @override
  String get learningSkip => 'Pular';

  @override
  String learningSpendCoinsToUnlock(Object price) {
    return 'Gastar $price moedas para desbloquear esta lição?';
  }

  @override
  String get learningStartFlashcards => 'Iniciar Flashcards';

  @override
  String get learningStartLesson => 'Iniciar Lição';

  @override
  String get learningStartPractice => 'Iniciar Prática';

  @override
  String get learningStartQuiz => 'Iniciar Questionário';

  @override
  String get learningStartingLesson => 'Iniciando lição...';

  @override
  String get learningStop => 'Parar';

  @override
  String get learningStreak => 'Sequência';

  @override
  String get learningStrengths => 'Pontos Fortes';

  @override
  String get learningSubmit => 'Enviar';

  @override
  String get learningSubmitForReview => 'Enviar para Revisão';

  @override
  String get learningSubmitForReviewBody =>
      'Sua lição será revisada pela nossa equipe antes de ficar disponível. Isto geralmente leva 24-48 horas.';

  @override
  String get learningSubmitForReviewQuestion => 'Enviar para Revisão?';

  @override
  String get learningTabAllLessons => 'Todas as Lições';

  @override
  String get learningTabEarnings => 'Ganhos';

  @override
  String get learningTabFlashcards => 'Flashcards';

  @override
  String get learningTabLessons => 'Lições';

  @override
  String get learningTabMyLessons => 'Minhas Lições';

  @override
  String get learningTabMyProgress => 'Meu Progresso';

  @override
  String get learningTabOverview => 'Visão Geral';

  @override
  String get learningTabPhrases => 'Frases';

  @override
  String get learningTabProgress => 'Progresso';

  @override
  String get learningTabPurchased => 'Comprados';

  @override
  String get learningTabQuizzes => 'Quizzes';

  @override
  String get learningTabStudents => 'Alunos';

  @override
  String get learningTapToContinue => 'Toque para continuar';

  @override
  String get learningTapToHearPassage => 'Toque para ouvir a passagem';

  @override
  String get learningTapToListen => 'Toque para ouvir';

  @override
  String get learningTapToMatch => 'Toque nos itens para combiná-los';

  @override
  String get learningTapToRevealTranslation => 'Toque para revelar tradução';

  @override
  String get learningTapWordsToBuild =>
      'Toque nas palavras abaixo para construir a frase';

  @override
  String get learningTargetLanguage => 'Idioma Alvo';

  @override
  String get learningTeacherDashboardTitle => 'Painel do Professor';

  @override
  String get learningTeacherTiers => 'Níveis de Professor';

  @override
  String get learningThisMonth => 'Este Mês';

  @override
  String get learningTopPerformingStudents => 'Melhores Alunos';

  @override
  String get learningTotalStudents => 'Total de Alunos';

  @override
  String get learningTotalStudentsLabel => 'Total de Alunos';

  @override
  String get learningTotalXp => 'XP Total';

  @override
  String get learningTranslatePhrase => 'Traduza esta frase';

  @override
  String get learningTrue => 'Verdadeiro';

  @override
  String get learningTryAgain => 'Tentar Novamente';

  @override
  String get learningTypeAnswerBelow => 'Digite sua resposta abaixo';

  @override
  String get learningTypeAnswerHint => 'Digite sua resposta...';

  @override
  String get learningTypeDescriptionHint => 'Digite sua descrição...';

  @override
  String get learningTypeMessageHint => 'Digite sua mensagem...';

  @override
  String get learningTypeMissingWordHint => 'Digite a palavra que falta...';

  @override
  String get learningTypeSentenceHint => 'Digite a frase...';

  @override
  String get learningTypeTranslationHint => 'Digite sua tradução...';

  @override
  String get learningTypeWhatYouHeardHint => 'Digite o que você ouviu...';

  @override
  String learningUnitLesson(Object lesson, Object unit) {
    return 'Unidade $unit - Lição $lesson';
  }

  @override
  String learningUnitNumber(Object number) {
    return 'Unidade $number';
  }

  @override
  String get learningUnlock => 'Desbloquear';

  @override
  String learningUnlockForCoins(Object price) {
    return 'Desbloquear por $price Moedas';
  }

  @override
  String learningUnlockForCoinsLower(Object price) {
    return 'Desbloquear por $price moedas';
  }

  @override
  String get learningUnlockLesson => 'Desbloquear Lição';

  @override
  String get learningViewAll => 'Ver Todos';

  @override
  String get learningViewAnalytics => 'Ver Análise';

  @override
  String get learningVocabulary => 'Vocabulário';

  @override
  String learningWeek(Object week) {
    return 'Semana $week';
  }

  @override
  String get learningWeeklyGoals => 'Objetivos Semanais';

  @override
  String get learningWhatWillStudentsLearnHint =>
      'O que os alunos vão aprender?';

  @override
  String get learningWhatYouWillLearn => 'O que você vai aprender';

  @override
  String get learningWithdraw => 'Sacar';

  @override
  String get learningWithdrawFunds => 'Sacar Fundos';

  @override
  String get learningWithdrawalSubmitted => 'Pedido de saque enviado!';

  @override
  String get learningWordsAndPhrases => 'Palavras e Frases';

  @override
  String get learningWriteAnswerFreely => 'Escreva sua resposta livremente';

  @override
  String get learningWriteAnswerHint => 'Escreva sua resposta...';

  @override
  String get learningXpEarned => 'XP Ganho';

  @override
  String learningYourAnswer(Object answer) {
    return 'Sua resposta: $answer';
  }

  @override
  String get learningYourScore => 'Sua Pontuação';

  @override
  String get lessThanOneKm => '< 1 km';

  @override
  String get lessonLabel => 'Lição';

  @override
  String get letsChat => 'Vamos conversar!';

  @override
  String get letsExchange => 'Comece a conectar!';

  @override
  String get levelLabel => 'Nivel';

  @override
  String levelLabelN(String level) {
    return 'Nível $level';
  }

  @override
  String get levelTitleEnthusiast => 'Entusiasta';

  @override
  String get levelTitleExpert => 'Especialista';

  @override
  String get levelTitleExplorer => 'Explorador';

  @override
  String get levelTitleLegend => 'Lenda';

  @override
  String get levelTitleMaster => 'Mestre';

  @override
  String get levelTitleNewcomer => 'Novato';

  @override
  String get levelTitleVeteran => 'Veterano';

  @override
  String get levelUp => 'SUBIU DE NÍVEL!';

  @override
  String get levelUpCongratulations => 'Parabéns por alcançar um novo nível!';

  @override
  String get levelUpContinue => 'Continuar';

  @override
  String get levelUpRewards => 'RECOMPENSAS';

  @override
  String get levelUpTitle => 'SUBIU DE NÍVEL!';

  @override
  String get levelUpVIPUnlocked => 'Status VIP Desbloqueado!';

  @override
  String levelUpYouReachedLevel(int level) {
    return 'Você alcançou o Nível $level';
  }

  @override
  String get likes => 'Curtidas';

  @override
  String get limitReachedTitle => 'Limite Atingido';

  @override
  String get listenMe => 'Me escute!';

  @override
  String get loading => 'Carregando...';

  @override
  String get loadingLabel => 'Carregando...';

  @override
  String get localGuideBadge => 'Guia Local';

  @override
  String get location => 'Localização';

  @override
  String get locationAndLanguages => 'Localização e Idiomas';

  @override
  String get locationError => 'Erro de Localização';

  @override
  String get locationNotFound => 'Localização Não Encontrada';

  @override
  String get locationNotFoundMessage =>
      'Não foi possível determinar seu endereço. Por favor, tente novamente ou defina sua localização manualmente mais tarde.';

  @override
  String get locationPermissionDenied => 'Permissão Negada';

  @override
  String get locationPermissionDeniedMessage =>
      'A permissão de localização é necessária para detectar sua localização atual. Por favor, conceda permissão para continuar.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permissão Permanentemente Negada';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'A permissão de localização foi permanentemente negada. Por favor, ative-a nas configurações do seu dispositivo para usar esta funcionalidade.';

  @override
  String get locationRequestTimeout => 'Tempo de Solicitação Esgotado';

  @override
  String get locationRequestTimeoutMessage =>
      'A obtenção da sua localização demorou demais. Por favor, verifique sua conexão e tente novamente.';

  @override
  String get locationServicesDisabled => 'Serviços de Localização Desativados';

  @override
  String get locationServicesDisabledMessage =>
      'Por favor, ative os serviços de localização nas configurações do seu dispositivo para usar esta funcionalidade.';

  @override
  String get locationUnavailable =>
      'Não é possível obter sua localização no momento. Você pode defini-la manualmente mais tarde nas configurações.';

  @override
  String get locationUnavailableTitle => 'Localização Indisponível';

  @override
  String get locationUpdatedMessage =>
      'Suas configurações de localização foram salvas';

  @override
  String get locationUpdatedTitle => 'Localização Atualizada!';

  @override
  String get logOut => 'Sair';

  @override
  String get logOutConfirmation => 'Você tem certeza de que quer sair?';

  @override
  String get login => 'Entrar';

  @override
  String get loginWithBiometrics => 'Entrar com Biometria';

  @override
  String get logout => 'Sair';

  @override
  String get longTermRelationship => 'Relacionamento sério';

  @override
  String get lookingFor => 'Procura';

  @override
  String get lvl => 'NIV';

  @override
  String get manageCouponsTiersRules => 'Gerenciar cupons, níveis e regras';

  @override
  String get matchDetailsTitle => 'Detalhes da Troca';

  @override
  String matchNotifExchangeMsg(String name) {
    return 'Voce e $name querem trocar idiomas!';
  }

  @override
  String get matchNotifKeepSwiping => 'Continuar Deslizando';

  @override
  String get matchNotifLetsChat => 'Vamos conversar!';

  @override
  String get matchNotifLetsExchange => 'COMECE A CONECTAR!';

  @override
  String get matchNotifViewProfile => 'Ver Perfil';

  @override
  String matchPercentage(String percentage) {
    return '$percentage compatibilidade';
  }

  @override
  String matchedOnDate(String date) {
    return 'Match em $date';
  }

  @override
  String matchedWithDate(String name, String date) {
    return 'Voce deu match com $name em $date';
  }

  @override
  String get matches => 'Combinações';

  @override
  String get matchesClearFilters => 'Limpar Filtros';

  @override
  String matchesCount(int count) {
    return '$count combinações';
  }

  @override
  String get matchesFilterAll => 'Todos';

  @override
  String get matchesFilterMessaged => 'Com Mensagens';

  @override
  String get matchesFilterNew => 'Novos';

  @override
  String get matchesNoMatchesFound => 'Nenhum match encontrado';

  @override
  String get matchesNoMatchesYet => 'Nenhum match ainda';

  @override
  String matchesOfCount(int filtered, int total) {
    return '$filtered de $total matches';
  }

  @override
  String matchesOfTotal(int filtered, int total) {
    return '$filtered de $total combinações';
  }

  @override
  String get matchesStartSwiping =>
      'Comece a deslizar para encontrar seus matches!';

  @override
  String get matchesTryDifferent => 'Tente uma pesquisa ou filtro diferente';

  @override
  String maximumInterestsAllowed(int count) {
    return 'Máximo de $count interesses permitidos';
  }

  @override
  String get maybeLater => 'Talvez Depois';

  @override
  String get discoverWorldwideTitle => 'Expanda seus horizontes!';

  @override
  String get discoverWorldwideMessage =>
      'Ainda não há muitas pessoas na sua região, mas o GreenGo conecta você com pessoas do mundo inteiro! Vá até os Filtros e adicione mais países para descobrir pessoas incríveis de todos os cantos do planeta.';

  @override
  String get openFilters => 'Abrir Filtros';

  @override
  String membershipActivatedMessage(
      String tierName, String formattedDate, String coinsText) {
    return 'Assinatura $tierName ativa até $formattedDate$coinsText';
  }

  @override
  String get membershipActivatedTitle => 'Assinatura Ativada!';

  @override
  String get membershipAdvancedFilters => 'Filtros Avançados';

  @override
  String get membershipBase => 'Base';

  @override
  String get membershipBaseMembership => 'Assinatura Base';

  @override
  String get membershipBestValue =>
      'Melhor valor para compromisso a longo prazo!';

  @override
  String get membershipBoostsMonth => 'Impulsos/mês';

  @override
  String get membershipBuyTitle => 'Comprar Assinatura';

  @override
  String get membershipCouponCodeLabel => 'Código do Cupom *';

  @override
  String get membershipCouponHint => 'ex: GOLD2024';

  @override
  String get membershipCurrent => 'Assinatura Atual';

  @override
  String get membershipDailyLikes => 'Conexões Diárias';

  @override
  String get membershipDailyMessagesLabel =>
      'Mensagens Diárias (vazio = ilimitado)';

  @override
  String get membershipDailySwipesLabel => 'Swipes Diários (vazio = ilimitado)';

  @override
  String membershipDaysRemaining(Object days) {
    return '$days dias restantes';
  }

  @override
  String get membershipDurationLabel => 'Duração (dias)';

  @override
  String get membershipEnterCouponHint => 'Insira o código do cupom';

  @override
  String get couponRedeemTitle => 'Resgatar código de cupom';

  @override
  String get couponApplyButton => 'Aplicar';

  @override
  String get couponAppliedSuccess => 'Cupom aplicado';

  @override
  String get couponNotValid => 'Cupom inválido';

  @override
  String get freeBaseWeekInfo =>
      'Sem cupom? Você ganha 1 semana de Base grátis!';

  @override
  String get couponRedeemSubtitle =>
      'Insira seu código para fazer upgrade da assinatura ou ganhar moedas grátis';

  @override
  String get couponRedeemButton => 'Resgatar Cupom';

  @override
  String couponRedeemedSuccess(String grantSummary) {
    return 'Resgatado: $grantSummary';
  }

  @override
  String get couponErrorInvalid => 'Este código de cupom não é válido';

  @override
  String get couponErrorExpired => 'Este cupom expirou';

  @override
  String get couponErrorMaxUsesReached => 'Este cupom atingiu o limite de uso';

  @override
  String get couponErrorEmailMismatch => 'Este cupom é restrito a outra conta';

  @override
  String get couponErrorAlreadyRedeemed => 'Você já usou este cupom';

  @override
  String get couponErrorDisabled => 'Este cupom não está mais ativo';

  @override
  String get couponErrorGeneric =>
      'Não foi possível resgatar o cupom. Tente novamente.';

  @override
  String get registerCouponLabel => 'Código de cupom (opcional)';

  @override
  String get registerCouponHint => 'Insira um código de cupom';

  @override
  String get welcomeGrantTitle => 'Bem-vindo ao GreenGo!';

  @override
  String get welcomeGrantDismiss => 'Entendi';

  @override
  String membershipEquivalentMonthly(Object price) {
    return 'Equivalente a $price/mês';
  }

  @override
  String get membershipErrorLoadingData => 'Erro ao carregar dados';

  @override
  String membershipExpires(Object date) {
    return 'Expira: $date';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get subscriptionAutoRenewInfo =>
      'As assinaturas são renovadas automaticamente, a menos que sejam canceladas pelo menos 24 horas antes do fim do período atual. Gerencie ou cancele quando quiser nas configurações da sua conta na loja.';

  @override
  String get purchasesRestored => 'Compras restauradas.';

  @override
  String get membershipExtendTitle => 'Estenda sua assinatura';

  @override
  String get membershipFeatureComparison => 'Comparação de Funcionalidades';

  @override
  String get membershipGeneric => 'Assinatura';

  @override
  String get membershipGold => 'Gold';

  @override
  String get membershipGreenGoBase => 'GreenGo Base';

  @override
  String get membershipIncognitoMode => 'Modo Incógnito';

  @override
  String get membershipLeaveEmptyLifetime => 'Deixe vazio para vitalício';

  @override
  String get membershipLeaveEmptyUnlimited => 'Deixe vazio para ilimitado';

  @override
  String get membershipLowerThanCurrent => 'Inferior ao seu nível atual';

  @override
  String get membershipMaxUsesLabel => 'Máximo de Usos';

  @override
  String get membershipMonthly => 'Assinaturas Mensais';

  @override
  String get membershipNameDescriptionLabel => 'Nome/Descrição';

  @override
  String get membershipActive => 'Ativo';

  @override
  String get membershipNoActive => 'Sem assinatura ativa';

  @override
  String get membershipNotesLabel => 'Observações';

  @override
  String get membershipOneMonth => '1 mês';

  @override
  String get membershipOneYear => '1 ano';

  @override
  String get membershipPanel => 'Painel de Assinaturas';

  @override
  String get membershipPermanent => 'Permanente';

  @override
  String get membershipPlatinum => 'Platinum';

  @override
  String get membershipPlus500Coins => '+500 MOEDAS';

  @override
  String get membershipPrioritySupport => 'Suporte Prioritário';

  @override
  String get membershipReadReceipts => 'Confirmação de Leitura';

  @override
  String get membershipRequired => 'Assinatura necessária';

  @override
  String get membershipRequiredDescription =>
      'Você precisa ser membro do GreenGo para realizar esta ação.';

  @override
  String get membershipExtendDescription =>
      'Sua assinatura base está ativa. Compre mais um ano para estender a data de vencimento.';

  @override
  String get membershipRewinds => 'Rewinds';

  @override
  String membershipSavePercent(Object percent) {
    return 'ECONOMIZE $percent%';
  }

  @override
  String get membershipSeeWhoLikes => 'Ver quem conecta';

  @override
  String get membershipSilver => 'Silver';

  @override
  String get membershipSubtitle =>
      'Compre uma vez, aproveite funcionalidades premium por 1 mês ou 1 ano';

  @override
  String get membershipSuperLikes => 'Conexões Prioritárias';

  @override
  String get membershipSuperLikesLabel =>
      'Conexões Prioritárias/Dia (vazio = ilimitado)';

  @override
  String get membershipTerms =>
      'Compra única. A assinatura será estendida a partir da sua data de término atual.';

  @override
  String get membershipTermsExtended =>
      'Compra única. A assinatura será estendida a partir da sua data de término atual. Compras de nível superior substituem níveis inferiores.';

  @override
  String get membershipTierLabel => 'Plano de Assinatura *';

  @override
  String membershipTierName(Object tierName) {
    return 'Assinatura $tierName';
  }

  @override
  String membershipYearly(Object percent) {
    return 'Assinaturas Anuais (Economize até $percent%)';
  }

  @override
  String membershipYouHaveTier(Object tierName) {
    return 'Você tem $tierName';
  }

  @override
  String get messages => 'Trocas';

  @override
  String get minutes => 'Minutos';

  @override
  String moreAchievements(int count) {
    return '+$count mais conquistas';
  }

  @override
  String get myBadges => 'Meus Emblemas';

  @override
  String get myProgress => 'Meu Progresso';

  @override
  String get myUsage => 'Meu Uso';

  @override
  String get navLearn => 'Aprender';

  @override
  String get navPlay => 'Jogar';

  @override
  String get nearby => 'Perto';

  @override
  String needCoinsForProfiles(int amount) {
    return 'Você precisa de $amount moedas para desbloquear mais perfis.';
  }

  @override
  String get newLabel => 'NOVO';

  @override
  String get next => 'Próximo';

  @override
  String nextLevelXp(String xp) {
    return 'Próximo nível em $xp XP';
  }

  @override
  String get nickname => 'Apelido';

  @override
  String get nicknameAlreadyTaken => 'Este apelido já está em uso';

  @override
  String get nicknameCheckError => 'Erro ao verificar disponibilidade';

  @override
  String nicknameInfoText(String nickname) {
    return 'Seu apelido é único e pode ser usado para te encontrar. Outros podem te procurar usando @$nickname';
  }

  @override
  String get nicknameMustBe3To20Chars => 'Deve ter 3-20 caracteres';

  @override
  String get nicknameNoConsecutiveUnderscores => 'Sem underscores consecutivos';

  @override
  String get nicknameNoReservedWords => 'Não pode conter palavras reservadas';

  @override
  String get nicknameOnlyAlphanumeric => 'Apenas letras, números e underscores';

  @override
  String get nicknameRequirements =>
      '3-20 caracteres. Apenas letras, números e underscores.';

  @override
  String get nicknameRules => 'Regras do Apelido';

  @override
  String get nicknameSearchChat => 'Conversar';

  @override
  String get nicknameSearchError => 'Erro na pesquisa. Tente novamente.';

  @override
  String get nicknameSearchHelp => 'Insira um nickname para encontrar alguem';

  @override
  String nicknameSearchNoProfile(String nickname) {
    return 'Nenhum perfil encontrado com @$nickname';
  }

  @override
  String get nicknameSearchOwnProfile => 'Esse e o seu proprio perfil!';

  @override
  String get nicknameSearchTitle => 'Pesquisar por Nickname';

  @override
  String get nicknameSearchView => 'Ver';

  @override
  String nicknameSearchActionNope(String nickname) {
    return 'Você selecionou \"Não\" para @$nickname';
  }

  @override
  String nicknameSearchActionSkip(String nickname) {
    return 'Você selecionou \"Pular\" para @$nickname';
  }

  @override
  String nicknameSearchActionPriorityConnect(String nickname) {
    return 'Você selecionou \"Conexão Prioritária\" para @$nickname';
  }

  @override
  String nicknameSearchActionConnect(String nickname) {
    return 'Você selecionou \"Vamos Conectar\" para @$nickname';
  }

  @override
  String nicknameSearchActionMatch(String nickname) {
    return 'É um match com @$nickname!';
  }

  @override
  String nicknameSearchLimitReached(String action) {
    return 'Você atingiu seu limite de $action. Tente novamente mais tarde.';
  }

  @override
  String get nicknameStartWithLetter => 'Começar com uma letra';

  @override
  String get nicknameUpdatedMessage => 'Seu novo apelido está ativo agora';

  @override
  String get nicknameUpdatedSuccess => 'Apelido atualizado com sucesso';

  @override
  String get nicknameUpdatedTitle => 'Apelido Atualizado!';

  @override
  String get no => 'Não';

  @override
  String get noActiveGamesLabel => 'Nenhum jogo ativo';

  @override
  String get noBadgesEarnedYet => 'Nenhum emblema conquistado';

  @override
  String get noInternetConnection => 'Sem conexão com a internet';

  @override
  String get noLanguagesYet => 'Nenhum idioma ainda. Comece a aprender!';

  @override
  String get noLeaderboardData => 'Ainda sem dados no ranking';

  @override
  String get noMatchesFound => 'Nenhuma combinação encontrada';

  @override
  String get noMatchesYet => 'Ainda sem combinações';

  @override
  String get noMessages => 'Ainda sem mensagens';

  @override
  String get noMoreProfiles => 'Não há mais perfis para mostrar';

  @override
  String get noOthersToSee => 'Não há mais pessoas para ver';

  @override
  String get noPendingVerifications => 'Sem verificações pendentes';

  @override
  String get noPhotoSubmitted => 'Nenhuma foto enviada';

  @override
  String get noPreviousProfile => 'Nenhum perfil anterior para voltar';

  @override
  String noProfileFoundWithNickname(String nickname) {
    return 'Nenhum perfil encontrado com @$nickname';
  }

  @override
  String get noResults => 'Sem resultados';

  @override
  String get noSocialProfilesLinked => 'Nenhum perfil social vinculado';

  @override
  String get noVoiceRecording => 'Sem gravação de voz';

  @override
  String get nodeAvailable => 'Disponível';

  @override
  String get nodeCompleted => 'Concluído';

  @override
  String get nodeInProgress => 'Em Andamento';

  @override
  String get nodeLocked => 'Bloqueado';

  @override
  String get notEnoughCoins => 'Moedas insuficientes';

  @override
  String get notNow => 'Agora Não';

  @override
  String get notSet => 'Não definido';

  @override
  String notificationAchievementUnlocked(String name) {
    return 'Conquista Desbloqueada: $name';
  }

  @override
  String notificationCoinsPurchased(int amount) {
    return 'Você comprou com sucesso $amount moedas.';
  }

  @override
  String get notificationDialogEnable => 'Ativar';

  @override
  String get notificationDialogMessage =>
      'Ative as notificações para saber quando receber matches, mensagens e conexões prioritárias.';

  @override
  String get notificationDialogNotNow => 'Agora não';

  @override
  String get notificationDialogTitle => 'Fique conectado';

  @override
  String get notificationEmailSubtitle => 'Receber notificações por email';

  @override
  String get notificationEmailTitle => 'Notificações por Email';

  @override
  String get notificationEnableQuietHours => 'Ativar Horas de Silêncio';

  @override
  String get notificationEndTime => 'Hora de Fim';

  @override
  String get notificationMasterControls => 'Controles Principais';

  @override
  String get notificationMatchExpiring => 'Compatibilidade a Expirar';

  @override
  String get notificationMatchExpiringSubtitle =>
      'Quando uma compatibilidade está prestes a expirar';

  @override
  String notificationNewChat(String nickname) {
    return '@$nickname iniciou uma conversa com você.';
  }

  @override
  String notificationNewLike(String nickname) {
    return 'Você recebeu uma curtida de @$nickname';
  }

  @override
  String get notificationNewLikes => 'Novos Likes';

  @override
  String get notificationNewLikesSubtitle => 'Quando alguém curte você';

  @override
  String notificationNewMatch(String nickname) {
    return 'É um Match! Você deu match com @$nickname. Comece a conversar agora.';
  }

  @override
  String get notificationNewMatches => 'Novas Compatibilidades';

  @override
  String get notificationNewMatchesSubtitle =>
      'Quando você obtém uma nova compatibilidade';

  @override
  String notificationNewMessage(String nickname) {
    return 'Nova mensagem de @$nickname';
  }

  @override
  String get notificationNewMessages => 'Novas Mensagens';

  @override
  String get notificationNewMessagesSubtitle =>
      'Quando alguém envia uma mensagem para você';

  @override
  String get notificationProfileViews => 'Visualizações do Perfil';

  @override
  String get notificationProfileViewsSubtitle => 'Quando alguém vê seu perfil';

  @override
  String get notificationPromotional => 'Promocional';

  @override
  String get notificationPromotionalSubtitle => 'Dicas, ofertas e promoções';

  @override
  String get notificationPushSubtitle =>
      'Receber notificações neste dispositivo';

  @override
  String get notificationPushTitle => 'Notificações Push';

  @override
  String get notificationQuietHours => 'Horas de Silêncio';

  @override
  String get notificationQuietHoursDescription =>
      'Silenciar notificações entre horários definidos';

  @override
  String get notificationQuietHoursSubtitle =>
      'Silenciar notificações durante determinadas horas';

  @override
  String get notificationSettings => 'Configurações de Notificações';

  @override
  String get notificationSettingsTitle => 'Configurações de Notificações';

  @override
  String get notificationSound => 'Som';

  @override
  String get notificationSoundSubtitle => 'Reproduzir som para notificações';

  @override
  String get notificationSoundVibration => 'Som e Vibração';

  @override
  String get notificationStartTime => 'Hora de Início';

  @override
  String notificationSuperLike(String nickname) {
    return 'Você recebeu uma conexão prioritária de @$nickname';
  }

  @override
  String get notificationSuperLikes => 'Conexões Prioritárias';

  @override
  String get notificationSuperLikesSubtitle =>
      'Quando alguém conecta prioritariamente com você';

  @override
  String get notificationTypes => 'Tipos de Notificação';

  @override
  String get notificationVibration => 'Vibração';

  @override
  String get notificationVibrationSubtitle => 'Vibrar para notificações';

  @override
  String get notificationsEmpty => 'Sem notificações ainda';

  @override
  String get notificationsEmptySubtitle =>
      'Quando você receber notificações, elas aparecerão aqui';

  @override
  String get notificationsMarkAllRead => 'Marcar tudo como lido';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get occupation => 'Profissão';

  @override
  String get ok => 'OK';

  @override
  String get onboardingAddPhoto => 'Adicionar Foto';

  @override
  String get onboardingAddPhotosSubtitle =>
      'Adicione fotos que representem o verdadeiro você';

  @override
  String get onboardingAiVerifiedDescription =>
      'Suas fotos são verificadas usando IA para garantir autenticidade';

  @override
  String get onboardingAiVerifiedPhotos => 'Fotos Verificadas por IA';

  @override
  String get onboardingBioHint =>
      'Fale sobre seus interesses, hobbies, o que você procura...';

  @override
  String get onboardingBioMinLength =>
      'A bio deve ter pelo menos 50 caracteres';

  @override
  String get onboardingChooseFromGallery => 'Escolher da Galeria';

  @override
  String get onboardingCompleteAllFields =>
      'Por favor, preencha todos os campos';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingDateOfBirth => 'Data de Nascimento';

  @override
  String get onboardingDisplayName => 'Nome de Exibição';

  @override
  String get onboardingDisplayNameHint => 'Como devemos chamá-lo?';

  @override
  String get onboardingEnterYourName => 'Por favor, insira seu nome';

  @override
  String get onboardingExpressYourself => 'Expresse-se';

  @override
  String get onboardingExpressYourselfSubtitle =>
      'Escreva algo que capture quem você é';

  @override
  String onboardingFailedPickImage(Object error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String onboardingFailedTakePhoto(Object error) {
    return 'Falha ao tirar foto: $error';
  }

  @override
  String get onboardingGenderFemale => 'Feminino';

  @override
  String get onboardingGenderMale => 'Masculino';

  @override
  String get onboardingGenderNonBinary => 'Não-binário';

  @override
  String get onboardingGenderOther => 'Outro';

  @override
  String get onboardingHoldIdNextToFace =>
      'Segure seu documento junto ao rosto';

  @override
  String get onboardingIdentifyAs => 'Me identifico como';

  @override
  String get onboardingInterestsHelpMatches =>
      'Seus interesses nos ajudam a encontrar melhores compatibilidades para você';

  @override
  String get onboardingInterestsSubtitle =>
      'Selecione pelo menos 3 interesses (máx. 10)';

  @override
  String get onboardingLanguages => 'Idiomas';

  @override
  String onboardingLanguagesSelected(Object count) {
    return '$count/3 selecionados';
  }

  @override
  String get onboardingLetsGetStarted => 'Vamos começar';

  @override
  String get onboardingLocation => 'Localização';

  @override
  String get onboardingLocationLater =>
      'Você pode definir sua localização mais tarde nas configurações';

  @override
  String get onboardingMainPhoto => 'PRINCIPAL';

  @override
  String get onboardingMaxInterests => 'Você pode selecionar até 10 interesses';

  @override
  String get onboardingMaxLanguages => 'Você pode selecionar até 3 idiomas';

  @override
  String get onboardingMinInterests =>
      'Por favor, selecione pelo menos 3 interesses';

  @override
  String get onboardingMinLanguage =>
      'Por favor, selecione pelo menos um idioma';

  @override
  String get onboardingMinLocation => 'Defina sua localização para continuar';

  @override
  String get onboardingNameMinLength =>
      'O nome deve ter pelo menos 2 caracteres';

  @override
  String get onboardingNoLocationSelected => 'Nenhuma localização selecionada';

  @override
  String get onboardingOptional => 'Opcional';

  @override
  String get onboardingSelectFromPhotos => 'Selecionar das suas fotos';

  @override
  String onboardingSelectedCount(Object count) {
    return '$count/10 selecionados';
  }

  @override
  String get onboardingShowYourself => 'Mostre-se';

  @override
  String get onboardingTakePhoto => 'Tirar Foto';

  @override
  String get onboardingTellUsAboutYourself => 'Fale um pouco sobre você';

  @override
  String get onboardingTipAuthentic => 'Seja autêntico e genuíno';

  @override
  String get onboardingTipPassions => 'Compartilhe suas paixões e hobbies';

  @override
  String get onboardingTipPositive => 'Mantenha-se positivo';

  @override
  String get onboardingTipUnique => 'O que torna você único?';

  @override
  String get onboardingUploadAtLeastOnePhoto =>
      'Por favor, carregue pelo menos uma foto';

  @override
  String get onboardingUseCurrentLocation => 'Usar Localização Atual';

  @override
  String get onboardingUseYourCamera => 'Usar sua câmera';

  @override
  String get onboardingWhereAreYou => 'Onde você está?';

  @override
  String get onboardingWhereAreYouSubtitle =>
      'Defina seus idiomas e localização preferidos (opcional)';

  @override
  String get onboardingWriteSomethingAboutYourself =>
      'Por favor, escreva algo sobre você';

  @override
  String get onboardingWritingTips => 'Dicas de escrita';

  @override
  String get onboardingYourInterests => 'Seus interesses';

  @override
  String oneTimeDownloadSize(int size) {
    return 'Este é um download único de aproximadamente ${size}MB.';
  }

  @override
  String get optionalConsents => 'Consentimentos Opcionais';

  @override
  String get orContinueWith => 'Ou continue com';

  @override
  String get origin => 'Origem';

  @override
  String packFocusMode(String packName) {
    return 'Pacote: $packName';
  }

  @override
  String get password => 'Senha';

  @override
  String get passwordMustContain => 'A senha deve conter:';

  @override
  String get passwordMustContainLowercase =>
      'A senha deve conter pelo menos uma letra minúscula';

  @override
  String get passwordMustContainNumber =>
      'A senha deve conter pelo menos um número';

  @override
  String get passwordMustContainSpecialChar =>
      'A senha deve conter pelo menos um caractere especial';

  @override
  String get passwordMustContainUppercase =>
      'A senha deve conter pelo menos uma letra maiúscula';

  @override
  String get passwordRequired => 'Senha é obrigatória';

  @override
  String get passwordStrengthFair => 'Razoável';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordStrengthVeryStrong => 'Muito Forte';

  @override
  String get passwordStrengthVeryWeak => 'Muito Fraca';

  @override
  String get passwordStrengthWeak => 'Fraca';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get passwordWeak =>
      'A senha deve conter maiúsculas, minúsculas, números e caracteres especiais';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get pendingVerifications => 'Verificações Pendentes';

  @override
  String get perMonth => '/mês';

  @override
  String get periodAllTime => 'Todos os Tempos';

  @override
  String get periodMonthly => 'Este Mês';

  @override
  String get periodWeekly => 'Esta Semana';

  @override
  String get personalStatistics => 'Estatísticas pessoais';

  @override
  String get personalStatisticsSubtitle =>
      'Gráficos, metas e progresso de idiomas';

  @override
  String get personalStatsActivity => 'Atividade recente';

  @override
  String get personalStatsChatStats => 'Estatísticas do chat';

  @override
  String get personalStatsConversations => 'Conversas';

  @override
  String get personalStatsGoalsAchieved => 'Metas alcançadas';

  @override
  String get personalStatsLevel => 'Nível';

  @override
  String get personalStatsLanguage => 'Idioma';

  @override
  String get personalStatsTotal => 'Total';

  @override
  String get personalStatsNextLevel => 'Próximo nível';

  @override
  String get personalStatsNoActivityYet => 'Nenhuma atividade registrada';

  @override
  String get personalStatsNoWordsYet =>
      'Comece a conversar para descobrir novas palavras';

  @override
  String get personalStatsTotalMessages => 'Mensagens enviadas';

  @override
  String get personalStatsWordsDiscovered => 'Palavras descobertas';

  @override
  String get personalStatsWordsLearned => 'Palavras Aprendidas';

  @override
  String get personalStatsXpOverview => 'Resumo de XP';

  @override
  String get photoAddPhoto => 'Adicionar Foto';

  @override
  String get photoAddPrivateDescription =>
      'Adicione fotos privadas que você pode compartilhar no chat';

  @override
  String get photoAddPublicDescription =>
      'Adicione fotos para completar seu perfil';

  @override
  String get photoAlreadyExistsInAlbum =>
      'A foto já existe no álbum de destino';

  @override
  String photoCountOf6(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get photoDeleteConfirm =>
      'Tem certeza de que deseja excluir esta foto?';

  @override
  String get photoDeleteMainWarning =>
      'Esta é sua foto principal. A próxima foto se tornará sua foto principal (deve mostrar seu rosto). Continuar?';

  @override
  String get photoExplicitContent =>
      'Esta foto pode conter conteúdo inapropriado. Fotos no app não devem mostrar nudez, roupas íntimas ou conteúdo explícito.';

  @override
  String get photoExplicitNudity =>
      'Esta foto parece conter nudez ou conteúdo explícito. Todas as fotos no app devem ser apropriadas e com roupas adequadas.';

  @override
  String photoFailedPickImage(Object error) {
    return 'Falha ao selecionar imagem: $error';
  }

  @override
  String get photoLongPressReorder => 'Pressione e arraste para reordenar';

  @override
  String get photoMainNoFace =>
      'Sua foto principal deve mostrar seu rosto claramente. Nenhum rosto foi detectado nesta foto.';

  @override
  String get photoMainNotForward =>
      'Por favor, use uma foto onde seu rosto esteja claramente visível e voltado para frente.';

  @override
  String get photoManagePhotos => 'Gerenciar Fotos';

  @override
  String get photoMaxPrivate => 'Máximo de 6 fotos privadas permitidas';

  @override
  String get photoMaxPublic => 'Máximo de 6 fotos públicas permitidas';

  @override
  String get photoMustHaveOne =>
      'Você deve ter pelo menos uma foto pública com seu rosto visível.';

  @override
  String get photoNoPhotos => 'Sem fotos ainda';

  @override
  String get photoNoPrivatePhotos => 'Sem fotos privadas ainda';

  @override
  String get photoNotAccepted => 'Foto não aceita';

  @override
  String get photoNotAllowedPublic =>
      'Esta foto não é permitida em nenhum lugar do app.';

  @override
  String get photoPrimary => 'PRINCIPAL';

  @override
  String get photoPrivateShareInfo =>
      'As fotos privadas podem ser compartilhadas no chat';

  @override
  String get photoTooLarge =>
      'A foto é muito grande. O tamanho máximo é 10 MB.';

  @override
  String get photoTooMuchSkin =>
      'Esta foto mostra muita pele exposta. Por favor, use uma foto onde você esteja vestido(a) de forma apropriada.';

  @override
  String get photoUploadedMessage => 'Sua foto foi adicionada ao seu perfil';

  @override
  String get photoUploadedTitle => 'Foto Enviada!';

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
  String get photosUpdatedMessage => 'Sua galeria de fotos foi salva';

  @override
  String get photosUpdatedTitle => 'Fotos Atualizadas!';

  @override
  String phrasesCount(String count) {
    return '$count frases';
  }

  @override
  String get phrasesLabel => 'frases';

  @override
  String get platinum => 'Platina';

  @override
  String get playAgain => 'Jogar Novamente';

  @override
  String playersRange(String min, String max) {
    return '$min-$max jogadores';
  }

  @override
  String get playing => 'Reproduzindo...';

  @override
  String playingCountLabel(String count) {
    return '$count jogando';
  }

  @override
  String get plusTaxes => '+ impostos';

  @override
  String get preferenceAddCountry => 'Adicionar Pais';

  @override
  String get preferenceLanguageFilter => 'Idioma';

  @override
  String get preferenceLanguageFilterDesc =>
      'Mostrar apenas pessoas que falam um idioma específico';

  @override
  String get preferenceAnyLanguage => 'Qualquer idioma';

  @override
  String get preferenceInterestFilter => 'Interesses';

  @override
  String get preferenceInterestFilterDesc =>
      'Mostrar apenas pessoas que compartilham seus interesses';

  @override
  String get preferenceNoInterestFilter =>
      'Sem filtro de interesses — mostrando todos';

  @override
  String get preferenceAddInterest => 'Adicionar interesse';

  @override
  String get preferenceSearchInterest => 'Pesquisar interesses...';

  @override
  String get preferenceNoInterestsFound => 'Nenhum interesse encontrado';

  @override
  String get preferenceAddDealBreaker => 'Adicionar Criterio Eliminatorio';

  @override
  String get preferenceAdvancedFilters => 'Filtros Avancados';

  @override
  String get preferenceAgeRange => 'Faixa Etaria';

  @override
  String get preferenceAllCountries => 'Todos os Paises';

  @override
  String get preferenceAllVerified => 'Todos os perfis devem ser verificados';

  @override
  String get preferenceCountry => 'Pais';

  @override
  String get preferenceCountryDescription =>
      'Mostrar apenas pessoas de paises especificos (deixar vazio para todos)';

  @override
  String get preferenceDealBreakers => 'Criterios Eliminatorios';

  @override
  String get preferenceDealBreakersDesc =>
      'Nunca me mostre perfis com essas caracteristicas';

  @override
  String preferenceDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get preferenceEveryone => 'Todos';

  @override
  String get preferenceMaxDistance => 'Distancia Maxima';

  @override
  String get preferenceMen => 'Homens';

  @override
  String get preferenceMostPopular => 'Mais Popular';

  @override
  String get preferenceNoCountriesFound => 'Nenhum pais encontrado';

  @override
  String get preferenceNoCountryFilter =>
      'Sem filtro de pais - mostrando mundialmente';

  @override
  String get preferenceCountryRequired =>
      'Pelo menos um país deve ser selecionado';

  @override
  String get preferenceByUsers => 'Por usuários';

  @override
  String get preferenceNoDealBreakers =>
      'Nenhum criterio eliminatorio definido';

  @override
  String get preferenceNoDistanceLimit => 'Sem limite de distancia';

  @override
  String get preferenceOnlineNow => 'Online Agora';

  @override
  String get preferenceOnlineNowDesc =>
      'Mostrar apenas perfis atualmente online';

  @override
  String get preferenceOnlyVerified => 'Mostrar apenas perfis verificados';

  @override
  String get preferenceOrientationDescription =>
      'Filtrar por orientacao (deixar tudo desmarcado para mostrar todos)';

  @override
  String get preferenceRecentlyActive => 'Ativos Recentemente';

  @override
  String get preferenceRecentlyActiveDesc =>
      'Mostrar apenas perfis ativos nos ultimos 7 dias';

  @override
  String get preferenceSave => 'Salvar';

  @override
  String get preferenceSelectCountry => 'Selecionar Pais';

  @override
  String get preferenceSexualOrientation => 'Orientacao Sexual';

  @override
  String get preferenceShowMe => 'Mostrar-me';

  @override
  String get preferenceUnlimited => 'Ilimitado';

  @override
  String preferenceUsersCount(int count) {
    return '$count usuarios';
  }

  @override
  String get preferenceWithin => 'Dentro de';

  @override
  String get preferenceWomen => 'Mulheres';

  @override
  String get preferencesSavedMessage =>
      'Suas preferências de descoberta foram atualizadas';

  @override
  String get preferencesSavedTitle => 'Preferências Salvas!';

  @override
  String get premiumTier => 'Premium';

  @override
  String get primaryOrigin => 'Origem Principal';

  @override
  String get priorityConnectNotificationMessage =>
      'Alguém quer se conectar com você!';

  @override
  String get priorityConnectNotificationTitle => 'Conexão Prioritária!';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get privacySettings => 'Configurações de Privacidade';

  @override
  String get privateAlbum => 'Privado';

  @override
  String get privateRoom => 'Sala Privada';

  @override
  String get proLabel => 'PRO';

  @override
  String get profile => 'Perfil';

  @override
  String get profileAboutMe => 'Sobre Mim';

  @override
  String get profileAccountDeletedSuccess => 'Conta excluída com sucesso.';

  @override
  String get profileActivate => 'Ativar';

  @override
  String get profileActivateIncognito => 'Ativar Incógnito?';

  @override
  String get profileActivateTravelerMode => 'Ativar Modo Viajante?';

  @override
  String get profileActivatingBoost => 'Ativando impulso...';

  @override
  String get profileActiveLabel => 'ATIVO';

  @override
  String get profileAdditionalDetails => 'Detalhes Adicionais';

  @override
  String profileAgeCannotChange(int age) {
    return 'Idade $age - Nao pode ser alterada (verificacao)';
  }

  @override
  String profileAlreadyBoosted(Object minutes) {
    return 'Perfil já impulsionado! ${minutes}m restantes';
  }

  @override
  String get profileAuthenticationFailed => 'Autenticação falhou';

  @override
  String profileBioMinLength(int min) {
    return 'A bio deve ter pelo menos $min caracteres';
  }

  @override
  String profileBoostCost(Object cost) {
    return 'Custo: $cost moedas';
  }

  @override
  String get profileBoostDescription =>
      'Seu perfil aparecerá no topo da descoberta por 30 minutos!';

  @override
  String get profileBoostNow => 'Impulsionar Agora';

  @override
  String get profileBoostProfile => 'Impulsionar Perfil';

  @override
  String get profileBoostSubtitle => 'Seja visto primeiro por 30 minutos';

  @override
  String get profileBoosted => 'Perfil Impulsionado!';

  @override
  String profileBoostedForMinutes(Object minutes) {
    return 'Perfil impulsionado por $minutes minutos!';
  }

  @override
  String get profileBuyCoins => 'Comprar Moedas';

  @override
  String get profileCoinShop => 'Loja de Moedas';

  @override
  String get profileCoinShopSubtitle => 'Comprar moedas e assinatura premium';

  @override
  String get profileConfirmYourPassword => 'Confirme Sua Senha';

  @override
  String get profileContinue => 'Continuar';

  @override
  String get profileDataExportSent =>
      'Exportação de dados enviada para seu email';

  @override
  String get profileDateOfBirth => 'Data de Nascimento';

  @override
  String get profileDeleteAccountWarning =>
      'Esta ação é permanente e não pode ser desfeita. Todos os seus dados, compatibilidades e mensagens serão excluídos. Por favor, insira sua senha para confirmar.';

  @override
  String get profileDiscoveryRestarted =>
      'Descoberta reiniciada! Agora você pode ver todos os perfis novamente.';

  @override
  String get profileDisplayName => 'Nome de Exibicao';

  @override
  String get profileDobInfo =>
      'Sua data de nascimento nao pode ser alterada para verificacao de idade. Sua idade exata e visivel para os matches.';

  @override
  String get profileEditBasicInfo => 'Editar Info Basica';

  @override
  String get profileEditLocation => 'Editar Localizacao e Idiomas';

  @override
  String get profileEditNickname => 'Editar Nickname';

  @override
  String get profileEducation => 'Educacao';

  @override
  String get profileEducationHint => 'ex. Bacharelado em Ciencia da Computacao';

  @override
  String get profileEnterNameHint => 'Insira seu nome';

  @override
  String get profileEnterNicknameHint => 'Insira o apelido';

  @override
  String get profileEnterNicknameWith => 'Insira um nickname que comece com @';

  @override
  String get profileExportingData => 'Exportando seus dados...';

  @override
  String profileFailedRestartDiscovery(Object error) {
    return 'Falha ao reiniciar descoberta: $error';
  }

  @override
  String get profileFindUsers => 'Encontrar Usuarios';

  @override
  String get profileGender => 'Genero';

  @override
  String get profileGetCoins => 'Obter Moedas';

  @override
  String get profileGetMembership => 'Obter Assinatura GreenGo';

  @override
  String get profileGettingLocation => 'Obtendo localizacao...';

  @override
  String get profileGreengoMembership => 'Assinatura GreenGo';

  @override
  String get profileHeightCm => 'Altura (cm)';

  @override
  String get profileIncognitoActivated =>
      'Modo incógnito ativado por 24 horas!';

  @override
  String profileIncognitoCost(Object cost) {
    return 'O modo incógnito custa $cost moedas por dia.';
  }

  @override
  String get profileIncognitoDeactivated => 'Modo incógnito desativado.';

  @override
  String profileIncognitoDescription(Object cost) {
    return 'O modo incógnito oculta seu perfil da descoberta por 24 horas.\n\nCusto: $cost';
  }

  @override
  String get profileIncognitoFreePlatinum =>
      'Grátis com Platinum - Oculto da descoberta';

  @override
  String get profileIncognitoMode => 'Modo Incógnito';

  @override
  String get profileInsufficientCoins => 'Moedas Insuficientes';

  @override
  String profileInterestsCount(Object count) {
    return '$count interesses';
  }

  @override
  String get profileInterestsHobbiesHint =>
      'Conte sobre seus interesses, hobbies, o que você procura...';

  @override
  String get profileLanguagesSectionTitle => 'Idiomas';

  @override
  String profileLanguagesSelectedCount(int count) {
    return '$count/3 idiomas selecionados';
  }

  @override
  String profileLinkedCount(Object count) {
    return '$count perfil(s) vinculado(s)';
  }

  @override
  String profileLocationFailed(String error) {
    return 'Nao foi possivel obter a localizacao: $error';
  }

  @override
  String get profileLocationSectionTitle => 'Localizacao';

  @override
  String get profileLookingFor => 'Procurando';

  @override
  String get profileLookingForHint => 'ex. Relacionamento serio';

  @override
  String get profileMaxLanguagesAllowed => 'Maximo 3 idiomas permitidos';

  @override
  String get profileMembershipActive => 'Ativo';

  @override
  String get profileMembershipExpired => 'Expirado';

  @override
  String profileMembershipValidTill(Object date) {
    return 'Válido até $date';
  }

  @override
  String get profileMyUsage => 'Meu Uso';

  @override
  String get profileMyUsageSubtitle => 'Ver seu uso diário e limites de nível';

  @override
  String get profileNicknameAlreadyTaken => 'Esse nickname ja esta em uso';

  @override
  String get profileNicknameCharRules =>
      '3-20 caracteres. Apenas letras, numeros e underscores.';

  @override
  String get profileNicknameCheckError => 'Erro ao verificar disponibilidade';

  @override
  String profileNicknameInfoWithNickname(String nickname) {
    return 'Seu nickname e unico e pode ser usado para te encontrar. Outros podem te procurar com @$nickname';
  }

  @override
  String get profileNicknameInfoWithout =>
      'Seu nickname e unico e pode ser usado para te encontrar. Defina um para que outros possam te descobrir.';

  @override
  String get profileNicknameLabel => 'Apelido';

  @override
  String get profileNicknameRefresh => 'Atualizar';

  @override
  String get profileNicknameRule1 => 'Deve ter 3-20 caracteres';

  @override
  String get profileNicknameRule2 => 'Comecar com uma letra';

  @override
  String get profileNicknameRule3 => 'Apenas letras, numeros e underscores';

  @override
  String get profileNicknameRule4 => 'Sem underscores consecutivos';

  @override
  String get profileNicknameRule5 => 'Nao pode conter palavras reservadas';

  @override
  String get profileNicknameRules => 'Regras do Nickname';

  @override
  String get profileNicknameSuggestions => 'Sugestoes';

  @override
  String profileNoUsersFound(String query) {
    return 'Nenhum usuario encontrado para \"@$query\"';
  }

  @override
  String profileNotEnoughCoins(Object available, Object required) {
    return 'Moedas insuficientes! Precisa de $required, tem $available';
  }

  @override
  String get profileOccupation => 'Profissao';

  @override
  String get profileOccupationHint => 'ex. Engenheiro de Software';

  @override
  String get profileOptionalDetails => 'Opcional - ajuda outros a te conhecer';

  @override
  String get profileOrientationPrivate =>
      'Isso e privado e nao e mostrado no seu perfil';

  @override
  String profilePhotosCount(Object count) {
    return '$count/6 fotos';
  }

  @override
  String get profilePremiumFeatures => 'Funcionalidades Premium';

  @override
  String get profileProgressGrowth => 'Progresso e crescimento';

  @override
  String get profileRestart => 'Reiniciar';

  @override
  String get profileRestartDiscovery => 'Reiniciar Descoberta';

  @override
  String get profileRestartDiscoveryDialogContent =>
      'Isto irá apagar todos os seus swipes (conexões, rejeições, conexões prioritárias) para que você possa redescobrir todos do início.';

  @override
  String get profileRestartDiscoveryDialogTitle => 'Reiniciar Descoberta';

  @override
  String get profileRestartDiscoverySubtitle =>
      'Redefinir todos os swipes e começar de novo';

  @override
  String get profileSearchByNickname => 'Pesquisar por @nickname';

  @override
  String get profileSearchByNicknameHint => 'Pesquisar por @apelido';

  @override
  String get profileSearchCityHint => 'Pesquisar cidade, endereço ou local...';

  @override
  String get profileSearchForUsers => 'Pesquisar usuarios por nickname';

  @override
  String get profileSearchLanguagesHint => 'Pesquisar idiomas...';

  @override
  String get profileSetLocationAndLanguage =>
      'Defina a localizacao e selecione pelo menos um idioma';

  @override
  String get profileSexualOrientation => 'Orientacao Sexual';

  @override
  String get profileStop => 'Parar';

  @override
  String get profileTellAboutYourselfHint => 'Conte sobre você...';

  @override
  String get profileTipAuthentic => 'Seja autentico e genuino';

  @override
  String get profileTipHobbies => 'Mencione seus hobbies e paixoes';

  @override
  String get profileTipHumor => 'Adicione um toque de humor';

  @override
  String get profileTipPositive => 'Mantenha-se positivo';

  @override
  String get profileTipsForGreatBio => 'Dicas para uma otima bio';

  @override
  String profileTravelerActivated(Object city) {
    return 'Modo viajante ativado! Aparecendo em $city por 24 horas.';
  }

  @override
  String profileTravelerCost(Object cost) {
    return 'O modo viajante custa $cost moedas por dia.';
  }

  @override
  String get profileTravelerDeactivated =>
      'Modo viajante desativado. De volta à sua localização real.';

  @override
  String profileTravelerDescription(Object cost) {
    return 'O modo viajante permite que você apareça no feed de descoberta de outra cidade por 24 horas.\n\nCusto: $cost';
  }

  @override
  String get profileTravelerMode => 'Modo Viajante';

  @override
  String get profileTryDifferentNickname => 'Tente um nickname diferente';

  @override
  String get profileUnableToVerifyAccount =>
      'Não foi possível verificar a conta';

  @override
  String get profileUpdateCurrentLocation => 'Atualizar Localizacao Atual';

  @override
  String get profileUpdatedMessage => 'Suas alterações foram salvas';

  @override
  String get profileUpdatedSuccess => 'Perfil atualizado com sucesso';

  @override
  String get profileUpdatedTitle => 'Perfil Atualizado!';

  @override
  String get profileWeightKg => 'Peso (kg)';

  @override
  String profilesLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
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
      'Permitir a análise das suas preferências para fornecer melhores sugestões de correspondência';

  @override
  String get progress => 'Progresso';

  @override
  String get progressAchievements => 'Emblemas';

  @override
  String get progressBadges => 'Emblemas';

  @override
  String get progressChallenges => 'Desafios';

  @override
  String get progressComparison => 'Comparacao de Progresso';

  @override
  String get progressCompleted => 'Concluídos';

  @override
  String get progressJourneyDescription =>
      'Veja sua jornada completa de encontros e conquistas';

  @override
  String get progressLabel => 'Progresso';

  @override
  String get progressLeaderboard => 'Ranking';

  @override
  String progressLevel(int level) {
    return 'Nível $level';
  }

  @override
  String progressNofM(String n, String m) {
    return '$n/$m';
  }

  @override
  String get progressOverview => 'Visão Geral';

  @override
  String get progressRecentAchievements => 'Conquistas Recentes';

  @override
  String get progressSeeAll => 'Ver Tudo';

  @override
  String get progressTitle => 'Progresso';

  @override
  String get progressTodaysChallenges => 'Desafios de Hoje';

  @override
  String get progressTotalXP => 'XP Total';

  @override
  String get progressViewJourney => 'Ver Sua Jornada';

  @override
  String get publicAlbum => 'Público';

  @override
  String get purchaseSuccessfulTitle => 'Compra Realizada!';

  @override
  String get purchasedLabel => 'Comprado';

  @override
  String get quickPlay => 'Jogo Rápido';

  @override
  String get quizCheckpointLabel => 'Quiz';

  @override
  String rankLabel(String rank) {
    return '#$rank';
  }

  @override
  String get readPrivacyPolicy => 'Ler Política de Privacidade';

  @override
  String get readTermsAndConditions => 'Ler Termos e Condições';

  @override
  String get readyButton => 'Pronto';

  @override
  String get recipientNickname => 'Apelido do destinatário';

  @override
  String get recordVoice => 'Gravar Voz';

  @override
  String get refresh => 'Atualizar';

  @override
  String get register => 'Cadastrar';

  @override
  String get rejectVerification => 'Rejeitar';

  @override
  String rejectionReason(String reason) {
    return 'Razão: $reason';
  }

  @override
  String get rejectionReasonRequired =>
      'Por favor introduza um motivo para a rejeição';

  @override
  String remainingToday(int remaining, String type, Object limitType) {
    return '$remaining $type restantes hoje';
  }

  @override
  String get reportSubmittedMessage =>
      'Obrigado por ajudar a manter nossa comunidade segura';

  @override
  String get reportSubmittedTitle => 'Denúncia Enviada!';

  @override
  String get reportWord => 'Reportar Palavra';

  @override
  String get reportsPanel => 'Painel de Denúncias';

  @override
  String get requestBetterPhoto => 'Solicitar Foto Melhor';

  @override
  String requiresTier(String tier) {
    return 'Requer $tier';
  }

  @override
  String get resetPassword => 'Redefinir Senha';

  @override
  String get resetToDefault => 'Restaurar Padrão';

  @override
  String get restartAppWizard => 'Reiniciar Assistente do App';

  @override
  String get restartWizard => 'Reiniciar Assistente';

  @override
  String get restartWizardDialogContent =>
      'Isto irá reiniciar o assistente de configuração. Você poderá atualizar as informações do seu perfil passo a passo. Seus dados atuais serão preservados.';

  @override
  String get retakePhoto => 'Tirar Novamente';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get reuploadVerification => 'Reenviar foto de verificação';

  @override
  String get reverificationCameraError => 'Não foi possível abrir a câmera';

  @override
  String get reverificationDescription =>
      'Tire uma selfie clara para verificarmos sua identidade. Certifique-se de ter boa iluminação e que seu rosto esteja bem visível.';

  @override
  String get reverificationHeading => 'Precisamos verificar sua identidade';

  @override
  String get reverificationInfoText =>
      'Após o envio, seu perfil ficará em revisão. Você terá acesso após a aprovação.';

  @override
  String get reverificationPhotoTips => 'Dicas para a foto';

  @override
  String get reverificationReasonLabel => 'Motivo da solicitação:';

  @override
  String get reverificationRetakePhoto => 'Tirar novamente';

  @override
  String get reverificationSubmit => 'Enviar para revisão';

  @override
  String get reverificationTapToSelfie => 'Toque para tirar uma selfie';

  @override
  String get reverificationTipCamera => 'Olhe diretamente para a câmera';

  @override
  String get reverificationTipFullFace =>
      'Certifique-se de que seu rosto esteja totalmente visível';

  @override
  String get reverificationTipLighting =>
      'Boa iluminação — fique de frente para a fonte de luz';

  @override
  String get reverificationTipNoAccessories =>
      'Sem óculos de sol, chapéus ou máscaras';

  @override
  String get reverificationTitle => 'Verificação de identidade';

  @override
  String get reverificationUploadFailed => 'Falha no envio. Tente novamente.';

  @override
  String get reviewReportedMessages =>
      'Revisar mensagens denunciadas e gerenciar contas';

  @override
  String get reviewUserVerifications => 'Revisar verificações de usuários';

  @override
  String reviewedBy(String admin) {
    return 'Revisto por $admin';
  }

  @override
  String get revokeAccess => 'Revogar acesso ao álbum';

  @override
  String get rewardsAndProgress => 'Recompensas e Progresso';

  @override
  String get romanticCategory => 'Romântico';

  @override
  String get roundTimer => 'Cronômetro da Rodada';

  @override
  String roundXofY(String current, String total) {
    return 'Rodada $current/$total';
  }

  @override
  String get rounds => 'Rodadas';

  @override
  String get safetyAdd => 'Adicionar';

  @override
  String get safetyAddAtLeastOneContact =>
      'Por favor, adicione pelo menos um contato de emergência';

  @override
  String get safetyAddEmergencyContact => 'Adicionar Contato de Emergência';

  @override
  String get safetyAddEmergencyContacts => 'Adicionar contatos de emergência';

  @override
  String get safetyAdditionalDetailsHint => 'Algum detalhe adicional...';

  @override
  String get safetyCheckInDescription =>
      'Configure um check-in para seu encontro. Vamos lembrá-lo de fazer check-in e alertar seus contatos se não responder.';

  @override
  String get safetyCheckInEvery => 'Check-in a cada';

  @override
  String get safetyCheckInScheduled => 'Check-in de encontro agendado!';

  @override
  String get safetyDateCheckIn => 'Check-In de Encontro';

  @override
  String get safetyDateTime => 'Data e Hora';

  @override
  String get safetyEmergencyContacts => 'Contatos de Emergência';

  @override
  String get safetyEmergencyContactsHelp =>
      'Serão notificados se você precisar de ajuda';

  @override
  String get safetyEmergencyContactsLocation =>
      'Os contatos de emergência podem ver sua localização';

  @override
  String get safetyInterval15Min => '15 min';

  @override
  String get safetyInterval1Hour => '1 hora';

  @override
  String get safetyInterval2Hours => '2 horas';

  @override
  String get safetyInterval30Min => '30 min';

  @override
  String get safetyLocation => 'Localização';

  @override
  String get safetyMeetingLocationHint => 'Onde vocês vão se encontrar?';

  @override
  String get safetyMeetingWith => 'Encontro com';

  @override
  String get safetyNameLabel => 'Nome';

  @override
  String get safetyNotesOptional => 'Notas (Opcional)';

  @override
  String get safetyPhoneLabel => 'Número de Telefone';

  @override
  String get safetyPleaseEnterLocation => 'Por favor, insira uma localização';

  @override
  String get safetyRelationshipFamily => 'Família';

  @override
  String get safetyRelationshipFriend => 'Amigo';

  @override
  String get safetyRelationshipLabel => 'Relacionamento';

  @override
  String get safetyRelationshipOther => 'Outro';

  @override
  String get safetyRelationshipPartner => 'Parceiro';

  @override
  String get safetyRelationshipRoommate => 'Colega de Quarto';

  @override
  String get safetyScheduleCheckIn => 'Agendar Check-In';

  @override
  String get safetyShareLiveLocation =>
      'Compartilhar localização em tempo real';

  @override
  String get safetyStaySafe => 'Mantenha-se Seguro';

  @override
  String get save => 'Salvar';

  @override
  String get searchByNameOrNickname => 'Pesquisar por nome ou @apelido';

  @override
  String get searchByNickname => 'Buscar por Apelido';

  @override
  String get searchByNicknameTooltip => 'Pesquisar por apelido';

  @override
  String get searchCityPlaceholder => 'Pesquisar cidade, endereço ou local...';

  @override
  String get searchCountries => 'Pesquisar países...';

  @override
  String get searchCountryHint => 'Pesquisar país...';

  @override
  String get searchForCity => 'Pesquise uma cidade ou use o GPS';

  @override
  String get searchMessagesHint => 'Pesquisar mensagens...';

  @override
  String get secondChanceDescription =>
      'Veja perfis que você passou e que realmente gostaram de você!';

  @override
  String secondChanceDistanceAway(Object distance) {
    return '$distance km de distância';
  }

  @override
  String get secondChanceEmpty => 'Sem segundas oportunidades disponíveis';

  @override
  String get secondChanceEmptySubtitle =>
      'Volte mais tarde para mais oportunidades!';

  @override
  String get secondChanceFindButton => 'Encontrar Segundas Oportunidades';

  @override
  String secondChanceFreeRemaining(Object max, Object remaining) {
    return '$remaining/$max grátis';
  }

  @override
  String secondChanceGetUnlimited(Object cost) {
    return 'Obter Ilimitado ($cost)';
  }

  @override
  String get secondChanceLike => 'Curtir';

  @override
  String secondChanceLikedYouAgo(Object ago) {
    return 'Gostaram de você $ago';
  }

  @override
  String get secondChanceMatchBody =>
      'Vocês gostam um do outro! Inicie uma conversa.';

  @override
  String get secondChanceMatchTitle => 'Comece a conectar!';

  @override
  String get secondChanceOutOf => 'Sem Segundas Oportunidades';

  @override
  String get secondChancePass => 'Passar';

  @override
  String secondChancePurchaseBody(Object cost, Object freePerDay) {
    return 'Você usou todas as $freePerDay segundas oportunidades grátis de hoje.\n\nTenha ilimitado por $cost moedas!';
  }

  @override
  String get secondChanceRefresh => 'Atualizar';

  @override
  String get secondChanceStartChat => 'Iniciar Conversa';

  @override
  String get secondChanceTitle => 'Segunda Oportunidade';

  @override
  String get secondChanceUnlimited => 'Ilimitado';

  @override
  String get secondChanceUnlimitedUnlocked =>
      'Segundas oportunidades ilimitadas desbloqueadas!';

  @override
  String get secondaryOrigin => 'Origem Secundária (opcional)';

  @override
  String get seconds => 'Segundos';

  @override
  String get secretAchievement => 'Conquista Secreta';

  @override
  String get seeAll => 'Ver Todos';

  @override
  String get seeHowOthersViewProfile => 'Veja como outros veem seu perfil';

  @override
  String seeMoreProfiles(int count) {
    return 'Ver mais $count';
  }

  @override
  String get seeMoreProfilesTitle => 'Ver Mais Perfis';

  @override
  String get seeProfile => 'Ver Perfil';

  @override
  String selectAtLeastInterests(int count) {
    return 'Selecione pelo menos $count interesses';
  }

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get selectTravelLocation => 'Selecionar local de viagem';

  @override
  String get sendCoins => 'Enviar moedas';

  @override
  String sendCoinsConfirm(String amount, String nickname) {
    return 'Enviar $amount moedas para @$nickname?';
  }

  @override
  String get sendMedia => 'Enviar Mídia';

  @override
  String get sendMessage => 'Enviar Mensagem';

  @override
  String get serverUnavailableMessage =>
      'Nossos servidores estão temporariamente indisponíveis. Tente novamente em alguns instantes.';

  @override
  String get serverUnavailableTitle => 'Servidor Indisponível';

  @override
  String get setYourUniqueNickname => 'Defina seu apelido único';

  @override
  String get settings => 'Configurações';

  @override
  String get shareAlbum => 'Compartilhar álbum';

  @override
  String get shop => 'Loja';

  @override
  String get shopActive => 'ATIVA';

  @override
  String get shopAdvancedFilters => 'Filtros Avançados';

  @override
  String shopAmountCoins(Object amount) {
    return '$amount moedas';
  }

  @override
  String get shopBadge => 'Distintivo';

  @override
  String get shopBaseMembership => 'Assinatura Base GreenGo';

  @override
  String get shopBaseMembershipDescription =>
      'Necessária para deslizar, curtir, conversar e interagir com outros usuários.';

  @override
  String shopBonusCoins(Object bonus) {
    return '+$bonus moedas bônus';
  }

  @override
  String get shopBoosts => 'Impulsos';

  @override
  String shopBuyTier(String tier, String duration) {
    return 'Comprar $tier ($duration)';
  }

  @override
  String get shopCannotSendToSelf =>
      'Você não pode enviar moedas para si mesmo';

  @override
  String get shopCheckInternet =>
      'Verifique sua conexão com a internet\ne tente novamente.';

  @override
  String get shopCoins => 'Moedas';

  @override
  String shopCoinsPerDollar(Object amount) {
    return '$amount moedas/\$';
  }

  @override
  String shopCoinsSentTo(String amount, String nickname) {
    return '$amount moedas enviadas para @$nickname';
  }

  @override
  String get shopComingSoon => 'Em breve';

  @override
  String get shopConfirmSend => 'Confirmar envio';

  @override
  String get shopCurrent => 'ATUAL';

  @override
  String shopCurrentExpires(Object date) {
    return 'ATUAL - Expira $date';
  }

  @override
  String shopCurrentPlan(String tier) {
    return 'Plano atual: $tier';
  }

  @override
  String get shopDailyLikes => 'Conexões Diárias';

  @override
  String shopDaysLeft(Object days) {
    return '${days}d restantes';
  }

  @override
  String get shopEnterAmount => 'Digite o valor';

  @override
  String get shopEnterBothFields => 'Digite o nickname e o valor';

  @override
  String get shopEnterValidAmount => 'Digite um valor válido';

  @override
  String shopExpired(String date) {
    return 'Expirado: $date';
  }

  @override
  String shopExpires(String date, String days) {
    return 'Expira: $date ($days dias restantes)';
  }

  @override
  String get shopFailedToInitiate => 'Não foi possível iniciar a compra';

  @override
  String get shopFailedToSendCoins => 'Falha ao enviar moedas';

  @override
  String get shopGetNotified => 'Receber notificação';

  @override
  String get shopGreenGoCoins => 'GreenGoCoins';

  @override
  String get shopIncognitoMode => 'Modo Incógnito';

  @override
  String get shopInsufficientCoins => 'Moedas insuficientes';

  @override
  String shopMembershipActivated(String date) {
    return 'Assinatura GreenGo ativada! +500 moedas bônus. Válida até $date.';
  }

  @override
  String get shopMonthly => 'Mensal';

  @override
  String get shopNotifyMessage =>
      'Avisaremos quando os Video-Coins estiverem disponíveis';

  @override
  String get shopOneMonth => '1 Mês';

  @override
  String get shopOneYear => '1 Ano';

  @override
  String get shopPerMonth => '/mês';

  @override
  String get shopPerYear => '/ano';

  @override
  String get shopPopular => 'POPULAR';

  @override
  String get shopPreviousPurchaseFound =>
      'Compra anterior encontrada. Tente novamente.';

  @override
  String get shopPriorityMatching => 'Matching prioritário';

  @override
  String shopPurchaseCoinsFor(String coins, String price) {
    return 'Comprar $coins moedas por $price';
  }

  @override
  String shopPurchaseError(Object error) {
    return 'Erro de compra: $error';
  }

  @override
  String get shopReadReceipts => 'Confirmação de Leitura';

  @override
  String get shopRecipientNickname => 'Nickname do destinatário';

  @override
  String get shopRetry => 'Tentar novamente';

  @override
  String shopSavePercent(String percent) {
    return 'ECONOMIZE $percent%';
  }

  @override
  String get shopSeeWhoLikesYou => 'Ver quem conecta';

  @override
  String get shopSend => 'Enviar';

  @override
  String get shopSendCoins => 'Enviar moedas';

  @override
  String get shopStoreNotAvailable =>
      'Loja indisponível. Verifique as configurações do dispositivo.';

  @override
  String get shopSuperLikes => 'Conexões Prioritárias';

  @override
  String get shopTabCoins => 'Moedas';

  @override
  String shopTabError(Object tabName) {
    return 'Erro na aba $tabName';
  }

  @override
  String get shopTabMembership => 'Assinatura';

  @override
  String get shopTabVideo => 'Vídeo';

  @override
  String get shopTitle => 'Loja';

  @override
  String get shopTravelling => 'Viajando';

  @override
  String get shopUnableToLoadPackages => 'Não foi possível carregar os pacotes';

  @override
  String get shopUnlimited => 'Ilimitado';

  @override
  String get shopUnlockPremium =>
      'Desbloqueie recursos premium e melhore sua experiência de encontros';

  @override
  String get shopUpgradeAndSave =>
      'Melhore e economize! Desconto nos níveis superiores';

  @override
  String get shopUpgradeExperience => 'Melhore sua experiência';

  @override
  String shopUpgradeTo(String tier, String duration) {
    return 'Melhorar para $tier ($duration)';
  }

  @override
  String get shopUserNotFound => 'Usuário não encontrado';

  @override
  String shopValidUntil(String date) {
    return 'Válida até $date';
  }

  @override
  String get shopVideoCoinsDescription =>
      'Assista vídeos curtos para ganhar moedas grátis!\nFique ligado nessa funcionalidade empolgante.';

  @override
  String get shopVipBadge => 'Selo VIP';

  @override
  String get shopYearly => 'Anual';

  @override
  String get shopYearlyPlan => 'Assinatura anual';

  @override
  String get shopYouHave => 'Você tem';

  @override
  String shopYouSave(String amount, String tier) {
    return 'Você economiza $amount/mês ao melhorar de $tier';
  }

  @override
  String get shortTermRelationship => 'Relacionamento casual';

  @override
  String showingProfiles(int count) {
    return '$count perfis';
  }

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signUp => 'Cadastre-se';

  @override
  String get silver => 'Prata';

  @override
  String get skip => 'Pular';

  @override
  String get skipForNow => 'Saltar por Agora';

  @override
  String get slangCategory => 'Gíria';

  @override
  String get socialConnectAccounts => 'Conectar suas contas sociais';

  @override
  String get socialHintUsername => 'Nome de usuário (sem @)';

  @override
  String get socialHintUsernameOrUrl => 'Nome de usuário ou URL do perfil';

  @override
  String get socialLinksUpdatedMessage => 'Seus perfis sociais foram salvos';

  @override
  String get socialLinksUpdatedTitle => 'Redes Sociais Atualizadas!';

  @override
  String get socialNotConnected => 'Não conectado';

  @override
  String get socialProfiles => 'Perfis Sociais';

  @override
  String get socialProfilesTip =>
      'Seus perfis sociais serão visíveis no seu perfil de encontros e ajudarão outros a verificar sua identidade.';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get spotsAbout => 'Sobre';

  @override
  String get spotsAddNewSpot => 'Adicionar um Novo Local';

  @override
  String get spotsAddSpot => 'Adicionar um Local';

  @override
  String spotsAddedBy(Object name) {
    return 'Adicionado por $name';
  }

  @override
  String get spotsAll => 'Todos';

  @override
  String get spotsCategory => 'Categoria';

  @override
  String get spotsCouldNotLoad => 'Não foi possível carregar locais';

  @override
  String get spotsCouldNotLoadSpot => 'Não foi possível carregar local';

  @override
  String get spotsCreateSpot => 'Criar Local';

  @override
  String get spotsCulturalSpots => 'Locais Culturais';

  @override
  String spotsDateDaysAgo(Object count) {
    return 'Há $count dias';
  }

  @override
  String spotsDateMonthsAgo(Object count) {
    return 'Há $count meses';
  }

  @override
  String get spotsDateToday => 'Hoje';

  @override
  String spotsDateWeeksAgo(Object count) {
    return 'Há $count semanas';
  }

  @override
  String spotsDateYearsAgo(Object count) {
    return 'Há $count anos';
  }

  @override
  String get spotsDateYesterday => 'Ontem';

  @override
  String get spotsDescriptionLabel => 'Descrição';

  @override
  String get spotsNameLabel => 'Nome do Local';

  @override
  String get spotsNoReviews =>
      'Sem avaliações ainda. Seja o primeiro a escrever uma!';

  @override
  String get spotsNoSpotsFound => 'Nenhum local encontrado';

  @override
  String get spotsReviewAdded => 'Avaliação adicionada!';

  @override
  String spotsReviewsCount(Object count) {
    return 'Avaliações ($count)';
  }

  @override
  String get spotsShareExperienceHint => 'Compartilhe sua experiência...';

  @override
  String get spotsSubmitReview => 'Enviar Avaliação';

  @override
  String get spotsWriteReview => 'Escrever uma Avaliação';

  @override
  String get spotsYourRating => 'Sua Classificação';

  @override
  String get standardTier => 'Padrão';

  @override
  String get startChat => 'Iniciar Chat';

  @override
  String get startConversation => 'Iniciar uma conversa';

  @override
  String get startGame => 'Iniciar Jogo';

  @override
  String get startLearning => 'Começar a Aprender';

  @override
  String get startLessonBtn => 'Iniciar Lição';

  @override
  String get startSwipingToFindMatches =>
      'Comece a deslizar para encontrar suas combinações!';

  @override
  String get step => 'Passo';

  @override
  String get stepOf => 'de';

  @override
  String get storiesAddCaptionHint => 'Adicionar uma legenda...';

  @override
  String get storiesCreateStory => 'Criar História';

  @override
  String storiesDaysAgo(Object count) {
    return 'Há ${count}d';
  }

  @override
  String get storiesDisappearAfter24h =>
      'Sua história desaparecerá após 24 horas';

  @override
  String get storiesGallery => 'Galeria';

  @override
  String storiesHoursAgo(Object count) {
    return 'Há ${count}h';
  }

  @override
  String storiesMinutesAgo(Object count) {
    return 'Há ${count}m';
  }

  @override
  String get storiesNoActive => 'Sem histórias ativas';

  @override
  String get storiesNoStories => 'Sem histórias disponíveis';

  @override
  String get storiesPhoto => 'Foto';

  @override
  String get storiesPost => 'Publicar';

  @override
  String get storiesSendMessageHint => 'Enviar uma mensagem...';

  @override
  String get storiesShareMoment => 'Compartilhar um momento';

  @override
  String get storiesVideo => 'Vídeo';

  @override
  String get storiesYourStory => 'Sua História';

  @override
  String get streakActiveToday => 'Ativo hoje';

  @override
  String get streakBonusHeader => 'Bônus de Sequência!';

  @override
  String get streakInactive => 'Comece sua sequência!';

  @override
  String get streakMessageIncredible => 'Dedicação incrível!';

  @override
  String get streakMessageKeepItUp => 'Continue assim!';

  @override
  String get streakMessageMomentum => 'Ganhando ritmo!';

  @override
  String get streakMessageOneWeek => 'Uma semana de marco!';

  @override
  String get streakMessageTwoWeeks => 'Duas semanas firme!';

  @override
  String get submitAnswer => 'Enviar Resposta';

  @override
  String get submitVerification => 'Enviar para Verificação';

  @override
  String submittedOn(String date) {
    return 'Enviado em $date';
  }

  @override
  String get subscribe => 'Assinar';

  @override
  String get subscribeNow => 'Assinar agora';

  @override
  String get subscriptionExpired => 'Assinatura Expirada';

  @override
  String subscriptionExpiredBody(Object tierName) {
    return 'Sua assinatura $tierName expirou. Você foi movido para o nível Grátis.';
  }

  @override
  String get suggestions => 'Sugestões';

  @override
  String get superLike => 'Conexão Prioritária';

  @override
  String superLikedYou(String name) {
    return '$name conectou-se prioritariamente com você!';
  }

  @override
  String get superLikes => 'Conexões Prioritárias';

  @override
  String get supportCenter => 'Central de Suporte';

  @override
  String get supportCenterSubtitle =>
      'Obter ajuda, reportar problemas, entre em contato';

  @override
  String get swipeIndicatorLike => 'CONECTAR';

  @override
  String get swipeIndicatorNope => 'PASSAR';

  @override
  String get swipeIndicatorSkip => 'EXPLORAR';

  @override
  String get swipeIndicatorSuperLike => 'PRIORITARIO';

  @override
  String get takePhoto => 'Tirar Foto';

  @override
  String get takeVerificationPhoto => 'Tirar Foto de Verificação';

  @override
  String get tapToContinue => 'Toque para continuar';

  @override
  String get targetLanguage => 'Idioma Alvo';

  @override
  String get termsAndConditions => 'Termos e Condições';

  @override
  String get thatsYourOwnProfile => 'Esse é o seu próprio perfil!';

  @override
  String get thirdPartyDataDescription =>
      'Permitir o compartilhamento de dados anonimizados com parceiros para melhoria do serviço';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get tierFree => 'Grátis';

  @override
  String get timeRemaining => 'Tempo restante';

  @override
  String get timeoutError => 'Tempo esgotado';

  @override
  String toNextLevel(int percent, int level) {
    return '$percent% para Nível $level';
  }

  @override
  String get today => 'hoje';

  @override
  String get totalXpLabel => 'XP Total';

  @override
  String get tourDiscoveryDescription =>
      'Deslize pelos perfis para encontrar seu match perfeito. Deslize para a direita se interessado, para a esquerda para passar.';

  @override
  String get tourDiscoveryTitle => 'Descubra Matches';

  @override
  String get tourDone => 'Concluído';

  @override
  String get tourLearnDescription =>
      'Estude vocabulário, gramática e habilidades de conversação';

  @override
  String get tourLearnTitle => 'Aprenda Idiomas';

  @override
  String get tourMatchesDescription =>
      'Veja todos que também curtiram você! Comece conversas com seus matches mútuos.';

  @override
  String get tourMatchesTitle => 'Seus Matches';

  @override
  String get tourMessagesDescription =>
      'Converse com seus matches aqui. Envie mensagens, fotos e áudios para se conectar.';

  @override
  String get tourMessagesTitle => 'Mensagens';

  @override
  String get tourNext => 'Próximo';

  @override
  String get tourPlayDescription =>
      'Desafie outros em jogos de idiomas divertidos';

  @override
  String get tourPlayTitle => 'Jogue';

  @override
  String get tourProfileDescription =>
      'Personalize seu perfil, gerencie configurações e controle sua privacidade.';

  @override
  String get tourProfileTitle => 'Seu Perfil';

  @override
  String get tourProgressDescription =>
      'Ganhe emblemas, complete desafios e suba no ranking!';

  @override
  String get tourProgressTitle => 'Acompanhe o Progresso';

  @override
  String get tourShopDescription =>
      'Obtenha moedas e recursos premium para melhorar sua experiência.';

  @override
  String get tourShopTitle => 'Loja e Moedas';

  @override
  String get tourSkip => 'Pular';

  @override
  String get trialWelcomeTitle => 'Bem-vindo ao GreenGo!';

  @override
  String trialWelcomeMessage(String expirationDate) {
    return 'Você está usando a versão de teste. Sua assinatura base gratuita está ativa até $expirationDate. Aproveite para explorar o GreenGo!';
  }

  @override
  String get trialWelcomeButton => 'Começar';

  @override
  String get translateWord => 'Traduza esta palavra';

  @override
  String get translationDownloadExplanation =>
      'Para ativar a tradução automática de mensagens, precisamos baixar dados de idioma para uso offline.';

  @override
  String get travelCategory => 'Viagem';

  @override
  String get travelLabel => 'Viagem';

  @override
  String get travelerAppearFor24Hours =>
      'Você aparecerá nos resultados de descoberta para esta localização por 24 horas.';

  @override
  String get travelerBadge => 'Viajante';

  @override
  String get travelerChangeLocation => 'Alterar localização';

  @override
  String get travelerConfirmLocation => 'Confirmar Localização';

  @override
  String travelerFailedGetLocation(Object error) {
    return 'Falha ao obter localização: $error';
  }

  @override
  String get travelerGettingLocation => 'Obtendo localização...';

  @override
  String travelerInCity(String city) {
    return 'Em $city';
  }

  @override
  String get travelerLoadingAddress => 'Carregando endereço...';

  @override
  String get travelerLocationInfo =>
      'Você aparecerá nos resultados de descoberta para esta localização por 24 horas.';

  @override
  String get travelerLocationPermissionsDenied =>
      'Permissões de localização negadas';

  @override
  String get travelerLocationPermissionsPermanentlyDenied =>
      'Permissões de localização permanentemente negadas';

  @override
  String get travelerLocationServicesDisabled =>
      'Os serviços de localização estão desativados';

  @override
  String travelerModeActivated(String city) {
    return 'Modo viajante ativado! Aparecendo em $city por 24 horas.';
  }

  @override
  String get travelerModeActive => 'Modo viajante ativo';

  @override
  String get travelerModeDeactivated =>
      'Modo viajante desativado. De volta à sua localização real.';

  @override
  String get travelerModeDescription =>
      'Apareça no feed de descoberta de outra cidade por 24 horas';

  @override
  String get travelerModeTitle => 'Modo Viajante';

  @override
  String travelerNoResultsFor(Object query) {
    return 'Nenhum resultado encontrado para \"$query\"';
  }

  @override
  String get travelerPickOnMap => 'Escolher no Mapa';

  @override
  String get travelerProfileAppearDescription =>
      'Seu perfil aparecerá no feed de descoberta dessa localização por 24 horas com um distintivo de Viajante.';

  @override
  String get travelerSearchHint =>
      'Seu perfil aparecerá no feed de descoberta dessa localização por 24 horas com um selo de Viajante.';

  @override
  String get travelerSearchOrGps => 'Pesquisar uma cidade ou usar GPS';

  @override
  String get travelerSelectOnMap => 'Selecionar no Mapa';

  @override
  String get travelerSelectThisLocation => 'Selecionar Esta Localização';

  @override
  String get travelerSelectTravelLocation => 'Selecionar Localização de Viagem';

  @override
  String get travelerTapOnMap =>
      'Toque no mapa para selecionar uma localização';

  @override
  String get travelerUseGps => 'Usar GPS';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get tryDifferentSearchOrFilter =>
      'Tente uma busca ou filtro diferente';

  @override
  String get twoFaDisabled => 'Autenticação 2FA desativada';

  @override
  String get twoFaEnabled => 'Autenticação 2FA ativada';

  @override
  String get twoFaToggleSubtitle =>
      'Exigir verificação por código de e-mail em cada login';

  @override
  String get twoFaToggleTitle => 'Ativar Autenticação 2FA';

  @override
  String get typeMessage => 'Digite uma mensagem...';

  @override
  String get typeQuizzes => 'Quizzes';

  @override
  String get typeStreak => 'Sequência';

  @override
  String typeWordStartingWith(String letter) {
    return 'Digite uma palavra que comece com \"$letter\"';
  }

  @override
  String get typeWordsLearned => 'Palavras Aprendidas';

  @override
  String get typeXp => 'XP';

  @override
  String get unableToLoadProfile => 'Não foi possível carregar o perfil';

  @override
  String get unableToPlayVoiceIntro =>
      'Não foi possível reproduzir a apresentação de voz';

  @override
  String get undoSwipe => 'Desfazer Swipe';

  @override
  String unitLabelN(String number) {
    return 'Unidade $number';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get unlock => 'Desbloquear';

  @override
  String unlockMoreProfiles(int count, int cost) {
    return 'Desbloqueie mais $count perfis na grade por $cost moedas.';
  }

  @override
  String unmatchConfirm(String name) {
    return 'Tem certeza de que deseja desfazer o match com $name? Isso nao pode ser desfeito.';
  }

  @override
  String get unmatchLabel => 'Desfazer Match';

  @override
  String unmatchedWith(String name) {
    return 'Match desfeito com $name';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeForEarlyAccess =>
      'Faça upgrade para Prata, Ouro ou Platina para acesso antecipado em 1º de março de 2026!';

  @override
  String get upgradeNow => 'Fazer Upgrade Agora';

  @override
  String get upgradeToPremium => 'Atualizar para Premium';

  @override
  String upgradeToTier(String tier) {
    return 'Fazer upgrade para $tier';
  }

  @override
  String get uploadPhoto => 'Fazer Upload de Foto';

  @override
  String get uppercaseLowercase => 'Letras maiúsculas e minúsculas';

  @override
  String get useCurrentGpsLocation => 'Usar minha localização GPS atual';

  @override
  String get usedToday => 'Usado hoje';

  @override
  String get usedWords => 'Palavras Usadas';

  @override
  String userBlockedMessage(String displayName) {
    return '$displayName foi bloqueado(a)';
  }

  @override
  String get userBlockedTitle => 'Usuário Bloqueado!';

  @override
  String get userNotFound => 'Usuário não encontrado';

  @override
  String get usernameOrProfileUrl => 'Nome de usuário ou URL do perfil';

  @override
  String get usernameWithoutAt => 'Nome de usuário (sem @)';

  @override
  String get verificationApproved => 'Verificação Aprovada';

  @override
  String get verificationApprovedMessage =>
      'A sua identidade foi verificada. Agora tem acesso completo à app.';

  @override
  String get verificationApprovedSuccess => 'Verificação aprovada com sucesso';

  @override
  String get verificationDescription =>
      'Para garantir a segurança da nossa comunidade, exigimos que todos os utilizadores verifiquem a sua identidade. Tire uma foto sua segurando o seu documento de identidade.';

  @override
  String get verificationHistory => 'Histórico de Verificações';

  @override
  String get verificationInstructions =>
      'Segure o seu documento de identidade (passaporte, carta de condução ou bilhete de identidade) junto ao rosto e tire uma foto clara.';

  @override
  String get verificationNeedsResubmission => 'Foto Melhor Necessária';

  @override
  String get verificationNeedsResubmissionMessage =>
      'Precisamos de uma foto mais clara para verificação. Por favor reenvie.';

  @override
  String get verificationPanel => 'Painel de Verificação';

  @override
  String get verificationPending => 'Verificação Pendente';

  @override
  String get verificationPendingMessage =>
      'A sua conta está a ser verificada. Isto geralmente demora 24-48 horas. Será notificado quando a revisão estiver completa.';

  @override
  String get verificationRejected => 'Verificação Rejeitada';

  @override
  String get verificationRejectedMessage =>
      'A sua verificação foi rejeitada. Por favor envie uma nova foto.';

  @override
  String get verificationRejectedSuccess => 'Verificação rejeitada';

  @override
  String get verificationRequired => 'Verificação de Identidade Necessária';

  @override
  String get verificationSkipWarning =>
      'Pode explorar a app, mas não poderá conversar ou ver outros perfis até estar verificado.';

  @override
  String get verificationTip1 => 'Certifique-se de ter boa iluminação';

  @override
  String get verificationTip2 =>
      'O seu rosto e o documento devem estar claramente visíveis';

  @override
  String get verificationTip3 =>
      'Segure o documento junto ao rosto, sem o cobrir';

  @override
  String get verificationTip4 => 'O texto do documento deve estar legível';

  @override
  String get verificationTips => 'Dicas para uma verificação bem-sucedida:';

  @override
  String get verificationTitle => 'Verifique Sua Identidade';

  @override
  String get verificationPrivacyTitle => 'Seus dados estão seguros conosco';

  @override
  String get verificationPrivacyEncryption =>
      'Todos os documentos são protegidos com criptografia de ponta a ponta. Nem mesmo os engenheiros do GreenGo podem acessar seus dados.';

  @override
  String get verificationPrivacyAccess =>
      'Suas informações só podem ser acessadas mediante solicitação pessoal por canais oficiais ou e-mail.';

  @override
  String get verificationPrivacySafety =>
      'Esta etapa é essencial para proteger todos os membros. Convidamos você a denunciar qualquer comportamento suspeito e deixar o GreenGo agir.';

  @override
  String get verificationPrivacyReporting =>
      'Se algo acontecer, denuncie imediatamente. O GreenGo investigará e agirá para manter a comunidade segura.';

  @override
  String get verificationChooseMethod => 'Escolha seu método de verificação';

  @override
  String get verificationMethodPhoto => 'Documento de Identidade';

  @override
  String get verificationMethodPhotoDesc =>
      'Tire uma foto segurando seu documento ao lado do rosto';

  @override
  String get verificationMethodPhone => 'Número de Telefone';

  @override
  String get verificationMethodPhoneDesc =>
      'Verifique com o código SMS enviado ao seu telefone';

  @override
  String get verificationPhoneTitle => 'Verificação por Telefone';

  @override
  String get verificationPhoneSubtitle =>
      'Insira seu número de telefone para receber um código de verificação por SMS';

  @override
  String get verificationPhoneLabel => 'Número de telefone';

  @override
  String get verificationPhoneHint => '+55 11 91234-5678';

  @override
  String get verificationSendCode => 'Enviar Código';

  @override
  String get verificationEnterCode =>
      'Insira o código de 6 dígitos enviado ao seu telefone';

  @override
  String get verificationCodeLabel => 'Código de verificação';

  @override
  String get verificationVerifyCode => 'Verificar Código';

  @override
  String get verificationPhoneSuccess =>
      'Número de telefone verificado com sucesso!';

  @override
  String get verificationPhoneResponsibility =>
      'Ao verificar com seu número de telefone, você reconhece que o titular deste número é pessoalmente responsável por todas as ações realizadas nesta conta.';

  @override
  String get verificationResendCode => 'Reenviar código';

  @override
  String verificationCodeSent(String phoneNumber) {
    return 'Código enviado para $phoneNumber';
  }

  @override
  String get verificationPhoneError =>
      'Falha ao verificar o número de telefone. Tente novamente.';

  @override
  String get verificationInvalidCode =>
      'Código inválido. Verifique e tente novamente.';

  @override
  String get verificationOr => 'ou';

  @override
  String get verifyNow => 'Verificar Agora';

  @override
  String vibeTagsCountSelected(Object count, Object limit) {
    return '$count / $limit tags selecionadas';
  }

  @override
  String get vibeTagsGet5Tags => 'Obter 5 tags';

  @override
  String get vibeTagsGetAccessTo => 'Obter acesso a:';

  @override
  String get vibeTagsLimitReached => 'Limite de Tags Atingido';

  @override
  String vibeTagsLimitReachedFree(Object limit) {
    return 'Usuários grátis podem selecionar até $limit tags. Atualize para Premium para 5 tags!';
  }

  @override
  String vibeTagsLimitReachedPremium(Object limit) {
    return 'Você atingiu o máximo de $limit tags. Remova uma para adicionar outra.';
  }

  @override
  String get vibeTagsNoTags => 'Sem tags disponíveis';

  @override
  String get vibeTagsPremiumFeature1 => '5 tags de vibe em vez de 3';

  @override
  String get vibeTagsPremiumFeature2 => 'Tags premium exclusivas';

  @override
  String get vibeTagsPremiumFeature3 => 'Prioridade nos resultados de pesquisa';

  @override
  String get vibeTagsPremiumFeature4 => 'E muito mais!';

  @override
  String get vibeTagsRemoveTag => 'Remover tag';

  @override
  String get vibeTagsSelectDescription =>
      'Selecione tags que correspondam ao seu humor e intenções atuais';

  @override
  String get vibeTagsSetTemporary => 'Definir como tag temporária (24h)';

  @override
  String get vibeTagsShowYourVibe => 'Mostre sua vibe';

  @override
  String get vibeTagsTemporaryDescription =>
      'Mostrar esta vibe nas próximas 24 horas';

  @override
  String get vibeTagsTemporaryTag => 'Tag Temporária (24h)';

  @override
  String get vibeTagsTitle => 'Sua Vibe';

  @override
  String get vibeTagsUpgradeToPremium => 'Atualizar para Premium';

  @override
  String get vibeTagsViewPlans => 'Ver Planos';

  @override
  String get vibeTagsYourSelected => 'Suas Tags Selecionadas';

  @override
  String get videoCallCategory => 'Chamada de Vídeo';

  @override
  String get view => 'Ver';

  @override
  String get viewAllChallenges => 'Ver Todos os Desafios';

  @override
  String get viewAllLabel => 'Ver Tudo';

  @override
  String get viewBadgesAchievementsLevel => 'Ver emblemas, conquistas e nível';

  @override
  String get viewMyProfile => 'Ver Meu Perfil';

  @override
  String viewsGainedCount(int count) {
    return '+$count';
  }

  @override
  String get vipGoldMember => 'MEMBRO OURO';

  @override
  String get vipPlatinumMember => 'PLATINA VIP';

  @override
  String get vipPremiumBenefitsActive => 'Benefícios Premium Ativos';

  @override
  String get vipSilverMember => 'MEMBRO PRATA';

  @override
  String get virtualGiftsAddMessageHint => 'Adicionar uma mensagem (opcional)';

  @override
  String get voiceDeleteConfirm =>
      'Tem certeza de que deseja excluir sua apresentação de voz?';

  @override
  String get voiceDeleteRecording => 'Excluir Gravação';

  @override
  String voiceFailedStartRecording(Object error) {
    return 'Falha ao iniciar gravação: $error';
  }

  @override
  String voiceFailedUploadRecording(Object error) {
    return 'Falha ao carregar gravação: $error';
  }

  @override
  String get voiceIntro => 'Apresentação de Voz';

  @override
  String get voiceIntroSaved => 'Apresentação de voz salva';

  @override
  String get voiceIntroShort => 'Intro de Voz';

  @override
  String get voiceIntroduction => 'Apresentação de Voz';

  @override
  String get voiceIntroductionInfo =>
      'As apresentações por voz ajudam os outros a conhecê-lo melhor. Este passo é opcional.';

  @override
  String get voiceIntroductionSubtitle =>
      'Gravar uma mensagem de voz curta (opcional)';

  @override
  String get voiceIntroductionTitle => 'Apresentação por voz';

  @override
  String get voiceMicrophonePermissionRequired =>
      'Permissão do microfone é necessária';

  @override
  String get voiceMessageTooShort => 'Segure para gravar, solte para enviar';

  @override
  String get voiceSlideToCancel => '‹ Deslize para cancelar';

  @override
  String get voiceReleaseToCancel => 'Solte para cancelar';

  @override
  String get voiceFailedToSend => 'Falha ao enviar mensagem de voz';

  @override
  String get voiceRecordAgain => 'Gravar Novamente';

  @override
  String voiceRecordIntroDescription(int seconds) {
    return 'Grave uma breve apresentação de $seconds segundos para que outros ouçam sua personalidade.';
  }

  @override
  String get voiceRecorded => 'Voz gravada';

  @override
  String voiceRecordingInProgress(Object maxDuration) {
    return 'Gravando... (máx. $maxDuration segundos)';
  }

  @override
  String get voiceRecordingReady => 'Gravação pronta';

  @override
  String get voiceRecordingSaved => 'Gravação salva';

  @override
  String get voiceRecordingTips => 'Dicas de Gravação';

  @override
  String get voiceSavedMessage => 'Sua apresentação de voz foi atualizada';

  @override
  String get voiceSavedTitle => 'Voz Salva!';

  @override
  String get voiceStandOutWithYourVoice => 'Destaque-se com sua voz!';

  @override
  String get voiceTapToRecord => 'Toque para gravar';

  @override
  String get voiceTipBeYourself => 'Seja você mesmo e natural';

  @override
  String get voiceTipFindQuietPlace => 'Encontre um lugar silencioso';

  @override
  String get voiceTipKeepItShort => 'Mantenha breve e simples';

  @override
  String get voiceTipShareWhatMakesYouUnique =>
      'Compartilhe o que te torna único';

  @override
  String get voiceUploadFailed => 'Falha ao enviar gravação de voz';

  @override
  String get voiceUploading => 'Enviando...';

  @override
  String get vsLabel => 'VS';

  @override
  String get waitingAccessDateBasic =>
      'Seu acesso começará em 15 de março de 2026';

  @override
  String waitingAccessDatePremium(String tier) {
    return 'Como membro $tier, você tem acesso antecipado em 1º de março de 2026!';
  }

  @override
  String get waitingAccessDateTitle => 'Sua Data de Acesso';

  @override
  String waitingCountLabel(String count) {
    return '$count esperando';
  }

  @override
  String get waitingCountdownLabel => 'Sua data de lançamento';

  @override
  String get waitingCountdownSubtitle =>
      'Obrigado pelo cadastro! O GreenGo Chat será lançado em breve. Prepare-se para uma experiência exclusiva.';

  @override
  String get waitingCountdownTitle => 'Contagem Regressiva para o Lançamento';

  @override
  String waitingDaysRemaining(int days) {
    return '$days dias';
  }

  @override
  String get waitingEarlyAccessMember => 'Membro de Acesso Antecipado';

  @override
  String get waitingEnableNotificationsSubtitle =>
      'Ative as notificações para ser o primeiro a saber quando pode acessar o app.';

  @override
  String get waitingEnableNotificationsTitle => 'Fique por dentro';

  @override
  String get waitingExclusiveAccess => 'Tempo até você poder usar o app';

  @override
  String get waitingGeneralLaunchDate => 'Data de lançamento geral';

  @override
  String get waitingYourAccessDate => 'Sua data de acesso';

  @override
  String get waitingForPlayers => 'Aguardando jogadores...';

  @override
  String get waitingForVerification => 'A aguardar verificação...';

  @override
  String waitingHoursRemaining(int hours) {
    return '$hours horas';
  }

  @override
  String get waitingMessageApproved =>
      'Ótimas notícias! Sua conta foi aprovada. Você poderá acessar o GreenGoChat na data indicada abaixo.';

  @override
  String get waitingMessagePending =>
      'Sua conta está pendente de aprovação pela nossa equipe. Iremos notificá-lo assim que sua conta for analisada.';

  @override
  String get waitingMessageRejected =>
      'Infelizmente, sua conta não pôde ser aprovada no momento. Por favor entre em contato com o suporte para mais informações.';

  @override
  String waitingMinutesRemaining(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get waitingNotificationEnabled =>
      'Notificações ativadas - avisaremos você quando puder acessar o app!';

  @override
  String get waitingProfileUnderReview => 'Perfil em análise';

  @override
  String get waitingReviewMessage =>
      'O app já está online! Nossa equipe está analisando seu perfil para garantir a melhor experiência para nossa comunidade. Isso geralmente leva de 24 a 48 horas.';

  @override
  String waitingSecondsRemaining(int seconds) {
    return '$seconds segundos';
  }

  @override
  String get waitingStayTuned =>
      'Fique ligado! Iremos notificá-lo quando for hora de começar a se conectar.';

  @override
  String get waitingStepActivation => 'Ativação de conta';

  @override
  String get waitingStepRegistration => 'Cadastro concluído';

  @override
  String get waitingStepReview => 'Análise de perfil em andamento';

  @override
  String get waitingSubtitle => 'Sua conta foi criada com sucesso';

  @override
  String get waitingThankYouRegistration => 'Obrigado pelo cadastro!';

  @override
  String get waitingTitle => 'Obrigado por se Cadastrar!';

  @override
  String get weeklyChallengesTitle => 'Desafios Semanais';

  @override
  String get weight => 'Peso';

  @override
  String get weightLabel => 'Peso';

  @override
  String get welcome => 'Bem-vindo ao GreenGoChat';

  @override
  String get wordAlreadyUsed => 'Palavra já usada';

  @override
  String get wordReported => 'Palavra reportada';

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
    return '$amount XP ganhos';
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
  String get yearlyMembership => 'Assinatura anual';

  @override
  String yearsLabel(int age) {
    return '$age anos';
  }

  @override
  String get yes => 'Sim';

  @override
  String get yesterday => 'ontem';

  @override
  String youAndMatched(String name) {
    return 'Você e $name curtiram um ao outro';
  }

  @override
  String get youGotSuperLike => 'Você recebeu uma Conexão Prioritária!';

  @override
  String get youLabel => 'VOCE';

  @override
  String get youLose => 'Você Perdeu';

  @override
  String youMatchedWithOnDate(String name, String date) {
    return 'Você deu match com $name em $date';
  }

  @override
  String get youWin => 'Você Venceu!';

  @override
  String get yourLanguages => 'Seus Idiomas';

  @override
  String get yourRankLabel => 'Sua Posição';

  @override
  String get yourTurn => 'Sua Vez!';

  @override
  String get achievementBadges => 'Distintivos de Conquistas';

  @override
  String get achievementBadgesSubtitle =>
      'Toque para selecionar quais distintivos exibir no seu perfil (máx. 5)';

  @override
  String get noBadgesYet => 'Desbloqueie conquistas para ganhar distintivos!';

  @override
  String get guideTitle => 'Como o GreenGo Funciona';

  @override
  String get guideSwipeTitle => 'Deslizar Perfis';

  @override
  String get guideSwipeItem1 =>
      'Deslize para a direita para Connect com alguém, deslize para a esquerda para Nope.';

  @override
  String get guideSwipeItem2 =>
      'Deslize para cima para enviar um Priority Connect (usa moedas).';

  @override
  String get guideSwipeItem3 =>
      'Deslize para baixo para Explore Next e pular um perfil por enquanto.';

  @override
  String get guideSwipeItem4 =>
      'Você pode alternar entre o modo de deslizar e grade usando o ícone na barra superior.';

  @override
  String get guideGridTitle => 'Visualização em Grade';

  @override
  String get guideGridItem1 =>
      'Navegue pelos perfis em formato de grade para uma visão geral rápida.';

  @override
  String get guideGridItem2 =>
      'Toque em uma imagem de perfil para revelar os quatro botões de ação: Connect, Priority Connect, Nope e Explore Next.';

  @override
  String get guideGridItem3 =>
      'Mantenha pressionada a imagem de um perfil para ver os detalhes sem abrir o perfil completo.';

  @override
  String get guideConnectionsTitle => 'Conectando-se com Pessoas';

  @override
  String get guideConnectionsItem1 =>
      'Quando duas pessoas fazem Connect uma com a outra, é um match!';

  @override
  String get guideConnectionsItem2 =>
      'Após o match, vocês podem começar a conversar imediatamente.';

  @override
  String get guideConnectionsItem3 =>
      'Use Priority Connect para se destacar e aumentar suas chances.';

  @override
  String get guideConnectionsItem4 =>
      'Confira a aba Trocas para ver todos os seus matches e conversas.';

  @override
  String get guideChatTitle => 'Chat e Mensagens';

  @override
  String get guideChatItem1 =>
      'Envie mensagens de texto, fotos e notas de voz.';

  @override
  String get guideChatItem2 =>
      'Use o recurso de tradução para conversar em diferentes idiomas.';

  @override
  String get guideChatItem3 =>
      'Abra as configurações do chat para personalizar sua experiência: ative a verificação gramatical, respostas inteligentes, dicas culturais, decomposição de palavras, ajuda na pronúncia e mais.';

  @override
  String get guideChatItem4 =>
      'Ative o texto para fala para ouvir as traduções, mostrar bandeiras de idiomas e acompanhar seus XP de aprendizado de idiomas.';

  @override
  String get guideFiltersTitle => 'Filtros de Descoberta';

  @override
  String get guideFiltersItem1 =>
      'Toque no ícone de filtro para definir suas preferências: faixa etária, distância, idiomas e mais.';

  @override
  String get guideFiltersItem2 =>
      'Modo Aleatório: ative este interruptor para descobrir pessoas aleatórias de todo o mundo. Cada atualização mostra um novo conjunto de perfis. Quando o Modo Aleatório está desativado, apenas são mostradas pessoas perto de você. Você também pode selecionar países específicos para restringir sua busca.';

  @override
  String get guideFiltersItem3 =>
      'Os filtros ajudam você a encontrar pessoas que combinam com o que você procura. Você pode ajustá-los a qualquer momento.';

  @override
  String get guideTravelTitle => 'Viagem e Exploração';

  @override
  String get guideTravelItem1 =>
      'Ative o Modo Viajante para aparecer na descoberta de uma cidade que planeja visitar por 24 horas.';

  @override
  String get guideTravelItem2 =>
      'Guias Locais podem ajudar viajantes a descobrir sua cidade e cultura.';

  @override
  String get guideTravelItem3 =>
      'Parceiros de intercâmbio de idiomas são conectados com base no que você fala e no que quer aprender.';

  @override
  String get guideMembershipTitle => 'Assinatura Base';

  @override
  String get guideMembershipItem1 =>
      'Sua assinatura base dá acesso a todos os recursos principais: deslizar, conversar e fazer matches.';

  @override
  String get guideMembershipItem2 =>
      'A assinatura começa com um período gratuito após o primeiro cadastro.';

  @override
  String get guideMembershipItem3 =>
      'Quando sua assinatura expirar, você pode renová-la para continuar usando o app.';

  @override
  String get guideTiersTitle => 'Níveis VIP (Prata, Ouro, Platina)';

  @override
  String get guideTiersItem1 =>
      'Prata: Mais connects diários, veja quem fez Connect com você e suporte prioritário.';

  @override
  String get guideTiersItem2 =>
      'Ouro: Tudo do Prata mais connects ilimitados, filtros avançados e confirmação de leitura.';

  @override
  String get guideTiersItem3 =>
      'Platina: Tudo do Ouro mais impulso de perfil, escolhas top e recursos exclusivos.';

  @override
  String get guideTiersItem4 =>
      'Os níveis VIP são independentes da assinatura base e oferecem benefícios extras.';

  @override
  String get guideCoinsTitle => 'Moedas';

  @override
  String get guideCoinsItem1 =>
      'As moedas são usadas para ações premium. Aqui estão os custos:';

  @override
  String get guideCoinsItem2 =>
      '• Priority Connect: 10 moedas  • Boost: 50 moedas  • Mensagem direta: 2/dia grátis, depois 50 moedas';

  @override
  String get guideCoinsItem3 =>
      '• Incógnito: 30 moedas/dia  • Viajante: 100 moedas/dia';

  @override
  String get guideCoinsItem4 =>
      '• Ouvir (TTS): 5 moedas  • Extensão da grade: 10 moedas  • Coach de aprendizagem: 10 moedas/sessão';

  @override
  String get guideCoinsItem5 =>
      'Você recebe 20 moedas grátis por dia. Ganhe mais com conquistas, classificações e a Loja.';

  @override
  String get guideLeaderboardTitle => 'Placar';

  @override
  String get guideLeaderboardItem1 =>
      'Compita com outros usuários para subir no placar e ganhar recompensas.';

  @override
  String get guideLeaderboardItem2 =>
      'Ganhe pontos sendo ativo, completando seu perfil e interagindo com outros.';

  @override
  String get guideGridFiltersTitle => 'Filtros de grade';

  @override
  String get guideGridFiltersItem1 =>
      'No modo grade, use os chips de filtro no topo para restringir perfis.';

  @override
  String get guideGridFiltersItem2 =>
      'Todos: Mostra todos no seu grupo de descoberta.';

  @override
  String get guideGridFiltersItem3 =>
      'Conectados: Pessoas para quem você enviou uma solicitação de conexão.';

  @override
  String get guideGridFiltersItem4 =>
      'Prioritário: Pessoas para quem você enviou uma Conexão Prioritária.';

  @override
  String get guideGridFiltersItem5 =>
      'Recusados: Pessoas que você escolheu passar.';

  @override
  String get guideGridFiltersItem6 =>
      'Viajantes: Pessoas com o Modo Viajante ativo, visitando uma cidade perto de você.';

  @override
  String get guideExchangesTitle => 'Trocas (Chat)';

  @override
  String get guideExchangesItem1 =>
      'As Trocas são onde ficam todas as suas conversas. Você as encontra no menu inferior.';

  @override
  String get guideExchangesItem2 =>
      'O emblema vermelho no ícone Trocas mostra o número de conversas com mensagens não lidas ou aprovações pendentes.';

  @override
  String get guideExchangesItem3 =>
      'Use os filtros para organizar seus chats: Todos, Novos, Sem resposta, Favoritos, A aprovar, Match e Pesquisa.';

  @override
  String get guideExchangesItem4 =>
      'Novos mostra conversas com novas mensagens não lidas. Sem resposta mostra mensagens que você ainda não respondeu.';

  @override
  String get guideExchangesItem5 =>
      'Para aprovar mostra solicitações de Conexão Prioritária aguardando sua decisão. Aceite ou recuse diretamente da lista.';

  @override
  String get guideExchangesItem6 =>
      'As conversas não lidas são destacadas com texto em negrito e um efeito dourado brilhante para encontrá-las facilmente.';

  @override
  String get guideExchangesItem7 =>
      'Toque em uma conversa para abrir o chat. Uma vez aberta, é marcada como lida e a contagem do emblema diminui.';

  @override
  String get guideExchangesItem8 =>
      'Pressione longamente uma conversa para mais opções. Use o ícone de estrela para adicionar um chat aos seus Favoritos.';

  @override
  String get guideExchangesItem9 =>
      'Cada conversa mostra as bandeiras de idioma do outro usuário, para que você saiba quais idiomas ele fala.';

  @override
  String get guideGroupsTitle => 'Grupos (Culture Circles)';

  @override
  String get guideGroupsItem1 =>
      'Crie um grupo para conversar com várias pessoas ao mesmo tempo sobre um interesse ou idioma em comum.';

  @override
  String get guideGroupsItem2 =>
      'Administradores podem renomear o grupo, mudar a foto e adicionar ou remover membros.';

  @override
  String get guideGroupsItem3 =>
      'Convide pessoas pelo apelido nas informações do grupo.';

  @override
  String get guideGroupsItem4 =>
      'Adicione suas próprias tags privadas a um grupo nas informações do grupo e filtre sua lista de grupos por tag — só você vê suas tags.';

  @override
  String get guideGroupsItem5 =>
      'Saia ou denuncie um grupo a qualquer momento.';

  @override
  String get guideEventsTitle => 'Eventos';

  @override
  String get guideEventsItem1 =>
      'Descubra eventos perto de você — festas, visitas a museus, encontros de idiomas e passeios pela cidade.';

  @override
  String get guideEventsItem2 =>
      'Explore experiências e atrações selecionadas, ou crie seu próprio evento com fotos, localização e data.';

  @override
  String get guideEventsItem3 =>
      'Marque eventos como Vou participar ou Tenho interesse e encontre-os na aba Vou participar.';

  @override
  String get guideEventsItem4 =>
      'Cada evento tem seu próprio chat; os organizadores podem enviar anúncios a todos os participantes.';

  @override
  String get guideEventsItem5 =>
      'Compartilhe qualquer evento em uma conversa privada ou em um grupo.';

  @override
  String get guideEventsItem6 =>
      'Explore eventos do mundo todo no mapa, por localização.';

  @override
  String get guideSafetyTitle => 'Segurança e Privacidade';

  @override
  String get guideSafetyItem1 =>
      'Todas as fotos são verificadas por IA para garantir perfis autênticos.';

  @override
  String get guideSafetyItem2 =>
      'Você pode bloquear ou denunciar qualquer usuário a qualquer momento pelo perfil dele.';

  @override
  String get guideSafetyItem3 =>
      'Suas informações pessoais são protegidas e nunca são compartilhadas sem o seu consentimento.';

  @override
  String get firstStepsTitle => 'Primeiros Passos';

  @override
  String get firstStepsReview =>
      'Seus documentos serão analisados em até 24 a 48 horas após o envio.';

  @override
  String get firstStepsStatusUpdate =>
      'O app precisa de aproximadamente 15 minutos para atualizar seu status atual após o primeiro login.';

  @override
  String get firstStepsSupportChat =>
      'Você pode entrar em contato com o suporte pelo chat ou abrindo um chamado diretamente.';

  @override
  String get showSupportUser => 'Mostrar Suporte GreenGo';

  @override
  String get showSupportUserDescription =>
      'Mostrar o usuário Suporte GreenGo na grade de descoberta';

  @override
  String get preferenceShowMyNetwork => 'Minha Rede';

  @override
  String get preferenceShowMyNetworkDesc =>
      'Mostrar apenas pessoas na sua rede (matches e Priority Connect aceitos).';

  @override
  String get randomMode => 'Modo Aleatório';

  @override
  String get randomModeDescription =>
      'Descubra pessoas aleatórias do mundo todo, ordenadas por distância. Quando desativado, apenas pessoas próximas a você são exibidas.';

  @override
  String get yourProfile => 'Você';

  @override
  String get loadingMsg1 => 'Procurando perfis incríveis ao redor do mundo...';

  @override
  String get loadingMsg2 => 'Conectando corações através dos continentes...';

  @override
  String get loadingMsg3 => 'Descobrindo pessoas incríveis perto de você...';

  @override
  String get loadingMsg4 =>
      'Preparando suas correspondências personalizadas...';

  @override
  String get loadingMsg5 => 'Explorando perfis de todos os cantos do mundo...';

  @override
  String get loadingMsg6 =>
      'Encontrando pessoas que compartilham seus interesses...';

  @override
  String get loadingMsg7 => 'Configurando sua experiência de descoberta...';

  @override
  String get loadingMsg8 => 'Carregando perfis lindos só para você...';

  @override
  String get loadingMsg9 => 'Procurando sua combinação perfeita...';

  @override
  String get loadingMsg10 => 'Trazendo o mundo mais perto de você...';

  @override
  String get loadingMsg11 =>
      'Selecionando perfis com base nas suas preferências...';

  @override
  String get loadingMsg12 => 'Quase lá! Coisas boas levam um momento...';

  @override
  String get loadingMsg13 => 'Conectando você a um mundo de possibilidades...';

  @override
  String get loadingMsg14 =>
      'Encontrando as melhores combinações na sua área...';

  @override
  String get loadingMsg15 => 'Desbloqueando novas conexões ao seu redor...';

  @override
  String get loadingMsg16 =>
      'Sua próxima grande conversa está a um swipe de distância...';

  @override
  String get loadingMsg17 => 'Reunindo perfis de todo o mundo...';

  @override
  String get loadingMsg18 => 'Preparando algo especial para você...';

  @override
  String get loadingMsg19 => 'Garantindo que tudo esteja perfeito...';

  @override
  String get loadingMsg20 =>
      'O amor não conhece fronteiras, e nós também não...';

  @override
  String get loadingMsg21 => 'Aquecendo seu feed de descoberta...';

  @override
  String get loadingMsg22 =>
      'Escaneando o globo em busca de pessoas interessantes...';

  @override
  String get loadingMsg23 => 'Grandes conexões começam aqui...';

  @override
  String get loadingMsg24 => 'Sua aventura está prestes a começar...';

  @override
  String get filterFavorites => 'Favoritos';

  @override
  String get filterToApprove => 'Para aprovar';

  @override
  String get priorityConnectAccept => 'Aceitar';

  @override
  String get priorityConnectReject => 'Rejeitar';

  @override
  String get priorityConnectPending => 'Aprovação pendente';

  @override
  String get membershipTrialTitle => 'Comece seu teste grátis!';

  @override
  String get membershipTrialSubtitle =>
      '7 dias grátis, depois renova anualmente';

  @override
  String get membershipTrialFeature1 => 'Swipes e conexões ilimitadas';

  @override
  String get membershipTrialFeature2 => '500 moedas bônus na ativação';

  @override
  String get membershipTrialFeature3 =>
      'Acesso completo a todas as funcionalidades';

  @override
  String get membershipTrialCta => 'Iniciar teste de 7 dias';

  @override
  String get membershipTrialFooter =>
      'Cancele a qualquer momento durante o teste. Sem cobrança até o dia 8.';

  @override
  String get membershipTrialBadge => 'GRÁTIS POR 7 DIAS';

  @override
  String get globeMyNetwork => 'Minha Rede';

  @override
  String get globeMyWorldMap => 'Meu mapa-múndi';

  @override
  String get globeLayerContacts => 'Minha comunidade';

  @override
  String get globeLayerExperiences => 'Experiências';

  @override
  String get globeYou => 'Você';

  @override
  String get globeConnections => 'Conexões';

  @override
  String get globeTraveler => 'Viajante';

  @override
  String globeConnectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'conexões',
      one: 'conexão',
    );
    return '$count $_temp0';
  }

  @override
  String globeConnectionsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'conexões',
      one: 'conexão',
    );
    return '$count $_temp0 aqui';
  }

  @override
  String get globeThisIsYou => 'Este é você!';

  @override
  String globeTravelingTo(String country) {
    return 'Viajando para $country';
  }

  @override
  String globeNoConnectionsInCountry(String country) {
    return 'Ainda não há conexões em $country';
  }

  @override
  String get globeNoConnectionsHint =>
      'Continue se conectando para encontrar pessoas aqui!';

  @override
  String get globeProfile => 'Perfil';

  @override
  String get globeChat => 'Chat';

  @override
  String get globeViewProfileTooltip => 'Ver Perfil';

  @override
  String get globeOpenChatTooltip => 'Abrir Chat';

  @override
  String globeNoConnectionsInCountryTitle(String country) {
    return 'Sem conexões em $country';
  }

  @override
  String get discoverabilityExact => 'Exata';

  @override
  String get discoverabilityExactDesc =>
      'Marcador na sua localização exata (<1km)';

  @override
  String get discoverabilityApproximate => 'Aproximada';

  @override
  String get discoverabilityApproximateDesc =>
      'Marcador na sua região (grade de ~50km, padrão)';

  @override
  String get discoverabilityCountry => 'País';

  @override
  String get discoverabilityCountryDesc =>
      'Marcador em algum lugar do seu país';

  @override
  String get discoverabilityHidden => 'Oculta';

  @override
  String get discoverabilityHiddenDesc => 'Não descobrível no Mapa';

  @override
  String get discoverabilityTitle => 'Visibilidade no Globo';

  @override
  String get discoverabilityInfo =>
      'Suas conexões sempre veem você no Mapa, independentemente desta configuração.';

  @override
  String get discoverabilityChangedExact => 'Localização definida como exata';

  @override
  String get discoverabilityChangedApproximate =>
      'Localização definida como aproximada';

  @override
  String get discoverabilityChangedCountry =>
      'Localização definida como nível de país';

  @override
  String get discoverabilityChangedHidden => 'Agora você está oculto no mapa';

  @override
  String get onboardingExitTitle => 'Sair do cadastro?';

  @override
  String get onboardingExitMessage =>
      'Você será desconectado. Você pode terminar de configurar seu perfil no próximo login.';

  @override
  String get onboardingExitConfirm => 'Sair';

  @override
  String get onboardingExitCancel => 'Cancelar';

  @override
  String get loginEmailOrNickname => 'E-mail / Apelido';

  @override
  String get paymentVerifying => 'Verificando seu pagamento...';

  @override
  String get paymentSuccess => 'Pagamento bem-sucedido!';

  @override
  String get paymentSuccessMessage => 'Sua compra foi creditada na sua conta.';

  @override
  String get paymentPending => 'Processando pagamento';

  @override
  String get paymentPendingMessage =>
      'Seu pagamento está sendo processado. Pode levar alguns minutos para aparecer.';

  @override
  String get paymentCancelled => 'Pagamento cancelado';

  @override
  String get paymentCancelledMessage =>
      'Seu pagamento foi cancelado. Nenhuma cobrança foi feita.';

  @override
  String get continueToApp => 'Continuar';

  @override
  String get webCheckoutOpening => 'Abrindo o pagamento seguro…';

  @override
  String get webCheckoutWaiting =>
      'Conclua seu pagamento na nova aba. Esta janela será atualizada automaticamente quando terminar.';

  @override
  String get webCheckoutTimeout =>
      'Ainda não conseguimos confirmar seu pagamento. Se você concluiu, seu saldo será atualizado em breve.';

  @override
  String get webCheckoutFailed =>
      'Não foi possível iniciar o pagamento. Tente novamente.';

  @override
  String get groupNewGroup => 'Novo grupo';

  @override
  String get groupCreate => 'Criar';

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String groupSelectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get groupInviteByNickname => 'Convidar por apelido';

  @override
  String get groupAddMembers => 'Adicionar membros';

  @override
  String get groupTtsReadTranslated => 'Ler a tradução em voz alta';

  @override
  String get groupTtsReadTranslatedHint =>
      'Toque duas vezes em uma mensagem para ouvi-la. Ligado = seu idioma, Desligado = original.';

  @override
  String get ttsNotEnoughCoins =>
      'Moedas insuficientes para TTS (são necessárias 5)';

  @override
  String get groupRemoveMember => 'Remover membro';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Remover $name deste grupo?';
  }

  @override
  String groupMemberRemoved(String name) {
    return '$name removido';
  }

  @override
  String groupAddSelected(int count) {
    return 'Adicionar $count selecionados';
  }

  @override
  String get groupNicknameHint => 'Digite um apelido';

  @override
  String get groupNoContacts => 'Ainda não há contatos para adicionar';

  @override
  String get groupNoOneFound => 'Ninguém encontrado com esse apelido';

  @override
  String get groupAlreadyAdded => 'Já adicionado';

  @override
  String groupAddedCount(int count) {
    return '$count adicionados';
  }

  @override
  String get groupSearchFailed => 'A busca falhou';

  @override
  String get groupInfo => 'Informações do grupo';

  @override
  String groupMembersCount(int count) {
    return '$count membros';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupYou => 'Você';

  @override
  String get groupLeave => 'Sair do grupo';

  @override
  String get groupLeaveConfirmTitle => 'Sair do grupo?';

  @override
  String get groupLeaveConfirmBody =>
      'Você deixará de receber mensagens deste grupo.';

  @override
  String get groupCancel => 'Cancelar';

  @override
  String get groupLeaveAction => 'Sair';

  @override
  String get groupReport => 'Denunciar grupo';

  @override
  String get groupReportConfirmBody =>
      'Denunciar este grupo à nossa equipe de segurança?';

  @override
  String get groupReportAction => 'Denunciar';

  @override
  String get groupReportSubmitted => 'Denúncia enviada';

  @override
  String get groupMessageHint => 'Mensagem…';

  @override
  String get groupSayHello => 'Diga olá ao grupo 👋';

  @override
  String get groupLoadError => 'Não foi possível carregar este grupo';

  @override
  String get chatLocation => 'Localização';

  @override
  String get chatShareLocation => 'Compartilhar localização';

  @override
  String get chatLocationDenied =>
      'É necessária a permissão de localização para compartilhar sua posição';

  @override
  String get chatOpenInMaps => 'Abrir no Maps';

  @override
  String get eventsSearchHint => 'Buscar por país, cidade ou nome';

  @override
  String get eventsSortPopular => 'Popular';

  @override
  String get eventsViewList => 'Visualização em lista';

  @override
  String get eventsViewGrid => 'Visualização em grade';

  @override
  String get eventViewEvent => 'Ver evento';

  @override
  String get eventLoadError => 'Não foi possível carregar este evento';

  @override
  String get eventShare => 'Compartilhar evento';

  @override
  String get eventShared => 'Evento compartilhado';

  @override
  String get eventShareEmpty =>
      'Ainda não há chats ou grupos para compartilhar';

  @override
  String get eventsUnlimitedAttendees => 'Participantes ilimitados';

  @override
  String get eventsPrivateEvent => 'Evento privado';

  @override
  String get eventsExternalLinks => 'Links';

  @override
  String get eventsLinkUrlHint => 'https://…';

  @override
  String get eventsAddLink => 'Adicionar link';

  @override
  String get tierLimitTitle => 'Faça upgrade para criar mais';

  @override
  String tierLimitEventsBody(int max) {
    return 'Seu plano permite $max eventos. Faça upgrade para criar mais.';
  }

  @override
  String tierLimitGroupsBody(int max) {
    return 'Seu plano permite $max grupos. Faça upgrade para criar mais.';
  }

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get profileRankingSubtitle => 'Ver o ranking global';

  @override
  String get eventBroadcastTooltip => 'Transmitir para todos';

  @override
  String get eventBroadcastHint => 'Anúncio para todos os participantes…';

  @override
  String get eventBroadcastLabel => 'Anúncio';

  @override
  String get eventsFeatured => 'Destaque';

  @override
  String get eventsInsufficientCoins => 'Moedas insuficientes';

  @override
  String get eventsConfirmAction => 'Confirmar';

  @override
  String get eventsBoost => 'Destacar';

  @override
  String get eventsBoosted => 'Evento destacado!';

  @override
  String eventsJoinForCoins(int cost) {
    return 'Participar deste evento por $cost moedas?';
  }

  @override
  String eventsBoostConfirm(int cost) {
    return 'Destacar este evento por $cost moedas por 7 dias?';
  }

  @override
  String groupMemberLimit(int count) {
    return 'Até $count membros por grupo';
  }

  @override
  String get eventsPriceHint => 'Preço (1–1000)';

  @override
  String get eventsPriceRange => 'Insira um preço entre 1 e 1000';

  @override
  String get eventsLinkLabelHint => 'Rótulo (opcional)';

  @override
  String get eventsPickLocation => 'Escolher local';

  @override
  String get eventsSearchAddress => 'Buscar endereço';

  @override
  String get eventsUseThisLocation => 'Usar este local';

  @override
  String get eventsEditEvent => 'Editar evento';

  @override
  String get groupEditName => 'Editar nome do grupo';

  @override
  String get groupChangePhoto => 'Alterar foto do grupo';

  @override
  String get groupUploadingPhoto => 'Enviando foto…';

  @override
  String get groupPhotoUpdated => 'Foto do grupo atualizada';

  @override
  String get groupPhotoUpdateFailed => 'Falha ao atualizar a foto do grupo';

  @override
  String get eventTextProhibited =>
      'O título ou a descrição contém linguagem proibida e não pode ser usado';

  @override
  String get groupSearchHint => 'Pesquisar grupos';

  @override
  String get groupNoSearchResults => 'Nenhum grupo encontrado';

  @override
  String get groupMyTags => 'Minhas tags';

  @override
  String get groupMyTagsSubtitle => 'Privadas — só você vê';

  @override
  String get groupNoTagsYet => 'Ainda sem tags';

  @override
  String get groupTagsEditTitle => 'Editar minhas tags';

  @override
  String get groupAddTagHint => 'Adicionar uma tag';

  @override
  String get groupTagsSave => 'Salvar';

  @override
  String get groupTagsSaved => 'Tags salvas';

  @override
  String get groupTagsSaveFailed => 'Não foi possível salvar as tags';

  @override
  String get groupTagsLimitReached => 'Limite de tags atingido';

  @override
  String peopleTagsEditTitle(String name) {
    return 'Tags de $name';
  }

  @override
  String get groupTranslationSettings => 'Tradução';

  @override
  String get groupTranslateMessages => 'Traduzir mensagens';

  @override
  String get groupShowOriginal => 'Mostrar texto original';

  @override
  String get eventsTabLiveEvents => 'Eventos ao vivo';

  @override
  String get globeLayerLiveEvents => 'Eventos ao vivo';

  @override
  String get eventsSortBy => 'Ordenar por';

  @override
  String get eventsSortDistance => 'Distância';

  @override
  String get eventsSortStars => 'Estrelas';

  @override
  String get eventsSortReviews => 'Avaliações';

  @override
  String get eventsSortDate => 'Data';

  @override
  String get catMuseums => 'Museus';

  @override
  String get catSights => 'Pontos turísticos';

  @override
  String get catParks => 'Parques';

  @override
  String get catNationalParks => 'Parques nacionais';

  @override
  String get catThemeParks => 'Parques temáticos';

  @override
  String get catTours => 'Passeios e turismo';

  @override
  String get catCulture => 'Cultura e museus';

  @override
  String get catFoodDrink => 'Comida e bebida';

  @override
  String get catCruises => 'Cruzeiros e água';

  @override
  String get catNature => 'Natureza e ar livre';

  @override
  String get catDayTrips => 'Passeios de um dia';

  @override
  String get catTickets => 'Ingressos e passes';

  @override
  String get catOther => 'Outros';

  @override
  String get eventsUnlimited => 'Ilimitado';

  @override
  String get eventsTabGoing => 'Vou';

  @override
  String get globeLayerCommunityEvents => 'Eventos da comunidade';

  @override
  String get webMapUnavailableTitle =>
      'Mapa interativo disponível no aplicativo mobile';

  @override
  String get webMapUnavailableBody =>
      'Pesquise um endereço para definir sua localização.';

  @override
  String get webLocationPickerTitle => 'Escolha sua localização';

  @override
  String get webLocationSearchHint => 'Pesquisar cidade ou endereço';

  @override
  String get webLocationConfirm => 'Usar esta localização';

  @override
  String get webLocationTapHint => 'Toque no mapa para posicionar um marcador';

  @override
  String webLocationMonthlyLimit(String date) {
    return 'Você pode atualizar sua localização uma vez por mês na web. Próxima atualização disponível em $date.';
  }

  @override
  String get eventMyTicket => 'Meu ingresso';

  @override
  String get eventScanCheckIn => 'Escanear / Check-in';

  @override
  String get eventAttendance => 'Presença';

  @override
  String get eventCheckedIn => 'Check-in feito';

  @override
  String get eventNotCheckedIn => 'Ainda não chegou';

  @override
  String get eventGuestsAllowedLabel =>
      'Convidados permitidos por participante';

  @override
  String get eventBringGuests => 'Levar convidados';

  @override
  String get eventInvalidTicket => 'Ingresso inválido para este evento';

  @override
  String get eventScanInstructions =>
      'Aponte a câmera para o código QR de um participante';

  @override
  String get eventTotalHeadcount => 'Total de presentes';

  @override
  String get eventCameraPermission =>
      'É necessária permissão da câmera para escanear';

  @override
  String get eventTicketSubtitle => 'Mostre este QR na entrada';

  @override
  String eventGuestCount(int count, int max) {
    return '$count de $max convidados';
  }

  @override
  String eventCheckedInSuccess(String name) {
    return '$name fez check-in';
  }

  @override
  String eventAlreadyCheckedIn(String name) {
    return '$name já fez check-in';
  }

  @override
  String eventGuestsBringing(int count) {
    return '+$count convidados';
  }

  @override
  String connectDailyLimitReached(int limit) {
    return 'Você atingiu seu limite diário de $limit novas conexões. Faça upgrade para se conectar com mais pessoas!';
  }

  @override
  String get boostFeatureName => 'Impulso de Perfil';

  @override
  String get boostRequiresTierDescription =>
      'Os impulsos de perfil são um benefício de assinatura paga. Faça upgrade do seu plano para impulsionar seu perfil e ser visto por mais pessoas.';

  @override
  String boostMonthlyLimitReached(int limit) {
    return 'Você já usou todos os $limit impulsos de perfil incluídos no seu plano este mês. Faça upgrade para mais.';
  }

  @override
  String get travelModeFeatureName => 'Modo Viajante';

  @override
  String get travelModeRequiresTierDescription =>
      'O Modo Viajante permite que você apareça no feed de descoberta de outra cidade. Faça upgrade do seu plano para desbloqueá-lo.';

  @override
  String get exploreRecommended => 'Recomendado para você';

  @override
  String get businessAccountTitle => 'Conta empresarial';

  @override
  String get becomeBusiness => 'Torne-se uma empresa';

  @override
  String get businessProfileLabel => 'Perfil empresarial';

  @override
  String get businessCategoryLabel => 'Categoria da empresa';

  @override
  String get businessCategoryHint => 'Selecione uma categoria';

  @override
  String get businessVerifiedLabel => 'Empresa verificada';

  @override
  String get featureThisEvent => 'Destacar este evento';

  @override
  String featureEventCostLabel(int cost) {
    return 'Destacar este evento · $cost moedas';
  }

  @override
  String featureEventActive(String date) {
    return 'Em destaque até $date';
  }

  @override
  String featureEventConfirm(int cost) {
    return 'Destacar este evento por $cost moedas?';
  }

  @override
  String get referralTitle => 'Convidar amigos';

  @override
  String get referralInviteFriends => 'Convidar amigos';

  @override
  String get referralYourCode => 'Seu código de indicação';

  @override
  String get referralShareCta => 'Compartilhar';

  @override
  String get referralShareMessage => 'Entre no GreenGo comigo!';

  @override
  String get referralRewardEarned => 'Moedas ganhas';

  @override
  String get referralCountLabel => 'Amigos convidados';

  @override
  String get referralHowItWorks =>
      'Compartilhe seu código — quando um amigo entra com ele, os dois ganham moedas.';

  @override
  String get streakTitle => 'Sequência';

  @override
  String get streakDaysLabel => 'dias de sequência';

  @override
  String get streakKeepGoing => 'Continue assim!';

  @override
  String get missionsTitle => 'Missões';

  @override
  String get missionsSubtitle => 'Complete missões para ganhar moedas';

  @override
  String get missionProgressLabel => 'Progresso';

  @override
  String get missionRewardLabel => 'Recompensa';

  @override
  String get missionCompleteLabel => 'Concluída';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao GreenGo';

  @override
  String get onboardingWelcomeBody =>
      'Descubra culturas, pratique idiomas, encontre eventos locais e conheça pessoas perto de você — sem barreiras linguísticas.';

  @override
  String get onboardingPickInterests => 'O que você adora?';

  @override
  String get onboardingPickLanguages => 'Idiomas que você fala';

  @override
  String get savedSearchesTitle => 'Buscas salvas';

  @override
  String get saveThisSearch => 'Salvar esta busca';

  @override
  String get savedSearchSaved => 'Busca salva';

  @override
  String get savedSearchRun => 'Executar';

  @override
  String get savedSearchEmpty => 'Ainda sem buscas salvas';

  @override
  String get savedSearchAlertsToggle => 'Alertas';

  @override
  String get exploreFeaturedCommunity => 'Eventos da comunidade em destaque';

  @override
  String get notificationMarkAllRead => 'Marcar tudo como lido';

  @override
  String get analyticsTitle => 'Análises';

  @override
  String get analyticsPlatinumOnly =>
      'As análises são uma funcionalidade Platinum.';

  @override
  String get analyticsEventsHosted => 'Eventos organizados';

  @override
  String get analyticsTotalAttendees => 'Total de participantes';

  @override
  String get analyticsReach => 'Alcance';

  @override
  String get analyticsUpgradeCta => 'Faça upgrade para Platinum';

  @override
  String get safetyVerifiedBadge => 'Verificado';

  @override
  String get safetyReportUser => 'Denunciar';

  @override
  String get safetyBlockUser => 'Bloquear';

  @override
  String get safetyCheckInTitle => 'Check-in de segurança';

  @override
  String get safetyCheckInArrived => 'Cheguei em segurança';

  @override
  String get safetyCheckInDone => 'Você fez check-in em segurança';

  @override
  String get guidelinesTitle => 'Diretrizes da comunidade';

  @override
  String get guidelinesAccept => 'Concordo';

  @override
  String get guidelinesBody =>
      'O GreenGo é uma comunidade intercultural para descoberta, intercâmbio de idiomas, eventos locais e amizade. Seja respeitoso e acolhedor com pessoas de todas as culturas. Este não é um app de encontros. Não são permitidos assédio, discurso de ódio, spam nem conteúdo explícito. Denuncie tudo o que não pertence aqui.';

  @override
  String get businessSectionTitle => 'Empresa';

  @override
  String get businessSectionSubtitle => 'Ferramentas para o seu negócio';

  @override
  String get businessHubAccount => 'Conta empresarial';

  @override
  String get businessHubAnalytics => 'Análises';

  @override
  String get businessHubFeatured => 'Destaques';

  @override
  String get becomeBusinessAction => 'Tornar-se uma';

  @override
  String get becomeBusinessPermanentHint =>
      'Upgrade único. Não pode ser desfeito.';

  @override
  String get becomeBusinessConfirmTitle => 'Tornar-se uma conta empresarial?';

  @override
  String get becomeBusinessConfirmMessage =>
      'Isto é permanente — sua conta se torna uma conta empresarial pública e não pode ser revertida.';

  @override
  String get becomeBusinessConfirmAction => 'Tornar permanente';

  @override
  String get becomeBusinessSuccess =>
      'Sua conta agora é uma conta empresarial.';

  @override
  String get becomeBusinessError =>
      'Não foi possível alterar sua conta. Tente novamente.';

  @override
  String get businessAccountActive => 'Conta empresarial ativa (permanente)';

  @override
  String get businessRequiresPlatinum =>
      'As contas empresariais são uma funcionalidade Platinum. Faça upgrade para desbloquear sua vitrine, seguidores e captação de leads.';

  @override
  String get viewStorefront => 'Ver vitrine';

  @override
  String get requestVerification => 'Solicitar verificação';

  @override
  String get requestVerificationPending => 'Verificação pendente';

  @override
  String get requestVerificationTitle => 'Solicitar verificação';

  @override
  String get verifyBusinessNameLabel => 'Nome da empresa';

  @override
  String get verifyLegalNameLabel => 'Nome legal';

  @override
  String get verifyLegalNameHint => 'Razao social registrada';

  @override
  String get verifyPhoneLabel => 'Numero de telefone';

  @override
  String get verifyPhoneHint => '+55 11 91234-5678';

  @override
  String get verifySendCode => 'Enviar codigo';

  @override
  String get verifyResendCode => 'Reenviar';

  @override
  String get verifyEnterCodeLabel => 'Codigo de 6 digitos';

  @override
  String get verifyConfirmCode => 'Verificar';

  @override
  String get verifyPhoneVerified => 'Telefone verificado';

  @override
  String get verifyOwnerDocumentLabel =>
      'Documento de identidade do proprietario';

  @override
  String get verifyUploadDocument => 'Enviar documento';

  @override
  String get verifyDocumentUploaded => 'Documento enviado';

  @override
  String get verifyDocumentUploadError =>
      'Nao foi possivel enviar o documento. Tente novamente.';

  @override
  String get verifyWebsiteLabel => 'Site (opcional)';

  @override
  String get verifyWebsiteHint => 'https://exemplo.com';

  @override
  String get verifyNotesLabel => 'Notas (opcional)';

  @override
  String get verifyMissingFields =>
      'Preencha todos os campos obrigatorios e verifique seu telefone.';

  @override
  String get requestVerificationMessage =>
      'Conte-nos um pouco sobre seu negócio para podermos verificá-lo. Nossa equipe analisará sua solicitação.';

  @override
  String get requestVerificationNoteHint =>
      'Adicione uma nota (site, endereço, qualquer coisa que nos ajude a verificar você)';

  @override
  String get requestVerificationSubmitted =>
      'Solicitação de verificação enviada.';

  @override
  String get requestVerificationError =>
      'Não foi possível enviar sua solicitação. Tente novamente.';

  @override
  String get submit => 'Enviar';

  @override
  String get businessVerifiedBadgeTooltip => 'Empresa verificada';

  @override
  String get businessLinks => 'Links';

  @override
  String get businessOpeningHours => 'Horário de funcionamento';

  @override
  String get businessHoursNotProvided =>
      'Horário de funcionamento não informado';

  @override
  String get businessGallery => 'Galeria';

  @override
  String get businessUpcomingEvents => 'Próximos eventos';

  @override
  String get businessNoUpcomingEvents => 'Ainda não há próximos eventos.';

  @override
  String get businessCommunities => 'Comunidades';

  @override
  String get businessNoCommunities => 'Ainda não há comunidades.';

  @override
  String get businessContact => 'Contato';

  @override
  String get businessFollow => 'Seguir';

  @override
  String get businessFollowing => 'Seguindo';

  @override
  String get businessFollowError =>
      'Não foi possível atualizar. Tente novamente.';

  @override
  String businessFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seguidores',
      one: '1 seguidor',
      zero: 'Sem seguidores',
    );
    return '$_temp0';
  }

  @override
  String businessMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
      zero: 'Sem membros',
    );
    return '$_temp0';
  }

  @override
  String get adminBusinessVerifications => 'Verificações de Empresas';

  @override
  String get adminBusinessVerificationsSubtitle =>
      'Revisar e aprovar distintivos de empresa verificada';

  @override
  String get adminApproveBusinessVerification => 'Aprovar';

  @override
  String get adminRejectBusinessVerification =>
      'Rejeitar Verificação de Empresa';

  @override
  String get adminBusinessRejectReasonHint => 'Motivo da rejeição (opcional)';

  @override
  String get adminBusinessApproved => 'Empresa verificada';

  @override
  String get adminBusinessRejected => 'Verificação de empresa rejeitada';

  @override
  String get adminNoPendingBusinessVerifications =>
      'Nenhuma verificação de empresa pendente';

  @override
  String get adminAccessDenied => 'Acesso negado. Apenas administradores.';

  @override
  String get adminBusinessVerifiedNotificationTitle =>
      'Sua empresa está verificada';

  @override
  String get adminBusinessVerifiedNotificationBody =>
      'Sua empresa agora exibe o distintivo de verificação dourado.';

  @override
  String adminSubmittedLabel(String date) {
    return 'Enviado $date';
  }

  @override
  String get communitiesSponsored => 'Patrocinado';

  @override
  String get communitiesSponsorThisCommunity => 'Patrocinar esta comunidade';

  @override
  String get communitiesSponsorSubtitle =>
      'Fixe uma promoção no topo para os membros';

  @override
  String get communitiesSponsorFeatureName => 'Patrocínio de comunidade';

  @override
  String get communitiesSponsorRequiresPlatinum =>
      'Patrocinar uma comunidade e fixar uma promoção é uma funcionalidade empresarial Platinum.';

  @override
  String get communitiesEditSponsorship => 'Editar patrocínio e promoção';

  @override
  String get communitiesMarkAsSponsored => 'Marcar como patrocinado';

  @override
  String get communitiesPromoTitleLabel => 'Título da promoção';

  @override
  String get communitiesPromoTitleHint =>
      'ex. 20% de desconto neste fim de semana';

  @override
  String get communitiesPromoBodyLabel => 'Mensagem da promoção';

  @override
  String get communitiesPromoBodyHint => 'Conte aos membros sobre sua oferta';

  @override
  String get communitiesPromoImageLabel => 'URL da imagem (opcional)';

  @override
  String get communitiesPromoLinkEventLabel =>
      'ID do evento associado (opcional)';

  @override
  String get communitiesPromoLinkUrlLabel => 'URL do link (opcional)';

  @override
  String get communitiesPromoTitleRequired =>
      'Insira um título para a promoção';

  @override
  String get communitiesSaveSponsorship => 'Salvar';

  @override
  String get communitiesRemovePromo => 'Remover promoção';

  @override
  String get exploreSearchTooltip => 'Buscar';

  @override
  String get exploreQrTooltip => 'Meus códigos QR';

  @override
  String get universalSearchTitle => 'Buscar';

  @override
  String get universalSearchHint => 'Buscar pessoas e eventos';

  @override
  String get universalSearchTabPeople => 'Pessoas';

  @override
  String get universalSearchTabEvents => 'Eventos';

  @override
  String get universalSearchEmptyPrompt =>
      'Encontre pessoas para conversar e eventos para participar';

  @override
  String get universalSearchNoPeople => 'Nenhuma pessoa encontrada';

  @override
  String get universalSearchNoEvents => 'Nenhum evento encontrado';

  @override
  String get qrHubTitle => 'Códigos QR';

  @override
  String get qrHubTabMyTickets => 'Meus ingressos';

  @override
  String get qrHubTabScan => 'Escanear';

  @override
  String get qrHubNoTickets =>
      'Ainda não há ingressos futuros. Participe de um evento para obter seu código QR.';

  @override
  String get qrHubTicketHint =>
      'Toque em um ingresso para abrir seu código QR completo';

  @override
  String get qrHubScanInstructions =>
      'Aponte a câmera para um código QR do GreenGo';

  @override
  String get qrHubInvalidCode => 'Este não é um código GreenGo válido';

  @override
  String get qrHubJoinedEvent => 'Você vai participar! Abrindo o evento…';

  @override
  String get eventsRepeats => 'Repete';

  @override
  String get eventsRepeatNone => 'Não repete';

  @override
  String get eventsRepeatDaily => 'Diariamente';

  @override
  String get eventsRepeatWeekly => 'Semanalmente';

  @override
  String get eventsRepeatMonthly => 'Mensalmente';

  @override
  String get eventsRepeatInterval => 'A cada';

  @override
  String get eventsRepeatCount => 'Ocorrências';

  @override
  String get eventsRecurringLabel => 'Recorrente';

  @override
  String get eventsCancelSeries => 'Cancelar toda a série';

  @override
  String get eventsCancelSeriesConfirm =>
      'Cancelar todas as ocorrências futuras deste evento recorrente?';

  @override
  String get eventsSeriesCancelled => 'Série cancelada';

  @override
  String get eventsSeriesCancelError => 'Não foi possível cancelar a série';

  @override
  String get eventsSaveAsDraft => 'Salvar como rascunho';

  @override
  String get eventsSchedule => 'Agendar';

  @override
  String get eventsStatusDraft => 'Rascunho';

  @override
  String get eventsStatusScheduled => 'Agendado';

  @override
  String get eventsStatusCancelled => 'Cancelado';

  @override
  String eventsScheduledForDate(String date) {
    return 'Agendado para $date';
  }

  @override
  String eventsRepeatCap(int max) {
    return 'Até $max ocorrências';
  }

  @override
  String get eventsTicketTiers => 'Tipos de ingresso';

  @override
  String get eventsAddTier => 'Adicionar tipo';

  @override
  String get eventsTierName => 'Nome do tipo';

  @override
  String get eventsTierPriceCoins => 'Preço (moedas, 0 = grátis)';

  @override
  String get eventsTierCapacity => 'Capacidade (0 = ilimitado)';

  @override
  String get eventsFreeTier => 'Grátis';

  @override
  String get eventsSelectTier => 'Selecione um ingresso';

  @override
  String get eventsJoinWaitlist => 'Entrar na lista de espera';

  @override
  String get eventsOnWaitlist => 'Na lista de espera';

  @override
  String eventsWaitlistPosition(int position) {
    return 'Você é o #$position na lista de espera';
  }

  @override
  String eventsTierPriceValue(int coins) {
    return '$coins moedas';
  }

  @override
  String eventsTierCapacityValue(int capacity) {
    return '$capacity vagas';
  }

  @override
  String get eventsRsvpError => 'Não foi possível atualizar sua confirmação';

  @override
  String get shareProfileTooltip => 'Compartilhar perfil';

  @override
  String shareProfileMessage(String link) {
    return 'Converse comigo no GreenGo: $link';
  }

  @override
  String shareEventMessage(String link) {
    return 'Veja este evento no GreenGo: $link';
  }

  @override
  String get guidelinesSubtitle =>
      'Uma rápida introdução a como nos conectamos aqui';

  @override
  String get guidelinesWelcomeTitle => 'Bem-vindo entre culturas';

  @override
  String get guidelinesWelcomeDesc =>
      'Conheça pessoas de todos os lugares e compartilhe seu mundo com abertura.';

  @override
  String get guidelinesRespectTitle => 'Respeite todo mundo';

  @override
  String get guidelinesRespectDesc =>
      'Gentileza e curiosidade primeiro — trate os outros como gostaria de ser tratado.';

  @override
  String get guidelinesAuthenticTitle => 'Seja autêntico';

  @override
  String get guidelinesAuthenticDesc =>
      'O GreenGo é para conexões culturais genuínas — não é um app de namoro.';

  @override
  String get guidelinesSafetyTitle => 'Sem assédio nem ódio';

  @override
  String get guidelinesSafetyDesc =>
      'Assédio, discurso de ódio e ameaças não têm lugar aqui.';

  @override
  String get guidelinesNoSpamTitle => 'Sem spam nem conteúdo explícito';

  @override
  String get guidelinesNoSpamDesc =>
      'Mantenha tudo limpo — sem spam, golpes ou conteúdo sexual.';

  @override
  String get guidelinesReportTitle => 'Denuncie o que estiver errado';

  @override
  String get guidelinesReportDesc =>
      'Viu algo estranho? Denuncie e nossa equipe vai analisar.';

  @override
  String get businessNewBadge => 'NOVO';

  @override
  String get businessLeadsTitle => 'Leads';

  @override
  String get businessLeadsEmpty =>
      'Ainda não há leads. As pessoas que entram em contato com você ou salvam seus eventos aparecerão aqui.';

  @override
  String get businessLeadContact => 'Entrou em contato';

  @override
  String get businessLeadSavedEvent => 'Salvou seu evento';

  @override
  String get eventTicketWhen => 'Quando';

  @override
  String get eventTicketVenue => 'Local';

  @override
  String get eventTicketWhere => 'Onde';

  @override
  String get eventTicketGuestsLabel => 'Convidados';

  @override
  String eventTicketAdmits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admite $count pessoas',
      one: 'Admite 1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get shareEvent => 'Compartilhar evento';

  @override
  String get promoteTitle => 'Promover';

  @override
  String get promoteSubtitle => 'Aumente sua visibilidade com GreenGoCoins';

  @override
  String get promoteBusinessOption => 'Promover negócio';

  @override
  String get promoteBusinessDesc => 'Destaque sua vitrine no topo do Explorar';

  @override
  String get promoteEventsOption => 'Promover um evento';

  @override
  String get promoteEventsDesc => 'Destaque um dos seus eventos na descoberta';

  @override
  String get promoteChooseDuration => 'Escolha uma duração';

  @override
  String get promoteNotActive => 'Sem promoção ativa';

  @override
  String get promoteConfirmTitle => 'Confirmar promoção';

  @override
  String get promoteConfirmCta => 'Promover';

  @override
  String get promoteCancel => 'Cancelar';

  @override
  String get promoteSelectEvent => 'Selecione um evento para destacar';

  @override
  String get promoteNoEvents => 'Você não tem eventos futuros para destacar';

  @override
  String get promoteEventAlreadyFeatured => 'Já em destaque';

  @override
  String get promoteSuccess => 'Promoção ativa!';

  @override
  String get promoteError => 'Algo deu errado. Tente novamente.';

  @override
  String get promoteInsufficientCoins => 'Moedas insuficientes';

  @override
  String get promoteInsufficientCoinsBody =>
      'Você não tem moedas suficientes para esta promoção. Recarregue para continuar.';

  @override
  String get promoteGetCoins => 'Obter moedas';

  @override
  String promoteDurationDays(int days) {
    return '$days dias';
  }

  @override
  String promoteCostLabel(int cost) {
    return '$cost moedas';
  }

  @override
  String promoteActiveUntil(String date) {
    return 'Promovido até $date';
  }

  @override
  String promoteBusinessConfirm(int days, int cost) {
    return 'Promover seu negócio por $days dias por $cost moedas?';
  }

  @override
  String promoteEventConfirm(int days, int cost) {
    return 'Destacar este evento por $days dias por $cost moedas?';
  }

  @override
  String get audienceSectionTitle => 'Insights do público';

  @override
  String get audiencePrivacyNote =>
      'Agregado e anonimizado — grupos pequenos são ocultados para proteger a privacidade.';

  @override
  String get audienceNotEnoughData =>
      'Ainda não há dados suficientes para mostrar isso protegendo a privacidade.';

  @override
  String get audienceAgeTitle => 'Distribuição por idade';

  @override
  String get audienceCountriesTitle => 'Principais países';

  @override
  String get audienceInterestsTitle => 'Principais interesses';

  @override
  String get eventAnalyticsTitle => 'Análises do evento';

  @override
  String get eventAnalyticsGoing => 'Confirmados';

  @override
  String get eventAnalyticsWaitlist => 'Lista de espera';

  @override
  String get eventAnalyticsCheckedIn => 'Check-in feito';

  @override
  String get eventAnalyticsCheckInRate => 'Taxa de check-in';

  @override
  String get eventAnalyticsTierBreakdown => 'Tipos de ingresso';

  @override
  String get businessEventsTitle => 'Gerenciar meus eventos';

  @override
  String get businessEventsEmpty => 'Você ainda não criou nenhum evento.';

  @override
  String get businessEventsAnalytics => 'Análises';

  @override
  String get businessEventsCancelTitle => 'Cancelar evento';

  @override
  String get businessEventsCancelMessage =>
      'Cancelar este evento? Os participantes serão notificados e ele será removido.';

  @override
  String get businessEventsCancelSeriesMessage =>
      'Cancelar todas as ocorrências desta série recorrente?';

  @override
  String get businessEventsCancelConfirm => 'Cancelar evento';

  @override
  String get businessEventsCancelled => 'Evento cancelado';

  @override
  String get businessPausedTitle => 'Negócio pausado';

  @override
  String get businessPausedSubtitle =>
      'Os recursos de negócio estão pausados porque sua assinatura Platinum expirou. Renove o Platinum para restaurar sua vitrine, análises, leads e promoções.';

  @override
  String get businessReactivate => 'Renovar Platinum';

  @override
  String get eventsBoostChooseDuration => 'Escolha a duração do impulso';

  @override
  String eventsBoostHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String eventsBoostWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String eventBoostEndsIn(String time) {
    return 'O impulso termina em $time';
  }

  @override
  String get eventBoostEnded => 'Impulso terminado';

  @override
  String get eventsBuyCoins => 'Comprar moedas';

  @override
  String get eventsBuyCoinsPrompt =>
      'Você não tem moedas suficientes. Deseja comprar mais?';

  @override
  String get messageTooLong => 'As mensagens podem ter até 4096 caracteres.';

  @override
  String get exploreBusinessesNearYou => 'Negócios perto de você';

  @override
  String get splashBusinessLabel => 'BUSINESS';

  @override
  String get rateThisBusiness => 'Avalie este negócio';

  @override
  String get businessRatingError =>
      'Não foi possível salvar sua avaliação. Tente novamente.';

  @override
  String businessRatingCount(int count) {
    return '($count)';
  }

  @override
  String rateStarsSemantic(int stars) {
    return 'Avaliar com $stars estrelas';
  }

  @override
  String businessRatingSemantic(String avg, int count) {
    return 'Avaliado $avg de 5, $count avaliações';
  }

  @override
  String get editStorefront => 'Editar vitrine';

  @override
  String get editStorefrontSubtitle =>
      'Gerencie sua galeria, horários, links e informações';

  @override
  String get storefrontGallerySubtitle =>
      'Mostre seu espaço, produtos ou equipe';

  @override
  String get storefrontOpeningHoursSubtitle =>
      'Defina seus dias e horários de funcionamento';

  @override
  String get storefrontDescriptionHint => 'Conte às pessoas sobre seu negócio';

  @override
  String get storefrontCategoryHint => 'ex. Restaurante, Café, Museu';

  @override
  String get storefrontLinkHint => 'https://...';

  @override
  String get storefrontAddLink => 'Adicionar link';

  @override
  String get storefrontAddImage => 'Adicionar imagem';

  @override
  String get storefrontSaved => 'Vitrine atualizada';

  @override
  String get analyticsEventViews => 'Visualizações do evento';

  @override
  String get analyticsCommunityReach => 'Alcance na comunidade';

  @override
  String get analyticsChatsInvolved => 'Conversas envolvidas';

  @override
  String get eventAnalyticsViews => 'Visualizações';

  @override
  String get businessHubScanner => 'Leitor rápido';

  @override
  String get businessHubScannerSubtitle =>
      'Escaneie ingressos para fazer o check-in dos participantes';

  @override
  String get businessHubFollowers => 'Seguidores';

  @override
  String get businessHubFollowersSubtitle => 'Veja quem segue seu negócio';

  @override
  String get businessFollowersTitle => 'Seguidores';

  @override
  String get businessNoFollowers =>
      'Ainda sem seguidores. Compartilhe sua vitrine para aumentar seu público.';

  @override
  String get membershipRequiredTitle => 'Assinatura necessária';

  @override
  String get membershipRequiredBody =>
      'Você precisa de uma assinatura ativa para fazer isto. Renove para continuar.';

  @override
  String get renewMembership => 'Renovar assinatura';

  @override
  String get extraEventTitle => 'Evento extra';

  @override
  String extraEventBody(int cost) {
    return 'Você atingiu seu limite de eventos gratuitos. Criar um evento extra por $cost moedas?';
  }

  @override
  String get accountBannedTitle => 'Conta banida permanentemente';

  @override
  String get accountBannedBody =>
      'Esta conta foi banida permanentemente por violar nossa política de conteúdo. Esta decisão é final.';

  @override
  String get adminBanPermanently => 'Banir permanentemente';

  @override
  String get adminBanConfirm => 'Banir esta conta permanentemente?';

  @override
  String get adminBanConfirmBody =>
      'Isto bane permanentemente a conta e bloqueia todo o acesso. Não pode ser desfeito.';

  @override
  String get adminBanReasonHint => 'Motivo (ex. nudez na galeria)';

  @override
  String get adminBanned => 'Conta banida permanentemente';
}
