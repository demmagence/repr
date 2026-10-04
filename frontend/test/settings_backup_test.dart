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
    tester.view.physicalSize = const Size(360, 2000);
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

    expect(find.text('Ekspor Telemetri Sesi'), findsOneWidget);
    expect(find.text('Unduh format .CSV / JSON data mentah'), findsOneWidget);
    expect(find.text('Impor Backup Data'), findsOneWidget);
    expect(find.text('Pulihkan sesi dari file JSON'), findsOneWidget);

    final exportInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Ekspor Telemetri Sesi'),
        matching: find.byType(InkWell),
      ),
    );
    final importInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Impor Backup Data'),
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
    'ekspor dan impor menampilkan snackbar saat workout aktif',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(database.startWorkout);
      await pumpSettings(tester, database: database);

      expect(find.text('Ekspor Telemetri Sesi'), findsOneWidget);
      expect(find.text('Impor Backup Data'), findsOneWidget);

      final exportInkWell = find.ancestor(
        of: find.text('Ekspor Telemetri Sesi'),
        matching: find.byType(InkWell),
      );
      final importInkWell = find.ancestor(
        of: find.text('Impor Backup Data'),
        matching: find.byType(InkWell),
      );

      await tester.tap(exportInkWell);
      await tester.pump();
      expect(find.text('Selesaikan atau buang workout aktif terlebih dahulu.'), findsOneWidget);
      // Wait for snackbar to disappear
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(importInkWell);
      await tester.pump();
      expect(find.text('Selesaikan atau buang workout aktif terlebih dahulu.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'perubahan status workout memperbarui interaksi ekspor/impor',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await pumpSettings(tester, database: database);

      final workoutId = (await tester.runAsync(database.startWorkout))!;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final exportInkWellActive = find.ancestor(
        of: find.text('Ekspor Telemetri Sesi'),
        matching: find.byType(InkWell),
      );
      
      await tester.tap(exportInkWellActive);
      await tester.pump();
      expect(find.text('Selesaikan atau buang workout aktif terlebih dahulu.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      await tester.runAsync(() => database.discardWorkout(workoutId));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final exportInkWellInactive = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Ekspor Telemetri Sesi'),
          matching: find.byType(InkWell),
        ),
      );
      expect(exportInkWellInactive.onTap, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
