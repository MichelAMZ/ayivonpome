import 'dart:convert';
import 'dart:io';

const productionProjectId = 'ayivon-aziangbede';

void main(List<String> args) {
  final options = _arguments(args);
  if (options.containsKey('apply')) {
    stderr.writeln(
      'REFUS: cet outil local ne réalise aucune écriture distante.',
    );
    exitCode = 2;
    return;
  }
  final inputPath = options['input'] ?? 'assets/data/family_tree.json';
  final outputPath =
      options['output'] ?? 'migration_output/staging_anonymized.json';
  final reportPath =
      options['report'] ?? 'migration_output/anonymization_report.json';
  final targetProject = options['target-project'] ?? '';
  if (targetProject == productionProjectId) {
    throw StateError(
      'La production est interdite comme cible d’anonymisation.',
    );
  }
  _refuseServiceAccounts(Directory.current);
  final sourceFile = File(inputPath);
  final source =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  final people = (source['people'] as List? ?? const [])
      .whereType<Map>()
      .map((value) => Map<String, dynamic>.from(value))
      .toList();
  const sensitiveKeys = {
    'email',
    'phoneNumber',
    'whatsappNumber',
    'currentAddress',
    'currentCity',
    'currentRegion',
    'currentCountry',
    'latitude',
    'longitude',
    'notes',
    'history',
    'importantPlaces',
    'birthDate',
    'birthPlace',
    'deathDate',
    'deathPlace',
    'burialPlace',
  };
  var changedFields = 0;
  final anonymizedPeople = people.map((person) {
    final result = Map<String, dynamic>.from(person);
    for (final key in sensitiveKeys) {
      if (!result.containsKey(key)) {
        continue;
      }
      changedFields++;
      final value = result[key];
      result[key] = value is List
          ? <Object?>[]
          : value is num
          ? null
          : '';
    }
    result['stagingData'] = true;
    return result;
  }).toList();
  final output = {...source, 'people': anonymizedPeople, 'stagingData': true};
  _writeJson(outputPath, output);
  _writeJson(reportPath, {
    'mode': 'dry-run-local-output',
    'source': sourceFile.absolute.path,
    'output': File(outputPath).absolute.path,
    'sourceOverwritten': false,
    'targetProject': targetProject.isEmpty ? null : targetProject,
    'memberCount': people.length,
    'changedSensitiveFields': changedFields,
    'publicIdentifiersPreserved': true,
    'remoteWritePerformed': false,
  });
  stdout.writeln(
    'Anonymisation locale: ${people.length} membres, $changedFields champs masqués.',
  );
}

Map<String, String> _arguments(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final value = args[i];
    if (!value.startsWith('--')) {
      continue;
    }
    final key = value.substring(2);
    if (key == 'apply' || key == 'dry-run') {
      result[key] = 'true';
    } else if (i + 1 < args.length) {
      result[key] = args[++i];
    }
  }
  return result;
}

void _refuseServiceAccounts(Directory root) {
  final found = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.service-account.json'))
      .take(1);
  if (found.isNotEmpty) {
    throw StateError('Compte de service détecté dans le dépôt.');
  }
}

void _writeJson(String path, Object value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}
