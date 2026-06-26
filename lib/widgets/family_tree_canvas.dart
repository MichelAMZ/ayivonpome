import 'package:flutter/material.dart';

import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import 'person_card.dart';

class FamilyTreeCanvas extends StatelessWidget {
  const FamilyTreeCanvas({
    super.key,
    required this.data,
    required this.onOpenPerson,
    required this.authMode,
  });

  final FamilyTreeData data;
  final ValueChanged<Person> onOpenPerson;
  final AuthMode authMode;

  @override
  Widget build(BuildContext context) {
    final people = data.people;
    if (people.isEmpty) {
      return const Center(child: Icon(Icons.account_tree_outlined, size: 64));
    }
    final roots = people.where((person) => person.parents.isEmpty).toList();
    return InteractiveViewer(
      minScale: 0.35,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(800),
      child: SizedBox(
        width: 1200,
        height: 800,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _LinkPainter(data))),
            for (var i = 0; i < roots.length; i++)
              Positioned(
                left: 80 + i * 250,
                top: 80,
                child: PersonCard(
                  person: roots[i],
                  data: data,
                  authMode: authMode,
                  onOpen: () => onOpenPerson(roots[i]),
                ),
              ),
            for (final root in roots)
              for (var i = 0; i < root.children.length; i++)
                if (_person(root.children[i]) case final child?)
                  Positioned(
                    left: 130 + i * 250,
                    top: 280,
                    child: PersonCard(
                      person: child,
                      data: data,
                      authMode: authMode,
                      onOpen: () => onOpenPerson(child),
                    ),
                  ),
            for (var i = 0; i < people.where((p) => p.parents.isNotEmpty).length; i++)
              if (people.where((p) => p.parents.isNotEmpty).toList()[i]
                  case final child)
                Positioned(
                  left: 120 + i * 240,
                  top: 500,
                  child: PersonCard(
                    person: child,
                    data: data,
                    compact: true,
                    authMode: authMode,
                    onOpen: () => onOpenPerson(child),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Person? _person(String id) {
    for (final person in data.people) {
      if (person.id == id) {
        return person;
      }
    }
    return null;
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter(this.data);

  final FamilyTreeData data;

  @override
  void paint(Canvas canvas, Size size) {
    final accepted = Paint()
      ..color = Colors.green.shade500
      ..strokeWidth = 2;
    final pending = Paint()
      ..color = Colors.orange.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final link in data.familyLinks) {
      final paint = link.status == 'accepted' ? accepted : pending;
      canvas.drawLine(const Offset(180, 132), const Offset(260, 520), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => oldDelegate.data != data;
}
