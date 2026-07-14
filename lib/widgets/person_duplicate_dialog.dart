import 'package:flutter/material.dart';

import '../models/person_duplicate_match.dart';

class PersonDuplicateDialog extends StatelessWidget {
  const PersonDuplicateDialog({super.key, required this.matches});

  final List<PersonDuplicateMatch> matches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Doublon probable détecté'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une fiche existante contient déjà des informations très proches.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _DuplicateMatchTile(match: matches[index]);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, PersonDuplicateDecision.cancel),
          child: const Text('Annuler'),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.pop(context, PersonDuplicateDecision.openExisting),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier la fiche existante'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.pop(context, PersonDuplicateDecision.saveAnyway),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer quand même'),
        ),
      ],
    );
  }
}

class _DuplicateMatchTile extends StatelessWidget {
  const _DuplicateMatchTile({required this.match});

  final PersonDuplicateMatch match;

  @override
  Widget build(BuildContext context) {
    final person = match.person;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE2D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(_initials(person.fullName))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'ID ${person.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text('Score ${match.score}')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (person.birthDate.isNotEmpty)
                  _InfoChip(icon: Icons.cake_outlined, label: person.birthDate),
                if (person.birthPlace.isNotEmpty)
                  _InfoChip(
                    icon: Icons.place_outlined,
                    label: person.birthPlace,
                  ),
                if (person.familyCode.isNotEmpty)
                  _InfoChip(
                    icon: Icons.account_tree_outlined,
                    label: person.familyCode,
                  ),
                if (person.generation > 0)
                  _InfoChip(
                    icon: Icons.groups_2_outlined,
                    label: 'G${person.generation}',
                  ),
              ],
            ),
            if (match.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                match.reasons.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF536238),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE1D4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF536238)),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
