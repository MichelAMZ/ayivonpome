import 'package:ayivonpome/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FamilyTreeApp builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyTreeApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
