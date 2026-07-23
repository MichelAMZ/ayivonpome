import 'dart:convert';
import 'dart:io';

const _extensions = <String>{
  '.dart',
  '.json',
  '.yaml',
  '.yml',
  '.js',
  '.ts',
  '.md',
  '.html',
  '.xml',
  '.gradle',
  '.properties',
};
const _roots = <String>[
  'assets',
  'lib',
  'test',
  'docs',
  'integration_test',
  'tooling',
  'scripts',
  'web',
  'android',
  'ios',
  'windows',
];
const _allowedValues = <String>{
  '',
  'REDACTED',
  'NOT_CONFIGURED',
  'MIGRATION_REQUIRED',
  'EXAMPLE_ONLY',
  'TEST_ONLY_VALUE',
  'INVALID_TEST_CODE',
  'PLACEHOLDER_NOT_A_SECRET',
};
final _historicalPatterns = <RegExp>[
  RegExp(r'edit[-_ ]?ayivon', caseSensitive: false),
  RegExp(r'ayivonvi[0-9]{2,}', caseSensitive: false),
  RegExp(r'aziangb[^\s"\x27]{0,24}[0-9]{2,}', caseSensitive: false),
];
final _literalAssignment = RegExp(
  r'''(?:currentAdminCode|recoveryCode|adminCode|superAdminCode|modificationCode|password|clientSecret|privateKey)\s*[:=]\s*["']([^"']*)["']''',
  caseSensitive: false,
);

Future<void> main(List<String> arguments) async {
  final findings = <_Finding>[];
  final roots = [
    ..._roots,
    if (arguments.contains('--include-build')) 'build/web',
  ];
  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || !_isScannable(entity.path)) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path == 'tooling/security/check_secrets.dart') continue;
      final content = await entity.readAsString();
      _scanText(path, content, findings);
      if (path.endsWith('.json')) _scanJson(path, content, findings);
    }
  }
  if (findings.isEmpty) {
    stdout.writeln('Secret check passed: no embedded access secret found.');
    return;
  }
  for (final finding in findings) {
    stderr.writeln(
      '${finding.path}:${finding.line}: ${finding.reason}: ${_redact(finding.value)}',
    );
  }
  exitCode = 1;
}

bool _isScannable(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.contains('/.dart_tool/') ||
      normalized.contains('/.git/') ||
      normalized.contains('/node_modules/')) {
    return false;
  }
  final dot = normalized.lastIndexOf('.');
  return dot >= 0 && _extensions.contains(normalized.substring(dot));
}

void _scanText(String path, String content, List<_Finding> findings) {
  final lines = const LineSplitter().convert(content);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    for (final pattern in _historicalPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        findings.add(_Finding(path, index + 1, 'historical value', match[0]!));
      }
    }
    for (final match in _literalAssignment.allMatches(line)) {
      final value = match[1] ?? '';
      if (!_allowedValues.contains(value)) {
        findings.add(_Finding(path, index + 1, 'sensitive literal', value));
      }
    }
    if (line.contains('-----BEGIN PRIVATE KEY-----')) {
      findings.add(_Finding(path, index + 1, 'private key', 'present'));
    }
  }
}

void _scanJson(String path, String content, List<_Finding> findings) {
  Object? decoded;
  try {
    decoded = jsonDecode(content);
  } on FormatException {
    return;
  }
  void visit(Object? value, String key) {
    if (value is Map) {
      for (final entry in value.entries) {
        visit(entry.value, entry.key.toString());
      }
    } else if (value is List) {
      if ({'accessCodes', 'modificationCodes', 'codeHistory'}.contains(key) &&
          value.isNotEmpty) {
        findings.add(_Finding(path, 1, 'non-empty sensitive list', key));
      }
      for (final item in value) {
        visit(item, key);
      }
    } else if ({
          'currentAdminCode',
          'recoveryCode',
          'adminCode',
          'superAdminCode',
          'modificationCode',
          'password',
          'private_key',
          'client_secret',
        }.contains(key) &&
        value is String &&
        !_allowedValues.contains(value)) {
      findings.add(_Finding(path, 1, 'sensitive JSON value', value));
    }
  }

  visit(decoded, '');
}

String _redact(String value) => value.length <= 4
    ? '****'
    : '${value.substring(0, 2)}********${value.substring(value.length - 2)}';

class _Finding {
  const _Finding(this.path, this.line, this.reason, this.value);
  final String path;
  final int line;
  final String reason;
  final String value;
}
