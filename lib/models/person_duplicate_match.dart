import 'person.dart';

enum PersonDuplicateDecision { cancel, openExisting, saveAnyway }

class PersonDuplicateMatch {
  const PersonDuplicateMatch({
    required this.person,
    required this.reasons,
    required this.score,
  });

  final Person person;
  final List<String> reasons;
  final int score;

  bool get isStrong => score >= 100;
}
