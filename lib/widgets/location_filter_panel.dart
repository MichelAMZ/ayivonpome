import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/location_filter.dart';
import '../models/person.dart';
import '../providers/tree_filter_provider.dart';
import 'filter_result_card.dart';

class LocationFilterPanel extends ConsumerStatefulWidget {
  const LocationFilterPanel({
    super.key,
    required this.people,
    required this.results,
    required this.onCenterOnPerson,
  });

  final List<Person> people;
  final List<Person> results;
  final ValueChanged<Person> onCenterOnPerson;

  @override
  ConsumerState<LocationFilterPanel> createState() =>
      _LocationFilterPanelState();
}

class _LocationFilterPanelState extends ConsumerState<LocationFilterPanel> {
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _currentAddress;
  late final TextEditingController _birthLocation;
  late final TextEditingController _deathLocation;
  late final TextEditingController _burialLocation;
  late final TextEditingController _radiusAddress;
  late int? _generation;
  late bool _showOnlyResults;
  late bool _highlightResults;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(treeFilterProvider);
    _country = TextEditingController(text: filter.country);
    _city = TextEditingController(text: filter.city);
    _region = TextEditingController(text: filter.region);
    _currentAddress = TextEditingController(text: filter.currentAddress);
    _birthLocation = TextEditingController(text: filter.birthLocation);
    _deathLocation = TextEditingController(text: filter.deathLocation);
    _burialLocation = TextEditingController(text: filter.burialLocation);
    _radiusAddress = TextEditingController(text: filter.radiusAddress);
    _generation = filter.generation;
    _showOnlyResults = filter.showOnlyResults;
    _highlightResults = filter.highlightResults;
  }

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    _region.dispose();
    _currentAddress.dispose();
    _birthLocation.dispose();
    _deathLocation.dispose();
    _burialLocation.dispose();
    _radiusAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final generations =
        widget.people
            .map((person) => person.generation)
            .where((generation) => generation > 0)
            .toSet()
            .toList()
          ..sort();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.filterByLocation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: Text(l10n.clearFilters),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _field(_country, l10n.country, Icons.public_outlined),
            _field(_city, l10n.city, Icons.location_city_outlined),
            _field(_region, l10n.region, Icons.map_outlined),
            _field(
              _currentAddress,
              l10n.currentAddress,
              Icons.home_work_outlined,
            ),
            _field(_birthLocation, l10n.birthLocation, Icons.child_care),
            _field(_deathLocation, l10n.deathLocation, Icons.event_busy),
            _field(_burialLocation, l10n.burialLocation, Icons.place_outlined),
            _field(
              _radiusAddress,
              l10n.radiusAroundAddress,
              Icons.radar_outlined,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<int?>(
                initialValue: _generation,
                decoration: InputDecoration(
                  labelText: l10n.generation,
                  prefixIcon: const Icon(Icons.family_restroom_outlined),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.allGenerations),
                  ),
                  ...generations.map(
                    (generation) => DropdownMenuItem<int?>(
                      value: generation,
                      child: Text('${l10n.generation} $generation'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _generation = value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showOnlyResults,
              title: Text(l10n.showOnlyResults),
              onChanged: (value) => setState(() => _showOnlyResults = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _highlightResults,
              title: Text(l10n.highlightResults),
              onChanged: (value) => setState(() => _highlightResults = value),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.tune_outlined),
              label: Text(l10n.filterByLocation),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.membersFound(widget.results.length),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.results.isEmpty)
              Text(
                l10n.noResults,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...widget.results
                  .take(30)
                  .map(
                    (person) => FilterResultCard(
                      person: person,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onCenterOnPerson(person);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  void _apply() {
    ref
        .read(treeFilterProvider.notifier)
        .setFilter(
          LocationFilter(
            country: _country.text.trim(),
            city: _city.text.trim(),
            region: _region.text.trim(),
            currentAddress: _currentAddress.text.trim(),
            birthLocation: _birthLocation.text.trim(),
            deathLocation: _deathLocation.text.trim(),
            burialLocation: _burialLocation.text.trim(),
            radiusAddress: _radiusAddress.text.trim(),
            generation: _generation,
            showOnlyResults: _showOnlyResults,
            highlightResults: _highlightResults,
          ),
        );
    Navigator.pop(context);
  }

  void _clear() {
    ref.read(treeFilterProvider.notifier).clearFilters();
    Navigator.pop(context);
  }
}
