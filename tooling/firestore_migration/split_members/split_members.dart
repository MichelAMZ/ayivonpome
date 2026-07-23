import 'dart:convert';
import 'dart:io';

const productionProjectId = 'ayivon-aziangbede';
const emulatorProjectId = 'demo-ayivon-preprod';

void main(List<String> args) {
  final options = _arguments(args);
  final apply = options['apply'] == 'true';
  final sourceProject = options['source-project'] ?? '';
  final targetProject = options['target-project'] ?? '';
  final familyId = options['family-id'] ?? 'ayivon';
  final inputPath =
      options['input'] ?? 'migration_output/staging_anonymized.json';
  final outputDir = options['output'] ?? 'migration_output/dry_run';
  final limit = int.tryParse(options['limit'] ?? '');
  final resumeFrom = options['resume-from'];
  _refuseServiceAccounts(Directory.current);
  if (apply) {
    final blockers = <String>[
      if (targetProject.isEmpty) 'target-project absent',
      if (targetProject == productionProjectId) 'cible production interdite',
      if (targetProject == emulatorProjectId)
        'émulateur interdit comme staging distant',
      if (options['confirm-staging'] != 'true') 'confirm-staging absent',
      if (options['backup-validated'] != 'true') 'sauvegarde non validée',
      if (options['dry-run-report']?.isEmpty ?? true) 'rapport dry-run absent',
    ];
    stderr.writeln(
      'REFUS --apply: ${blockers.isEmpty ? 'écriture distante non implémentée avant validation humaine' : blockers.join(', ')}',
    );
    exitCode = 2;
    return;
  }

  final input = File(inputPath);
  final root = jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
  var people = (root['people'] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
  if (resumeFrom != null && resumeFrom.isNotEmpty) {
    final index = people.indexWhere((person) => person['id'] == resumeFrom);
    if (index >= 0) {
      people = people.sublist(index);
    }
  }
  if (limit != null && limit >= 0 && people.length > limit) {
    people = people.take(limit).toList();
  }

  final errors = <Map<String, Object?>>[];
  final warnings = <Map<String, Object?>>[];
  final ids = <String>{};
  final duplicates = <String>{};
  const knownLegacyKeys = {
    'id',
    'firstName',
    'lastName',
    'birthLastName',
    'originalLastName',
    'gender',
    'birthDate',
    'birthPlace',
    'deathDate',
    'deathPlace',
    'publicMapLocation',
    'currentAddress',
    'currentCity',
    'currentRegion',
    'currentCountry',
    'birthCity',
    'birthCountry',
    'burialPlace',
    'latitude',
    'longitude',
    'importantPlaces',
    'email',
    'phoneNumber',
    'whatsappNumber',
    'allowContact',
    'emailVisibility',
    'phoneVisibility',
    'whatsappVisibility',
    'privacy',
    'photo',
    'familyId',
    'originFamilyId',
    'linkedTreeEnabled',
    'familyCode',
    'fatherId',
    'motherId',
    'spouseIds',
    'childrenIds',
    'marriageType',
    'parents',
    'spouses',
    'children',
    'history',
    'notes',
    'generation',
    'createdAt',
    'updatedAt',
    'updatedBy',
    'version',
    'deletedAt',
    'isTemporaryProfile',
    'profileNeedsCompletion',
    'stagingData',
  };
  for (final person in people) {
    final id = '${person['id'] ?? ''}'.trim();
    if (!ids.add(id)) {
      duplicates.add(id);
    }
    if (id.isEmpty || !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)) {
      errors.add(_issue('P0', 'invalid_id', id));
    }
    if ('${person['familyId'] ?? ''}' != familyId) {
      errors.add(_issue('P0', 'invalid_family_id', id));
    }
    final unknown = person.keys.toSet().difference(knownLegacyKeys);
    if (unknown.isNotEmpty) {
      errors.add(_issue('P1', 'unknown_fields', '$id: ${unknown.join(',')}'));
    }
    for (final key in ['createdAt', 'updatedAt']) {
      final value = '${person[key] ?? ''}'.trim();
      if (value.isNotEmpty && DateTime.tryParse(value) == null) {
        errors.add(_issue('P1', 'invalid_timestamp', '$id.$key'));
      }
    }
    if ('${person['ownerUid'] ?? ''}'.trim().isNotEmpty) {
      errors.add(_issue('P0', 'unexpected_owner_uid', id));
    }
  }
  for (final id in duplicates) {
    errors.add(_issue('P0', 'duplicate_id', id));
  }

  final publicDocs = <Map<String, Object?>>[];
  final privateDocs = <Map<String, Object?>>[];
  for (final person in people) {
    final id = '${person['id'] ?? ''}';
    for (final key in ['fatherId', 'motherId']) {
      final related = '${person[key] ?? ''}'.trim();
      if (related.isNotEmpty && !ids.contains(related)) {
        errors.add(_issue('P1', 'broken_$key', '$id -> $related'));
      }
    }
    for (final key in [
      'spouseIds',
      'childrenIds',
      'parents',
      'spouses',
      'children',
    ]) {
      for (final related in _strings(person[key])) {
        if (!ids.contains(related)) {
          errors.add(_issue('P1', 'broken_$key', '$id -> $related'));
        }
      }
    }
    publicDocs.add(_publicProjection(person, familyId));
    privateDocs.add(_privateProjection(person, familyId));
  }
  for (final cycle in _cycles(people)) {
    errors.add(_issue('P0', 'genealogy_cycle', cycle.join(' -> ')));
  }
  const privatePublicKeys = {
    'email',
    'phone',
    'phoneNumber',
    'whatsapp',
    'whatsappNumber',
    'fullAddress',
    'currentAddress',
    'fullBirthDate',
    'privateNotes',
    'notes',
    'ownerUid',
    'visibilitySettings',
  };
  for (final doc in publicDocs) {
    final leaked = doc.keys.toSet().intersection(privatePublicKeys);
    if (leaked.isNotEmpty) {
      errors.add(
        _issue(
          'P0',
          'private_field_in_public',
          '${doc['id']}: ${leaked.join(',')}',
        ),
      );
    }
  }
  if (targetProject.isEmpty) {
    warnings.add(
      _issue(
        'INFO',
        'staging_project_unconfigured',
        'Aucune cible distante utilisée.',
      ),
    );
  }
  warnings.add(
    _issue(
      'INFO',
      'remote_conflict_check_not_run',
      'Dry-run strictement local; conflits distants non vérifiés.',
    ),
  );
  final existingPublic = (root['members_public'] as List? ?? const []).length;
  final existingPrivate = (root['members_private'] as List? ?? const []).length;
  if (existingPublic > 0 || existingPrivate > 0) {
    warnings.add(
      _issue(
        'P1',
        'existing_split_documents_in_input',
        'public=$existingPublic private=$existingPrivate',
      ),
    );
  }

  final projectionDigest = _checksum(
    jsonEncode({'public': publicDocs, 'private': privateDocs}),
  );
  final p0Count = errors.where((item) => item['severity'] == 'P0').length;
  final p1Count = errors.where((item) => item['severity'] == 'P1').length;
  final report = <String, Object?>{
    'mode': 'dry-run',
    'sourceProject': sourceProject.isEmpty ? null : sourceProject,
    'targetProject': targetProject.isEmpty ? null : targetProject,
    'familyId': familyId,
    'input': input.absolute.path,
    'totalMembers': people.length,
    'publicDocuments': publicDocs.length,
    'privateDocuments': privateDocs.length,
    'duplicateIds': duplicates.length,
    'p0Errors': p0Count,
    'p1Errors': p1Count,
    'warningCount': warnings.length,
    'projectionDigestFnv1a64': projectionDigest,
    'schemaVersion': 2,
    'existingPublicDocumentsInInput': existingPublic,
    'existingPrivateDocumentsInInput': existingPrivate,
    'timestampsStrategy': 'serverTimestamp-on-apply',
    'ownerUidStrategy': 'always-null-until-controlled-claim',
    'remoteReadPerformed': false,
    'remoteWritePerformed': false,
    'applyAllowed': false,
  };
  final output = Directory(outputDir)..createSync(recursive: true);
  _writeJson('${output.path}/migration_report.json', report);
  _writeJson('${output.path}/migration_errors.json', errors);
  _writeJson('${output.path}/migration_manifest.json', {
    ...report,
    'sourceChecksumFnv1a64': _checksum(input.readAsStringSync()),
    'publicIds': publicDocs.map((doc) => doc['id']).toList(),
    'privateIds': privateDocs.map((doc) => doc['memberId']).toList(),
  });
  File('${output.path}/migration_report.md').writeAsStringSync(
    '# Dry-run split members\n\n'
    '- Membres : ${people.length}\n'
    '- Documents publics : ${publicDocs.length}\n'
    '- Documents privés : ${privateDocs.length}\n'
    '- Erreurs P0 : $p0Count\n'
    '- Erreurs P1 : $p1Count\n'
    '- Digest : `$projectionDigest`\n'
    '- Écriture distante : non\n\n'
    'Verdict : **${p0Count == 0 && p1Count == 0 ? 'DRY-RUN VALIDÉ' : 'DRY-RUN BLOQUÉ'}**\n',
  );
  stdout.writeln(jsonEncode(report));
  if (p0Count > 0 || p1Count > 0) {
    exitCode = 1;
  }
}

Map<String, Object?> _publicProjection(
  Map<String, dynamic> p,
  String familyId,
) {
  final birthDate = '${p['birthDate'] ?? ''}';
  final year = RegExp(r'^(\d{4})').firstMatch(birthDate)?.group(1);
  return {
    'id': p['id'],
    'familyId': familyId,
    'firstName': p['firstName'] ?? '',
    'lastName': p['lastName'] ?? '',
    'gender': p['gender'] ?? '',
    'fatherId': p['fatherId'] ?? '',
    'motherId': p['motherId'] ?? '',
    'spouseIds': _strings(p['spouseIds']),
    'childrenIds': _strings(p['childrenIds']),
    'parents': _strings(p['parents']),
    'spouses': _strings(p['spouses']),
    'children': _strings(p['children']),
    if (year != null) 'birthYear': int.parse(year),
    'birthCity': p['birthCity'] ?? '',
    'isDeceased': '${p['deathDate'] ?? ''}'.isNotEmpty,
    'photoUrl': '${p['photo'] ?? ''}'.isEmpty ? null : p['photo'],
    'generation': p['generation'] ?? 0,
    'schemaVersion': 2,
    'deletedAt': p['deletedAt'] ?? '',
  };
}

Map<String, Object?> _privateProjection(
  Map<String, dynamic> p,
  String familyId,
) => {
  'memberId': p['id'],
  'familyId': familyId,
  'ownerUid': null,
  'fullBirthDate': p['birthDate'] ?? '',
  'email': p['email'] ?? '',
  'phone': p['phoneNumber'] ?? '',
  'whatsapp': p['whatsappNumber'] ?? '',
  'fullAddress': p['currentAddress'] ?? '',
  'privateNotes': p['notes'] ?? '',
  'visibilitySettings': p['privacy'] ?? <String, Object?>{},
  'schemaVersion': 2,
};

List<List<String>> _cycles(List<Map<String, dynamic>> people) {
  final graph = {
    for (final p in people) '${p['id']}': _strings(p['childrenIds']),
  };
  final visiting = <String>{};
  final visited = <String>{};
  final cycles = <List<String>>[];
  void visit(String id, List<String> path) {
    if (visiting.contains(id)) {
      cycles.add([...path, id]);
      return;
    }
    if (!visited.add(id)) {
      return;
    }
    visiting.add(id);
    for (final child in graph[id] ?? const <String>[]) {
      visit(child, [...path, id]);
    }
    visiting.remove(id);
  }

  for (final id in graph.keys) {
    visit(id, const []);
  }
  return cycles;
}

List<String> _strings(Object? value) => (value as List? ?? const [])
    .map((item) => '$item')
    .where((item) => item.isNotEmpty)
    .toList();
Map<String, Object?> _issue(String severity, String code, String detail) => {
  'severity': severity,
  'code': code,
  'detail': detail,
};
Map<String, String> _arguments(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--')) {
      continue;
    }
    final key = args[i].substring(2);
    if ([
      'apply',
      'dry-run',
      'confirm-staging',
      'backup-validated',
    ].contains(key)) {
      result[key] = 'true';
    } else if (i + 1 < args.length) {
      result[key] = args[++i];
    }
  }
  return result;
}

void _refuseServiceAccounts(Directory root) {
  if (root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .any((f) => f.path.endsWith('.service-account.json'))) {
    throw StateError('Compte de service détecté.');
  }
}

void _writeJson(String path, Object value) => File(
  path,
).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(value)}\n');
String _checksum(String value) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
