import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/location_filter.dart';

final treeFilterProvider =
    NotifierProvider<TreeFilterController, LocationFilter>(
      TreeFilterController.new,
    );

class TreeFilterController extends Notifier<LocationFilter> {
  @override
  LocationFilter build() => const LocationFilter();

  void setFilter(LocationFilter filter) {
    state = filter;
  }

  void clearFilters() {
    state = const LocationFilter();
  }
}
