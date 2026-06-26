import '../models/family_tree_data.dart';
import '../models/modification_history.dart';

class ModificationHistoryService {
  const ModificationHistoryService();

  FamilyTreeData pruneExpired(FamilyTreeData data) {
    final now = DateTime.now();
    return data.copyWith(
      modificationHistory: data.modificationHistory.where((item) {
        final expiresAt = DateTime.tryParse(item.expiresAt);
        return expiresAt == null || expiresAt.isAfter(now);
      }).toList(),
    );
  }

  List<ModificationHistory> recent(FamilyTreeData data) {
    final items = [...data.modificationHistory]
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }
}
