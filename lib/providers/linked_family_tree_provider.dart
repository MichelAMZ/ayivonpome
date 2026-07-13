import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_tree_data.dart';
import '../services/linked_family_tree_service.dart';

final linkedFamilyTreeServiceProvider =
    Provider.family<LinkedFamilyTreeService, FamilyTreeData>(
      (ref, data) => LinkedFamilyTreeService(data),
    );
