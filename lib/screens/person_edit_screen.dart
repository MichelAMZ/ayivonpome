import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/history_event.dart';
import '../models/important_place.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../models/person_duplicate_match.dart';
import '../models/person_privacy.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/parent_auto_creation_service.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/person_duplicate_dialog.dart';
import 'person_edit_progress.dart';

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
  late bool _photoVisible;
  late bool _genderVisible;
  late bool _birthLastNameVisible;
  late bool _birthDateVisible;
  late bool _deathDateVisible;
  late bool _deathPlaceVisible;
  late bool _burialPlaceVisible;
  late bool _privateCoordinatesVisible;
  late bool _familyBranchVisible;
  late bool _familyRelationsVisible;
  late bool _emailVisible;
  late bool _phoneVisible;
  late bool _whatsappVisible;
  late bool _notesVisible;
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
  final List<_PendingUnionDraft> _pendingUnions = [];
  int _activeStep = 0;
  _RelationsTab _relationsTab = _RelationsTab.parents;
  _ParentInputMode? _fatherMode;
  _ParentInputMode? _motherMode;
  DateTime? _lastDraftSavedAt;
  bool _hasUnsavedChanges = false;
  bool _showRequiredErrors = false;
  final Set<String> _highlightedRequiredFieldIds = {};
  bool _didHydrateExistingRelations = false;

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
    _photoVisible = p?.privacy.photoVisible ?? true;
    _genderVisible = p?.privacy.genderVisible ?? true;
    _birthLastNameVisible = p?.privacy.birthLastNameVisible ?? true;
    _birthDateVisible = p?.privacy.birthDateVisible ?? true;
    _deathDateVisible = p?.privacy.deathDateVisible ?? true;
    _deathPlaceVisible = p?.privacy.deathPlaceVisible ?? false;
    _burialPlaceVisible = p?.privacy.burialPlaceVisible ?? false;
    _privateCoordinatesVisible = p?.privacy.privateCoordinatesVisible ?? false;
    _familyBranchVisible = p?.privacy.familyBranchVisible ?? true;
    _familyRelationsVisible = p?.privacy.familyRelationsVisible ?? false;
    _emailVisible = p?.privacy.emailVisible ?? false;
    _phoneVisible = p?.privacy.phoneVisible ?? false;
    _whatsappVisible = p?.privacy.whatsappVisible ?? false;
    _notesVisible = p?.privacy.notesVisible ?? false;
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
    _spouseIds = TextEditingController(
      text: p == null ? '' : _joinUnique([...p.spouseIds, ...p.spouses]),
    );
    _childrenIds = TextEditingController(
      text: p == null ? '' : _joinUnique([...p.childrenIds, ...p.children]),
    );
    _marriageType = p?.marriageType ?? 'unknown';
    _parents = TextEditingController(
      text: p == null
          ? ''
          : _joinUnique([p.fatherId, p.motherId, ...p.parents]),
    );
    _spouses = TextEditingController(
      text: p == null ? '' : _joinUnique([...p.spouses, ...p.spouseIds]),
    );
    _children = TextEditingController(
      text: p == null ? '' : _joinUnique([...p.children, ...p.childrenIds]),
    );
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
    _fatherMode = _fatherId.text.trim().isEmpty
        ? null
        : _ParentInputMode.existing;
    _motherMode = _motherId.text.trim().isEmpty
        ? null
        : _ParentInputMode.existing;
  }

  @override
  void didUpdateWidget(covariant PersonEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person?.id != widget.person?.id && widget.person != null) {
      _loadExistingPerson(widget.person!);
      _didHydrateExistingRelations = false;
    }
  }

  List<String> get _stepTitles {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.identity,
      l10n.family,
      l10n.relationships,
      l10n.communication,
      l10n.places,
      l10n.privacy,
      l10n.history,
    ];
  }

  static String _joinUnique(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(', ');
  }

  void _hydrateExistingRelationDetails(FamilyTreeData data) {
    final person = widget.person;
    if (person == null) return;
    final relationService = ref.read(familyRelationServiceProvider);
    final father = relationService.fatherOf(data, person);
    final mother = relationService.motherOf(data, person);
    final spouses = relationService.spousesOf(data, person);
    final children = relationService.childrenOf(data, person);
    if (father != null && _fatherId.text.trim().isEmpty) {
      _fatherId.text = father.id;
      _fatherMode = _ParentInputMode.existing;
    }
    if (mother != null && _motherId.text.trim().isEmpty) {
      _motherId.text = mother.id;
      _motherMode = _ParentInputMode.existing;
    }
    _parents.text = _joinUnique([
      if (father != null) father.id,
      if (mother != null) mother.id,
      person.fatherId,
      person.motherId,
      ...person.parents,
    ]);
    _spouseIds.text = _joinUnique([
      ..._split(_spouseIds.text),
      ...person.spouseIds,
      ...person.spouses,
      ...spouses.map((item) => item.id),
    ]);
    _spouses.text = _joinUnique([
      ..._split(_spouses.text),
      ...person.spouses,
      ...person.spouseIds,
      ...spouses.map((item) => item.id),
    ]);
    _childrenIds.text = _joinUnique([
      ..._split(_childrenIds.text),
      ...person.childrenIds,
      ...person.children,
      ...children.map((item) => item.id),
    ]);
    _children.text = _joinUnique([
      ..._split(_children.text),
      ...person.children,
      ...person.childrenIds,
      ...children.map((item) => item.id),
    ]);
    if (father != null) {
      _fillParentControllersFromPerson(
        source: father,
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
      );
    }
    if (mother != null) {
      _fillParentControllersFromPerson(
        source: mother,
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
      );
    }
  }

  void _fillParentControllersFromPerson({
    required Person source,
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
  }) {
    firstName.text = source.firstName;
    lastName?.text = source.lastName;
    birthLastName?.text = source.originLastName;
    maritalLastName?.text = source.lastName;
    birthDate.text = source.birthDate;
    deathDate.text = source.deathDate;
    photo.text = source.photo;
    country.text = source.currentCountry.isNotEmpty
        ? source.currentCountry
        : source.birthCountry;
    city.text = source.currentCity.isNotEmpty
        ? source.currentCity
        : source.birthCity;
    birthPlace.text = source.birthPlace;
  }

  List<ProfileRequiredField> _requiredFields() {
    final l10n = AppLocalizations.of(context);
    return [
      ProfileRequiredField(
        id: 'firstName',
        stepIndex: 0,
        label: l10n.firstName,
        value: () => _firstName.text,
      ),
      ProfileRequiredField(
        id: 'lastName',
        stepIndex: 0,
        label: l10n.lastName,
        value: () => _lastName.text,
      ),
      ProfileRequiredField(
        id: 'gender',
        stepIndex: 0,
        label: l10n.gender,
        value: () => _gender.text,
      ),
      ProfileRequiredField(
        id: 'birthDate',
        stepIndex: 0,
        label: l10n.birthDate,
        value: () => _birthDate.text,
      ),
      ProfileRequiredField(
        id: 'familyCode',
        stepIndex: 1,
        label: l10n.familyBranch,
        value: () => _familyCode.text,
      ),
      if (_fatherMode == _ParentInputMode.existing)
        ProfileRequiredField(
          id: 'fatherId',
          stepIndex: 2,
          label: l10n.existingTreeMember,
          value: () => _fatherId.text,
        ),
      if (_fatherMode == _ParentInputMode.create) ...[
        ProfileRequiredField(
          id: 'fatherFirstName',
          stepIndex: 2,
          label: l10n.firstName,
          value: () => _fatherFirstName.text,
        ),
        ProfileRequiredField(
          id: 'fatherLastName',
          stepIndex: 2,
          label: l10n.lastName,
          value: () => _fatherLastName.text,
        ),
      ],
      if (_motherMode == _ParentInputMode.existing)
        ProfileRequiredField(
          id: 'motherId',
          stepIndex: 2,
          label: l10n.existingTreeMember,
          value: () => _motherId.text,
        ),
      if (_motherMode == _ParentInputMode.create) ...[
        ProfileRequiredField(
          id: 'motherFirstName',
          stepIndex: 2,
          label: l10n.firstName,
          value: () => _motherFirstName.text,
        ),
        ProfileRequiredField(
          id: 'motherBirthLastName',
          stepIndex: 2,
          label: l10n.lastName,
          value: () => _motherBirthLastName.text,
        ),
      ],
    ];
  }

  ProfileProgress get _progress =>
      ProfileProgress.fromFields(_requiredFields());

  Widget _progressCard() {
    final l10n = AppLocalizations.of(context);
    final progress = _progress;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileProgress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tooltip(
                message: l10n.profileProgressHelp,
                child: const Icon(Icons.info_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.percent} %',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF173B57),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _segmentedProgress(progress),
          const SizedBox(height: 8),
          Text(l10n.requiredFieldsRemaining(progress.missingRequired)),
          Text(
            progress.missingRequired <= 1
                ? l10n.requiredInfoAlmostDone
                : l10n.completeRequiredInfoHelp,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF52606D)),
          ),
        ],
      ),
    );
  }

  Widget _segmentedProgress(ProfileProgress progress) {
    return Row(
      children: List.generate(_stepTitles.length, (index) {
        final value = progress.stepPercent(index) / 100;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _stepTitles.length - 1 ? 0 : 4,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value,
                backgroundColor: const Color(0xFFE0E4E8),
                color: index == _activeStep
                    ? const Color(0xFF2F6FA3)
                    : const Color(0xFF173B57),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _stepSelector() {
    final progress = _progress;
    final buttons = List.generate(_stepTitles.length, (index) {
      final isActive = index == _activeStep;
      final isComplete = progress.isStepComplete(index);
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: isActive ? const Color(0xFF173B57) : Colors.white,
            foregroundColor: isActive ? Colors.white : const Color(0xFF173B57),
            side: BorderSide(
              color: isActive
                  ? const Color(0xFF173B57)
                  : const Color(0xFFB8C4CE),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => setState(() => _activeStep = index),
          icon: Icon(
            isComplete
                ? Icons.check_circle
                : isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          label: Text(
            isActive
                ? '${_stepTitles[index]} · ${progress.stepPercent(index)} %'
                : _stepTitles[index],
          ),
        ),
      );
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: buttons),
          );
        }
        return Wrap(children: buttons);
      },
    );
  }

  Widget _activeStepContent(FamilyTreeData? data) {
    return switch (_activeStep) {
      0 => _identityStep(),
      1 => _familyStep(),
      2 => _relationshipsStep(data),
      3 => _communicationStep(),
      4 => _placesStep(),
      5 => _privacyStep(),
      _ => _historyStep(),
    };
  }

  Widget _identityStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          _firstName,
          l10n.firstName,
          required: true,
          fieldId: 'firstName',
        ),
        _field(_lastName, l10n.lastName, required: true, fieldId: 'lastName'),
        _field(_birthLastName, l10n.bornLastName),
        _field(_gender, l10n.gender, required: true, fieldId: 'gender'),
        _field(
          _birthDate,
          l10n.birthDate,
          required: true,
          fieldId: 'birthDate',
        ),
        _field(_birthPlace, l10n.birthPlace),
        _field(_deathDate, l10n.deathDate),
        _field(_deathPlace, l10n.deathPlace),
        _field(_burialPlace, l10n.burialPlace),
      ],
    );
  }

  Widget _familyStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          _familyCode,
          l10n.familyBranch,
          required: true,
          fieldId: 'familyCode',
        ),
        _field(_parents, l10n.parents),
        _field(_spouses, l10n.spouses),
        _field(_children, l10n.children),
        _field(_notes, l10n.notes, maxLines: 3),
      ],
    );
  }

  Widget _relationshipsStep(FamilyTreeData? data) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _relationsTabs(),
        const SizedBox(height: 12),
        if (_relationsTab == _RelationsTab.parents) _parentsTab(data),
        if (_relationsTab == _RelationsTab.unions) _unionsTab(data),
        if (_relationsTab == _RelationsTab.children) _childrenTab(data),
        const SizedBox(height: 12),
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
            if (value != null) {
              _markDirty();
              setState(() => _marriageType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _relationsTabs() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _relationTabButton(
          tab: _RelationsTab.parents,
          icon: Icons.account_tree_outlined,
          label: l10n.parents,
          count: [
            _fatherId.text,
            _motherId.text,
          ].where((value) => value.trim().isNotEmpty).length,
        ),
        _relationTabButton(
          tab: _RelationsTab.unions,
          icon: Icons.favorite_border,
          label: l10n.unionsAndSpouses,
          count: _split(_spouseIds.text).length + _pendingUnions.length,
        ),
        _relationTabButton(
          tab: _RelationsTab.children,
          icon: Icons.family_restroom,
          label: l10n.children,
          count: _split(_childrenIds.text).length,
        ),
      ],
    );
  }

  Widget _relationTabButton({
    required _RelationsTab tab,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final selected = _relationsTab == tab;
    return FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 18),
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() => _relationsTab = tab),
      selectedColor: const Color(0xFFD8E8F5),
      checkmarkColor: const Color(0xFF173B57),
    );
  }

  Widget _parentsTab(FamilyTreeData? data) {
    final l10n = AppLocalizations.of(context);
    final father = _parentSection(
      title: l10n.father,
      role: ParentRole.father,
      mode: _fatherMode,
      onModeChanged: (mode) => setState(() {
        _fatherMode = mode;
        _markDirty();
      }),
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
    );
    final mother = _parentSection(
      title: l10n.mother,
      role: ParentRole.mother,
      mode: _motherMode,
      onModeChanged: (mode) => setState(() {
        _motherMode = mode;
        _markDirty();
      }),
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
    );
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(children: [father, mother]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: father),
                const SizedBox(width: 12),
                Expanded(child: mother),
              ],
            );
          },
        ),
        SwitchListTile(
          value: _linkParentsAsCouple,
          title: const Text('Relier le père et la mère comme couple'),
          subtitle: const Text('Uniquement après confirmation.'),
          onChanged: (value) => setState(() {
            _linkParentsAsCouple = value;
            _markDirty();
          }),
        ),
        if (_linkParentsAsCouple)
          DropdownButtonFormField<String>(
            initialValue: _parentCoupleStatus,
            decoration: const InputDecoration(
              labelText: 'Statut de la relation des parents',
            ),
            items: const [
              DropdownMenuItem(value: 'married', child: Text('Mariés')),
              DropdownMenuItem(value: 'partner', child: Text('Union libre')),
              DropdownMenuItem(value: 'separated', child: Text('Séparés')),
              DropdownMenuItem(value: 'divorced', child: Text('Divorcés')),
              DropdownMenuItem(
                value: 'unknown',
                child: Text('Relation inconnue'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _parentCoupleStatus = value;
                  _markDirty();
                });
              }
            },
          ),
      ],
    );
  }

  Widget _unionsTab(FamilyTreeData? data) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.unionRequiredFieldsAppearOnAdd),
        const SizedBox(height: 12),
        _field(_spouseIds, l10n.spouses),
        if (data != null) _unionSection(data),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.manage_accounts_outlined),
          label: Text(l10n.manageUnions),
        ),
      ],
    );
  }

  Widget _childrenTab(FamilyTreeData? data) {
    final l10n = AppLocalizations.of(context);
    final ids = _split(_childrenIds.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_childrenIds, l10n.children),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in ids)
              _personRelationChip(
                data: data,
                id: id,
                relation: l10n.child,
                onDeleted: () {
                  setState(() {
                    _childrenIds.text = ids
                        .where((item) => item != id)
                        .join(', ');
                    _markDirty();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.family_restroom),
          label: Text(l10n.manageChildren),
        ),
      ],
    );
  }

  Widget _communicationStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SwitchListTile(
          value: _allowContact,
          title: Text(l10n.contact),
          subtitle: Text(_allowContact ? l10n.accepted : l10n.contactDisabled),
          onChanged: (value) => setState(() {
            _allowContact = value;
            _markDirty();
          }),
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
      ],
    );
  }

  Widget _placesStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _field(_publicMapLocation, l10n.publicMapLocation),
        _field(_currentAddress, l10n.currentAddress),
        _responsivePair(
          _field(_latitude, l10n.latitude, keyboard: true),
          _field(_longitude, l10n.longitude, keyboard: true),
        ),
        _field(_importantPlaceName, l10n.details),
        _field(_importantPlaceAddress, l10n.currentAddress),
        _responsivePair(
          _field(_importantPlaceLatitude, l10n.latitude, keyboard: true),
          _field(_importantPlaceLongitude, l10n.longitude, keyboard: true),
        ),
        _field(_importantPlaceDescription, l10n.notes, maxLines: 2),
      ],
    );
  }

  Widget _privacyStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _visibilitySettingsCard(),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _showMapInPublicMode,
          title: Text(l10n.showMapInPublicMode),
          subtitle: Text(l10n.alwaysVisible),
          secondary: const Icon(Icons.lock_outline),
          onChanged: null,
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
      ],
    );
  }

  Widget _visibilitySettingsCard() {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.informationVisibility,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(l10n.choosePublicProfileVisibility),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _hideSensitiveVisibility,
                icon: const Icon(Icons.visibility_off_outlined),
                label: Text(l10n.hideSensitiveInfo),
              ),
              OutlinedButton.icon(
                onPressed: _restoreDefaultVisibility,
                icon: const Icon(Icons.restore),
                label: Text(l10n.restoreDefaultVisibility),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _visibilityGroup(l10n.identity, [
            _lockedVisibilityTile(l10n.lastName, Icons.lock_outline),
            _lockedVisibilityTile(l10n.firstName, Icons.lock_outline),
            _visibilityTile(
              label: l10n.photo,
              icon: Icons.photo_outlined,
              value: _photoVisible,
              onChanged: (value) => setState(() => _photoVisible = value),
            ),
            _visibilityTile(
              label: l10n.gender,
              icon: Icons.badge_outlined,
              value: _genderVisible,
              onChanged: (value) => setState(() => _genderVisible = value),
            ),
            _visibilityTile(
              label: l10n.bornLastName,
              icon: Icons.drive_file_rename_outline,
              value: _birthLastNameVisible,
              onChanged: (value) =>
                  setState(() => _birthLastNameVisible = value),
            ),
          ]),
          _visibilityGroup(l10n.familyRelationships, [
            _visibilityTile(
              label: l10n.familyBranch,
              icon: Icons.account_tree_outlined,
              value: _familyBranchVisible,
              onChanged: (value) =>
                  setState(() => _familyBranchVisible = value),
            ),
            _visibilityTile(
              label: l10n.relationships,
              description: l10n.familyRelationsVisibilityDescription,
              icon: Icons.family_restroom,
              value: _familyRelationsVisible,
              sensitive: true,
              onChanged: (value) =>
                  setState(() => _familyRelationsVisible = value),
            ),
          ]),
          _visibilityGroup(l10n.birthDate, [
            _visibilityTile(
              label: l10n.birthDate,
              icon: Icons.cake_outlined,
              value: _birthDateVisible,
              onChanged: (value) => setState(() => _birthDateVisible = value),
            ),
            _visibilityTile(
              label: l10n.birthPlace,
              icon: Icons.place_outlined,
              value: _showBirthPlaceInPublicMode,
              onChanged: (value) =>
                  setState(() => _showBirthPlaceInPublicMode = value),
            ),
            _visibilityTile(
              label: l10n.deathDate,
              icon: Icons.event_busy_outlined,
              value: _deathDateVisible,
              onChanged: (value) => setState(() => _deathDateVisible = value),
            ),
            _visibilityTile(
              label: l10n.deathPlace,
              icon: Icons.location_off_outlined,
              value: _deathPlaceVisible,
              onChanged: (value) => setState(() => _deathPlaceVisible = value),
            ),
            _visibilityTile(
              label: l10n.burialPlace,
              icon: Icons.landscape_outlined,
              value: _burialPlaceVisible,
              onChanged: (value) => setState(() => _burialPlaceVisible = value),
            ),
          ]),
          _visibilityGroup(l10n.contact, [
            _visibilityTile(
              label: l10n.email,
              icon: Icons.mail_outline,
              value: _emailVisible,
              sensitive: true,
              onChanged: (value) => setState(() => _emailVisible = value),
            ),
            _visibilityTile(
              label: l10n.phoneNumber,
              icon: Icons.phone_outlined,
              value: _phoneVisible,
              sensitive: true,
              onChanged: (value) => setState(() => _phoneVisible = value),
            ),
            _visibilityTile(
              label: l10n.whatsappNumber,
              icon: Icons.chat_outlined,
              value: _whatsappVisible,
              sensitive: true,
              onChanged: (value) => setState(() => _whatsappVisible = value),
            ),
          ]),
          _visibilityGroup(l10n.places, [
            _lockedVisibilityTile(l10n.publicMapLocation, Icons.lock_outline),
            _visibilityTile(
              label: l10n.currentAddress,
              icon: Icons.home_outlined,
              value: _showCurrentAddressInPublicMode,
              sensitive: true,
              onChanged: (value) =>
                  setState(() => _showCurrentAddressInPublicMode = value),
            ),
            _visibilityTile(
              label: l10n.privateCoordinates,
              icon: Icons.my_location_outlined,
              value: _privateCoordinatesVisible,
              sensitive: true,
              onChanged: (value) =>
                  setState(() => _privateCoordinatesVisible = value),
            ),
          ]),
          _visibilityGroup(l10n.history, [
            _visibilityTile(
              label: l10n.history,
              icon: Icons.history_outlined,
              value: _showHistoryInPublicMode,
              sensitive: true,
              onChanged: (value) =>
                  setState(() => _showHistoryInPublicMode = value),
            ),
            _visibilityTile(
              label: l10n.notes,
              icon: Icons.notes_outlined,
              value: _notesVisible,
              sensitive: true,
              onChanged: (value) => setState(() => _notesVisible = value),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _visibilityGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _lockedVisibilityTile(String label, IconData icon) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Chip(
        avatar: const Icon(Icons.lock_outline, size: 16),
        label: Text(l10n.alwaysVisible),
      ),
    );
  }

  Widget _visibilityTile({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? description,
    bool sensitive = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(label),
      subtitle: Text(description ?? (value ? l10n.visible : l10n.hidden)),
      value: value,
      onChanged: (next) async {
        if (next && sensitive && !await _confirmSensitiveVisible()) return;
        _markDirty();
        onChanged(next);
      },
    );
  }

  Future<bool> _confirmSensitiveVisible() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.informationVisibility),
        content: Text(l10n.sensitiveVisibilityConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.makeVisible),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _hideSensitiveVisibility() {
    setState(() {
      _showMapInPublicMode = true;
      _showCurrentAddressInPublicMode = false;
      _showContactInPublicMode = false;
      _showHistoryInPublicMode = false;
      _privateCoordinatesVisible = false;
      _familyRelationsVisible = false;
      _emailVisible = false;
      _phoneVisible = false;
      _whatsappVisible = false;
      _notesVisible = false;
      _markDirty();
    });
  }

  void _restoreDefaultVisibility() {
    const defaults = PersonPrivacy();
    setState(() {
      _showMapInPublicMode = true;
      _showBirthPlaceInPublicMode = defaults.showBirthPlaceInPublicMode;
      _showCurrentAddressInPublicMode = defaults.showCurrentAddressInPublicMode;
      _showContactInPublicMode = defaults.showContactInPublicMode;
      _showHistoryInPublicMode = defaults.showHistoryInPublicMode;
      _photoVisible = defaults.photoVisible;
      _genderVisible = defaults.genderVisible;
      _birthLastNameVisible = defaults.birthLastNameVisible;
      _birthDateVisible = defaults.birthDateVisible;
      _deathDateVisible = defaults.deathDateVisible;
      _deathPlaceVisible = defaults.deathPlaceVisible;
      _burialPlaceVisible = defaults.burialPlaceVisible;
      _privateCoordinatesVisible = defaults.privateCoordinatesVisible;
      _familyBranchVisible = defaults.familyBranchVisible;
      _familyRelationsVisible = defaults.familyRelationsVisible;
      _emailVisible = defaults.emailVisible;
      _phoneVisible = defaults.phoneVisible;
      _whatsappVisible = defaults.whatsappVisible;
      _notesVisible = defaults.notesVisible;
      _markDirty();
    });
  }

  Widget _historyStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _field(_historyDate, l10n.birthDate),
        _field(_historyTitle, l10n.history),
        _field(_historyPlace, l10n.birthPlace),
        _responsivePair(
          _field(_historyLatitude, l10n.latitude, keyboard: true),
          _field(_historyLongitude, l10n.longitude, keyboard: true),
        ),
        _field(_historyDescription, l10n.notes, maxLines: 3),
      ],
    );
  }

  Widget _responsivePair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, second]);
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E4E8)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _requiredErrorsCard() {
    final l10n = AppLocalizations.of(context);
    final missing = _missingRequiredFields().toList();
    final activeMissing = missing
        .where((field) => field.stepIndex == _activeStep)
        .toList();
    final visibleMissing = activeMissing.isEmpty ? missing : activeMissing;
    return Semantics(
      liveRegion: true,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.requiredFieldsMissingTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.requiredFieldsMissingMessage(
                        missing.length,
                        visibleMissing.map((field) => field.label).join(', '),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepActions() {
    final l10n = AppLocalizations.of(context);
    final canContinue = _activeStepVisibleRequiredComplete();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _save(draft: true),
          icon: const Icon(Icons.drafts_outlined),
          label: Text(l10n.saveDraft),
        ),
        OutlinedButton.icon(
          onPressed: _activeStep == 0 || _isSaving
              ? null
              : () => setState(() => _activeStep -= 1),
          icon: const Icon(Icons.chevron_left),
          label: Text(l10n.previous),
        ),
        FilledButton.icon(
          onPressed: _isSaving || !canContinue ? null : _saveAndContinue,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          label: Text(l10n.saveAndContinue),
        ),
        if (_lastDraftSavedAt != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              l10n.draftSavedNow,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF52606D)),
            ),
          ),
      ],
    );
  }

  bool _activeStepVisibleRequiredComplete() => _requiredFields()
      .where((field) => field.stepIndex == _activeStep)
      .every((field) => field.isComplete);

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    await _save(draft: true);
    if (!mounted) return;
    if (_activeStep < _stepTitles.length - 1) {
      setState(() => _activeStep += 1);
    }
  }

  Widget _personRelationChip({
    required FamilyTreeData? data,
    required String id,
    required String relation,
    required VoidCallback onDeleted,
  }) {
    final person = data?.people.where((person) => person.id == id).firstOrNull;
    return InputChip(
      avatar: CircleAvatar(
        backgroundImage: person == null || person.photo.isEmpty
            ? null
            : NetworkImage(person.photo),
        child: person == null || person.photo.isEmpty
            ? Text(person == null ? '?' : _initials(person))
            : null,
      ),
      label: Text(
        person == null ? '$relation · $id' : '$relation · ${person.fullName}',
      ),
      onPressed: person == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonEditScreen(person: person),
                ),
              );
            },
      onDeleted: onDeleted,
    );
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
    if (data != null && !_didHydrateExistingRelations) {
      _hydrateExistingRelationDetails(data);
      _didHydrateExistingRelations = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? l10n.addPerson : l10n.edit),
        actions: [_appBarActions(), const SizedBox(width: 8)],
      ),
      body: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || !_hasUnsavedChanges) return;
          final shouldLeave = await _confirmDiscardChanges();
          if (shouldLeave && context.mounted) Navigator.pop(context);
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _progressCard(),
                      const SizedBox(height: 12),
                      _stepSelector(),
                      const SizedBox(height: 12),
                      Text(
                        l10n.requiredFieldsNotice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_showRequiredErrors) ...[
                        _requiredErrorsCard(),
                        const SizedBox(height: 12),
                      ],
                      _sectionCard(child: _activeStepContent(data)),
                      const SizedBox(height: 12),
                      _stepActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarActions() {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final saveIcon = _isSaving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.save);
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l10n.cancelChangesTooltip,
            child: Semantics(
              label: l10n.cancelChangesTooltip,
              button: true,
              child: IconButton.outlined(
                tooltip: l10n.cancel,
                onPressed: _isSaving ? null : _cancelEdits,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.save,
            child: Semantics(
              label: l10n.save,
              button: true,
              child: IconButton.filled(
                tooltip: l10n.save,
                onPressed: _isSaving ? null : _save,
                icon: saveIcon,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.cancelChangesTooltip,
          button: true,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _cancelEdits,
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.cancel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: l10n.save,
          button: true,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: saveIcon,
            label: Text(l10n.save),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: const Color(0xFF2F6FA3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unionSection(FamilyTreeData data) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showUnionDialog(data),
            icon: const Icon(Icons.favorite_border),
            label: Text(l10n.addUnion),
          ),
          if (_pendingUnions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final union in _pendingUnions)
                  InputChip(
                    label: Text(_pendingUnionLabel(data, union)),
                    onDeleted: () {
                      setState(() => _pendingUnions.remove(union));
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _pendingUnionLabel(FamilyTreeData data, _PendingUnionDraft union) {
    final partner = data.people
        .where((person) => person.id == union.partnerId)
        .firstOrNull;
    return '${partner?.fullName ?? union.partnerId} · ${_unionTypeLabel(union.type)}';
  }

  String _unionTypeLabel(String type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      'traditional' => l10n.traditionalMarriage,
      'civil' => l10n.civilMarriage,
      'religious' => l10n.religiousMarriage,
      'customaryAndCivil' =>
        '${l10n.traditionalMarriage} + ${l10n.civilMarriage}',
      'customaryCivilAndReligious' =>
        '${l10n.traditionalMarriage} + ${l10n.civilMarriage} + ${l10n.religiousMarriage}',
      'freeUnion' => l10n.freeUnion,
      _ => l10n.unknown,
    };
  }

  Future<void> _showUnionDialog(FamilyTreeData data) async {
    final l10n = AppLocalizations.of(context);
    final currentId =
        widget.person?.id ??
        (_draftPersonId ??= 'p${DateTime.now().microsecondsSinceEpoch}');
    final candidates =
        data.people.where((person) => person.id != currentId).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (candidates.isEmpty) return;
    var partnerId = candidates.first.id;
    var type = 'traditional';
    var status = 'active';
    final date = TextEditingController();
    final place = TextEditingController();
    final country = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<_PendingUnionDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.addUnion),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: partnerId,
                      decoration: InputDecoration(labelText: l10n.spouse),
                      items: [
                        for (final person in candidates)
                          DropdownMenuItem(
                            value: person.id,
                            child: Text(person.fullName),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => partnerId = value);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(labelText: l10n.unionType),
                      items: [
                        DropdownMenuItem(
                          value: 'traditional',
                          child: Text(l10n.traditionalMarriage),
                        ),
                        DropdownMenuItem(
                          value: 'civil',
                          child: Text(l10n.civilMarriage),
                        ),
                        DropdownMenuItem(
                          value: 'religious',
                          child: Text(l10n.religiousMarriage),
                        ),
                        DropdownMenuItem(
                          value: 'customaryAndCivil',
                          child: Text(
                            '${l10n.traditionalMarriage} + ${l10n.civilMarriage}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'customaryCivilAndReligious',
                          child: Text(
                            '${l10n.traditionalMarriage} + ${l10n.civilMarriage} + ${l10n.religiousMarriage}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'freeUnion',
                          child: Text(l10n.freeUnion),
                        ),
                        DropdownMenuItem(
                          value: 'unknown',
                          child: Text(l10n.unknown),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => type = value);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: l10n.marriageStatus,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text(l10n.activeUnion),
                        ),
                        DropdownMenuItem(
                          value: 'separated',
                          child: Text(l10n.separated),
                        ),
                        DropdownMenuItem(
                          value: 'divorced',
                          child: Text(l10n.divorced),
                        ),
                        DropdownMenuItem(
                          value: 'endedByDeath',
                          child: Text(l10n.endedByDeath),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => status = value);
                      },
                    ),
                    TextField(
                      controller: date,
                      decoration: InputDecoration(
                        labelText: l10n.traditionalMarriageDate,
                      ),
                    ),
                    TextField(
                      controller: place,
                      decoration: InputDecoration(
                        labelText: l10n.marriagePlace,
                      ),
                    ),
                    TextField(
                      controller: country,
                      decoration: InputDecoration(labelText: l10n.country),
                    ),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.notes),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _PendingUnionDraft(
                      partnerId: partnerId,
                      type: type,
                      status: status,
                      traditionalMarriageDate: date.text.trim(),
                      marriagePlace: place.text.trim(),
                      marriageCountry: country.text.trim(),
                      notes: notes.text.trim(),
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
    date.dispose();
    place.dispose();
    country.dispose();
    notes.dispose();
    if (result == null) return;
    setState(() {
      _pendingUnions.removeWhere(
        (union) => union.partnerId == result.partnerId,
      );
      _pendingUnions.add(result);
      _spouseIds.text = {
        ..._split(_spouseIds.text),
        result.partnerId,
      }.join(', ');
      _spouses.text = {..._split(_spouses.text), result.partnerId}.join(', ');
    });
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? fieldId,
    int maxLines = 1,
    bool keyboard = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasRequiredError =
        required &&
        fieldId != null &&
        _showRequiredErrors &&
        _highlightedRequiredFieldIds.contains(fieldId) &&
        controller.text.trim().isEmpty;
    final errorColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {
          _markDirty();
          if (fieldId != null && controller.text.trim().isNotEmpty) {
            _highlightedRequiredFieldIds.remove(fieldId);
            if (_highlightedRequiredFieldIds.isEmpty) {
              _showRequiredErrors = false;
            }
          }
        }),
        keyboardType: keyboard
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        decoration: InputDecoration(
          label: RequiredFieldLabel(label: label, required: required),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: hasRequiredError
              ? errorColor.withValues(alpha: 0.06)
              : Colors.white,
          helperText: hasRequiredError ? l10n.requiredFieldExplicit : null,
          helperStyle: TextStyle(
            color: hasRequiredError ? errorColor : null,
            fontWeight: hasRequiredError ? FontWeight.w600 : null,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasRequiredError ? errorColor : const Color(0xFFE0E4E8),
              width: hasRequiredError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasRequiredError ? errorColor : const Color(0xFF2F6FA3),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: errorColor, width: 2),
          ),
        ),
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
    required _ParentInputMode? mode,
    required ValueChanged<_ParentInputMode> onModeChanged,
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
              SegmentedButton<_ParentInputMode>(
                segments: [
                  ButtonSegment(
                    value: _ParentInputMode.existing,
                    icon: const Icon(Icons.person_search_outlined),
                    label: Text(l10n.existingMember),
                  ),
                  ButtonSegment(
                    value: _ParentInputMode.create,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(l10n.createMember),
                  ),
                ],
                selected: mode == null ? <_ParentInputMode>{} : {mode},
                emptySelectionAllowed: true,
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) onModeChanged(selection.first);
                },
              ),
              const SizedBox(height: 12),
              if (mode == _ParentInputMode.existing) ...[
                _field(
                  existingId,
                  l10n.existingTreeMember,
                  required: true,
                  fieldId: role == ParentRole.father ? 'fatherId' : 'motherId',
                ),
                Text(
                  l10n.parentSelectionRequired,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF52606D),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (mode == _ParentInputMode.create || mode == null) ...[
                _field(
                  firstName,
                  l10n.firstName,
                  required: mode == _ParentInputMode.create,
                  fieldId: role == ParentRole.father
                      ? 'fatherFirstName'
                      : 'motherFirstName',
                ),
                if (lastName != null)
                  _field(
                    lastName,
                    l10n.lastName,
                    required: mode == _ParentInputMode.create,
                    fieldId: 'fatherLastName',
                  ),
              ],
              if (birthLastName != null)
                _field(
                  birthLastName,
                  l10n.bornLastName,
                  required: mode == _ParentInputMode.create,
                  fieldId: 'motherBirthLastName',
                ),
              if (maritalLastName != null)
                _field(maritalLastName, 'Nom marital facultatif'),
              _responsivePair(
                _field(birthDate, l10n.birthDate),
                _field(deathDate, l10n.deathDate),
              ),
              _field(birthPlace, l10n.birthPlace),
              _responsivePair(_field(country, 'Pays'), _field(city, 'Ville')),
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

  Future<void> _save({bool draft = false}) async {
    if (_isSaving) return;
    if (!draft &&
        (!_allRequiredFieldsComplete() || !_formKey.currentState!.validate())) {
      _goToFirstMissingRequiredField();
      return;
    }
    setState(() {
      _isSaving = true;
      if (!draft) {
        _showRequiredErrors = false;
        _highlightedRequiredFieldIds.clear();
      }
    });
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
        showMapInPublicMode: true,
        showBirthPlaceInPublicMode: _showBirthPlaceInPublicMode,
        showCurrentAddressInPublicMode: _showCurrentAddressInPublicMode,
        showContactInPublicMode: _showContactInPublicMode,
        showHistoryInPublicMode: _showHistoryInPublicMode,
        photoVisible: _photoVisible,
        genderVisible: _genderVisible,
        birthLastNameVisible: _birthLastNameVisible,
        birthDateVisible: _birthDateVisible,
        deathDateVisible: _deathDateVisible,
        deathPlaceVisible: _deathPlaceVisible,
        burialPlaceVisible: _burialPlaceVisible,
        privateCoordinatesVisible: _privateCoordinatesVisible,
        familyBranchVisible: _familyBranchVisible,
        familyRelationsVisible: _familyRelationsVisible,
        emailVisible: _emailVisible,
        phoneVisible: _phoneVisible,
        whatsappVisible: _whatsappVisible,
        notesVisible: _notesVisible,
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
      final saveResults = [result];
      if (_pendingUnions.isNotEmpty) {
        final auth = ref.read(authSessionProvider);
        final actorRole = auth.firebaseRole ?? auth.session?.role ?? 'viewer';
        final adminId = auth.firebaseUid ?? auth.firebaseEmail ?? actorRole;
        for (final union in _pendingUnions) {
          saveResults.add(
            await ref
                .read(familyTreeProvider.notifier)
                .upsertMarriageUnion(
                  MarriageRelation(
                    id: '',
                    personId: id,
                    spouseId: union.partnerId,
                    familyId: person.familyCode,
                    marriageType: union.type,
                    status: union.status,
                    marriageDate: union.traditionalMarriageDate,
                    traditionalMarriageDate: union.traditionalMarriageDate,
                    marriagePlace: union.marriagePlace,
                    marriageCountry: union.marriageCountry,
                    notes: union.notes,
                  ),
                  actorRole: actorRole,
                  adminId: adminId,
                ),
          );
        }
      }
      if (!mounted) return;
      if (saveResults.every((item) => item.isFirestoreConfirmed)) {
        _hasUnsavedChanges = false;
        _showSaveSnackBar(
          color: Colors.green,
          icon: Icons.check_circle,
          message: draft
              ? l10n.draftSavedNow
              : 'Modification enregistrée dans la base de données.',
          duration: const Duration(seconds: 3),
        );
        if (draft) {
          setState(() => _lastDraftSavedAt = DateTime.now());
          return;
        }
        Navigator.pop(context);
        return;
      }
      if (saveResults.any((item) => item.isAuthorizationRequired)) {
        _hasUnsavedChanges = false;
        await _requestAuthorizationAndRetrySave(draft: draft);
        return;
      }
      if (saveResults.any((item) => item.isLocalPending)) {
        _hasUnsavedChanges = false;
        _showSaveSnackBar(
          color: Colors.orange.shade800,
          icon: Icons.sync_problem_outlined,
          message: draft
              ? l10n.draftSavedNow
              : 'Modifications enregistrées sur cet appareil. Elles seront synchronisées automatiquement dès que Firestore sera disponible.',
          duration: const Duration(seconds: 5),
        );
        if (draft) setState(() => _lastDraftSavedAt = DateTime.now());
        return;
      }
      _showSaveSnackBar(
        color: Colors.red,
        icon: Icons.error,
        message: _databaseErrorMessage(
          saveResults.map((item) => item.lastError).join('\n'),
        ),
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

  Future<void> _requestAuthorizationAndRetrySave({required bool draft}) async {
    _showSaveSnackBar(
      color: Colors.orange.shade800,
      icon: Icons.lock_outline,
      message:
          'Saisissez le code de modification pour autoriser l’enregistrement de ces changements.',
      duration: const Duration(seconds: 4),
    );
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const ModificationCodeRequiredDialog(),
    );
    if (!mounted) return;
    if (unlocked != true) {
      _showSaveSnackBar(
        color: Colors.red,
        icon: Icons.lock_outline,
        message: 'Code incorrect ou accès non autorisé.',
        duration: const Duration(seconds: 5),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final synced = await ref
          .read(familyTreeProvider.notifier)
          .syncPendingChanges(force: true);
      if (!mounted) return;
      final stillNeedsAuthorization = synced.pendingSyncQueue.any(
        (item) =>
            item.lastErrorCode == 'permission-denied' ||
            item.lastErrorCode == 'unauthenticated',
      );
      if (stillNeedsAuthorization) {
        _showSaveSnackBar(
          color: Colors.red,
          icon: Icons.lock_outline,
          message: 'Code incorrect ou accès non autorisé.',
          duration: const Duration(seconds: 5),
        );
        return;
      }
      _showSaveSnackBar(
        color: Colors.green,
        icon: Icons.check_circle,
        message: 'Code validé. Les modifications ont été enregistrées.',
        duration: const Duration(seconds: 3),
      );
      if (draft) {
        setState(() => _lastDraftSavedAt = DateTime.now());
        return;
      }
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showSaveSnackBar(
        color: Colors.orange.shade800,
        icon: Icons.sync_problem_outlined,
        message:
            'Modifications enregistrées sur cet appareil. Elles seront synchronisées automatiquement dès que Firestore sera disponible.',
        duration: const Duration(seconds: 5),
      );
    }
  }

  bool _allRequiredFieldsComplete() =>
      _requiredFields().every((field) => field.isComplete);

  Iterable<ProfileRequiredField> _missingRequiredFields() =>
      _requiredFields().where((field) => !field.isComplete);

  void _goToFirstMissingRequiredField() {
    final missing = _missingRequiredFields().toList();
    if (missing.isEmpty) return;
    setState(() {
      _activeStep = missing.first.stepIndex;
      _showRequiredErrors = true;
      _highlightedRequiredFieldIds
        ..clear()
        ..addAll(missing.map((field) => field.id));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          AppLocalizations.of(
            context,
          ).requiredFieldsMissingSnackbar(missing.length),
        ),
      ),
    );
  }

  void _markDirty() {
    _hasUnsavedChanges = true;
  }

  Future<bool> _confirmDiscardChanges() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).unsavedChangesTitle),
        content: Text(AppLocalizations.of(context).unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).leave),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _cancelEdits() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }
    final abandon = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.cancelChangesTitle),
          content: Text(l10n.cancelChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.continueEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.discardChanges),
            ),
          ],
        );
      },
    );
    if (abandon != true || !mounted) return;
    _restoreInitialFormValues();
    _hasUnsavedChanges = false;
    if (mounted) Navigator.pop(context);
  }

  void _restoreInitialFormValues() {
    final person = widget.person;
    if (person != null) {
      _loadExistingPerson(person);
      return;
    }
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
      controller.clear();
    }
    _familyCode.text = 'AMOUZOU2026';
    _allowContact = true;
    _emailVisibility = 'familyOnly';
    _phoneVisibility = 'familyOnly';
    _whatsappVisibility = 'familyOnly';
    _showMapInPublicMode = true;
    _showBirthPlaceInPublicMode = false;
    _showCurrentAddressInPublicMode = false;
    _showContactInPublicMode = false;
    _showHistoryInPublicMode = false;
    _photoVisible = true;
    _genderVisible = true;
    _birthLastNameVisible = true;
    _birthDateVisible = true;
    _deathDateVisible = true;
    _deathPlaceVisible = false;
    _burialPlaceVisible = false;
    _privateCoordinatesVisible = false;
    _familyBranchVisible = true;
    _familyRelationsVisible = false;
    _emailVisible = false;
    _phoneVisible = false;
    _whatsappVisible = false;
    _notesVisible = false;
    _linkParentsAsCouple = false;
    _parentCoupleStatus = 'unknown';
    _pendingUnions.clear();
    _activeStep = 0;
    _relationsTab = _RelationsTab.parents;
    _fatherMode = null;
    _motherMode = null;
  }

  Future<PersonDuplicateDecision> _resolveDuplicateBeforeSave(
    Person person,
  ) async {
    if (widget.person != null) return PersonDuplicateDecision.saveAnyway;
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
      final importantPlace = person.importantPlaces.firstOrNull;
      _importantPlaceName.text = importantPlace?.name ?? '';
      _importantPlaceAddress.text = importantPlace?.address ?? '';
      _importantPlaceLatitude.text = importantPlace?.latitude?.toString() ?? '';
      _importantPlaceLongitude.text =
          importantPlace?.longitude?.toString() ?? '';
      _importantPlaceDescription.text = importantPlace?.description ?? '';
      _email.text = person.email;
      _phoneNumber.text = person.phoneNumber;
      _whatsappNumber.text = person.whatsappNumber;
      _allowContact = person.allowContact;
      _emailVisibility = person.emailVisibility;
      _phoneVisibility = person.phoneVisibility;
      _whatsappVisibility = person.whatsappVisibility;
      _showMapInPublicMode = true;
      _showBirthPlaceInPublicMode = person.privacy.showBirthPlaceInPublicMode;
      _showCurrentAddressInPublicMode =
          person.privacy.showCurrentAddressInPublicMode;
      _showContactInPublicMode = person.privacy.showContactInPublicMode;
      _showHistoryInPublicMode = person.privacy.showHistoryInPublicMode;
      _photoVisible = person.privacy.photoVisible;
      _genderVisible = person.privacy.genderVisible;
      _birthLastNameVisible = person.privacy.birthLastNameVisible;
      _birthDateVisible = person.privacy.birthDateVisible;
      _deathDateVisible = person.privacy.deathDateVisible;
      _deathPlaceVisible = person.privacy.deathPlaceVisible;
      _burialPlaceVisible = person.privacy.burialPlaceVisible;
      _privateCoordinatesVisible = person.privacy.privateCoordinatesVisible;
      _familyBranchVisible = person.privacy.familyBranchVisible;
      _familyRelationsVisible = person.privacy.familyRelationsVisible;
      _emailVisible = person.privacy.emailVisible;
      _phoneVisible = person.privacy.phoneVisible;
      _whatsappVisible = person.privacy.whatsappVisible;
      _notesVisible = person.privacy.notesVisible;
      _familyCode.text = person.familyCode;
      _fatherId.text = person.fatherId;
      _motherId.text = person.motherId;
      _fatherMode = person.fatherId.trim().isEmpty
          ? null
          : _ParentInputMode.existing;
      _motherMode = person.motherId.trim().isEmpty
          ? null
          : _ParentInputMode.existing;
      _spouseIds.text = _joinUnique([...person.spouseIds, ...person.spouses]);
      _childrenIds.text = _joinUnique([
        ...person.childrenIds,
        ...person.children,
      ]);
      _marriageType = person.marriageType;
      _parents.text = _joinUnique([
        person.fatherId,
        person.motherId,
        ...person.parents,
      ]);
      _spouses.text = _joinUnique([...person.spouses, ...person.spouseIds]);
      _children.text = _joinUnique([...person.children, ...person.childrenIds]);
      _notes.text = person.notes;
      final event = person.history.firstOrNull;
      _historyTitle.text = event?.title ?? '';
      _historyDate.text = event?.date ?? '';
      _historyPlace.text = event?.place ?? '';
      _historyLatitude.text = event?.latitude?.toString() ?? '';
      _historyLongitude.text = event?.longitude?.toString() ?? '';
      _historyDescription.text = event?.description ?? '';
      _showRequiredErrors = false;
      _highlightedRequiredFieldIds.clear();
      _didHydrateExistingRelations = false;
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

class _PendingUnionDraft {
  const _PendingUnionDraft({
    required this.partnerId,
    required this.type,
    required this.status,
    required this.traditionalMarriageDate,
    required this.marriagePlace,
    required this.marriageCountry,
    required this.notes,
  });

  final String partnerId;
  final String type;
  final String status;
  final String traditionalMarriageDate;
  final String marriagePlace;
  final String marriageCountry;
  final String notes;
}

enum _RelationsTab { parents, unions, children }

enum _ParentInputMode { existing, create }

class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({
    super.key,
    required this.label,
    this.required = false,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: required ? '$label, champ obligatoire' : label,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label),
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
