import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/ui/material/app_ui.dart';

void main() {
  test('tema memakai konfigurasi standar Material 3', () {
    final theme = buildAppTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, isNotNull);
    expect(theme.cardTheme.shape, isNull);
    expect(theme.navigationBarTheme.height, isNull);
    expect(theme.inputDecorationTheme.border, isNull);
  });

  testWidgets('shell hanya merender komponen Material standar', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const AppPageShell(
          topBar: AppTopBar(title: 'Repr'),
          body: AppCard(child: AppListRow(title: 'Routine')),
        ),
      ),
    );

    expect(find.text('Repr'), findsOneWidget);
    expect(find.text('Routine'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
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
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => AppButton(
              label: 'Buka pilihan',
              onPressed: () => showAppActionSheet<int>(
                context: context,
                title: 'Pilih RPE',
                actions: List.generate(
                  19,
                  (index) =>
                      AppAction(value: index, label: 'Pilihan ${index + 1}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka pilihan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih RPE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Pilihan 19'), findsOneWidget);
  });

  testWidgets('kontrol interaktif memiliki target sentuh minimal 48 px', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                key: const Key('compact-button'),
                label: 'Aksi',
                onPressed: () {},
              ),
              AppTextField(
                key: const Key('text-field'),
                hint: 'Input',
                onChanged: (_) {},
              ),
              AppSegmentedControl<int>(
                key: const Key('segments'),
                segments: const [
                  AppSegment(value: 1, label: 'Satu'),
                  AppSegment(value: 2, label: 'Dua'),
                ],
                value: 1,
                onChanged: (_) {},
              ),
              AppToggle(
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
