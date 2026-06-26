import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationService {
  Uri emailUri({
    required String email,
    required String subject,
    required String body,
  }) {
    return Uri(
      scheme: 'mailto',
      path: email.trim(),
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
  }

  Uri whatsappUri({required String phoneNumber, required String message}) {
    final normalized = _digitsAndPlus(phoneNumber);
    return Uri.https('wa.me', '/$normalized', {'text': message});
  }

  Uri phoneUri(String phoneNumber) => Uri(scheme: 'tel', path: phoneNumber.trim());

  Future<void> sendEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    await _launch(emailUri(email: email, subject: subject, body: body));
  }

  Future<void> openWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    await _launch(whatsappUri(phoneNumber: phoneNumber, message: message));
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    await _launch(phoneUri(phoneNumber));
  }

  Future<void> copyEmail(String email) =>
      Clipboard.setData(ClipboardData(text: email.trim()));

  Future<void> copyPhone(String phoneNumber) =>
      Clipboard.setData(ClipboardData(text: phoneNumber.trim()));

  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text.trim()));

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('cannot_open_external_app');
    }
  }

  String _digitsAndPlus(String value) {
    final trimmed = value.trim();
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if ((char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) ||
          (i == 0 && char == '+')) {
        buffer.write(char);
      }
    }
    return buffer.toString().replaceFirst('+', '');
  }
}
