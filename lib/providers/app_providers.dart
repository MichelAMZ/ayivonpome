import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/firebase/firebase_runtime_config.dart';
import '../data/firestore/firestore_remote_database_client.dart';
import '../models/family_tree_data.dart';
import '../services/auth_code_service.dart';
import '../services/backup_service.dart';
import '../services/change_notification_service.dart';
import '../services/connectivity_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/bug_report_service.dart';
import '../services/communication_service.dart';
import '../services/data_cleanup_service.dart';
import '../services/admin_service.dart';
import '../services/admin_access_service.dart';
import '../services/access_code_service.dart';
import '../services/app_settings_service.dart';
import '../services/family_relation_service.dart';
import '../services/family_council_service.dart';
import '../services/family_announcement_service.dart';
import '../services/genealogy_statistics_service.dart';
import '../services/genealogy_generation_service.dart';
import '../services/history_cleanup_service.dart';
import '../services/hybrid_family_repository.dart';
import '../services/import_export_service.dart';
import '../services/info_news_service.dart';
import '../services/json_storage_service.dart';
import '../services/local_json_repository.dart';
import '../services/kpi_service.dart';
import '../services/language_detection_service.dart';
import '../services/map_service.dart';
import '../services/marriage_service.dart';
import '../services/modification_history_service.dart';
import '../services/modification_code_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_provider.dart';
import '../services/remote_database_repository.dart';
import '../services/sync_service.dart';
import '../services/tree_view_settings_service.dart';
import '../services/super_admin_recovery_service.dart';

final jsonStorageServiceProvider = Provider<JsonStorageService>(
  (ref) => JsonStorageService(),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(jsonStorageServiceProvider)),
);

final localJsonRepositoryProvider = Provider<JsonFamilyRepository>(
  (ref) => JsonFamilyRepository(ref.watch(jsonStorageServiceProvider)),
);

final remoteDatabaseRepositoryProvider = Provider<DatabaseFamilyRepository>((
  ref,
) {
  final config = FirebaseRuntimeConfig.fromEnvironment();
  if (config.enabled && Firebase.apps.isNotEmpty) {
    return DatabaseFamilyRepository(
      client: FirestoreRemoteDatabaseClient(
        firestore: FirebaseFirestore.instance,
        familyId: config.familyId,
      ),
    );
  }
  return const DatabaseFamilyRepository();
});

final hybridFamilyRepositoryProvider = Provider<HybridFamilyRepository>(
  (ref) => HybridFamilyRepository(
    localRepository: ref.watch(localJsonRepositoryProvider),
    remoteRepository: ref.watch(remoteDatabaseRepositoryProvider),
  ),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => const ConnectivityService(),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    connectivity: ref.watch(connectivityServiceProvider),
    remoteRepository: ref.watch(remoteDatabaseRepositoryProvider),
  ),
);

final conflictResolutionServiceProvider = Provider<ConflictResolutionService>(
  (ref) => const ConflictResolutionService(),
);

final authCodeServiceProvider = Provider<AuthCodeService>(
  (ref) => AuthCodeService(),
);

final importExportServiceProvider = Provider<ImportExportService>(
  (ref) => ImportExportService(),
);

final bugReportServiceProvider = Provider<BugReportService>(
  (ref) => const BugReportService(),
);

final dataCleanupServiceProvider = Provider<DataCleanupService>(
  (ref) => const DataCleanupService(),
);

final mapServiceProvider = Provider<MapService>((ref) => MapService());

final marriageServiceProvider = Provider<MarriageService>(
  (ref) => const MarriageService(),
);

final communicationServiceProvider = Provider<CommunicationService>(
  (ref) => CommunicationService(),
);

final modificationCodeServiceProvider = Provider<ModificationCodeService>(
  (ref) => ModificationCodeService(),
);

final kpiServiceProvider = Provider<KpiService>((ref) => KpiService());

final languageDetectionServiceProvider = Provider<LanguageDetectionService>(
  (ref) => const LanguageDetectionService(),
);

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final adminAccessServiceProvider = Provider<AdminAccessService>(
  (ref) => const AdminAccessService(),
);

final accessCodeServiceProvider = Provider<AccessCodeService>(
  (ref) => const AccessCodeService(),
);

final appSettingsServiceProvider = Provider<AppSettingsService>(
  (ref) => const AppSettingsService(),
);

final treeViewSettingsServiceProvider = Provider<TreeViewSettingsService>(
  (ref) => const TreeViewSettingsService(),
);

final superAdminRecoveryServiceProvider = Provider<SuperAdminRecoveryService>(
  (ref) => const SuperAdminRecoveryService(),
);

final familyRelationServiceProvider = Provider<FamilyRelationService>(
  (ref) => FamilyRelationService(),
);

final familyCouncilServiceProvider = Provider<FamilyCouncilService>(
  (ref) => const FamilyCouncilService(),
);

final familyAnnouncementServiceProvider = Provider<FamilyAnnouncementService>(
  (ref) => const FamilyAnnouncementService(),
);

final genealogyStatisticsServiceProvider =
    Provider.family<GenealogyStatisticsService, FamilyTreeData>(
      (ref, data) => GenealogyStatisticsService(data),
    );

final genealogyGenerationServiceProvider = Provider<GenealogyGenerationService>(
  (ref) => const GenealogyGenerationService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final infoNewsServiceProvider = Provider<InfoNewsService>(
  (ref) => const InfoNewsService(),
);

final historyCleanupServiceProvider = Provider<HistoryCleanupService>(
  (ref) => const HistoryCleanupService(),
);

final changeNotificationServiceProvider = Provider<ChangeNotificationService>(
  (ref) => const ChangeNotificationService(),
);

final modificationHistoryServiceProvider = Provider<ModificationHistoryService>(
  (ref) => const ModificationHistoryService(),
);

final pushNotificationProvider = Provider<PushNotificationProvider>(
  (ref) => NoBackendPushNotificationProvider(),
);
