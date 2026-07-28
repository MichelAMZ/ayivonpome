import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tree connectors use the accessible high-contrast stroke style', () {
    final source = File(
      'lib/widgets/family_tree_canvas.dart',
    ).readAsStringSync();
    final painter = source.substring(
      source.indexOf('class _TreeConnectorPainter'),
      source.indexOf('class _TreeGridPainter'),
    );

    expect(painter, contains('_connectorStrokeWidth = 4.0'));
    expect(painter, contains('..strokeCap = StrokeCap.round'));
    expect(painter, contains('..strokeJoin = StrokeJoin.round'));
    expect(painter, contains('const dashWidth = 12.0'));
    expect(painter, contains('const dashGap = 6.0'));
    expect(
      painter,
      contains('_drawDashedLine(canvas, start, end, traditionalMarriage)'),
    );
    expect(painter, isNot(contains('strokeWidth = 1.35')));
    expect(painter, isNot(contains('strokeWidth = 1.25')));
    expect(painter, isNot(contains('strokeWidth = 1.7')));
  });
}
