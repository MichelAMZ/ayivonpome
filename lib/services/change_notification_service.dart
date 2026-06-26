import '../models/audit_log.dart';
import '../models/change_notification.dart';
import '../models/family_tree_data.dart';
import '../models/modification_history.dart';
import '../models/person.dart';

class ChangeNotificationService {
  const ChangeNotificationService();

  FamilyTreeData syncFromAuditLog(FamilyTreeData data) {
    final knownIds = {
      ...data.changeNotifications.map(
        (item) => item.id.replaceFirst('cn_', ''),
      ),
      ...data.modificationHistory.map(
        (item) => item.id.replaceFirst('mh_', ''),
      ),
    };
    final notifications = [...data.changeNotifications];
    final history = [...data.modificationHistory];

    for (final log in data.auditLog) {
      if (knownIds.contains(log.id) || !_isTracked(log.action)) continue;
      final normalizedAction = _normalizeAction(log.action);
      final person = _personById(data, log.personId);
      final personName = person?.fullName ?? log.personId;
      final modifierName = _modifierName(data, log);
      final message = _message(
        action: normalizedAction,
        personName: personName.isEmpty ? 'Personne inconnue' : personName,
        modifierName: modifierName,
      );
      notifications.add(
        ChangeNotification(
          id: 'cn_${log.id}',
          personId: log.personId,
          personFullName: personName,
          action: normalizedAction,
          modifiedByAdminId: log.adminId,
          modifiedByName: modifierName,
          modifiedAt: log.date,
          message: message,
        ),
      );
      final modifiedAt = DateTime.tryParse(log.date) ?? DateTime.now();
      history.add(
        ModificationHistory(
          id: 'mh_${log.id}',
          personId: log.personId,
          personFullName: personName,
          action: normalizedAction,
          modifiedByAdminId: log.adminId,
          modifiedByName: modifierName,
          modifiedAt: log.date,
          details: log.description.isEmpty ? message : log.description,
          expiresAt: DateTime(
            modifiedAt.year,
            modifiedAt.month + 3,
            modifiedAt.day,
            modifiedAt.hour,
            modifiedAt.minute,
            modifiedAt.second,
          ).toIso8601String(),
        ),
      );
      knownIds.add(log.id);
    }

    return data.copyWith(
      changeNotifications: notifications,
      modificationHistory: history,
    );
  }

  List<ChangeNotification> unseenForCode(FamilyTreeData data, String code) {
    if (code.trim().isEmpty) return const [];
    final normalized = code.trim().toUpperCase();
    final items =
        data.changeNotifications
            .where(
              (item) => !item.seenByCodes
                  .map((seenCode) => seenCode.toUpperCase())
                  .contains(normalized),
            )
            .toList()
          ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  FamilyTreeData markSeen(
    FamilyTreeData data,
    String code,
    Iterable<String> notificationIds,
  ) {
    final normalized = code.trim().toUpperCase();
    final selectedIds = notificationIds.toSet();
    return data.copyWith(
      changeNotifications: data.changeNotifications.map((item) {
        if (!selectedIds.contains(item.id)) return item;
        return item.copyWith(
          seenByCodes: {...item.seenByCodes, normalized}.toList(),
        );
      }).toList(),
    );
  }

  bool _isTracked(String action) {
    return {
      'create_person',
      'edit_person',
      'delete_person',
      'add_father',
      'add_mother',
      'add_child',
      'add_brother',
      'add_sister',
      'add_spouse',
      'link_father',
      'link_mother',
      'link_child',
      'link_spouse',
      'family_link_accepted',
      'family_link_refused',
      'modification_code_accepted',
      'modification_code_refused',
      'admin_action',
    }.contains(action);
  }

  String _normalizeAction(String action) {
    return switch (action) {
      'create_person' => 'person_added',
      'edit_person' => 'person_updated',
      'delete_person' => 'person_deleted',
      'add_father' ||
      'add_mother' ||
      'add_child' ||
      'add_brother' ||
      'add_sister' ||
      'add_spouse' ||
      'link_father' ||
      'link_mother' ||
      'link_child' ||
      'link_spouse' => 'relationship_added',
      'modification_code_accepted' ||
      'modification_code_refused' => 'modification_code_used',
      _ => action,
    };
  }

  Person? _personById(FamilyTreeData data, String id) {
    for (final person in data.people) {
      if (person.id == id) return person;
    }
    return null;
  }

  String _modifierName(FamilyTreeData data, AuditLog log) {
    for (final admin in data.admins) {
      if (admin.id == log.adminId) return admin.fullName;
    }
    if (log.actorRole.isNotEmpty) return log.actorRole;
    return 'Utilisateur famille';
  }

  String _message({
    required String action,
    required String personName,
    required String modifierName,
  }) {
    final verb = switch (action) {
      'person_added' => 'a été ajoutée',
      'person_updated' => 'a été modifiée',
      'person_deleted' => 'a été supprimée',
      'relationship_added' => 'a reçu un nouveau lien familial',
      'relationship_updated' => 'a eu un lien familial modifié',
      'family_link_accepted' => 'a eu une demande de lien acceptée',
      'family_link_refused' => 'a eu une demande de lien refusée',
      'modification_code_used' => 'a utilisé un code de modification',
      _ => 'a été mise à jour',
    };
    return '$personName $verb par $modifierName.';
  }
}
