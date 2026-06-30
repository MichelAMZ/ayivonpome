import 'package:flutter/material.dart';

import '../models/person.dart';

class FilterResultCard extends StatelessWidget {
  const FilterResultCard({
    super.key,
    required this.person,
    required this.onTap,
  });

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = [
      person.currentCity,
      person.currentCountry,
      person.currentAddress,
      person.birthPlace,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card(
      elevation: 0,
      child: ListTile(
        dense: true,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF2DD),
          child: Icon(Icons.person_search_outlined, color: Color(0xFF5F7F2B)),
        ),
        title: Text(person.fullName),
        subtitle: location.isEmpty ? null : Text(location),
        trailing: const Icon(Icons.center_focus_strong_outlined),
        onTap: onTap,
      ),
    );
  }
}
