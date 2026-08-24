import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/ui/greek/greek.dart';

void main() {
  test('tema memakai palet Yunani klasik', () {
    final theme = buildGreekTheme();
    expect(theme.useMaterial3, isFalse);
    expect(theme.colorScheme.primary, GreekColors.aegean);
    expect(theme.colorScheme.secondary, GreekColors.terracotta);
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
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
        home: const GreekPageShell(
          body: Column(
            children: [
              GreekBrandMark(),
              Padding(padding: EdgeInsets.all(12), child: GreekMottoBanner()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ΑΡΕΤΗ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action sheet panjang dapat di-scroll pada layar sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => GreekButton(
            label: 'Buka pilihan',
            onPressed: () => showGreekActionSheet<int>(
              context: context,
              title: 'Pilih RPE',
              actions: List.generate(
                19,
                (index) =>
                    GreekAction(value: index, label: 'Pilihan ${index + 1}'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('BUKA PILIHAN'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih RPE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Pilihan 19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kontrol interaktif memiliki target sentuh minimal 48 px', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Scaffold(
          body: Column(
            children: [
              GreekButton(
                key: const Key('compact-button'),
                label: 'Aksi',
                compact: true,
                onPressed: () {},
              ),
              GreekTextField(
                key: const Key('text-field'),
                hint: 'Input',
                onChanged: (_) {},
              ),
              GreekSegmentedControl<int>(
                key: const Key('segments'),
                segments: const [
                  GreekSegment(value: 1, label: 'Satu'),
                  GreekSegment(value: 2, label: 'Dua'),
                ],
                value: 1,
                onChanged: (_) {},
              ),
              GreekToggle(
                key: const Key('toggle'),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    for (final key in const [
      Key('compact-button'),
      Key('text-field'),
      Key('segments'),
      Key('toggle'),
    ]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }
  });
}
