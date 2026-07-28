import 'package:ayivonpome/widgets/family_tree_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('horizontal connector reaches a parent left of all children', () {
    final span = familyConnectorHorizontalSpan(
      parentX: 80,
      childXs: const [120, 180, 240],
    );

    expect(span.$1, 80);
    expect(span.$2, 240);
  });

  test('horizontal connector reaches a parent right of all children', () {
    final span = familyConnectorHorizontalSpan(
      parentX: 280,
      childXs: const [120, 180, 240],
    );

    expect(span.$1, 120);
    expect(span.$2, 280);
  });

  test(
    'horizontal connector keeps the children span when parent is inside',
    () {
      final span = familyConnectorHorizontalSpan(
        parentX: 180,
        childXs: const [120, 180, 240],
      );

      expect(span.$1, 120);
      expect(span.$2, 240);
    },
  );
}
