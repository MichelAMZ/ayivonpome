class AdminKpi {
  const AdminKpi({
    required this.totalPeople,
    required this.peopleAddedThisMonth,
    required this.peopleModifiedThisMonth,
    required this.linkedFamilies,
    required this.pendingFamilyLinks,
    required this.activeCodes,
    required this.expiredCodes,
    required this.adminActions,
    required this.adminContactRequests,
  });

  final int totalPeople;
  final int peopleAddedThisMonth;
  final int peopleModifiedThisMonth;
  final int linkedFamilies;
  final int pendingFamilyLinks;
  final int activeCodes;
  final int expiredCodes;
  final int adminActions;
  final int adminContactRequests;
}
