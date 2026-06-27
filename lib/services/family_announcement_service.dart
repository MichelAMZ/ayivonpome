import '../models/family_announcement.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';

class FamilyAnnouncementService {
  const FamilyAnnouncementService();

  static const recentBirthWindowDays = 30;

  FamilyTreeData ensureTodayBirthdayAnnouncements(
    FamilyTreeData data, {
    DateTime? now,
  }) {
    if (!data.familyAnnouncementSettings.birthdayPopupsEnabled) return data;
    final today = now ?? DateTime.now();
    final todayKey = _dateKey(today);
    final items = [...data.familyAnnouncementHistory];
    var changed = false;
    for (final person in todayBirthdays(data, now: today)) {
      final exists = items.any(
        (item) =>
            item.type == 'birthday' &&
            item.memberId == person.id &&
            item.date == todayKey,
      );
      if (exists) continue;
      items.add(
        FamilyAnnouncementHistory(
          id: 'birthday${today.microsecondsSinceEpoch}${person.id}',
          type: 'birthday',
          memberId: person.id,
          message: data.familyAnnouncementSettings.birthdayMessage,
          date: todayKey,
          createdAt: today.toIso8601String(),
        ),
      );
      changed = true;
    }
    return changed ? data.copyWith(familyAnnouncementHistory: items) : data;
  }

  FamilyTreeData addBirthAnnouncementIfNeeded(
    FamilyTreeData data,
    Person person, {
    DateTime? now,
  }) {
    if (!data.familyAnnouncementSettings.birthPopupsEnabled) return data;
    final today = now ?? DateTime.now();
    final birthDate = DateTime.tryParse(person.birthDate);
    if (birthDate == null) return data;
    final days = today.difference(birthDate).inDays;
    if (days < 0 || days > recentBirthWindowDays) return data;
    final exists = data.familyAnnouncementHistory.any(
      (item) => item.type == 'birth' && item.memberId == person.id,
    );
    if (exists) return data;
    return data.copyWith(
      familyAnnouncementHistory: [
        ...data.familyAnnouncementHistory,
        FamilyAnnouncementHistory(
          id: 'birth${today.microsecondsSinceEpoch}${person.id}',
          type: 'birth',
          memberId: person.id,
          message: data.familyAnnouncementSettings.birthMessage,
          date: _dateKey(today),
          createdAt: today.toIso8601String(),
        ),
      ],
    );
  }

  List<FamilyAnnouncementHistory> pendingPopups(FamilyTreeData data) {
    return data.familyAnnouncementHistory
        .where((item) => item.whatsappStatus == 'pending')
        .where((item) => item.type == 'birthday' || item.type == 'birth')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<Person> todayBirthdays(FamilyTreeData data, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return data.people.where((person) {
      final birthDate = DateTime.tryParse(person.birthDate);
      return birthDate != null &&
          birthDate.day == today.day &&
          birthDate.month == today.month &&
          person.deathDate.trim().isEmpty;
    }).toList();
  }

  String contactPhone(Person person) {
    final whatsapp = person.whatsappNumber.trim();
    if (whatsapp.isNotEmpty) return whatsapp;
    return person.phoneNumber.trim();
  }

  String birthdayWhatsAppMessage(Person person) {
    final firstName = person.firstName.trim().isEmpty
        ? person.fullName
        : person.firstName.trim();
    return 'Bonjour $firstName,\n'
        'La grande famille te souhaite un joyeux anniversaire.\n'
        'Que cette nouvelle année de vie soit remplie de paix, de joie, de santé et de bénédictions.';
  }

  String birthWhatsAppMessage(Person person) {
    return 'Grande nouvelle dans la famille !\n'
        'Nous accueillons avec joie ${person.fullName}, né(e) le ${_formatDate(person.birthDate)}.\n'
        'Que cette naissance apporte bonheur, paix et bénédictions à toute la famille.';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
