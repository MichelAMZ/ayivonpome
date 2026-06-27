import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/info_news.dart';
import 'package:ayivonpome/services/history_cleanup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletes only send logs older than 90 days', () {
    final now = DateTime(2026, 6, 27, 12);
    final oldDate = now.subtract(const Duration(days: 91)).toIso8601String();
    final recentDate = now.subtract(const Duration(days: 90)).toIso8601String();
    final data = FamilyTreeData(
      infoNews: const [
        InfoNews(id: 'news1', title: 'Info', message: 'Message'),
      ],
      infoNewsSendLogs: [
        InfoNewsSendLog(
          id: 'old',
          infoNewsId: 'news1',
          contactPersonId: 'p1',
          contactName: 'Old Contact',
          contactPhone: '+22890000001',
          date: oldDate,
          createdAt: oldDate,
        ),
        InfoNewsSendLog(
          id: 'recent',
          infoNewsId: 'news1',
          contactPersonId: 'p2',
          contactName: 'Recent Contact',
          contactPhone: '+22890000002',
          date: recentDate,
          createdAt: recentDate,
        ),
      ],
    );

    final result = const HistoryCleanupService().deleteEntriesOlderThan90Days(
      data,
      now: now,
    );

    expect(result.deletedCount, 1);
    expect(result.retainedCount, 1);
    expect(result.data.infoNews.single.id, 'news1');
    expect(result.data.infoNewsSendLogs.single.id, 'recent');
    expect(result.data.infoNewsSendHistoryLastCleanedAt, now.toIso8601String());
  });
}
