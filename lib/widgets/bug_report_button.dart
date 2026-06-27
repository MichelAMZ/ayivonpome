import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/bug_report.dart';
import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import 'bug_report_form_dialog.dart';

class BugReportButton extends ConsumerWidget {
  const BugReportButton({
    super.key,
    this.initialScreen = '',
    this.compact = false,
  });

  final String initialScreen;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (compact) {
      return IconButton(
        tooltip: l10n.reportBug,
        onPressed: () => _open(context, ref),
        icon: const Icon(Icons.bug_report_outlined),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.bug_report_outlined),
      label: Text(l10n.reportBug),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final bug = await showDialog<BugReport>(
      context: context,
      builder: (context) => BugReportFormDialog(initialScreen: initialScreen),
    );
    if (bug == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).bugReportCreated)),
    );
    await _offerWhatsappNotifications(context, ref, bug);
  }

  Future<void> _offerWhatsappNotifications(
    BuildContext context,
    WidgetRef ref,
    BugReport bug,
  ) async {
    final l10n = AppLocalizations.of(context);
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final service = ref.read(bugReportServiceProvider);
    final admins = service.whatsappAdmins(data);
    if (admins.isEmpty) return;
    final selected = <String>{for (final admin in admins) admin.id};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.notifyAdminsWhatsapp),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminWhatsappNotification),
                const SizedBox(height: 10),
                for (final admin in admins)
                  CheckboxListTile(
                    value: selected.contains(admin.id),
                    title: Text(admin.fullName),
                    subtitle: Text(admin.whatsappNumber),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(admin.id);
                      } else {
                        selected.remove(admin.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l10n.notifyAdminsWhatsapp),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final message = service.whatsappMessage(bug);
    final notified = <String>[];
    for (final admin in admins.where((admin) => selected.contains(admin.id))) {
      await ref
          .read(communicationServiceProvider)
          .openWhatsApp(phoneNumber: admin.whatsappNumber, message: message);
      notified.add(admin.id);
    }
    await ref
        .read(familyTreeProvider.notifier)
        .markBugReportAdminsNotified(bug, notified);
  }
}
