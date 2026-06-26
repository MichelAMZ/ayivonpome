import '../models/family_tree_data.dart';
import '../models/modification_code.dart';

class ModificationCodeService {
  ModificationCode? validate(FamilyTreeData data, String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final item in data.modificationCodes) {
      if (item.code.toUpperCase() == normalized && item.isValid) {
        return item;
      }
    }
    return null;
  }
}
