import 'access_code.dart';
import 'audit_log.dart';
import 'admin_access.dart';
import 'admin_user.dart';
import 'change_notification.dart';
import 'family_code.dart';
import 'family_honor.dart';
import 'family_link.dart';
import 'family_notification.dart';
import 'history_event.dart';
import 'important_place.dart';
import 'marriage_relation.dart';
import 'modification_history.dart';
import 'person.dart';
import 'public_mode_config.dart';
import 'modification_code.dart';

class FamilyTreeData {
  const FamilyTreeData({
    this.appVersion = '1.0.0',
    this.mainFamilyCode = 'ayivon',
    this.publicMode = const PublicModeConfig(),
    this.language = 'fr',
    this.familyHonor = const FamilyHonor(),
    this.familyCodes = const [],
    this.accessCodes = const [],
    this.modificationCodes = const [],
    this.admins = const [],
    this.adminAccess = const AdminAccess(),
    this.people = const [],
    this.familyLinks = const [],
    this.marriageRelations = const [],
    this.notifications = const [],
    this.changeNotifications = const [],
    this.modificationHistory = const [],
    this.auditLog = const [],
  });

  final String appVersion;
  final String mainFamilyCode;
  final PublicModeConfig publicMode;
  final String language;
  final FamilyHonor familyHonor;
  final List<FamilyCode> familyCodes;
  final List<AccessCode> accessCodes;
  final List<ModificationCode> modificationCodes;
  final List<AdminUser> admins;
  final AdminAccess adminAccess;
  final List<Person> people;
  final List<FamilyLink> familyLinks;
  final List<MarriageRelation> marriageRelations;
  final List<FamilyNotification> notifications;
  final List<ChangeNotification> changeNotifications;
  final List<ModificationHistory> modificationHistory;
  final List<AuditLog> auditLog;

  factory FamilyTreeData.fromJson(Map<String, dynamic> json) => FamilyTreeData(
    appVersion: json['appVersion'] as String? ?? '1.0.0',
    mainFamilyCode: json['mainFamilyCode'] as String? ?? 'ayivon',
    publicMode: PublicModeConfig.fromJson(
      Map<String, dynamic>.from(json['publicMode'] as Map? ?? const {}),
    ),
    language: json['language'] as String? ?? 'fr',
    familyHonor: FamilyHonor.fromJson(
      Map<String, dynamic>.from(json['familyHonor'] as Map? ?? const {}),
    ),
    familyCodes: (json['familyCodes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => FamilyCode.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    accessCodes: (json['accessCodes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AccessCode.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    modificationCodes: (json['modificationCodes'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ModificationCode.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    admins: (json['admins'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    adminAccess: AdminAccess.fromJson(
      Map<String, dynamic>.from(json['adminAccess'] as Map? ?? const {}),
    ),
    people: (json['people'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Person.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    familyLinks: (json['familyLinks'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => FamilyLink.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    marriageRelations: (json['marriageRelations'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MarriageRelation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    notifications: (json['notifications'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              FamilyNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    changeNotifications: (json['changeNotifications'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ChangeNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    modificationHistory: (json['modificationHistory'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ModificationHistory.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
    auditLog: (json['auditLog'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AuditLog.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  factory FamilyTreeData.demo() => FamilyTreeData(
    mainFamilyCode: 'ayivon',
    familyHonor: const FamilyHonor(
      patriarchPersonId: 'p002',
      showPatriarchBadge: true,
      badgePosition: 'topLeft',
      badgeStyle: 'premium',
    ),
    familyCodes: const [
      FamilyCode(
        code: 'ayivon',
        familyName: 'Famille Amouzou',
        role: 'owner',
        status: 'accepted',
      ),
      FamilyCode(
        code: 'KOFFI2026',
        familyName: 'Famille Koffi',
        role: 'editor',
        status: 'pending',
      ),
    ],
    accessCodes: const [
      AccessCode(
        id: 'code001',
        code: 'ayivon',
        label: 'Code accès famille principale',
        type: 'familyAccess',
        role: 'viewer',
        familyCode: 'AYIVON',
        createdByAdminId: 'admin001',
        createdByName: 'Admin Principal',
        createdAt: '2026-06-26T10:00:00',
      ),
      AccessCode(
        id: 'code002',
        code: 'ayivonvi2026',
        label: 'Code Admin KPI',
        type: 'adminKpi',
        role: 'admin',
        familyCode: 'AYIVON',
        createdByAdminId: 'superAdmin001',
        createdByName: 'Super Admin',
        createdAt: '2026-06-26T10:00:00',
        expiresAt: '2026-09-26T10:00:00',
        notes: 'Code à renouveler tous les 3 mois',
      ),
      AccessCode(
        id: 'code003',
        code: 'EDIT-AYIVON-2026',
        label: 'Code modification famille Ayivon',
        type: 'modification',
        role: 'editor',
        familyCode: 'AYIVON',
        createdByAdminId: 'admin001',
        createdByName: 'Admin Principal',
        createdAt: '2026-06-26T10:00:00',
      ),
    ],
    modificationCodes: const [
      ModificationCode(
        code: 'EDIT-AYIVON-2026',
        label: 'Code modification famille Ayivon',
        createdByAdminId: 'admin001',
      ),
    ],
    admins: const [
      AdminUser(
        id: 'admin001',
        fullName: 'Admin Principal Ayivon',
        role: 'superAdmin',
        email: 'admin@email.com',
        phoneNumber: '+33000000000',
        whatsappNumber: '+33000000000',
      ),
      AdminUser(id: 'admin002', fullName: 'Admin Famille', role: 'admin'),
    ],
    adminAccess: const AdminAccess(
      currentAdminCode: 'ayivonvi2026',
      lastChangedAt: '2026-06-26T00:00:00',
      nextChangeDueAt: '2026-09-26T00:00:00',
      rotationMonths: 3,
      enabled: true,
      requireCodeRotationReminder: true,
      codeHistory: [
        AdminCodeHistory(
          code: 'ayivonvi2026',
          createdAt: '2026-06-26T00:00:00',
          changedByAdminId: 'superAdmin001',
        ),
      ],
    ),
    people: const [
      Person(
        id: 'p001',
        firstName: 'Ama',
        lastName: 'Amouzou',
        gender: 'F',
        birthDate: '1954-04-20',
        birthPlace: 'Lome',
        publicMapLocation: 'Lome, Togo',
        currentAddress: 'Lome, Togo',
        burialPlace: '',
        latitude: 6.1319,
        longitude: 1.2228,
        email: 'ama.amouzou@example.com',
        phoneNumber: '+22890123456',
        whatsappNumber: '+22890123456',
        allowContact: true,
        emailVisibility: 'familyOnly',
        phoneVisibility: 'familyOnly',
        whatsappVisibility: 'familyOnly',
        familyCode: 'AMOUZOU2026',
        spouseIds: ['p002'],
        childrenIds: ['p003'],
        marriageType: 'customary',
        spouses: ['p002'],
        children: ['p003'],
        importantPlaces: [
          ImportantPlace(
            name: 'Maison familiale',
            address: 'Lome, Togo',
            latitude: 6.1319,
            longitude: 1.2228,
            description: 'Adresse de reference de la branche principale.',
          ),
        ],
        history: [
          HistoryEvent(
            id: 'h001',
            date: '1979-08-12',
            title: 'Mariage familial',
            description: 'Union celebree avec les deux branches familiales.',
            place: 'Lome',
            latitude: 6.1319,
            longitude: 1.2228,
          ),
        ],
        notes: 'Matriarche de la branche principale.',
      ),
      Person(
        id: 'p002',
        firstName: 'Kossi',
        lastName: 'Amouzou',
        gender: 'M',
        birthDate: '1950-01-15',
        birthPlace: 'Kpalime',
        familyCode: 'AMOUZOU2026',
        spouseIds: ['p001'],
        childrenIds: ['p003'],
        marriageType: 'customary',
        spouses: ['p001'],
        children: ['p003'],
      ),
      Person(
        id: 'p003',
        firstName: 'Mawuli',
        lastName: 'Amouzou',
        gender: 'M',
        birthDate: '1982-11-03',
        birthPlace: 'Accra',
        familyCode: 'AMOUZOU2026',
        fatherId: 'p002',
        motherId: 'p001',
        parents: ['p001', 'p002'],
      ),
    ],
    marriageRelations: const [
      MarriageRelation(
        id: 'marriage001',
        personId: 'p001',
        spouseId: 'p002',
        marriageType: 'customary',
        status: 'active',
        marriageDate: '1979-08-12',
        marriagePlace: 'Lome',
        order: 1,
      ),
    ],
    familyLinks: const [
      FamilyLink(
        id: 'link001',
        fromPersonId: 'p003',
        toPersonId: 'p001',
        relationshipType: 'child',
        linkedFamilyCode: 'KOFFI2026',
        status: 'pending',
        notes: 'Lien propose par la branche Koffi.',
      ),
    ],
    notifications: [
      FamilyNotification(
        id: 'n001',
        personId: 'p001',
        targetPersonId: 'p001',
        type: 'birthday',
        channel: 'local',
        title: 'Anniversaire',
        message: 'Aujourd’hui, c’est l’anniversaire de Ama Amouzou.',
        scheduledDate: DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ],
    changeNotifications: const [
      ChangeNotification(
        id: 'cn001',
        personId: 'p001',
        personFullName: 'Ama Amouzou',
        action: 'person_added',
        modifiedByAdminId: 'admin001',
        modifiedByName: 'Admin Principal Ayivon',
        modifiedAt: '2026-06-26T12:30:00',
        message: 'Ama Amouzou a été ajoutée par Admin Principal Ayivon.',
      ),
    ],
    modificationHistory: const [
      ModificationHistory(
        id: 'mh001',
        personId: 'p001',
        personFullName: 'Ama Amouzou',
        action: 'person_added',
        modifiedByAdminId: 'admin001',
        modifiedByName: 'Admin Principal Ayivon',
        modifiedAt: '2026-06-26T12:30:00',
        details: 'Création de la fiche personne.',
        expiresAt: '2026-09-26T12:30:00',
      ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'mainFamilyCode': mainFamilyCode,
    'publicMode': publicMode.toJson(),
    'language': language,
    'familyHonor': familyHonor.toJson(),
    'familyCodes': familyCodes.map((item) => item.toJson()).toList(),
    'accessCodes': accessCodes.map((item) => item.toJson()).toList(),
    'modificationCodes': modificationCodes
        .map((item) => item.toJson())
        .toList(),
    'admins': admins.map((item) => item.toJson()).toList(),
    'adminAccess': adminAccess.toJson(),
    'people': people.map((item) => item.toJson()).toList(),
    'familyLinks': familyLinks.map((item) => item.toJson()).toList(),
    'marriageRelations': marriageRelations
        .map((item) => item.toJson())
        .toList(),
    'notifications': notifications.map((item) => item.toJson()).toList(),
    'changeNotifications': changeNotifications
        .map((item) => item.toJson())
        .toList(),
    'modificationHistory': modificationHistory
        .map((item) => item.toJson())
        .toList(),
    'auditLog': auditLog.map((item) => item.toJson()).toList(),
  };

  FamilyTreeData copyWith({
    String? appVersion,
    String? mainFamilyCode,
    PublicModeConfig? publicMode,
    String? language,
    FamilyHonor? familyHonor,
    List<FamilyCode>? familyCodes,
    List<AccessCode>? accessCodes,
    List<ModificationCode>? modificationCodes,
    List<AdminUser>? admins,
    AdminAccess? adminAccess,
    List<Person>? people,
    List<FamilyLink>? familyLinks,
    List<MarriageRelation>? marriageRelations,
    List<FamilyNotification>? notifications,
    List<ChangeNotification>? changeNotifications,
    List<ModificationHistory>? modificationHistory,
    List<AuditLog>? auditLog,
  }) {
    return FamilyTreeData(
      appVersion: appVersion ?? this.appVersion,
      mainFamilyCode: mainFamilyCode ?? this.mainFamilyCode,
      publicMode: publicMode ?? this.publicMode,
      language: language ?? this.language,
      familyHonor: familyHonor ?? this.familyHonor,
      familyCodes: familyCodes ?? this.familyCodes,
      accessCodes: accessCodes ?? this.accessCodes,
      modificationCodes: modificationCodes ?? this.modificationCodes,
      admins: admins ?? this.admins,
      adminAccess: adminAccess ?? this.adminAccess,
      people: people ?? this.people,
      familyLinks: familyLinks ?? this.familyLinks,
      marriageRelations: marriageRelations ?? this.marriageRelations,
      notifications: notifications ?? this.notifications,
      changeNotifications: changeNotifications ?? this.changeNotifications,
      modificationHistory: modificationHistory ?? this.modificationHistory,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}
