import '../models/sync_incident.dart';

abstract class NotificationChannel {
  const NotificationChannel();

  String get id;
  bool get enabled;

  Future<void> notifySyncIncident(SyncIncident incident);
}

class DisabledNotificationChannel extends NotificationChannel {
  const DisabledNotificationChannel(this.id);

  @override
  final String id;

  @override
  bool get enabled => false;

  @override
  Future<void> notifySyncIncident(SyncIncident incident) async {}
}
