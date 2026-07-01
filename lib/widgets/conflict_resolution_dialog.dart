import 'package:flutter/material.dart';

import '../services/conflict_resolution_service.dart';

class ConflictResolutionDialog extends StatelessWidget {
  const ConflictResolutionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conflit détecté'),
      content: const Text(
        'Une version locale et une version distante ont été modifiées. Choisissez quelle version conserver.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ConflictResolutionChoice.keepLocal),
          child: const Text('Garder version locale'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, ConflictResolutionChoice.keepRemote),
          child: const Text('Garder version distante'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ConflictResolutionChoice.mergeManually),
          child: const Text('Fusionner manuellement'),
        ),
      ],
    );
  }
}
