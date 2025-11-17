// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubra o Seu Par Perfeito';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registar';

  @override
  String get email => 'Email';

  @override
  String get password => 'Palavra-passe';

  @override
  String get confirmPassword => 'Confirmar Palavra-passe';

  @override
  String get forgotPassword => 'Esqueceu a Palavra-passe?';

  @override
  String get resetPassword => 'Redefinir Palavra-passe';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get signUp => 'Inscrever-se';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get continueWithFacebook => 'Continuar com Facebook';

  @override
  String get orContinueWith => 'Ou continue com';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get joinMessage =>
      'Junte-se ao GreenGoChat e encontre o seu par perfeito';

  @override
  String get emailRequired => 'Email é obrigatório';

  @override
  String get emailInvalid => 'Por favor introduza um email válido';

  @override
  String get passwordRequired => 'Palavra-passe é obrigatória';

  @override
  String get passwordTooShort =>
      'A palavra-passe deve ter pelo menos 8 caracteres';

  @override
  String get passwordWeak =>
      'A palavra-passe deve conter maiúsculas, minúsculas, números e caracteres especiais';

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não coincidem';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get completeProfile => 'Complete o Seu Perfil';

  @override
  String get firstName => 'Primeiro Nome';

  @override
  String get lastName => 'Apelido';

  @override
  String get dateOfBirth => 'Data de Nascimento';

  @override
  String get gender => 'Género';

  @override
  String get bio => 'Biografia';

  @override
  String get interests => 'Interesses';

  @override
  String get photos => 'Fotos';

  @override
  String get addPhoto => 'Adicionar Foto';

  @override
  String get uploadPhoto => 'Carregar Foto';

  @override
  String get takePhoto => 'Tirar Foto';

  @override
  String get chooseFromGallery => 'Escolher da Galeria';

  @override
  String get location => 'Localização';

  @override
  String get language => 'Idioma';

  @override
  String get voiceIntro => 'Apresentação de Voz';

  @override
  String get recordVoice => 'Gravar Voz';

  @override
  String get welcome => 'Bem-vindo ao GreenGoChat';

  @override
  String get getStarted => 'Começar';

  @override
  String get next => 'Seguinte';

  @override
  String get skip => 'Saltar';

  @override
  String get finish => 'Terminar';

  @override
  String get step => 'Passo';

  @override
  String get stepOf => 'de';

  @override
  String get discover => 'Descobrir';

  @override
  String get matches => 'Correspondências';

  @override
  String get likes => 'Gostos';

  @override
  String get superLikes => 'Super Gostos';

  @override
  String get filters => 'Filtros';

  @override
  String get ageRange => 'Faixa Etária';

  @override
  String get distance => 'Distância';

  @override
  String get noMoreProfiles => 'Não há mais perfis para mostrar';

  @override
  String get itsAMatch => 'É uma Correspondência!';

  @override
  String youAndMatched(String name) {
    return 'Você e $name gostaram um do outro';
  }

  @override
  String get sendMessage => 'Enviar Mensagem';

  @override
  String get keepSwiping => 'Continuar a Deslizar';

  @override
  String get messages => 'Mensagens';

  @override
  String get typeMessage => 'Escreva uma mensagem...';

  @override
  String get noMessages => 'Ainda sem mensagens';

  @override
  String get startConversation => 'Iniciar uma conversação';

  @override
  String get settings => 'Definições';

  @override
  String get accountSettings => 'Definições da Conta';

  @override
  String get notificationSettings => 'Definições de Notificações';

  @override
  String get privacySettings => 'Definições de Privacidade';

  @override
  String get deleteAccount => 'Eliminar Conta';

  @override
  String get logout => 'Sair';

  @override
  String get upgradeToPremium => 'Atualizar para Premium';

  @override
  String get basic => 'Básico';

  @override
  String get silver => 'Prata';

  @override
  String get gold => 'Ouro';

  @override
  String get subscribe => 'Subscrever';

  @override
  String get perMonth => '/mês';

  @override
  String get somethingWentWrong => 'Algo correu mal';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noInternetConnection => 'Sem ligação à internet';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

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
  String get done => 'Concluído';

  @override
  String get loading => 'A carregar...';

  @override
  String get ok => 'OK';

  @override
  String get selectLanguage => 'Selecionar Idioma';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => 'GreenGoChat';

  @override
  String get appTagline => 'Descubra Seu Par Perfeito';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Cadastrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get forgotPassword => 'Esqueceu a Senha?';

  @override
  String get resetPassword => 'Redefinir Senha';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get signUp => 'Cadastre-se';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get continueWithFacebook => 'Continuar com Facebook';

  @override
  String get orContinueWith => 'Ou continue com';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get joinMessage =>
      'Junte-se ao GreenGoChat e encontre seu par perfeito';

  @override
  String get emailRequired => 'E-mail é obrigatório';

  @override
  String get emailInvalid => 'Por favor insira um e-mail válido';

  @override
  String get passwordRequired => 'Senha é obrigatória';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get passwordWeak =>
      'A senha deve conter maiúsculas, minúsculas, números e caracteres especiais';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get completeProfile => 'Complete Seu Perfil';

  @override
  String get firstName => 'Primeiro Nome';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get dateOfBirth => 'Data de Nascimento';

  @override
  String get gender => 'Gênero';

  @override
  String get bio => 'Biografia';

  @override
  String get interests => 'Interesses';

  @override
  String get photos => 'Fotos';

  @override
  String get addPhoto => 'Adicionar Foto';

  @override
  String get uploadPhoto => 'Fazer Upload de Foto';

  @override
  String get takePhoto => 'Tirar Foto';

  @override
  String get chooseFromGallery => 'Escolher da Galeria';

  @override
  String get location => 'Localização';

  @override
  String get language => 'Idioma';

  @override
  String get voiceIntro => 'Apresentação de Voz';

  @override
  String get recordVoice => 'Gravar Voz';

  @override
  String get welcome => 'Bem-vindo ao GreenGoChat';

  @override
  String get getStarted => 'Começar';

  @override
  String get next => 'Próximo';

  @override
  String get skip => 'Pular';

  @override
  String get finish => 'Finalizar';

  @override
  String get step => 'Passo';

  @override
  String get stepOf => 'de';

  @override
  String get discover => 'Descobrir';

  @override
  String get matches => 'Combinações';

  @override
  String get likes => 'Curtidas';

  @override
  String get superLikes => 'Super Curtidas';

  @override
  String get filters => 'Filtros';

  @override
  String get ageRange => 'Faixa Etária';

  @override
  String get distance => 'Distância';

  @override
  String get noMoreProfiles => 'Não há mais perfis para mostrar';

  @override
  String get itsAMatch => 'É uma Combinação!';

  @override
  String youAndMatched(String name) {
    return 'Você e $name curtiram um ao outro';
  }

  @override
  String get sendMessage => 'Enviar Mensagem';

  @override
  String get keepSwiping => 'Continuar Deslizando';

  @override
  String get messages => 'Mensagens';

  @override
  String get typeMessage => 'Digite uma mensagem...';

  @override
  String get noMessages => 'Ainda sem mensagens';

  @override
  String get startConversation => 'Iniciar uma conversa';

  @override
  String get settings => 'Configurações';

  @override
  String get accountSettings => 'Configurações da Conta';

  @override
  String get notificationSettings => 'Configurações de Notificações';

  @override
  String get privacySettings => 'Configurações de Privacidade';

  @override
  String get deleteAccount => 'Excluir Conta';

  @override
  String get logout => 'Sair';

  @override
  String get upgradeToPremium => 'Atualizar para Premium';

  @override
  String get basic => 'Básico';

  @override
  String get silver => 'Prata';

  @override
  String get gold => 'Ouro';

  @override
  String get subscribe => 'Assinar';

  @override
  String get perMonth => '/mês';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noInternetConnection => 'Sem conexão com a internet';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Concluído';

  @override
  String get loading => 'Carregando...';

  @override
  String get ok => 'OK';

  @override
  String get selectLanguage => 'Selecionar Idioma';
}
