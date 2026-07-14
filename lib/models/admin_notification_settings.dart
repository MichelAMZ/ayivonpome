class AdminNotificationSettings {
  const AdminNotificationSettings({
    this.enabled = true,
    this.adminEmail = '',
    this.emailEnabled = false,
    this.whatsappEnabled = false,
    this.adminWhatsappNumber = '',
    this.notifyOnWarning = false,
    this.notifyOnCritical = true,
    this.minimumAttemptsForWhatsapp = 3,
    this.cooldownMinutes = 60,
  });

  final bool enabled;
  final String adminEmail;
  final bool emailEnabled;
  final bool whatsappEnabled;
  final String adminWhatsappNumber;
  final bool notifyOnWarning;
  final bool notifyOnCritical;
  final int minimumAttemptsForWhatsapp;
  final int cooldownMinutes;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'adminEmail': adminEmail,
    'emailEnabled': emailEnabled,
    'whatsappEnabled': whatsappEnabled,
    'adminWhatsappNumber': adminWhatsappNumber,
    'notifyOnWarning': notifyOnWarning,
    'notifyOnCritical': notifyOnCritical,
    'minimumAttemptsForWhatsapp': minimumAttemptsForWhatsapp,
    'cooldownMinutes': cooldownMinutes,
  };
}
