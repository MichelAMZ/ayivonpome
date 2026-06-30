import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../screens/tutorial_screen.dart';

class TutorialFloatingButton extends StatefulWidget {
  const TutorialFloatingButton({super.key, required this.settings});

  final TutorialSettings settings;

  @override
  State<TutorialFloatingButton> createState() => _TutorialFloatingButtonState();
}

class _TutorialFloatingButtonState extends State<TutorialFloatingButton> {
  static const _seenKey = 'family_tree_tutorial_seen';
  var _autoPromptChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowFirstLaunchTutorial();
  }

  @override
  void didUpdateWidget(covariant TutorialFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _maybeShowFirstLaunchTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.showFloatingHelpButton) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.helpAndTutorial,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showTutorialDialog(context),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5F7F2B), Color(0xFFD6AD42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.school_outlined, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _maybeShowFirstLaunchTutorial() async {
    if (_autoPromptChecked ||
        !widget.settings.showTutorialOnFirstLaunch ||
        widget.settings.tutorialAlreadySeen) {
      return;
    }
    _autoPromptChecked = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) == true) return;
    await prefs.setBool(_seenKey, true);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showTutorialDialog(context, interactive: true);
    });
  }

  static Future<void> showTutorialDialog(
    BuildContext context, {
    bool interactive = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: size.width < 640 ? 12 : 32,
          vertical: size.height < 720 ? 12 : 32,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: size.height * 0.86,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.helpAndTutorial,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: interactive
                    ? _InteractiveTutorial(l10n: l10n)
                    : const TutorialScreen(embedded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveTutorial extends StatefulWidget {
  const _InteractiveTutorial({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_InteractiveTutorial> createState() => _InteractiveTutorialState();
}

class _InteractiveTutorialState extends State<_InteractiveTutorial> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TutorialPageData(
        icon: Icons.waving_hand_outlined,
        title: widget.l10n.tutorialWelcomeTitle,
        body: widget.l10n.howToUse,
      ),
      _TutorialPageData(
        icon: Icons.lock_open_outlined,
        title: widget.l10n.tutorialAccessCodesTitle,
        body: widget.l10n.tutorialAccessCodesBody,
      ),
      _TutorialPageData(
        icon: Icons.zoom_in_outlined,
        title: widget.l10n.tutorialZoomTitle,
        body: widget.l10n.tutorialZoomBody,
      ),
      _TutorialPageData(
        icon: Icons.ads_click_outlined,
        title: widget.l10n.tutorialContextMenuTitle,
        body: widget.l10n.tutorialContextMenuBody,
      ),
      _TutorialPageData(
        icon: Icons.info_outline,
        title: widget.l10n.tutorialInfoTitle,
        body: widget.l10n.tutorialInfoBody,
      ),
    ];
    final step = steps[_index];
    final isFirst = _index == 0;
    final isLast = _index == steps.length - 1;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFFEAF2DD),
                      child: Icon(
                        step.icon,
                        size: 34,
                        color: const Color(0xFF5F7F2B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${_index + 1} / ${steps.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.l10n.skipTutorial),
              ),
              const Spacer(),
              TextButton(
                onPressed: isFirst ? null : () => setState(() => _index -= 1),
                child: Text(widget.l10n.previousStep),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLast
                    ? () => Navigator.pop(context)
                    : () => setState(() => _index += 1),
                child: Text(
                  isLast ? widget.l10n.finishTutorial : widget.l10n.nextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TutorialPageData {
  const _TutorialPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
