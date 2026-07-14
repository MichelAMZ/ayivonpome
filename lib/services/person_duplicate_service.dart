import '../models/person.dart';
import '../models/person_duplicate_match.dart';

class PersonDuplicateService {
  const PersonDuplicateService();

  List<PersonDuplicateMatch> findDuplicates({
    required Person draft,
    required List<Person> people,
  }) {
    final matches = <PersonDuplicateMatch>[];
    for (final candidate in people) {
      if (candidate.id == draft.id || candidate.deletedAt.isNotEmpty) {
        continue;
      }
      final reasons = <String>[];
      var score = 0;

      if (_same(candidate.firstName, draft.firstName) &&
          _same(candidate.lastName, draft.lastName)) {
        score += 60;
        reasons.add('Même nom et prénom');
      }
      if (_filledAndSame(candidate.birthDate, draft.birthDate)) {
        score += 40;
        reasons.add('Même date de naissance');
      }
      if (_filledAndSame(candidate.birthPlace, draft.birthPlace)) {
        score += 20;
        reasons.add('Même lieu de naissance');
      }
      if (_filledAndSame(candidate.fatherId, draft.fatherId)) {
        score += 15;
        reasons.add('Même père');
      }
      if (_filledAndSame(candidate.motherId, draft.motherId)) {
        score += 15;
        reasons.add('Même mère');
      }

      if (score >= 100) {
        matches.add(
          PersonDuplicateMatch(
            person: candidate,
            reasons: reasons,
            score: score,
          ),
        );
      }
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  bool hasBlockingDuplicate({
    required Person draft,
    required List<Person> people,
  }) {
    return findDuplicates(draft: draft, people: people).isNotEmpty;
  }

  bool _filledAndSame(String first, String second) {
    return first.trim().isNotEmpty &&
        second.trim().isNotEmpty &&
        _same(first, second);
  }

  bool _same(String first, String second) {
    return _normalize(first) == _normalize(second);
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }
}
