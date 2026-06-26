abstract class PushNotificationProvider {
  Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String message,
  });
}

class NoBackendPushNotificationProvider implements PushNotificationProvider {
  @override
  Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String message,
  }) async {
    throw UnsupportedError('Push notifications require a backend.');
  }
}
