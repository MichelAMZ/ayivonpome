import '../models/app_settings.dart';

class AppSettingsService {
  const AppSettingsService();

  AppSettings normalize(AppSettings settings) {
    final title = settings.applicationTitle.trim();
    final subtitle = settings.applicationSubtitle.trim();
    final officialFamilyName = settings.officialFamilyName.trim();
    final treeSettings = settings.treeSettings;
    final minZoom = treeSettings.minZoom.clamp(0.10, 1.0).toDouble();
    final maxZoom = treeSettings.maxZoom.clamp(minZoom, 5.0).toDouble();
    final initialZoom = treeSettings.initialZoom
        .clamp(minZoom, maxZoom)
        .toDouble();
    return settings.copyWith(
      applicationTitle: title.isEmpty ? 'FamilyTreeApp' : title,
      applicationSubtitle: subtitle,
      showApplicationSubtitle:
          settings.showApplicationSubtitle && subtitle.isNotEmpty,
      officialFamilyName: officialFamilyName,
      treeSettings: treeSettings.copyWith(
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
    );
  }
}
