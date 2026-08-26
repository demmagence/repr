import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/ui/greek/greek.dart';

void main() {
  testWidgets('memilih tanggal mengembalikan DateTime yang dipilih', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => GreekButton(
            label: 'Buka kalender',
            onPressed: () async {
              selected = await showGreekDatePicker(
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

    await tester.tap(find.text('BUKA KALENDER'));
    await tester.pumpAndSettle();

    expect(find.text('Agustus 2026'), findsOneWidget);

    // Tap day 20
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();

    // Tap Pilih button
    await tester.tap(find.text('PILIH'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.year, 2026);
    expect(selected!.month, 8);
    expect(selected!.day, 20);
  });

  testWidgets('batal mengembalikan null', (tester) async {
    DateTime? selected = DateTime(2026, 8, 15);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => GreekButton(
            label: 'Buka kalender',
            onPressed: () async {
              selected = await showGreekDatePicker(
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

    await tester.tap(find.text('BUKA KALENDER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BATAL'));
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });

  testWidgets('navigasi bulan dan batas firstDate / lastDate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => GreekButton(
            label: 'Buka kalender',
            onPressed: () => showGreekDatePicker(
              context: context,
              initialDate: DateTime(2026, 8, 15),
              firstDate: DateTime(2026, 8, 1),
              lastDate: DateTime(2026, 9, 30),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('BUKA KALENDER'));
    await tester.pumpAndSettle();

    expect(find.text('Agustus 2026'), findsOneWidget);

    // Pada bulan Agustus 2026 (firstDate = 2026-08-01), tombol bulan sebelumnya dinonaktifkan
    final prevIconButton = tester.widget<GreekIconButton>(
      find.byType(GreekIconButton).first,
    );
    expect(prevIconButton.onPressed, isNull);

    // Tombol bulan berikutnya aktif
    final nextIconButton = tester.widget<GreekIconButton>(
      find.byType(GreekIconButton).last,
    );
    expect(nextIconButton.onPressed, isNotNull);

    // Navigasi ke September 2026
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);

    // Pada September 2026 (lastDate = 2026-09-30), tombol bulan berikutnya sekarang dinonaktifkan
    final nextIconButtonSept = tester.widget<GreekIconButton>(
      find.byType(GreekIconButton).last,
    );
    expect(nextIconButtonSept.onPressed, isNull);

    // Tombol bulan sebelumnya kembali aktif
    final prevIconButtonSept = tester.widget<GreekIconButton>(
      find.byType(GreekIconButton).first,
    );
    expect(prevIconButtonSept.onPressed, isNotNull);
  });

  testWidgets('tanggal di luar batas firstDate/lastDate tidak dapat dipilih', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => GreekButton(
            label: 'Buka kalender',
            onPressed: () async {
              selected = await showGreekDatePicker(
                context: context,
                initialDate: DateTime(2026, 8, 15),
                firstDate: DateTime(2026, 8, 10),
                lastDate: DateTime(2026, 8, 20),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('BUKA KALENDER'));
    await tester.pumpAndSettle();

    // Hari ke-5 berada di luar batas (firstDate = 10), onTap pada InkWell adalah null
    final day5InkWell = tester.widget<InkWell>(
      find
          .ancestor(of: find.text('5').first, matching: find.byType(InkWell))
          .first,
    );
    expect(day5InkWell.onTap, isNull);

    // Tap day 5
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    // Pilih -> harus tetap tanggal initialDate (15)
    await tester.tap(find.text('PILIH'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.day, 15);
  });

  const testSizes = [Size(320, 640), Size(360, 800), Size(412, 915)];
  const testScales = [1.0, 1.3, 2.0];

  for (final size in testSizes) {
    for (final scale in testScales) {
      testWidgets(
        'kalender aman tanpa overflow pada ${size.width}x${size.height} scale $scale dan target sentuh minimal 48x48 px',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: buildGreekTheme(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Builder(
                  builder: (context) => GreekButton(
                    label: 'Buka kalender',
                    onPressed: () => showGreekDatePicker(
                      context: context,
                      initialDate: DateTime(2026, 8, 15),
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime(2026, 12, 31),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('BUKA KALENDER'));
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow pada $size scale $scale',
          );

          // Verifikasi tombol aksi minimal 48 px
          final batalButton = find.widgetWithText(GreekButton, 'BATAL');
          expect(batalButton, findsOneWidget);
          final batalSize = tester.getSize(batalButton);
          expect(
            batalSize.height,
            greaterThanOrEqualTo(48),
            reason: 'Tinggi tombol Batal < 48 pada $size scale $scale',
          );

          final pilihButton = find.widgetWithText(GreekButton, 'PILIH');
          expect(pilihButton, findsOneWidget);
          final pilihSize = tester.getSize(pilihButton);
          expect(
            pilihSize.height,
            greaterThanOrEqualTo(48),
            reason: 'Tinggi tombol Pilih < 48 pada $size scale $scale',
          );

          // Verifikasi chevron icons target sentuh 48x48
          final chevronLeftSize = tester.getSize(
            find.byType(GreekIconButton).first,
          );
          expect(chevronLeftSize.width, greaterThanOrEqualTo(48));
          expect(chevronLeftSize.height, greaterThanOrEqualTo(48));

          // Verifikasi setiap cell tanggal memiliki target sentuh minimal 48x48 px
          final dateCellInkWell = find.ancestor(
            of: find.text('15'),
            matching: find.byType(InkWell),
          );
          expect(dateCellInkWell, findsWidgets);
          final cellTargetSize = tester.getSize(dateCellInkWell.first);
          expect(
            cellTargetSize.width,
            greaterThanOrEqualTo(48),
            reason: 'Lebar cell tanggal < 48 pada $size scale $scale',
          );
          expect(
            cellTargetSize.height,
            greaterThanOrEqualTo(48),
            reason: 'Tinggi cell tanggal < 48 pada $size scale $scale',
          );
        },
      );
    }
  }
}
