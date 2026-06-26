import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/history_event.dart';
import '../models/important_place.dart';
import '../models/person.dart';
import '../models/person_privacy.dart';
import '../providers/family_tree_provider.dart';

class PersonEditScreen extends ConsumerStatefulWidget {
  const PersonEditScreen({super.key, this.person});

  final Person? person;

  @override
  ConsumerState<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends ConsumerState<PersonEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _gender;
  late final TextEditingController _birthDate;
  late final TextEditingController _birthPlace;
  late final TextEditingController _deathDate;
  late final TextEditingController _deathPlace;
  late final TextEditingController _publicMapLocation;
  late final TextEditingController _currentAddress;
  late final TextEditingController _burialPlace;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _importantPlaceName;
  late final TextEditingController _importantPlaceAddress;
  late final TextEditingController _importantPlaceLatitude;
  late final TextEditingController _importantPlaceLongitude;
  late final TextEditingController _importantPlaceDescription;
  late final TextEditingController _email;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _whatsappNumber;
  late bool _allowContact;
  late String _emailVisibility;
  late String _phoneVisibility;
  late String _whatsappVisibility;
  late bool _showMapInPublicMode;
  late bool _showBirthPlaceInPublicMode;
  late bool _showCurrentAddressInPublicMode;
  late bool _showContactInPublicMode;
  late bool _showHistoryInPublicMode;
  late final TextEditingController _familyCode;
  late final TextEditingController _fatherId;
  late final TextEditingController _motherId;
  late final TextEditingController _spouseIds;
  late final TextEditingController _childrenIds;
  late String _marriageType;
  late final TextEditingController _parents;
  late final TextEditingController _spouses;
  late final TextEditingController _children;
  late final TextEditingController _notes;
  late final TextEditingController _historyTitle;
  late final TextEditingController _historyDate;
  late final TextEditingController _historyPlace;
  late final TextEditingController _historyLatitude;
  late final TextEditingController _historyLongitude;
  late final TextEditingController _historyDescription;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _gender = TextEditingController(text: p?.gender ?? '');
    _birthDate = TextEditingController(text: p?.birthDate ?? '');
    _birthPlace = TextEditingController(text: p?.birthPlace ?? '');
    _deathDate = TextEditingController(text: p?.deathDate ?? '');
    _deathPlace = TextEditingController(text: p?.deathPlace ?? '');
    _publicMapLocation = TextEditingController(text: p?.publicMapLocation ?? '');
    _currentAddress = TextEditingController(text: p?.currentAddress ?? '');
    _burialPlace = TextEditingController(text: p?.burialPlace ?? '');
    _latitude = TextEditingController(text: p?.latitude?.toString() ?? '');
    _longitude = TextEditingController(text: p?.longitude?.toString() ?? '');
    final importantPlace = p?.importantPlaces.firstOrNull;
    _importantPlaceName = TextEditingController(text: importantPlace?.name ?? '');
    _importantPlaceAddress =
        TextEditingController(text: importantPlace?.address ?? '');
    _importantPlaceLatitude =
        TextEditingController(text: importantPlace?.latitude?.toString() ?? '');
    _importantPlaceLongitude =
        TextEditingController(text: importantPlace?.longitude?.toString() ?? '');
    _importantPlaceDescription =
        TextEditingController(text: importantPlace?.description ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _phoneNumber = TextEditingController(text: p?.phoneNumber ?? '');
    _whatsappNumber = TextEditingController(text: p?.whatsappNumber ?? '');
    _allowContact = p?.allowContact ?? true;
    _emailVisibility = p?.emailVisibility ?? 'familyOnly';
    _phoneVisibility = p?.phoneVisibility ?? 'familyOnly';
    _whatsappVisibility = p?.whatsappVisibility ?? 'familyOnly';
    _showMapInPublicMode = p?.privacy.showMapInPublicMode ?? true;
    _showBirthPlaceInPublicMode =
        p?.privacy.showBirthPlaceInPublicMode ?? false;
    _showCurrentAddressInPublicMode =
        p?.privacy.showCurrentAddressInPublicMode ?? false;
    _showContactInPublicMode = p?.privacy.showContactInPublicMode ?? false;
    _showHistoryInPublicMode = p?.privacy.showHistoryInPublicMode ?? false;
    _familyCode = TextEditingController(text: p?.familyCode ?? 'AMOUZOU2026');
    _fatherId = TextEditingController(text: p?.fatherId ?? '');
    _motherId = TextEditingController(text: p?.motherId ?? '');
    _spouseIds = TextEditingController(text: p?.spouseIds.join(', ') ?? '');
    _childrenIds = TextEditingController(text: p?.childrenIds.join(', ') ?? '');
    _marriageType = p?.marriageType ?? 'unknown';
    _parents = TextEditingController(text: p?.parents.join(', ') ?? '');
    _spouses = TextEditingController(text: p?.spouses.join(', ') ?? '');
    _children = TextEditingController(text: p?.children.join(', ') ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    final event = p?.history.firstOrNull;
    _historyTitle = TextEditingController(text: event?.title ?? '');
    _historyDate = TextEditingController(text: event?.date ?? '');
    _historyPlace = TextEditingController(text: event?.place ?? '');
    _historyLatitude =
        TextEditingController(text: event?.latitude?.toString() ?? '');
    _historyLongitude =
        TextEditingController(text: event?.longitude?.toString() ?? '');
    _historyDescription = TextEditingController(text: event?.description ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _gender,
      _birthDate,
      _birthPlace,
      _deathDate,
      _deathPlace,
      _publicMapLocation,
      _currentAddress,
      _burialPlace,
      _latitude,
      _longitude,
      _importantPlaceName,
      _importantPlaceAddress,
      _importantPlaceLatitude,
      _importantPlaceLongitude,
      _importantPlaceDescription,
      _email,
      _phoneNumber,
      _whatsappNumber,
      _familyCode,
      _fatherId,
      _motherId,
      _spouseIds,
      _childrenIds,
      _parents,
      _spouses,
      _children,
      _notes,
      _historyTitle,
      _historyDate,
      _historyPlace,
      _historyLatitude,
      _historyLongitude,
      _historyDescription,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.person == null ? l10n.addPerson : l10n.edit)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_firstName, l10n.firstName, required: true),
            _field(_lastName, l10n.lastName, required: true),
            _field(_gender, l10n.gender),
            _field(_birthDate, l10n.birthDate),
            _field(_birthPlace, l10n.birthPlace),
            _field(_deathDate, l10n.deathDate),
            _field(_deathPlace, l10n.deathPlace),
            _field(_publicMapLocation, l10n.publicMapLocation),
            _field(_currentAddress, l10n.currentAddress),
            _field(_burialPlace, l10n.burialPlace),
            Row(
              children: [
                Expanded(child: _field(_latitude, l10n.latitude, keyboard: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_longitude, l10n.longitude, keyboard: true)),
              ],
            ),
            _field(_familyCode, l10n.familyBranch),
            const SizedBox(height: 12),
            Text(
              l10n.familyRelationships,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _field(_fatherId, l10n.father),
            _field(_motherId, l10n.mother),
            _field(_spouseIds, l10n.spouses),
            _field(_childrenIds, l10n.children),
            DropdownButtonFormField<String>(
              initialValue: _marriageType,
              decoration: InputDecoration(labelText: l10n.marriageType),
              items: [
                DropdownMenuItem(value: 'monogamy', child: Text(l10n.monogamy)),
                DropdownMenuItem(value: 'polygamy', child: Text(l10n.polygamy)),
                DropdownMenuItem(
                  value: 'customary',
                  child: Text(l10n.customaryMarriage),
                ),
                DropdownMenuItem(value: 'civil', child: Text(l10n.civilMarriage)),
                DropdownMenuItem(
                  value: 'religious',
                  child: Text(l10n.religiousMarriage),
                ),
                DropdownMenuItem(value: 'unknown', child: Text(l10n.unknown)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _marriageType = value);
              },
            ),
            const SizedBox(height: 12),
            _field(_parents, l10n.parents),
            _field(_spouses, l10n.spouses),
            _field(_children, l10n.children),
            _field(_notes, l10n.notes, maxLines: 3),
            const SizedBox(height: 12),
            Text(l10n.communication, style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              value: _allowContact,
              title: Text(l10n.contact),
              subtitle: Text(_allowContact ? l10n.accepted : l10n.contactDisabled),
              onChanged: (value) => setState(() => _allowContact = value),
            ),
            _field(_email, l10n.email),
            _visibilitySelector(
              value: _emailVisibility,
              label: l10n.copyEmail,
              onChanged: (value) => setState(() => _emailVisibility = value),
            ),
            _field(_phoneNumber, l10n.phoneNumber),
            _visibilitySelector(
              value: _phoneVisibility,
              label: l10n.call,
              onChanged: (value) => setState(() => _phoneVisibility = value),
            ),
            _field(_whatsappNumber, l10n.whatsappNumber),
            _visibilitySelector(
              value: _whatsappVisibility,
              label: l10n.sendWhatsapp,
              onChanged: (value) => setState(() => _whatsappVisibility = value),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.importantPlaces,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _field(_importantPlaceName, l10n.details),
            _field(_importantPlaceAddress, l10n.currentAddress),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _importantPlaceLatitude,
                    l10n.latitude,
                    keyboard: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _importantPlaceLongitude,
                    l10n.longitude,
                    keyboard: true,
                  ),
                ),
              ],
            ),
            _field(_importantPlaceDescription, l10n.notes, maxLines: 2),
            const SizedBox(height: 12),
            Text(l10n.publicMode, style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              value: _showMapInPublicMode,
              title: Text(l10n.showMapInPublicMode),
              onChanged: (value) => setState(() => _showMapInPublicMode = value),
            ),
            SwitchListTile(
              value: _showBirthPlaceInPublicMode,
              title: Text(l10n.showBirthPlaceInPublicMode),
              onChanged: (value) =>
                  setState(() => _showBirthPlaceInPublicMode = value),
            ),
            SwitchListTile(
              value: _showCurrentAddressInPublicMode,
              title: Text(l10n.showCurrentAddressInPublicMode),
              onChanged: (value) =>
                  setState(() => _showCurrentAddressInPublicMode = value),
            ),
            SwitchListTile(
              value: _showContactInPublicMode,
              title: Text(l10n.showContactInPublicMode),
              onChanged: (value) =>
                  setState(() => _showContactInPublicMode = value),
            ),
            SwitchListTile(
              value: _showHistoryInPublicMode,
              title: Text(l10n.showHistoryInPublicMode),
              onChanged: (value) =>
                  setState(() => _showHistoryInPublicMode = value),
            ),
            const SizedBox(height: 12),
            Text(l10n.history, style: Theme.of(context).textTheme.titleLarge),
            _field(_historyDate, l10n.birthDate),
            _field(_historyTitle, l10n.history),
            _field(_historyPlace, l10n.birthPlace),
            Row(
              children: [
                Expanded(
                  child: _field(_historyLatitude, l10n.latitude, keyboard: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_historyLongitude, l10n.longitude, keyboard: true),
                ),
              ],
            ),
            _field(_historyDescription, l10n.notes, maxLines: 3),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    bool keyboard = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? l10n.requiredField
                : null
            : null,
      ),
    );
  }

  Widget _visibilitySelector({
    required String value,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(value: 'public', child: Text(l10n.public)),
          DropdownMenuItem(value: 'familyOnly', child: Text(l10n.familyOnly)),
          DropdownMenuItem(value: 'private', child: Text(l10n.private)),
        ],
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final id = widget.person?.id ?? 'p${DateTime.now().microsecondsSinceEpoch}';
    final history = _historyTitle.text.trim().isEmpty &&
            _historyDate.text.trim().isEmpty &&
            _historyDescription.text.trim().isEmpty
        ? <HistoryEvent>[]
        : [
            HistoryEvent(
              id: widget.person?.history.firstOrNull?.id ??
                  'h${DateTime.now().microsecondsSinceEpoch}',
              date: _historyDate.text.trim(),
              title: _historyTitle.text.trim(),
              description: _historyDescription.text.trim(),
              place: _historyPlace.text.trim(),
              latitude: _parseDouble(_historyLatitude.text),
              longitude: _parseDouble(_historyLongitude.text),
            ),
          ];
    final importantPlaces = _importantPlaceName.text.trim().isEmpty &&
            _importantPlaceAddress.text.trim().isEmpty
        ? <ImportantPlace>[]
        : [
            ImportantPlace(
              name: _importantPlaceName.text.trim(),
              address: _importantPlaceAddress.text.trim(),
              latitude: _parseDouble(_importantPlaceLatitude.text),
              longitude: _parseDouble(_importantPlaceLongitude.text),
              description: _importantPlaceDescription.text.trim(),
            ),
          ];
    final person = Person(
      id: id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      gender: _gender.text.trim(),
      birthDate: _birthDate.text.trim(),
      birthPlace: _birthPlace.text.trim(),
      deathDate: _deathDate.text.trim(),
      deathPlace: _deathPlace.text.trim(),
      publicMapLocation: _publicMapLocation.text.trim(),
      currentAddress: _currentAddress.text.trim(),
      burialPlace: _burialPlace.text.trim(),
      latitude: _parseDouble(_latitude.text),
      longitude: _parseDouble(_longitude.text),
      importantPlaces: importantPlaces,
      email: _email.text.trim(),
      phoneNumber: _phoneNumber.text.trim(),
      whatsappNumber: _whatsappNumber.text.trim(),
      allowContact: _allowContact,
      emailVisibility: _emailVisibility,
      phoneVisibility: _phoneVisibility,
      whatsappVisibility: _whatsappVisibility,
      privacy: PersonPrivacy(
        showMapInPublicMode: _showMapInPublicMode,
        showBirthPlaceInPublicMode: _showBirthPlaceInPublicMode,
        showCurrentAddressInPublicMode: _showCurrentAddressInPublicMode,
        showContactInPublicMode: _showContactInPublicMode,
        showHistoryInPublicMode: _showHistoryInPublicMode,
      ),
      familyCode: _familyCode.text.trim(),
      fatherId: _fatherId.text.trim(),
      motherId: _motherId.text.trim(),
      spouseIds: _split(_spouseIds.text),
      childrenIds: _split(_childrenIds.text),
      marriageType: _marriageType,
      parents: _split(_parents.text),
      spouses: _split(_spouses.text),
      children: _split(_children.text),
      history: history,
      notes: _notes.text.trim(),
    );
    if (person.fatherId == person.id ||
        person.motherId == person.id ||
        person.spouseIds.contains(person.id) ||
        person.childrenIds.contains(person.id) ||
        person.parents.contains(person.id) ||
        person.spouses.contains(person.id) ||
        person.children.contains(person.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidRelationship)),
      );
      return;
    }
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .upsertPerson(person, widget.person == null ? 'create_person' : 'edit_person');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.duplicatePerson)),
        );
      }
    }
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}
