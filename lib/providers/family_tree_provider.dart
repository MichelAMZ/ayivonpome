import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/family_tree/domain/use_cases/link_existing_father.dart';
import '../models/audit_log.dart';
import '../models/access_code.dart';
import '../models/admin_access.dart';
import '../models/app_settings.dart';
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
import '../models/marriage_relation.dart';
import '../models/member_save_result.dart';
import '../models/modification_code.dart';
import '../models/person.dart';
import '../models/sync_state.dart';
import '../services/activity_log_service.dart';
import '../services/parent_auto_creation_service.dart';
import 'app_providers.dart';
import 'genealogy_statistics_provider.dart';
import 'tree_filter_provider.dart';
import 'tree_runtime_provider.dart';

final familyTreeProvider =
    AsyncNotifierProvider<FamilyTreeController, FamilyTreeData>(
      FamilyTreeController.new,
    );

class FamilyTreeController extends AsyncNotifier<FamilyTreeData> {
  StreamSubscription<FamilyTreeData>? _remoteFamilyTreeSubscription;

  @override
  Future<FamilyTreeData> build() async {
    debugPrint('Fresh app initialization started');
    ref.onDispose(() {
      _remoteFamilyTreeSubscription?.cancel();
      _remoteFamilyTreeSubscription = null;
    });
    clearTreeRuntimeState();
    final data = await _loadFreshData();
    _startRemoteFamilyTreeWatch(data);
    resetFilters();
    fitAndCenterTreeOnStart();
    return data;
  }

  Future<void> initializeAppFresh() async {
    debugPrint('Fresh app initialization started');
    clearTreeRuntimeState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await _loadFreshData(forceReloadSource: true);
      _startRemoteFamilyTreeWatch(data);
      resetFilters();
      fitAndCenterTreeOnStart();
      return data;
    });
  }

  Future<FamilyTreeData> syncPendingChanges({bool force = true}) async {
    final data = await future;
    debugPrint(
      'SYNC PROVIDER syncPendingChanges START '
      'familyId=${data.mainFamilyCode} queue=${data.pendingSyncQueue.length}',
    );
    final synced = await ref
        .read(syncServiceProvider)
        .syncPendingQueue(data, force: force);
    if (_encode(synced) == _encode(data)) return data;
    debugPrint('SYNC PROVIDER local save after pending sync START');
    await ref.read(localJsonRepositoryProvider).saveFamilyTree(synced);
    debugPrint('SYNC PROVIDER local save after pending sync SUCCESS');
    state = AsyncData(synced);
    return synced;
  }

  Future<void> updateSyncOperationStatus(
    String operationId, {
    required String status,
    String resolvedBy = '',
  }) async {
    final data = await future;
    final now = DateTime.now().toIso8601String();
    final queue = data.pendingSyncQueue.map((item) {
      if (item.id != operationId) return item;
      return item.copyWith(
        status: status,
        updatedAt: now,
        updatedBy: resolvedBy.isEmpty ? item.updatedBy : resolvedBy,
        retryCount: status == 'pending' ? 0 : item.retryCount,
        lastError: status == 'resolved' || status == 'pending'
            ? ''
            : item.lastError,
        lastErrorCode: status == 'resolved' || status == 'pending'
            ? ''
            : item.lastErrorCode,
        nextAttemptAt: status == 'resolved' || status == 'pending'
            ? ''
            : item.nextAttemptAt,
        requiresUserAction: status == 'pending'
            ? false
            : item.requiresUserAction,
      );
    }).toList();
    final next = data.copyWith(pendingSyncQueue: queue);
    await ref.read(localJsonRepositoryProvider).saveFamilyTree(next);
    state = AsyncData(next);
  }

  void clearTreeRuntimeState() {
    ref.invalidate(treeFilterProvider);
    ref.invalidate(genealogyStatisticsProvider);
    debugPrint('Runtime tree state cleared');
  }

  Future<FamilyTreeData> reloadFamilyJson() async {
    debugPrint('FAMILY RELOAD START');
    final data = await _loadFreshData(forceReloadSource: true);
    debugPrint('FAMILY RELOAD SUCCESS familyId=${data.mainFamilyCode}');
    return data;
  }

  FamilyTreeData rebuildRelationshipGraph(FamilyTreeData data) {
    final rebuilt = ref
        .read(familyRelationServiceProvider)
        .normalizeRelationships(data);
    debugPrint('Relationship graph rebuilt');
    return rebuilt;
  }

  FamilyTreeData recalculateGenerationsForStartup(FamilyTreeData data) {
    final recalculated = ref
        .read(genealogyGenerationServiceProvider)
        .recalculate(data);
    debugPrint('Generations recalculated');
    return recalculated;
  }

  FamilyTreeData recomputeTreeLayout(FamilyTreeData data) {
    debugPrint('Tree layout recomputed');
    return data;
  }

  void resetFilters() {
    ref.invalidate(treeFilterProvider);
  }

  void fitAndCenterTreeOnStart() {
    ref.read(treeViewResetProvider.notifier).requestReset();
    debugPrint('Tree centered');
  }

  Future<FamilyTreeData> _loadFreshData({
    bool forceReloadSource = false,
  }) async {
    final storage = ref.read(jsonStorageServiceProvider);
    final storedRaw = await storage.readRaw();
    final sourceRaw = await _readBundledFamilyJson();
    final raw = _selectNewestJson(storedRaw, sourceRaw);
    debugPrint('Family JSON reloaded');
    if (raw == null || raw.trim().isEmpty) {
      final demo = _withFreshMetadata(FamilyTreeData.demo());
      await storage.writeRaw(_encode(demo));
      return recomputeTreeLayout(
        recalculateGenerationsForStartup(rebuildRelationshipGraph(demo)),
      );
    }
    final loaded = FamilyTreeData.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final parsed = _preserveUsefulLocalData(
      loaded,
      storedRaw: storedRaw,
      sourceSelected: raw == sourceRaw,
    );
    var pruned = ref
        .read(modificationHistoryServiceProvider)
        .pruneExpired(_normalizeHomeSyncState(parsed));
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
    pruned = rebuildRelationshipGraph(dataCleaned);
    pruned = recalculateGenerationsForStartup(pruned);
    pruned = recomputeTreeLayout(pruned);
    if (pruned.modificationHistory.length !=
            parsed.modificationHistory.length ||
        pruned.infoNewsSendLogs.length != parsed.infoNewsSendLogs.length ||
        pruned.notifications.length != parsed.notifications.length ||
        pruned.auditLog.length != parsed.auditLog.length ||
        !_sameGenerations(pruned, parsed) ||
        pruned.dataCleanupLastCleanedAt != parsed.dataCleanupLastCleanedAt ||
        pruned.infoNewsSendHistoryLastCleanedAt !=
            parsed.infoNewsSendHistoryLastCleanedAt ||
        raw == sourceRaw ||
        forceReloadSource) {
      await storage.writeRaw(_encode(pruned));
    }
    return pruned;
  }

  void _startRemoteFamilyTreeWatch(FamilyTreeData initialData) {
    _remoteFamilyTreeSubscription?.cancel();
    _remoteFamilyTreeSubscription = ref
        .read(remoteDatabaseRepositoryProvider)
        .watchFamilyTree()
        .listen(
          (remoteData) {
            _applyRemoteFamilyTreeSnapshot(remoteData, initialData);
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('FIRESTORE WATCH skipped: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _applyRemoteFamilyTreeSnapshot(
    FamilyTreeData remoteData,
    FamilyTreeData fallbackData,
  ) async {
    if (remoteData.people.isEmpty &&
        remoteData.marriageRelations.isEmpty &&
        remoteData.familyLinks.isEmpty) {
      debugPrint('FIRESTORE WATCH empty snapshot ignored');
      return;
    }

    final current = state.value ?? fallbackData;
    final pendingQueue = current.pendingSyncQueue;
    final syncStatus = pendingQueue.isEmpty ? 'synced' : 'pending';
    var merged = current.copyWith(
      mainFamilyCode: remoteData.mainFamilyCode,
      people: _mergeRemotePeopleKeepingLocalChanges(current, remoteData),
      marriageRelations: remoteData.marriageRelations,
      familyLinks: remoteData.familyLinks,
      lastUpdatedAt: DateTime.now().toIso8601String(),
      syncSettings: current.syncSettings.copyWith(syncStatus: syncStatus),
      appSettings: current.appSettings.copyWith(
        storageSettings: current.appSettings.storageSettings.copyWith(
          syncStatus: syncStatus,
        ),
      ),
    );
    merged = rebuildRelationshipGraph(merged);
    merged = recalculateGenerationsForStartup(merged);
    merged = recomputeTreeLayout(merged);

    if (_encode(merged) == _encode(current)) return;
    await ref.read(localJsonRepositoryProvider).saveFamilyTree(merged);
    state = AsyncData(merged);
    debugPrint(
      'FIRESTORE WATCH applied familyId=${merged.mainFamilyCode} '
      'members=${merged.people.length}',
    );
  }

  List<Person> _mergeRemotePeopleKeepingLocalChanges(
    FamilyTreeData current,
    FamilyTreeData remoteData,
  ) {
    final pendingPersonIds = current.pendingSyncQueue
        .where(
          (item) => item.entityType == 'person' && _isOpenPendingSyncItem(item),
        )
        .map((item) => item.entityId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final remoteById = {
      for (final person in remoteData.people) person.id: person,
    };
    final mergedById = Map<String, Person>.from(remoteById);

    for (final localPerson in current.people) {
      final remotePerson = remoteById[localPerson.id];
      if (pendingPersonIds.contains(localPerson.id) ||
          remotePerson == null ||
          _isLocalVersionNewer(localPerson.updatedAt, remotePerson.updatedAt)) {
        mergedById[localPerson.id] = localPerson;
      }
    }

    return [
      for (final remotePerson in remoteData.people)
        mergedById[remotePerson.id]!,
      for (final localPerson in current.people)
        if (!remoteById.containsKey(localPerson.id) &&
            mergedById.containsKey(localPerson.id))
          mergedById[localPerson.id]!,
    ];
  }

  bool _isOpenPendingSyncItem(PendingSyncItem item) {
    const closedStatuses = {'completed', 'discarded', 'resolved', 'synced'};
    return !closedStatuses.contains(item.status);
  }

  bool _isLocalVersionNewer(String localUpdatedAt, String remoteUpdatedAt) {
    final local = DateTime.tryParse(localUpdatedAt);
    final remote = DateTime.tryParse(remoteUpdatedAt);
    if (local == null) return false;
    if (remote == null) return true;
    return local.isAfter(remote);
  }

  Future<FamilyTreeData> save(
    FamilyTreeData data, {
    PendingSyncItem? syncOperation,
    List<PendingSyncItem> syncOperations = const [],
  }) async {
    final generationSynced = ref
        .read(genealogyGenerationServiceProvider)
        .recalculate(data);
    var localFirst = ref
        .read(changeNotificationServiceProvider)
        .syncFromAuditLog(
          ref
              .read(modificationHistoryServiceProvider)
              .pruneExpired(generationSynced),
        )
        .copyWith(lastUpdatedAt: DateTime.now().toIso8601String());
    final operations = [?syncOperation, ...syncOperations];
    final locallySaved = operations.isEmpty
        ? localFirst
        : _queueLocalSyncOperations(localFirst, operations);
    debugPrint(
      'FAMILY SAVE START familyId=${localFirst.mainFamilyCode} '
      'operations=${operations.length}',
    );
    debugPrint('FAMILY SAVE local JSON START');
    await ref.read(localJsonRepositoryProvider).saveFamilyTree(locallySaved);
    debugPrint('FAMILY SAVE local JSON SUCCESS');
    state = AsyncData(locallySaved);
    debugPrint('FAMILY SAVE state updated from local JSON');
    if (operations.isNotEmpty) {
      unawaited(_syncSavedDataInBackground(locallySaved, operations));
    }
    return locallySaved;
  }

  FamilyTreeData _queueLocalSyncOperations(
    FamilyTreeData data,
    List<PendingSyncItem> operations,
  ) {
    var queue = [...data.pendingSyncQueue];
    for (final operation in operations) {
      queue = [
        ..._removeMatchingSyncOperations(queue, [operation]),
        operation.copyWith(status: 'pending'),
      ];
    }
    return data.copyWith(
      pendingSyncQueue: queue,
      syncSettings: data.syncSettings.copyWith(syncStatus: 'pending'),
      appSettings: data.appSettings.copyWith(
        storageSettings: data.appSettings.storageSettings.copyWith(
          syncStatus: 'pending',
        ),
      ),
    );
  }

  Future<void> _syncSavedDataInBackground(
    FamilyTreeData localData,
    List<PendingSyncItem> operations,
  ) async {
    final syncService = ref.read(syncServiceProvider);
    final localRepository = ref.read(localJsonRepositoryProvider);
    try {
      final synced = await syncService.enqueueOrSyncMany(
        localData,
        operations: operations,
      );
      if (!ref.mounted) return;
      if (_encode(synced) == _encode(state.value ?? localData)) return;
      await localRepository.saveFamilyTree(synced);
      if (!ref.mounted) return;
      state = AsyncData(synced);
      debugPrint('FAMILY SAVE state updated after remote sync');
    } catch (error, stackTrace) {
      debugPrint('FAMILY SAVE remote sync failed after local save: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<PendingSyncItem> _removeMatchingSyncOperations(
    List<PendingSyncItem> queue,
    List<PendingSyncItem> operations,
  ) {
    if (operations.isEmpty || queue.isEmpty) return queue;
    return queue
        .where(
          (item) => !operations.any(
            (operation) =>
                item.entityType == operation.entityType &&
                item.entityId == operation.entityId &&
                item.action == operation.action,
          ),
        )
        .toList();
  }

  Future<MemberSaveResult> saveRelationshipChange(
    FamilyTreeData nextData, {
    required String relationship,
    required String actorRole,
    required String adminId,
  }) async {
    final current = await future;
    final now = DateTime.now().toIso8601String();
    final updatedBy = adminId.trim().isEmpty ? actorRole : adminId.trim();
    final previousPeople = {
      for (final person in current.people) person.id: person,
    };
    final previousRelations = {
      for (final relation in current.marriageRelations) relation.id: relation,
    };
    final changedPeopleIds = <String>{};
    final changedRelationIds = <String>{};

    final preparedPeople = nextData.people.map((person) {
      final previous = previousPeople[person.id];
      if (previous == null || _personPayloadChanged(previous, person)) {
        changedPeopleIds.add(person.id);
        return person.copyWith(
          createdAt:
              previous?.createdAt ??
              (person.createdAt.isEmpty ? now : person.createdAt),
          updatedAt: now,
          updatedBy: updatedBy,
          version: previous == null ? 1 : previous.version + 1,
          deletedAt: '',
        );
      }
      return person;
    }).toList();

    final preparedRelations = nextData.marriageRelations.map((relation) {
      final previous = previousRelations[relation.id];
      if (previous == null || _marriagePayloadChanged(previous, relation)) {
        changedRelationIds.add(relation.id);
        return relation.copyWith(
          familyId: relation.familyId.isEmpty
              ? nextData.mainFamilyCode
              : relation.familyId,
          createdAt:
              previous?.createdAt ??
              (relation.createdAt.isEmpty ? now : relation.createdAt),
          updatedAt: now,
          updatedBy: updatedBy,
          version: previous == null ? 1 : previous.version + 1,
        );
      }
      return relation;
    }).toList();

    final prepared = nextData.copyWith(
      people: preparedPeople,
      marriageRelations: preparedRelations,
    );
    final peopleById = {
      for (final person in prepared.people) person.id: person,
    };
    final relationsById = {
      for (final relation in prepared.marriageRelations) relation.id: relation,
    };
    final operations = <PendingSyncItem>[
      for (final id in changedPeopleIds)
        ref
            .read(syncServiceProvider)
            .personOperation(
              person: peopleById[id]!,
              action: previousPeople.containsKey(id) ? 'update' : 'create',
              updatedBy: relationship,
            ),
      for (final id in changedRelationIds)
        ref
            .read(syncServiceProvider)
            .marriageOperation(
              relation: relationsById[id]!,
              action: previousRelations.containsKey(id) ? 'update' : 'create',
              updatedBy: relationship,
            ),
    ];

    debugPrint(
      'RELATION LINK relationship=$relationship actorRole=$actorRole '
      'changedPeople=${changedPeopleIds.join(',')} '
      'changedRelations=${changedRelationIds.join(',')} '
      'operations=${operations.length}',
    );
    final saved = await save(prepared, syncOperations: operations);
    return _memberSaveResult(saved, operations);
  }

  Future<MemberSaveResult> linkExistingFather({
    required String childId,
    required String fatherId,
    required String actorRole,
    required String adminId,
  }) async {
    final data = await future;
    final linked = const LinkExistingFatherUseCase()(
      data: data,
      childId: childId,
      fatherId: fatherId,
    );
    final normalized = ref
        .read(familyRelationServiceProvider)
        .normalizeRelationships(
          linked.copyWith(
            auditLog: [
              ...linked.auditLog,
              _log(
                'link_father',
                childId,
                linked.mainFamilyCode,
                actorRole: actorRole,
                adminId: adminId,
                description: '$fatherId->$childId',
              ),
            ],
          ),
        );
    return saveRelationshipChange(
      normalized,
      relationship: 'link_father',
      actorRole: actorRole,
      adminId: adminId,
    );
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

  Future<int> clearActivityLog({
    required ActivityLogClearPeriod period,
    required String actorRole,
    required String adminId,
    required String actorUid,
  }) async {
    final service = ref.read(activityLogServiceProvider);
    if (!service.canClearActivityLog(actorRole)) {
      throw StateError('forbidden');
    }
    final data = await future;
    final olderThan = service.thresholdFor(period);
    final retentionLabel = service.labelFor(period);
    await ref
        .read(remoteDatabaseRepositoryProvider)
        .deleteActivityLogs(
          familyId: data.mainFamilyCode,
          olderThan: olderThan,
          actorUid: actorUid,
          actorRole: actorRole,
          retentionLabel: retentionLabel,
        );
    final result = service.clearLocalEntries(data, period: period);
    await ref.read(localJsonRepositoryProvider).saveFamilyTree(result.data);
    state = AsyncData(result.data);
    return result.deletedCount;
  }

  Future<void> setLanguage(String languageCode, {bool manual = true}) async {
    final data = await future;
    final normalized = languageCode.trim().toLowerCase();
    final settings = data.appSettings.languageSettings;
    await save(
      data.copyWith(
        language: normalized,
        appSettings: data.appSettings.copyWith(
          languageSettings: settings.copyWith(
            manualLocale: manual ? normalized : settings.manualLocale,
            currentLocale: normalized,
          ),
        ),
      ),
    );
  }

  Future<void> updateAppSettings(
    AppSettings settings, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final normalized = ref.read(appSettingsServiceProvider).normalize(settings);
    await save(
      data.copyWith(
        appSettings: normalized,
        auditLog: [
          ...data.auditLog,
          _log(
            'app_settings_updated',
            '',
            data.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: normalized.applicationTitle,
          ),
        ],
      ),
    );
  }

  Future<void> recalculateGenerations({
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    await save(
      ref
          .read(genealogyGenerationServiceProvider)
          .recalculate(data)
          .copyWith(
            auditLog: [
              ...data.auditLog,
              _log(
                'generations_recalculated',
                '',
                data.mainFamilyCode,
                actorRole: actorRole,
                adminId: adminId,
              ),
            ],
          ),
    );
  }

  Future<void> declareDivorce(
    MarriageRelation relation, {
    required String divorceDate,
    String notes = '',
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final updated = ref
        .read(marriageServiceProvider)
        .declareDivorce(data, relation, divorceDate: divorceDate, notes: notes);
    final updatedRelation = updated.marriageRelations.firstWhere(
      (item) => item.id == relation.id,
      orElse: () => relation,
    );
    await save(
      updated.copyWith(
        auditLog: [
          ...updated.auditLog,
          _log(
            'marriage_divorced',
            relation.personId,
            updated.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${relation.personId}-${relation.spouseId}',
          ),
        ],
      ),
      syncOperation: ref
          .read(syncServiceProvider)
          .marriageOperation(
            relation: updatedRelation,
            action: 'update',
            updatedBy: adminId,
          ),
    );
  }

  Future<void> restoreMarriage(
    MarriageRelation relation, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' && actorRole != 'admin') {
      throw StateError('forbidden');
    }
    final data = await future;
    final updated = ref
        .read(marriageServiceProvider)
        .restoreMarriage(data, relation);
    final updatedRelation = updated.marriageRelations.firstWhere(
      (item) => item.id == relation.id,
      orElse: () => relation,
    );
    await save(
      updated.copyWith(
        auditLog: [
          ...updated.auditLog,
          _log(
            'marriage_restored',
            relation.personId,
            updated.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${relation.personId}-${relation.spouseId}',
          ),
        ],
      ),
      syncOperation: ref
          .read(syncServiceProvider)
          .marriageOperation(
            relation: updatedRelation,
            action: 'restore',
            updatedBy: adminId,
          ),
    );
  }

  Future<MemberSaveResult> upsertMarriageUnion(
    MarriageRelation draft, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' &&
        actorRole != 'admin' &&
        actorRole != 'editor') {
      throw StateError('forbidden');
    }
    final data = await future;
    final existing = ref
        .read(marriageServiceProvider)
        .relationBetween(data, draft.personId, draft.spouseId);
    final updated = ref
        .read(marriageServiceProvider)
        .upsertUnion(data, draft, updatedBy: adminId);
    final updatedRelation = updated.marriageRelations.firstWhere(
      (item) => item.involves(draft.personId) && item.involves(draft.spouseId),
    );
    final operation = ref
        .read(syncServiceProvider)
        .marriageOperation(
          relation: updatedRelation,
          action: existing == null ? 'create' : 'update',
          updatedBy: adminId,
        );
    final saved = await save(
      updated.copyWith(
        auditLog: [
          ...updated.auditLog,
          _log(
            existing == null ? 'marriage_created' : 'marriage_updated',
            draft.personId,
            updated.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${draft.personId}-${draft.spouseId}',
          ),
        ],
      ),
      syncOperation: operation,
    );
    return _memberSaveResult(saved, [operation]);
  }

  Future<MemberSaveResult> deleteMarriageUnion(
    MarriageRelation relation, {
    required String actorRole,
    required String adminId,
  }) async {
    if (actorRole != 'superAdmin' &&
        actorRole != 'admin' &&
        actorRole != 'editor') {
      throw StateError('forbidden');
    }
    final data = await future;
    final updated = ref
        .read(marriageServiceProvider)
        .deleteUnion(data, relation, deletedBy: adminId);
    final updatedRelation = updated.marriageRelations.firstWhere(
      (item) => item.id == relation.id,
      orElse: () => relation,
    );
    final operation = ref
        .read(syncServiceProvider)
        .marriageOperation(
          relation: updatedRelation,
          action: 'update',
          updatedBy: adminId,
        );
    final saved = await save(
      updated.copyWith(
        auditLog: [
          ...updated.auditLog,
          _log(
            'marriage_deleted',
            relation.personId,
            updated.mainFamilyCode,
            actorRole: actorRole,
            adminId: adminId,
            description: '${relation.personId}-${relation.spouseId}',
          ),
        ],
      ),
      syncOperation: operation,
    );
    return _memberSaveResult(saved, [operation]);
  }

  Future<MemberSaveResult> upsertPerson(
    Person person,
    String action, {
    bool allowDuplicate = false,
  }) async {
    final data = await future;
    final now = DateTime.now().toIso8601String();
    final people = [...data.people];
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1 && !allowDuplicate) {
      final duplicate = ref
          .read(personDuplicateServiceProvider)
          .hasBlockingDuplicate(draft: person, people: data.people);
      if (duplicate) {
        throw StateError('duplicate_person');
      }
    }
    final preparedPerson = person.copyWith(
      createdAt: index == -1
          ? (person.createdAt.isEmpty ? now : person.createdAt)
          : people[index].createdAt,
      updatedAt: now,
      updatedBy: action,
      version: index == -1 ? 1 : people[index].version + 1,
      deletedAt: '',
    );
    if (index == -1) {
      people.add(preparedPerson);
    } else {
      await createBackup();
      people[index] = preparedPerson;
    }
    var nextData = ref
        .read(familyRelationServiceProvider)
        .normalizeRelationships(
          data.copyWith(
            people: people,
            auditLog: [
              ...data.auditLog,
              _log(action, person.id, person.familyCode),
            ],
          ),
        );
    if (index == -1 && action == 'create_person') {
      nextData = ref
          .read(familyAnnouncementServiceProvider)
          .addBirthAnnouncementIfNeeded(nextData, preparedPerson);
    }
    final operation = ref
        .read(syncServiceProvider)
        .personOperation(
          person: preparedPerson,
          action: index == -1 ? 'create' : 'update',
          updatedBy: action,
        );
    final saved = await save(nextData, syncOperation: operation);
    return _memberSaveResult(saved, [operation]);
  }

  Future<MemberSaveResult> upsertPersonWithParents(
    Person person,
    String action, {
    ParentDraft? fatherDraft,
    ParentDraft? motherDraft,
    bool linkParentsAsCouple = false,
    String parentCoupleStatus = 'unknown',
    String actorRole = '',
    String adminId = '',
    bool allowDuplicate = false,
  }) async {
    final data = await future;
    final now = DateTime.now().toIso8601String();
    final updatedBy = adminId.trim().isEmpty ? actorRole : adminId.trim();
    final people = [...data.people];
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1 && !allowDuplicate) {
      final duplicate = ref
          .read(personDuplicateServiceProvider)
          .hasBlockingDuplicate(draft: person, people: data.people);
      if (duplicate) {
        throw StateError('duplicate_person');
      }
    }
    final preparedPerson = person.copyWith(
      createdAt: index == -1
          ? (person.createdAt.isEmpty ? now : person.createdAt)
          : people[index].createdAt,
      updatedAt: now,
      updatedBy: updatedBy.isEmpty ? action : updatedBy,
      version: index == -1 ? 1 : people[index].version + 1,
      deletedAt: '',
    );
    if (index == -1) {
      people.add(preparedPerson);
    } else {
      await createBackup();
      people[index] = preparedPerson;
    }

    var nextData = data.copyWith(
      people: people,
      auditLog: [
        ...data.auditLog,
        _log(
          action,
          person.id,
          person.familyCode,
          actorRole: actorRole,
          adminId: adminId,
        ),
      ],
    );
    final parentResult = ref
        .read(parentAutoCreationServiceProvider)
        .apply(
          data: nextData,
          child: preparedPerson,
          fatherDraft: fatherDraft,
          motherDraft: motherDraft,
          linkParentsAsCouple: linkParentsAsCouple,
          parentCoupleStatus: parentCoupleStatus,
          actorRole: actorRole,
          adminId: adminId,
        );
    nextData = ref
        .read(familyRelationServiceProvider)
        .normalizeRelationships(
          parentResult.data.copyWith(
            auditLog: [
              ...parentResult.data.auditLog,
              ...parentResult.auditLogs,
            ],
          ),
        );
    if (index == -1 && action == 'create_person') {
      final updatedChild = nextData.people.firstWhere(
        (item) => item.id == preparedPerson.id,
        orElse: () => preparedPerson,
      );
      nextData = ref
          .read(familyAnnouncementServiceProvider)
          .addBirthAnnouncementIfNeeded(nextData, updatedChild);
    }

    final updatedChild = nextData.people.firstWhere(
      (item) => item.id == preparedPerson.id,
      orElse: () => preparedPerson,
    );
    final operations = [
      ref
          .read(syncServiceProvider)
          .personOperation(
            person: updatedChild,
            action: index == -1 ? 'create' : 'update',
            updatedBy: updatedBy.isEmpty ? action : updatedBy,
          ),
      ...parentResult.createdParents.map(
        (parent) => ref
            .read(syncServiceProvider)
            .personOperation(
              person: parent,
              action: 'create',
              updatedBy: updatedBy.isEmpty ? 'auto_parent_creation' : updatedBy,
            ),
      ),
      ...parentResult.updatedParents.map(
        (parent) => ref
            .read(syncServiceProvider)
            .personOperation(
              person: parent,
              action: 'update',
              updatedBy: updatedBy.isEmpty ? 'parent_link' : updatedBy,
            ),
      ),
      ...parentResult.createdMarriageRelations.map(
        (relation) => ref
            .read(syncServiceProvider)
            .marriageOperation(
              relation: relation,
              action: 'create',
              updatedBy: 'auto_parent_creation',
            ),
      ),
    ];

    final saved = await save(nextData, syncOperations: operations);
    return _memberSaveResult(saved, operations);
  }

  Future<void> deletePerson(String id) async {
    final data = await future;
    await createBackup();
    await save(
      data.copyWith(
        people: data.people.where((person) => person.id != id).toList(),
        auditLog: [...data.auditLog, _log('delete_person', id, '')],
      ),
      syncOperation: ref
          .read(syncServiceProvider)
          .deletePersonOperation(personId: id, updatedBy: 'delete_person'),
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
    await save(
      data.copyWith(familyLinks: links),
      syncOperation: ref
          .read(syncServiceProvider)
          .familyLinkOperation(
            link: link,
            action: index == -1 ? 'create' : 'update',
            updatedBy: 'family_link_upsert',
          ),
    );
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

  Future<({String familyCode, String adminCode, String modificationCode})>
  resetCodesWithSuperAdminRecovery({
    required String recoveryCode,
    String? familyAccessCode,
    String? adminKpiCode,
    String? modificationCode,
    required bool generateAll,
  }) async {
    final data = await future;
    final recoveryService = ref.read(superAdminRecoveryServiceProvider);
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    if (!recoveryService.validate(data, recoveryCode)) {
      await save(
        data.copyWith(
          auditLog: [
            ...data.auditLog,
            _log(
              'super_admin_recovery_failed',
              '',
              data.mainFamilyCode,
              actorRole: 'superAdminRecovery',
              description: 'Code secret Super Admin incorrect.',
            ),
          ],
        ),
      );
      throw StateError('recovery_code_invalid');
    }

    if (!data.superAdminRecovery.allowResetAllCodes) {
      throw StateError('recovery_reset_disabled');
    }

    await ref.read(backupServiceProvider).createBackup();

    final codeService = ref.read(accessCodeServiceProvider);
    final nextFamilyCode =
        generateAll || (familyAccessCode ?? '').trim().isEmpty
        ? codeService.generateUniqueSecureCode(data, 'familyAccess')
        : familyAccessCode!.trim();
    final nextAdminCode = generateAll || (adminKpiCode ?? '').trim().isEmpty
        ? codeService.generateUniqueSecureCode(data, 'adminKpi')
        : adminKpiCode!.trim();
    final nextModificationCode =
        generateAll || (modificationCode ?? '').trim().isEmpty
        ? codeService.generateUniqueSecureCode(data, 'modification')
        : modificationCode!.trim();

    final disabledTypes = {
      'familyAccess',
      'adminKpi',
      'modification',
      'temporary',
      'linkedFamily',
    };
    final disabledAccessCodes = data.accessCodes
        .map(
          (code) => disabledTypes.contains(code.type)
              ? code.copyWith(enabled: false, updatedAt: nowIso)
              : code,
        )
        .toList();
    final newAccessCodes = [
      AccessCode(
        id: 'code${now.microsecondsSinceEpoch}family',
        code: nextFamilyCode,
        label: 'Code accès familial réinitialisé',
        type: 'familyAccess',
        role: 'viewer',
        familyCode: data.mainFamilyCode.toUpperCase(),
        createdByAdminId: 'superAdminRecovery',
        createdByName: 'Super Admin Recovery',
        createdAt: nowIso,
      ),
      AccessCode(
        id: 'code${now.microsecondsSinceEpoch}admin',
        code: nextAdminCode,
        label: 'Code Admin KPI réinitialisé',
        type: 'adminKpi',
        role: 'admin',
        familyCode: data.mainFamilyCode.toUpperCase(),
        createdByAdminId: 'superAdminRecovery',
        createdByName: 'Super Admin Recovery',
        createdAt: nowIso,
      ),
      AccessCode(
        id: 'code${now.microsecondsSinceEpoch}edit',
        code: nextModificationCode,
        label: 'Code modification réinitialisé',
        type: 'modification',
        role: 'editor',
        familyCode: data.mainFamilyCode.toUpperCase(),
        createdByAdminId: 'superAdminRecovery',
        createdByName: 'Super Admin Recovery',
        createdAt: nowIso,
      ),
    ];

    final nextFamilyCodes = data.familyCodes.isEmpty
        ? [
            FamilyCode(
              code: nextFamilyCode,
              familyName: 'Famille principale',
              role: 'owner',
              status: 'accepted',
            ),
          ]
        : data.familyCodes
              .asMap()
              .entries
              .map(
                (entry) => entry.key == 0 || generateAll
                    ? entry.value.copyWith(
                        code: entry.key == 0
                            ? nextFamilyCode
                            : codeService.generateSecureCode('linkedFamily'),
                      )
                    : entry.value,
              )
              .toList();

    final nextAdminAccess = data.adminAccess.copyWith(
      currentAdminCode: nextAdminCode,
      lastChangedAt: nowIso,
      nextChangeDueAt: DateTime(
        now.year,
        now.month + data.adminAccess.rotationMonths,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ).toIso8601String(),
      codeHistory: [
        ...data.adminAccess.codeHistory.map(
          (item) => item.expiredAt.isEmpty
              ? AdminCodeHistory(
                  code: item.code,
                  createdAt: item.createdAt,
                  expiredAt: nowIso,
                  changedByAdminId: item.changedByAdminId,
                )
              : item,
        ),
        AdminCodeHistory(
          code: nextAdminCode,
          createdAt: nowIso,
          changedByAdminId: 'superAdminRecovery',
        ),
      ],
    );

    final nextModificationCodes = [
      ...data.modificationCodes.map(
        (code) => code.copyWith(enabled: false, usedCount: code.usedCount),
      ),
      ModificationCode(
        code: nextModificationCode,
        label: 'Code modification réinitialisé',
        createdByAdminId: 'superAdminRecovery',
      ),
    ];

    await save(
      data.copyWith(
        familyCodes: nextFamilyCodes,
        accessCodes: [...disabledAccessCodes, ...newAccessCodes],
        modificationCodes: nextModificationCodes,
        adminAccess: nextAdminAccess,
        superAdminRecovery: data.superAdminRecovery.copyWith(
          lastUsedAt: nowIso,
          lastResetAt: nowIso,
        ),
        auditLog: [
          ...data.auditLog,
          _log(
            'access_codes_reset',
            '',
            data.mainFamilyCode,
            actorRole: 'superAdminRecovery',
          ),
          _log(
            'admin_code_reset',
            '',
            data.mainFamilyCode,
            actorRole: 'superAdminRecovery',
          ),
          _log(
            'modification_code_reset',
            '',
            data.mainFamilyCode,
            actorRole: 'superAdminRecovery',
          ),
        ],
      ),
    );

    return (
      familyCode: nextFamilyCode,
      adminCode: nextAdminCode,
      modificationCode: nextModificationCode,
    );
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

  Future<String?> _readBundledFamilyJson() async {
    const assetPath = 'assets/data/family_tree.json';
    try {
      if (kIsWeb) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        return NetworkAssetBundle(
          Uri.base,
        ).loadString('assets/$assetPath?v=$cacheBuster');
      }
      return rootBundle.loadString(assetPath);
    } catch (_) {
      return null;
    }
  }

  String? _selectNewestJson(String? storedRaw, String? sourceRaw) {
    if (storedRaw == null || storedRaw.trim().isEmpty) return sourceRaw;
    if (sourceRaw == null || sourceRaw.trim().isEmpty) return storedRaw;
    final storedDate = _lastUpdatedFromRaw(storedRaw);
    final sourceDate = _lastUpdatedFromRaw(sourceRaw);
    if (sourceDate == null) return storedRaw;
    if (storedDate == null) return sourceRaw;
    return sourceDate.isAfter(storedDate) ? sourceRaw : storedRaw;
  }

  FamilyTreeData _preserveUsefulLocalData(
    FamilyTreeData loaded, {
    required String? storedRaw,
    required bool sourceSelected,
  }) {
    if (!sourceSelected || storedRaw == null || storedRaw.trim().isEmpty) {
      return loaded;
    }
    try {
      final stored = FamilyTreeData.fromJson(
        jsonDecode(storedRaw) as Map<String, dynamic>,
      );
      final storedLanguage = stored.language.trim();
      final storedLanguageSettings = stored.appSettings.languageSettings;
      return loaded.copyWith(
        language: storedLanguage.isEmpty ? loaded.language : storedLanguage,
        appSettings: loaded.appSettings.copyWith(
          languageSettings:
              storedLanguageSettings.currentLocale.isEmpty &&
                  storedLanguageSettings.manualLocale.isEmpty
              ? loaded.appSettings.languageSettings
              : storedLanguageSettings,
          tutorialSettings: stored.appSettings.tutorialSettings,
        ),
        familyCodes: loaded.familyCodes.isEmpty
            ? stored.familyCodes
            : loaded.familyCodes,
        accessCodes: stored.accessCodes,
        modificationCodes: stored.modificationCodes,
        adminAccess: stored.adminAccess,
        superAdminRecovery: stored.superAdminRecovery,
      );
    } catch (_) {
      return loaded;
    }
  }

  FamilyTreeData _normalizeHomeSyncState(FamilyTreeData data) {
    if (data.syncSettings.syncStatus != 'error') return data;
    final hasPending = data.pendingSyncQueue.any(
      (item) => item.status != 'synced' && item.status != 'resolved',
    );
    final status = hasPending ? 'pending' : 'synced';
    return data.copyWith(
      syncSettings: data.syncSettings.copyWith(syncStatus: status),
      appSettings: data.appSettings.copyWith(
        storageSettings: data.appSettings.storageSettings.copyWith(
          syncStatus: status,
        ),
      ),
    );
  }

  DateTime? _lastUpdatedFromRaw(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final explicit = _parseDate(json['lastUpdatedAt']);
      if (explicit != null) return explicit;
      final dataVersion = _parseDataVersion(json['dataVersion']);
      if (dataVersion != null) return dataVersion;
      return _latestNestedDate(json);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  DateTime? _parseDataVersion(Object? value) {
    if (value is! String || value.length < 10) return null;
    final normalized = value.substring(0, 10);
    return DateTime.tryParse(normalized);
  }

  DateTime? _latestNestedDate(Object? value) {
    DateTime? latest;
    void visit(Object? item) {
      if (item is Map) {
        for (final entry in item.entries) {
          if (entry.key.toString().toLowerCase().contains('date') ||
              entry.key.toString().toLowerCase().contains('updatedat') ||
              entry.key.toString().toLowerCase().contains('modifiedat')) {
            final parsed = _parseDate(entry.value);
            if (parsed != null && (latest == null || parsed.isAfter(latest!))) {
              latest = parsed;
            }
          }
          visit(entry.value);
        }
      } else if (item is List) {
        for (final child in item) {
          visit(child);
        }
      }
    }

    visit(value);
    return latest;
  }

  FamilyTreeData _withFreshMetadata(FamilyTreeData data) {
    final now = DateTime.now().toIso8601String();
    return data.copyWith(lastUpdatedAt: now, dataVersion: now.substring(0, 10));
  }

  String _encode(FamilyTreeData data) =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  bool _sameGenerations(FamilyTreeData first, FamilyTreeData second) {
    final secondById = {for (final person in second.people) person.id: person};
    for (final person in first.people) {
      if (secondById[person.id]?.generation != person.generation) {
        return false;
      }
    }
    return first.people.length == second.people.length;
  }

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

  MemberSaveResult _memberSaveResult(
    FamilyTreeData data,
    List<PendingSyncItem> operations,
  ) {
    if (operations.isEmpty) {
      return const MemberSaveResult(
        status: MemberSaveStatus.firestoreConfirmed,
      );
    }
    final operationIds = operations.map((item) => item.id).toSet();
    final queued = data.pendingSyncQueue
        .where((item) => operationIds.contains(item.id))
        .toList();
    final authorizationErrors = queued.where(
      (item) =>
          item.lastErrorCode == 'permission-denied' ||
          item.lastErrorCode == 'unauthenticated',
    );
    if (authorizationErrors.isNotEmpty) {
      return MemberSaveResult(
        status: MemberSaveStatus.authorizationRequired,
        lastError: authorizationErrors
            .map((item) => item.lastError)
            .where((item) => item.trim().isNotEmpty)
            .join('\n'),
        lastErrorCode: authorizationErrors
            .map((item) => item.lastErrorCode)
            .where((item) => item.trim().isNotEmpty)
            .join('\n'),
      );
    }
    if (queued.any((item) => item.status == 'failed')) {
      return MemberSaveResult(
        status: MemberSaveStatus.failed,
        lastError: queued
            .map((item) => item.lastError)
            .where((item) => item.trim().isNotEmpty)
            .join('\n'),
        lastErrorCode: queued
            .map((item) => item.lastErrorCode)
            .where((item) => item.trim().isNotEmpty)
            .join('\n'),
      );
    }
    if (queued.isNotEmpty || data.syncSettings.syncStatus == 'offline') {
      return const MemberSaveResult(status: MemberSaveStatus.localPending);
    }
    final storage = data.appSettings.storageSettings;
    if (!storage.remoteDatabaseEnabled || storage.mode == 'jsonOnly') {
      return const MemberSaveResult(status: MemberSaveStatus.localPending);
    }
    return const MemberSaveResult(status: MemberSaveStatus.firestoreConfirmed);
  }

  bool _personPayloadChanged(Person previous, Person next) =>
      !_samePayload(previous.toJson(), next.toJson());

  bool _marriagePayloadChanged(
    MarriageRelation previous,
    MarriageRelation next,
  ) => !_samePayload(previous.toJson(), next.toJson());

  bool _samePayload(Map<String, dynamic> first, Map<String, dynamic> second) {
    final left = Map<String, dynamic>.from(first);
    final right = Map<String, dynamic>.from(second);
    for (final key in const [
      'createdAt',
      'updatedAt',
      'updatedBy',
      'version',
    ]) {
      left.remove(key);
      right.remove(key);
    }
    return const JsonEncoder.withIndent('  ').convert(left) ==
        const JsonEncoder.withIndent('  ').convert(right);
  }
}
