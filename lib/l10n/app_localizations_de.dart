// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FamilyTreeApp';

  @override
  String get applicationTitle => 'Anwendungsname';

  @override
  String get applicationSubtitle => 'Untertitel';

  @override
  String get showApplicationSubtitle => 'Untertitel anzeigen';

  @override
  String get editApplicationTitle => 'Anwendungstitel bearbeiten';

  @override
  String get applicationSettings => 'Anwendungseinstellungen';

  @override
  String get officialFamilyName => 'Offizieller Familienname';

  @override
  String get treeInitialZoom => 'Initialer Baum-Zoom';

  @override
  String get rememberLastZoom => 'Letzten Zoom merken';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
      zero: '0 Mitglieder',
    );
    return '$_temp0';
  }

  @override
  String totalMembers(int count) {
    return 'Gesamt: $count';
  }

  @override
  String get showMembersCounter =>
      'Mitgliederzähler in der unteren Leiste anzeigen';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get help => 'Hilfe';

  @override
  String get helpAndTutorial => 'Hilfe und Tutorial';

  @override
  String get showTutorial => 'Tutorial-Schaltfläche anzeigen';

  @override
  String get hideTutorial => 'Tutorial ausblenden';

  @override
  String get nextStep => 'Weiter';

  @override
  String get previousStep => 'Zurück';

  @override
  String get finishTutorial => 'Fertigstellen';

  @override
  String get skipTutorial => 'Überspringen';

  @override
  String get firstLaunchTutorial => 'Tutorial beim ersten Start anzeigen';

  @override
  String get treeLegend => 'Legende';

  @override
  String get howToUse => 'So verwenden Sie den Baum';

  @override
  String get tutorialWelcomeTitle => 'Willkommen im Stammbaum';

  @override
  String get tutorialMoveTitle => 'Verschieben';

  @override
  String get tutorialMoveBody =>
      'Klicken und ziehen, um den Baum zu verschieben.';

  @override
  String get tutorialZoomTitle => 'Zoom';

  @override
  String get tutorialZoomBody =>
      'Verwenden Sie die Schaltflächen + und -. Strg + Mausrad kann ebenfalls zoomen.';

  @override
  String get tutorialInfoTitle => 'Informationen';

  @override
  String get tutorialInfoBody =>
      'Bewegen Sie den Mauszeiger über eine Person, um Informationen anzuzeigen.';

  @override
  String get tutorialContextMenuTitle => 'Kontextmenü';

  @override
  String get tutorialContextMenuBody =>
      'Klicken Sie mit der rechten Maustaste auf eine Person, um hinzuzufügen, zu bearbeiten, einen Zweig zu drucken oder den Verlauf zu sehen.';

  @override
  String get tutorialAccessCodesTitle => 'Zugangscodes';

  @override
  String get tutorialAccessCodesBody =>
      'Einige Aktionen erfordern einen Änderungscode.';

  @override
  String get tutorialMapTitle => 'Karte';

  @override
  String get tutorialMapBody =>
      'Klicken Sie auf das Standort-Symbol, um Google Maps zu öffnen.';

  @override
  String get tutorialNotificationsTitle => 'Benachrichtigungen';

  @override
  String get tutorialNotificationsBody =>
      'Neue Änderungen werden automatisch angezeigt.';

  @override
  String get married => 'Verheiratet';

  @override
  String get knownPlace => 'Bekannter Ort';

  @override
  String get loginTitle => 'Familienanmeldung';

  @override
  String get chooseLanguage => 'Sprache wählen';

  @override
  String get autoLanguage => 'Automatische Sprache';

  @override
  String get detectedLanguage => 'Erkannte Sprache';

  @override
  String get french => 'Französisch';

  @override
  String get english => 'Englisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get portuguese => 'Portugiesisch';

  @override
  String get german => 'Deutsch';

  @override
  String get familyCode => 'Familiencode';

  @override
  String get enter => 'Eintreten';

  @override
  String get invalidCode => 'Ungültiger Code';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get addPerson => 'Person hinzufügen';

  @override
  String get importJson => 'JSON importieren';

  @override
  String get exportJson => 'JSON exportieren';

  @override
  String get familyTree => 'Baum';

  @override
  String get personDetails => 'Personendetails';

  @override
  String get birthDate => 'Geburtsdatum';

  @override
  String get birthPlace => 'Geburtsort';

  @override
  String get deathDate => 'Sterbedatum';

  @override
  String get deathPlace => 'Sterbeort';

  @override
  String get parents => 'Eltern';

  @override
  String get spouses => 'Ehepartner';

  @override
  String get children => 'Kinder';

  @override
  String get directChildren => 'Direkte Kinder';

  @override
  String get totalDescendants => 'Alle Nachkommen';

  @override
  String get descendants => 'Nachkommen';

  @override
  String get childrenCount => 'Anzahl Kinder';

  @override
  String get familyHistory => 'Familiengeschichte';

  @override
  String get ourHistory => 'Unsere Geschichte';

  @override
  String get historyOfFamily => 'Geschichte der Familie';

  @override
  String get generalFamilyHistory => 'Allgemeine Familiengeschichte';

  @override
  String get viewFamilyHistory => 'Allgemeine Familiengeschichte anzeigen';

  @override
  String get editFamilyHistory => 'Familiengeschichte bearbeiten';

  @override
  String get linkedFamilyHistory => 'Geschichte der verknüpften Familie';

  @override
  String get historyContent => 'Inhalt der Geschichte';

  @override
  String get historyTitle => 'Titel der Geschichte';

  @override
  String get characterLimit => 'Zeichenlimit';

  @override
  String get charactersRemaining => 'Verbleibende Zeichen';

  @override
  String get characterLimitExceeded => 'Das Zeichenlimit wurde überschritten.';

  @override
  String get lastUpdatedBy => 'Zuletzt bearbeitet von';

  @override
  String get lastUpdatedAt => 'Zuletzt bearbeitet am';

  @override
  String get familyCouncil => 'Familienrat';

  @override
  String get councilMembers => 'Ratsmitglieder';

  @override
  String get councilMember => 'Ratsmitglied';

  @override
  String get roleInCouncil => 'Funktion im Rat';

  @override
  String get residencePlace => 'Wohnort';

  @override
  String get contactCouncilMember => 'Ratsmitglied kontaktieren';

  @override
  String get viewCouncilMembers => 'Mitglieder des Familienrats anzeigen';

  @override
  String get addCouncilMember => 'Mitglied hinzufügen';

  @override
  String get editCouncilMember => 'Mitglied bearbeiten';

  @override
  String get deleteCouncilMember => 'Mitglied löschen';

  @override
  String get councilDescription =>
      'Mitglieder, die das Familienoberhaupt begleiten.';

  @override
  String get chiefCouncil => 'Rat des Oberhaupts';

  @override
  String get infoNews => 'Information';

  @override
  String get infoNewsManagement => 'Informationen / Neuigkeiten';

  @override
  String get addInfoNews => 'Information hinzufügen';

  @override
  String get editInfoNews => 'Information bearbeiten';

  @override
  String get deleteInfoNews => 'Information löschen';

  @override
  String get infoNewsTitle => 'Titel der Information';

  @override
  String get infoNewsMessage => 'Kurze Nachricht';

  @override
  String get infoNewsActive => 'Aktive Information';

  @override
  String get priority => 'Priorität';

  @override
  String get startAt => 'Anzeigebeginn';

  @override
  String get endAt => 'Anzeigeende';

  @override
  String get sendToContacts => 'An verfügbare Kontakte senden';

  @override
  String get sendViaWhatsApp => 'Per WhatsApp senden';

  @override
  String get infoNewsSendLog => 'Sendeprotokoll';

  @override
  String get whatsappManualNotice =>
      'WhatsApp wird mit einer vorausgefüllten Nachricht geöffnet. Der Admin muss den Versand bestätigen.';

  @override
  String get freeWhatsAppQueue =>
      'Kostenlose Versandliste: WhatsApp öffnet sich mit einer vorausgefüllten Nachricht, danach bestätigt der Admin manuell.';

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get markAsSent => 'Als gesendet markieren';

  @override
  String get skipContact => 'Kontakt überspringen';

  @override
  String get nextContact => 'Weiter';

  @override
  String get messageCopied => 'Nachricht kopiert';

  @override
  String get whatsappOpened => 'WhatsApp geöffnet';

  @override
  String get sent => 'Gesendet';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get skipped => 'Übersprungen';

  @override
  String get historyCleanupNotice =>
      'Verläufe, die älter als 3 Monate sind, werden automatisch gelöscht.';

  @override
  String get autoHistoryCleanup => 'Automatische Verlaufsbereinigung';

  @override
  String get deleteOldHistoriesNow => 'Alte Verläufe jetzt löschen';

  @override
  String get confirmDeleteOldHistories =>
      'Möchten Sie Versandverläufe, die älter als 3 Monate sind, jetzt löschen?';

  @override
  String get historiesKept => 'Beibehaltene Verläufe';

  @override
  String get lastCleanup => 'Letzte Bereinigung';

  @override
  String get autoCleanupNotifications =>
      'Automatische Benachrichtigungsbereinigung nach 1 Woche';

  @override
  String get autoCleanupKpiActivityLogs =>
      'Automatische KPI-Aktivitätsprotokollbereinigung nach 3 Monaten';

  @override
  String get deletedItems => 'Gelöschte Elemente';

  @override
  String get cleanNow => 'Jetzt bereinigen';

  @override
  String get confirmDataCleanup =>
      'Möchten Sie alte Benachrichtigungen und alte KPI-Aktivitätsprotokolle jetzt bereinigen?';

  @override
  String get notificationAdminOnly =>
      'Nur Administratoren dürfen Benachrichtigungen senden.';

  @override
  String get history => 'Historie';

  @override
  String get notes => 'Notizen';

  @override
  String get linkedFamilies => 'Verknüpfte Familien';

  @override
  String get addFamilyCode => 'Familiencode hinzufügen';

  @override
  String get requestFamilyLink => 'Familienlink anfragen';

  @override
  String get pending => 'Ausstehend';

  @override
  String get accepted => 'Akzeptiert';

  @override
  String get refused => 'Abgelehnt';

  @override
  String get viewer => 'Leser';

  @override
  String get editor => 'Bearbeiter';

  @override
  String get owner => 'Eigentümer';

  @override
  String get preview => 'Vorschau';

  @override
  String get viewFullProfile => 'Vollständiges Profil anzeigen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirmDelete => 'Löschung bestätigen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get search => 'Suchen';

  @override
  String get familyLinks => 'Familienlinks';

  @override
  String get relationshipType => 'Beziehungstyp';

  @override
  String get marriage => 'Ehe';

  @override
  String get parent => 'Elternteil';

  @override
  String get child => 'Kind';

  @override
  String get adoption => 'Adoption';

  @override
  String get alliance => 'Allianz';

  @override
  String get commonAncestor => 'Gemeinsamer Vorfahr';

  @override
  String get other => 'Andere';

  @override
  String get backupCreated => 'Sicherung erstellt';

  @override
  String get importError => 'Importfehler';

  @override
  String get exportSuccess => 'Export erfolgreich';

  @override
  String get people => 'Personen';

  @override
  String get familiesCount => 'Verknüpfte Familien';

  @override
  String get pendingCount => 'Ausstehende Anfragen';

  @override
  String get totalPeople => 'Personen gesamt';

  @override
  String get emptyState => 'Keine Daten vorhanden';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get bornLastName => 'Geburtsname';

  @override
  String get bornAs => 'Geboren als';

  @override
  String get nee => 'geb.';

  @override
  String get gender => 'Geschlecht';

  @override
  String get photo => 'Foto';

  @override
  String get familyBranch => 'Familie oder Zweig';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get details => 'Details';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get confirmOverwrite => 'Aktuelle Daten ersetzen?';

  @override
  String get merge => 'Zusammenführen';

  @override
  String get replace => 'Ersetzen';

  @override
  String get create => 'Erstellen';

  @override
  String get status => 'Status';

  @override
  String get role => 'Rolle';

  @override
  String get sourcePerson => 'Ausgangsperson';

  @override
  String get targetPerson => 'Zielperson';

  @override
  String get note => 'Notiz';

  @override
  String get accept => 'Akzeptieren';

  @override
  String get refuse => 'Ablehnen';

  @override
  String get storage => 'Speicher';

  @override
  String get readOnly => 'Nur lesen';

  @override
  String get duplicatePerson => 'Wahrscheinliches Duplikat erkannt';

  @override
  String get requiredField => 'Pflichtfeld';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get currentAddress => 'Aktuelle Adresse';

  @override
  String get locationFilter => 'Standortfilter';

  @override
  String get filterByLocation => 'Nach Standort filtern';

  @override
  String get country => 'Land';

  @override
  String get city => 'Stadt';

  @override
  String get region => 'Region / Präfektur / Landkreis';

  @override
  String get birthLocation => 'Geburtsort';

  @override
  String get deathLocation => 'Sterbeort';

  @override
  String get burialLocation => 'Bestattungsort';

  @override
  String get radiusAroundAddress => 'Radius um eine Adresse';

  @override
  String membersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder gefunden',
      one: '1 Mitglied gefunden',
      zero: '0 Mitglieder gefunden',
    );
    return '$_temp0';
  }

  @override
  String get showOnlyResults => 'Nur Ergebnisse anzeigen';

  @override
  String get highlightResults => 'Ergebnisse hervorheben';

  @override
  String get clearFilters => 'Filter zurücksetzen';

  @override
  String get centerOnPerson => 'Auf Person zentrieren';

  @override
  String get burialPlace => 'Bestattungsort';

  @override
  String get importantPlaces => 'Wichtige Orte';

  @override
  String get viewOnMap => 'Auf Karte anzeigen';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get latitude => 'Breitengrad';

  @override
  String get longitude => 'Längengrad';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get contact => 'Kontakt';

  @override
  String get sendEmail => 'E-Mail senden';

  @override
  String get sendWhatsapp => 'WhatsApp';

  @override
  String get call => 'Anrufen';

  @override
  String get copyEmail => 'E-Mail kopieren';

  @override
  String get copyPhone => 'Telefon kopieren';

  @override
  String get contactDisabled => 'Kontakt deaktiviert';

  @override
  String get noContactInformation => 'Keine Kontaktdaten verfügbar';

  @override
  String get emailCopied => 'E-Mail kopiert';

  @override
  String get phoneCopied => 'Telefon kopiert';

  @override
  String get openWhatsapp => 'WhatsApp öffnen';

  @override
  String get communication => 'Kommunikation';

  @override
  String get email => 'E-Mail';

  @override
  String get phoneNumber => 'Telefon';

  @override
  String get whatsappNumber => 'WhatsApp-Nummer';

  @override
  String get public => 'Öffentlich';

  @override
  String get familyOnly => 'Nur Familie';

  @override
  String get private => 'Privat';

  @override
  String get familyEmailSubject => 'Hallo von der Familie';

  @override
  String get familyEmailBody =>
      'Hallo,\n\nIch kontaktiere Sie über FamilyTreeApp.\n\nMit freundlichen Grüßen.';

  @override
  String get familyWhatsappMessage => 'Hallo von FamilyTreeApp';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notifyPerson => 'Diese Person benachrichtigen';

  @override
  String get sendNotification => 'Benachrichtigung senden';

  @override
  String get notificationChannel => 'Benachrichtigungskanal';

  @override
  String get localNotification => 'Lokale Erinnerung';

  @override
  String get emailNotification => 'E-Mail';

  @override
  String get whatsappNotification => 'WhatsApp';

  @override
  String get scheduleReminder => 'Erinnerung planen';

  @override
  String get customMessage => 'Eigene Nachricht';

  @override
  String get birthdayReminder => 'Geburtstagserinnerung';

  @override
  String get deathAnniversaryReminder => 'Todestag-Erinnerung';

  @override
  String get familyMeetingReminder => 'Familientreffen';

  @override
  String get linkRequestReminder => 'Familienlink-Anfrage';

  @override
  String get notificationSent => 'Benachrichtigung vorbereitet';

  @override
  String get notificationFailed => 'Benachrichtigung fehlgeschlagen';

  @override
  String get notificationScheduled => 'Erinnerung geplant';

  @override
  String get notificationPermissionRequired =>
      'Benachrichtigungsberechtigung erforderlich';

  @override
  String get futurePushNotification => 'Zukünftiger Push';

  @override
  String get noBackendPushNotice =>
      'Echte Remote-Push-Benachrichtigungen benötigen ein Backend. Diese lokale Version bereitet E-Mail/WhatsApp vor und plant lokale Erinnerungen.';

  @override
  String get notificationExternalAppNotice =>
      'E-Mail und WhatsApp öffnen nach Bestätigung eine externe App.';

  @override
  String get copy => 'Kopieren';

  @override
  String get enterAccessCode => 'Zugangscode eingeben';

  @override
  String get logout => 'Abmelden';

  @override
  String get publicLimitedMode => 'Eingeschränkter öffentlicher Modus';

  @override
  String get publicLimitedModeDescription =>
      'Geben Sie den Zugangscode ein, um private Familieninformationen anzuzeigen.';

  @override
  String get publicMode => 'Öffentlicher Modus';

  @override
  String get publicMapLocation => 'Öffentlicher Kartenort';

  @override
  String get showMapInPublicMode => 'Karte im öffentlichen Modus anzeigen';

  @override
  String get showBirthPlaceInPublicMode => 'Öffentlichen Geburtsort erlauben';

  @override
  String get showCurrentAddressInPublicMode =>
      'Öffentliche aktuelle Adresse erlauben';

  @override
  String get showContactInPublicMode => 'Öffentlichen Kontakt erlauben';

  @override
  String get showHistoryInPublicMode => 'Öffentliche Historie erlauben';

  @override
  String get totalMembersTitle => 'Gesamtmitglieder';

  @override
  String get visiblePeopleCount => 'sichtbare Personen';

  @override
  String get adminDashboard => 'Familienadmin';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get admin => 'Admin';

  @override
  String get modificationCode => 'Änderungscode';

  @override
  String get enterModificationCode => 'Änderungscode eingeben';

  @override
  String get modificationCodeRequired => 'Änderungscode erforderlich';

  @override
  String get modificationCodeRequiredMessage =>
      'Zum Hinzufügen oder Bearbeiten einer Person benötigen Sie einen Änderungscode von einem Familienadministrator.';

  @override
  String get invalidModificationCode => 'Ungültiger Änderungscode';

  @override
  String get validModificationCode => 'Änderungscode akzeptiert';

  @override
  String get contactAdmin => 'Admin kontaktieren';

  @override
  String get contactAdmins => 'Admins kontaktieren';

  @override
  String get adminContactMessage =>
      'Hallo, ich möchte einen Änderungscode für FamilyTreeApp erhalten.';

  @override
  String get manageAdmins => 'Admins verwalten';

  @override
  String get manageModificationCodes => 'Änderungscodes verwalten';

  @override
  String get activeCodes => 'Aktive Codes';

  @override
  String get expiredCodes => 'Abgelaufene Codes';

  @override
  String get usedCodes => 'Verwendete Codes';

  @override
  String get adminKpi => 'Admin KPI';

  @override
  String get activityLog => 'Aktivitätsprotokoll';

  @override
  String get codeCreated => 'Code erstellt';

  @override
  String get codeDisabled => 'Code deaktiviert';

  @override
  String get personAddedThisMonth => 'Diesen Monat hinzugefügt';

  @override
  String get personModifiedThisMonth => 'Diesen Monat geändert';

  @override
  String get familyRelationships => 'Familienbeziehungen';

  @override
  String get father => 'Vater';

  @override
  String get mother => 'Mutter';

  @override
  String get marriedTo => 'Verheiratet mit';

  @override
  String get spouse => 'Ehepartner';

  @override
  String get husband => 'Ehemann';

  @override
  String get wife => 'Ehefrau';

  @override
  String get wives => 'Ehefrauen';

  @override
  String get siblings => 'Geschwister';

  @override
  String get male => 'Männlich';

  @override
  String get female => 'Weiblich';

  @override
  String get unknownGender => 'Nicht angegeben';

  @override
  String get polygamy => 'Polygamie';

  @override
  String get monogamy => 'Monogamie';

  @override
  String get customaryMarriage => 'Traditionelle Ehe';

  @override
  String get civilMarriage => 'Zivile Ehe';

  @override
  String get religiousMarriage => 'Religiöse Ehe';

  @override
  String get marriageType => 'Ehetyp';

  @override
  String get marriageStatus => 'Ehestatus';

  @override
  String get maritalStatus => 'Familienstand';

  @override
  String get activeMarriage => 'Aktive Ehe';

  @override
  String get separated => 'Getrennt';

  @override
  String get divorced => 'Geschieden';

  @override
  String get divorce => 'Scheidung';

  @override
  String get declareDivorce => 'Scheidung eintragen';

  @override
  String get divorceDate => 'Scheidungsdatum';

  @override
  String get formerSpouse => 'Ehemalige(r) Ehepartner(in)';

  @override
  String get formerSpouses => 'Ehemalige Ehepartner';

  @override
  String get restoreMarriage => 'Ehe wiederherstellen';

  @override
  String get divorceHistory => 'Eheverlauf';

  @override
  String get widowed => 'Verwitwet';

  @override
  String get invalidRelationship =>
      'Ungültige Beziehung: Eine Person kann nicht ihr eigener Elternteil, Ehepartner oder Kind sein.';

  @override
  String get addFather => 'Vater hinzufügen';

  @override
  String get addMother => 'Mutter hinzufügen';

  @override
  String get addParents => 'Eltern hinzufügen';

  @override
  String get addChild => 'Kind hinzufügen';

  @override
  String get addChildren => 'Mehrere Kinder hinzufügen';

  @override
  String get addSibling => 'Geschwister hinzufügen';

  @override
  String get addBrother => 'Bruder hinzufügen';

  @override
  String get addSister => 'Schwester hinzufügen';

  @override
  String get addSpouse => 'Ehepartner hinzufügen';

  @override
  String get linkExistingPerson => 'Bestehende Person verknüpfen';

  @override
  String get viewProfile => 'Profil anzeigen';

  @override
  String get editPerson => 'Person bearbeiten';

  @override
  String get deletePerson => 'Person löschen';

  @override
  String get addHistoricalEvent => 'Historisches Ereignis hinzufügen';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get copyInformation => 'Informationen kopieren';

  @override
  String get latestChanges => 'Neueste Änderungen';

  @override
  String get newPeopleAdded => 'Neue Personen hinzugefügt';

  @override
  String get newModifications => 'Neue Änderungen';

  @override
  String get modifiedBy => 'Geändert von';

  @override
  String get addedBy => 'Hinzugefügt von';

  @override
  String get updatedBy => 'Aktualisiert von';

  @override
  String get deletedBy => 'Gelöscht von';

  @override
  String get viewHistory => 'Historie anzeigen';

  @override
  String get markAsSeen => 'Gesehen';

  @override
  String get doNotShowAgain => 'Nicht mehr anzeigen';

  @override
  String get modificationHistory => 'Änderungshistorie';

  @override
  String get personAdded => 'Person hinzugefügt';

  @override
  String get personUpdated => 'Person geändert';

  @override
  String get personDeleted => 'Person gelöscht';

  @override
  String get relationshipAdded => 'Familienbeziehung hinzugefügt';

  @override
  String get historyRetention => 'Historienaufbewahrung';

  @override
  String get historyDeletedAfterThreeMonths =>
      'Historie wird nach drei Monaten gelöscht';

  @override
  String get adminAccessCode => 'Admin-Code';

  @override
  String get enterAdminCode => 'Admin-Code eingeben';

  @override
  String get invalidAdminCode => 'Ungültiger Admin-Code';

  @override
  String get forgotCode => 'Code vergessen?';

  @override
  String get superAdminRecovery => 'Super-Admin-Zurücksetzung';

  @override
  String get enterSuperAdminRecoveryCode =>
      'Geheimen Super-Admin-Code eingeben';

  @override
  String get resetCodes => 'Codes zurücksetzen';

  @override
  String get resetAllCodes => 'Alle Codes automatisch neu generieren';

  @override
  String get generateNewCodes => 'Neue Codes erstellen';

  @override
  String get recoveryCodeInvalid => 'Ungültiger geheimer Super-Admin-Code';

  @override
  String get recoveryCodeAccepted => 'Geheimer Super-Admin-Code akzeptiert';

  @override
  String get codesResetSuccess => 'Codes erfolgreich zurückgesetzt';

  @override
  String get confirmResetCodes =>
      'Zurücksetzen der Codes bestätigen? Vor der Änderung wird ein JSON-Backup erstellt.';

  @override
  String get adminKpiAccess => 'Admin-/KPI-Zugriff';

  @override
  String get adminSecurity => 'Admin-Sicherheit';

  @override
  String get changeAdminCode => 'Admin-Code ändern';

  @override
  String get currentAdminCode => 'Aktueller Admin-Code';

  @override
  String get oldAdminCode => 'Alter Admin-Code';

  @override
  String get newAdminCode => 'Neuer Admin-Code';

  @override
  String get confirmNewAdminCode => 'Neuen Code bestätigen';

  @override
  String get adminCodeChanged => 'Admin-Code geändert';

  @override
  String get adminCodeRotationDue => 'Der Admin-Code muss geändert werden';

  @override
  String get adminCodeRotationLate => 'Admin-Code-Änderung ist überfällig';

  @override
  String get nextAdminCodeChange => 'Nächste empfohlene Änderung';

  @override
  String get lastAdminCodeChange => 'Letzte Änderung';

  @override
  String get adminCodeHistory => 'Admin-Code-Historie';

  @override
  String get codeManagement => 'Codeverwaltung';

  @override
  String get accessCodes => 'Zugriffscodes';

  @override
  String get createAccessCode => 'Code erstellen';

  @override
  String get editAccessCode => 'Code bearbeiten';

  @override
  String get deleteAccessCode => 'Code löschen';

  @override
  String get disableAccessCode => 'Code deaktivieren';

  @override
  String get enableAccessCode => 'Code reaktivieren';

  @override
  String get copyCode => 'Code kopieren';

  @override
  String get showCode => 'Code anzeigen';

  @override
  String get hideCode => 'Code verbergen';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get codeType => 'Codetyp';

  @override
  String get codeRole => 'Coderolle';

  @override
  String get codeStatus => 'Codestatus';

  @override
  String get codeExpiration => 'Ablaufdatum';

  @override
  String get codeUsage => 'Nutzung';

  @override
  String get createdBy => 'Erstellt von';

  @override
  String get lastUsedAt => 'Zuletzt verwendet';

  @override
  String get maxUses => 'Maximale Nutzungen';

  @override
  String get generateCode => 'Code generieren';

  @override
  String get manualCode => 'Manueller Code';

  @override
  String get familyAccessCode => 'Familienzugriffscode';

  @override
  String get adminKpiCode => 'Admin-KPI-Code';

  @override
  String get linkedFamilyCode => 'Verknüpfte-Familie-Code';

  @override
  String get temporaryCode => 'Temporärer Code';

  @override
  String get codeUpdated => 'Code aktualisiert';

  @override
  String get codeDeleted => 'Code gelöscht';

  @override
  String get codeEnabled => 'Code reaktiviert';

  @override
  String get codeAlreadyExists => 'Dieser Code existiert bereits';

  @override
  String get regenerateCode => 'Neu generieren';

  @override
  String get confirmRegenerateCode =>
      'Möchten Sie diesen Code neu generieren? Der alte Code wird deaktiviert.';

  @override
  String get codeRegenerated => 'Neuer Code wurde erfolgreich generiert.';

  @override
  String get newGeneratedCode => 'Neu generierter Code';

  @override
  String get copyNewCode => 'Neuen Code kopieren';

  @override
  String get oldCodeDisabled => 'Der alte Code wurde deaktiviert.';

  @override
  String get previousCode => 'Vorheriger Code';

  @override
  String get replacedByCode => 'Ersetzt durch Code';

  @override
  String get regeneratedAt => 'Neu generiert am';

  @override
  String get familyHonor => 'Familienehre';

  @override
  String get patriarch => 'Patriarch';

  @override
  String get patriarchBadge => 'Patriarchen-Badge';

  @override
  String get selectPatriarch => 'Patriarch auswählen';

  @override
  String get showPatriarchBadge => 'Patriarchen-Badge anzeigen';

  @override
  String get badgePosition => 'Badge-Position';

  @override
  String get badgeStyle => 'Badge-Stil';

  @override
  String get viewPatriarchProfile => 'Profil des Patriarchen anzeigen';

  @override
  String get familyDistinctions => 'Familiäre Auszeichnungen';

  @override
  String get leader => 'Oberhaupt';

  @override
  String get currentLeader => 'Aktuelles Oberhaupt';

  @override
  String get familyLeader => 'Familienoberhaupt';

  @override
  String get familyChief => 'Familienchef';

  @override
  String get matriarch => 'Matriarchin';

  @override
  String get viewLeaderProfile => 'Profil des aktuellen Oberhaupts anzeigen';

  @override
  String get chiefTitle => 'Titel des Oberhaupts';

  @override
  String get showLeaderInTopBar => 'Oberhaupt in der TopBar anzeigen';

  @override
  String get showLeaderBanner => 'Banner des Familienoberhaupts anzeigen';

  @override
  String get showLeaderPhoto => 'Foto / Avatar anzeigen';

  @override
  String get topBarLogoMode => 'TopBar-Logo-Modus';

  @override
  String get classicLogo => 'Klassisches Logo';

  @override
  String get logoAndLeader => 'Logo + aktuelles Oberhaupt';

  @override
  String get leaderOnly => 'Nur aktuelles Oberhaupt';

  @override
  String get currentChief => 'Aktuelles Oberhaupt';

  @override
  String get formerChief => 'Ehemaliges Oberhaupt';

  @override
  String get successor => 'Designierter Nachfolger';

  @override
  String get familyLeadership => 'Familienführung';

  @override
  String get leadershipHistory => 'Chronik der Oberhäupter';

  @override
  String get familyHonorHall => 'Familiäre Persönlichkeiten';

  @override
  String get appointLeader => 'Oberhaupt ernennen';

  @override
  String get removeLeader => 'Oberhaupt entfernen';

  @override
  String get chiefSince => 'Oberhaupt seit';

  @override
  String get bugReports => 'Gemeldete Fehler';

  @override
  String get reportBug => 'Fehler melden';

  @override
  String get bugTitle => 'Fehlertitel';

  @override
  String get bugDescription => 'Beschreibung';

  @override
  String get bugScreen => 'Betroffener Bildschirm';

  @override
  String get bugPriority => 'Priorität';

  @override
  String get bugStatus => 'Fehlerstatus aktualisiert';

  @override
  String get reportedBy => 'Gemeldet von';

  @override
  String get reportedAt => 'Gemeldet am';

  @override
  String get notifyAdminsWhatsapp => 'Admins per WhatsApp benachrichtigen';

  @override
  String get bugOpen => 'Offen';

  @override
  String get bugInProgress => 'In Bearbeitung';

  @override
  String get bugResolved => 'Gelöst';

  @override
  String get bugDeleted => 'Gelöscht';

  @override
  String get deleteBugReport => 'Fehlermeldung löschen';

  @override
  String get confirmDeleteBugReport =>
      'Möchtest du diese Fehlermeldung löschen?';

  @override
  String get bugReportCreated => 'Fehler gemeldet.';

  @override
  String get adminWhatsappNotification =>
      'WhatsApp wird mit einer vorbereiteten Nachricht geöffnet. Jeder Admin muss den Versand bestätigen.';

  @override
  String get generation => 'Generation';

  @override
  String get generations => 'Generationen';

  @override
  String get generationNumber => 'Generationsnummer';

  @override
  String get rootAncestor => 'Stammvorfahr';

  @override
  String get firstAncestor => 'Erster Vorfahr';

  @override
  String get recalculateGenerations => 'Alle Generationen neu berechnen';

  @override
  String get showGenerationBadges => 'Generationsbadges anzeigen';

  @override
  String get allGenerations => 'Alle Generationen';

  @override
  String get storageMode => 'Speichermodus';

  @override
  String get jsonOnly => 'Nur JSON';

  @override
  String get databaseOnly => 'Nur Datenbank';

  @override
  String get hybridStorage => 'Hybrider Speicher';

  @override
  String get syncStatus => 'Synchronisierungsstatus';

  @override
  String get synced => 'Synchronisiert';

  @override
  String get offline => 'Offline';

  @override
  String get syncPending => 'Synchronisierung ausstehend';

  @override
  String get syncInProgress => 'Synchronisierung läuft';

  @override
  String get syncError => 'Synchronisierungsfehler';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get lastSyncAt => 'Letzte Synchronisierung';

  @override
  String get pendingOperations => 'Ausstehende Vorgänge';

  @override
  String get conflictDetected => 'Konflikt erkannt';

  @override
  String get keepLocalVersion => 'Lokale Version behalten';

  @override
  String get keepRemoteVersion => 'Remote-Version behalten';

  @override
  String get mergeManually => 'Manuell zusammenführen';
}
