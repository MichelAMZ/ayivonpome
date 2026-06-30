import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/tutorial_step_card.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = _TutorialContent(l10n: l10n);
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpAndTutorial)),
      body: SafeArea(child: content),
    );
  }
}

class _TutorialContent extends StatelessWidget {
  const _TutorialContent({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tutorialWelcomeTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        TutorialStepCard(
          icon: '🖱️',
          title: l10n.tutorialMoveTitle,
          description: l10n.tutorialMoveBody,
        ),
        TutorialStepCard(
          icon: '➕',
          title: l10n.tutorialZoomTitle,
          description: l10n.tutorialZoomBody,
        ),
        TutorialStepCard(
          icon: 'ℹ️',
          title: l10n.tutorialInfoTitle,
          description: l10n.tutorialInfoBody,
        ),
        TutorialStepCard(
          icon: '🖱️',
          title: l10n.tutorialContextMenuTitle,
          description: l10n.tutorialContextMenuBody,
        ),
        TutorialStepCard(
          icon: '🔒',
          title: l10n.tutorialAccessCodesTitle,
          description: l10n.tutorialAccessCodesBody,
        ),
        TutorialStepCard(
          icon: '📍',
          title: l10n.tutorialMapTitle,
          description: l10n.tutorialMapBody,
        ),
        TutorialStepCard(
          icon: '🔔',
          title: l10n.tutorialNotificationsTitle,
          description: l10n.tutorialNotificationsBody,
        ),
        const SizedBox(height: 18),
        Text(
          l10n.treeLegend,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _LegendChip(icon: '♂', label: l10n.male),
            _LegendChip(icon: '♀', label: l10n.female),
            _LegendChip(icon: '💍', label: l10n.married),
            _LegendChip(icon: '💔', label: l10n.divorced),
            _LegendChip(icon: '👑', label: l10n.currentChief),
            _LegendChip(icon: '📍', label: l10n.knownPlace),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Text(icon),
      label: Text(label),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: theme.textTheme.labelLarge,
    );
  }
}
