import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import 'person_card.dart';

class FamilyTreeCanvas extends StatefulWidget {
  const FamilyTreeCanvas({
    super.key,
    required this.data,
    required this.onOpenPerson,
    required this.authMode,
    this.topReservedSpace = 0,
  });

  final FamilyTreeData data;
  final ValueChanged<Person> onOpenPerson;
  final AuthMode authMode;
  final double topReservedSpace;

  @override
  State<FamilyTreeCanvas> createState() => _FamilyTreeCanvasState();
}

class _FamilyTreeCanvasState extends State<FamilyTreeCanvas> {
  final _controller = TransformationController();
  var _scale = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = widget.data.people;
    if (people.isEmpty) {
      return const Center(child: Icon(Icons.account_tree_outlined, size: 64));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TreeMetrics.fromWidth(constraints.maxWidth);
        final layout = _TreeLayout.build(
          data: widget.data,
          metrics: metrics,
          topReservedSpace: widget.topReservedSpace,
        );
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final treeSize = Size(
          math.max(layout.size.width, viewport.width),
          math.max(layout.size.height, viewport.height),
        );
        final offset = Offset(
          math.max((treeSize.width - layout.size.width) / 2, 0),
          math.max((treeSize.height - layout.size.height) / 2, 0),
        );

        return Container(
          color: const Color(0xFFFBFCF7),
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _controller,
                minScale: 0.45,
                maxScale: 2.4,
                boundaryMargin: EdgeInsets.all(metrics.canvasPadding * 3),
                onInteractionUpdate: (_) {
                  final next = _controller.value.getMaxScaleOnAxis();
                  if ((next - _scale).abs() > 0.01) {
                    setState(() => _scale = next);
                  }
                },
                child: SizedBox(
                  width: treeSize.width,
                  height: treeSize.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TreeConnectorPainter(layout, offset),
                        ),
                      ),
                      for (final marker in layout.marriageMarkers)
                        Positioned(
                          left: offset.dx + marker.center.dx - 24,
                          top: offset.dy + marker.center.dy - 18,
                          child: _MarriageMarker(year: marker.year),
                        ),
                      for (final entry in layout.nodes.entries)
                        Positioned(
                          left: offset.dx + entry.value.left,
                          top: offset.dy + entry.value.top,
                          child: PersonCard(
                            person: entry.key,
                            data: widget.data,
                            authMode: widget.authMode,
                            width: metrics.cardWidth,
                            height: metrics.cardHeight,
                            compact: constraints.maxWidth < 700,
                            onOpen: () => widget.onOpenPerson(entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: metrics.canvasPadding,
                right: metrics.canvasPadding,
                top: metrics.canvasPadding,
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: TreeToolbar(
                      onSearch: _showSearchDialog,
                      onFullscreen: _openFullscreenCanvas,
                      onFilters: _showFiltersSheet,
                      onOptions: _showOptionsMenu,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: metrics.canvasPadding + 2,
                bottom: metrics.canvasPadding + 92,
                child: TreeZoomControls(
                  scale: _scale,
                  onZoomIn: () => _applyScale(1.15),
                  onZoomOut: () => _applyScale(0.87),
                  onReset: _resetView,
                ),
              ),
              Positioned(
                left: metrics.canvasPadding,
                right: metrics.canvasPadding,
                bottom: metrics.canvasPadding,
                child: const TreeLegend(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyScale(double factor) {
    final next = (_scale * factor).clamp(0.45, 2.4);
    setState(() => _scale = next.toDouble());
    _controller.value = Matrix4.identity()..scaleByDouble(_scale, _scale, 1, 1);
  }

  void _resetView() {
    setState(() => _scale = 1);
    _controller.value = Matrix4.identity();
  }

  Future<void> _openFullscreenCanvas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Arbre généalogique'),
            actions: [
              IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: FamilyTreeCanvas(
            data: widget.data,
            onOpenPerson: widget.onOpenPerson,
            authMode: widget.authMode,
          ),
        ),
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final selected = await showDialog<Person>(
      context: context,
      builder: (context) => _PersonSearchDialog(people: widget.data.people),
    );
    if (selected != null) {
      widget.onOpenPerson(selected);
    }
  }

  Future<void> _showFiltersSheet() async {
    final people = widget.data.people;
    final men = people.where((person) => _isMale(person.gender)).length;
    final women = people.where((person) => _isFemale(person.gender)).length;
    final places = people.where((person) => _hasKnownPlace(person)).length;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres de l’arbre',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: true,
              onChanged: null,
              title: Text('Afficher toutes les personnes (${people.length})'),
            ),
            CheckboxListTile(
              value: true,
              onChanged: null,
              title: Text('Hommes ($men)'),
              secondary: const Text('♂'),
            ),
            CheckboxListTile(
              value: true,
              onChanged: null,
              title: Text('Femmes ($women)'),
              secondary: const Text('♀'),
            ),
            CheckboxListTile(
              value: true,
              onChanged: null,
              title: Text('Lieux connus ($places)'),
              secondary: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOptionsMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location_outlined),
                title: const Text('Recentrer l’arbre'),
                onTap: () => Navigator.pop(context, 'center'),
              ),
              ListTile(
                leading: const Icon(Icons.zoom_out_map),
                title: const Text('Zoom 100%'),
                onTap: () => Navigator.pop(context, 'zoom100'),
              ),
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('Ouvrir en plein écran'),
                onTap: () => Navigator.pop(context, 'fullscreen'),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == 'center' || selected == 'zoom100') {
      _resetView();
      _showFeedback(
        selected == 'center' ? 'Arbre recentré' : 'Zoom réinitialisé à 100%',
      );
    }
    if (selected == 'fullscreen') {
      await _openFullscreenCanvas();
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  bool _isMale(String gender) {
    final value = gender.toLowerCase();
    return value == 'male' || value == 'm' || value == 'homme';
  }

  bool _isFemale(String gender) {
    final value = gender.toLowerCase();
    return value == 'female' || value == 'f' || value == 'femme';
  }

  bool _hasKnownPlace(Person person) {
    return person.publicMapLocation.isNotEmpty ||
        person.currentAddress.isNotEmpty ||
        person.birthPlace.isNotEmpty ||
        person.deathPlace.isNotEmpty ||
        person.burialPlace.isNotEmpty;
  }
}

class _TreeMetrics {
  const _TreeMetrics({
    required this.canvasPadding,
    required this.verticalGap,
    required this.cardGap,
    required this.spouseGap,
    required this.cardWidth,
    required this.cardHeight,
  });

  final double canvasPadding;
  final double verticalGap;
  final double cardGap;
  final double spouseGap;
  final double cardWidth;
  final double cardHeight;

  factory _TreeMetrics.fromWidth(double width) {
    if (width < 620) {
      return const _TreeMetrics(
        canvasPadding: 12,
        verticalGap: 44,
        cardGap: 12,
        spouseGap: 12,
        cardWidth: 260,
        cardHeight: 96,
      );
    }
    if (width < 1000) {
      return const _TreeMetrics(
        canvasPadding: 16,
        verticalGap: 56,
        cardGap: 18,
        spouseGap: 18,
        cardWidth: 280,
        cardHeight: 96,
      );
    }
    return const _TreeMetrics(
      canvasPadding: 24,
      verticalGap: 72,
      cardGap: 24,
      spouseGap: 24,
      cardWidth: 320,
      cardHeight: 96,
    );
  }
}

class _TreeLayout {
  const _TreeLayout({
    required this.nodes,
    required this.marriageMarkers,
    required this.size,
    required this.parentLinks,
  });

  final Map<Person, Rect> nodes;
  final List<_MarriageMarkerData> marriageMarkers;
  final List<_ParentLink> parentLinks;
  final Size size;

  static _TreeLayout build({
    required FamilyTreeData data,
    required _TreeMetrics metrics,
    required double topReservedSpace,
  }) {
    final peopleById = {for (final person in data.people) person.id: person};
    final levels = <int, List<Person>>{};
    for (final person in data.people) {
      final level = _generationOf(person, peopleById, <String>{});
      levels.putIfAbsent(level, () => []).add(person);
    }

    final nodes = <Person, Rect>{};
    final markers = <_MarriageMarkerData>[];
    final levelUnits = <int, List<_TreeUnit>>{};
    final levelWidths = <int, double>{};
    var maxWidth = 0.0;

    for (final level in levels.keys.toList()..sort()) {
      final units = _unitsForLevel(levels[level]!, data, peopleById);
      final totalWidth =
          units.fold<double>(
            0,
            (sum, unit) => sum + unit.width(metrics) + metrics.cardGap,
          ) -
          metrics.cardGap;
      levelUnits[level] = units;
      levelWidths[level] = totalWidth;
      maxWidth = math.max(maxWidth, totalWidth);
    }

    for (final level in levels.keys.toList()..sort()) {
      final units = levelUnits[level]!;
      final totalWidth = levelWidths[level]!;
      var x = metrics.canvasPadding + (maxWidth - totalWidth) / 2;
      final y =
          metrics.canvasPadding +
          topReservedSpace +
          level * (metrics.cardHeight + metrics.verticalGap);
      for (final unit in units) {
        var personX = x;
        for (final person in unit.people) {
          nodes[person] = Rect.fromLTWH(
            personX,
            y,
            metrics.cardWidth,
            metrics.cardHeight,
          );
          personX += metrics.cardWidth + metrics.spouseGap;
        }

        for (var i = 0; i < unit.people.length - 1; i++) {
          final first = nodes[unit.people[i]]!;
          final second = nodes[unit.people[i + 1]]!;
          final relation = _marriageBetween(
            data,
            unit.people[i].id,
            unit.people[i + 1].id,
          );
          markers.add(
            _MarriageMarkerData(
              center: Offset((first.right + second.left) / 2, first.center.dy),
              year: _yearOf(relation?.marriageDate ?? ''),
            ),
          );
        }
        x += unit.width(metrics) + metrics.cardGap;
      }
    }

    final links = <_ParentLink>[];
    for (final person in data.people) {
      final childRect = nodes[person];
      if (childRect == null) continue;
      final parentRects = _parentIds(person)
          .map(peopleById.get)
          .whereType<Person>()
          .map(nodes.get)
          .whereType<Rect>()
          .toList();
      if (parentRects.isEmpty) continue;
      links.add(_ParentLink(parentRects: parentRects, childRect: childRect));
    }

    final height =
        metrics.canvasPadding * 2 +
        topReservedSpace +
        (levels.keys.reduce(math.max) + 1) * metrics.cardHeight +
        levels.keys.reduce(math.max) * metrics.verticalGap;

    return _TreeLayout(
      nodes: nodes,
      marriageMarkers: markers,
      parentLinks: links,
      size: Size(maxWidth + metrics.canvasPadding * 2, height),
    );
  }

  static int _generationOf(
    Person person,
    Map<String, Person> peopleById,
    Set<String> seen,
  ) {
    if (!seen.add(person.id)) return 0;
    final parents = _parentIds(person).map(peopleById.get).whereType<Person>();
    if (parents.isEmpty) return 0;
    return 1 +
        parents
            .map((parent) => _generationOf(parent, peopleById, {...seen}))
            .fold<int>(0, math.max);
  }

  static List<_TreeUnit> _unitsForLevel(
    List<Person> people,
    FamilyTreeData data,
    Map<String, Person> peopleById,
  ) {
    final seen = <String>{};
    final units = <_TreeUnit>[];
    final sorted = [...people]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    for (final person in sorted) {
      if (seen.contains(person.id)) continue;
      final spouses =
          _spouseIds(person, data)
              .map(peopleById.get)
              .whereType<Person>()
              .where(
                (spouse) =>
                    people.contains(spouse) && !seen.contains(spouse.id),
              )
              .toList()
            ..sort((a, b) {
              final aOrder =
                  _marriageBetween(data, person.id, a.id)?.order ?? 999;
              final bOrder =
                  _marriageBetween(data, person.id, b.id)?.order ?? 999;
              return aOrder.compareTo(bOrder);
            });
      final unitPeople = [person, ...spouses];
      for (final member in unitPeople) {
        seen.add(member.id);
      }
      units.add(_TreeUnit(unitPeople));
    }
    return units;
  }

  static List<String> _parentIds(Person person) {
    final ids = <String>[
      if (person.fatherId.isNotEmpty) person.fatherId,
      if (person.motherId.isNotEmpty) person.motherId,
      ...person.parents,
    ];
    return ids.toSet().toList();
  }

  static List<String> _spouseIds(Person person, FamilyTreeData data) {
    final ids = <String>[...person.spouseIds, ...person.spouses];
    for (final relation in data.marriageRelations) {
      if (relation.personId == person.id) ids.add(relation.spouseId);
      if (relation.spouseId == person.id) ids.add(relation.personId);
    }
    return ids.toSet().toList();
  }

  static MarriageRelation? _marriageBetween(
    FamilyTreeData data,
    String firstId,
    String secondId,
  ) {
    for (final relation in data.marriageRelations) {
      final matches =
          relation.personId == firstId && relation.spouseId == secondId;
      final reverse =
          relation.personId == secondId && relation.spouseId == firstId;
      if (matches || reverse) return relation;
    }
    return null;
  }

  static String _yearOf(String date) =>
      date.length >= 4 ? date.substring(0, 4) : '';
}

class _TreeUnit {
  const _TreeUnit(this.people);

  final List<Person> people;

  double width(_TreeMetrics metrics) {
    return people.length * metrics.cardWidth +
        math.max(people.length - 1, 0) * metrics.spouseGap;
  }
}

class _ParentLink {
  const _ParentLink({required this.parentRects, required this.childRect});

  final List<Rect> parentRects;
  final Rect childRect;
}

class _MarriageMarkerData {
  const _MarriageMarkerData({required this.center, required this.year});

  final Offset center;
  final String year;
}

class _TreeConnectorPainter extends CustomPainter {
  _TreeConnectorPainter(this.layout, this.offset);

  final _TreeLayout layout;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final connector = Paint()
      ..color = const Color(0xFF92A78D)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final marriage = Paint()
      ..color = const Color(0xFFB9C4B4)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    for (final marker in layout.marriageMarkers) {
      canvas.drawLine(
        offset + Offset(marker.center.dx - 30, marker.center.dy),
        offset + Offset(marker.center.dx + 30, marker.center.dy),
        marriage,
      );
    }

    for (final link in layout.parentLinks) {
      final parentCenters = link.parentRects
          .map((rect) => offset + rect.bottomCenter)
          .toList();
      final parentAnchor = parentCenters.length == 1
          ? parentCenters.first
          : Offset(
              (parentCenters.map((point) => point.dx).reduce(math.min) +
                      parentCenters.map((point) => point.dx).reduce(math.max)) /
                  2,
              parentCenters.first.dy,
            );
      final childTop = offset + link.childRect.topCenter;
      final elbowY =
          parentAnchor.dy +
          math.max((childTop.dy - parentAnchor.dy) * 0.48, 18);

      final path = Path()
        ..moveTo(parentAnchor.dx, parentAnchor.dy)
        ..lineTo(parentAnchor.dx, elbowY)
        ..lineTo(childTop.dx, elbowY)
        ..lineTo(childTop.dx, childTop.dy);
      canvas.drawPath(path, connector);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.offset != offset;
  }
}

class TreeToolbar extends StatelessWidget {
  const TreeToolbar({
    super.key,
    required this.onSearch,
    required this.onFullscreen,
    required this.onFilters,
    required this.onOptions,
  });

  final VoidCallback onSearch;
  final VoidCallback onFullscreen;
  final VoidCallback onFilters;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.search,
            tooltip: 'Recherche',
            onPressed: onSearch,
          ),
          _Divider(),
          _ToolbarButton(
            icon: Icons.open_in_full,
            tooltip: 'Plein écran',
            onPressed: onFullscreen,
          ),
          _Divider(),
          _ToolbarButton(
            icon: Icons.tune,
            tooltip: 'Filtres',
            onPressed: onFilters,
          ),
          _ToolbarButton(
            icon: Icons.more_vert,
            tooltip: 'Options',
            onPressed: onOptions,
          ),
        ],
      ),
    );
  }
}

class _PersonSearchDialog extends StatefulWidget {
  const _PersonSearchDialog({required this.people});

  final List<Person> people;

  @override
  State<_PersonSearchDialog> createState() => _PersonSearchDialogState();
}

class _PersonSearchDialogState extends State<_PersonSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = widget.people
        .where(
          (person) =>
              query.isEmpty || person.fullName.toLowerCase().contains(query),
        )
        .take(12)
        .toList();
    return AlertDialog(
      title: const Text('Rechercher une personne'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Nom ou prénom',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: results.isEmpty
                    ? const Center(child: Text('Aucun résultat'))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final person = results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(_initials(person)),
                            ),
                            title: Text(person.fullName),
                            subtitle: person.familyCode.isEmpty
                                ? null
                                : Text(person.familyCode),
                            onTap: () => Navigator.pop(context, person),
                          );
                        },
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemCount: results.length,
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class TreeZoomControls extends StatelessWidget {
  const TreeZoomControls({
    super.key,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7DC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(
                icon: Icons.add,
                tooltip: 'Zoom +',
                onPressed: onZoomIn,
              ),
              SizedBox(
                width: 54,
                height: 36,
                child: Center(
                  child: Text(
                    '${(scale * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF3F433A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _ToolbarButton(
                icon: Icons.remove,
                tooltip: 'Zoom -',
                onPressed: onZoomOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E7DC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: _ToolbarButton(
            icon: Icons.my_location_outlined,
            tooltip: 'Recentrer',
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 28, child: VerticalDivider(width: 1));
  }
}

class TreeLegend extends StatelessWidget {
  const TreeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E7DC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _LegendItem(icon: '♂', label: 'Homme', color: Color(0xFF2D7DD2)),
              _LegendItem(icon: '♀', label: 'Femme', color: Color(0xFFE53964)),
              _LegendItem(
                icon: '💍',
                label: 'Marié(e)',
                color: Color(0xFFE6A400),
              ),
              _LegendItem(
                icon: '📍',
                label: 'Lieu connu',
                color: Color(0xFF4C7A2E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _MarriageMarker extends StatelessWidget {
  const _MarriageMarker({required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '∞',
            style: TextStyle(
              color: Color(0xFFE6A400),
              fontSize: 28,
              height: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (year.isNotEmpty)
            Text(
              year,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF4F4F45),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

extension _MapGet<K, V> on Map<K, V> {
  V? get(K key) => this[key];
}
