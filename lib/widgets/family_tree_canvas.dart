import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/web/context_menu_preventer.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_leader_provider.dart';
import '../providers/linked_family_tree_provider.dart';
import '../providers/tree_filter_provider.dart';
import '../screens/person_edit_screen.dart';
import 'members_counter_badge.dart';
import '../services/location_filter_service.dart';
import '../services/genealogy_layout_service.dart';
import 'location_filter_panel.dart';
import 'person_card.dart';
import 'sync_status_badge.dart';
import 'tutorial_floating_button.dart';

class FamilyTreeCanvas extends ConsumerStatefulWidget {
  const FamilyTreeCanvas({
    super.key,
    required this.data,
    required this.onOpenPerson,
    required this.authMode,
    this.topReservedSpace = 0,
    this.membersCount,
    this.resetToken = 0,
    this.showMembersCounter = true,
    this.highlightedPersonIds = const {},
  });

  final FamilyTreeData data;
  final ValueChanged<Person> onOpenPerson;
  final AuthMode authMode;
  final double topReservedSpace;
  final int? membersCount;
  final int resetToken;
  final bool showMembersCounter;
  final Set<String> highlightedPersonIds;

  @override
  ConsumerState<FamilyTreeCanvas> createState() => _FamilyTreeCanvasState();
}

class _FamilyTreeCanvasState extends ConsumerState<FamilyTreeCanvas> {
  static const _virtualCanvasMargin = 600.0;
  static const _panBoundaryMargin = 2000.0;

  final _canvasKey = GlobalKey();
  final _controller = TransformationController();
  ContextMenuPreventerDisposer? _contextMenuPreventerDisposer;
  var _scale = 1.0;
  var _needsInitialView = true;
  var _isInteracting = false;
  var _hasPendingViewportCenter = false;
  Size? _lastViewport;
  Size? _lastCenteredViewport;
  Size? _lastLayoutSize;
  Rect? _lastContentRect;
  Offset? _lastCanvasOffset;
  Map<String, Rect> _lastPersonRects = const {};

  @override
  void initState() {
    super.initState();
    _contextMenuPreventerDisposer = installContextMenuPreventer(
      _isPointerInsideCanvas,
    );
  }

  @override
  void dispose() {
    _contextMenuPreventerDisposer?.call();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FamilyTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken &&
        widget.data.appSettings.treeSettings.resetViewOnStartup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resetView();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourcePeople = widget.data.people;
    if (sourcePeople.isEmpty) {
      return const Center(child: Icon(Icons.account_tree_outlined, size: 64));
    }
    final filter = ref.watch(treeFilterProvider);
    const filterService = LocationFilterService();
    final filteredPeople = filterService.filterPeopleByLocation(
      sourcePeople,
      filter,
    );
    final highlightedIds = filter.isActive && filter.highlightResults
        ? filteredPeople.map((person) => person.id).toSet()
        : <String>{};
    final displayData = filter.isActive && filter.showOnlyResults
        ? widget.data.copyWith(people: filteredPeople)
        : widget.data;
    final linkedTreeService = ref.watch(
      linkedFamilyTreeServiceProvider(widget.data),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TreeMetrics.fromWidth(constraints.maxWidth);
        final treeSettings = widget.data.appSettings.treeSettings;
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final compactSurface = constraints.maxWidth < 720;
        final familyHead = ref.watch(familyLeaderProvider);
        final overlayReservedSpace = compactSurface ? 118.0 : 128.0;
        final hasDisplayPeople = displayData.people.isNotEmpty;
        final layout = hasDisplayPeople
            ? _TreeLayout.build(
                data: displayData,
                metrics: metrics,
                topReservedSpace:
                    widget.topReservedSpace + overlayReservedSpace,
              )
            : _TreeLayout.empty();
        final treeSize = Size(
          math.max(
            viewport.width,
            layout.size.width + _virtualCanvasMargin * 2,
          ),
          math.max(
            viewport.height,
            layout.size.height + _virtualCanvasMargin * 2,
          ),
        );
        _lastViewport = viewport;
        final offset = Offset(
          math.max((treeSize.width - layout.size.width) / 2, 0),
          math.max((treeSize.height - layout.size.height) / 2, 0),
        );
        final contentRect = offset & layout.size;
        _lastLayoutSize = layout.size;
        _lastContentRect = contentRect;
        _scheduleInitialView(viewport, contentRect);
        _scheduleViewportCenter(viewport, contentRect);
        _lastCanvasOffset = offset;
        _lastPersonRects = {
          for (final entry in layout.nodes.entries) entry.key.id: entry.value,
        };

        return Container(
          key: _canvasKey,
          color: const Color(0xFFFBFCF7),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _TreeGridPainter()),
              ),
              Listener(
                onPointerDown: (_) => _isInteracting = true,
                onPointerUp: (_) => _endInteraction(),
                onPointerCancel: (_) => _endInteraction(),
                onPointerSignal: _handlePointerSignal,
                child: InteractiveViewer(
                  constrained: false,
                  transformationController: _controller,
                  minScale: treeSettings.minZoom,
                  maxScale: treeSettings.maxZoom,
                  panAxis: PanAxis.free,
                  clipBehavior: Clip.hardEdge,
                  boundaryMargin: const EdgeInsets.all(_panBoundaryMargin),
                  onInteractionUpdate: (_) {
                    final next = _controller.value.getMaxScaleOnAxis();
                    if ((next - _scale).abs() > 0.01) {
                      setState(() => _scale = next);
                    }
                  },
                  onInteractionEnd: (_) {
                    _endInteraction();
                    _saveLastZoom();
                  },
                  child: SizedBox(
                    width: treeSize.width,
                    height: treeSize.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _TreeConnectorPainter(layout, offset),
                            ),
                          ),
                        ),
                        for (final marker in layout.marriageMarkers)
                          Positioned(
                            left: offset.dx + marker.center.dx - 24,
                            top: offset.dy + marker.center.dy - 18,
                            child: _MarriageMarker(
                              marriageYear: marker.marriageYear,
                              divorceYear: marker.divorceYear,
                              status: marker.status,
                              marriageType: marker.marriageType,
                              marriagePlace: marker.marriagePlace,
                            ),
                          ),
                        for (final entry in layout.nodes.entries)
                          Positioned(
                            left: offset.dx + entry.value.left,
                            top: offset.dy + entry.value.top,
                            child: RepaintBoundary(
                              child: PersonCard(
                                person: entry.key,
                                data: widget.data,
                                authMode: widget.authMode,
                                width: metrics.cardWidth,
                                height: metrics.cardHeight,
                                compact: constraints.maxWidth < 700,
                                highlighted:
                                    highlightedIds.contains(entry.key.id) ||
                                    widget.highlightedPersonIds.contains(
                                      entry.key.id,
                                    ),
                                hasLinkedFamilyTree: linkedTreeService
                                    .hasLinkedFamilyTree(entry.key),
                                onOpen: () => widget.onOpenPerson(entry.key),
                              ),
                            ),
                          ),
                        if (!hasDisplayPeople)
                          Center(
                            child: Text(
                              AppLocalizations.of(context).noResults,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compactSurface ? 12 : metrics.canvasPadding,
                right: compactSurface ? 12 : metrics.canvasPadding,
                top: compactSurface ? 10 : 12,
                child: _TreeWorkspaceHeader(
                  compact: compactSurface,
                  familyHead: familyHead,
                  onOpenFamilyHead: familyHead == null
                      ? null
                      : () => widget.onOpenPerson(familyHead),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TreeToolbar(
                      compact: compactSurface,
                      canAddMember: ref.watch(authSessionProvider).canModify,
                      onSearch: _showSearchDialog,
                      onCenter: _resetView,
                      onFit: _fitTreeView,
                      onFilters: _showFiltersSheet,
                      onOptions: _showOptionsMenu,
                      onAddMember: _openNewMemberForm,
                      filterActive: filter.isActive,
                      filterCount: filteredPeople.length,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: metrics.canvasPadding + 2,
                bottom: constraints.maxWidth < 620
                    ? 118
                    : math.max(metrics.canvasPadding, 24),
                child: TreeFloatingActionsColumn(
                  compact: constraints.maxWidth < 620,
                  scale: _scale,
                  onZoomIn: () => _applyScale(1.15),
                  onZoomOut: () => _applyScale(0.87),
                  onReset: _resetView,
                  onFit: _fitTreeView,
                  tutorialButton:
                      widget
                          .data
                          .appSettings
                          .tutorialSettings
                          .showFloatingHelpButton
                      ? TutorialFloatingButton(
                          settings: widget.data.appSettings.tutorialSettings,
                        )
                      : null,
                ),
              ),
              Positioned(
                left: metrics.canvasPadding,
                right: metrics.canvasPadding,
                bottom: metrics.canvasPadding,
                child: TreeLegend(
                  membersCount: widget.membersCount,
                  showMembersCounter: widget.showMembersCounter,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyScale(double factor) {
    final settings = widget.data.appSettings.treeSettings;
    final next = (_scale * factor).clamp(settings.minZoom, settings.maxZoom);
    setState(() => _scale = next.toDouble());
    _controller.value = _centeredMatrix(_scale);
    _lastCenteredViewport = _lastViewport;
    _saveLastZoom();
  }

  void _openNewMemberForm() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonEditScreen()));
  }

  void _resetView() {
    final zoom = _initialZoomForViewport(widget.data.appSettings.treeSettings);
    setState(() => _scale = zoom);
    _controller.value = _centeredMatrix(zoom);
    _lastCenteredViewport = _lastViewport;
    _saveLastZoom();
  }

  void _fitTreeView() {
    final viewport = _lastViewport;
    final layoutSize = _lastLayoutSize;
    if (viewport == null || layoutSize == null) {
      _resetView();
      return;
    }
    final settings = widget.data.appSettings.treeSettings;
    final compact = viewport.width < 620;
    final fitPadding = compact ? 72.0 : 96.0;
    final reservedBottom = compact ? 150.0 : 96.0;
    final widthScale =
        (viewport.width - fitPadding).clamp(120, double.infinity) /
        layoutSize.width;
    final heightScale =
        (viewport.height - reservedBottom).clamp(120, double.infinity) /
        layoutSize.height;
    final zoom = math
        .min(widthScale, heightScale)
        .clamp(settings.minZoom, settings.maxZoom)
        .toDouble();
    setState(() => _scale = zoom);
    _controller.value = _centeredMatrix(zoom);
    _lastCenteredViewport = _lastViewport;
    _saveLastZoom();
    _showFeedback('Tout l’arbre est visible');
  }

  void _scheduleInitialView(Size viewport, Rect contentRect) {
    if (!_needsInitialView) return;
    _needsInitialView = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final settings = widget.data.appSettings.treeSettings;
      final zoom = _initialZoomForViewport(settings, viewport);
      setState(() => _scale = zoom);
      _controller.value = _centeredMatrix(zoom, viewport, contentRect);
      _lastCenteredViewport = viewport;
    });
  }

  void _scheduleViewportCenter(Size viewport, Rect contentRect) {
    final previous = _lastCenteredViewport;
    if (previous == null) return;
    if (!_hasViewportMeaningfullyChanged(previous, viewport)) return;
    if (_hasPendingViewportCenter) return;

    _hasPendingViewportCenter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hasPendingViewportCenter = false;
      if (_isInteracting) return;
      _centerForViewportChange(viewport, contentRect);
    });
  }

  bool _hasViewportMeaningfullyChanged(Size previous, Size next) {
    return (previous.width - next.width).abs() > 2 ||
        (previous.height - next.height).abs() > 2;
  }

  void _centerForViewportChange(Size viewport, Rect contentRect) {
    _controller.value = _centeredMatrix(_scale, viewport, contentRect);
    _lastCenteredViewport = viewport;
  }

  void _endInteraction() {
    if (!_isInteracting && !_hasPendingViewportCenter) return;
    _isInteracting = false;
    final viewport = _lastViewport;
    final contentRect = _lastContentRect;
    if (viewport == null || contentRect == null) return;
    if (_lastCenteredViewport == null ||
        _hasViewportMeaningfullyChanged(_lastCenteredViewport!, viewport)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isInteracting) return;
        final latestViewport = _lastViewport;
        final latestContentRect = _lastContentRect;
        if (latestViewport == null || latestContentRect == null) return;
        _centerForViewportChange(latestViewport, latestContentRect);
      });
    }
  }

  Matrix4 _centeredMatrix([double? zoom, Size? viewport, Rect? contentRect]) {
    final scale = zoom ?? _scale;
    final effectiveViewport = viewport ?? _lastViewport;
    final effectiveContent = contentRect ?? _lastContentRect;
    if (effectiveViewport == null || effectiveContent == null) {
      return Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
    }
    final compact = effectiveViewport.width < 620;
    final targetCenter = Offset(
      effectiveViewport.width / 2,
      effectiveViewport.height * (compact ? 0.43 : 0.5),
    );
    final dx = targetCenter.dx - effectiveContent.center.dx * scale;
    final dy = targetCenter.dy - effectiveContent.center.dy * scale;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  double _initialZoomForViewport(TreeViewSettings settings, [Size? viewport]) {
    final width = viewport?.width ?? _lastViewport?.width;
    final base = ref
        .read(treeViewSettingsServiceProvider)
        .getInitialZoom(settings);
    final responsiveZoom = width != null && width >= 600 && width <= 1024
        ? math.max(base, 0.65)
        : base;
    return responsiveZoom.clamp(settings.minZoom, settings.maxZoom).toDouble();
  }

  bool _isPointerInsideCanvas(double clientX, double clientY) {
    final currentContext = _canvasKey.currentContext;
    if (currentContext == null) return false;
    final renderObject = currentContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = topLeft & renderObject.size;
    return rect.contains(Offset(clientX, clientY));
  }

  void _saveLastZoom() {
    if (!widget.data.appSettings.treeSettings.rememberLastZoom) return;
    ref.read(treeViewSettingsServiceProvider).saveLastZoom(_scale);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftPressed =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
    final delta = shiftPressed
        ? Offset(-event.scrollDelta.dy, 0)
        : Offset(-event.scrollDelta.dx, -event.scrollDelta.dy);
    if (delta == Offset.zero) return;
    _controller.value = _controller.value.clone()
      ..translateByDouble(delta.dx, delta.dy, 0, 1);
  }

  Future<void> _openFullscreenCanvas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).totalMembersTitle),
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
            membersCount: widget.membersCount,
            showMembersCounter: widget.showMembersCounter,
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
    final filter = ref.read(treeFilterProvider);
    const filterService = LocationFilterService();
    final results = filterService.filterPeopleByLocation(people, filter);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => LocationFilterPanel(
        people: people,
        results: results,
        onCenterOnPerson: centerTreeOnPerson,
      ),
    );
  }

  void centerTreeOnPerson(Person person) {
    final viewport = _lastViewport;
    final offset = _lastCanvasOffset;
    final rect = _lastPersonRects[person.id];
    if (viewport == null || offset == null || rect == null) return;
    final scale = _scale;
    final viewportCenter = Offset(viewport.width / 2, viewport.height / 2);
    final personCenter = offset + rect.center;
    final translation = viewportCenter - personCenter * scale;
    setState(() {
      _controller.value = Matrix4.identity()
        ..translateByDouble(translation.dx, translation.dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    });
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
                title: const Text('Voir tout l’arbre'),
                onTap: () => Navigator.pop(context, 'fit'),
              ),
              ListTile(
                leading: const Icon(Icons.center_focus_strong_outlined),
                title: const Text('Revenir au zoom initial'),
                onTap: () => Navigator.pop(context, 'initialZoom'),
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
    if (selected == 'center' || selected == 'initialZoom') {
      _resetView();
      _showFeedback(
        selected == 'center' ? 'Arbre recentré' : 'Zoom initial restauré',
      );
    }
    if (selected == 'fit') {
      _fitTreeView();
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
        verticalGap: 54,
        cardGap: 12,
        spouseGap: 12,
        cardWidth: 310,
        cardHeight: 122,
      );
    }
    if (width < 1000) {
      return const _TreeMetrics(
        canvasPadding: 16,
        verticalGap: 68,
        cardGap: 18,
        spouseGap: 18,
        cardWidth: 360,
        cardHeight: 126,
      );
    }
    return const _TreeMetrics(
      canvasPadding: 24,
      verticalGap: 82,
      cardGap: 32,
      spouseGap: 44,
      cardWidth: 430,
      cardHeight: 132,
    );
  }
}

class _TreeLayout {
  static const _branchConnectorColors = [
    Color(0xFF6BA368),
    Color(0xFF5B8DEF),
    Color(0xFF9B7EDE),
    Color(0xFFE0A64B),
    Color(0xFF8AA0A8),
  ];

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

  factory _TreeLayout.empty() => const _TreeLayout(
    nodes: {},
    marriageMarkers: [],
    size: Size(1, 1),
    parentLinks: [],
  );

  static _TreeLayout build({
    required FamilyTreeData data,
    required _TreeMetrics metrics,
    required double topReservedSpace,
  }) {
    final peopleById = {for (final person in data.people) person.id: person};
    final generations = const GenealogyLayoutService().computeGenerations(data);
    final relationshipErrors = const GenealogyLayoutService()
        .validateRelationshipGraph(data);
    for (final error in relationshipErrors) {
      debugPrint('Genealogy relationship error: $error');
    }
    final levels = <int, List<Person>>{};
    for (final person in data.people) {
      final level = generations[person.id] ?? 0;
      levels.putIfAbsent(level, () => []).add(person);
    }

    final nodes = <Person, Rect>{};
    final markers = <_MarriageMarkerData>[];
    final levelUnits = <int, List<_TreeUnit>>{};
    final levelWidths = <int, double>{};
    final parentRank = <String, double>{};
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
      final units = [...levelUnits[level]!]
        ..sort(
          (a, b) => _compareUnitsByParentRank(a, b, parentRank, peopleById),
        );
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
        final unitRect = _boundsForRects(
          unit.people.map(nodes.get).whereType<Rect>().toList(),
        );
        if (unitRect != null) {
          for (final person in unit.people) {
            parentRank[person.id] = unitRect.center.dx;
          }
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
              marriageYear: _yearOf(
                relation?.traditionalMarriageDate.isNotEmpty == true
                    ? relation!.traditionalMarriageDate
                    : relation?.marriageDate ?? '',
              ),
              divorceYear: _yearOf(relation?.divorceDate ?? ''),
              status: relation?.status ?? 'unknown',
              marriageType: relation?.marriageType ?? 'unknown',
              marriagePlace: relation?.marriagePlace ?? '',
            ),
          );
        }
        x += unit.width(metrics) + metrics.cardGap;
      }
    }

    final linksByFamily = <String, _ParentLink>{};
    for (final person in data.people) {
      final childRect = nodes[person];
      if (childRect == null) continue;
      final parentIds =
          _parentIds(person)
              .where((id) => id != person.id && peopleById.containsKey(id))
              .toSet()
              .toList()
            ..sort();
      final parentRects =
          parentIds
              .map((id) => peopleById[id])
              .whereType<Person>()
              .map(nodes.get)
              .whereType<Rect>()
              .toList()
            ..sort((a, b) => a.center.dx.compareTo(b.center.dx));
      if (parentRects.isEmpty) continue;
      final key = parentIds.join('|');
      final existing = linksByFamily[key];
      if (existing == null) {
        linksByFamily[key] = _ParentLink(
          parentIds: parentIds,
          parentRects: parentRects,
          childRects: [childRect],
          connectorColor: _branchConnectorColors.first,
          connectorLane: 0,
        );
      } else {
        existing.childRects.add(childRect);
      }
    }
    final links =
        linksByFamily.values.map((link) {
          link.childRects.sort((a, b) => a.center.dx.compareTo(b.center.dx));
          return link;
        }).toList()..sort((a, b) {
          final aCenter = _rectsCenterX(a.parentRects);
          final bCenter = _rectsCenterX(b.parentRects);
          final generationCompare = a.parentRects.first.top.compareTo(
            b.parentRects.first.top,
          );
          if (generationCompare != 0) return generationCompare;
          return aCenter.compareTo(bCenter);
        });
    for (var i = 0; i < links.length; i++) {
      links[i].connectorColor =
          _branchConnectorColors[i % _branchConnectorColors.length];
      links[i].connectorLane = i % 4;
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

  static int _compareUnitsByParentRank(
    _TreeUnit first,
    _TreeUnit second,
    Map<String, double> parentRank,
    Map<String, Person> peopleById,
  ) {
    final firstRank = _unitParentRank(first, parentRank, peopleById);
    final secondRank = _unitParentRank(second, parentRank, peopleById);
    final rankCompare = firstRank.compareTo(secondRank);
    if (rankCompare != 0) return rankCompare;
    return first.label.compareTo(second.label);
  }

  static double _unitParentRank(
    _TreeUnit unit,
    Map<String, double> parentRank,
    Map<String, Person> peopleById,
  ) {
    final ranks = <double>[];
    for (final person in unit.people) {
      for (final parentId in _parentIds(person)) {
        final rank = parentRank[parentId];
        if (rank != null && peopleById.containsKey(parentId)) ranks.add(rank);
      }
    }
    if (ranks.isEmpty) return double.maxFinite;
    return ranks.reduce((a, b) => a + b) / ranks.length;
  }

  static Rect? _boundsForRects(List<Rect> rects) {
    if (rects.isEmpty) return null;
    var left = rects.first.left;
    var top = rects.first.top;
    var right = rects.first.right;
    var bottom = rects.first.bottom;
    for (final rect in rects.skip(1)) {
      left = math.min(left, rect.left);
      top = math.min(top, rect.top);
      right = math.max(right, rect.right);
      bottom = math.max(bottom, rect.bottom);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static double _rectsCenterX(List<Rect> rects) {
    if (rects.isEmpty) return 0;
    final bounds = _boundsForRects(rects);
    return bounds?.center.dx ?? 0;
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

  String get label => people.map((person) => person.fullName).join('|');

  double width(_TreeMetrics metrics) {
    return people.length * metrics.cardWidth +
        math.max(people.length - 1, 0) * metrics.spouseGap;
  }
}

class _ParentLink {
  _ParentLink({
    required this.parentIds,
    required this.parentRects,
    required this.childRects,
    required this.connectorColor,
    required this.connectorLane,
  });

  final List<String> parentIds;
  final List<Rect> parentRects;
  final List<Rect> childRects;
  Color connectorColor;
  int connectorLane;
}

class _MarriageMarkerData {
  const _MarriageMarkerData({
    required this.center,
    required this.marriageYear,
    required this.divorceYear,
    required this.status,
    required this.marriageType,
    required this.marriagePlace,
  });

  final Offset center;
  final String marriageYear;
  final String divorceYear;
  final String status;
  final String marriageType;
  final String marriagePlace;
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
    final divorcedMarriage = Paint()
      ..color = const Color(0xFFE5A6AE)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    final traditionalMarriage = Paint()
      ..color = const Color(0xFFE1A928)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    for (final marker in layout.marriageMarkers) {
      final start = offset + Offset(marker.center.dx - 30, marker.center.dy);
      final end = offset + Offset(marker.center.dx + 30, marker.center.dy);
      if (marker.status == 'divorced') {
        _drawDashedLine(canvas, start, end, divorcedMarriage);
      } else if (marker.marriageType == 'traditional') {
        canvas.drawLine(start, end, traditionalMarriage);
      } else {
        canvas.drawLine(start, end, marriage);
      }
    }

    for (final link in layout.parentLinks) {
      final branchConnector = Paint()
        ..color = link.connectorColor.withValues(alpha: 0.72)
        ..strokeWidth = connector.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawFamilyUnitConnectors(canvas, link, branchConnector);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.offset != offset;
  }

  void _drawFamilyUnitConnectors(
    Canvas canvas,
    _ParentLink link,
    Paint connector,
  ) {
    if (link.parentRects.isEmpty || link.childRects.isEmpty) return;

    final parentCenters = link.parentRects
        .map((rect) => offset + rect.bottomCenter)
        .toList();
    final childTops =
        link.childRects.map((rect) => offset + rect.topCenter).toList()
          ..sort((a, b) => a.dx.compareTo(b.dx));
    final parentMinX = parentCenters.map((point) => point.dx).reduce(math.min);
    final parentMaxX = parentCenters.map((point) => point.dx).reduce(math.max);
    final parentAnchor = Offset(
      link.parentRects.length == 1
          ? parentCenters.first.dx
          : (parentMinX + parentMaxX) / 2,
      parentCenters.map((point) => point.dy).reduce(math.max),
    );
    final firstChildTop = childTops.map((point) => point.dy).reduce(math.min);
    final elbowY =
        parentAnchor.dy +
        math.max((firstChildTop - parentAnchor.dy) * 0.45, 18) +
        link.connectorLane * 6;

    canvas.drawLine(parentAnchor, Offset(parentAnchor.dx, elbowY), connector);

    if (childTops.length == 1) {
      final childTop = childTops.first;
      canvas.drawLine(
        Offset(parentAnchor.dx, elbowY),
        Offset(childTop.dx, elbowY),
        connector,
      );
      canvas.drawLine(Offset(childTop.dx, elbowY), childTop, connector);
      return;
    }

    final minChildX = childTops.map((point) => point.dx).reduce(math.min);
    final maxChildX = childTops.map((point) => point.dx).reduce(math.max);
    canvas.drawLine(
      Offset(minChildX, elbowY),
      Offset(maxChildX, elbowY),
      connector,
    );
    for (final childTop in childTops) {
      canvas.drawLine(Offset(childTop.dx, elbowY), childTop, connector);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashGap = 4.0;
    final distance = (end - start).distance;
    final direction = (end - start) / distance;
    var current = 0.0;
    while (current < distance) {
      final next = math.min(current + dashWidth, distance);
      canvas.drawLine(
        start + direction * current,
        start + direction * next,
        paint,
      );
      current += dashWidth + dashGap;
    }
  }
}

class _TreeGridPainter extends CustomPainter {
  const _TreeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E6DD)
      ..strokeWidth = 1;
    const step = 18.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreeGridPainter oldDelegate) => false;
}

class _TreeWorkspaceHeader extends StatelessWidget {
  const _TreeWorkspaceHeader({
    required this.compact,
    required this.familyHead,
    required this.onOpenFamilyHead,
    required this.child,
  });

  final bool compact;
  final Person? familyHead;
  final VoidCallback? onOpenFamilyHead;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final headAccordion = familyHead == null || onOpenFamilyHead == null
        ? null
        : FamilyHeadAccordion(member: familyHead!, onOpen: onOpenFamilyHead!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (headAccordion != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: headAccordion,
                ),
                const SizedBox(height: 8),
              ],
              Align(alignment: AlignmentDirectional.centerStart, child: child),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headAccordion != null) ...[
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: headAccordion,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Align(alignment: Alignment.topCenter, child: child),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                width: 172,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SyncStatusBadge(),
                ),
              ),
            ],
          ),
        if (compact) ...[
          const SizedBox(height: 6),
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SyncStatusBadge(),
          ),
        ],
      ],
    );
  }
}

class FamilyHeadAccordion extends StatefulWidget {
  const FamilyHeadAccordion({
    super.key,
    required this.member,
    required this.onOpen,
  });

  final Person member;
  final VoidCallback onOpen;

  @override
  State<FamilyHeadAccordion> createState() => _FamilyHeadAccordionState();
}

class _FamilyHeadAccordionState extends State<FamilyHeadAccordion> {
  final MenuController _controller = MenuController();
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant FamilyHeadAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.id != widget.member.id && _expanded) {
      _controller.close();
      _expanded = false;
    }
  }

  @override
  void dispose() {
    if (_expanded) _controller.close();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.open();
      } else {
        _controller.close();
      }
    });
  }

  void _onOpenChanged(bool value) {
    if (_expanded == value || !mounted) return;
    setState(() => _expanded = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: _expanded,
      label: _expanded
          ? 'Masquer le chef de famille'
          : 'Afficher le chef de famille',
      value: _expanded ? 'développé' : 'réduit',
      child: MenuAnchor(
        controller: _controller,
        alignmentOffset: const Offset(0, 8),
        onOpen: () => _onOpenChanged(true),
        onClose: () => _onOpenChanged(false),
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        menuChildren: [
          FamilyHeadCard(member: widget.member, onOpen: widget.onOpen),
        ],
        builder: (context, controller, child) {
          return Tooltip(
            message: _expanded
                ? 'Masquer le chef de famille'
                : 'Afficher le chef de famille',
            child: OutlinedButton.icon(
              onPressed: _toggle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: Colors.white.withValues(alpha: 0.96),
                foregroundColor: const Color(0xFF183B2A),
                side: const BorderSide(color: Color(0xFF55752B)),
                padding: const EdgeInsetsDirectional.only(
                  start: 14,
                  end: 10,
                  top: 12,
                  bottom: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFC99A19),
                size: 21,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chef de famille',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    semanticLabel: _expanded ? 'Réduire' : 'Développer',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FamilyHeadCard extends StatelessWidget {
  const FamilyHeadCard({super.key, required this.member, required this.onOpen});

  final Person member;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 64.0;
    final photo = member.photo.trim();
    final name = member.fullName.trim().isEmpty
        ? '${member.firstName} ${member.lastName}'.trim()
        : member.fullName.trim();
    final displayName = name.isEmpty ? 'Chef de famille' : name;
    return Semantics(
      button: true,
      image: photo.isNotEmpty,
      label: 'Chef de famille : $displayName',
      child: Tooltip(
        message: 'Voir la fiche du chef de famille',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpen,
            child: Ink(
              width: 252,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: const Color(0xFFE6F0FA),
                        foregroundColor: const Color(0xFF2F6FA3),
                        backgroundImage: photo.isEmpty
                            ? null
                            : NetworkImage(photo),
                        child: photo.isEmpty
                            ? Text(
                                _initials(member),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        top: -12,
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFC99A19),
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF183B2A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Chef de famille',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(Person person) {
    final first = person.firstName.trim();
    final last = person.lastName.trim();
    final value = [
      if (first.isNotEmpty) first.characters.first,
      if (last.isNotEmpty) last.characters.first,
    ].join();
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class TreeToolbar extends StatelessWidget {
  const TreeToolbar({
    super.key,
    required this.onSearch,
    required this.onCenter,
    required this.onFit,
    required this.onFilters,
    required this.onOptions,
    required this.onAddMember,
    this.compact = false,
    this.canAddMember = false,
    this.filterActive = false,
    this.filterCount = 0,
  });

  final VoidCallback onSearch;
  final VoidCallback onCenter;
  final VoidCallback onFit;
  final VoidCallback onFilters;
  final VoidCallback onOptions;
  final VoidCallback onAddMember;
  final bool compact;
  final bool canAddMember;
  final bool filterActive;
  final int filterCount;

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
            label: compact ? null : 'Rechercher',
            tooltip: 'Rechercher',
            onPressed: onSearch,
          ),
          _Divider(),
          _ToolbarButton(
            icon: Icons.my_location_outlined,
            label: compact ? null : 'Centrer',
            tooltip: 'Centrer',
            onPressed: onCenter,
          ),
          _Divider(),
          _ToolbarButton(
            icon: Icons.fit_screen_outlined,
            label: compact ? null : 'Ajuster',
            tooltip: 'Ajuster',
            onPressed: onFit,
          ),
          _Divider(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ToolbarButton(
                icon: Icons.tune,
                label: compact ? null : 'Filtres',
                tooltip: 'Filtres',
                onPressed: onFilters,
              ),
              if (filterActive)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6AD42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      filterCount.toString(),
                      style: const TextStyle(
                        color: Color(0xFF2F3A13),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _Divider(),
          _ToolbarButton(
            icon: Icons.visibility_outlined,
            label: compact ? null : 'Affichage',
            tooltip: 'Affichage',
            onPressed: onOptions,
          ),
          _ToolbarButton(
            icon: Icons.more_horiz,
            label: compact ? null : 'Plus',
            tooltip: 'Plus',
            onPressed: onOptions,
          ),
          if (canAddMember) ...[
            _Divider(),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: OutlinedButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.add, size: 18),
                label: compact
                    ? const SizedBox.shrink()
                    : const Text('Ajouter un membre'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 42),
                  foregroundColor: const Color(0xFF315B22),
                  side: const BorderSide(color: Color(0xFF5D7E35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
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

class TreeFloatingActionsColumn extends StatelessWidget {
  const TreeFloatingActionsColumn({
    super.key,
    this.compact = false,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onFit,
    this.tutorialButton,
  });

  final bool compact;
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onFit;
  final Widget? tutorialButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TreeZoomControls(
          compact: compact,
          scale: scale,
          onZoomIn: onZoomIn,
          onZoomOut: onZoomOut,
        ),
        SizedBox(height: compact ? 10 : 16),
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
        if (tutorialButton != null) ...[
          SizedBox(height: compact ? 10 : 16),
          SizedBox(
            width: compact ? 48 : 54,
            height: compact ? 48 : 54,
            child: Center(child: tutorialButton),
          ),
        ],
        SizedBox(height: compact ? 10 : 16),
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
            icon: Icons.fit_screen_outlined,
            tooltip: 'Voir tout l’arbre',
            onPressed: onFit,
          ),
        ),
      ],
    );
  }
}

class TreeZoomControls extends StatelessWidget {
  const TreeZoomControls({
    super.key,
    this.compact = false,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final bool compact;
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            width: compact ? 48 : 54,
            height: compact ? 30 : 36,
            child: Center(
              child: Text(
                '${(scale * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF3F433A),
                  fontSize: compact ? 11 : null,
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
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label!),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: const Color(0xFF263428),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
  const TreeLegend({
    super.key,
    this.membersCount,
    this.showMembersCounter = true,
  });

  final int? membersCount;
  final bool showMembersCounter;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[
      const _LegendItem(icon: '♂', label: 'Homme', color: Color(0xFF2D7DD2)),
      const _LegendItem(icon: '♀', label: 'Femme', color: Color(0xFFE53964)),
      const _LegendItem(
        icon: '💍',
        label: 'Marié(e)',
        color: Color(0xFFE6A400),
      ),
      _LegendItem(
        icon: '◇',
        label: l10n.traditionalMarriage,
        color: const Color(0xFFE1A928),
      ),
      const _LegendItem(
        icon: '💔',
        label: 'Divorcé(e)',
        color: Color(0xFFD64D61),
      ),
      const _LegendItem(
        icon: '📍',
        label: 'Lieu connu',
        color: Color(0xFF4C7A2E),
      ),
      if (showMembersCounter && membersCount != null)
        MembersCounterBadge(count: membersCount!, compact: compact),
    ];
    final content = compact
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  items[i],
                ],
              ],
            ),
          )
        : Wrap(
            spacing: 18,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: items,
          );

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: content,
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
  const _MarriageMarker({
    required this.marriageYear,
    required this.divorceYear,
    required this.status,
    required this.marriageType,
    required this.marriagePlace,
  });

  final String marriageYear;
  final String divorceYear;
  final String status;
  final String marriageType;
  final String marriagePlace;

  @override
  Widget build(BuildContext context) {
    final isTraditional = marriageType == 'traditional';
    final tooltipParts = [
      if (isTraditional) AppLocalizations.of(context).traditionalMarriage,
      if (marriageYear.isNotEmpty) marriageYear,
      if (marriagePlace.isNotEmpty) marriagePlace,
    ];
    return Tooltip(
      message: tooltipParts.isEmpty
          ? AppLocalizations.of(context).marriageType
          : tooltipParts.join(' · '),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status == 'divorced'
                ? '💔'
                : isTraditional
                ? '◇'
                : '∞',
            style: TextStyle(
              color: status == 'divorced'
                  ? const Color(0xFFD64D61)
                  : isTraditional
                  ? const Color(0xFFE1A928)
                  : const Color(0xFFE6A400),
              fontSize: status == 'divorced' ? 20 : 28,
              height: 0.9,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (marriageYear.isNotEmpty)
            Text(
              '${isTraditional ? '◇' : '💍'} $marriageYear',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF4F4F45),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (divorceYear.isNotEmpty)
            Text(
              '💔 $divorceYear',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF9A2636),
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
