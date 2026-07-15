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

    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: GestureDetector(
        onLongPressStart: (_) => _paused = true,
        onLongPressEnd: (_) => _paused = false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8E8),
            border: Border(bottom: BorderSide(color: Color(0xFFE8D9B4))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF725516),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MarqueeText(
                  key: ValueKey(current.id),
                  text: _label(current),
                  paused: _paused,
                ),
              ),
              if (hasPublishedNews)
                IconButton(
                  tooltip: 'Fermer',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      setState(() => _dismissedIds.add(current.id)),
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
      ),
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

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({super.key, required this.text, required this.paused});

  final String text;
  final bool paused;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
    if (oldWidget.text != widget.text) {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF3B3322),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final offset = width * (1 - 2 * _controller.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.text, maxLines: 1, style: style),
                    SizedBox(width: width),
                    Text(widget.text, maxLines: 1, style: style),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
