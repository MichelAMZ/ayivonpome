import '../models/family_tree_data.dart';
import '../models/info_news.dart';
import '../models/person.dart';

class InfoNewsService {
  const InfoNewsService();

  List<InfoNews> activeNews(FamilyTreeData data) {
    final now = DateTime.now();
    final items = data.infoNews.where((item) {
      if (!item.isActive) return false;
      final start = DateTime.tryParse(item.startAt);
      final end = DateTime.tryParse(item.endAt);
      if (start != null && now.isBefore(start)) return false;
      if (end != null && now.isAfter(end)) return false;
      return item.title.trim().isNotEmpty || item.message.trim().isNotEmpty;
    }).toList()..sort((a, b) => b.priority.compareTo(a.priority));
    return items;
  }

  List<Person> contactTargets(FamilyTreeData data) {
    return data.people.where((person) {
      if (!person.allowContact) return false;
      return person.whatsappNumber.trim().isNotEmpty ||
          person.phoneNumber.trim().isNotEmpty;
    }).toList();
  }

  String contactPhone(Person person) {
    final whatsapp = person.whatsappNumber.trim();
    return whatsapp.isNotEmpty ? whatsapp : person.phoneNumber.trim();
  }

  String whatsappMessage(InfoNews news) {
    return [
      news.title.trim(),
      news.message.trim(),
    ].where((value) => value.isNotEmpty).join('\n\n');
  }
}
