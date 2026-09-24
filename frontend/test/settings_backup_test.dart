import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repr/app.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<RestTimerPermissionStatus> requestRestTimerPermission() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<RestTimerPermissionStatus> permissionStatus() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {}

  @override
  Future<void> cancelRestTimer() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpSettings(
    WidgetTester tester, {
    required AppDatabase database,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          notificationProvider.overrideWithValue(_NoopNotificationService()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('ekspor dan impor aktif saat tidak ada workout aktif', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await pumpSettings(tester, database: database);

    expect(find.text('Ekspor backup'), findsOneWidget);
    expect(find.text('Simpan seluruh data sebagai JSON'), findsOneWidget);
    expect(find.text('Impor backup'), findsOneWidget);
    expect(find.text('Ganti data dari file backup Repr'), findsOneWidget);

    final exportRow = tester.widget<AppListRow>(
      find.widgetWithText(AppListRow, 'Ekspor backup'),
    );
    final importRow = tester.widget<AppListRow>(
      find.widgetWithText(AppListRow, 'Impor backup'),
    );
    expect(exportRow.onTap, isNotNull);
    expect(importRow.onTap, isNotNull);

    final exportInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Ekspor backup'),
        matching: find.byType(InkWell),
      ),
    );
    final importInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Impor backup'),
        matching: find.byType(InkWell),
      ),
    );
    expect(exportInkWell.onTap, isNotNull);
    expect(importInkWell.onTap, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(database.close);
  });

  testWidgets(
    'ekspor dan impor memakai status disabled Material saat workout aktif',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(database.startWorkout);
      await pumpSettings(tester, database: database);

      expect(find.text('Ekspor backup'), findsOneWidget);
      expect(find.text('Impor backup'), findsOneWidget);
      expect(
        find.text('Selesaikan atau buang workout aktif terlebih dahulu'),
        findsNWidgets(2),
      );

      final exportRow = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Ekspor backup'),
      );
      final importRow = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Impor backup'),
      );
      expect(exportRow.onTap, isNull);
      expect(importRow.onTap, isNull);

      final exportInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Ekspor backup'),
          matching: find.byType(InkWell),
        ),
      );
      final importInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Impor backup'),
          matching: find.byType(InkWell),
        ),
      );
      expect(exportInkWell.onTap, isNull);
      expect(importInkWell.onTap, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'perubahan status workout memperbarui status ekspor/impor secara reaktif',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await pumpSettings(tester, database: database);

      expect(find.text('Simpan seluruh data sebagai JSON'), findsOneWidget);
      expect(find.text('Ganti data dari file backup Repr'), findsOneWidget);

      final workoutId = (await tester.runAsync(database.startWorkout))!;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Selesaikan atau buang workout aktif terlebih dahulu'),
        findsNWidgets(2),
      );
      final exportRowActive = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Ekspor backup'),
      );
      final importRowActive = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Impor backup'),
      );
      expect(exportRowActive.onTap, isNull);
      expect(importRowActive.onTap, isNull);

      await tester.runAsync(() => database.discardWorkout(workoutId));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Simpan seluruh data sebagai JSON'), findsOneWidget);
      expect(find.text('Ganti data dari file backup Repr'), findsOneWidget);
      expect(
        find.text('Selesaikan atau buang workout aktif terlebih dahulu'),
        findsNothing,
      );
      final exportRowInactive = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Ekspor backup'),
      );
      final importRowInactive = tester.widget<AppListRow>(
        find.widgetWithText(AppListRow, 'Impor backup'),
      );
      expect(exportRowInactive.onTap, isNotNull);
      expect(importRowInactive.onTap, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
