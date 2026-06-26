import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/admin_user.dart';
import '../providers/app_providers.dart';

class AdminContactCard extends ConsumerWidget {
  const AdminContactCard({super.key, required this.admin});

  final AdminUser admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: Text(admin.fullName),
        subtitle: Text(
          [
            admin.role,
            admin.email,
            admin.phoneNumber,
            admin.whatsappNumber,
          ].where((value) => value.isNotEmpty).join('\n'),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.sendEmail,
              onPressed: admin.email.isEmpty
                  ? null
                  : () => ref.read(communicationServiceProvider).sendEmail(
                        email: admin.email,
                        subject: l10n.modificationCode,
                        body: l10n.adminContactMessage,
                      ),
              icon: const Icon(Icons.email_outlined),
            ),
            IconButton(
              tooltip: l10n.openWhatsapp,
              onPressed: admin.whatsappNumber.isEmpty
                  ? null
                  : () => ref.read(communicationServiceProvider).openWhatsApp(
                        phoneNumber: admin.whatsappNumber,
                        message: l10n.adminContactMessage,
                      ),
              icon: const Icon(Icons.chat_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
