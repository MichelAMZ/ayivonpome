import 'package:ayivonpome/widgets/info_news_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widths = <double>[1920, 1440, 1280, 1024, 768, 375];
  const longMessage =
      'Bienvenue — consultez les dernières informations de la famille et découvrez toutes les actualités importantes publiées par le conseil familial.';

  for (final width in widths) {
    testWidgets('information bar has no overflow at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_testApp(message: longMessage, onClose: () {}));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text(longMessage), findsOneWidget);
      expect(find.byTooltip('Fermer le message'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('close button remains accessible and closes the bar', (
    tester,
  ) async {
    await tester.pumpWidget(const _DismissibleTestBar());

    await tester.tap(find.byTooltip('Fermer le message'));
    await tester.pump();

    expect(find.byType(ResponsiveInfoMessageBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short message and large text scale remain responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(message: 'Information familiale.', textScaleFactor: 1.5),
    );

    expect(find.text('Information familiale.'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required String message,
  VoidCallback? onClose,
  double textScaleFactor = 1,
}) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: ResponsiveInfoMessageBar(
        message: message,
        onClose: onClose ?? () {},
      ),
    ),
  ),
);

class _DismissibleTestBar extends StatefulWidget {
  const _DismissibleTestBar();

  @override
  State<_DismissibleTestBar> createState() => _DismissibleTestBarState();
}

class _DismissibleTestBarState extends State<_DismissibleTestBar> {
  var visible = true;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: visible
          ? ResponsiveInfoMessageBar(
              message: 'Message à fermer',
              onClose: () => setState(() => visible = false),
            )
          : const SizedBox.shrink(),
    ),
  );
}
