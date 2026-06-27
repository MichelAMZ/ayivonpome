import 'dart:async';

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
  Timer? _timer;
  var _index = 0;
  var _paused = false;

  @override
  void dispose() {
    _timer?.cancel();
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
    _syncTimer(news);
    if (news.isEmpty) return const SizedBox.shrink();
    if (_index >= news.length) _index = 0;
    final current = news[_index];

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
                Icons.campaign_outlined,
                color: Color(0xFF725516),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: Text(
                    _label(current),
                    key: ValueKey(current.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3B3322),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _dismissedIds.add(current.id)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncTimer(List<InfoNews> news) {
    if (news.length <= 1) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _paused) return;
      setState(() => _index = (_index + 1) % news.length);
    });
  }

  String _label(InfoNews news) {
    final title = news.title.trim();
    final message = news.message.trim();
    if (title.isEmpty) return message;
    if (message.isEmpty) return title;
    return '$title - $message';
  }
}
