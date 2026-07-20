import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import '../models/family_tree_data.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';

class ActivityJournalPanel extends ConsumerStatefulWidget {
  const ActivityJournalPanel({
    super.key,
    required this.data,
    required this.auth,
  });

  final FamilyTreeData data;
  final AuthState auth;

  @override
  ConsumerState<ActivityJournalPanel> createState() =>
      _ActivityJournalPanelState();
}

class _ActivityJournalPanelState extends ConsumerState<ActivityJournalPanel> {
  static const _nightBlue = Color(0xFF173B57);
  static const _green = Color(0xFF55752B);
  static const _warmBackground = Color(0xFFF7F6F2);

  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  Timer? _debounce;
  String _query = '';
  String _type = 'all';
  String _status = 'all';
  String _user = 'all';
  String _period = 'all';
  int _page = 0;
  int _rowsPerPage = 10;
  bool _deleting = false;

  bool get _canDelete => widget.auth.canSecurelyDeleteMember;

  @override
  void didUpdateWidget(covariant ActivityJournalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.data.auditLog.map((log) => log.id).toSet();
    _selectedIds.removeWhere((id) => !ids.contains(id));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(activityLogServiceProvider);
    final periodStart = switch (_period) {
      '7d' => DateTime.now().subtract(const Duration(days: 7)),
      '30d' => DateTime.now().subtract(const Duration(days: 30)),
      '90d' => DateTime.now().subtract(const Duration(days: 90)),
      _ => null,
    };
    final filtered = service.filterAndSort(
      widget.data.auditLog,
      query: _query,
      type: _type,
      status: _status,
      user: _user,
      from: periodStart,
    );
    final kpis = service.computeKpis(widget.data.auditLog);
    final pageCount = filtered.isEmpty
        ? 1
        : ((filtered.length - 1) ~/ _rowsPerPage) + 1;
    if (_page >= pageCount) {
      _page = pageCount - 1;
    }
    final start = (_page * _rowsPerPage).clamp(0, filtered.length);
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final visible = filtered.sublist(start, end);
    final types = widget.data.auditLog.map((log) => log.action).toSet().toList()
      ..sort();
    final users =
        widget.data.auditLog
            .map((log) => log.actorRole.isEmpty ? log.adminId : log.actorRole)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ColoredBox(
      color: _warmBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 18),
          _kpiGrid(kpis),
          const SizedBox(height: 18),
          _filters(types, users),
          if (_canDelete && _selectedIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            _selectionToolbar(),
          ],
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E4DF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (filtered.isEmpty) {
                  return _emptyState(widget.data.auditLog.isEmpty);
                }
                if (constraints.maxWidth < 1100) {
                  return Column(
                    children: [
                      if (_canDelete) _selectVisibleControl(visible),
                      ...visible.map((log) => _mobileActivityCard(log)),
                    ],
                  );
                }
                return _activityTable(visible);
              },
            ),
          ),
          const SizedBox(height: 12),
          _pagination(start, end, filtered.length, pageCount),
        ],
      ),
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Admin familial / Journal d’activité',
        style: TextStyle(color: Color(0xFF65727B), fontSize: 13),
      ),
      const SizedBox(height: 8),
      const Text(
        'Journal d’activité',
        style: TextStyle(
          color: _nightBlue,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Consultez et gérez les événements enregistrés pour la famille ${widget.data.mainFamilyCode}.',
        style: const TextStyle(color: Color(0xFF52616B)),
      ),
      const SizedBox(height: 6),
      Text(
        _updatedLabel(),
        style: const TextStyle(color: _green, fontSize: 12),
      ),
    ],
  );

  String _updatedLabel() {
    final date = DateTime.tryParse(widget.data.lastUpdatedAt);
    if (date == null || DateTime.now().difference(date).inMinutes < 1) {
      return 'Mis à jour à l’instant';
    }
    return 'Mis à jour il y a ${DateTime.now().difference(date).inMinutes} min';
  }

  Widget _kpiGrid(dynamic kpis) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1000
          ? 4
          : width >= 560
          ? 2
          : 1;
      final cardWidth = (width - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _kpi(
            'Activités totales',
            kpis.total,
            Icons.history,
            _nightBlue,
            'Tous les événements',
          ),
          _kpi(
            'Synchronisations réussies',
            kpis.successfulSyncs,
            Icons.cloud_done_outlined,
            _green,
            'Écritures confirmées',
          ),
          _kpi(
            'Échecs',
            kpis.failures,
            Icons.error_outline,
            const Color(0xFFB3261E),
            'Actions en erreur',
          ),
          _kpi(
            'Suppressions',
            kpis.deletions,
            Icons.delete_outline,
            const Color(0xFF8A4D45),
            'Événements destructifs',
          ),
        ].map((card) => SizedBox(width: cardWidth, child: card)).toList(),
      );
    },
  );

  Widget _kpi(
    String label,
    int value,
    IconData icon,
    Color color,
    String note,
  ) => Card(
    elevation: 1,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE2E4DF)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF65727B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filters(List<String> types, List<String> users) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFE2E4DF)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              key: const Key('activity-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher une activité, un membre…',
                isDense: true,
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _query = value;
                      _page = 0;
                    });
                  }
                });
              },
            ),
          ),
          _dropdown(
            'Type',
            _type,
            [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tous les types'),
              ),
              ...types.map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    ref.read(activityLogServiceProvider).labelForAction(value),
                  ),
                ),
              ),
            ],
            (value) => setState(() {
              _type = value!;
              _page = 0;
            }),
          ),
          _dropdown(
            'Statut',
            _status,
            const [
              DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
              DropdownMenuItem(value: 'success', child: Text('Réussi')),
              DropdownMenuItem(value: 'failure', child: Text('Échec')),
              DropdownMenuItem(value: 'info', child: Text('Information')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
            ],
            (value) => setState(() {
              _status = value!;
              _page = 0;
            }),
          ),
          _dropdown(
            'Utilisateur',
            _user,
            [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tous les utilisateurs'),
              ),
              ...users.map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              ),
            ],
            (value) => setState(() {
              _user = value!;
              _page = 0;
            }),
          ),
          _dropdown(
            'Période',
            _period,
            const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Toutes les périodes'),
              ),
              DropdownMenuItem(value: '7d', child: Text('7 derniers jours')),
              DropdownMenuItem(value: '30d', child: Text('30 derniers jours')),
              DropdownMenuItem(value: '90d', child: Text('3 derniers mois')),
            ],
            (value) => setState(() {
              _period = value!;
              _page = 0;
            }),
          ),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Réinitialiser'),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => ref
                .read(familyTreeProvider.notifier)
                .startRemoteFamilyTreeWatch(includeActivityLog: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 180,
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items,
      onChanged: onChanged,
    ),
  );

  Widget _selectionToolbar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFDECEA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text('${_selectedIds.length} activité(s) sélectionnée(s)'),
        ),
        TextButton(
          onPressed: () => setState(_selectedIds.clear),
          child: const Text('Tout désélectionner'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: const Key('delete-selected-activities'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB3261E),
          ),
          onPressed: _deleting ? null : () => _confirmDelete(_selectedIds),
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(
            _deleting ? 'Suppression…' : 'Supprimer (${_selectedIds.length})',
          ),
        ),
      ],
    ),
  );

  Widget _activityTable(List<AuditLog> logs) => DataTable(
    showCheckboxColumn: false,
    headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F4F1)),
    columns: [
      if (_canDelete)
        DataColumn(label: _selectVisibleControl(logs, compact: true)),
      const DataColumn(label: Text('Activité')),
      const DataColumn(label: Text('Élément concerné')),
      const DataColumn(label: Text('Utilisateur')),
      const DataColumn(label: Text('Date et heure')),
      const DataColumn(label: Text('Statut')),
      const DataColumn(label: Text('Actions')),
    ],
    rows: logs
        .map(
          (log) => DataRow(
            key: ValueKey(log.id),
            cells: [
              if (_canDelete)
                DataCell(
                  Checkbox(
                    semanticLabel:
                        'Sélectionner ${ref.read(activityLogServiceProvider).labelForAction(log.action)}',
                    value: _selectedIds.contains(log.id),
                    onChanged: (value) => setState(
                      () => value == true
                          ? _selectedIds.add(log.id)
                          : _selectedIds.remove(log.id),
                    ),
                  ),
                ),
              DataCell(_activityLabel(log), onTap: () => _showDetails(log)),
              DataCell(Text(log.personId.isEmpty ? '—' : log.personId)),
              DataCell(Text(log.actorRole.isEmpty ? '—' : log.actorRole)),
              DataCell(Text(_formatDate(log.date))),
              DataCell(
                _ActivityStatusBadge(
                  status: ref.read(activityLogServiceProvider).statusFor(log),
                ),
              ),
              DataCell(_actions(log)),
            ],
          ),
        )
        .toList(growable: false),
  );

  Widget _selectVisibleControl(List<AuditLog> visible, {bool compact = false}) {
    final visibleIds = visible.map((log) => log.id).toSet();
    final allSelected =
        visibleIds.isNotEmpty && _selectedIds.containsAll(visibleIds);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          semanticLabel: 'Sélectionner les activités visibles',
          value: allSelected,
          onChanged: (selected) => setState(() {
            if (selected == true) {
              _selectedIds.addAll(visibleIds);
            } else {
              _selectedIds.removeAll(visibleIds);
            }
          }),
        ),
        if (!compact) const Text('Sélectionner les éléments visibles'),
      ],
    );
  }

  Widget _mobileActivityCard(AuditLog log) => ListTile(
    key: ValueKey(log.id),
    minVerticalPadding: 12,
    leading: _canDelete
        ? Checkbox(
            value: _selectedIds.contains(log.id),
            onChanged: (value) => setState(
              () => value == true
                  ? _selectedIds.add(log.id)
                  : _selectedIds.remove(log.id),
            ),
          )
        : const Icon(Icons.history, color: _nightBlue),
    title: _activityLabel(log),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(_formatDate(log.date)),
          _ActivityStatusBadge(
            status: ref.read(activityLogServiceProvider).statusFor(log),
          ),
        ],
      ),
    ),
    trailing: _actions(log),
    onTap: () => _showDetails(log),
  );

  Widget _activityLabel(AuditLog log) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        ref.read(activityLogServiceProvider).labelForAction(log.action),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      Text(
        log.action,
        style: const TextStyle(fontSize: 11, color: Color(0xFF65727B)),
      ),
    ],
  );

  Widget _actions(AuditLog log) => PopupMenuButton<String>(
    tooltip: 'Actions',
    onSelected: (value) =>
        value == 'details' ? _showDetails(log) : _confirmDelete({log.id}),
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'details',
        child: ListTile(
          leading: Icon(Icons.visibility_outlined),
          title: Text('Voir les détails'),
        ),
      ),
      if (_canDelete)
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Color(0xFFB3261E)),
            title: Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ),
    ],
  );

  Widget _emptyState(bool completelyEmpty) => Padding(
    padding: const EdgeInsets.all(36),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history_toggle_off,
            size: 44,
            color: Color(0xFF65727B),
          ),
          const SizedBox(height: 10),
          Text(
            completelyEmpty
                ? 'Aucune activité enregistrée pour le moment.'
                : 'Aucun résultat pour ces filtres.',
          ),
        ],
      ),
    ),
  );

  Widget _pagination(int start, int end, int total, int pageCount) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(total == 0 ? '0 sur 0' : '${start + 1}–$end sur $total'),
      DropdownButton<int>(
        value: _rowsPerPage,
        items: const [10, 25, 50]
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text('$value lignes')),
            )
            .toList(),
        onChanged: (value) => setState(() {
          _rowsPerPage = value!;
          _page = 0;
        }),
      ),
      IconButton(
        tooltip: 'Page précédente',
        onPressed: _page > 0 ? () => setState(() => _page--) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Text('${_page + 1} / $pageCount'),
      IconButton(
        tooltip: 'Page suivante',
        onPressed: _page + 1 < pageCount ? () => setState(() => _page++) : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  void _resetFilters() => setState(() {
    _debounce?.cancel();
    _searchController.clear();
    _query = '';
    _type = 'all';
    _status = 'all';
    _user = 'all';
    _period = 'all';
    _page = 0;
  });

  Future<void> _confirmDelete(Set<String> ids) async {
    if (!_canDelete || _deleting || ids.isEmpty) return;
    final count = ids.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            count == 1
                ? 'Supprimer cette activité ?'
                : 'Supprimer $count activités ?',
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette action supprimera définitivement les activités sélectionnées du journal.',
              ),
              SizedBox(height: 12),
              Text(
                'Cette action est réservée aux administrateurs et ne peut pas être annulée.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final result = await ref
          .read(familyTreeProvider.notifier)
          .deleteActivityLogsByIds(
            activityIds: ids,
            actorRole: widget.auth.firebaseRole ?? '',
            actorUid: widget.auth.firebaseUid ?? '',
          );
      if (!mounted) return;
      setState(
        () => _selectedIds.removeAll(ids.difference(result.failedIds.toSet())),
      );
      final message = result.failedCount == 0
          ? '${result.deletedCount} activité(s) supprimée(s).'
          : '${result.deletedCount} supprimée(s), ${result.failedCount} en échec.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La suppression nécessite une connexion sécurisée à Firebase.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showDetails(AuditLog log) {
    final service = ref.read(activityLogServiceProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.labelForAction(log.action),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _detail('Code technique', log.action),
              _detail('Date et heure', _formatDate(log.date)),
              _detail('Élément concerné', _maskIdentifier(log.personId)),
              _detail('Utilisateur / rôle', log.actorRole),
              _detail('Statut', _statusLabel(service.statusFor(log))),
              if (log.description.isNotEmpty)
                _detail('Message', _sanitize(log.description)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    ),
  );
  String _sanitize(String value) => value.replaceAll(
    RegExp(r'(token|password|secret|code)\s*[:=]\s*\S+', caseSensitive: false),
    r'$1: [masqué]',
  );
  String _maskIdentifier(String value) => value.length <= 8
      ? value
      : '${value.substring(0, 4)}…${value.substring(value.length - 4)}';
  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value.isEmpty ? '—' : value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) => switch (status) {
    'success' => 'Réussi',
    'failure' => 'Échec',
    'pending' => 'En attente',
    'cancelled' => 'Annulé',
    _ => 'Information',
  };
}

class _ActivityStatusBadge extends StatelessWidget {
  const _ActivityStatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      'success' => ('Réussi', const Color(0xFF31551B), const Color(0xFFE7F0DF)),
      'failure' => ('Échec', const Color(0xFF9B1C16), const Color(0xFFFDECEA)),
      'pending' => (
        'En attente',
        const Color(0xFF8A5B00),
        const Color(0xFFFFF0D5),
      ),
      'cancelled' => (
        'Annulé',
        const Color(0xFF555B60),
        const Color(0xFFECEEEF),
      ),
      _ => ('Information', const Color(0xFF173B57), const Color(0xFFE5EFF5)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
