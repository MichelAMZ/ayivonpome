import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/history_event.dart';
import '../models/important_place.dart';
import '../models/person.dart';
import '../models/person_duplicate_match.dart';
import '../models/person_privacy.dart';
import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import '../services/parent_auto_creation_service.dart';
import '../widgets/person_duplicate_dialog.dart';

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
  late final TextEditingController _birthLastName;
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
  late final TextEditingController _fatherFirstName;
  late final TextEditingController _fatherLastName;
  late final TextEditingController _fatherBirthDate;
  late final TextEditingController _fatherDeathDate;
  late final TextEditingController _fatherPhoto;
  late final TextEditingController _fatherCountry;
  late final TextEditingController _fatherCity;
  late final TextEditingController _fatherBirthPlace;
  late final TextEditingController _motherId;
  late final TextEditingController _motherFirstName;
  late final TextEditingController _motherBirthLastName;
  late final TextEditingController _motherMaritalLastName;
  late final TextEditingController _motherBirthDate;
  late final TextEditingController _motherDeathDate;
  late final TextEditingController _motherPhoto;
  late final TextEditingController _motherCountry;
  late final TextEditingController _motherCity;
  late final TextEditingController _motherBirthPlace;
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
  bool _linkParentsAsCouple = false;
  String _parentCoupleStatus = 'unknown';
  bool _isSaving = false;
  String? _draftPersonId;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _birthLastName = TextEditingController(text: p?.birthLastName ?? '');
    _gender = TextEditingController(text: p?.gender ?? '');
    _birthDate = TextEditingController(text: p?.birthDate ?? '');
    _birthPlace = TextEditingController(text: p?.birthPlace ?? '');
    _deathDate = TextEditingController(text: p?.deathDate ?? '');
    _deathPlace = TextEditingController(text: p?.deathPlace ?? '');
    _publicMapLocation = TextEditingController(
      text: p?.publicMapLocation ?? '',
    );
    _currentAddress = TextEditingController(text: p?.currentAddress ?? '');
    _burialPlace = TextEditingController(text: p?.burialPlace ?? '');
    _latitude = TextEditingController(text: p?.latitude?.toString() ?? '');
    _longitude = TextEditingController(text: p?.longitude?.toString() ?? '');
    final importantPlace = p?.importantPlaces.firstOrNull;
    _importantPlaceName = TextEditingController(
      text: importantPlace?.name ?? '',
    );
    _importantPlaceAddress = TextEditingController(
      text: importantPlace?.address ?? '',
    );
    _importantPlaceLatitude = TextEditingController(
      text: importantPlace?.latitude?.toString() ?? '',
    );
    _importantPlaceLongitude = TextEditingController(
      text: importantPlace?.longitude?.toString() ?? '',
    );
    _importantPlaceDescription = TextEditingController(
      text: importantPlace?.description ?? '',
    );
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
    _fatherFirstName = TextEditingController();
    _fatherLastName = TextEditingController();
    _fatherBirthDate = TextEditingController();
    _fatherDeathDate = TextEditingController();
    _fatherPhoto = TextEditingController();
    _fatherCountry = TextEditingController();
    _fatherCity = TextEditingController();
    _fatherBirthPlace = TextEditingController();
    _motherId = TextEditingController(text: p?.motherId ?? '');
    _motherFirstName = TextEditingController();
    _motherBirthLastName = TextEditingController();
    _motherMaritalLastName = TextEditingController();
    _motherBirthDate = TextEditingController();
    _motherDeathDate = TextEditingController();
    _motherPhoto = TextEditingController();
    _motherCountry = TextEditingController();
    _motherCity = TextEditingController();
    _motherBirthPlace = TextEditingController();
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
    _historyLatitude = TextEditingController(
      text: event?.latitude?.toString() ?? '',
    );
    _historyLongitude = TextEditingController(
      text: event?.longitude?.toString() ?? '',
    );
    _historyDescription = TextEditingController(text: event?.description ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _birthLastName,
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
      _fatherFirstName,
      _fatherLastName,
      _fatherBirthDate,
      _fatherDeathDate,
      _fatherPhoto,
      _fatherCountry,
      _fatherCity,
      _fatherBirthPlace,
      _motherId,
      _motherFirstName,
      _motherBirthLastName,
      _motherMaritalLastName,
      _motherBirthDate,
      _motherDeathDate,
      _motherPhoto,
      _motherCountry,
      _motherCity,
      _motherBirthPlace,
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
    final data = ref.watch(familyTreeProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? l10n.addPerson : l10n.edit),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_firstName, l10n.firstName, required: true),
            _field(_lastName, l10n.lastName, required: true),
            _field(_birthLastName, l10n.bornLastName),
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
                Expanded(
                  child: _field(_latitude, l10n.latitude, keyboard: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_longitude, l10n.longitude, keyboard: true),
                ),
              ],
            ),
            _field(_familyCode, l10n.familyBranch),
            const SizedBox(height: 12),
            Text(
              l10n.familyRelationships,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _parentSection(
              title: l10n.father,
              role: ParentRole.father,
              existingId: _fatherId,
              firstName: _fatherFirstName,
              lastName: _fatherLastName,
              birthLastName: null,
              maritalLastName: null,
              birthDate: _fatherBirthDate,
              deathDate: _fatherDeathDate,
              photo: _fatherPhoto,
              country: _fatherCountry,
              city: _fatherCity,
              birthPlace: _fatherBirthPlace,
              data: data,
            ),
            _parentSection(
              title: l10n.mother,
              role: ParentRole.mother,
              existingId: _motherId,
              firstName: _motherFirstName,
              lastName: null,
              birthLastName: _motherBirthLastName,
              maritalLastName: _motherMaritalLastName,
              birthDate: _motherBirthDate,
              deathDate: _motherDeathDate,
              photo: _motherPhoto,
              country: _motherCountry,
              city: _motherCity,
              birthPlace: _motherBirthPlace,
              data: data,
            ),
            SwitchListTile(
              value: _linkParentsAsCouple,
              title: const Text('Relier le père et la mère comme couple'),
              subtitle: const Text('Uniquement après confirmation.'),
              onChanged: (value) =>
                  setState(() => _linkParentsAsCouple = value),
            ),
            if (_linkParentsAsCouple)
              DropdownButtonFormField<String>(
                initialValue: _parentCoupleStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut de la relation des parents',
                ),
                items: const [
                  DropdownMenuItem(value: 'married', child: Text('Mariés')),
                  DropdownMenuItem(
                    value: 'partner',
                    child: Text('Union libre'),
                  ),
                  DropdownMenuItem(value: 'separated', child: Text('Séparés')),
                  DropdownMenuItem(value: 'divorced', child: Text('Divorcés')),
                  DropdownMenuItem(
                    value: 'unknown',
                    child: Text('Relation inconnue'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _parentCoupleStatus = value);
                  }
                },
              ),
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
                DropdownMenuItem(
                  value: 'civil',
                  child: Text(l10n.civilMarriage),
                ),
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
            Text(
              l10n.communication,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              value: _allowContact,
              title: Text(l10n.contact),
              subtitle: Text(
                _allowContact ? l10n.accepted : l10n.contactDisabled,
              ),
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
            Text(
              l10n.publicMode,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              value: _showMapInPublicMode,
              title: Text(l10n.showMapInPublicMode),
              onChanged: (value) =>
                  setState(() => _showMapInPublicMode = value),
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
                  child: _field(
                    _historyLatitude,
                    l10n.latitude,
                    keyboard: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _historyLongitude,
                    l10n.longitude,
                    keyboard: true,
                  ),
                ),
              ],
            ),
            _field(_historyDescription, l10n.notes, maxLines: 3),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Enregistrement...' : l10n.save),
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
        onChanged: (_) => setState(() {}),
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

  Widget _parentSection({
    required String title,
    required ParentRole role,
    required TextEditingController existingId,
    required TextEditingController firstName,
    required TextEditingController? lastName,
    required TextEditingController? birthLastName,
    required TextEditingController? maritalLastName,
    required TextEditingController birthDate,
    required TextEditingController deathDate,
    required TextEditingController photo,
    required TextEditingController country,
    required TextEditingController city,
    required TextEditingController birthPlace,
    required dynamic data,
  }) {
    final l10n = AppLocalizations.of(context);
    final draft = _draft(
      role,
      existingId: existingId.text,
      firstName: firstName.text,
      lastName: lastName?.text ?? '',
      birthLastName: birthLastName?.text ?? '',
      maritalLastName: maritalLastName?.text ?? '',
      birthDate: birthDate.text,
      deathDate: deathDate.text,
      photo: photo.text,
      country: country.text,
      city: city.text,
      birthPlace: birthPlace.text,
    );
    final matches = data == null || existingId.text.trim().isNotEmpty
        ? const <ParentMatch>[]
        : ref.read(parentAutoCreationServiceProvider).search(data, draft);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _field(existingId, 'Membre existant dans l’arbre'),
              _field(firstName, l10n.firstName),
              if (lastName != null) _field(lastName, l10n.lastName),
              if (birthLastName != null)
                _field(birthLastName, l10n.bornLastName),
              if (maritalLastName != null)
                _field(maritalLastName, 'Nom marital facultatif'),
              Row(
                children: [
                  Expanded(child: _field(birthDate, l10n.birthDate)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(deathDate, l10n.deathDate)),
                ],
              ),
              _field(birthPlace, l10n.birthPlace),
              Row(
                children: [
                  Expanded(child: _field(country, 'Pays')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(city, 'Ville')),
                ],
              ),
              _field(photo, 'Photo'),
              if (matches.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Membres similaires',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                ...matches
                    .take(3)
                    .map(
                      (match) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: match.person.photo.isEmpty
                              ? null
                              : NetworkImage(match.person.photo),
                          child: match.person.photo.isEmpty
                              ? Text(_initials(match.person))
                              : null,
                        ),
                        title: Text(match.person.fullName),
                        subtitle: Text(
                          [
                            match.person.gender,
                            match.person.birthDate,
                            match.person.currentCity.isNotEmpty
                                ? match.person.currentCity
                                : match.person.currentCountry,
                            match.person.familyCode,
                          ].where((item) => item.trim().isNotEmpty).join(' · '),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            setState(() {
                              existingId.text = match.person.id;
                              firstName.clear();
                              lastName?.clear();
                              birthLastName?.clear();
                              maritalLastName?.clear();
                            });
                          },
                          child: const Text('Sélectionner'),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
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

  ParentDraft _draft(
    ParentRole role, {
    required String existingId,
    required String firstName,
    required String lastName,
    required String birthLastName,
    required String maritalLastName,
    required String birthDate,
    required String deathDate,
    required String photo,
    required String country,
    required String city,
    required String birthPlace,
  }) {
    return ParentDraft(
      role: role,
      existingPersonId: existingId.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      birthLastName: birthLastName.trim(),
      maritalLastName: maritalLastName.trim(),
      birthDate: birthDate.trim(),
      deathDate: deathDate.trim(),
      photo: photo.trim(),
      country: country.trim(),
      city: city.trim(),
      birthPlace: birthPlace.trim(),
    );
  }

  String _initials(Person person) {
    final first = person.firstName.trim().isEmpty
        ? ''
        : person.firstName.trim()[0];
    final last = person.lastName.trim().isEmpty
        ? ''
        : person.lastName.trim()[0];
    final value = '$first$last'.trim();
    return value.isEmpty ? '?' : value.toUpperCase();
  }

  Future<bool> _confirmParentCreation(ParentDraft draft, Person child) async {
    if (!draft.createsNewPerson) return true;
    final data = ref.read(familyTreeProvider).value;
    final matches = data == null
        ? const <ParentMatch>[]
        : ref.read(parentAutoCreationServiceProvider).search(data, draft);
    final hasStrongMatch = matches.any(
      (match) => match.level == ParentSimilarityLevel.strong,
    );
    final roleLabel = draft.role == ParentRole.father ? 'père' : 'mère';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau parent détecté'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matches.isEmpty
                    ? 'Aucun membre correspondant à ${draft.displayName} n’a été trouvé dans l’arbre. Voulez-vous créer cette personne et la définir comme $roleLabel de ${child.fullName} ?'
                    : 'Un ou plusieurs membres similaires existent déjà. Vérifiez qu’il ne s’agit pas de la même personne avant de créer un nouveau membre.',
              ),
              if (matches.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...matches
                    .take(4)
                    .map(
                      (match) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(match.person.fullName),
                        subtitle: Text(
                          '${match.person.gender} · ${match.person.birthDate} · ${match.level.name}',
                        ),
                      ),
                    ),
              ],
              if (hasStrongMatch) ...[
                const SizedBox(height: 8),
                const Text(
                  'Correspondance forte détectée : confirmez seulement s’il s’agit bien d’une autre personne.',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'search'),
            child: const Text('Rechercher à nouveau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'create'),
            child: Text(
              hasStrongMatch ? 'Créer quand même' : 'Créer le parent',
            ),
          ),
        ],
      ),
    );
    return result == 'create';
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    final id =
        widget.person?.id ??
        (_draftPersonId ??= 'p${DateTime.now().microsecondsSinceEpoch}');
    final history =
        _historyTitle.text.trim().isEmpty &&
            _historyDate.text.trim().isEmpty &&
            _historyDescription.text.trim().isEmpty
        ? <HistoryEvent>[]
        : [
            HistoryEvent(
              id:
                  widget.person?.history.firstOrNull?.id ??
                  'h${DateTime.now().microsecondsSinceEpoch}',
              date: _historyDate.text.trim(),
              title: _historyTitle.text.trim(),
              description: _historyDescription.text.trim(),
              place: _historyPlace.text.trim(),
              latitude: _parseDouble(_historyLatitude.text),
              longitude: _parseDouble(_historyLongitude.text),
            ),
          ];
    final importantPlaces =
        _importantPlaceName.text.trim().isEmpty &&
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
      birthLastName: _birthLastName.text.trim(),
      originalLastName: widget.person?.originalLastName ?? '',
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
    final fatherDraft = _draft(
      ParentRole.father,
      existingId: _fatherId.text,
      firstName: _fatherFirstName.text,
      lastName: _fatherLastName.text,
      birthLastName: '',
      maritalLastName: '',
      birthDate: _fatherBirthDate.text,
      deathDate: _fatherDeathDate.text,
      photo: _fatherPhoto.text,
      country: _fatherCountry.text,
      city: _fatherCity.text,
      birthPlace: _fatherBirthPlace.text,
    );
    final motherDraft = _draft(
      ParentRole.mother,
      existingId: _motherId.text,
      firstName: _motherFirstName.text,
      lastName: '',
      birthLastName: _motherBirthLastName.text,
      maritalLastName: _motherMaritalLastName.text,
      birthDate: _motherBirthDate.text,
      deathDate: _motherDeathDate.text,
      photo: _motherPhoto.text,
      country: _motherCountry.text,
      city: _motherCity.text,
      birthPlace: _motherBirthPlace.text,
    );
    if (person.fatherId == person.id ||
        person.motherId == person.id ||
        person.spouseIds.contains(person.id) ||
        person.childrenIds.contains(person.id) ||
        person.parents.contains(person.id) ||
        person.spouses.contains(person.id) ||
        person.children.contains(person.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRelationship)));
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    try {
      if (!await _confirmParentCreation(fatherDraft, person)) return;
      if (!await _confirmParentCreation(motherDraft, person)) return;
      final duplicateDecision = await _resolveDuplicateBeforeSave(person);
      if (duplicateDecision == PersonDuplicateDecision.cancel) return;
      if (duplicateDecision == PersonDuplicateDecision.openExisting) {
        final existing = _firstDuplicateFor(person);
        if (existing != null && mounted) {
          _loadExistingPerson(existing.person);
          _showSaveSnackBar(
            color: const Color(0xFF4F6F2A),
            icon: Icons.edit_outlined,
            message:
                'La fiche existante a été chargée. Vérifiez puis enregistrez.',
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }
      final result = await ref
          .read(familyTreeProvider.notifier)
          .upsertPersonWithParents(
            person,
            widget.person == null ? 'create_person' : 'edit_person',
            fatherDraft: fatherDraft.hasIdentity ? fatherDraft : null,
            motherDraft: motherDraft.hasIdentity ? motherDraft : null,
            linkParentsAsCouple: _linkParentsAsCouple,
            parentCoupleStatus: _parentCoupleStatus,
            allowDuplicate:
                duplicateDecision == PersonDuplicateDecision.saveAnyway,
          );
      if (!mounted) return;
      if (result.isFirestoreConfirmed) {
        _showSaveSnackBar(
          color: Colors.green,
          icon: Icons.check_circle,
          message:
              'Enregistrement effectué avec succès dans la base de données.',
          duration: const Duration(seconds: 3),
        );
        Navigator.pop(context);
        return;
      }
      if (result.isLocalPending) {
        _showSaveSnackBar(
          color: Colors.orange.shade800,
          icon: Icons.sync_problem_outlined,
          message:
              'Modification enregistrée localement. Synchronisation en attente.',
          duration: const Duration(seconds: 5),
        );
        return;
      }
      _showSaveSnackBar(
        color: Colors.red,
        icon: Icons.error,
        message: _databaseErrorMessage(result.lastError),
        duration: const Duration(seconds: 5),
      );
    } on StateError catch (error) {
      if (mounted) {
        _showSaveSnackBar(
          color: Colors.red,
          icon: Icons.error,
          message: error.message == 'duplicate_person'
              ? l10n.duplicatePerson
              : 'Échec de l’enregistrement dans la base de données.',
          duration: const Duration(seconds: 5),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSaveSnackBar(
        color: Colors.red,
        icon: Icons.error,
        message:
            'Enregistrement impossible. Vos modifications ont été conservées.',
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<PersonDuplicateDecision> _resolveDuplicateBeforeSave(
    Person person,
  ) async {
    final matches = _duplicateMatchesFor(person);
    if (matches.isEmpty) return PersonDuplicateDecision.saveAnyway;
    final decision = await showDialog<PersonDuplicateDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PersonDuplicateDialog(matches: matches),
    );
    return decision ?? PersonDuplicateDecision.cancel;
  }

  PersonDuplicateMatch? _firstDuplicateFor(Person person) {
    final matches = _duplicateMatchesFor(person);
    return matches.isEmpty ? null : matches.first;
  }

  List<PersonDuplicateMatch> _duplicateMatchesFor(Person person) {
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return const [];
    return ref
        .read(personDuplicateServiceProvider)
        .findDuplicates(draft: person, people: data.people);
  }

  void _loadExistingPerson(Person person) {
    setState(() {
      _draftPersonId = person.id;
      _firstName.text = person.firstName;
      _lastName.text = person.lastName;
      _birthLastName.text = person.birthLastName;
      _gender.text = person.gender;
      _birthDate.text = person.birthDate;
      _birthPlace.text = person.birthPlace;
      _deathDate.text = person.deathDate;
      _deathPlace.text = person.deathPlace;
      _publicMapLocation.text = person.publicMapLocation;
      _currentAddress.text = person.currentAddress;
      _burialPlace.text = person.burialPlace;
      _latitude.text = person.latitude?.toString() ?? '';
      _longitude.text = person.longitude?.toString() ?? '';
      _email.text = person.email;
      _phoneNumber.text = person.phoneNumber;
      _whatsappNumber.text = person.whatsappNumber;
      _allowContact = person.allowContact;
      _emailVisibility = person.emailVisibility;
      _phoneVisibility = person.phoneVisibility;
      _whatsappVisibility = person.whatsappVisibility;
      _showMapInPublicMode = person.privacy.showMapInPublicMode;
      _showBirthPlaceInPublicMode = person.privacy.showBirthPlaceInPublicMode;
      _showCurrentAddressInPublicMode =
          person.privacy.showCurrentAddressInPublicMode;
      _showContactInPublicMode = person.privacy.showContactInPublicMode;
      _showHistoryInPublicMode = person.privacy.showHistoryInPublicMode;
      _familyCode.text = person.familyCode;
      _fatherId.text = person.fatherId;
      _motherId.text = person.motherId;
      _spouseIds.text = person.spouseIds.join(', ');
      _childrenIds.text = person.childrenIds.join(', ');
      _marriageType = person.marriageType;
      _parents.text = person.parents.join(', ');
      _spouses.text = person.spouses.join(', ');
      _children.text = person.children.join(', ');
      _notes.text = person.notes;
    });
  }

  void _showSaveSnackBar({
    required Color color,
    required IconData icon,
    required String message,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _databaseErrorMessage(String error) =>
      'Enregistrement impossible. Vos modifications ont été conservées.';

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
