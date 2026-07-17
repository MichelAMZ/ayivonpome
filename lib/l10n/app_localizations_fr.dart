// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FamilyTreeApp';

  @override
  String get applicationTitle => 'Nom de l\'application';

  @override
  String get applicationSubtitle => 'Sous-titre';

  @override
  String get showApplicationSubtitle => 'Afficher le sous-titre';

  @override
  String get editApplicationTitle => 'Modifier le titre de l\'application';

  @override
  String get applicationSettings => 'Paramètres de l\'application';

  @override
  String get officialFamilyName => 'Nom officiel de la famille';

  @override
  String get treeInitialZoom => 'Zoom initial de l\'arbre';

  @override
  String get rememberLastZoom => 'Mémoriser le dernier zoom';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: '0 membre',
    );
    return '$_temp0';
  }

  @override
  String totalMembers(int count) {
    return 'Total : $count';
  }

  @override
  String get showMembersCounter => 'Afficher le compteur dans la barre du bas';

  @override
  String get tutorial => 'Tutoriel';

  @override
  String get help => 'Aide';

  @override
  String get helpAndTutorial => 'Aide et tutoriel';

  @override
  String get showTutorial => 'Afficher le bouton tutoriel';

  @override
  String get hideTutorial => 'Masquer le tutoriel';

  @override
  String get nextStep => 'Suivant';

  @override
  String get previousStep => 'Précédent';

  @override
  String get finishTutorial => 'Terminer';

  @override
  String get skipTutorial => 'Ignorer';

  @override
  String get firstLaunchTutorial => 'Afficher le tutoriel au premier lancement';

  @override
  String get treeLegend => 'Légende';

  @override
  String get howToUse => 'Comment utiliser l\'arbre';

  @override
  String get tutorialWelcomeTitle => 'Bienvenue dans l\'arbre généalogique';

  @override
  String get tutorialMoveTitle => 'Déplacement';

  @override
  String get tutorialMoveBody => 'Cliquer-glisser pour déplacer l\'arbre.';

  @override
  String get tutorialZoomTitle => 'Zoom';

  @override
  String get tutorialZoomBody =>
      'Utiliser les boutons + et -. Ctrl + molette permet aussi de zoomer.';

  @override
  String get tutorialInfoTitle => 'Informations';

  @override
  String get tutorialInfoBody =>
      'Survoler une personne pour voir ses informations.';

  @override
  String get tutorialContextMenuTitle => 'Menu contextuel';

  @override
  String get tutorialContextMenuBody =>
      'Faire un clic droit sur une personne pour ajouter, modifier, imprimer une branche ou voir l\'historique.';

  @override
  String get tutorialAccessCodesTitle => 'Codes d\'accès';

  @override
  String get tutorialAccessCodesBody =>
      'Certaines actions nécessitent un code de modification.';

  @override
  String get tutorialMapTitle => 'Carte';

  @override
  String get tutorialMapBody =>
      'Cliquer sur l\'icône localisation pour ouvrir Google Maps.';

  @override
  String get tutorialNotificationsTitle => 'Notifications';

  @override
  String get tutorialNotificationsBody =>
      'Les nouvelles modifications apparaissent automatiquement.';

  @override
  String get married => 'Marié(e)';

  @override
  String get knownPlace => 'Lieu connu';

  @override
  String get loginTitle => 'Connexion familiale';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get autoLanguage => 'Langue automatique';

  @override
  String get detectedLanguage => 'Langue détectée';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get portuguese => 'Portugais';

  @override
  String get german => 'Allemand';

  @override
  String get familyCode => 'Code familial';

  @override
  String get enter => 'Entrer';

  @override
  String get invalidCode => 'Code incorrect';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get addPerson => 'Ajouter une personne';

  @override
  String get importJson => 'Importer JSON';

  @override
  String get exportJson => 'Exporter JSON';

  @override
  String get familyTree => 'Arbre';

  @override
  String get personDetails => 'Fiche personne';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get birthPlace => 'Lieu de naissance';

  @override
  String get deathDate => 'Date de décès';

  @override
  String get deathPlace => 'Lieu de décès';

  @override
  String get parents => 'Parents';

  @override
  String get spouses => 'Conjoints';

  @override
  String get children => 'Enfants';

  @override
  String get directChildren => 'Enfants directs';

  @override
  String get totalDescendants => 'Descendants totaux';

  @override
  String get descendants => 'Descendants';

  @override
  String get childrenCount => 'Nombre d’enfants';

  @override
  String get familyHistory => 'Historique familial';

  @override
  String get ourHistory => 'Notre histoire';

  @override
  String get historyOfFamily => 'Histoire de la famille';

  @override
  String get generalFamilyHistory => 'Historique général de la famille';

  @override
  String get viewFamilyHistory => 'Voir l’histoire générale de la famille';

  @override
  String get editFamilyHistory => 'Modifier l’historique familial';

  @override
  String get linkedFamilyHistory => 'Historique de la famille liée';

  @override
  String get historyContent => 'Contenu de l’histoire';

  @override
  String get historyTitle => 'Titre de l’histoire';

  @override
  String get characterLimit => 'Limite de caractères';

  @override
  String get charactersRemaining => 'Caractères restants';

  @override
  String get characterLimitExceeded => 'La limite de caractères est dépassée.';

  @override
  String get lastUpdatedBy => 'Dernière modification par';

  @override
  String get lastUpdatedAt => 'Dernière modification le';

  @override
  String get familyCouncil => 'Conseil familial';

  @override
  String get councilMembers => 'Membres du conseil';

  @override
  String get councilMember => 'Membre du conseil';

  @override
  String get roleInCouncil => 'Fonction dans le conseil';

  @override
  String get residencePlace => 'Lieu d’habitation';

  @override
  String get contactCouncilMember => 'Contacter le membre du conseil';

  @override
  String get viewCouncilMembers => 'Voir les membres du conseil familial';

  @override
  String get addCouncilMember => 'Ajouter un membre';

  @override
  String get editCouncilMember => 'Modifier le membre';

  @override
  String get deleteCouncilMember => 'Supprimer le membre';

  @override
  String get councilDescription =>
      'Membres qui accompagnent le chef de famille.';

  @override
  String get chiefCouncil => 'Conseil du chef';

  @override
  String get infoNews => 'Information';

  @override
  String get infoNewsManagement => 'Informations / Actualités';

  @override
  String get addInfoNews => 'Ajouter une information';

  @override
  String get editInfoNews => 'Modifier l’information';

  @override
  String get deleteInfoNews => 'Supprimer l’information';

  @override
  String get infoNewsTitle => 'Titre de l’information';

  @override
  String get infoNewsMessage => 'Message court';

  @override
  String get infoNewsActive => 'Information active';

  @override
  String get priority => 'Priorité';

  @override
  String get startAt => 'Début d’affichage';

  @override
  String get endAt => 'Fin d’affichage';

  @override
  String get sendToContacts => 'Envoyer aux contacts disponibles';

  @override
  String get sendViaWhatsApp => 'Envoyer via WhatsApp';

  @override
  String get infoNewsSendLog => 'Journal d’envoi';

  @override
  String get whatsappManualNotice =>
      'WhatsApp s’ouvrira avec un message prérempli. L’admin doit valider l’envoi.';

  @override
  String get freeWhatsAppQueue =>
      'File d’envoi gratuite : WhatsApp s’ouvre avec un message prérempli, puis l’admin confirme manuellement.';

  @override
  String get copyMessage => 'Copier le message';

  @override
  String get markAsSent => 'Marquer comme envoyé';

  @override
  String get skipContact => 'Ignorer ce contact';

  @override
  String get nextContact => 'Suivant';

  @override
  String get messageCopied => 'Message copié';

  @override
  String get whatsappOpened => 'WhatsApp ouvert';

  @override
  String get sent => 'Envoyé';

  @override
  String get failed => 'Échec';

  @override
  String get skipped => 'Ignoré';

  @override
  String get historyCleanupNotice =>
      'Les historiques de plus de 3 mois sont automatiquement supprimés.';

  @override
  String get autoHistoryCleanup => 'Nettoyage automatique des historiques';

  @override
  String get deleteOldHistoriesNow =>
      'Supprimer maintenant les historiques anciens';

  @override
  String get confirmDeleteOldHistories =>
      'Voulez-vous supprimer maintenant les historiques d’envoi de plus de 3 mois ?';

  @override
  String get historiesKept => 'Historiques conservés';

  @override
  String get lastCleanup => 'Dernier nettoyage';

  @override
  String get autoCleanupNotifications =>
      'Nettoyage automatique des notifications après 1 semaine';

  @override
  String get autoCleanupKpiActivityLogs =>
      'Nettoyage automatique du journal KPI après 3 mois';

  @override
  String get deletedItems => 'Éléments supprimés';

  @override
  String get cleanNow => 'Nettoyer maintenant';

  @override
  String get confirmDataCleanup =>
      'Voulez-vous nettoyer maintenant les notifications anciennes et le journal KPI ancien ?';

  @override
  String get notificationAdminOnly =>
      'Seuls les administrateurs sont autorisés à envoyer des notifications.';

  @override
  String get history => 'Historique';

  @override
  String get notes => 'Notes';

  @override
  String get linkedFamilies => 'Familles liées';

  @override
  String get addFamilyCode => 'Ajouter un code familial';

  @override
  String get requestFamilyLink => 'Demander un lien familial';

  @override
  String get pending => 'En attente';

  @override
  String get accepted => 'Accepté';

  @override
  String get refused => 'Refusé';

  @override
  String get viewer => 'Lecteur';

  @override
  String get editor => 'Éditeur';

  @override
  String get owner => 'Propriétaire';

  @override
  String get preview => 'Aperçu';

  @override
  String get viewFullProfile => 'Voir la fiche complète';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get search => 'Rechercher';

  @override
  String get familyLinks => 'Liens familiaux';

  @override
  String get relationshipType => 'Type de lien';

  @override
  String get marriage => 'Mariage';

  @override
  String get parent => 'Parent';

  @override
  String get child => 'Enfant';

  @override
  String get adoption => 'Adoption';

  @override
  String get alliance => 'Alliance';

  @override
  String get commonAncestor => 'Ancêtre commun';

  @override
  String get other => 'Autre';

  @override
  String get backupCreated => 'Sauvegarde de sécurité créée';

  @override
  String get importError => 'Erreur d\'import';

  @override
  String get exportSuccess => 'Export réussi';

  @override
  String get people => 'Personnes';

  @override
  String get familiesCount => 'Familles liées';

  @override
  String get pendingCount => 'Demandes en attente';

  @override
  String get totalPeople => 'Personnes au total';

  @override
  String get emptyState => 'Aucune donnée à afficher';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get bornLastName => 'Nom de naissance';

  @override
  String get bornAs => 'Né(e)';

  @override
  String get nee => 'née';

  @override
  String get gender => 'Sexe';

  @override
  String get photo => 'Photo';

  @override
  String get familyBranch => 'Famille ou branche';

  @override
  String get edit => 'Modifier';

  @override
  String get details => 'Détails';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get confirmOverwrite => 'Remplacer les données actuelles ?';

  @override
  String get merge => 'Fusionner';

  @override
  String get replace => 'Remplacer';

  @override
  String get create => 'Créer';

  @override
  String get status => 'Statut';

  @override
  String get role => 'Rôle';

  @override
  String get sourcePerson => 'Personne source';

  @override
  String get targetPerson => 'Personne cible';

  @override
  String get note => 'Note';

  @override
  String get accept => 'Accepter';

  @override
  String get refuse => 'Refuser';

  @override
  String get storage => 'Stockage';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get duplicatePerson => 'Doublon probable détecté';

  @override
  String get requiredField => 'Champ obligatoire';

  @override
  String get requiredFieldsNotice =>
      'Les champs marqués d’un * sont obligatoires.';

  @override
  String get requiredFieldExplicit => 'Ce champ obligatoire doit être rempli.';

  @override
  String get requiredFieldsMissingTitle => 'Champs obligatoires manquants';

  @override
  String requiredFieldsMissingMessage(int count, String fields) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Veuillez remplir les champs obligatoires suivants : $fields.',
      one: 'Veuillez remplir le champ obligatoire suivant : $fields.',
    );
    return '$_temp0';
  }

  @override
  String requiredFieldsMissingSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs obligatoires restent à remplir.',
      one: '1 champ obligatoire reste à remplir.',
    );
    return '$_temp0';
  }

  @override
  String get profileLoadError => 'Impossible de charger la fiche personne.';

  @override
  String get retry => 'Réessayer';

  @override
  String get moreActions => 'Plus d’actions';

  @override
  String get editThisPerson => 'Modifier cette personne';

  @override
  String get viewInTree => 'Voir dans l’arbre';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get notProvided => 'Non renseigné';

  @override
  String get notProvidedFeminine => 'Non renseignée';

  @override
  String get branchLabel => 'Branche';

  @override
  String bornOn(String date) {
    return 'Né le $date';
  }

  @override
  String get noChildrenProvided => 'Aucun enfant renseigné';

  @override
  String get noSiblingsProvided => 'Aucun frère ou sœur renseigné';

  @override
  String get location => 'Localisation';

  @override
  String get noLocationAvailable => 'Aucune localisation disponible';

  @override
  String get eventsAndPlaces => 'Événements et lieux';

  @override
  String get noHistoryEvents => 'Aucun événement à afficher pour le moment.';

  @override
  String get noHistoryEventsHelp =>
      'Les événements marquants de cette personne apparaîtront ici lorsqu’ils seront ajoutés.';

  @override
  String get noNotes => 'Aucune note';

  @override
  String get viewMore => 'Voir plus';

  @override
  String get profileProgress => 'Progression du profil';

  @override
  String get profileProgressHelp =>
      'La progression est calculée à partir des champs obligatoires réellement remplis. Les champs facultatifs n’empêchent pas d’atteindre 100 %.';

  @override
  String requiredFieldsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs à compléter',
      one: '1 champ à compléter',
      zero: 'Tous les champs obligatoires sont complétés',
    );
    return '$_temp0';
  }

  @override
  String get requiredInfoAlmostDone =>
      'Les informations obligatoires sont presque terminées';

  @override
  String get completeRequiredInfoHelp =>
      'Complétez les champs obligatoires pour finaliser le profil.';

  @override
  String get identity => 'Identité';

  @override
  String get family => 'Famille';

  @override
  String get relationships => 'Relations';

  @override
  String get places => 'Lieux';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get existingMember => 'Membre existant';

  @override
  String get createMember => 'Créer un membre';

  @override
  String get existingTreeMember => 'Membre existant dans l’arbre';

  @override
  String get parentSelectionRequired =>
      'Sélection obligatoire lorsqu’un parent est renseigné.';

  @override
  String get unionsAndSpouses => 'Unions et conjoints';

  @override
  String get saveDraft => 'Enregistrer le brouillon';

  @override
  String get saveAndContinue => 'Enregistrer et continuer';

  @override
  String get draftSavedNow => 'Brouillon enregistré à l’instant';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get manageUnions => 'Gérer les unions';

  @override
  String get manageChildren => 'Gérer les enfants';

  @override
  String get unionRequiredFieldsAppearOnAdd =>
      'Les champs obligatoires apparaîtront lors de l’ajout d’une union.';

  @override
  String get unsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get unsavedChangesMessage =>
      'Des modifications ne sont pas enregistrées. Voulez-vous quitter sans enregistrer ?';

  @override
  String get leave => 'Quitter';

  @override
  String get informationVisibility => 'Visibilité des informations';

  @override
  String get choosePublicProfileVisibility =>
      'Choisissez les informations visibles sur la fiche publique du membre.';

  @override
  String get alwaysVisible => 'Toujours visible';

  @override
  String get hideSensitiveInfo => 'Masquer les informations sensibles';

  @override
  String get restoreDefaultVisibility => 'Restaurer les réglages par défaut';

  @override
  String get visible => 'Visible';

  @override
  String get hidden => 'Masqué';

  @override
  String get privateCoordinates => 'Coordonnées privées';

  @override
  String get familyRelationsVisibilityDescription =>
      'Père, mère, conjoints, unions et enfants.';

  @override
  String get sensitiveVisibilityConfirmation =>
      'Cette information pourra être consultée sur la fiche publique. Voulez-vous continuer ?';

  @override
  String get makeVisible => 'Rendre visible';

  @override
  String get cancelChangesTooltip => 'Annuler les modifications';

  @override
  String get cancelChangesTitle => 'Annuler les modifications ?';

  @override
  String get cancelChangesMessage =>
      'Les modifications non enregistrées seront perdues.';

  @override
  String get continueEditing => 'Continuer la modification';

  @override
  String get discardChanges => 'Abandonner les modifications';

  @override
  String get unknown => 'Inconnu';

  @override
  String get currentAddress => 'Adresse actuelle';

  @override
  String get locationFilter => 'Filtre de localisation';

  @override
  String get filterByLocation => 'Filtrer par localisation';

  @override
  String get country => 'Pays';

  @override
  String get city => 'Ville';

  @override
  String get region => 'Région / préfecture / département';

  @override
  String get birthLocation => 'Lieu de naissance';

  @override
  String get deathLocation => 'Lieu de décès';

  @override
  String get burialLocation => 'Lieu de sépulture';

  @override
  String get radiusAroundAddress => 'Rayon autour d\'une adresse';

  @override
  String membersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres trouvés',
      one: '1 membre trouvé',
      zero: '0 membre trouvé',
    );
    return '$_temp0';
  }

  @override
  String get showOnlyResults => 'Afficher uniquement les résultats';

  @override
  String get highlightResults => 'Surligner les résultats';

  @override
  String get clearFilters => 'Réinitialiser les filtres';

  @override
  String get centerOnPerson => 'Centrer sur la personne';

  @override
  String get burialPlace => 'Lieu de sépulture';

  @override
  String get importantPlaces => 'Lieux importants';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get contact => 'Contact';

  @override
  String get sendEmail => 'Envoyer un email';

  @override
  String get sendWhatsapp => 'WhatsApp';

  @override
  String get call => 'Appeler';

  @override
  String get copyEmail => 'Copier l\'email';

  @override
  String get copyPhone => 'Copier le téléphone';

  @override
  String get contactDisabled => 'Contact désactivé';

  @override
  String get noContactInformation => 'Aucune coordonnée disponible';

  @override
  String get emailCopied => 'Email copié';

  @override
  String get phoneCopied => 'Téléphone copié';

  @override
  String get openWhatsapp => 'Ouvrir WhatsApp';

  @override
  String get communication => 'Communication';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Téléphone';

  @override
  String get whatsappNumber => 'Numéro WhatsApp';

  @override
  String get public => 'Public';

  @override
  String get familyOnly => 'Famille uniquement';

  @override
  String get private => 'Privé';

  @override
  String get familyEmailSubject => 'Bonjour de la famille';

  @override
  String get familyEmailBody =>
      'Bonjour,\n\nJe vous contacte depuis l\'application FamilyTreeApp.\n\nCordialement.';

  @override
  String get familyWhatsappMessage => 'Bonjour depuis FamilyTreeApp';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyPerson => 'Notifier cette personne';

  @override
  String get sendNotification => 'Envoyer la notification';

  @override
  String get notificationChannel => 'Canal de notification';

  @override
  String get localNotification => 'Rappel local';

  @override
  String get emailNotification => 'Email';

  @override
  String get whatsappNotification => 'WhatsApp';

  @override
  String get scheduleReminder => 'Programmer un rappel';

  @override
  String get customMessage => 'Message personnalisé';

  @override
  String get birthdayReminder => 'Rappel d\'anniversaire';

  @override
  String get deathAnniversaryReminder => 'Rappel de décès';

  @override
  String get familyMeetingReminder => 'Réunion familiale';

  @override
  String get linkRequestReminder => 'Demande de lien familial';

  @override
  String get notificationSent => 'Notification préparée';

  @override
  String get notificationFailed => 'Notification échouée';

  @override
  String get notificationScheduled => 'Rappel programmé';

  @override
  String get notificationPermissionRequired =>
      'Permission de notification requise';

  @override
  String get futurePushNotification => 'Push futur';

  @override
  String get noBackendPushNotice =>
      'Les vraies notifications push à distance nécessitent un backend. Cette version locale prépare email/WhatsApp et programme des rappels locaux.';

  @override
  String get notificationExternalAppNotice =>
      'Email et WhatsApp ouvrent une application externe après confirmation.';

  @override
  String get copy => 'Copier';

  @override
  String get enterAccessCode => 'Entrer le code d\'accès';

  @override
  String get logout => 'Déconnexion';

  @override
  String get publicLimitedMode => 'Mode public limité';

  @override
  String get publicLimitedModeDescription =>
      'Entrez le code d\'accès pour afficher les informations privées de la famille.';

  @override
  String get publicMode => 'Mode public';

  @override
  String get publicMapLocation => 'Lieu public sur la carte';

  @override
  String get showMapInPublicMode => 'Afficher la carte en mode public';

  @override
  String get showBirthPlaceInPublicMode =>
      'Autoriser le lieu de naissance public';

  @override
  String get showCurrentAddressInPublicMode =>
      'Autoriser l\'adresse actuelle publique';

  @override
  String get showContactInPublicMode => 'Autoriser les contacts publics';

  @override
  String get showHistoryInPublicMode => 'Autoriser l\'historique public';

  @override
  String get totalMembersTitle => 'Total des membres';

  @override
  String get visiblePeopleCount => 'personnes visibles';

  @override
  String get adminDashboard => 'Admin familial';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get admin => 'Admin';

  @override
  String get modificationCode => 'Code de modification';

  @override
  String get enterModificationCode => 'Entrer un code de modification';

  @override
  String get modificationCodeRequired => 'Code de modification requis';

  @override
  String get modificationCodeRequiredMessage =>
      'Pour ajouter ou modifier une personne, vous devez obtenir un code de modification auprès d’un administrateur familial.';

  @override
  String get invalidModificationCode => 'Code de modification incorrect';

  @override
  String get validModificationCode => 'Code de modification accepté';

  @override
  String get contactAdmin => 'Contacter un admin';

  @override
  String get contactAdmins => 'Contacter les admins';

  @override
  String get adminContactMessage =>
      'Bonjour, je souhaite obtenir un code de modification pour FamilyTreeApp.';

  @override
  String get manageAdmins => 'Gestion des admins';

  @override
  String get manageModificationCodes => 'Gestion des codes de modification';

  @override
  String get activeCodes => 'Codes actifs';

  @override
  String get expiredCodes => 'Codes expirés';

  @override
  String get usedCodes => 'Codes utilisés';

  @override
  String get adminKpi => 'KPI Admin';

  @override
  String get activityLog => 'Journal d’activité';

  @override
  String get codeCreated => 'Code créé';

  @override
  String get codeDisabled => 'Code désactivé';

  @override
  String get personAddedThisMonth => 'Personnes ajoutées ce mois-ci';

  @override
  String get personModifiedThisMonth => 'Personnes modifiées ce mois-ci';

  @override
  String get familyRelationships => 'Relations familiales';

  @override
  String get father => 'Père';

  @override
  String get mother => 'Mère';

  @override
  String get marriedTo => 'Marié(e) à';

  @override
  String get spouse => 'Conjoint';

  @override
  String get husband => 'Époux';

  @override
  String get wife => 'Épouse';

  @override
  String get wives => 'Épouses';

  @override
  String get siblings => 'Frères et sœurs';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get unknownGender => 'Non renseigné';

  @override
  String get polygamy => 'Polygamie';

  @override
  String get monogamy => 'Monogamie';

  @override
  String get customaryMarriage => 'Mariage coutumier';

  @override
  String get traditionalMarriage => 'Mariage coutumier';

  @override
  String get civilMarriage => 'Mariage civil';

  @override
  String get religiousMarriage => 'Mariage religieux';

  @override
  String get marriageType => 'Type de mariage';

  @override
  String get unionType => 'Type d’union';

  @override
  String get addUnion => 'Ajouter une union';

  @override
  String get traditionalMarriageDate => 'Date du mariage coutumier';

  @override
  String get marriagePlace => 'Lieu du mariage';

  @override
  String get marriageStatus => 'Statut du mariage';

  @override
  String get activeUnion => 'Union active';

  @override
  String get freeUnion => 'Union libre';

  @override
  String get endedByDeath => 'Union terminée par décès';

  @override
  String get maritalStatus => 'Statut matrimonial';

  @override
  String get activeMarriage => 'Mariage actif';

  @override
  String get separated => 'Séparé';

  @override
  String get divorced => 'Divorcé(e)';

  @override
  String get divorce => 'Divorce';

  @override
  String get declareDivorce => 'Déclarer un divorce';

  @override
  String get divorceDate => 'Date du divorce';

  @override
  String get formerSpouse => 'Ancien(ne) conjoint(e)';

  @override
  String get formerSpouses => 'Anciens conjoints';

  @override
  String get restoreMarriage => 'Annuler le divorce';

  @override
  String get divorceHistory => 'Historique matrimonial';

  @override
  String get widowed => 'Veuf / veuve';

  @override
  String get invalidRelationship =>
      'Relation incohérente : une personne ne peut pas être son propre parent, conjoint ou enfant.';

  @override
  String get addFather => 'Ajouter le père';

  @override
  String get addMother => 'Ajouter la mère';

  @override
  String get addParents => 'Ajouter les parents';

  @override
  String get addChild => 'Ajouter un enfant';

  @override
  String get addChildren => 'Ajouter plusieurs enfants';

  @override
  String get addSibling => 'Ajouter un frère ou une sœur';

  @override
  String get addBrother => 'Ajouter un frère';

  @override
  String get addSister => 'Ajouter une sœur';

  @override
  String get addSpouse => 'Ajouter un(e) conjoint(e)';

  @override
  String get linkExistingPerson => 'Lier une personne existante';

  @override
  String get viewProfile => 'Voir la fiche';

  @override
  String get editPerson => 'Modifier la personne';

  @override
  String get deletePerson => 'Supprimer la personne';

  @override
  String get addHistoricalEvent => 'Ajouter un événement historique';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String get copyInformation => 'Copier les informations';

  @override
  String get latestChanges => 'Dernières modifications';

  @override
  String get newPeopleAdded => 'Nouvelles personnes ajoutées';

  @override
  String get newModifications => 'Nouvelles modifications';

  @override
  String get modifiedBy => 'Modifié par';

  @override
  String get addedBy => 'Ajouté par';

  @override
  String get updatedBy => 'Mis à jour par';

  @override
  String get deletedBy => 'Supprimé par';

  @override
  String get viewHistory => 'Voir l’historique';

  @override
  String get markAsSeen => 'J’ai vu';

  @override
  String get doNotShowAgain => 'Ne plus afficher';

  @override
  String get modificationHistory => 'Historique des modifications';

  @override
  String get personAdded => 'Personne ajoutée';

  @override
  String get personUpdated => 'Personne modifiée';

  @override
  String get personDeleted => 'Personne supprimée';

  @override
  String get relationshipAdded => 'Lien familial ajouté';

  @override
  String get historyRetention => 'Conservation de l’historique';

  @override
  String get historyDeletedAfterThreeMonths =>
      'Historique supprimé après trois mois';

  @override
  String get adminAccessCode => 'Code admin';

  @override
  String get enterAdminCode => 'Entrer le code admin';

  @override
  String get invalidAdminCode => 'Code admin incorrect';

  @override
  String get forgotCode => 'Code oublié ?';

  @override
  String get superAdminRecovery => 'Réinitialisation Super Admin';

  @override
  String get enterSuperAdminRecoveryCode => 'Entrer le code secret Super Admin';

  @override
  String get resetCodes => 'Réinitialiser les codes';

  @override
  String get resetAllCodes => 'Régénérer automatiquement tous les codes';

  @override
  String get generateNewCodes => 'Créer les nouveaux codes';

  @override
  String get recoveryCodeInvalid => 'Code secret Super Admin incorrect';

  @override
  String get recoveryCodeAccepted => 'Code secret Super Admin accepté';

  @override
  String get codesResetSuccess => 'Codes réinitialisés avec succès';

  @override
  String get confirmResetCodes =>
      'Confirmer la réinitialisation des codes ? Une sauvegarde JSON sera créée avant modification.';

  @override
  String get adminKpiAccess => 'Accès Admin / KPI';

  @override
  String get adminSecurity => 'Sécurité admin';

  @override
  String get changeAdminCode => 'Modifier le code admin';

  @override
  String get currentAdminCode => 'Code admin actuel';

  @override
  String get oldAdminCode => 'Ancien code admin';

  @override
  String get newAdminCode => 'Nouveau code admin';

  @override
  String get confirmNewAdminCode => 'Confirmer le nouveau code';

  @override
  String get adminCodeChanged => 'Code admin modifié';

  @override
  String get adminCodeRotationDue => 'Le code admin doit être changé';

  @override
  String get adminCodeRotationLate => 'Changement du code admin en retard';

  @override
  String get nextAdminCodeChange => 'Prochaine modification recommandée';

  @override
  String get lastAdminCodeChange => 'Dernière modification';

  @override
  String get adminCodeHistory => 'Historique des codes admin';

  @override
  String get codeManagement => 'Gestion des codes';

  @override
  String get accessCodes => 'Codes d’accès';

  @override
  String get createAccessCode => 'Créer un code';

  @override
  String get editAccessCode => 'Modifier le code';

  @override
  String get deleteAccessCode => 'Supprimer le code';

  @override
  String get disableAccessCode => 'Désactiver le code';

  @override
  String get enableAccessCode => 'Réactiver le code';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get showCode => 'Afficher le code';

  @override
  String get hideCode => 'Masquer le code';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get codeType => 'Type de code';

  @override
  String get codeRole => 'Rôle du code';

  @override
  String get codeStatus => 'Statut du code';

  @override
  String get codeExpiration => 'Expiration';

  @override
  String get codeUsage => 'Utilisations';

  @override
  String get createdBy => 'Créé par';

  @override
  String get lastUsedAt => 'Dernière utilisation';

  @override
  String get maxUses => 'Nombre maximum d’utilisations';

  @override
  String get generateCode => 'Générer un code';

  @override
  String get manualCode => 'Code manuel';

  @override
  String get familyAccessCode => 'Code d’accès familial';

  @override
  String get adminKpiCode => 'Code Admin KPI';

  @override
  String get linkedFamilyCode => 'Code famille liée';

  @override
  String get branding => 'Branding';

  @override
  String get visualIdentity => 'Identité visuelle';

  @override
  String get familyLogo => 'Logo familial';

  @override
  String get customizeLogo => 'Personnaliser le logo';

  @override
  String get uploadLogo => 'Importer un logo';

  @override
  String get replaceLogo => 'Remplacer le logo';

  @override
  String get deleteLogo => 'Supprimer le logo';

  @override
  String get restoreDefaultLogo => 'Restaurer par défaut';

  @override
  String get logoPreview => 'Aperçu du logo';

  @override
  String get logoPosition => 'Position du logo';

  @override
  String get logoSize => 'Taille du logo';

  @override
  String get logoShape => 'Forme du logo';

  @override
  String get showLogo => 'Afficher le logo';

  @override
  String get hideLogo => 'Masquer le logo';

  @override
  String get showMemberCountOnLogo => 'Affichage du compteur de membres';

  @override
  String get useLogoAsFavicon => 'Utiliser comme favicon';

  @override
  String get logoUpdated => 'Logo mis à jour avec succès';

  @override
  String get invalidLogoFile => 'Fichier logo invalide';

  @override
  String get logoFileTooLarge => 'Le fichier logo est trop volumineux';

  @override
  String get brandingPermissionRequired => 'Permission branding requise';

  @override
  String get linkedFamilyTree => 'Arbre familial lié';

  @override
  String get openLinkedFamilyTree => 'Ouvrir l\'arbre familial lié';

  @override
  String get originFamilyTree => 'Arbre de la famille d\'origine';

  @override
  String get familyOfOrigin => 'Famille d\'origine';

  @override
  String get linkedBranch => 'Branche liée';

  @override
  String get openFamilyBranch => 'Ouvrir la branche familiale';

  @override
  String get backToMainTree => 'Retour à l\'arbre principal';

  @override
  String get mainFamilyTree => 'Arbre familial principal';

  @override
  String get familyBreadcrumb => 'Fil d\'Ariane familial';

  @override
  String get linkedTreeAvailable => 'Arbre lié disponible';

  @override
  String get noLinkedTree => 'Aucun arbre lié';

  @override
  String get manageLinkedTrees => 'Gérer les arbres liés';

  @override
  String get treeBridgePerson => 'Personne passerelle';

  @override
  String get temporaryCode => 'Code temporaire';

  @override
  String get codeUpdated => 'Code modifié';

  @override
  String get codeDeleted => 'Code supprimé';

  @override
  String get codeEnabled => 'Code réactivé';

  @override
  String get codeAlreadyExists => 'Ce code existe déjà';

  @override
  String get regenerateCode => 'Régénérer';

  @override
  String get confirmRegenerateCode =>
      'Voulez-vous régénérer ce code ? L’ancien code sera désactivé.';

  @override
  String get codeRegenerated => 'Nouveau code généré avec succès.';

  @override
  String get newGeneratedCode => 'Nouveau code généré';

  @override
  String get copyNewCode => 'Copier le nouveau code';

  @override
  String get oldCodeDisabled => 'L’ancien code a été désactivé.';

  @override
  String get previousCode => 'Code précédent';

  @override
  String get replacedByCode => 'Remplacé par le code';

  @override
  String get regeneratedAt => 'Régénéré le';

  @override
  String get familyHonor => 'Honneur familial';

  @override
  String get patriarch => 'Patriarche';

  @override
  String get patriarchBadge => 'Badge patriarche';

  @override
  String get selectPatriarch => 'Choisir le patriarche';

  @override
  String get showPatriarchBadge => 'Afficher le badge patriarche';

  @override
  String get badgePosition => 'Position du badge';

  @override
  String get badgeStyle => 'Style du badge';

  @override
  String get viewPatriarchProfile => 'Voir la fiche du patriarche';

  @override
  String get familyDistinctions => 'Distinctions familiales';

  @override
  String get leader => 'Chef';

  @override
  String get currentLeader => 'Chef actuel';

  @override
  String get familyLeader => 'Chef de famille';

  @override
  String get familyChief => 'Chef familial';

  @override
  String get matriarch => 'Matriarche';

  @override
  String get viewLeaderProfile => 'Voir la fiche du chef actuel';

  @override
  String get chiefTitle => 'Titre du chef';

  @override
  String get showLeaderInTopBar => 'Afficher le chef dans la TopBar';

  @override
  String get showLeaderBanner => 'Afficher la bannière du chef de famille';

  @override
  String get showLeaderPhoto => 'Afficher la photo / avatar';

  @override
  String get topBarLogoMode => 'Mode logo TopBar';

  @override
  String get classicLogo => 'Logo classique';

  @override
  String get logoAndLeader => 'Logo + chef actuel';

  @override
  String get leaderOnly => 'Chef actuel seul';

  @override
  String get currentChief => 'Chef actuel';

  @override
  String get formerChief => 'Ancien chef';

  @override
  String get successor => 'Héritier désigné';

  @override
  String get familyLeadership => 'Direction familiale';

  @override
  String get leadershipHistory => 'Chronologie des chefs';

  @override
  String get familyHonorHall => 'Personnalités familiales';

  @override
  String get appointLeader => 'Nommer un chef';

  @override
  String get removeLeader => 'Retirer le chef';

  @override
  String get chiefSince => 'Chef depuis';

  @override
  String get bugReports => 'Bugs signalés';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String get bugTitle => 'Titre du bug';

  @override
  String get bugDescription => 'Description';

  @override
  String get bugScreen => 'Écran concerné';

  @override
  String get bugPriority => 'Priorité';

  @override
  String get bugStatus => 'Statut du bug modifié';

  @override
  String get reportedBy => 'Déclarant';

  @override
  String get reportedAt => 'Signalé le';

  @override
  String get notifyAdminsWhatsapp => 'Notifier les admins par WhatsApp';

  @override
  String get bugOpen => 'Ouvert';

  @override
  String get bugInProgress => 'En cours';

  @override
  String get bugResolved => 'Résolu';

  @override
  String get bugDeleted => 'Supprimé';

  @override
  String get deleteBugReport => 'Supprimer le bug';

  @override
  String get confirmDeleteBugReport => 'Voulez-vous supprimer ce bug ?';

  @override
  String get bugReportCreated => 'Bug signalé.';

  @override
  String get adminWhatsappNotification =>
      'WhatsApp s’ouvrira avec un message prérempli. Chaque admin devra valider l’envoi.';

  @override
  String get generation => 'Génération';

  @override
  String get generations => 'Générations';

  @override
  String get generationNumber => 'Numéro de génération';

  @override
  String get rootAncestor => 'Ancêtre racine';

  @override
  String get firstAncestor => 'Premier ancêtre';

  @override
  String get recalculateGenerations => 'Recalculer toutes les générations';

  @override
  String get showGenerationBadges => 'Afficher les badges de génération';

  @override
  String get allGenerations => 'Toutes les générations';

  @override
  String get storageMode => 'Mode de stockage';

  @override
  String get jsonOnly => 'JSON uniquement';

  @override
  String get databaseOnly => 'Base uniquement';

  @override
  String get hybridStorage => 'Stockage hybride';

  @override
  String get syncStatus => 'Statut de synchronisation';

  @override
  String get synced => 'Synchronisé';

  @override
  String get offline => 'Hors ligne';

  @override
  String get syncPending => 'Synchronisation en attente';

  @override
  String get syncInProgress => 'Synchronisation en cours';

  @override
  String get syncError => 'Erreur de synchronisation';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get lastSyncAt => 'Dernière synchronisation';

  @override
  String get pendingOperations => 'Opérations en attente';

  @override
  String get conflictDetected => 'Conflit détecté';

  @override
  String get keepLocalVersion => 'Garder version locale';

  @override
  String get keepRemoteVersion => 'Garder version distante';

  @override
  String get mergeManually => 'Fusionner manuellement';
}
