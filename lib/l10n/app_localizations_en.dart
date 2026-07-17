// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FamilyTreeApp';

  @override
  String get applicationTitle => 'Application name';

  @override
  String get applicationSubtitle => 'Subtitle';

  @override
  String get showApplicationSubtitle => 'Show subtitle';

  @override
  String get editApplicationTitle => 'Edit application title';

  @override
  String get applicationSettings => 'Application settings';

  @override
  String get officialFamilyName => 'Official family name';

  @override
  String get treeInitialZoom => 'Initial tree zoom';

  @override
  String get rememberLastZoom => 'Remember last zoom';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: '0 members',
    );
    return '$_temp0';
  }

  @override
  String totalMembers(int count) {
    return 'Total: $count';
  }

  @override
  String get showMembersCounter => 'Show members counter in the bottom bar';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get help => 'Help';

  @override
  String get helpAndTutorial => 'Help and tutorial';

  @override
  String get showTutorial => 'Show tutorial button';

  @override
  String get hideTutorial => 'Hide tutorial';

  @override
  String get nextStep => 'Next';

  @override
  String get previousStep => 'Previous';

  @override
  String get finishTutorial => 'Finish';

  @override
  String get skipTutorial => 'Skip';

  @override
  String get firstLaunchTutorial => 'Show tutorial on first launch';

  @override
  String get treeLegend => 'Legend';

  @override
  String get howToUse => 'How to use the tree';

  @override
  String get tutorialWelcomeTitle => 'Welcome to the family tree';

  @override
  String get tutorialMoveTitle => 'Move';

  @override
  String get tutorialMoveBody => 'Click and drag to move the tree.';

  @override
  String get tutorialZoomTitle => 'Zoom';

  @override
  String get tutorialZoomBody =>
      'Use the + and - buttons. Ctrl + mouse wheel can also zoom.';

  @override
  String get tutorialInfoTitle => 'Information';

  @override
  String get tutorialInfoBody =>
      'Hover over a person to view their information.';

  @override
  String get tutorialContextMenuTitle => 'Context menu';

  @override
  String get tutorialContextMenuBody =>
      'Right-click a person to add, edit, print a branch, or view history.';

  @override
  String get tutorialAccessCodesTitle => 'Access codes';

  @override
  String get tutorialAccessCodesBody =>
      'Some actions require a modification code.';

  @override
  String get tutorialMapTitle => 'Map';

  @override
  String get tutorialMapBody => 'Click the location icon to open Google Maps.';

  @override
  String get tutorialNotificationsTitle => 'Notifications';

  @override
  String get tutorialNotificationsBody => 'New changes appear automatically.';

  @override
  String get married => 'Married';

  @override
  String get knownPlace => 'Known place';

  @override
  String get loginTitle => 'Family sign in';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get autoLanguage => 'Automatic language';

  @override
  String get detectedLanguage => 'Detected language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get german => 'German';

  @override
  String get familyCode => 'Family code';

  @override
  String get enter => 'Enter';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get addPerson => 'Add person';

  @override
  String get importJson => 'Import JSON';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get familyTree => 'Tree';

  @override
  String get personDetails => 'Person details';

  @override
  String get birthDate => 'Birth date';

  @override
  String get birthPlace => 'Birth place';

  @override
  String get deathDate => 'Death date';

  @override
  String get deathPlace => 'Death place';

  @override
  String get parents => 'Parents';

  @override
  String get spouses => 'Spouses';

  @override
  String get children => 'Children';

  @override
  String get directChildren => 'Direct children';

  @override
  String get totalDescendants => 'Total descendants';

  @override
  String get descendants => 'Descendants';

  @override
  String get childrenCount => 'Children count';

  @override
  String get familyHistory => 'Family history';

  @override
  String get ourHistory => 'Our Story';

  @override
  String get historyOfFamily => 'History of the family';

  @override
  String get generalFamilyHistory => 'General family history';

  @override
  String get viewFamilyHistory => 'View the general family history';

  @override
  String get editFamilyHistory => 'Edit family history';

  @override
  String get linkedFamilyHistory => 'Linked family history';

  @override
  String get historyContent => 'History content';

  @override
  String get historyTitle => 'History title';

  @override
  String get characterLimit => 'Character limit';

  @override
  String get charactersRemaining => 'Characters remaining';

  @override
  String get characterLimitExceeded => 'The character limit has been exceeded.';

  @override
  String get lastUpdatedBy => 'Last updated by';

  @override
  String get lastUpdatedAt => 'Last updated at';

  @override
  String get familyCouncil => 'Family council';

  @override
  String get councilMembers => 'Council members';

  @override
  String get councilMember => 'Council member';

  @override
  String get roleInCouncil => 'Role in council';

  @override
  String get residencePlace => 'Residence place';

  @override
  String get contactCouncilMember => 'Contact council member';

  @override
  String get viewCouncilMembers => 'View family council members';

  @override
  String get addCouncilMember => 'Add council member';

  @override
  String get editCouncilMember => 'Edit council member';

  @override
  String get deleteCouncilMember => 'Delete council member';

  @override
  String get councilDescription => 'Members who support the family chief.';

  @override
  String get chiefCouncil => 'Chief council';

  @override
  String get infoNews => 'Information';

  @override
  String get infoNewsManagement => 'Information / News';

  @override
  String get addInfoNews => 'Add information';

  @override
  String get editInfoNews => 'Edit information';

  @override
  String get deleteInfoNews => 'Delete information';

  @override
  String get infoNewsTitle => 'Information title';

  @override
  String get infoNewsMessage => 'Short message';

  @override
  String get infoNewsActive => 'Active information';

  @override
  String get priority => 'Priority';

  @override
  String get startAt => 'Display start';

  @override
  String get endAt => 'Display end';

  @override
  String get sendToContacts => 'Send to available contacts';

  @override
  String get sendViaWhatsApp => 'Send via WhatsApp';

  @override
  String get infoNewsSendLog => 'Send log';

  @override
  String get whatsappManualNotice =>
      'WhatsApp will open with a prefilled message. The admin must confirm sending.';

  @override
  String get freeWhatsAppQueue =>
      'Free send queue: WhatsApp opens with a prefilled message, then the admin confirms manually.';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get markAsSent => 'Mark as sent';

  @override
  String get skipContact => 'Skip this contact';

  @override
  String get nextContact => 'Next';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get whatsappOpened => 'WhatsApp opened';

  @override
  String get sent => 'Sent';

  @override
  String get failed => 'Failed';

  @override
  String get skipped => 'Skipped';

  @override
  String get historyCleanupNotice =>
      'Histories older than 3 months are automatically deleted.';

  @override
  String get autoHistoryCleanup => 'Automatic history cleanup';

  @override
  String get deleteOldHistoriesNow => 'Delete old histories now';

  @override
  String get confirmDeleteOldHistories =>
      'Do you want to delete send histories older than 3 months now?';

  @override
  String get historiesKept => 'Histories kept';

  @override
  String get lastCleanup => 'Last cleanup';

  @override
  String get autoCleanupNotifications =>
      'Automatic notification cleanup after 1 week';

  @override
  String get autoCleanupKpiActivityLogs =>
      'Automatic KPI activity log cleanup after 3 months';

  @override
  String get deletedItems => 'Deleted items';

  @override
  String get cleanNow => 'Clean now';

  @override
  String get confirmDataCleanup =>
      'Do you want to clean old notifications and old KPI activity logs now?';

  @override
  String get notificationAdminOnly =>
      'Only administrators are allowed to send notifications.';

  @override
  String get history => 'History';

  @override
  String get notes => 'Notes';

  @override
  String get linkedFamilies => 'Linked families';

  @override
  String get addFamilyCode => 'Add family code';

  @override
  String get requestFamilyLink => 'Request family link';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get refused => 'Refused';

  @override
  String get viewer => 'Viewer';

  @override
  String get editor => 'Editor';

  @override
  String get owner => 'Owner';

  @override
  String get preview => 'Preview';

  @override
  String get viewFullProfile => 'View full profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get search => 'Search';

  @override
  String get familyLinks => 'Family links';

  @override
  String get relationshipType => 'Relationship type';

  @override
  String get marriage => 'Marriage';

  @override
  String get parent => 'Parent';

  @override
  String get child => 'Child';

  @override
  String get adoption => 'Adoption';

  @override
  String get alliance => 'Alliance';

  @override
  String get commonAncestor => 'Common ancestor';

  @override
  String get other => 'Other';

  @override
  String get backupCreated => 'Safety backup created';

  @override
  String get importError => 'Import error';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get people => 'People';

  @override
  String get familiesCount => 'Linked families';

  @override
  String get pendingCount => 'Pending requests';

  @override
  String get totalPeople => 'Total people';

  @override
  String get emptyState => 'No data to display';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get bornLastName => 'Birth last name';

  @override
  String get bornAs => 'Born as';

  @override
  String get nee => 'born';

  @override
  String get gender => 'Gender';

  @override
  String get photo => 'Photo';

  @override
  String get familyBranch => 'Family or branch';

  @override
  String get edit => 'Edit';

  @override
  String get details => 'Details';

  @override
  String get noResults => 'No results';

  @override
  String get confirmOverwrite => 'Replace current data?';

  @override
  String get merge => 'Merge';

  @override
  String get replace => 'Replace';

  @override
  String get create => 'Create';

  @override
  String get status => 'Status';

  @override
  String get role => 'Role';

  @override
  String get sourcePerson => 'Source person';

  @override
  String get targetPerson => 'Target person';

  @override
  String get note => 'Note';

  @override
  String get accept => 'Accept';

  @override
  String get refuse => 'Refuse';

  @override
  String get storage => 'Storage';

  @override
  String get readOnly => 'Read only';

  @override
  String get duplicatePerson => 'Probable duplicate detected';

  @override
  String get requiredField => 'Required field';

  @override
  String get requiredFieldsNotice => 'Fields marked with * are required.';

  @override
  String get requiredFieldExplicit => 'This required field must be completed.';

  @override
  String get requiredFieldsMissingTitle => 'Required fields missing';

  @override
  String requiredFieldsMissingMessage(int count, String fields) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Please complete these required fields: $fields.',
      one: 'Please complete this required field: $fields.',
    );
    return '$_temp0';
  }

  @override
  String requiredFieldsMissingSnackbar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count required fields still need to be completed.',
      one: '1 required field still needs to be completed.',
    );
    return '$_temp0';
  }

  @override
  String get profileLoadError => 'Unable to load the person profile.';

  @override
  String get retry => 'Retry';

  @override
  String get moreActions => 'More actions';

  @override
  String get editThisPerson => 'Edit this person';

  @override
  String get viewInTree => 'View in tree';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get notProvided => 'Not provided';

  @override
  String get notProvidedFeminine => 'Not provided';

  @override
  String get branchLabel => 'Branch';

  @override
  String bornOn(String date) {
    return 'Born on $date';
  }

  @override
  String get noChildrenProvided => 'No child provided';

  @override
  String get noSiblingsProvided => 'No sibling provided';

  @override
  String get location => 'Location';

  @override
  String get noLocationAvailable => 'No location available';

  @override
  String get eventsAndPlaces => 'Events and places';

  @override
  String get noHistoryEvents => 'No event to display for now.';

  @override
  String get noHistoryEventsHelp =>
      'Important events for this person will appear here when they are added.';

  @override
  String get noNotes => 'No notes';

  @override
  String get viewMore => 'View more';

  @override
  String get profileProgress => 'Profile progress';

  @override
  String get profileProgressHelp =>
      'Progress is calculated from required fields that are actually completed. Optional fields do not prevent reaching 100%.';

  @override
  String requiredFieldsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields to complete',
      one: '1 field to complete',
      zero: 'All required fields are complete',
    );
    return '$_temp0';
  }

  @override
  String get requiredInfoAlmostDone =>
      'The required information is almost complete';

  @override
  String get completeRequiredInfoHelp =>
      'Complete the required fields to finalize the profile.';

  @override
  String get identity => 'Identity';

  @override
  String get family => 'Family';

  @override
  String get relationships => 'Relationships';

  @override
  String get places => 'Places';

  @override
  String get privacy => 'Privacy';

  @override
  String get existingMember => 'Existing member';

  @override
  String get createMember => 'Create a member';

  @override
  String get existingTreeMember => 'Existing member in the tree';

  @override
  String get parentSelectionRequired =>
      'Selection is required when a parent is provided.';

  @override
  String get unionsAndSpouses => 'Unions and spouses';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get draftSavedNow => 'Draft saved just now';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get manageUnions => 'Manage unions';

  @override
  String get manageChildren => 'Manage children';

  @override
  String get unionRequiredFieldsAppearOnAdd =>
      'Required fields will appear when adding a union.';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'Some changes have not been saved. Do you want to leave without saving?';

  @override
  String get leave => 'Leave';

  @override
  String get informationVisibility => 'Information visibility';

  @override
  String get choosePublicProfileVisibility =>
      'Choose which information is visible on the member\'s public profile.';

  @override
  String get alwaysVisible => 'Always visible';

  @override
  String get hideSensitiveInfo => 'Hide sensitive information';

  @override
  String get restoreDefaultVisibility => 'Restore default settings';

  @override
  String get visible => 'Visible';

  @override
  String get hidden => 'Hidden';

  @override
  String get privateCoordinates => 'Private coordinates';

  @override
  String get familyRelationsVisibilityDescription =>
      'Father, mother, spouses, unions and children.';

  @override
  String get sensitiveVisibilityConfirmation =>
      'This information will be visible on the public profile. Do you want to continue?';

  @override
  String get makeVisible => 'Make visible';

  @override
  String get cancelChangesTooltip => 'Cancel changes';

  @override
  String get cancelChangesTitle => 'Cancel changes?';

  @override
  String get cancelChangesMessage => 'Unsaved changes will be lost.';

  @override
  String get continueEditing => 'Continue editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get unknown => 'Unknown';

  @override
  String get currentAddress => 'Current address';

  @override
  String get locationFilter => 'Location filter';

  @override
  String get filterByLocation => 'Filter by location';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get region => 'Region / prefecture / department';

  @override
  String get birthLocation => 'Birth location';

  @override
  String get deathLocation => 'Death location';

  @override
  String get burialLocation => 'Burial location';

  @override
  String get radiusAroundAddress => 'Radius around an address';

  @override
  String membersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members found',
      one: '1 member found',
      zero: '0 members found',
    );
    return '$_temp0';
  }

  @override
  String get showOnlyResults => 'Show only results';

  @override
  String get highlightResults => 'Highlight results';

  @override
  String get clearFilters => 'Reset filters';

  @override
  String get centerOnPerson => 'Center on person';

  @override
  String get burialPlace => 'Burial place';

  @override
  String get importantPlaces => 'Important places';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get contact => 'Contact';

  @override
  String get sendEmail => 'Send email';

  @override
  String get sendWhatsapp => 'WhatsApp';

  @override
  String get call => 'Call';

  @override
  String get copyEmail => 'Copy email';

  @override
  String get copyPhone => 'Copy phone';

  @override
  String get contactDisabled => 'Contact disabled';

  @override
  String get noContactInformation => 'No contact information available';

  @override
  String get emailCopied => 'Email copied';

  @override
  String get phoneCopied => 'Phone copied';

  @override
  String get openWhatsapp => 'Open WhatsApp';

  @override
  String get communication => 'Communication';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Phone';

  @override
  String get whatsappNumber => 'WhatsApp number';

  @override
  String get public => 'Public';

  @override
  String get familyOnly => 'Family only';

  @override
  String get private => 'Private';

  @override
  String get familyEmailSubject => 'Hello from the family';

  @override
  String get familyEmailBody =>
      'Hello,\n\nI am contacting you from FamilyTreeApp.\n\nBest regards.';

  @override
  String get familyWhatsappMessage => 'Hello from FamilyTreeApp';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyPerson => 'Notify this person';

  @override
  String get sendNotification => 'Send notification';

  @override
  String get notificationChannel => 'Notification channel';

  @override
  String get localNotification => 'Local reminder';

  @override
  String get emailNotification => 'Email';

  @override
  String get whatsappNotification => 'WhatsApp';

  @override
  String get scheduleReminder => 'Schedule reminder';

  @override
  String get customMessage => 'Custom message';

  @override
  String get birthdayReminder => 'Birthday reminder';

  @override
  String get deathAnniversaryReminder => 'Death anniversary reminder';

  @override
  String get familyMeetingReminder => 'Family meeting';

  @override
  String get linkRequestReminder => 'Family link request';

  @override
  String get notificationSent => 'Notification prepared';

  @override
  String get notificationFailed => 'Notification failed';

  @override
  String get notificationScheduled => 'Reminder scheduled';

  @override
  String get notificationPermissionRequired =>
      'Notification permission required';

  @override
  String get futurePushNotification => 'Future push';

  @override
  String get noBackendPushNotice =>
      'Real remote push notifications require a backend. This local version prepares email/WhatsApp and schedules local reminders.';

  @override
  String get notificationExternalAppNotice =>
      'Email and WhatsApp open an external app after confirmation.';

  @override
  String get copy => 'Copy';

  @override
  String get enterAccessCode => 'Enter access code';

  @override
  String get logout => 'Log out';

  @override
  String get publicLimitedMode => 'Limited public mode';

  @override
  String get publicLimitedModeDescription =>
      'Enter the access code to view private family information.';

  @override
  String get publicMode => 'Public mode';

  @override
  String get publicMapLocation => 'Public map location';

  @override
  String get showMapInPublicMode => 'Show map in public mode';

  @override
  String get showBirthPlaceInPublicMode => 'Allow public birth place';

  @override
  String get showCurrentAddressInPublicMode => 'Allow public current address';

  @override
  String get showContactInPublicMode => 'Allow public contact';

  @override
  String get showHistoryInPublicMode => 'Allow public history';

  @override
  String get totalMembersTitle => 'Total Members';

  @override
  String get visiblePeopleCount => 'visible people';

  @override
  String get adminDashboard => 'Family admin';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get admin => 'Admin';

  @override
  String get modificationCode => 'Modification code';

  @override
  String get enterModificationCode => 'Enter modification code';

  @override
  String get modificationCodeRequired => 'Modification code required';

  @override
  String get modificationCodeRequiredMessage =>
      'To add or edit a person, you need a modification code from a family administrator.';

  @override
  String get invalidModificationCode => 'Invalid modification code';

  @override
  String get validModificationCode => 'Modification code accepted';

  @override
  String get contactAdmin => 'Contact admin';

  @override
  String get contactAdmins => 'Contact admins';

  @override
  String get adminContactMessage =>
      'Hello, I would like to get a modification code for FamilyTreeApp.';

  @override
  String get manageAdmins => 'Manage admins';

  @override
  String get manageModificationCodes => 'Manage modification codes';

  @override
  String get activeCodes => 'Active codes';

  @override
  String get expiredCodes => 'Expired codes';

  @override
  String get usedCodes => 'Used codes';

  @override
  String get adminKpi => 'Admin KPI';

  @override
  String get activityLog => 'Activity log';

  @override
  String get codeCreated => 'Code created';

  @override
  String get codeDisabled => 'Code disabled';

  @override
  String get personAddedThisMonth => 'People added this month';

  @override
  String get personModifiedThisMonth => 'People modified this month';

  @override
  String get familyRelationships => 'Family relationships';

  @override
  String get father => 'Father';

  @override
  String get mother => 'Mother';

  @override
  String get marriedTo => 'Married to';

  @override
  String get spouse => 'Spouse';

  @override
  String get husband => 'Husband';

  @override
  String get wife => 'Wife';

  @override
  String get wives => 'Wives';

  @override
  String get siblings => 'Siblings';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get unknownGender => 'Unknown';

  @override
  String get polygamy => 'Polygamy';

  @override
  String get monogamy => 'Monogamy';

  @override
  String get customaryMarriage => 'Customary marriage';

  @override
  String get traditionalMarriage => 'Traditional marriage';

  @override
  String get civilMarriage => 'Civil marriage';

  @override
  String get religiousMarriage => 'Religious marriage';

  @override
  String get marriageType => 'Marriage type';

  @override
  String get unionType => 'Union type';

  @override
  String get addUnion => 'Add union';

  @override
  String get traditionalMarriageDate => 'Traditional marriage date';

  @override
  String get marriagePlace => 'Marriage place';

  @override
  String get marriageStatus => 'Marriage status';

  @override
  String get activeUnion => 'Active union';

  @override
  String get freeUnion => 'Free union';

  @override
  String get endedByDeath => 'Union ended by death';

  @override
  String get maritalStatus => 'Marital status';

  @override
  String get activeMarriage => 'Active marriage';

  @override
  String get separated => 'Separated';

  @override
  String get divorced => 'Divorced';

  @override
  String get divorce => 'Divorce';

  @override
  String get declareDivorce => 'Declare divorce';

  @override
  String get divorceDate => 'Divorce date';

  @override
  String get formerSpouse => 'Former spouse';

  @override
  String get formerSpouses => 'Former spouses';

  @override
  String get restoreMarriage => 'Restore marriage';

  @override
  String get divorceHistory => 'Marriage history';

  @override
  String get widowed => 'Widowed';

  @override
  String get invalidRelationship =>
      'Invalid relationship: a person cannot be their own parent, spouse or child.';

  @override
  String get addFather => 'Add father';

  @override
  String get addMother => 'Add mother';

  @override
  String get addParents => 'Add parents';

  @override
  String get addChild => 'Add child';

  @override
  String get addChildren => 'Add multiple children';

  @override
  String get addSibling => 'Add sibling';

  @override
  String get addBrother => 'Add brother';

  @override
  String get addSister => 'Add sister';

  @override
  String get addSpouse => 'Add spouse';

  @override
  String get linkExistingPerson => 'Link existing person';

  @override
  String get viewProfile => 'View profile';

  @override
  String get editPerson => 'Edit person';

  @override
  String get deletePerson => 'Delete person';

  @override
  String get addHistoricalEvent => 'Add historical event';

  @override
  String get sendMessage => 'Send message';

  @override
  String get copyInformation => 'Copy information';

  @override
  String get latestChanges => 'Latest changes';

  @override
  String get newPeopleAdded => 'New people added';

  @override
  String get newModifications => 'New modifications';

  @override
  String get modifiedBy => 'Modified by';

  @override
  String get addedBy => 'Added by';

  @override
  String get updatedBy => 'Updated by';

  @override
  String get deletedBy => 'Deleted by';

  @override
  String get viewHistory => 'View history';

  @override
  String get markAsSeen => 'I’ve seen it';

  @override
  String get doNotShowAgain => 'Do not show again';

  @override
  String get modificationHistory => 'Modification history';

  @override
  String get personAdded => 'Person added';

  @override
  String get personUpdated => 'Person updated';

  @override
  String get personDeleted => 'Person deleted';

  @override
  String get relationshipAdded => 'Relationship added';

  @override
  String get historyRetention => 'History retention';

  @override
  String get historyDeletedAfterThreeMonths =>
      'History deleted after three months';

  @override
  String get adminAccessCode => 'Admin code';

  @override
  String get enterAdminCode => 'Enter admin code';

  @override
  String get invalidAdminCode => 'Invalid admin code';

  @override
  String get forgotCode => 'Forgot code?';

  @override
  String get superAdminRecovery => 'Super Admin reset';

  @override
  String get enterSuperAdminRecoveryCode => 'Enter Super Admin secret code';

  @override
  String get resetCodes => 'Reset codes';

  @override
  String get resetAllCodes => 'Automatically regenerate all codes';

  @override
  String get generateNewCodes => 'Create new codes';

  @override
  String get recoveryCodeInvalid => 'Invalid Super Admin secret code';

  @override
  String get recoveryCodeAccepted => 'Super Admin secret code accepted';

  @override
  String get codesResetSuccess => 'Codes reset successfully';

  @override
  String get confirmResetCodes =>
      'Confirm code reset? A JSON backup will be created before changes.';

  @override
  String get adminKpiAccess => 'Admin / KPI access';

  @override
  String get adminSecurity => 'Admin security';

  @override
  String get changeAdminCode => 'Change admin code';

  @override
  String get currentAdminCode => 'Current admin code';

  @override
  String get oldAdminCode => 'Old admin code';

  @override
  String get newAdminCode => 'New admin code';

  @override
  String get confirmNewAdminCode => 'Confirm new code';

  @override
  String get adminCodeChanged => 'Admin code changed';

  @override
  String get adminCodeRotationDue => 'The admin code must be changed';

  @override
  String get adminCodeRotationLate => 'Admin code change is overdue';

  @override
  String get nextAdminCodeChange => 'Next recommended change';

  @override
  String get lastAdminCodeChange => 'Last change';

  @override
  String get adminCodeHistory => 'Admin code history';

  @override
  String get codeManagement => 'Code management';

  @override
  String get accessCodes => 'Access codes';

  @override
  String get createAccessCode => 'Create code';

  @override
  String get editAccessCode => 'Edit code';

  @override
  String get deleteAccessCode => 'Delete code';

  @override
  String get disableAccessCode => 'Disable code';

  @override
  String get enableAccessCode => 'Enable code';

  @override
  String get copyCode => 'Copy code';

  @override
  String get showCode => 'Show code';

  @override
  String get hideCode => 'Hide code';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get codeType => 'Code type';

  @override
  String get codeRole => 'Code role';

  @override
  String get codeStatus => 'Code status';

  @override
  String get codeExpiration => 'Expiration';

  @override
  String get codeUsage => 'Usage';

  @override
  String get createdBy => 'Created by';

  @override
  String get lastUsedAt => 'Last used';

  @override
  String get maxUses => 'Maximum uses';

  @override
  String get generateCode => 'Generate code';

  @override
  String get manualCode => 'Manual code';

  @override
  String get familyAccessCode => 'Family access code';

  @override
  String get adminKpiCode => 'Admin KPI code';

  @override
  String get linkedFamilyCode => 'Linked family code';

  @override
  String get branding => 'Branding';

  @override
  String get visualIdentity => 'Visual identity';

  @override
  String get familyLogo => 'Family logo';

  @override
  String get customizeLogo => 'Customize logo';

  @override
  String get uploadLogo => 'Upload logo';

  @override
  String get replaceLogo => 'Replace logo';

  @override
  String get deleteLogo => 'Delete logo';

  @override
  String get restoreDefaultLogo => 'Restore default';

  @override
  String get logoPreview => 'Logo preview';

  @override
  String get logoPosition => 'Logo position';

  @override
  String get logoSize => 'Logo size';

  @override
  String get logoShape => 'Logo shape';

  @override
  String get showLogo => 'Show logo';

  @override
  String get hideLogo => 'Hide logo';

  @override
  String get showMemberCountOnLogo => 'Member count display';

  @override
  String get useLogoAsFavicon => 'Use logo as favicon';

  @override
  String get logoUpdated => 'Logo updated successfully';

  @override
  String get invalidLogoFile => 'Invalid logo file';

  @override
  String get logoFileTooLarge => 'Logo file is too large';

  @override
  String get brandingPermissionRequired => 'Branding permission required';

  @override
  String get linkedFamilyTree => 'Linked family tree';

  @override
  String get openLinkedFamilyTree => 'Open linked family tree';

  @override
  String get originFamilyTree => 'Family of origin tree';

  @override
  String get familyOfOrigin => 'Family of origin';

  @override
  String get linkedBranch => 'Linked branch';

  @override
  String get openFamilyBranch => 'Open family branch';

  @override
  String get backToMainTree => 'Back to main tree';

  @override
  String get mainFamilyTree => 'Main family tree';

  @override
  String get familyBreadcrumb => 'Family breadcrumb';

  @override
  String get linkedTreeAvailable => 'Linked tree available';

  @override
  String get noLinkedTree => 'No linked tree';

  @override
  String get manageLinkedTrees => 'Manage linked trees';

  @override
  String get treeBridgePerson => 'Bridge person';

  @override
  String get temporaryCode => 'Temporary code';

  @override
  String get codeUpdated => 'Code updated';

  @override
  String get codeDeleted => 'Code deleted';

  @override
  String get codeEnabled => 'Code enabled';

  @override
  String get codeAlreadyExists => 'This code already exists';

  @override
  String get regenerateCode => 'Regenerate';

  @override
  String get confirmRegenerateCode =>
      'Do you want to regenerate this code? The old code will be disabled.';

  @override
  String get codeRegenerated => 'New code generated successfully.';

  @override
  String get newGeneratedCode => 'New generated code';

  @override
  String get copyNewCode => 'Copy new code';

  @override
  String get oldCodeDisabled => 'The old code has been disabled.';

  @override
  String get previousCode => 'Previous code';

  @override
  String get replacedByCode => 'Replaced by code';

  @override
  String get regeneratedAt => 'Regenerated at';

  @override
  String get familyHonor => 'Family honor';

  @override
  String get patriarch => 'Patriarch';

  @override
  String get patriarchBadge => 'Patriarch badge';

  @override
  String get selectPatriarch => 'Select patriarch';

  @override
  String get showPatriarchBadge => 'Show patriarch badge';

  @override
  String get badgePosition => 'Badge position';

  @override
  String get badgeStyle => 'Badge style';

  @override
  String get viewPatriarchProfile => 'View patriarch profile';

  @override
  String get familyDistinctions => 'Family distinctions';

  @override
  String get leader => 'Leader';

  @override
  String get currentLeader => 'Current leader';

  @override
  String get familyLeader => 'Family leader';

  @override
  String get familyChief => 'Family chief';

  @override
  String get matriarch => 'Matriarch';

  @override
  String get viewLeaderProfile => 'View current leader profile';

  @override
  String get chiefTitle => 'Leader title';

  @override
  String get showLeaderInTopBar => 'Show leader in TopBar';

  @override
  String get showLeaderBanner => 'Show family leader banner';

  @override
  String get showLeaderPhoto => 'Show photo / avatar';

  @override
  String get topBarLogoMode => 'TopBar logo mode';

  @override
  String get classicLogo => 'Classic logo';

  @override
  String get logoAndLeader => 'Logo + current leader';

  @override
  String get leaderOnly => 'Current leader only';

  @override
  String get currentChief => 'Current chief';

  @override
  String get formerChief => 'Former chief';

  @override
  String get successor => 'Designated successor';

  @override
  String get familyLeadership => 'Family leadership';

  @override
  String get leadershipHistory => 'Leadership history';

  @override
  String get familyHonorHall => 'Family honor hall';

  @override
  String get appointLeader => 'Appoint leader';

  @override
  String get removeLeader => 'Remove leader';

  @override
  String get chiefSince => 'Chief since';

  @override
  String get bugReports => 'Reported bugs';

  @override
  String get reportBug => 'Report a bug';

  @override
  String get bugTitle => 'Bug title';

  @override
  String get bugDescription => 'Description';

  @override
  String get bugScreen => 'Affected screen';

  @override
  String get bugPriority => 'Priority';

  @override
  String get bugStatus => 'Bug status updated';

  @override
  String get reportedBy => 'Reported by';

  @override
  String get reportedAt => 'Reported at';

  @override
  String get notifyAdminsWhatsapp => 'Notify admins by WhatsApp';

  @override
  String get bugOpen => 'Open';

  @override
  String get bugInProgress => 'In progress';

  @override
  String get bugResolved => 'Resolved';

  @override
  String get bugDeleted => 'Deleted';

  @override
  String get deleteBugReport => 'Delete bug report';

  @override
  String get confirmDeleteBugReport => 'Do you want to delete this bug report?';

  @override
  String get bugReportCreated => 'Bug report created.';

  @override
  String get adminWhatsappNotification =>
      'WhatsApp will open with a prefilled message. Each admin must confirm sending.';

  @override
  String get generation => 'Generation';

  @override
  String get generations => 'Generations';

  @override
  String get generationNumber => 'Generation number';

  @override
  String get rootAncestor => 'Root ancestor';

  @override
  String get firstAncestor => 'First ancestor';

  @override
  String get recalculateGenerations => 'Recalculate all generations';

  @override
  String get showGenerationBadges => 'Show generation badges';

  @override
  String get allGenerations => 'All generations';

  @override
  String get storageMode => 'Storage mode';

  @override
  String get jsonOnly => 'JSON only';

  @override
  String get databaseOnly => 'Database only';

  @override
  String get hybridStorage => 'Hybrid storage';

  @override
  String get syncStatus => 'Sync status';

  @override
  String get synced => 'Synced';

  @override
  String get offline => 'Offline';

  @override
  String get syncPending => 'Sync pending';

  @override
  String get syncInProgress => 'Sync in progress';

  @override
  String get syncError => 'Sync error';

  @override
  String get syncNow => 'Sync now';

  @override
  String get lastSyncAt => 'Last sync at';

  @override
  String get pendingOperations => 'Pending operations';

  @override
  String get conflictDetected => 'Conflict detected';

  @override
  String get keepLocalVersion => 'Keep local version';

  @override
  String get keepRemoteVersion => 'Keep remote version';

  @override
  String get mergeManually => 'Merge manually';
}
