import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../widgets/responsive.dart';

class TreeViewSettingsService {
  const TreeViewSettingsService();

  static const _lastZoomKey = 'family_tree_last_zoom';

  double getInitialZoom(BuildContext context, TreeViewSettings settings) {
    final configured = settings.initialZoom;
    if (ResponsiveBreakpoints.isMobile(context)) {
      return configured < 0.80 ? 0.80 : configured;
    }
    if (ResponsiveBreakpoints.isTablet(context)) {
      return configured < 0.70 ? 0.70 : configured;
    }
    return configured;
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
    return zoom.clamp(settings.minZoom, settings.maxZoom).toDouble();
  }
}
