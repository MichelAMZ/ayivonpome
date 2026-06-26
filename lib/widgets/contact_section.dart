import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../services/auth_code_service.dart';
import 'contact_action_button.dart';

class ContactSection extends ConsumerWidget {
  const ContactSection({
    super.key,
    required this.person,
    required this.session,
  });

  final Person person;
  final AuthSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = _visible(person.email, person.emailVisibility);
    final phone = _visible(person.phoneNumber, person.phoneVisibility);
    final whatsapp = _visible(person.whatsappNumber, person.whatsappVisibility);
    final hasRawContact = person.email.trim().isNotEmpty ||
        person.phoneNumber.trim().isNotEmpty ||
        person.whatsappNumber.trim().isNotEmpty;
    final hasAny = email.isNotEmpty || phone.isNotEmpty || whatsapp.isNotEmpty;

    if (!hasRawContact) {
      return const SizedBox.shrink();
    }
    if (!person.allowContact) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.communication),
          subtitle: Text(l10n.contactDisabled),
        ),
      );
    }
    if (!hasAny) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communication, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (email.isNotEmpty)
                  ContactActionButton(
                    icon: Icons.email_outlined,
                    label: l10n.sendEmail,
                    onPressed: () => _confirm(
                      context,
                      l10n.sendEmail,
                      email,
                      () => ref.read(communicationServiceProvider).sendEmail(
                            email: email,
                            subject: l10n.familyEmailSubject,
                            body: l10n.familyEmailBody,
                          ),
                    ),
                  ),
                if (whatsapp.isNotEmpty)
                  ContactActionButton(
                    icon: Icons.chat_outlined,
                    label: l10n.sendWhatsapp,
                    onPressed: () => _confirm(
                      context,
                      l10n.openWhatsapp,
                      whatsapp,
                      () => ref.read(communicationServiceProvider).openWhatsApp(
                            phoneNumber: whatsapp,
                            message: l10n.familyWhatsappMessage,
                          ),
                    ),
                  ),
                if (phone.isNotEmpty)
                  ContactActionButton(
                    icon: Icons.call_outlined,
                    label: l10n.call,
                    onPressed: () => _confirm(
                      context,
                      l10n.call,
                      phone,
                      () => ref.read(communicationServiceProvider).makePhoneCall(phone),
                    ),
                  ),
                if (email.isNotEmpty)
                  ContactActionButton(
                    icon: Icons.copy_outlined,
                    label: l10n.copyEmail,
                    onPressed: () async {
                      await ref.read(communicationServiceProvider).copyEmail(email);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.emailCopied)),
                        );
                      }
                    },
                  ),
                if (phone.isNotEmpty || whatsapp.isNotEmpty)
                  ContactActionButton(
                    icon: Icons.content_copy_outlined,
                    label: l10n.copyPhone,
                    onPressed: () async {
                      await ref
                          .read(communicationServiceProvider)
                          .copyPhone(phone.isNotEmpty ? phone : whatsapp);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.phoneCopied)),
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _visible(String value, String visibility) {
    if (value.trim().isEmpty || visibility == 'private') {
      return '';
    }
    if (visibility == 'familyOnly' && session == null) {
      return '';
    }
    return value.trim();
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    String value,
    Future<void> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.enter),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
