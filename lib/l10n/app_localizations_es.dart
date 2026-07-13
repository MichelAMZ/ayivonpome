// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FamilyTreeApp';

  @override
  String get applicationTitle => 'Nombre de la aplicación';

  @override
  String get applicationSubtitle => 'Subtítulo';

  @override
  String get showApplicationSubtitle => 'Mostrar subtítulo';

  @override
  String get editApplicationTitle => 'Editar título de la aplicación';

  @override
  String get applicationSettings => 'Configuración de la aplicación';

  @override
  String get officialFamilyName => 'Nombre oficial de la familia';

  @override
  String get treeInitialZoom => 'Zoom inicial del árbol';

  @override
  String get rememberLastZoom => 'Recordar el último zoom';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
      zero: '0 miembros',
    );
    return '$_temp0';
  }

  @override
  String totalMembers(int count) {
    return 'Total: $count';
  }

  @override
  String get showMembersCounter => 'Mostrar el contador en la barra inferior';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get help => 'Ayuda';

  @override
  String get helpAndTutorial => 'Ayuda y tutorial';

  @override
  String get showTutorial => 'Mostrar el botón de tutorial';

  @override
  String get hideTutorial => 'Ocultar tutorial';

  @override
  String get nextStep => 'Siguiente';

  @override
  String get previousStep => 'Anterior';

  @override
  String get finishTutorial => 'Finalizar';

  @override
  String get skipTutorial => 'Omitir';

  @override
  String get firstLaunchTutorial => 'Mostrar el tutorial en el primer inicio';

  @override
  String get treeLegend => 'Leyenda';

  @override
  String get howToUse => 'Cómo usar el árbol';

  @override
  String get tutorialWelcomeTitle => 'Bienvenido al árbol genealógico';

  @override
  String get tutorialMoveTitle => 'Desplazamiento';

  @override
  String get tutorialMoveBody => 'Haz clic y arrastra para mover el árbol.';

  @override
  String get tutorialZoomTitle => 'Zoom';

  @override
  String get tutorialZoomBody =>
      'Usa los botones + y -. Ctrl + rueda también permite hacer zoom.';

  @override
  String get tutorialInfoTitle => 'Información';

  @override
  String get tutorialInfoBody =>
      'Pasa el cursor sobre una persona para ver su información.';

  @override
  String get tutorialContextMenuTitle => 'Menú contextual';

  @override
  String get tutorialContextMenuBody =>
      'Haz clic derecho sobre una persona para añadir, editar, imprimir una rama o ver el historial.';

  @override
  String get tutorialAccessCodesTitle => 'Códigos de acceso';

  @override
  String get tutorialAccessCodesBody =>
      'Algunas acciones requieren un código de modificación.';

  @override
  String get tutorialMapTitle => 'Mapa';

  @override
  String get tutorialMapBody =>
      'Haz clic en el icono de ubicación para abrir Google Maps.';

  @override
  String get tutorialNotificationsTitle => 'Notificaciones';

  @override
  String get tutorialNotificationsBody =>
      'Los nuevos cambios aparecen automáticamente.';

  @override
  String get married => 'Casado/a';

  @override
  String get knownPlace => 'Lugar conocido';

  @override
  String get loginTitle => 'Acceso familiar';

  @override
  String get chooseLanguage => 'Elegir idioma';

  @override
  String get autoLanguage => 'Idioma automático';

  @override
  String get detectedLanguage => 'Idioma detectado';

  @override
  String get french => 'Francés';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get portuguese => 'Portugués';

  @override
  String get german => 'Alemán';

  @override
  String get familyCode => 'Código familiar';

  @override
  String get enter => 'Entrar';

  @override
  String get invalidCode => 'Código incorrecto';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get addPerson => 'Añadir persona';

  @override
  String get importJson => 'Importar JSON';

  @override
  String get exportJson => 'Exportar JSON';

  @override
  String get familyTree => 'Árbol';

  @override
  String get personDetails => 'Ficha de persona';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get birthPlace => 'Lugar de nacimiento';

  @override
  String get deathDate => 'Fecha de fallecimiento';

  @override
  String get deathPlace => 'Lugar de fallecimiento';

  @override
  String get parents => 'Padres';

  @override
  String get spouses => 'Cónyuges';

  @override
  String get children => 'Hijos';

  @override
  String get directChildren => 'Hijos directos';

  @override
  String get totalDescendants => 'Descendientes totales';

  @override
  String get descendants => 'Descendientes';

  @override
  String get childrenCount => 'Número de hijos';

  @override
  String get familyHistory => 'Historia familiar';

  @override
  String get ourHistory => 'Nuestra historia';

  @override
  String get historyOfFamily => 'Historia de la familia';

  @override
  String get generalFamilyHistory => 'Historia general de la familia';

  @override
  String get viewFamilyHistory => 'Ver la historia general de la familia';

  @override
  String get editFamilyHistory => 'Editar historia familiar';

  @override
  String get linkedFamilyHistory => 'Historia de la familia vinculada';

  @override
  String get historyContent => 'Contenido de la historia';

  @override
  String get historyTitle => 'Título de la historia';

  @override
  String get characterLimit => 'Límite de caracteres';

  @override
  String get charactersRemaining => 'Caracteres restantes';

  @override
  String get characterLimitExceeded =>
      'Se ha superado el límite de caracteres.';

  @override
  String get lastUpdatedBy => 'Última modificación por';

  @override
  String get lastUpdatedAt => 'Última modificación el';

  @override
  String get familyCouncil => 'Consejo familiar';

  @override
  String get councilMembers => 'Miembros del consejo';

  @override
  String get councilMember => 'Miembro del consejo';

  @override
  String get roleInCouncil => 'Función en el consejo';

  @override
  String get residencePlace => 'Lugar de residencia';

  @override
  String get contactCouncilMember => 'Contactar al miembro del consejo';

  @override
  String get viewCouncilMembers => 'Ver los miembros del consejo familiar';

  @override
  String get addCouncilMember => 'Añadir miembro';

  @override
  String get editCouncilMember => 'Editar miembro';

  @override
  String get deleteCouncilMember => 'Eliminar miembro';

  @override
  String get councilDescription => 'Miembros que acompañan al jefe de familia.';

  @override
  String get chiefCouncil => 'Consejo del jefe';

  @override
  String get infoNews => 'Información';

  @override
  String get infoNewsManagement => 'Informaciones / Noticias';

  @override
  String get addInfoNews => 'Añadir información';

  @override
  String get editInfoNews => 'Editar información';

  @override
  String get deleteInfoNews => 'Eliminar información';

  @override
  String get infoNewsTitle => 'Título de la información';

  @override
  String get infoNewsMessage => 'Mensaje corto';

  @override
  String get infoNewsActive => 'Información activa';

  @override
  String get priority => 'Prioridad';

  @override
  String get startAt => 'Inicio de visualización';

  @override
  String get endAt => 'Fin de visualización';

  @override
  String get sendToContacts => 'Enviar a contactos disponibles';

  @override
  String get sendViaWhatsApp => 'Enviar por WhatsApp';

  @override
  String get infoNewsSendLog => 'Historial de envíos';

  @override
  String get whatsappManualNotice =>
      'WhatsApp se abrirá con un mensaje prellenado. El administrador debe confirmar el envío.';

  @override
  String get freeWhatsAppQueue =>
      'Cola de envío gratuita: WhatsApp se abre con un mensaje prellenado y el administrador confirma manualmente.';

  @override
  String get copyMessage => 'Copiar mensaje';

  @override
  String get markAsSent => 'Marcar como enviado';

  @override
  String get skipContact => 'Omitir este contacto';

  @override
  String get nextContact => 'Siguiente';

  @override
  String get messageCopied => 'Mensaje copiado';

  @override
  String get whatsappOpened => 'WhatsApp abierto';

  @override
  String get sent => 'Enviado';

  @override
  String get failed => 'Error';

  @override
  String get skipped => 'Omitido';

  @override
  String get historyCleanupNotice =>
      'Los historiales de más de 3 meses se eliminan automáticamente.';

  @override
  String get autoHistoryCleanup => 'Limpieza automática de historiales';

  @override
  String get deleteOldHistoriesNow => 'Eliminar ahora los historiales antiguos';

  @override
  String get confirmDeleteOldHistories =>
      '¿Desea eliminar ahora los historiales de envío de más de 3 meses?';

  @override
  String get historiesKept => 'Historiales conservados';

  @override
  String get lastCleanup => 'Última limpieza';

  @override
  String get autoCleanupNotifications =>
      'Limpieza automática de notificaciones después de 1 semana';

  @override
  String get autoCleanupKpiActivityLogs =>
      'Limpieza automática del registro KPI después de 3 meses';

  @override
  String get deletedItems => 'Elementos eliminados';

  @override
  String get cleanNow => 'Limpiar ahora';

  @override
  String get confirmDataCleanup =>
      '¿Desea limpiar ahora las notificaciones antiguas y el registro KPI antiguo?';

  @override
  String get notificationAdminOnly =>
      'Solo los administradores están autorizados a enviar notificaciones.';

  @override
  String get history => 'Historia';

  @override
  String get notes => 'Notas';

  @override
  String get linkedFamilies => 'Familias vinculadas';

  @override
  String get addFamilyCode => 'Añadir código familiar';

  @override
  String get requestFamilyLink => 'Solicitar vínculo familiar';

  @override
  String get pending => 'Pendiente';

  @override
  String get accepted => 'Aceptado';

  @override
  String get refused => 'Rechazado';

  @override
  String get viewer => 'Lector';

  @override
  String get editor => 'Editor';

  @override
  String get owner => 'Propietario';

  @override
  String get preview => 'Vista previa';

  @override
  String get viewFullProfile => 'Ver ficha completa';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirmDelete => 'Confirmar eliminación';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get search => 'Buscar';

  @override
  String get familyLinks => 'Vínculos familiares';

  @override
  String get relationshipType => 'Tipo de vínculo';

  @override
  String get marriage => 'Matrimonio';

  @override
  String get parent => 'Padre';

  @override
  String get child => 'Hijo';

  @override
  String get adoption => 'Adopción';

  @override
  String get alliance => 'Alianza';

  @override
  String get commonAncestor => 'Ancestro común';

  @override
  String get other => 'Otro';

  @override
  String get backupCreated => 'Copia de seguridad creada';

  @override
  String get importError => 'Error de importación';

  @override
  String get exportSuccess => 'Exportación correcta';

  @override
  String get people => 'Personas';

  @override
  String get familiesCount => 'Familias vinculadas';

  @override
  String get pendingCount => 'Solicitudes pendientes';

  @override
  String get totalPeople => 'Personas en total';

  @override
  String get emptyState => 'No hay datos para mostrar';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get bornLastName => 'Apellido de nacimiento';

  @override
  String get bornAs => 'Nacido/a como';

  @override
  String get nee => 'nacida';

  @override
  String get gender => 'Sexo';

  @override
  String get photo => 'Foto';

  @override
  String get familyBranch => 'Familia o rama';

  @override
  String get edit => 'Editar';

  @override
  String get details => 'Detalles';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get confirmOverwrite => '¿Reemplazar los datos actuales?';

  @override
  String get merge => 'Fusionar';

  @override
  String get replace => 'Reemplazar';

  @override
  String get create => 'Crear';

  @override
  String get status => 'Estado';

  @override
  String get role => 'Rol';

  @override
  String get sourcePerson => 'Persona origen';

  @override
  String get targetPerson => 'Persona destino';

  @override
  String get note => 'Nota';

  @override
  String get accept => 'Aceptar';

  @override
  String get refuse => 'Rechazar';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get readOnly => 'Solo lectura';

  @override
  String get duplicatePerson => 'Posible duplicado detectado';

  @override
  String get requiredField => 'Campo obligatorio';

  @override
  String get unknown => 'Desconocido';

  @override
  String get currentAddress => 'Dirección actual';

  @override
  String get locationFilter => 'Filtro de ubicación';

  @override
  String get filterByLocation => 'Filtrar por ubicación';

  @override
  String get country => 'País';

  @override
  String get city => 'Ciudad';

  @override
  String get region => 'Región / prefectura / departamento';

  @override
  String get birthLocation => 'Lugar de nacimiento';

  @override
  String get deathLocation => 'Lugar de fallecimiento';

  @override
  String get burialLocation => 'Lugar de sepultura';

  @override
  String get radiusAroundAddress => 'Radio alrededor de una dirección';

  @override
  String membersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros encontrados',
      one: '1 miembro encontrado',
      zero: '0 miembros encontrados',
    );
    return '$_temp0';
  }

  @override
  String get showOnlyResults => 'Mostrar solo resultados';

  @override
  String get highlightResults => 'Resaltar resultados';

  @override
  String get clearFilters => 'Restablecer filtros';

  @override
  String get centerOnPerson => 'Centrar en la persona';

  @override
  String get burialPlace => 'Lugar de sepultura';

  @override
  String get importantPlaces => 'Lugares importantes';

  @override
  String get viewOnMap => 'Ver en el mapa';

  @override
  String get copyAddress => 'Copiar dirección';

  @override
  String get latitude => 'Latitud';

  @override
  String get longitude => 'Longitud';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get contact => 'Contacto';

  @override
  String get sendEmail => 'Enviar email';

  @override
  String get sendWhatsapp => 'WhatsApp';

  @override
  String get call => 'Llamar';

  @override
  String get copyEmail => 'Copiar email';

  @override
  String get copyPhone => 'Copiar teléfono';

  @override
  String get contactDisabled => 'Contacto desactivado';

  @override
  String get noContactInformation => 'No hay datos de contacto disponibles';

  @override
  String get emailCopied => 'Email copiado';

  @override
  String get phoneCopied => 'Teléfono copiado';

  @override
  String get openWhatsapp => 'Abrir WhatsApp';

  @override
  String get communication => 'Comunicación';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Teléfono';

  @override
  String get whatsappNumber => 'Número de WhatsApp';

  @override
  String get public => 'Público';

  @override
  String get familyOnly => 'Solo familia';

  @override
  String get private => 'Privado';

  @override
  String get familyEmailSubject => 'Hola de la familia';

  @override
  String get familyEmailBody =>
      'Hola,\n\nLe contacto desde FamilyTreeApp.\n\nSaludos.';

  @override
  String get familyWhatsappMessage => 'Hola desde FamilyTreeApp';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notifyPerson => 'Notificar a esta persona';

  @override
  String get sendNotification => 'Enviar notificación';

  @override
  String get notificationChannel => 'Canal de notificación';

  @override
  String get localNotification => 'Recordatorio local';

  @override
  String get emailNotification => 'Email';

  @override
  String get whatsappNotification => 'WhatsApp';

  @override
  String get scheduleReminder => 'Programar recordatorio';

  @override
  String get customMessage => 'Mensaje personalizado';

  @override
  String get birthdayReminder => 'Recordatorio de cumpleaños';

  @override
  String get deathAnniversaryReminder => 'Recordatorio de fallecimiento';

  @override
  String get familyMeetingReminder => 'Reunión familiar';

  @override
  String get linkRequestReminder => 'Solicitud de vínculo familiar';

  @override
  String get notificationSent => 'Notificación preparada';

  @override
  String get notificationFailed => 'Notificación fallida';

  @override
  String get notificationScheduled => 'Recordatorio programado';

  @override
  String get notificationPermissionRequired =>
      'Permiso de notificación requerido';

  @override
  String get futurePushNotification => 'Push futuro';

  @override
  String get noBackendPushNotice =>
      'Las notificaciones push remotas reales requieren backend. Esta versión local prepara email/WhatsApp y programa recordatorios locales.';

  @override
  String get notificationExternalAppNotice =>
      'Email y WhatsApp abren una aplicación externa tras confirmación.';

  @override
  String get copy => 'Copiar';

  @override
  String get enterAccessCode => 'Introducir código de acceso';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get publicLimitedMode => 'Modo público limitado';

  @override
  String get publicLimitedModeDescription =>
      'Introduzca el código de acceso para ver la información privada de la familia.';

  @override
  String get publicMode => 'Modo público';

  @override
  String get publicMapLocation => 'Ubicación pública en el mapa';

  @override
  String get showMapInPublicMode => 'Mostrar mapa en modo público';

  @override
  String get showBirthPlaceInPublicMode =>
      'Permitir lugar de nacimiento público';

  @override
  String get showCurrentAddressInPublicMode =>
      'Permitir dirección actual pública';

  @override
  String get showContactInPublicMode => 'Permitir contacto público';

  @override
  String get showHistoryInPublicMode => 'Permitir historia pública';

  @override
  String get totalMembersTitle => 'Total de miembros';

  @override
  String get visiblePeopleCount => 'personas visibles';

  @override
  String get adminDashboard => 'Admin familiar';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get admin => 'Admin';

  @override
  String get modificationCode => 'Código de modificación';

  @override
  String get enterModificationCode => 'Introducir código de modificación';

  @override
  String get modificationCodeRequired => 'Código de modificación requerido';

  @override
  String get modificationCodeRequiredMessage =>
      'Para añadir o modificar una persona, necesita un código de modificación de un administrador familiar.';

  @override
  String get invalidModificationCode => 'Código de modificación incorrecto';

  @override
  String get validModificationCode => 'Código de modificación aceptado';

  @override
  String get contactAdmin => 'Contactar admin';

  @override
  String get contactAdmins => 'Contactar admins';

  @override
  String get adminContactMessage =>
      'Hola, quisiera obtener un código de modificación para FamilyTreeApp.';

  @override
  String get manageAdmins => 'Gestionar admins';

  @override
  String get manageModificationCodes => 'Gestionar códigos de modificación';

  @override
  String get activeCodes => 'Códigos activos';

  @override
  String get expiredCodes => 'Códigos expirados';

  @override
  String get usedCodes => 'Códigos usados';

  @override
  String get adminKpi => 'KPI Admin';

  @override
  String get activityLog => 'Registro de actividad';

  @override
  String get codeCreated => 'Código creado';

  @override
  String get codeDisabled => 'Código desactivado';

  @override
  String get personAddedThisMonth => 'Personas añadidas este mes';

  @override
  String get personModifiedThisMonth => 'Personas modificadas este mes';

  @override
  String get familyRelationships => 'Relaciones familiares';

  @override
  String get father => 'Padre';

  @override
  String get mother => 'Madre';

  @override
  String get marriedTo => 'Casado/a con';

  @override
  String get spouse => 'Cónyuge';

  @override
  String get husband => 'Esposo';

  @override
  String get wife => 'Esposa';

  @override
  String get wives => 'Esposas';

  @override
  String get siblings => 'Hermanos';

  @override
  String get male => 'Hombre';

  @override
  String get female => 'Mujer';

  @override
  String get unknownGender => 'No indicado';

  @override
  String get polygamy => 'Poligamia';

  @override
  String get monogamy => 'Monogamia';

  @override
  String get customaryMarriage => 'Matrimonio consuetudinario';

  @override
  String get civilMarriage => 'Matrimonio civil';

  @override
  String get religiousMarriage => 'Matrimonio religioso';

  @override
  String get marriageType => 'Tipo de matrimonio';

  @override
  String get marriageStatus => 'Estado del matrimonio';

  @override
  String get maritalStatus => 'Estado civil';

  @override
  String get activeMarriage => 'Matrimonio activo';

  @override
  String get separated => 'Separado';

  @override
  String get divorced => 'Divorciado';

  @override
  String get divorce => 'Divorcio';

  @override
  String get declareDivorce => 'Declarar divorcio';

  @override
  String get divorceDate => 'Fecha de divorcio';

  @override
  String get formerSpouse => 'Ex cónyuge';

  @override
  String get formerSpouses => 'Ex cónyuges';

  @override
  String get restoreMarriage => 'Restaurar matrimonio';

  @override
  String get divorceHistory => 'Historial matrimonial';

  @override
  String get widowed => 'Viudo/a';

  @override
  String get invalidRelationship =>
      'Relación incoherente: una persona no puede ser su propio padre, cónyuge o hijo.';

  @override
  String get addFather => 'Añadir padre';

  @override
  String get addMother => 'Añadir madre';

  @override
  String get addParents => 'Añadir padres';

  @override
  String get addChild => 'Añadir hijo';

  @override
  String get addChildren => 'Añadir varios hijos';

  @override
  String get addSibling => 'Añadir hermano/a';

  @override
  String get addBrother => 'Añadir hermano';

  @override
  String get addSister => 'Añadir hermana';

  @override
  String get addSpouse => 'Añadir cónyuge';

  @override
  String get linkExistingPerson => 'Vincular persona existente';

  @override
  String get viewProfile => 'Ver ficha';

  @override
  String get editPerson => 'Editar persona';

  @override
  String get deletePerson => 'Eliminar persona';

  @override
  String get addHistoricalEvent => 'Añadir evento histórico';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get copyInformation => 'Copiar información';

  @override
  String get latestChanges => 'Últimos cambios';

  @override
  String get newPeopleAdded => 'Nuevas personas añadidas';

  @override
  String get newModifications => 'Nuevas modificaciones';

  @override
  String get modifiedBy => 'Modificado por';

  @override
  String get addedBy => 'Añadido por';

  @override
  String get updatedBy => 'Actualizado por';

  @override
  String get deletedBy => 'Eliminado por';

  @override
  String get viewHistory => 'Ver historial';

  @override
  String get markAsSeen => 'Visto';

  @override
  String get doNotShowAgain => 'No mostrar de nuevo';

  @override
  String get modificationHistory => 'Historial de modificaciones';

  @override
  String get personAdded => 'Persona añadida';

  @override
  String get personUpdated => 'Persona modificada';

  @override
  String get personDeleted => 'Persona eliminada';

  @override
  String get relationshipAdded => 'Vínculo familiar añadido';

  @override
  String get historyRetention => 'Conservación del historial';

  @override
  String get historyDeletedAfterThreeMonths =>
      'Historial eliminado después de tres meses';

  @override
  String get adminAccessCode => 'Código admin';

  @override
  String get enterAdminCode => 'Introducir código admin';

  @override
  String get invalidAdminCode => 'Código admin incorrecto';

  @override
  String get forgotCode => '¿Código olvidado?';

  @override
  String get superAdminRecovery => 'Restablecimiento Super Admin';

  @override
  String get enterSuperAdminRecoveryCode =>
      'Introducir el código secreto Super Admin';

  @override
  String get resetCodes => 'Restablecer códigos';

  @override
  String get resetAllCodes => 'Regenerar automáticamente todos los códigos';

  @override
  String get generateNewCodes => 'Crear nuevos códigos';

  @override
  String get recoveryCodeInvalid => 'Código secreto Super Admin incorrecto';

  @override
  String get recoveryCodeAccepted => 'Código secreto Super Admin aceptado';

  @override
  String get codesResetSuccess => 'Códigos restablecidos correctamente';

  @override
  String get confirmResetCodes =>
      '¿Confirmar el restablecimiento de códigos? Se creará una copia JSON antes de modificar.';

  @override
  String get adminKpiAccess => 'Acceso Admin / KPI';

  @override
  String get adminSecurity => 'Seguridad admin';

  @override
  String get changeAdminCode => 'Cambiar código admin';

  @override
  String get currentAdminCode => 'Código admin actual';

  @override
  String get oldAdminCode => 'Código admin anterior';

  @override
  String get newAdminCode => 'Nuevo código admin';

  @override
  String get confirmNewAdminCode => 'Confirmar nuevo código';

  @override
  String get adminCodeChanged => 'Código admin cambiado';

  @override
  String get adminCodeRotationDue => 'El código admin debe cambiarse';

  @override
  String get adminCodeRotationLate => 'Cambio de código admin atrasado';

  @override
  String get nextAdminCodeChange => 'Próximo cambio recomendado';

  @override
  String get lastAdminCodeChange => 'Último cambio';

  @override
  String get adminCodeHistory => 'Historial de códigos admin';

  @override
  String get codeManagement => 'Gestión de códigos';

  @override
  String get accessCodes => 'Códigos de acceso';

  @override
  String get createAccessCode => 'Crear código';

  @override
  String get editAccessCode => 'Modificar código';

  @override
  String get deleteAccessCode => 'Eliminar código';

  @override
  String get disableAccessCode => 'Desactivar código';

  @override
  String get enableAccessCode => 'Reactivar código';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get showCode => 'Mostrar código';

  @override
  String get hideCode => 'Ocultar código';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get codeType => 'Tipo de código';

  @override
  String get codeRole => 'Rol del código';

  @override
  String get codeStatus => 'Estado del código';

  @override
  String get codeExpiration => 'Expiración';

  @override
  String get codeUsage => 'Usos';

  @override
  String get createdBy => 'Creado por';

  @override
  String get lastUsedAt => 'Último uso';

  @override
  String get maxUses => 'Usos máximos';

  @override
  String get generateCode => 'Generar código';

  @override
  String get manualCode => 'Código manual';

  @override
  String get familyAccessCode => 'Código de acceso familiar';

  @override
  String get adminKpiCode => 'Código Admin KPI';

  @override
  String get linkedFamilyCode => 'Código familia vinculada';

  @override
  String get branding => 'Marca';

  @override
  String get visualIdentity => 'Identidad visual';

  @override
  String get familyLogo => 'Logo familiar';

  @override
  String get customizeLogo => 'Personalizar logo';

  @override
  String get uploadLogo => 'Subir logo';

  @override
  String get replaceLogo => 'Reemplazar logo';

  @override
  String get deleteLogo => 'Eliminar logo';

  @override
  String get restoreDefaultLogo => 'Restaurar predeterminado';

  @override
  String get logoPreview => 'Vista previa del logo';

  @override
  String get logoPosition => 'Posición del logo';

  @override
  String get logoSize => 'Tamaño del logo';

  @override
  String get logoShape => 'Forma del logo';

  @override
  String get showLogo => 'Mostrar logo';

  @override
  String get hideLogo => 'Ocultar logo';

  @override
  String get showMemberCountOnLogo => 'Visualización del contador de miembros';

  @override
  String get useLogoAsFavicon => 'Usar logo como favicon';

  @override
  String get logoUpdated => 'Logo actualizado correctamente';

  @override
  String get invalidLogoFile => 'Archivo de logo inválido';

  @override
  String get logoFileTooLarge => 'El archivo de logo es demasiado grande';

  @override
  String get brandingPermissionRequired => 'Permiso de marca requerido';

  @override
  String get linkedFamilyTree => 'Árbol familiar vinculado';

  @override
  String get openLinkedFamilyTree => 'Abrir árbol familiar vinculado';

  @override
  String get originFamilyTree => 'Árbol de la familia de origen';

  @override
  String get familyOfOrigin => 'Familia de origen';

  @override
  String get linkedBranch => 'Rama vinculada';

  @override
  String get openFamilyBranch => 'Abrir rama familiar';

  @override
  String get backToMainTree => 'Volver al árbol principal';

  @override
  String get mainFamilyTree => 'Árbol familiar principal';

  @override
  String get familyBreadcrumb => 'Ruta familiar';

  @override
  String get linkedTreeAvailable => 'Árbol vinculado disponible';

  @override
  String get noLinkedTree => 'Sin árbol vinculado';

  @override
  String get manageLinkedTrees => 'Gestionar árboles vinculados';

  @override
  String get treeBridgePerson => 'Persona puente';

  @override
  String get temporaryCode => 'Código temporal';

  @override
  String get codeUpdated => 'Código actualizado';

  @override
  String get codeDeleted => 'Código eliminado';

  @override
  String get codeEnabled => 'Código reactivado';

  @override
  String get codeAlreadyExists => 'Este código ya existe';

  @override
  String get regenerateCode => 'Regenerar';

  @override
  String get confirmRegenerateCode =>
      '¿Desea regenerar este código? El código anterior se desactivará.';

  @override
  String get codeRegenerated => 'Nuevo código generado correctamente.';

  @override
  String get newGeneratedCode => 'Nuevo código generado';

  @override
  String get copyNewCode => 'Copiar nuevo código';

  @override
  String get oldCodeDisabled => 'El código anterior se ha desactivado.';

  @override
  String get previousCode => 'Código anterior';

  @override
  String get replacedByCode => 'Reemplazado por el código';

  @override
  String get regeneratedAt => 'Regenerado el';

  @override
  String get familyHonor => 'Honor familiar';

  @override
  String get patriarch => 'Patriarca';

  @override
  String get patriarchBadge => 'Insignia del patriarca';

  @override
  String get selectPatriarch => 'Seleccionar patriarca';

  @override
  String get showPatriarchBadge => 'Mostrar insignia del patriarca';

  @override
  String get badgePosition => 'Posición de la insignia';

  @override
  String get badgeStyle => 'Estilo de la insignia';

  @override
  String get viewPatriarchProfile => 'Ver ficha del patriarca';

  @override
  String get familyDistinctions => 'Distinciones familiares';

  @override
  String get leader => 'Líder';

  @override
  String get currentLeader => 'Líder actual';

  @override
  String get familyLeader => 'Líder familiar';

  @override
  String get familyChief => 'Jefe de familia';

  @override
  String get matriarch => 'Matriarca';

  @override
  String get viewLeaderProfile => 'Ver ficha del líder actual';

  @override
  String get chiefTitle => 'Título del líder';

  @override
  String get showLeaderInTopBar => 'Mostrar líder en la TopBar';

  @override
  String get showLeaderBanner => 'Mostrar el banner del jefe de familia';

  @override
  String get showLeaderPhoto => 'Mostrar foto / avatar';

  @override
  String get topBarLogoMode => 'Modo de logo TopBar';

  @override
  String get classicLogo => 'Logo clásico';

  @override
  String get logoAndLeader => 'Logo + líder actual';

  @override
  String get leaderOnly => 'Solo líder actual';

  @override
  String get currentChief => 'Jefe actual';

  @override
  String get formerChief => 'Antiguo jefe';

  @override
  String get successor => 'Sucesor designado';

  @override
  String get familyLeadership => 'Liderazgo familiar';

  @override
  String get leadershipHistory => 'Historia de los jefes';

  @override
  String get familyHonorHall => 'Personalidades familiares';

  @override
  String get appointLeader => 'Nombrar líder';

  @override
  String get removeLeader => 'Retirar líder';

  @override
  String get chiefSince => 'Jefe desde';

  @override
  String get bugReports => 'Errores reportados';

  @override
  String get reportBug => 'Reportar un error';

  @override
  String get bugTitle => 'Título del error';

  @override
  String get bugDescription => 'Descripción';

  @override
  String get bugScreen => 'Pantalla afectada';

  @override
  String get bugPriority => 'Prioridad';

  @override
  String get bugStatus => 'Estado del error actualizado';

  @override
  String get reportedBy => 'Reportado por';

  @override
  String get reportedAt => 'Reportado el';

  @override
  String get notifyAdminsWhatsapp => 'Notificar admins por WhatsApp';

  @override
  String get bugOpen => 'Abierto';

  @override
  String get bugInProgress => 'En curso';

  @override
  String get bugResolved => 'Resuelto';

  @override
  String get bugDeleted => 'Eliminado';

  @override
  String get deleteBugReport => 'Eliminar reporte';

  @override
  String get confirmDeleteBugReport =>
      '¿Quieres eliminar este reporte de error?';

  @override
  String get bugReportCreated => 'Error reportado.';

  @override
  String get adminWhatsappNotification =>
      'WhatsApp se abrirá con un mensaje preparado. Cada admin deberá confirmar el envío.';

  @override
  String get generation => 'Generación';

  @override
  String get generations => 'Generaciones';

  @override
  String get generationNumber => 'Número de generación';

  @override
  String get rootAncestor => 'Ancestro raíz';

  @override
  String get firstAncestor => 'Primer ancestro';

  @override
  String get recalculateGenerations => 'Recalcular todas las generaciones';

  @override
  String get showGenerationBadges => 'Mostrar insignias de generación';

  @override
  String get allGenerations => 'Todas las generaciones';

  @override
  String get storageMode => 'Modo de almacenamiento';

  @override
  String get jsonOnly => 'Solo JSON';

  @override
  String get databaseOnly => 'Solo base de datos';

  @override
  String get hybridStorage => 'Almacenamiento híbrido';

  @override
  String get syncStatus => 'Estado de sincronización';

  @override
  String get synced => 'Sincronizado';

  @override
  String get offline => 'Sin conexión';

  @override
  String get syncPending => 'Sincronización pendiente';

  @override
  String get syncInProgress => 'Sincronización en curso';

  @override
  String get syncError => 'Error de sincronización';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get lastSyncAt => 'Última sincronización';

  @override
  String get pendingOperations => 'Operaciones pendientes';

  @override
  String get conflictDetected => 'Conflicto detectado';

  @override
  String get keepLocalVersion => 'Conservar versión local';

  @override
  String get keepRemoteVersion => 'Conservar versión remota';

  @override
  String get mergeManually => 'Fusionar manualmente';
}
