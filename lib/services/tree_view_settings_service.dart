import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class TreeViewSettingsService {
  const TreeViewSettingsService();

  static const _lastZoomKey = 'family_tree_last_zoom';
  static const _minReadableZoom = 0.40;
  static const _maxReadableZoom = 1.20;

  double getInitialZoom(TreeViewSettings settings) {
    return settings.initialZoom
        .clamp(_minReadableZoom, _maxReadableZoom)
        .toDouble();
  }

  Future<void> saveLastZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastZoomKey, zoom);
  }

  Future<double?> restoreLastZoom(TreeViewSettings settings) async {
    if (!settings.rememberLastZoom) return null;
    final prefs = await SharedPreferences.getInstance();
    final zoom = prefs.getDouble(_lastZoomKey);
    if (zoom == null) return null;
    return zoom.clamp(_minReadableZoom, _maxReadableZoom).toDouble();
  }
}
