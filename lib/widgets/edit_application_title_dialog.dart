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
  late final TextEditingController _accessCodeContactName;
  late final TextEditingController _initialZoomPercent;
  late bool _showSubtitle;
  late bool _rememberLastZoom;
  late bool _showMembersCounter;
  late bool _showGenerationBadges;
  late bool _showTutorialOnFirstLaunch;
  late bool _showFloatingHelpButton;

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
    _accessCodeContactName = TextEditingController(
      text: widget.settings.accessCodeContactName,
    );
    _initialZoomPercent = TextEditingController(
      text: (widget.settings.treeSettings.initialZoom * 100).round().toString(),
    );
    _showSubtitle = widget.settings.showApplicationSubtitle;
    _rememberLastZoom = widget.settings.treeSettings.rememberLastZoom;
    _showMembersCounter = widget.settings.treeSettings.showMembersCounter;
    _showGenerationBadges = widget.settings.treeSettings.showGenerationBadges;
    _showTutorialOnFirstLaunch =
        widget.settings.tutorialSettings.showTutorialOnFirstLaunch;
    _showFloatingHelpButton =
        widget.settings.tutorialSettings.showFloatingHelpButton;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _officialFamilyName.dispose();
    _accessCodeContactName.dispose();
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
              controller: _accessCodeContactName,
              decoration: const InputDecoration(
                labelText: 'Libellé de l’autorité familiale',
                helperText: 'Exemple : Conseil de Famille',
              ),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showMembersCounter,
              title: Text(l10n.showMembersCounter),
              onChanged: (value) => setState(() => _showMembersCounter = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showGenerationBadges,
              title: Text(l10n.showGenerationBadges),
              onChanged: (value) =>
                  setState(() => _showGenerationBadges = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showFloatingHelpButton,
              title: Text(l10n.showTutorial),
              onChanged: (value) =>
                  setState(() => _showFloatingHelpButton = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showTutorialOnFirstLaunch,
              title: Text(l10n.firstLaunchTutorial),
              onChanged: (value) =>
                  setState(() => _showTutorialOnFirstLaunch = value),
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
              accessCodeContactName: _accessCodeContactName.text.trim(),
              treeSettings: widget.settings.treeSettings.copyWith(
                initialZoom:
                    (_parseZoomPercent(_initialZoomPercent.text) / 100),
                rememberLastZoom: _rememberLastZoom,
                showMembersCounter: _showMembersCounter,
                showGenerationBadges: _showGenerationBadges,
              ),
              languageSettings: widget.settings.languageSettings,
              tutorialSettings: widget.settings.tutorialSettings.copyWith(
                showFloatingHelpButton: _showFloatingHelpButton,
                showTutorialOnFirstLaunch: _showTutorialOnFirstLaunch,
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
    return parsed == null ? 60 : parsed.clamp(40, 120).toDouble();
  }
}
