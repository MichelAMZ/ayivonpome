import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'family_tree_provider.dart';

final appSettingsProvider = Provider<AppSettings>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  return data?.appSettings ?? const AppSettings();
});
