import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/app_settings.dart';
import 'package:ayivonpome/services/app_settings_service.dart';

void main() {
  test('AppSettings serializes tree view settings', () {
    const settings = AppSettings(
      applicationTitle: 'Famille AYIVON',
      treeSettings: TreeViewSettings(
        initialZoom: 0.60,
        minZoom: 0.20,
        maxZoom: 3.00,
        rememberLastZoom: true,
      ),
    );

    final parsed = AppSettings.fromJson(settings.toJson());

    expect(parsed.treeSettings.initialZoom, 0.60);
    expect(parsed.treeSettings.minZoom, 0.20);
    expect(parsed.treeSettings.maxZoom, 3.00);
    expect(parsed.treeSettings.rememberLastZoom, isTrue);
  });

  test('AppSettingsService clamps invalid tree zoom values', () {
    const service = AppSettingsService();
    const settings = AppSettings(
      treeSettings: TreeViewSettings(
        initialZoom: 8.00,
        minZoom: 0.01,
        maxZoom: 9.00,
      ),
    );

    final normalized = service.normalize(settings);

    expect(normalized.treeSettings.minZoom, 0.10);
    expect(normalized.treeSettings.maxZoom, 5.00);
    expect(normalized.treeSettings.initialZoom, 5.00);
  });
}
