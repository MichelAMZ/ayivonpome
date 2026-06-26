import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() {
    tz_data.initializeTimeZones();
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );
    _initialized = await _plugin.initialize(settings) ?? false;
    return _initialized;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> scheduleLocalReminder({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledDate,
  }) async {
    final initialized = await initialize();
    final allowed = await requestPermission();
    if (!initialized || !allowed) {
      throw StateError('notification_permission_required');
    }
    await _plugin.zonedSchedule(
      id,
      title,
      message,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'family_tree_reminders',
          'Family reminders',
          channelDescription: 'FamilyTreeApp local reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
