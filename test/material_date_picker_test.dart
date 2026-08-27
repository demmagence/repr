import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/ui/material/app_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('id', 'ID'),
  supportedLocales: const [Locale('id', 'ID')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('date picker Material memilih tanggal', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => AppButton(
            label: 'Buka kalender',
            onPressed: () async {
              selected = await showAppDatePicker(
                context: context,
                initialDate: DateTime(2026, 8, 15),
                firstDate: DateTime(2026, 1, 1),
                lastDate: DateTime(2026, 12, 31),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka kalender'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.textContaining('Agustus'), findsOneWidget);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(selected, DateTime(2026, 8, 20));
  });

  testWidgets('date picker Material dapat dibatalkan', (tester) async {
    DateTime? selected = DateTime(2026, 8, 15);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => AppButton(
            label: 'Buka kalender',
            onPressed: () async {
              selected = await showAppDatePicker(
                context: context,
                initialDate: DateTime(2026, 8, 15),
                firstDate: DateTime(2026, 1, 1),
                lastDate: DateTime(2026, 12, 31),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka kalender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });

  for (final size in const [Size(320, 640), Size(360, 800), Size(412, 915)]) {
    testWidgets('date picker aman pada ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => AppButton(
              label: 'Buka kalender',
              onPressed: () => showAppDatePicker(
                context: context,
                initialDate: DateTime(2026, 8, 15),
                firstDate: DateTime(2026, 1, 1),
                lastDate: DateTime(2026, 12, 31),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka kalender'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  }
}
