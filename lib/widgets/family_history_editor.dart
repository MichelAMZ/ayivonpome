import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_history.dart';
import 'character_counter.dart';

class FamilyHistoryEditor extends StatefulWidget {
  const FamilyHistoryEditor({
    super.key,
    required this.history,
    required this.onSave,
  });

  final FamilyHistory history;
  final ValueChanged<FamilyHistory> onSave;

  @override
  State<FamilyHistoryEditor> createState() => _FamilyHistoryEditorState();
}

class _FamilyHistoryEditorState extends State<FamilyHistoryEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _bannerImage;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.history.title);
    _content = TextEditingController(text: widget.history.content)
      ..addListener(() => setState(() {}));
    _bannerImage = TextEditingController(text: widget.history.bannerImage);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _bannerImage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exceeded = _content.text.length > widget.history.maxCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: l10n.historyTitle),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bannerImage,
          decoration: const InputDecoration(labelText: 'Bannière / photo'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _content,
          minLines: 8,
          maxLines: 16,
          decoration: InputDecoration(
            labelText: l10n.historyContent,
            alignLabelWithHint: true,
            errorText: exceeded ? l10n.characterLimitExceeded : null,
          ),
        ),
        const SizedBox(height: 8),
        CharacterCounter(
          count: _content.text.length,
          max: widget.history.maxCharacters,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            onPressed: exceeded
                ? null
                : () => widget.onSave(
                    widget.history.copyWith(
                      title: _title.text.trim(),
                      content: _content.text,
                      bannerImage: _bannerImage.text.trim(),
                    ),
                  ),
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
