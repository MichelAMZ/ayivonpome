import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/info_news.dart';
import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';

class InfoNewsBar extends ConsumerStatefulWidget {
  const InfoNewsBar({super.key});

  @override
  ConsumerState<InfoNewsBar> createState() => _InfoNewsBarState();
}

class _InfoNewsBarState extends ConsumerState<InfoNewsBar> {
  final _dismissedIds = <String>{};
  var _index = 0;
  var _paused = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(familyTreeProvider).value;
    final news = data == null
        ? <InfoNews>[]
        : ref
              .watch(infoNewsServiceProvider)
              .activeNews(data)
              .where((item) => !_dismissedIds.contains(item.id))
              .toList();
    final hasPublishedNews = news.isNotEmpty;
    final defaultMessage = _defaultMessage(
      data?.appSettings.accessCodeContactName ?? '',
    );
    if (news.isEmpty && data != null) {
      news.add(
        InfoNews(
          id: '_default_info_news',
          title: '',
          message: defaultMessage,
          priority: 0,
          isActive: true,
        ),
      );
    }
    if (news.isEmpty) return const SizedBox.shrink();
    if (_index >= news.length) _index = 0;
    final current = news[_index];
    if (!_paused && hasPublishedNews && news.length > 1) {
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted || _paused) return;
        final latestData = ref.read(familyTreeProvider).value;
        final latestCount = latestData == null
            ? 0
            : ref
                  .read(infoNewsServiceProvider)
                  .activeNews(latestData)
                  .where((item) => !_dismissedIds.contains(item.id))
                  .length;
        if (latestCount > 1) {
          setState(() => _index = (_index + 1) % latestCount);
        }
      });
    }

    return ResponsiveInfoMessageBar(
      key: ValueKey(current.id),
      message: _label(current),
      showCloseButton: hasPublishedNews,
      onClose: hasPublishedNews
          ? () => setState(() => _dismissedIds.add(current.id))
          : null,
      onPauseChanged: (paused) => _paused = paused,
    );
  }

  String _label(InfoNews news) {
    final title = news.title.trim();
    final message = news.message.trim();
    if (title.isEmpty) return message;
    if (message.isEmpty) return title;
    return '$title - $message';
  }

  String _defaultMessage(String contactName) {
    final contact = contactName.trim().isEmpty
        ? 'Conseil de Famille'
        : contactName.trim();
    return 'Bienvenue ! Pour accéder aux fonctionnalités avancées '
        '(ajout, modification, administration), demandez votre code secret '
        'auprès du $contact.';
  }
}

class ResponsiveInfoMessageBar extends StatelessWidget {
  const ResponsiveInfoMessageBar({
    super.key,
    required this.message,
    this.showCloseButton = true,
    this.onClose,
    this.onPauseChanged,
  });

  final String message;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final ValueChanged<bool>? onPauseChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final horizontalPadding = compact ? 12.0 : 24.0;
        final maxLines = compact ? 2 : 1;
        return MouseRegion(
          onEnter: (_) => onPauseChanged?.call(true),
          onExit: (_) => onPauseChanged?.call(false),
          child: GestureDetector(
            onLongPressStart: (_) => onPauseChanged?.call(true),
            onLongPressEnd: (_) => onPauseChanged?.call(false),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E8),
                border: Border(bottom: BorderSide(color: Color(0xFFE8D9B4))),
              ),
              padding: EdgeInsetsDirectional.only(
                start: horizontalPadding,
                end: showCloseButton ? 2 : horizontalPadding,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Information familiale',
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF725516),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Tooltip(
                      message: message,
                      child: Text(
                        message,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF3B3322),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (showCloseButton) ...[
                    const SizedBox(width: 4),
                    Semantics(
                      button: true,
                      label: 'Fermer le message',
                      child: IconButton(
                        tooltip: 'Fermer le message',
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        onPressed: onClose,
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
