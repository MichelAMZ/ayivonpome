import 'package:flutter_riverpod/flutter_riverpod.dart';

final treeViewResetProvider = NotifierProvider<TreeViewResetController, int>(
  TreeViewResetController.new,
);

class TreeViewResetController extends Notifier<int> {
  @override
  int build() => 0;

  void requestReset() {
    state++;
  }
}
