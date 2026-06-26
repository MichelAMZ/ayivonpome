import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import '../models/family_code.dart';
import '../models/family_link.dart';
import '../models/family_notification.dart';
import '../models/family_tree_data.dart';
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
    return FamilyTreeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(FamilyTreeData data) async {
    await ref.read(jsonStorageServiceProvider).writeRaw(_encode(data));
    state = AsyncData(data);
  }

  Future<String?> createBackup() => ref.read(backupServiceProvider).createBackup();

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
    await save(
      data.copyWith(
        people: people,
        auditLog: [...data.auditLog, _log(action, person.id, person.familyCode)],
      ),
    );
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

  Future<void> upsertNotification(FamilyNotification notification) async {
    final data = await future;
    final notifications = [...data.notifications];
    final index = notifications.indexWhere((item) => item.id == notification.id);
    if (index == -1) {
      notifications.add(notification);
    } else {
      notifications[index] = notification;
    }
    await save(
      data.copyWith(
        notifications: notifications,
        auditLog: [
          ...data.auditLog,
          _log('notification_${notification.channel}', notification.personId, ''),
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

  Future<void> importData(FamilyTreeData imported, {required bool merge}) async {
    final data = await future;
    await createBackup();
    final next = merge
        ? ref.read(importExportServiceProvider).merge(data, imported)
        : imported;
    await save(
      next.copyWith(
        auditLog: [...next.auditLog, _log('import_json', '', next.mainFamilyCode)],
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
