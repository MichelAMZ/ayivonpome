// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'FamilyTreeApp';

  @override
  String get applicationTitle => 'Nome do aplicativo';

  @override
  String get applicationSubtitle => 'Subtítulo';

  @override
  String get showApplicationSubtitle => 'Mostrar subtítulo';

  @override
  String get editApplicationTitle => 'Editar título do aplicativo';

  @override
  String get applicationSettings => 'Configurações do aplicativo';

  @override
  String get officialFamilyName => 'Nome oficial da família';

  @override
  String get treeInitialZoom => 'Zoom inicial da árvore';

  @override
  String get rememberLastZoom => 'Memorizar o último zoom';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
      zero: '0 membros',
    );
    return '$_temp0';
  }

  @override
  String totalMembers(int count) {
    return 'Total: $count';
  }

  @override
  String get showMembersCounter => 'Mostrar contador na barra inferior';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get help => 'Ajuda';

  @override
  String get helpAndTutorial => 'Ajuda e tutorial';

  @override
  String get showTutorial => 'Mostrar botão de tutorial';

  @override
  String get hideTutorial => 'Ocultar tutorial';

  @override
  String get nextStep => 'Seguinte';

  @override
  String get previousStep => 'Anterior';

  @override
  String get finishTutorial => 'Concluir';

  @override
  String get skipTutorial => 'Ignorar';

  @override
  String get firstLaunchTutorial => 'Mostrar tutorial no primeiro arranque';

  @override
  String get treeLegend => 'Legenda';

  @override
  String get howToUse => 'Como usar a árvore';

  @override
  String get tutorialWelcomeTitle => 'Bem-vindo à árvore genealógica';

  @override
  String get tutorialMoveTitle => 'Deslocamento';

  @override
  String get tutorialMoveBody => 'Clique e arraste para mover a árvore.';

  @override
  String get tutorialZoomTitle => 'Zoom';

  @override
  String get tutorialZoomBody =>
      'Use os botões + e -. Ctrl + roda também permite ampliar.';

  @override
  String get tutorialInfoTitle => 'Informações';

  @override
  String get tutorialInfoBody =>
      'Passe o cursor sobre uma pessoa para ver as informações.';

  @override
  String get tutorialContextMenuTitle => 'Menu contextual';

  @override
  String get tutorialContextMenuBody =>
      'Clique com o botão direito numa pessoa para adicionar, editar, imprimir um ramo ou ver o histórico.';

  @override
  String get tutorialAccessCodesTitle => 'Códigos de acesso';

  @override
  String get tutorialAccessCodesBody =>
      'Algumas ações exigem um código de modificação.';

  @override
  String get tutorialMapTitle => 'Mapa';

  @override
  String get tutorialMapBody =>
      'Clique no ícone de localização para abrir o Google Maps.';

  @override
  String get tutorialNotificationsTitle => 'Notificações';

  @override
  String get tutorialNotificationsBody =>
      'As novas alterações aparecem automaticamente.';

  @override
  String get married => 'Casado(a)';

  @override
  String get knownPlace => 'Local conhecido';

  @override
  String get loginTitle => 'Entrada familiar';

  @override
  String get chooseLanguage => 'Escolher idioma';

  @override
  String get autoLanguage => 'Idioma automático';

  @override
  String get detectedLanguage => 'Idioma detectado';

  @override
  String get french => 'Francês';

  @override
  String get english => 'Inglês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get portuguese => 'Português';

  @override
  String get german => 'Alemão';

  @override
  String get familyCode => 'Código familiar';

  @override
  String get enter => 'Entrar';

  @override
  String get invalidCode => 'Código inválido';

  @override
  String get dashboardTitle => 'Painel';

  @override
  String get addPerson => 'Adicionar pessoa';

  @override
  String get importJson => 'Importar JSON';

  @override
  String get exportJson => 'Exportar JSON';

  @override
  String get familyTree => 'Árvore';

  @override
  String get personDetails => 'Ficha da pessoa';

  @override
  String get birthDate => 'Data de nascimento';

  @override
  String get birthPlace => 'Local de nascimento';

  @override
  String get deathDate => 'Data de falecimento';

  @override
  String get deathPlace => 'Local de falecimento';

  @override
  String get parents => 'Pais';

  @override
  String get spouses => 'Cônjuges';

  @override
  String get children => 'Filhos';

  @override
  String get directChildren => 'Filhos diretos';

  @override
  String get totalDescendants => 'Descendentes totais';

  @override
  String get descendants => 'Descendentes';

  @override
  String get childrenCount => 'Número de filhos';

  @override
  String get familyHistory => 'Histórico familiar';

  @override
  String get ourHistory => 'Nossa história';

  @override
  String get historyOfFamily => 'História da família';

  @override
  String get generalFamilyHistory => 'Histórico geral da família';

  @override
  String get viewFamilyHistory => 'Ver a história geral da família';

  @override
  String get editFamilyHistory => 'Editar histórico familiar';

  @override
  String get linkedFamilyHistory => 'Histórico da família ligada';

  @override
  String get historyContent => 'Conteúdo da história';

  @override
  String get historyTitle => 'Título da história';

  @override
  String get characterLimit => 'Limite de caracteres';

  @override
  String get charactersRemaining => 'Caracteres restantes';

  @override
  String get characterLimitExceeded => 'O limite de caracteres foi excedido.';

  @override
  String get lastUpdatedBy => 'Última alteração por';

  @override
  String get lastUpdatedAt => 'Última alteração em';

  @override
  String get familyCouncil => 'Conselho familiar';

  @override
  String get councilMembers => 'Membros do conselho';

  @override
  String get councilMember => 'Membro do conselho';

  @override
  String get roleInCouncil => 'Função no conselho';

  @override
  String get residencePlace => 'Local de residência';

  @override
  String get contactCouncilMember => 'Contactar membro do conselho';

  @override
  String get viewCouncilMembers => 'Ver membros do conselho familiar';

  @override
  String get addCouncilMember => 'Adicionar membro';

  @override
  String get editCouncilMember => 'Editar membro';

  @override
  String get deleteCouncilMember => 'Excluir membro';

  @override
  String get councilDescription => 'Membros que acompanham o chefe da família.';

  @override
  String get chiefCouncil => 'Conselho do chefe';

  @override
  String get infoNews => 'Informação';

  @override
  String get infoNewsManagement => 'Informações / Notícias';

  @override
  String get addInfoNews => 'Adicionar informação';

  @override
  String get editInfoNews => 'Editar informação';

  @override
  String get deleteInfoNews => 'Excluir informação';

  @override
  String get infoNewsTitle => 'Título da informação';

  @override
  String get infoNewsMessage => 'Mensagem curta';

  @override
  String get infoNewsActive => 'Informação ativa';

  @override
  String get priority => 'Prioridade';

  @override
  String get startAt => 'Início da exibição';

  @override
  String get endAt => 'Fim da exibição';

  @override
  String get sendToContacts => 'Enviar aos contatos disponíveis';

  @override
  String get sendViaWhatsApp => 'Enviar via WhatsApp';

  @override
  String get infoNewsSendLog => 'Histórico de envios';

  @override
  String get whatsappManualNotice =>
      'O WhatsApp será aberto com uma mensagem preenchida. O admin deve confirmar o envio.';

  @override
  String get freeWhatsAppQueue =>
      'Fila de envio gratuita: o WhatsApp abre com uma mensagem preenchida e o admin confirma manualmente.';

  @override
  String get copyMessage => 'Copiar mensagem';

  @override
  String get markAsSent => 'Marcar como enviado';

  @override
  String get skipContact => 'Ignorar este contato';

  @override
  String get nextContact => 'Próximo';

  @override
  String get messageCopied => 'Mensagem copiada';

  @override
  String get whatsappOpened => 'WhatsApp aberto';

  @override
  String get sent => 'Enviado';

  @override
  String get failed => 'Falhou';

  @override
  String get skipped => 'Ignorado';

  @override
  String get historyCleanupNotice =>
      'Históricos com mais de 3 meses são excluídos automaticamente.';

  @override
  String get autoHistoryCleanup => 'Limpeza automática de históricos';

  @override
  String get deleteOldHistoriesNow => 'Excluir históricos antigos agora';

  @override
  String get confirmDeleteOldHistories =>
      'Deseja excluir agora os históricos de envio com mais de 3 meses?';

  @override
  String get historiesKept => 'Históricos conservados';

  @override
  String get lastCleanup => 'Última limpeza';

  @override
  String get autoCleanupNotifications =>
      'Limpeza automática das notificações após 1 semana';

  @override
  String get autoCleanupKpiActivityLogs =>
      'Limpeza automática do registro KPI após 3 meses';

  @override
  String get deletedItems => 'Itens excluídos';

  @override
  String get cleanNow => 'Limpar agora';

  @override
  String get confirmDataCleanup =>
      'Deseja limpar agora as notificações antigas e o registro KPI antigo?';

  @override
  String get notificationAdminOnly =>
      'Somente administradores podem enviar notificações.';

  @override
  String get history => 'Histórico';

  @override
  String get notes => 'Notas';

  @override
  String get linkedFamilies => 'Famílias ligadas';

  @override
  String get addFamilyCode => 'Adicionar código familiar';

  @override
  String get requestFamilyLink => 'Solicitar ligação familiar';

  @override
  String get pending => 'Pendente';

  @override
  String get accepted => 'Aceito';

  @override
  String get refused => 'Recusado';

  @override
  String get viewer => 'Leitor';

  @override
  String get editor => 'Editor';

  @override
  String get owner => 'Proprietário';

  @override
  String get preview => 'Prévia';

  @override
  String get viewFullProfile => 'Ver ficha completa';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get search => 'Pesquisar';

  @override
  String get familyLinks => 'Ligações familiares';

  @override
  String get relationshipType => 'Tipo de ligação';

  @override
  String get marriage => 'Casamento';

  @override
  String get parent => 'Pai/Mãe';

  @override
  String get child => 'Filho';

  @override
  String get adoption => 'Adoção';

  @override
  String get alliance => 'Aliança';

  @override
  String get commonAncestor => 'Ancestral comum';

  @override
  String get other => 'Outro';

  @override
  String get backupCreated => 'Backup de segurança criado';

  @override
  String get importError => 'Erro de importação';

  @override
  String get exportSuccess => 'Exportação concluída';

  @override
  String get people => 'Pessoas';

  @override
  String get familiesCount => 'Famílias ligadas';

  @override
  String get pendingCount => 'Pedidos pendentes';

  @override
  String get totalPeople => 'Total de pessoas';

  @override
  String get emptyState => 'Nenhum dado para exibir';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get bornLastName => 'Sobrenome de nascimento';

  @override
  String get bornAs => 'Nascido(a) como';

  @override
  String get nee => 'nascida';

  @override
  String get gender => 'Sexo';

  @override
  String get photo => 'Foto';

  @override
  String get familyBranch => 'Família ou ramo';

  @override
  String get edit => 'Editar';

  @override
  String get details => 'Detalhes';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get confirmOverwrite => 'Substituir os dados atuais?';

  @override
  String get merge => 'Mesclar';

  @override
  String get replace => 'Substituir';

  @override
  String get create => 'Criar';

  @override
  String get status => 'Estado';

  @override
  String get role => 'Função';

  @override
  String get sourcePerson => 'Pessoa de origem';

  @override
  String get targetPerson => 'Pessoa de destino';

  @override
  String get note => 'Nota';

  @override
  String get accept => 'Aceitar';

  @override
  String get refuse => 'Recusar';

  @override
  String get storage => 'Armazenamento';

  @override
  String get readOnly => 'Somente leitura';

  @override
  String get duplicatePerson => 'Possível duplicado detectado';

  @override
  String get requiredField => 'Campo obrigatório';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get currentAddress => 'Endereço atual';

  @override
  String get locationFilter => 'Filtro de localização';

  @override
  String get filterByLocation => 'Filtrar por localização';

  @override
  String get country => 'País';

  @override
  String get city => 'Cidade';

  @override
  String get region => 'Região / prefeitura / departamento';

  @override
  String get birthLocation => 'Local de nascimento';

  @override
  String get deathLocation => 'Local de falecimento';

  @override
  String get burialLocation => 'Local de sepultamento';

  @override
  String get radiusAroundAddress => 'Raio ao redor de um endereço';

  @override
  String membersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros encontrados',
      one: '1 membro encontrado',
      zero: '0 membros encontrados',
    );
    return '$_temp0';
  }

  @override
  String get showOnlyResults => 'Mostrar apenas resultados';

  @override
  String get highlightResults => 'Destacar resultados';

  @override
  String get clearFilters => 'Redefinir filtros';

  @override
  String get centerOnPerson => 'Centrar na pessoa';

  @override
  String get burialPlace => 'Local de sepultamento';

  @override
  String get importantPlaces => 'Lugares importantes';

  @override
  String get viewOnMap => 'Ver no mapa';

  @override
  String get copyAddress => 'Copiar endereço';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get contact => 'Contato';

  @override
  String get sendEmail => 'Enviar email';

  @override
  String get sendWhatsapp => 'WhatsApp';

  @override
  String get call => 'Ligar';

  @override
  String get copyEmail => 'Copiar email';

  @override
  String get copyPhone => 'Copiar telefone';

  @override
  String get contactDisabled => 'Contato desativado';

  @override
  String get noContactInformation => 'Nenhum contato disponível';

  @override
  String get emailCopied => 'Email copiado';

  @override
  String get phoneCopied => 'Telefone copiado';

  @override
  String get openWhatsapp => 'Abrir WhatsApp';

  @override
  String get communication => 'Comunicação';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Telefone';

  @override
  String get whatsappNumber => 'Número WhatsApp';

  @override
  String get public => 'Público';

  @override
  String get familyOnly => 'Somente família';

  @override
  String get private => 'Privado';

  @override
  String get familyEmailSubject => 'Olá da família';

  @override
  String get familyEmailBody =>
      'Olá,\n\nEstou entrando em contato pelo FamilyTreeApp.\n\nAtenciosamente.';

  @override
  String get familyWhatsappMessage => 'Olá pelo FamilyTreeApp';

  @override
  String get notifications => 'Notificações';

  @override
  String get notifyPerson => 'Notificar esta pessoa';

  @override
  String get sendNotification => 'Enviar notificação';

  @override
  String get notificationChannel => 'Canal de notificação';

  @override
  String get localNotification => 'Lembrete local';

  @override
  String get emailNotification => 'Email';

  @override
  String get whatsappNotification => 'WhatsApp';

  @override
  String get scheduleReminder => 'Agendar lembrete';

  @override
  String get customMessage => 'Mensagem personalizada';

  @override
  String get birthdayReminder => 'Lembrete de aniversário';

  @override
  String get deathAnniversaryReminder => 'Lembrete de falecimento';

  @override
  String get familyMeetingReminder => 'Reunião familiar';

  @override
  String get linkRequestReminder => 'Pedido de ligação familiar';

  @override
  String get notificationSent => 'Notificação preparada';

  @override
  String get notificationFailed => 'Falha na notificação';

  @override
  String get notificationScheduled => 'Lembrete agendado';

  @override
  String get notificationPermissionRequired =>
      'Permissão de notificação necessária';

  @override
  String get futurePushNotification => 'Push futuro';

  @override
  String get noBackendPushNotice =>
      'Notificações push remotas reais exigem backend. Esta versão local prepara email/WhatsApp e agenda lembretes locais.';

  @override
  String get notificationExternalAppNotice =>
      'Email e WhatsApp abrem um aplicativo externo após confirmação.';

  @override
  String get copy => 'Copiar';

  @override
  String get enterAccessCode => 'Inserir código de acesso';

  @override
  String get logout => 'Sair';

  @override
  String get publicLimitedMode => 'Modo público limitado';

  @override
  String get publicLimitedModeDescription =>
      'Insira o código de acesso para ver as informações privadas da família.';

  @override
  String get publicMode => 'Modo público';

  @override
  String get publicMapLocation => 'Local público no mapa';

  @override
  String get showMapInPublicMode => 'Mostrar mapa no modo público';

  @override
  String get showBirthPlaceInPublicMode =>
      'Permitir local de nascimento público';

  @override
  String get showCurrentAddressInPublicMode =>
      'Permitir endereço atual público';

  @override
  String get showContactInPublicMode => 'Permitir contato público';

  @override
  String get showHistoryInPublicMode => 'Permitir histórico público';

  @override
  String get totalMembersTitle => 'Total de membros';

  @override
  String get visiblePeopleCount => 'pessoas visíveis';

  @override
  String get adminDashboard => 'Admin familiar';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get admin => 'Admin';

  @override
  String get modificationCode => 'Código de modificação';

  @override
  String get enterModificationCode => 'Inserir código de modificação';

  @override
  String get modificationCodeRequired => 'Código de modificação necessário';

  @override
  String get modificationCodeRequiredMessage =>
      'Para adicionar ou modificar uma pessoa, você precisa obter um código de modificação com um administrador familiar.';

  @override
  String get invalidModificationCode => 'Código de modificação inválido';

  @override
  String get validModificationCode => 'Código de modificação aceito';

  @override
  String get contactAdmin => 'Contatar admin';

  @override
  String get contactAdmins => 'Contatar admins';

  @override
  String get adminContactMessage =>
      'Olá, gostaria de obter um código de modificação para FamilyTreeApp.';

  @override
  String get manageAdmins => 'Gerenciar admins';

  @override
  String get manageModificationCodes => 'Gerenciar códigos de modificação';

  @override
  String get activeCodes => 'Códigos ativos';

  @override
  String get expiredCodes => 'Códigos expirados';

  @override
  String get usedCodes => 'Códigos usados';

  @override
  String get adminKpi => 'KPI Admin';

  @override
  String get activityLog => 'Registro de atividade';

  @override
  String get codeCreated => 'Código criado';

  @override
  String get codeDisabled => 'Código desativado';

  @override
  String get personAddedThisMonth => 'Pessoas adicionadas este mês';

  @override
  String get personModifiedThisMonth => 'Pessoas modificadas este mês';

  @override
  String get familyRelationships => 'Relações familiares';

  @override
  String get father => 'Pai';

  @override
  String get mother => 'Mãe';

  @override
  String get marriedTo => 'Casado(a) com';

  @override
  String get spouse => 'Cônjuge';

  @override
  String get husband => 'Marido';

  @override
  String get wife => 'Esposa';

  @override
  String get wives => 'Esposas';

  @override
  String get siblings => 'Irmãos';

  @override
  String get male => 'Homem';

  @override
  String get female => 'Mulher';

  @override
  String get unknownGender => 'Não informado';

  @override
  String get polygamy => 'Poligamia';

  @override
  String get monogamy => 'Monogamia';

  @override
  String get customaryMarriage => 'Casamento costumeiro';

  @override
  String get civilMarriage => 'Casamento civil';

  @override
  String get religiousMarriage => 'Casamento religioso';

  @override
  String get marriageType => 'Tipo de casamento';

  @override
  String get marriageStatus => 'Estado do casamento';

  @override
  String get maritalStatus => 'Estado civil';

  @override
  String get activeMarriage => 'Casamento ativo';

  @override
  String get separated => 'Separado';

  @override
  String get divorced => 'Divorciado';

  @override
  String get divorce => 'Divórcio';

  @override
  String get declareDivorce => 'Declarar divórcio';

  @override
  String get divorceDate => 'Data do divórcio';

  @override
  String get formerSpouse => 'Ex-cônjuge';

  @override
  String get formerSpouses => 'Ex-cônjuges';

  @override
  String get restoreMarriage => 'Restaurar casamento';

  @override
  String get divorceHistory => 'Histórico matrimonial';

  @override
  String get widowed => 'Viúvo(a)';

  @override
  String get invalidRelationship =>
      'Relação incoerente: uma pessoa não pode ser seu próprio pai, cônjuge ou filho.';

  @override
  String get addFather => 'Adicionar pai';

  @override
  String get addMother => 'Adicionar mãe';

  @override
  String get addParents => 'Adicionar pais';

  @override
  String get addChild => 'Adicionar filho';

  @override
  String get addChildren => 'Adicionar vários filhos';

  @override
  String get addSibling => 'Adicionar irmão/irmã';

  @override
  String get addBrother => 'Adicionar irmão';

  @override
  String get addSister => 'Adicionar irmã';

  @override
  String get addSpouse => 'Adicionar cônjuge';

  @override
  String get linkExistingPerson => 'Ligar pessoa existente';

  @override
  String get viewProfile => 'Ver ficha';

  @override
  String get editPerson => 'Editar pessoa';

  @override
  String get deletePerson => 'Excluir pessoa';

  @override
  String get addHistoricalEvent => 'Adicionar evento histórico';

  @override
  String get sendMessage => 'Enviar mensagem';

  @override
  String get copyInformation => 'Copiar informações';

  @override
  String get latestChanges => 'Últimas alterações';

  @override
  String get newPeopleAdded => 'Novas pessoas adicionadas';

  @override
  String get newModifications => 'Novas modificações';

  @override
  String get modifiedBy => 'Modificado por';

  @override
  String get addedBy => 'Adicionado por';

  @override
  String get updatedBy => 'Atualizado por';

  @override
  String get deletedBy => 'Excluído por';

  @override
  String get viewHistory => 'Ver histórico';

  @override
  String get markAsSeen => 'Já vi';

  @override
  String get doNotShowAgain => 'Não mostrar novamente';

  @override
  String get modificationHistory => 'Histórico de modificações';

  @override
  String get personAdded => 'Pessoa adicionada';

  @override
  String get personUpdated => 'Pessoa modificada';

  @override
  String get personDeleted => 'Pessoa excluída';

  @override
  String get relationshipAdded => 'Relação familiar adicionada';

  @override
  String get historyRetention => 'Retenção do histórico';

  @override
  String get historyDeletedAfterThreeMonths =>
      'Histórico excluído após três meses';

  @override
  String get adminAccessCode => 'Código admin';

  @override
  String get enterAdminCode => 'Inserir código admin';

  @override
  String get invalidAdminCode => 'Código admin inválido';

  @override
  String get forgotCode => 'Esqueceu o código?';

  @override
  String get superAdminRecovery => 'Redefinição Super Admin';

  @override
  String get enterSuperAdminRecoveryCode =>
      'Inserir o código secreto Super Admin';

  @override
  String get resetCodes => 'Redefinir códigos';

  @override
  String get resetAllCodes => 'Regenerar automaticamente todos os códigos';

  @override
  String get generateNewCodes => 'Criar novos códigos';

  @override
  String get recoveryCodeInvalid => 'Código secreto Super Admin inválido';

  @override
  String get recoveryCodeAccepted => 'Código secreto Super Admin aceito';

  @override
  String get codesResetSuccess => 'Códigos redefinidos com sucesso';

  @override
  String get confirmResetCodes =>
      'Confirmar a redefinição dos códigos? Uma cópia JSON será criada antes das alterações.';

  @override
  String get adminKpiAccess => 'Acesso Admin / KPI';

  @override
  String get adminSecurity => 'Segurança admin';

  @override
  String get changeAdminCode => 'Alterar código admin';

  @override
  String get currentAdminCode => 'Código admin atual';

  @override
  String get oldAdminCode => 'Código admin antigo';

  @override
  String get newAdminCode => 'Novo código admin';

  @override
  String get confirmNewAdminCode => 'Confirmar novo código';

  @override
  String get adminCodeChanged => 'Código admin alterado';

  @override
  String get adminCodeRotationDue => 'O código admin deve ser alterado';

  @override
  String get adminCodeRotationLate => 'Alteração do código admin atrasada';

  @override
  String get nextAdminCodeChange => 'Próxima alteração recomendada';

  @override
  String get lastAdminCodeChange => 'Última alteração';

  @override
  String get adminCodeHistory => 'Histórico de códigos admin';

  @override
  String get codeManagement => 'Gestão de códigos';

  @override
  String get accessCodes => 'Códigos de acesso';

  @override
  String get createAccessCode => 'Criar código';

  @override
  String get editAccessCode => 'Editar código';

  @override
  String get deleteAccessCode => 'Excluir código';

  @override
  String get disableAccessCode => 'Desativar código';

  @override
  String get enableAccessCode => 'Reativar código';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get showCode => 'Mostrar código';

  @override
  String get hideCode => 'Ocultar código';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get codeType => 'Tipo de código';

  @override
  String get codeRole => 'Função do código';

  @override
  String get codeStatus => 'Estado do código';

  @override
  String get codeExpiration => 'Expiração';

  @override
  String get codeUsage => 'Usos';

  @override
  String get createdBy => 'Criado por';

  @override
  String get lastUsedAt => 'Último uso';

  @override
  String get maxUses => 'Usos máximos';

  @override
  String get generateCode => 'Gerar código';

  @override
  String get manualCode => 'Código manual';

  @override
  String get familyAccessCode => 'Código de acesso familiar';

  @override
  String get adminKpiCode => 'Código Admin KPI';

  @override
  String get linkedFamilyCode => 'Código família ligada';

  @override
  String get temporaryCode => 'Código temporário';

  @override
  String get codeUpdated => 'Código atualizado';

  @override
  String get codeDeleted => 'Código excluído';

  @override
  String get codeEnabled => 'Código reativado';

  @override
  String get codeAlreadyExists => 'Este código já existe';

  @override
  String get regenerateCode => 'Regenerar';

  @override
  String get confirmRegenerateCode =>
      'Deseja regenerar este código? O código antigo será desativado.';

  @override
  String get codeRegenerated => 'Novo código gerado com sucesso.';

  @override
  String get newGeneratedCode => 'Novo código gerado';

  @override
  String get copyNewCode => 'Copiar novo código';

  @override
  String get oldCodeDisabled => 'O código antigo foi desativado.';

  @override
  String get previousCode => 'Código anterior';

  @override
  String get replacedByCode => 'Substituído pelo código';

  @override
  String get regeneratedAt => 'Regenerado em';

  @override
  String get familyHonor => 'Honra familiar';

  @override
  String get patriarch => 'Patriarca';

  @override
  String get patriarchBadge => 'Distintivo do patriarca';

  @override
  String get selectPatriarch => 'Selecionar patriarca';

  @override
  String get showPatriarchBadge => 'Mostrar distintivo do patriarca';

  @override
  String get badgePosition => 'Posição do distintivo';

  @override
  String get badgeStyle => 'Estilo do distintivo';

  @override
  String get viewPatriarchProfile => 'Ver ficha do patriarca';

  @override
  String get familyDistinctions => 'Distinções familiares';

  @override
  String get leader => 'Líder';

  @override
  String get currentLeader => 'Líder atual';

  @override
  String get familyLeader => 'Líder familiar';

  @override
  String get familyChief => 'Chefe de família';

  @override
  String get matriarch => 'Matriarca';

  @override
  String get viewLeaderProfile => 'Ver ficha do líder atual';

  @override
  String get chiefTitle => 'Título do líder';

  @override
  String get showLeaderInTopBar => 'Mostrar líder na TopBar';

  @override
  String get showLeaderBanner => 'Mostrar banner do chefe da família';

  @override
  String get showLeaderPhoto => 'Mostrar foto / avatar';

  @override
  String get topBarLogoMode => 'Modo do logo TopBar';

  @override
  String get classicLogo => 'Logo clássico';

  @override
  String get logoAndLeader => 'Logo + líder atual';

  @override
  String get leaderOnly => 'Somente líder atual';

  @override
  String get currentChief => 'Chefe atual';

  @override
  String get formerChief => 'Antigo chefe';

  @override
  String get successor => 'Sucessor designado';

  @override
  String get familyLeadership => 'Liderança familiar';

  @override
  String get leadershipHistory => 'Histórico dos chefes';

  @override
  String get familyHonorHall => 'Personalidades familiares';

  @override
  String get appointLeader => 'Nomear líder';

  @override
  String get removeLeader => 'Remover líder';

  @override
  String get chiefSince => 'Chefe desde';

  @override
  String get bugReports => 'Bugs reportados';

  @override
  String get reportBug => 'Reportar bug';

  @override
  String get bugTitle => 'Título do bug';

  @override
  String get bugDescription => 'Descrição';

  @override
  String get bugScreen => 'Tela afetada';

  @override
  String get bugPriority => 'Prioridade';

  @override
  String get bugStatus => 'Status do bug atualizado';

  @override
  String get reportedBy => 'Reportado por';

  @override
  String get reportedAt => 'Reportado em';

  @override
  String get notifyAdminsWhatsapp => 'Notificar admins pelo WhatsApp';

  @override
  String get bugOpen => 'Aberto';

  @override
  String get bugInProgress => 'Em andamento';

  @override
  String get bugResolved => 'Resolvido';

  @override
  String get bugDeleted => 'Excluído';

  @override
  String get deleteBugReport => 'Excluir relatório';

  @override
  String get confirmDeleteBugReport => 'Deseja excluir este relatório de bug?';

  @override
  String get bugReportCreated => 'Bug reportado.';

  @override
  String get adminWhatsappNotification =>
      'O WhatsApp será aberto com uma mensagem preenchida. Cada admin deverá confirmar o envio.';

  @override
  String get generation => 'Geração';

  @override
  String get generations => 'Gerações';

  @override
  String get generationNumber => 'Número da geração';

  @override
  String get rootAncestor => 'Ancestral raiz';

  @override
  String get firstAncestor => 'Primeiro ancestral';

  @override
  String get recalculateGenerations => 'Recalcular todas as gerações';

  @override
  String get showGenerationBadges => 'Mostrar badges de geração';

  @override
  String get allGenerations => 'Todas as gerações';

  @override
  String get storageMode => 'Modo de armazenamento';

  @override
  String get jsonOnly => 'Apenas JSON';

  @override
  String get databaseOnly => 'Apenas banco de dados';

  @override
  String get hybridStorage => 'Armazenamento híbrido';

  @override
  String get syncStatus => 'Status de sincronização';

  @override
  String get synced => 'Sincronizado';

  @override
  String get offline => 'Offline';

  @override
  String get syncPending => 'Sincronização pendente';

  @override
  String get syncInProgress => 'Sincronização em andamento';

  @override
  String get syncError => 'Erro de sincronização';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get lastSyncAt => 'Última sincronização';

  @override
  String get pendingOperations => 'Operações pendentes';

  @override
  String get conflictDetected => 'Conflito detectado';

  @override
  String get keepLocalVersion => 'Manter versão local';

  @override
  String get keepRemoteVersion => 'Manter versão remota';

  @override
  String get mergeManually => 'Mesclar manualmente';
}
