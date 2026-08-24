import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/core/greek_theme.dart';

void main() {
  test('tema memakai palet Yunani klasik', () {
    final theme = buildGreekTheme();
    expect(theme.colorScheme.primary, GreekPalette.aegean);
    expect(theme.colorScheme.secondary, GreekPalette.terracotta);
    expect(theme.scaffoldBackgroundColor, GreekPalette.marble);
  });

  testWidgets('ornamen dan motto aman pada layar Android sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              GreekKeyBorder(),
              Padding(padding: EdgeInsets.all(12), child: GreekMottoBanner()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ΑΡΕΤΗ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
