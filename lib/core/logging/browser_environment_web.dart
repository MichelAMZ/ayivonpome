import 'package:web/web.dart' as web;

Map<String, String> readBrowserEnvironment() {
  try {
    final userAgent = web.window.navigator.userAgent;
    return {
      'browser': _browserName(userAgent),
      'userAgent': userAgent.isEmpty ? 'Indisponible' : userAgent,
      'url': web.window.location.href,
    };
  } catch (_) {
    return const {
      'browser': 'Web (détails indisponibles)',
      'userAgent': 'Indisponible',
      'url': 'Indisponible',
    };
  }
}

String _browserName(String userAgent) {
  final value = userAgent.toLowerCase();
  if (value.contains('whatsapp')) return 'WebView WhatsApp';
  if (value.contains('iphone') && value.contains('safari')) {
    return 'Safari iOS';
  }
  if (value.contains('edg/')) return 'Microsoft Edge';
  if (value.contains('chrome/') || value.contains('crios/')) return 'Chrome';
  if (value.contains('safari/')) return 'Safari';
  if (value.contains('firefox/') || value.contains('fxios/')) return 'Firefox';
  return 'Navigateur Web';
}
