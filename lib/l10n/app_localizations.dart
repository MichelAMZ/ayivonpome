import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'FamilyTreeApp'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion familiale'**
  String get loginTitle;

  /// No description provided for @familyCode.
  ///
  /// In fr, this message translates to:
  /// **'Code familial'**
  String get familyCode;

  /// No description provided for @enter.
  ///
  /// In fr, this message translates to:
  /// **'Entrer'**
  String get enter;

  /// No description provided for @invalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get invalidCode;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @addPerson.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une personne'**
  String get addPerson;

  /// No description provided for @importJson.
  ///
  /// In fr, this message translates to:
  /// **'Importer JSON'**
  String get importJson;

  /// No description provided for @exportJson.
  ///
  /// In fr, this message translates to:
  /// **'Exporter JSON'**
  String get exportJson;

  /// No description provided for @familyTree.
  ///
  /// In fr, this message translates to:
  /// **'Arbre'**
  String get familyTree;

  /// No description provided for @personDetails.
  ///
  /// In fr, this message translates to:
  /// **'Fiche personne'**
  String get personDetails;

  /// No description provided for @birthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDate;

  /// No description provided for @birthPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de naissance'**
  String get birthPlace;

  /// No description provided for @deathDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de décès'**
  String get deathDate;

  /// No description provided for @deathPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de décès'**
  String get deathPlace;

  /// No description provided for @parents.
  ///
  /// In fr, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @spouses.
  ///
  /// In fr, this message translates to:
  /// **'Conjoints'**
  String get spouses;

  /// No description provided for @children.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get children;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @linkedFamilies.
  ///
  /// In fr, this message translates to:
  /// **'Familles liées'**
  String get linkedFamilies;

  /// No description provided for @addFamilyCode.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un code familial'**
  String get addFamilyCode;

  /// No description provided for @requestFamilyLink.
  ///
  /// In fr, this message translates to:
  /// **'Demander un lien familial'**
  String get requestFamilyLink;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In fr, this message translates to:
  /// **'Accepté'**
  String get accepted;

  /// No description provided for @refused.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get refused;

  /// No description provided for @viewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get viewer;

  /// No description provided for @editor.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get editor;

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get owner;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @viewFullProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir la fiche complète'**
  String get viewFullProfile;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDelete;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @familyLinks.
  ///
  /// In fr, this message translates to:
  /// **'Liens familiaux'**
  String get familyLinks;

  /// No description provided for @relationshipType.
  ///
  /// In fr, this message translates to:
  /// **'Type de lien'**
  String get relationshipType;

  /// No description provided for @marriage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage'**
  String get marriage;

  /// No description provided for @parent.
  ///
  /// In fr, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @child.
  ///
  /// In fr, this message translates to:
  /// **'Enfant'**
  String get child;

  /// No description provided for @adoption.
  ///
  /// In fr, this message translates to:
  /// **'Adoption'**
  String get adoption;

  /// No description provided for @alliance.
  ///
  /// In fr, this message translates to:
  /// **'Alliance'**
  String get alliance;

  /// No description provided for @commonAncestor.
  ///
  /// In fr, this message translates to:
  /// **'Ancêtre commun'**
  String get commonAncestor;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @backupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde de sécurité créée'**
  String get backupCreated;

  /// No description provided for @importError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'import'**
  String get importError;

  /// No description provided for @exportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Export réussi'**
  String get exportSuccess;

  /// No description provided for @people.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get people;

  /// No description provided for @familiesCount.
  ///
  /// In fr, this message translates to:
  /// **'Familles liées'**
  String get familiesCount;

  /// No description provided for @pendingCount.
  ///
  /// In fr, this message translates to:
  /// **'Demandes en attente'**
  String get pendingCount;

  /// No description provided for @totalPeople.
  ///
  /// In fr, this message translates to:
  /// **'Personnes au total'**
  String get totalPeople;

  /// No description provided for @emptyState.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée à afficher'**
  String get emptyState;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @gender.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get gender;

  /// No description provided for @photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @familyBranch.
  ///
  /// In fr, this message translates to:
  /// **'Famille ou branche'**
  String get familyBranch;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @confirmOverwrite.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer les données actuelles ?'**
  String get confirmOverwrite;

  /// No description provided for @merge.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner'**
  String get merge;

  /// No description provided for @replace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get replace;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @sourcePerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne source'**
  String get sourcePerson;

  /// No description provided for @targetPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne cible'**
  String get targetPerson;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @accept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuse;

  /// No description provided for @storage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get storage;

  /// No description provided for @readOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get readOnly;

  /// No description provided for @duplicatePerson.
  ///
  /// In fr, this message translates to:
  /// **'Doublon probable détecté'**
  String get duplicatePerson;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get requiredField;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @currentAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse actuelle'**
  String get currentAddress;

  /// No description provided for @burialPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de sépulture'**
  String get burialPlace;

  /// No description provided for @importantPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Lieux importants'**
  String get importantPlaces;

  /// No description provided for @viewOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Voir sur la carte'**
  String get viewOnMap;

  /// No description provided for @copyAddress.
  ///
  /// In fr, this message translates to:
  /// **'Copier l\'adresse'**
  String get copyAddress;

  /// No description provided for @latitude.
  ///
  /// In fr, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In fr, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @googleMaps.
  ///
  /// In fr, this message translates to:
  /// **'Google Maps'**
  String get googleMaps;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @sendEmail.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un email'**
  String get sendEmail;

  /// No description provided for @sendWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get sendWhatsapp;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @copyEmail.
  ///
  /// In fr, this message translates to:
  /// **'Copier l\'email'**
  String get copyEmail;

  /// No description provided for @copyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Copier le téléphone'**
  String get copyPhone;

  /// No description provided for @contactDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Contact désactivé'**
  String get contactDisabled;

  /// No description provided for @noContactInformation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune coordonnée disponible'**
  String get noContactInformation;

  /// No description provided for @emailCopied.
  ///
  /// In fr, this message translates to:
  /// **'Email copié'**
  String get emailCopied;

  /// No description provided for @phoneCopied.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone copié'**
  String get phoneCopied;

  /// No description provided for @openWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir WhatsApp'**
  String get openWhatsapp;

  /// No description provided for @communication.
  ///
  /// In fr, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phoneNumber;

  /// No description provided for @whatsappNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp'**
  String get whatsappNumber;

  /// No description provided for @public.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @familyOnly.
  ///
  /// In fr, this message translates to:
  /// **'Famille uniquement'**
  String get familyOnly;

  /// No description provided for @private.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get private;

  /// No description provided for @familyEmailSubject.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour de la famille'**
  String get familyEmailSubject;

  /// No description provided for @familyEmailBody.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,\n\nJe vous contacte depuis l\'application FamilyTreeApp.\n\nCordialement.'**
  String get familyEmailBody;

  /// No description provided for @familyWhatsappMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour depuis FamilyTreeApp'**
  String get familyWhatsappMessage;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifyPerson.
  ///
  /// In fr, this message translates to:
  /// **'Notifier cette personne'**
  String get notifyPerson;

  /// No description provided for @sendNotification.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la notification'**
  String get sendNotification;

  /// No description provided for @notificationChannel.
  ///
  /// In fr, this message translates to:
  /// **'Canal de notification'**
  String get notificationChannel;

  /// No description provided for @localNotification.
  ///
  /// In fr, this message translates to:
  /// **'Rappel local'**
  String get localNotification;

  /// No description provided for @emailNotification.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailNotification;

  /// No description provided for @whatsappNotification.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsappNotification;

  /// No description provided for @scheduleReminder.
  ///
  /// In fr, this message translates to:
  /// **'Programmer un rappel'**
  String get scheduleReminder;

  /// No description provided for @customMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message personnalisé'**
  String get customMessage;

  /// No description provided for @birthdayReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel d\'anniversaire'**
  String get birthdayReminder;

  /// No description provided for @deathAnniversaryReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de décès'**
  String get deathAnniversaryReminder;

  /// No description provided for @familyMeetingReminder.
  ///
  /// In fr, this message translates to:
  /// **'Réunion familiale'**
  String get familyMeetingReminder;

  /// No description provided for @linkRequestReminder.
  ///
  /// In fr, this message translates to:
  /// **'Demande de lien familial'**
  String get linkRequestReminder;

  /// No description provided for @notificationSent.
  ///
  /// In fr, this message translates to:
  /// **'Notification préparée'**
  String get notificationSent;

  /// No description provided for @notificationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Notification échouée'**
  String get notificationFailed;

  /// No description provided for @notificationScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Rappel programmé'**
  String get notificationScheduled;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission de notification requise'**
  String get notificationPermissionRequired;

  /// No description provided for @futurePushNotification.
  ///
  /// In fr, this message translates to:
  /// **'Push futur'**
  String get futurePushNotification;

  /// No description provided for @noBackendPushNotice.
  ///
  /// In fr, this message translates to:
  /// **'Les vraies notifications push à distance nécessitent un backend. Cette version locale prépare email/WhatsApp et programme des rappels locaux.'**
  String get noBackendPushNotice;

  /// No description provided for @notificationExternalAppNotice.
  ///
  /// In fr, this message translates to:
  /// **'Email et WhatsApp ouvrent une application externe après confirmation.'**
  String get notificationExternalAppNotice;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @enterAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrer le code d\'accès'**
  String get enterAccessCode;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @publicLimitedMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode public limité'**
  String get publicLimitedMode;

  /// No description provided for @publicLimitedModeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code d\'accès pour afficher les informations privées de la famille.'**
  String get publicLimitedModeDescription;

  /// No description provided for @publicMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode public'**
  String get publicMode;

  /// No description provided for @publicMapLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu public sur la carte'**
  String get publicMapLocation;

  /// No description provided for @showMapInPublicMode.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la carte en mode public'**
  String get showMapInPublicMode;

  /// No description provided for @showBirthPlaceInPublicMode.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le lieu de naissance public'**
  String get showBirthPlaceInPublicMode;

  /// No description provided for @showCurrentAddressInPublicMode.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l\'adresse actuelle publique'**
  String get showCurrentAddressInPublicMode;

  /// No description provided for @showContactInPublicMode.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les contacts publics'**
  String get showContactInPublicMode;

  /// No description provided for @showHistoryInPublicMode.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l\'historique public'**
  String get showHistoryInPublicMode;

  /// No description provided for @familyTreeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Arbre généalogique'**
  String get familyTreeTitle;

  /// No description provided for @visiblePeopleCount.
  ///
  /// In fr, this message translates to:
  /// **'personnes visibles'**
  String get visiblePeopleCount;

  /// No description provided for @adminDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Admin familial'**
  String get adminDashboard;

  /// No description provided for @superAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @modificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de modification'**
  String get modificationCode;

  /// No description provided for @enterModificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrer un code de modification'**
  String get enterModificationCode;

  /// No description provided for @modificationCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Code de modification requis'**
  String get modificationCodeRequired;

  /// No description provided for @modificationCodeRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Pour ajouter ou modifier une personne, vous devez obtenir un code de modification auprès d’un administrateur familial.'**
  String get modificationCodeRequiredMessage;

  /// No description provided for @invalidModificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de modification incorrect'**
  String get invalidModificationCode;

  /// No description provided for @validModificationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de modification accepté'**
  String get validModificationCode;

  /// No description provided for @contactAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Contacter un admin'**
  String get contactAdmin;

  /// No description provided for @contactAdmins.
  ///
  /// In fr, this message translates to:
  /// **'Contacter les admins'**
  String get contactAdmins;

  /// No description provided for @adminContactMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je souhaite obtenir un code de modification pour FamilyTreeApp.'**
  String get adminContactMessage;

  /// No description provided for @manageAdmins.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des admins'**
  String get manageAdmins;

  /// No description provided for @manageModificationCodes.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des codes de modification'**
  String get manageModificationCodes;

  /// No description provided for @activeCodes.
  ///
  /// In fr, this message translates to:
  /// **'Codes actifs'**
  String get activeCodes;

  /// No description provided for @expiredCodes.
  ///
  /// In fr, this message translates to:
  /// **'Codes expirés'**
  String get expiredCodes;

  /// No description provided for @usedCodes.
  ///
  /// In fr, this message translates to:
  /// **'Codes utilisés'**
  String get usedCodes;

  /// No description provided for @adminKpi.
  ///
  /// In fr, this message translates to:
  /// **'KPI Admin'**
  String get adminKpi;

  /// No description provided for @activityLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal d’activité'**
  String get activityLog;

  /// No description provided for @codeCreated.
  ///
  /// In fr, this message translates to:
  /// **'Code créé'**
  String get codeCreated;

  /// No description provided for @codeDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Code désactivé'**
  String get codeDisabled;

  /// No description provided for @personAddedThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Personnes ajoutées ce mois-ci'**
  String get personAddedThisMonth;

  /// No description provided for @personModifiedThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Personnes modifiées ce mois-ci'**
  String get personModifiedThisMonth;

  /// No description provided for @familyRelationships.
  ///
  /// In fr, this message translates to:
  /// **'Relations familiales'**
  String get familyRelationships;

  /// No description provided for @father.
  ///
  /// In fr, this message translates to:
  /// **'Père'**
  String get father;

  /// No description provided for @mother.
  ///
  /// In fr, this message translates to:
  /// **'Mère'**
  String get mother;

  /// No description provided for @marriedTo.
  ///
  /// In fr, this message translates to:
  /// **'Marié(e) à'**
  String get marriedTo;

  /// No description provided for @spouse.
  ///
  /// In fr, this message translates to:
  /// **'Conjoint'**
  String get spouse;

  /// No description provided for @husband.
  ///
  /// In fr, this message translates to:
  /// **'Époux'**
  String get husband;

  /// No description provided for @wife.
  ///
  /// In fr, this message translates to:
  /// **'Épouse'**
  String get wife;

  /// No description provided for @wives.
  ///
  /// In fr, this message translates to:
  /// **'Épouses'**
  String get wives;

  /// No description provided for @siblings.
  ///
  /// In fr, this message translates to:
  /// **'Frères et sœurs'**
  String get siblings;

  /// No description provided for @male.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get male;

  /// No description provided for @female.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get female;

  /// No description provided for @unknownGender.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get unknownGender;

  /// No description provided for @polygamy.
  ///
  /// In fr, this message translates to:
  /// **'Polygamie'**
  String get polygamy;

  /// No description provided for @monogamy.
  ///
  /// In fr, this message translates to:
  /// **'Monogamie'**
  String get monogamy;

  /// No description provided for @customaryMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage coutumier'**
  String get customaryMarriage;

  /// No description provided for @civilMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage civil'**
  String get civilMarriage;

  /// No description provided for @religiousMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage religieux'**
  String get religiousMarriage;

  /// No description provided for @marriageType.
  ///
  /// In fr, this message translates to:
  /// **'Type de mariage'**
  String get marriageType;

  /// No description provided for @marriageStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut du mariage'**
  String get marriageStatus;

  /// No description provided for @activeMarriage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage actif'**
  String get activeMarriage;

  /// No description provided for @separated.
  ///
  /// In fr, this message translates to:
  /// **'Séparé'**
  String get separated;

  /// No description provided for @divorced.
  ///
  /// In fr, this message translates to:
  /// **'Divorcé'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In fr, this message translates to:
  /// **'Veuf / veuve'**
  String get widowed;

  /// No description provided for @invalidRelationship.
  ///
  /// In fr, this message translates to:
  /// **'Relation incohérente : une personne ne peut pas être son propre parent, conjoint ou enfant.'**
  String get invalidRelationship;

  /// No description provided for @addFather.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le père'**
  String get addFather;

  /// No description provided for @addMother.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la mère'**
  String get addMother;

  /// No description provided for @addParents.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter les parents'**
  String get addParents;

  /// No description provided for @addChild.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un enfant'**
  String get addChild;

  /// No description provided for @addChildren.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter plusieurs enfants'**
  String get addChildren;

  /// No description provided for @addSibling.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un frère ou une sœur'**
  String get addSibling;

  /// No description provided for @addBrother.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un frère'**
  String get addBrother;

  /// No description provided for @addSister.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une sœur'**
  String get addSister;

  /// No description provided for @addSpouse.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un(e) conjoint(e)'**
  String get addSpouse;

  /// No description provided for @linkExistingPerson.
  ///
  /// In fr, this message translates to:
  /// **'Lier une personne existante'**
  String get linkExistingPerson;

  /// No description provided for @viewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir la fiche'**
  String get viewProfile;

  /// No description provided for @editPerson.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la personne'**
  String get editPerson;

  /// No description provided for @deletePerson.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la personne'**
  String get deletePerson;

  /// No description provided for @addHistoricalEvent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un événement historique'**
  String get addHistoricalEvent;

  /// No description provided for @sendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get sendMessage;

  /// No description provided for @copyInformation.
  ///
  /// In fr, this message translates to:
  /// **'Copier les informations'**
  String get copyInformation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
