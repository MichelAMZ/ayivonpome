import 'package:ayivonpome/services/app_error_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts the first application frame without inventing a line', () {
    final frame = AppErrorLogger.parseRelevantStackFrame(
      StackTrace.fromString(
        '#0 Firebase.run (package:flutter/src/test.dart:2:3)\n'
        '#1 FamilyRepository.updateMember '
        '(package:ayivonpome/services/family_firestore_repository.dart:142:9)',
      ),
    );

    expect(frame.methodName, 'FamilyRepository.updateMember');
    expect(frame.sourceFile, 'lib/services/family_firestore_repository.dart');
    expect(frame.sourceLine, 142);
    expect(frame.sourceColumn, 9);
  });

  test('keeps source information null when the stack is unavailable', () {
    final frame = AppErrorLogger.parseRelevantStackFrame(
      StackTrace.fromString('stack unavailable'),
    );

    expect(frame.sourceFile, isNull);
    expect(frame.sourceLine, isNull);
  });

  test('sanitizes secrets and personal identifiers', () {
    final message = AppErrorLogger.sanitizeErrorMessage(
      'password=secret token:abc user@example.com +228 90 12 34 56',
    );

    expect(message, isNot(contains('secret')));
    expect(message, isNot(contains('abc')));
    expect(message, isNot(contains('user@example.com')));
    expect(message, isNot(contains('90 12 34 56')));
  });

  test('limits stack trace size and line count', () {
    final stack = List.generate(100, (index) => 'frame $index').join('\n');
    final sanitized = AppErrorLogger.sanitizeStackTrace(stack);

    expect(sanitized.split('\n').length, lessThanOrEqualTo(40));
    expect(sanitized, isNot(contains('frame 99')));
  });
}
