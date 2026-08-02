import '../models/family_tree_data.dart';
import '../models/info_news.dart';
import '../models/person.dart';

class InfoNewsService {
  const InfoNewsService();

  static const defaultInfoNewsId = '_default_info_news';

  InfoNews defaultNews(String contactName) => InfoNews(
    id: defaultInfoNewsId,
    title: '',
    message: defaultMessage(contactName),
    priority: 0,
    isActive: true,
  );

  String defaultMessage(String contactName) {
    final contact = contactName.trim().isEmpty
        ? 'Conseil de Famille'
        : contactName.trim();
    return 'Bienvenue ! Pour accéder aux fonctionnalités avancées '
        '(ajout, modification, administration), demandez votre code secret '
        'auprès du $contact.';
  }

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
    if (items.isNotEmpty) return items;
    return [defaultNews(data.appSettings.accessCodeContactName)];
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
