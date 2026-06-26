import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_code_service.dart';
import '../services/backup_service.dart';
import '../services/change_notification_service.dart';
import '../services/communication_service.dart';
import '../services/admin_service.dart';
import '../services/admin_access_service.dart';
import '../services/access_code_service.dart';
import '../services/family_relation_service.dart';
import '../services/import_export_service.dart';
import '../services/json_storage_service.dart';
import '../services/kpi_service.dart';
import '../services/map_service.dart';
import '../services/modification_history_service.dart';
import '../services/modification_code_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_provider.dart';

final jsonStorageServiceProvider = Provider<JsonStorageService>(
  (ref) => JsonStorageService(),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(jsonStorageServiceProvider)),
);

final authCodeServiceProvider = Provider<AuthCodeService>(
  (ref) => AuthCodeService(),
);

final importExportServiceProvider = Provider<ImportExportService>(
  (ref) => ImportExportService(),
);

final mapServiceProvider = Provider<MapService>((ref) => MapService());

final communicationServiceProvider = Provider<CommunicationService>(
  (ref) => CommunicationService(),
);

final modificationCodeServiceProvider = Provider<ModificationCodeService>(
  (ref) => ModificationCodeService(),
);

final kpiServiceProvider = Provider<KpiService>((ref) => KpiService());

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final adminAccessServiceProvider = Provider<AdminAccessService>(
  (ref) => const AdminAccessService(),
);

final accessCodeServiceProvider = Provider<AccessCodeService>(
  (ref) => const AccessCodeService(),
);

final familyRelationServiceProvider = Provider<FamilyRelationService>(
  (ref) => FamilyRelationService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
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
