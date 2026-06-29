import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';

class EditApplicationTitleDialog extends StatefulWidget {
  const EditApplicationTitleDialog({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<EditApplicationTitleDialog> createState() =>
      _EditApplicationTitleDialogState();
}

class _EditApplicationTitleDialogState
    extends State<EditApplicationTitleDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _officialFamilyName;
  late final TextEditingController _initialZoomPercent;
  late bool _showSubtitle;
  late bool _rememberLastZoom;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.settings.applicationTitle);
    _subtitle = TextEditingController(
      text: widget.settings.applicationSubtitle,
    );
    _officialFamilyName = TextEditingController(
      text: widget.settings.officialFamilyName,
    );
    _initialZoomPercent = TextEditingController(
      text: (widget.settings.treeSettings.initialZoom * 100).round().toString(),
    );
    _showSubtitle = widget.settings.showApplicationSubtitle;
    _rememberLastZoom = widget.settings.treeSettings.rememberLastZoom;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _officialFamilyName.dispose();
    _initialZoomPercent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editApplicationTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.applicationTitle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitle,
              decoration: InputDecoration(labelText: l10n.applicationSubtitle),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showSubtitle,
              title: Text(l10n.showApplicationSubtitle),
              onChanged: (value) => setState(() => _showSubtitle = value),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _officialFamilyName,
              decoration: InputDecoration(labelText: l10n.officialFamilyName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _initialZoomPercent,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.treeInitialZoom,
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _rememberLastZoom,
              title: Text(l10n.rememberLastZoom),
              onChanged: (value) => setState(() => _rememberLastZoom = value),
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
            AppSettings(
              applicationTitle: _title.text.trim(),
              applicationSubtitle: _subtitle.text.trim(),
              showApplicationSubtitle: _showSubtitle,
              officialFamilyName: _officialFamilyName.text.trim(),
              treeSettings: widget.settings.treeSettings.copyWith(
                initialZoom:
                    (_parseZoomPercent(_initialZoomPercent.text) / 100),
                rememberLastZoom: _rememberLastZoom,
              ),
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  double _parseZoomPercent(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed == null ? 60 : parsed.clamp(20, 300).toDouble();
  }
}
