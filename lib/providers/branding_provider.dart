import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branding_settings.dart';
import '../services/branding_service.dart';
import 'app_settings_provider.dart';

final brandingServiceProvider = Provider<BrandingService>(
  (ref) => const BrandingService(),
);

final brandingProvider = Provider<BrandingSettings>((ref) {
  return ref.watch(appSettingsProvider).branding;
});
