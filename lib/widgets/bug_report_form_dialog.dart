import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/bug_report.dart';
import '../providers/family_tree_provider.dart';

class BugReportFormDialog extends ConsumerStatefulWidget {
  const BugReportFormDialog({super.key, this.initialScreen = ''});

  final String initialScreen;

  @override
  ConsumerState<BugReportFormDialog> createState() =>
      _BugReportFormDialogState();
}

class _BugReportFormDialogState extends ConsumerState<BugReportFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _screen;
  late final TextEditingController _reportedByName;
  late final TextEditingController _reportedByContact;
  late final TextEditingController _screenshotPath;
  var _priority = 'medium';
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _screen = TextEditingController(text: widget.initialScreen);
    _reportedByName = TextEditingController();
    _reportedByContact = TextEditingController();
    _screenshotPath = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _screen.dispose();
    _reportedByName.dispose();
    _reportedByContact.dispose();
    _screenshotPath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportBug),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l10n.bugTitle),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.bugTitle
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: l10n.bugDescription),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.bugDescription
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _screen,
                  decoration: InputDecoration(labelText: l10n.bugScreen),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: InputDecoration(labelText: l10n.bugPriority),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Faible')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (value) =>
                      setState(() => _priority = value ?? _priority),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _reportedByName,
                  decoration: InputDecoration(labelText: l10n.reportedBy),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _reportedByContact,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _screenshotPath,
                  decoration: const InputDecoration(
                    labelText: 'Capture d’écran optionnelle',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.bug_report_outlined),
          label: Text(l10n.reportBug),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final bug = BugReport(
      id: '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      screen: _screen.text.trim(),
      priority: _priority,
      reportedByName: _reportedByName.text.trim(),
      reportedByContact: _reportedByContact.text.trim(),
      screenshotPath: _screenshotPath.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    final created = await ref
        .read(familyTreeProvider.notifier)
        .createBugReport(bug);
    if (!mounted) return;
    Navigator.pop(context, created);
  }
}
