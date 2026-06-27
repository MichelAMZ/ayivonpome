import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import '../models/access_code.dart';
import '../models/bug_report.dart';
import '../models/family_announcement.dart';
import '../models/family_code.dart';
import '../models/family_council_member.dart';
import '../models/family_history.dart';
import '../models/family_link.dart';
import '../models/family_honor.dart';
import '../models/family_leadership.dart';
import '../models/family_leadership_history_entry.dart';
import '../models/family_notification.dart';
import '../models/family_tree_data.dart';
import '../models/info_news.dart';
import '../models/person.dart';
import 'app_providers.dart';

final familyTreeProvider =
    AsyncNotifierProvider<FamilyTreeController, FamilyTreeData>(
      FamilyTreeController.new,
    );

class FamilyTreeController extends AsyncNotifier<FamilyTreeData> {
  @override
  Future<FamilyTreeData> build() async {
    final storage = ref.watch(jsonStorageServiceProvider);
    final raw = await storage.readRaw();
    if (raw == null || raw.trim().isEmpty) {
      final demo = FamilyTreeData.demo();
      await storage.writeRaw(_encode(demo));
      return demo;
    }
    final parsed = FamilyTreeData.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    var pruned = ref
        .read(modificationHistoryServiceProvider)
        .pruneExpired(parsed);
    if (pruned.autoCleanupInfoNewsSendHistory) {
      pruned = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(pruned)
          .data;
    }
    final dataCleaned = ref
        .read(dataCleanupServiceProvider)
        .runAutomaticCleanup(pruned)
        .data;
    pruned = dataCleaned;
    if (pruned.modificationHistory.length !=
            parsed.modificationHistory.length ||
        pruned.infoNewsSendLogs.length != parsed.infoNewsSendLogs.length ||
        pruned.notifications.length != parsed.notifications.length ||
        pruned.auditLog.length != parsed.auditLog.length ||
        pruned.dataCleanupLastCleanedAt != parsed.dataCleanupLastCleanedAt ||
        pruned.infoNewsSendHistoryLastCleanedAt !=
            parsed.infoNewsSendHistoryLastCleanedAt) {
      await storage.writeRaw(_encode(pruned));
    }
    return pruned;
  }

  Future<void> save(FamilyTreeData data) async {
    final synced = ref
        .read(changeNotificationServiceProvider)
        .syncFromAuditLog(
          ref.read(modificationHistoryServiceProvider).pruneExpired(data),
        );
    await ref.read(jsonStorageServiceProvider).writeRaw(_encode(synced));
    state = AsyncData(synced);
  }

  Future<String?> createBackup() =>
      ref.read(backupServiceProvider).createBackup();

  Future<void> addAuditLog(
    String action, {
    String actorRole = '',
    String adminId = '',
    String personId = '',
    String familyCode = '',
    String description = '',
  }) async {
    final data = await future;
    await save(
      data.copyWith(
        auditLog: [
          ...data.auditLog,
          _log(
            action,
            personId,
            familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: description,
          ),
        ],
      ),
    );
  }

  Future<void> setLanguage(String languageCode) async {
    final data = await future;
    await save(data.copyWith(language: languageCode));
  }

  Future<void> upsertPerson(Person person, String action) async {
    final data = await future;
    final duplicate = data.people.any(
      (candidate) =>
          candidate.id != person.id &&
          candidate.firstName.toLowerCase() == person.firstName.toLowerCase() &&
          candidate.lastName.toLowerCase() == person.lastName.toLowerCase() &&
          candidate.birthDate == person.birthDate,
    );
    if (duplicate) {
      throw StateError('duplicate_person');
    }
    final people = [...data.people];
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1) {
      people.add(person);
    } else {
      await createBackup();
      people[index] = person;
    }
    var nextData = data.copyWith(
      people: people,
      auditLog: [...data.auditLog, _log(action, person.id, person.familyCode)],
    );
    if (index == -1 && action == 'create_person') {
      nextData = ref
          .read(familyAnnouncementServiceProvider)
          .addBirthAnnouncementIfNeeded(nextData, person);
    }
    await save(nextData);
  }

  Future<void> deletePerson(String id) async {
    final data = await future;
    await createBackup();
    await save(
      data.copyWith(
        people: data.people.where((person) => person.id != id).toList(),
        auditLog: [...data.auditLog, _log('delete_person', id, '')],
      ),
    );
  }

  Future<void> upsertFamilyCode(FamilyCode familyCode) async {
    final data = await future;
    await createBackup();
    final codes = [...data.familyCodes];
    final index = codes.indexWhere((item) => item.code == familyCode.code);
    if (index == -1) {
      codes.add(familyCode);
    } else {
      codes[index] = familyCode;
    }
    await save(data.copyWith(familyCodes: codes));
  }

  Future<void> updateFamilyGeneralHistory(
    FamilyHistory history, {
    required String actorRole,
    required String adminId,
    required String adminName,
  }) async {
    final data = await future;
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    if (history.content.length > history.maxCharacters) {
      await addAuditLog(
        'history_character_limit_exceeded',
        actorRole: actorRole,
        adminId: adminId,
        familyCode: data.mainFamilyCode,
        description: 'Limite dépassée pour l’historique général.',
      );
      throw StateError('character_limit_exceeded');
    }
    final now = DateTime.now().toIso8601String();
    final next = history.copyWith(
      lastUpdatedAt: now,
      lastUpdatedByAdminId: adminId,
      lastUpdatedByName: adminName,
      maxCharacters: 5000,
    );
    await save(
      data.copyWith(
        familyGeneralHistory: next,
        auditLog: [
          ...data.auditLog,
          _log(
            'family_history_updated',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: next.title,
          ),
        ],
      ),
    );
  }

  Future<void> updateLinkedFamilyHistory(
    String familyCode,
    FamilyHistory history, {
    required String actorRole,
    required String adminId,
    required String adminName,
  }) async {
    final data = await future;
    final normalized = familyCode.trim().toUpperCase();
    final index = data.familyCodes.indexWhere(
      (item) => item.code.trim().toUpperCase() == normalized,
    );
    if (index == -1) throw StateError('family_code_not_found');
    final canEdit =
        actorRole == 'superAdmin' ||
        actorRole == 'admin' ||
        ((actorRole == 'editor' || actorRole == 'owner') &&
            adminId.trim().toUpperCase() == normalized);
    if (!canEdit) throw StateError('forbidden');
    if (history.content.length > history.maxCharacters) {
      await addAuditLog(
        'history_character_limit_exceeded',
        actorRole: actorRole,
        adminId: adminId,
        familyCode: normalized,
        description: 'Limite dépassée pour l’historique de famille liée.',
      );
      throw StateError('character_limit_exceeded');
    }
    final now = DateTime.now().toIso8601String();
    final nextHistory = history.copyWith(
      lastUpdatedAt: now,
      lastUpdatedByAdminId: adminId,
      lastUpdatedByName: adminName,
      maxCharacters: 3000,
    );
    final codes = [...data.familyCodes];
    codes[index] = codes[index].copyWith(history: nextHistory);
    await save(
      data.copyWith(
        familyCodes: codes,
        auditLog: [
          ...data.auditLog,
          _log(
            'linked_family_history_updated',
            '',
            normalized,
            actorRole: actorRole,
            adminId: adminId,
            description: nextHistory.title,
          ),
        ],
      ),
    );
  }

  Future<void> upsertFamilyCouncilMember(
    FamilyCouncilMember member, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final prepared = member.copyWith(
      id: member.id.isEmpty
          ? 'council${DateTime.now().microsecondsSinceEpoch}'
          : member.id,
    );
    final members = [...data.familyCouncil.members];
    final index = members.indexWhere((item) => item.id == prepared.id);
    if (index == -1) {
      members.add(prepared);
    } else {
      members[index] = prepared;
    }
    members.sort((a, b) => a.order.compareTo(b.order));
    await save(
      data.copyWith(
        familyCouncil: data.familyCouncil.copyWith(members: members),
        auditLog: [
          ...data.auditLog,
          _log(
            'family_council_updated',
            prepared.personId,
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: prepared.fullName,
          ),
        ],
      ),
    );
  }

  Future<void> deleteFamilyCouncilMember(
    FamilyCouncilMember member, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    await save(
      data.copyWith(
        familyCouncil: data.familyCouncil.copyWith(
          members: data.familyCouncil.members
              .where((item) => item.id != member.id)
              .toList(),
        ),
        auditLog: [
          ...data.auditLog,
          _log(
            'family_council_member_deleted',
            member.personId,
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: member.fullName,
          ),
        ],
      ),
    );
  }

  Future<void> upsertFamilyLink(FamilyLink link) async {
    final data = await future;
    await createBackup();
    final links = [...data.familyLinks];
    final index = links.indexWhere((item) => item.id == link.id);
    if (index == -1) {
      links.add(link);
    } else {
      links[index] = link;
    }
    await save(data.copyWith(familyLinks: links));
  }

  Future<void> upsertNotification(
    FamilyNotification notification, {
    required String actorRole,
    required String adminId,
    String adminName = '',
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError(
        'Seuls les administrateurs sont autorisés à envoyer des notifications.',
      );
    }
    final data = await future;
    final notifications = [...data.notifications];
    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index == -1) {
      notifications.add(notification);
    } else {
      notifications[index] = notification;
    }
    var nextData = data.copyWith(
      notifications: notifications,
      auditLog: [
        ...data.auditLog,
        _log(
          'notification_${notification.channel}',
          notification.targetPersonId,
          '',
          actorRole: actorRole,
          adminId: adminId,
          description:
              'admin=$adminName; type=${notification.type}; status=${notification.status}; message=${notification.message}',
        ),
      ],
    );
    nextData = ref
        .read(dataCleanupServiceProvider)
        .runAutomaticCleanup(nextData)
        .data;
    await save(nextData);
  }

  Future<BugReport> createBugReport(BugReport bug) async {
    final data = await future;
    final now = DateTime.now().toIso8601String();
    final prepared = bug.copyWith(
      id: bug.id.isEmpty
          ? 'bug${DateTime.now().microsecondsSinceEpoch}'
          : bug.id,
      createdAt: bug.createdAt.isEmpty ? now : bug.createdAt,
      status: bug.status.isEmpty ? 'open' : bug.status,
    );
    await save(
      data.copyWith(
        bugReports: [...data.bugReports, prepared],
        auditLog: [
          ...data.auditLog,
          _log(
            'bug_report_created',
            '',
            data.mainFamilyCode,
            description: prepared.title,
          ),
        ],
      ),
    );
    return prepared;
  }

  Future<void> updateBugReportStatus(
    BugReport bug, {
    required String status,
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    await save(
      data.copyWith(
        bugReports: data.bugReports
            .map(
              (item) =>
                  item.id == bug.id ? item.copyWith(status: status) : item,
            )
            .toList(),
        auditLog: [
          ...data.auditLog,
          _log(
            'bug_report_status_updated',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${bug.id}:$status',
          ),
        ],
      ),
    );
  }

  Future<void> markBugReportAdminsNotified(
    BugReport bug,
    Iterable<String> adminIds,
  ) async {
    final data = await future;
    final ids = {...bug.notifiedAdmins, ...adminIds}.toList();
    await save(
      data.copyWith(
        bugReports: data.bugReports
            .map(
              (item) =>
                  item.id == bug.id ? item.copyWith(notifiedAdmins: ids) : item,
            )
            .toList(),
      ),
    );
  }

  Future<void> deleteBugReport(
    BugReport bug, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final nextReports = actorRole == 'superAdmin'
        ? data.bugReports.where((item) => item.id != bug.id).toList()
        : data.bugReports
              .map(
                (item) =>
                    item.id == bug.id ? item.copyWith(status: 'deleted') : item,
              )
              .toList();
    await save(
      data.copyWith(
        bugReports: nextReports,
        auditLog: [
          ...data.auditLog,
          _log(
            'bug_report_deleted',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: bug.id,
          ),
        ],
      ),
    );
  }

  Future<void> upsertInfoNews(
    InfoNews news, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final now = DateTime.now().toIso8601String();
    final isCreate =
        news.id.isEmpty || !data.infoNews.any((item) => item.id == news.id);
    final prepared = news.copyWith(
      id: news.id.isEmpty
          ? 'news${DateTime.now().microsecondsSinceEpoch}'
          : news.id,
      createdAt: news.createdAt.isEmpty ? now : news.createdAt,
      updatedAt: now,
      createdBy: news.createdBy.isEmpty ? adminId : news.createdBy,
    );
    final items = [...data.infoNews];
    final index = items.indexWhere((item) => item.id == prepared.id);
    if (index == -1) {
      items.add(prepared);
    } else {
      items[index] = prepared;
    }

    final sendLogs = [...data.infoNewsSendLogs];
    if (isCreate && prepared.sendToContacts) {
      final service = ref.read(infoNewsServiceProvider);
      for (final person in service.contactTargets(data)) {
        sendLogs.add(
          InfoNewsSendLog(
            id: 'send${DateTime.now().microsecondsSinceEpoch}${person.id}',
            infoNewsId: prepared.id,
            contactPersonId: person.id,
            contactName: person.fullName,
            contactPhone: service.contactPhone(person),
            date: now,
            createdAt: now,
          ),
        );
      }
    }

    var nextData = data.copyWith(
      infoNews: items,
      infoNewsSendLogs: sendLogs,
      auditLog: [
        ...data.auditLog,
        _log(
          isCreate ? 'info_news_created' : 'info_news_updated',
          '',
          data.mainFamilyCode,
          actorRole: actorRole,
          adminId: adminId,
          description: prepared.title,
        ),
      ],
    );
    if (nextData.autoCleanupInfoNewsSendHistory) {
      nextData = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(nextData)
          .data;
    }
    await save(nextData);
  }

  Future<void> deleteInfoNews(
    InfoNews news, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    await save(
      data.copyWith(
        infoNews: data.infoNews.where((item) => item.id != news.id).toList(),
        auditLog: [
          ...data.auditLog,
          _log(
            'info_news_deleted',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: news.title,
          ),
        ],
      ),
    );
  }

  Future<void> updateInfoNewsSendLog(
    InfoNewsSendLog log, {
    required String status,
    String error = '',
  }) async {
    final data = await future;
    final now = DateTime.now().toIso8601String();
    var nextData = data.copyWith(
      infoNewsSendLogs: data.infoNewsSendLogs
          .map(
            (item) => item.id == log.id
                ? item.copyWith(status: status, error: error, date: now)
                : item,
          )
          .toList(),
    );
    if (nextData.autoCleanupInfoNewsSendHistory) {
      nextData = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(nextData)
          .data;
    }
    await save(nextData);
  }

  Future<void> cleanOldInfoNewsSendHistory({
    bool force = false,
    String actorRole = '',
    String adminId = '',
  }) async {
    final data = await future;
    if (!force && !data.autoCleanupInfoNewsSendHistory) return;
    final result = ref
        .read(historyCleanupServiceProvider)
        .deleteEntriesOlderThan90Days(data);
    await save(
      result.data.copyWith(
        auditLog: force
            ? [
                ...result.data.auditLog,
                _log(
                  'info_news_send_history_cleaned',
                  '',
                  data.mainFamilyCode,
                  actorRole: actorRole,
                  adminId: adminId,
                  description: '${result.deletedCount}',
                ),
              ]
            : result.data.auditLog,
      ),
    );
  }

  Future<void> updateInfoNewsSendHistoryCleanupSetting({
    required bool enabled,
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    var nextData = data.copyWith(
      autoCleanupInfoNewsSendHistory: enabled,
      auditLog: [
        ...data.auditLog,
        _log(
          'info_news_send_history_cleanup_setting_updated',
          '',
          data.mainFamilyCode,
          actorRole: actorRole,
          adminId: adminId,
          description: '$enabled',
        ),
      ],
    );
    if (enabled) {
      nextData = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(nextData)
          .data;
    }
    await save(nextData);
  }

  Future<void> runAutomaticDataCleanup() async {
    final data = await future;
    final result = ref
        .read(dataCleanupServiceProvider)
        .runAutomaticCleanup(data);
    if (result.deletedCount != 0 ||
        result.data.dataCleanupLastCleanedAt != data.dataCleanupLastCleanedAt) {
      await save(result.data);
    }
  }

  Future<void> updateDataCleanupSettings({
    required bool autoCleanupNotifications,
    required bool autoCleanupKpiActivityLogs,
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    var nextData = data.copyWith(
      autoCleanupNotifications: autoCleanupNotifications,
      autoCleanupKpiActivityLogs: autoCleanupKpiActivityLogs,
      auditLog: [
        ...data.auditLog,
        _log(
          'data_cleanup_settings_updated',
          '',
          data.mainFamilyCode,
          actorRole: actorRole,
          adminId: adminId,
          description:
              'notifications=$autoCleanupNotifications;kpi=$autoCleanupKpiActivityLogs',
        ),
      ],
    );
    nextData = ref
        .read(dataCleanupServiceProvider)
        .runAutomaticCleanup(nextData)
        .data;
    await save(nextData);
  }

  Future<void> ensureTodayFamilyAnnouncements() async {
    final data = await future;
    var nextData = ref
        .read(familyAnnouncementServiceProvider)
        .ensureTodayBirthdayAnnouncements(data);
    if (nextData.autoCleanupInfoNewsSendHistory) {
      nextData = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(nextData)
          .data;
    }
    if (nextData.familyAnnouncementHistory.length !=
            data.familyAnnouncementHistory.length ||
        nextData.infoNewsSendHistoryLastCleanedAt !=
            data.infoNewsSendHistoryLastCleanedAt) {
      await save(nextData);
    }
  }

  Future<void> updateFamilyAnnouncementStatus(
    FamilyAnnouncementHistory announcement,
    String status,
  ) async {
    final data = await future;
    var nextData = data.copyWith(
      familyAnnouncementHistory: data.familyAnnouncementHistory
          .map(
            (item) => item.id == announcement.id
                ? item.copyWith(whatsappStatus: status)
                : item,
          )
          .toList(),
    );
    if (nextData.autoCleanupInfoNewsSendHistory) {
      nextData = ref
          .read(historyCleanupServiceProvider)
          .cleanOldNotificationHistory(nextData)
          .data;
    }
    await save(nextData);
  }

  Future<void> updateFamilyAnnouncementSettings(
    FamilyAnnouncementSettings settings, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    await save(
      data.copyWith(
        familyAnnouncementSettings: settings,
        auditLog: [
          ...data.auditLog,
          _log(
            'family_announcement_settings_updated',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
          ),
        ],
      ),
    );
  }

  Future<void> markModificationCodeUsed(String code) async {
    final data = await future;
    final nextCodes = data.modificationCodes
        .map(
          (item) => item.code.toUpperCase() == code.trim().toUpperCase()
              ? item.copyWith(usedCount: item.usedCount + 1)
              : item,
        )
        .toList();
    await save(data.copyWith(modificationCodes: nextCodes));
  }

  Future<void> changeAdminAccessCode({
    required String oldCode,
    required String newCode,
    required String changedByAdminId,
    required String actorRole,
  }) async {
    final data = await future;
    final updated = ref
        .read(adminAccessServiceProvider)
        .changeCode(
          data: data,
          oldCode: oldCode,
          newCode: newCode,
          changedByAdminId: changedByAdminId,
        );
    await save(
      updated.copyWith(
        auditLog: [
          ...updated.auditLog,
          _log(
            'admin_action',
            '',
            updated.mainFamilyCode,
            actorRole: actorRole,
            adminId: changedByAdminId,
            description: 'Code admin KPI modifié.',
          ),
        ],
      ),
    );
  }

  Future<void> upsertAccessCode(
    AccessCode code, {
    required String actorRole,
    required String adminId,
    required String adminName,
  }) async {
    final data = await future;
    final isCreate =
        code.id.isEmpty || !data.accessCodes.any((item) => item.id == code.id);
    final prepared = ref
        .read(accessCodeServiceProvider)
        .upsert(
          data,
          code.copyWith(
            createdByAdminId: code.createdByAdminId.isEmpty
                ? adminId
                : code.createdByAdminId,
            createdByName: code.createdByName.isEmpty
                ? adminName
                : code.createdByName,
          ),
          actorRole: actorRole,
          isCreate: isCreate,
        );
    final codes = [...data.accessCodes];
    final index = codes.indexWhere((item) => item.id == prepared.id);
    if (index == -1) {
      codes.add(prepared);
    } else {
      codes[index] = prepared;
    }
    await save(
      data.copyWith(
        accessCodes: codes,
        auditLog: [
          ...data.auditLog,
          _log(
            isCreate ? 'code_created' : 'code_updated',
            '',
            prepared.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: prepared.label,
          ),
        ],
      ),
    );
  }

  Future<void> setAccessCodeEnabled(
    AccessCode code, {
    required bool enabled,
    required String actorRole,
    required String adminId,
  }) async {
    final data = await future;
    final next = ref
        .read(accessCodeServiceProvider)
        .toggle(code, enabled: enabled);
    await save(
      data.copyWith(
        accessCodes: data.accessCodes
            .map((item) => item.id == code.id ? next : item)
            .toList(),
        auditLog: [
          ...data.auditLog,
          _log(
            enabled ? 'code_enabled' : 'code_disabled',
            '',
            code.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: code.label,
          ),
        ],
      ),
    );
  }

  Future<void> deleteAccessCode(
    AccessCode code, {
    required String actorRole,
    required String adminId,
  }) async {
    final data = await future;
    if (!ref.read(accessCodeServiceProvider).canDelete(code, actorRole)) {
      throw StateError('forbidden');
    }
    await save(
      data.copyWith(
        accessCodes: data.accessCodes
            .where((item) => item.id != code.id)
            .toList(),
        auditLog: [
          ...data.auditLog,
          _log(
            'code_deleted',
            '',
            code.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: code.label,
          ),
        ],
      ),
    );
  }

  Future<AccessCode> regenerateAccessCode(
    AccessCode code, {
    required String actorRole,
    required String adminId,
    required String adminName,
  }) async {
    final data = await future;
    final service = ref.read(accessCodeServiceProvider);
    final existingIndex = data.accessCodes.indexWhere(
      (item) => item.id == code.id,
    );
    if (existingIndex == -1) throw StateError('code_not_found');
    final existing = data.accessCodes[existingIndex];
    if (!service.canRegenerate(
      existing,
      actorRole: actorRole,
      adminId: adminId,
    )) {
      throw StateError('forbidden');
    }

    final now = DateTime.now().toIso8601String();
    final newCode = existing.copyWith(
      id: 'code${DateTime.now().microsecondsSinceEpoch}',
      code: service.generateUniqueSecureCode(data, existing.type),
      enabled: true,
      createdAt: now,
      updatedAt: '',
      usedCount: 0,
      lastUsedAt: '',
      createdByAdminId: adminId,
      createdByName: adminName,
      previousCodeId: existing.id,
      replacedByCodeId: '',
      regeneratedAt: '',
    );
    final disabledOldCode = existing.copyWith(
      enabled: false,
      updatedAt: now,
      replacedByCodeId: newCode.id,
      regeneratedAt: now,
    );
    final codes = [...data.accessCodes];
    codes[existingIndex] = disabledOldCode;
    codes.add(newCode);

    await save(
      data.copyWith(
        accessCodes: codes,
        auditLog: [
          ...data.auditLog,
          _log(
            'code_regenerated',
            '',
            existing.familyCode,
            actorRole: actorRole,
            adminId: adminId,
            description:
                '${existing.label} régénéré. Ancien code ${existing.id}, nouveau code ${newCode.id}.',
          ),
        ],
      ),
    );
    return newCode;
  }

  Future<void> auditAccessCodeAction(
    String action,
    AccessCode code, {
    required String actorRole,
    required String adminId,
  }) async {
    await addAuditLog(
      action,
      actorRole: actorRole,
      adminId: adminId,
      familyCode: code.familyCode,
      description: code.label,
    );
  }

  Future<void> updateFamilyHonor(
    FamilyHonor familyHonor, {
    required String actorRole,
    required String adminId,
  }) async {
    final data = await future;
    await save(
      data.copyWith(
        familyHonor: familyHonor,
        auditLog: [
          ...data.auditLog,
          _log(
            'admin_action',
            familyHonor.patriarchPersonId,
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: 'Distinctions familiales mises à jour.',
          ),
        ],
      ),
    );
  }

  Future<void> updateFamilyLeadership(
    FamilyLeadership familyLeadership, {
    required String actorRole,
    required String adminId,
  }) async {
    final data = await future;
    final previousLeaderId = data.familyLeadership.currentLeaderPersonId;
    final leaderChanged =
        previousLeaderId.isNotEmpty &&
        previousLeaderId != familyLeadership.currentLeaderPersonId;
    final history = [
      ...data.familyLeadershipHistory,
      if (leaderChanged)
        FamilyLeadershipHistoryEntry(
          personId: previousLeaderId,
          title: data.familyLeadership.title,
          startDate: '',
          endDate: DateTime.now().toIso8601String(),
          notes: 'Fin de mandat enregistrée automatiquement.',
        ),
    ];
    await save(
      data.copyWith(
        familyLeadership: familyLeadership,
        familyLeadershipHistory: history,
        auditLog: [
          ...data.auditLog,
          _log(
            'admin_action',
            familyLeadership.currentLeaderPersonId,
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: 'Chef actuel mis à jour dans la TopBar.',
          ),
        ],
      ),
    );
  }

  Future<void> markChangeNotificationsSeen(
    String code,
    Iterable<String> notificationIds,
  ) async {
    final data = await future;
    await save(
      ref
          .read(changeNotificationServiceProvider)
          .markSeen(data, code, notificationIds),
    );
  }

  Future<void> importData(
    FamilyTreeData imported, {
    required bool merge,
  }) async {
    final data = await future;
    await createBackup();
    final next = merge
        ? ref.read(importExportServiceProvider).merge(data, imported)
        : imported;
    await save(
      next.copyWith(
        auditLog: [
          ...next.auditLog,
          _log('import_json', '', next.mainFamilyCode),
        ],
      ),
    );
  }

  String _encode(FamilyTreeData data) =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  AuditLog _log(
    String action,
    String personId,
    String familyCode, {
    String actorRole = '',
    String adminId = '',
    String description = '',
  }) => AuditLog(
    id: 'log${DateTime.now().microsecondsSinceEpoch}',
    date: DateTime.now().toIso8601String(),
    action: action,
    actorRole: actorRole,
    adminId: adminId,
    personId: personId,
    familyCode: familyCode,
    description: description.isEmpty ? action : description,
  );
}
