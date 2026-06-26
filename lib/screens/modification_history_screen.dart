import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/modification_history_card.dart';

class ModificationHistoryScreen extends ConsumerStatefulWidget {
  const ModificationHistoryScreen({super.key});

  @override
  ConsumerState<ModificationHistoryScreen> createState() =>
      _ModificationHistoryScreenState();
}

class _ModificationHistoryScreenState
    extends ConsumerState<ModificationHistoryScreen> {
  final _searchController = TextEditingController();
  String _action = '';
  String _modifier = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(familyTreeProvider).value!;
    final allItems = ref.read(modificationHistoryServiceProvider).recent(data);
    final actions = allItems.map((item) => item.action).toSet().toList()
      ..sort();
    final modifiers =
        allItems.map((item) => item.modifiedByName).toSet().toList()..sort();
    final query = _searchController.text.trim().toLowerCase();
    final items = allItems.where((item) {
      final matchesQuery =
          query.isEmpty || item.personFullName.toLowerCase().contains(query);
      final matchesAction = _action.isEmpty || item.action == _action;
      final matchesModifier =
          _modifier.isEmpty || item.modifiedByName == _modifier;
      return matchesQuery && matchesAction && matchesModifier;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des modifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Rechercher une personne',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _action,
                    decoration: const InputDecoration(labelText: 'Action'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Toutes')),
                      ...actions.map(
                        (action) => DropdownMenuItem(
                          value: action,
                          child: Text(action),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _action = value ?? ''),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: _modifier,
                    decoration: const InputDecoration(
                      labelText: 'Modificateur',
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Tous')),
                      ...modifiers.map(
                        (modifier) => DropdownMenuItem(
                          value: modifier,
                          child: Text(modifier),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _modifier = value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Aucune modification sur la période.'),
                    )
                  : ListView.separated(
                      itemBuilder: (context, index) =>
                          ModificationHistoryCard(item: items[index]),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemCount: items.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
