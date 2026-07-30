import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sync_incident.dart';

typedef IncidentStatusChanged =
    Future<void> Function(SyncIncident incident, String status);

class IncidentDashboardPage extends StatefulWidget {
  const IncidentDashboardPage({
    super.key,
    required this.incidents,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  final List<SyncIncident> incidents;
  final Future<void> Function() onRefresh;
  final IncidentStatusChanged onStatusChanged;

  @override
  State<IncidentDashboardPage> createState() => _IncidentDashboardPageState();
}

class _IncidentDashboardPageState extends State<IncidentDashboardPage> {
  final _searchController = TextEditingController();
  String _severity = 'all';
  String _type = 'all';
  String _resource = 'all';
  String _period = 'all';
  int _pageSize = 20;
  int _page = 0;
  SyncIncident? _selectedIncident;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SyncIncident> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final result = widget.incidents.where((incident) {
      final date = DateTime.tryParse(incident.lastOccurredAt);
      final inPeriod = switch (_period) {
        '24h' => date != null && now.difference(date).inHours <= 24,
        '7d' => date != null && now.difference(date).inDays <= 7,
        '30d' => date != null && now.difference(date).inDays <= 30,
        _ => true,
      };
      final haystack = [
        incident.id,
        incident.errorType,
        incident.errorCode,
        incident.operationType,
        incident.collectionName,
        incident.documentId,
        incident.userEmail,
        incident.userId,
      ].join(' ').toLowerCase();
      return (_severity == 'all' || incident.severity == _severity) &&
          (_type == 'all' || incident.errorType == _type) &&
          (_resource == 'all' || incident.collectionName == _resource) &&
          inPeriod &&
          (query.isEmpty || haystack.contains(query));
    }).toList()..sort((a, b) => b.lastOccurredAt.compareTo(a.lastOccurredAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pageCount = filtered.isEmpty
        ? 1
        : ((filtered.length - 1) ~/ _pageSize) + 1;
    if (_page >= pageCount) _page = pageCount - 1;
    final start = _page * _pageSize;
    final visible = filtered.skip(start).take(_pageSize).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IncidentHeader(
              onRefresh: widget.onRefresh,
              onExport: () => _export(context, filtered),
            ),
            const SizedBox(height: 20),
            IncidentSummaryCards(incidents: widget.incidents),
            const SizedBox(height: 20),
            IncidentToolbar(
              searchController: _searchController,
              severity: _severity,
              type: _type,
              resource: _resource,
              period: _period,
              types: _values(widget.incidents, (item) => item.errorType),
              resources: _values(
                widget.incidents,
                (item) => item.collectionName,
              ),
              onSearchChanged: (_) => _resetPage(),
              onSeverityChanged: (value) => setState(() => _severity = value),
              onTypeChanged: (value) => setState(() => _type = value),
              onResourceChanged: (value) => setState(() => _resource = value),
              onPeriodChanged: (value) => setState(() => _period = value),
              onExport: () => _export(context, filtered),
              onClear: _clearFilters,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: filtered.isEmpty
                  ? IncidentEmptyState(
                      key: const ValueKey('empty'),
                      onRefresh: widget.onRefresh,
                    )
                  : IncidentDataTable(
                      key: ValueKey('${filtered.length}-$_page-$_pageSize'),
                      incidents: visible,
                      onSelected: (incident) =>
                          setState(() => _selectedIncident = incident),
                      onStatusChanged: widget.onStatusChanged,
                    ),
            ),
            if (filtered.isNotEmpty) ...[
              const SizedBox(height: 14),
              IncidentPagination(
                page: _page,
                pageSize: _pageSize,
                total: filtered.length,
                onPageChanged: (value) => setState(() => _page = value),
                onPageSizeChanged: (value) => setState(() {
                  _pageSize = value;
                  _page = 0;
                }),
              ),
            ],
          ],
        ),
        if (_selectedIncident != null)
          Positioned.fill(
            child: IncidentDetailsDrawer(
              incident: _selectedIncident!,
              onClose: () => setState(() => _selectedIncident = null),
              onStatusChanged: (status) async {
                await widget.onStatusChanged(_selectedIncident!, status);
                if (mounted) setState(() => _selectedIncident = null);
              },
            ),
          ),
      ],
    );
  }

  List<String> _values(
    List<SyncIncident> incidents,
    String Function(SyncIncident) select,
  ) {
    final values =
        incidents.map(select).where((value) => value.isNotEmpty).toSet()
          ..remove('');
    return values.toList()..sort();
  }

  void _resetPage() => setState(() => _page = 0);

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _severity = 'all';
      _type = 'all';
      _resource = 'all';
      _period = 'all';
      _page = 0;
    });
  }

  Future<void> _export(
    BuildContext context,
    List<SyncIncident> incidents,
  ) async {
    final rows = <String>[
      'date,gravite,type,code,operation,ressource,source,utilisateur,statut',
      for (final item in incidents)
        [
          item.lastOccurredAt,
          item.severity,
          item.errorType,
          item.errorCode,
          item.operationType,
          '${item.collectionName}/${item.documentId}',
          _source(item),
          _user(item),
          item.status,
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV copié dans le presse-papiers.')),
    );
  }
}

class _IncidentHeader extends StatelessWidget {
  const _IncidentHeader({required this.onRefresh, required this.onExport});

  final Future<void> Function() onRefresh;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.gpp_maybe_outlined, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incidents',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Surveillez et gérez les problèmes détectés dans l’application.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _SoftBadge(
              label: 'Autorisation requise',
              icon: Icons.lock_outline,
              foreground: Color(0xFFA05A00),
              background: Color(0xFFFFF1D6),
            ),
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Exporter'),
            ),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualiser'),
            ),
          ],
        );
        if (constraints.maxWidth < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class IncidentSummaryCards extends StatelessWidget {
  const IncidentSummaryCards({super.key, required this.incidents});

  final List<SyncIncident> incidents;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData(
        'Nouveaux',
        incidents.where((item) => item.status == 'new').length,
        'Incidents non traités',
        Icons.person_off_outlined,
        const Color(0xFFD64545),
        const Color(0xFFFFEEEE),
      ),
      _SummaryData(
        'En cours',
        incidents.where((item) => item.status == 'inProgress').length,
        'Analyse en cours',
        Icons.hourglass_top_rounded,
        const Color(0xFFC46B17),
        const Color(0xFFFFF3E6),
      ),
      _SummaryData(
        'Résolus',
        incidents.where((item) => item.status == 'resolved').length,
        'Incidents corrigés',
        Icons.verified_outlined,
        const Color(0xFF2774C7),
        const Color(0xFFEAF3FF),
      ),
      _SummaryData(
        'Critiques',
        incidents.where((item) => item.severity == 'critical').length,
        'Intervention immédiate',
        Icons.flag_outlined,
        const Color(0xFF7651B5),
        const Color(0xFFF2ECFF),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.1 : 1.8,
          children: [
            for (final card in cards) _IncidentSummaryCard(data: card),
          ],
        );
      },
    );
  }
}

class _IncidentSummaryCard extends StatefulWidget {
  const _IncidentSummaryCard({required this.data});

  final _SummaryData data;

  @override
  State<_IncidentSummaryCard> createState() => _IncidentSummaryCardState();
}

class _IncidentSummaryCardState extends State<_IncidentSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.data.tint),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.data.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.data.icon, color: widget.data.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.data.value.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: widget.data.color,
                    ),
                  ),
                  Text(
                    widget.data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentToolbar extends StatelessWidget {
  const IncidentToolbar({
    super.key,
    required this.searchController,
    required this.severity,
    required this.type,
    required this.resource,
    required this.period,
    required this.types,
    required this.resources,
    required this.onSearchChanged,
    required this.onSeverityChanged,
    required this.onTypeChanged,
    required this.onResourceChanged,
    required this.onPeriodChanged,
    required this.onExport,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String severity;
  final String type;
  final String resource;
  final String period;
  final List<String> types;
  final List<String> resources;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onResourceChanged;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(context),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IncidentSearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          IncidentFilterBar(
            severity: severity,
            type: type,
            resource: resource,
            period: period,
            types: types,
            resources: resources,
            onSeverityChanged: onSeverityChanged,
            onTypeChanged: onTypeChanged,
            onResourceChanged: onResourceChanged,
            onPeriodChanged: onPeriodChanged,
          ),
          OutlinedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.table_view_outlined, size: 18),
            label: const Text('Exporter CSV'),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Effacer les filtres'),
          ),
        ],
      ),
    );
  }
}

class IncidentSearchBar extends StatelessWidget {
  const IncidentSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Rechercher un incident…',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
      ),
    );
  }
}

class IncidentFilterBar extends StatelessWidget {
  const IncidentFilterBar({
    super.key,
    required this.severity,
    required this.type,
    required this.resource,
    required this.period,
    required this.types,
    required this.resources,
    required this.onSeverityChanged,
    required this.onTypeChanged,
    required this.onResourceChanged,
    required this.onPeriodChanged,
  });

  final String severity;
  final String type;
  final String resource;
  final String period;
  final List<String> types;
  final List<String> resources;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onResourceChanged;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterDropdown(
          value: severity,
          label: 'Gravité',
          items: const {
            'all': 'Toutes',
            'warning': 'Warning',
            'critical': 'Critique',
          },
          onChanged: onSeverityChanged,
        ),
        _FilterDropdown(
          value: type,
          label: 'Type',
          items: {'all': 'Tous', for (final value in types) value: value},
          onChanged: onTypeChanged,
        ),
        _FilterDropdown(
          value: resource,
          label: 'Ressource',
          items: {'all': 'Toutes', for (final value in resources) value: value},
          onChanged: onResourceChanged,
        ),
        _FilterDropdown(
          value: period,
          label: 'Période',
          items: const {
            'all': 'Toutes',
            '24h': '24 heures',
            '7d': '7 jours',
            '30d': '30 jours',
          },
          onChanged: onPeriodChanged,
        ),
      ],
    );
  }
}

class IncidentDataTable extends StatelessWidget {
  const IncidentDataTable({
    super.key,
    required this.incidents,
    required this.onSelected,
    required this.onStatusChanged,
  });

  final List<SyncIncident> incidents;
  final ValueChanged<SyncIncident> onSelected;
  final IncidentStatusChanged onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _panelDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              children: [
                for (final incident in incidents)
                  _IncidentMobileCard(
                    incident: incident,
                    onTap: () => onSelected(incident),
                    onStatusChanged: onStatusChanged,
                  ),
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              dataRowColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered)
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.22)
                    : null,
              ),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Gravité')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Code')),
                DataColumn(label: Text('Opération')),
                DataColumn(label: Text('Ressource')),
                DataColumn(label: Text('Source')),
                DataColumn(label: Text('Utilisateur')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final incident in incidents)
                  DataRow(
                    onSelectChanged: (_) => onSelected(incident),
                    cells: [
                      DataCell(_IncidentDate(value: incident.lastOccurredAt)),
                      DataCell(IncidentSeverityBadge(value: incident.severity)),
                      DataCell(_IncidentBadge(value: incident.errorType)),
                      DataCell(_IncidentBadge(value: incident.errorCode)),
                      DataCell(_IncidentBadge(value: incident.operationType)),
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: Text(
                            '${incident.collectionName}/${incident.documentId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            _source(incident),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: Text(
                            _user(incident),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        IncidentActionMenu(
                          incident: incident,
                          onView: () => onSelected(incident),
                          onStatusChanged: onStatusChanged,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class IncidentSeverityBadge extends StatelessWidget {
  const IncidentSeverityBadge({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final critical = value == 'critical';
    return _SoftBadge(
      label: critical ? 'critical' : value,
      icon: critical ? Icons.error_outline : Icons.warning_amber_rounded,
      foreground: critical ? const Color(0xFFB42318) : const Color(0xFFA05A00),
      background: critical ? const Color(0xFFFFE7E5) : const Color(0xFFFFF1D6),
    );
  }
}

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final data = switch (value) {
      'inProgress' => (
        'En analyse',
        const Color(0xFFA05A00),
        const Color(0xFFFFF1D6),
      ),
      'resolved' => (
        'Résolu',
        const Color(0xFF287A3E),
        const Color(0xFFE5F6E9),
      ),
      'ignored' => ('Ignoré', const Color(0xFF667085), const Color(0xFFF0F2F5)),
      _ => ('Nouveau', const Color(0xFFB42318), const Color(0xFFFFE7E5)),
    };
    return _SoftBadge(label: data.$1, foreground: data.$2, background: data.$3);
  }
}

class IncidentActionMenu extends StatelessWidget {
  const IncidentActionMenu({
    super.key,
    required this.incident,
    required this.onView,
    required this.onStatusChanged,
  });

  final SyncIncident incident;
  final VoidCallback onView;
  final IncidentStatusChanged onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onView, child: const Text('Voir')),
        PopupMenuButton<String>(
          tooltip: 'Plus d’actions',
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) => onStatusChanged(incident, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'new', child: Text('Marquer nouveau')),
            PopupMenuItem(
              value: 'inProgress',
              child: Text('Mettre en analyse'),
            ),
            PopupMenuItem(value: 'resolved', child: Text('Marquer résolu')),
            PopupMenuItem(value: 'ignored', child: Text('Ignorer')),
          ],
        ),
      ],
    );
  }
}

class IncidentDetailsDrawer extends StatelessWidget {
  const IncidentDetailsDrawer({
    super.key,
    required this.incident,
    required this.onClose,
    required this.onStatusChanged,
  });

  final SyncIncident incident;
  final VoidCallback onClose;
  final Future<void> Function(String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      child: InkWell(
        onTap: onClose,
        child: Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () {},
            child: Container(
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width
                  : 520,
              height: double.infinity,
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Détails de l’incident',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fermer',
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              IncidentSeverityBadge(value: incident.severity),
                              IncidentStatusBadge(value: incident.status),
                              _IncidentBadge(value: incident.errorCode),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _DetailsSection(
                            title: 'Informations générales',
                            children: [
                              _DetailRow(label: 'Incident', value: incident.id),
                              _DetailRow(
                                label: 'Horodatage',
                                value: incident.lastOccurredAt,
                              ),
                              _DetailRow(
                                label: 'Utilisateur',
                                value: _user(incident),
                              ),
                              _DetailRow(
                                label: 'Ressource',
                                value:
                                    '${incident.collectionName}/${incident.documentId}',
                              ),
                              _DetailRow(
                                label: 'Opération',
                                value: incident.operationType,
                              ),
                            ],
                          ),
                          _DetailsSection(
                            title: 'Description complète',
                            children: [
                              SelectableText(
                                incident.safeMessage.isEmpty
                                    ? incident.technicalMessage
                                    : incident.safeMessage,
                              ),
                            ],
                          ),
                          _DetailsSection(
                            title: 'Message d’erreur',
                            children: [
                              SelectableText(
                                incident.technicalMessage.isEmpty
                                    ? incident.errorCode
                                    : incident.technicalMessage,
                              ),
                            ],
                          ),
                          _DetailsSection(
                            title: 'Environnement',
                            children: [
                              _DetailRow(
                                label: 'Navigateur / plateforme',
                                value: incident.platform.isEmpty
                                    ? 'Non renseigné'
                                    : incident.platform,
                              ),
                              _DetailRow(
                                label: 'Version application',
                                value: incident.appVersion.isEmpty
                                    ? 'Non renseignée'
                                    : incident.appVersion,
                              ),
                              const _DetailRow(
                                label: 'Version Flutter',
                                value: 'Non renseignée',
                              ),
                              const _DetailRow(
                                label: 'Version Firebase',
                                value: 'Non renseignée',
                              ),
                              _DetailRow(
                                label: 'Source',
                                value: _source(incident),
                              ),
                            ],
                          ),
                          _DetailsSection(
                            title: 'Pile d’appel',
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  incident.stackTrace.trim().isEmpty
                                      ? 'Pile d’appel indisponible.'
                                      : incident.stackTrace,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyDiagnostic(context),
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copier'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _copyDiagnostic(context),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Télécharger'),
                          ),
                          FilledButton.icon(
                            onPressed: () => onStatusChanged('resolved'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marquer résolu'),
                          ),
                          Tooltip(
                            message: 'Intégration ticket non configurée',
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(
                                Icons.confirmation_number_outlined,
                              ),
                              label: const Text('Créer ticket'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyDiagnostic(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: [
          'incident=${incident.id}',
          'date=${incident.lastOccurredAt}',
          'user=${_user(incident)}',
          'operation=${incident.operationType}',
          'resource=${incident.collectionName}/${incident.documentId}',
          'errorType=${incident.errorType}',
          'errorCode=${incident.errorCode}',
          'message=${incident.technicalMessage}',
          'source=${_source(incident)}',
          'platform=${incident.platform}',
          'appVersion=${incident.appVersion}',
          'stackTrace=${incident.stackTrace}',
        ].join('\n'),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Diagnostic copié.')));
  }
}

class IncidentPagination extends StatelessWidget {
  const IncidentPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final first = total == 0 ? 0 : page * pageSize + 1;
    final last = ((page + 1) * pageSize).clamp(0, total);
    final lastPage = total == 0 ? 0 : (total - 1) ~/ pageSize;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        const Text('Lignes par page'),
        DropdownButton<int>(
          value: pageSize,
          items: const [10, 20, 50, 100]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value')),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onPageSizeChanged(value);
          },
        ),
        Text('$first–$last sur $total incidents'),
        IconButton(
          tooltip: 'Page précédente',
          onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Page suivante',
          onPressed: page < lastPage ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class IncidentEmptyState extends StatelessWidget {
  const IncidentEmptyState({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun incident détecté',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }
}

class IncidentLoadingState extends StatelessWidget {
  const IncidentLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _IncidentMobileCard extends StatelessWidget {
  const _IncidentMobileCard({
    required this.incident,
    required this.onTap,
    required this.onStatusChanged,
  });

  final SyncIncident incident;
  final VoidCallback onTap;
  final IncidentStatusChanged onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IncidentSeverityBadge(value: incident.severity),
                const SizedBox(width: 8),
                IncidentStatusBadge(value: incident.status),
                const Spacer(),
                IncidentActionMenu(
                  incident: incident,
                  onView: onTap,
                  onStatusChanged: onStatusChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${incident.operationType} · ${incident.collectionName}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${incident.errorCode} · ${_shortDate(incident.lastOccurredAt)}',
            ),
            Text(
              incident.documentId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentDate extends StatelessWidget {
  const _IncidentDate({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return const Text('-');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
        Text(
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _IncidentBadge extends StatelessWidget {
  const _IncidentBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = switch (value) {
      'permission-denied' ||
      'unauthenticated' => (const Color(0xFFB42318), const Color(0xFFFFE7E5)),
      'create' => (const Color(0xFF287A3E), const Color(0xFFE5F6E9)),
      'update' => (const Color(0xFF2774C7), const Color(0xFFEAF3FF)),
      'delete' => (const Color(0xFFB42318), const Color(0xFFFFE7E5)),
      _ => (
        Theme.of(context).colorScheme.onSurfaceVariant,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    };
    return _SoftBadge(
      label: value.isEmpty ? '-' : value,
      foreground: colors.$1,
      background: colors.$2,
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String label;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      key: ValueKey('$label-$value'),
      width: 155,
      initialSelection: value,
      label: Text(label),
      inputDecorationTheme: const InputDecorationTheme(isDense: true),
      dropdownMenuEntries: [
        for (final entry in items.entries)
          DropdownMenuEntry(value: entry.key, label: entry.value),
      ],
      onSelected: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData(
    this.label,
    this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.tint,
  );

  final String label;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
}

BoxDecoration _panelDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.7),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String _shortDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _source(SyncIncident incident) {
  final function = incident.sourceFunction.trim();
  final file = incident.sourceFile.trim();
  if (file.isEmpty && function.isEmpty) return 'Indisponible';
  final line = incident.sourceLine;
  final location = file.isEmpty
      ? ''
      : line == null
      ? file
      : '$file:$line';
  if (function.isEmpty) return location;
  if (location.isEmpty) return function;
  return '$function · $location';
}

String _user(SyncIncident incident) {
  if (incident.userEmail.trim().isNotEmpty) return incident.userEmail;
  if (incident.userId.trim().isNotEmpty) return incident.userId;
  return 'Non identifié';
}

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
