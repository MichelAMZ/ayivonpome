import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';

class DivorceResult {
  const DivorceResult({required this.divorceDate, this.notes = ''});

  final String divorceDate;
  final String notes;
}

class DivorceDialog extends StatefulWidget {
  const DivorceDialog({super.key, required this.first, required this.second});

  final Person first;
  final Person second;

  @override
  State<DivorceDialog> createState() => _DivorceDialogState();
}

class _DivorceDialogState extends State<DivorceDialog> {
  final _date = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _date.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.declareDivorce),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmer le divorce entre ${widget.first.fullName} et ${widget.second.fullName} ?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _date,
              decoration: InputDecoration(
                labelText: l10n.divorceDate,
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.notes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            DivorceResult(divorceDate: _date.text, notes: _notes.text),
          ),
          child: Text(l10n.divorce),
        ),
      ],
    );
  }
}
