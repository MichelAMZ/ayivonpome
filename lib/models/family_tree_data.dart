import 'audit_log.dart';
import 'admin_user.dart';
import 'family_code.dart';
import 'family_link.dart';
import 'family_notification.dart';
import 'history_event.dart';
import 'important_place.dart';
import 'marriage_relation.dart';
import 'person.dart';
import 'public_mode_config.dart';
import 'modification_code.dart';

class FamilyTreeData {
  const FamilyTreeData({
    this.appVersion = '1.0.0',
    this.mainFamilyCode = 'ayivon',
    this.publicMode = const PublicModeConfig(),
    this.language = 'fr',
    this.familyCodes = const [],
    this.modificationCodes = const [],
    this.admins = const [],
    this.people = const [],
    this.familyLinks = const [],
    this.marriageRelations = const [],
    this.notifications = const [],
    this.auditLog = const [],
  });

  final String appVersion;
  final String mainFamilyCode;
  final PublicModeConfig publicMode;
  final String language;
  final List<FamilyCode> familyCodes;
  final List<ModificationCode> modificationCodes;
  final List<AdminUser> admins;
  final List<Person> people;
  final List<FamilyLink> familyLinks;
  final List<MarriageRelation> marriageRelations;
  final List<FamilyNotification> notifications;
  final List<AuditLog> auditLog;

  factory FamilyTreeData.fromJson(Map<String, dynamic> json) => FamilyTreeData(
        appVersion: json['appVersion'] as String? ?? '1.0.0',
        mainFamilyCode: json['mainFamilyCode'] as String? ?? 'ayivon',
        publicMode: PublicModeConfig.fromJson(
          Map<String, dynamic>.from(json['publicMode'] as Map? ?? const {}),
        ),
        language: json['language'] as String? ?? 'fr',
        familyCodes: (json['familyCodes'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => FamilyCode.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        modificationCodes: (json['modificationCodes'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  ModificationCode.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        admins: (json['admins'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
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
              (item) =>
                  MarriageRelation.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        notifications: (json['notifications'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => FamilyNotification.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        auditLog: (json['auditLog'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => AuditLog.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );

  factory FamilyTreeData.demo() => FamilyTreeData(
        mainFamilyCode: 'ayivon',
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
          AdminUser(
            id: 'admin002',
            fullName: 'Admin Famille',
            role: 'admin',
          ),
        ],
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
            scheduledDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            status: 'pending',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ],
      );

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'mainFamilyCode': mainFamilyCode,
        'publicMode': publicMode.toJson(),
        'language': language,
        'familyCodes': familyCodes.map((item) => item.toJson()).toList(),
        'modificationCodes':
            modificationCodes.map((item) => item.toJson()).toList(),
        'admins': admins.map((item) => item.toJson()).toList(),
        'people': people.map((item) => item.toJson()).toList(),
        'familyLinks': familyLinks.map((item) => item.toJson()).toList(),
        'marriageRelations':
            marriageRelations.map((item) => item.toJson()).toList(),
        'notifications': notifications.map((item) => item.toJson()).toList(),
        'auditLog': auditLog.map((item) => item.toJson()).toList(),
      };

  FamilyTreeData copyWith({
    String? appVersion,
    String? mainFamilyCode,
    PublicModeConfig? publicMode,
    String? language,
    List<FamilyCode>? familyCodes,
    List<ModificationCode>? modificationCodes,
    List<AdminUser>? admins,
    List<Person>? people,
    List<FamilyLink>? familyLinks,
    List<MarriageRelation>? marriageRelations,
    List<FamilyNotification>? notifications,
    List<AuditLog>? auditLog,
  }) {
    return FamilyTreeData(
      appVersion: appVersion ?? this.appVersion,
      mainFamilyCode: mainFamilyCode ?? this.mainFamilyCode,
      publicMode: publicMode ?? this.publicMode,
      language: language ?? this.language,
      familyCodes: familyCodes ?? this.familyCodes,
      modificationCodes: modificationCodes ?? this.modificationCodes,
      admins: admins ?? this.admins,
      people: people ?? this.people,
      familyLinks: familyLinks ?? this.familyLinks,
      marriageRelations: marriageRelations ?? this.marriageRelations,
      notifications: notifications ?? this.notifications,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}
