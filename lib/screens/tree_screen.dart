import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/family_tree_canvas.dart';
import '../widgets/title_with_superscript_count.dart';
import 'person_detail_screen.dart';

class TreeScreen extends ConsumerWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final visiblePeopleCount = auth.isAuthenticated
        ? data.people.length
        : data.people.where(_isPubliclyVisible).length;
    return Scaffold(
      appBar: AppBar(
        title: TitleWithSuperscriptCount(
          title: l10n.familyTreeTitle,
          count: visiblePeopleCount,
          semanticLabel: l10n.visiblePeopleCount,
        ),
      ),
      body: FamilyTreeCanvas(
        data: data,
        authMode: auth.mode,
        onOpenPerson: (person) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(personId: person.id),
          ),
        ),
      ),
    );
  }

  bool _isPubliclyVisible(Person person) {
    return '${person.firstName}${person.lastName}'.trim().isNotEmpty;
  }
}
