import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repr/app.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/greek/greek.dart';

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
          theme: buildGreekTheme(),
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'ekspor dan impor aktif saat tidak ada workout aktif',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await pumpSettings(tester, database: database);

      expect(find.text('Ekspor backup'), findsOneWidget);
      expect(find.text('Simpan seluruh data sebagai JSON'), findsOneWidget);
      expect(find.text('Impor backup'), findsOneWidget);
      expect(find.text('Ganti data dari file backup Repr'), findsOneWidget);

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();
      expect(opacities.contains(0.5), isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'ekspor dan impor dinonaktifkan secara reaktif dengan subtitle dan opacity saat ada workout aktif',
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

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((w) => w.opacity == 0.5)
          .toList();
      expect(opacities.length, greaterThanOrEqualTo(2));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'mengetuk ekspor backup saat workout aktif menampilkan pesan larangan',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(database.startWorkout);
      await pumpSettings(tester, database: database);

      await tester.tap(find.text('Ekspor backup'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Selesaikan atau buang workout aktif terlebih dahulu.'),
        findsOneWidget,
      );

      // Wait for toast auto-dismiss timer
      await tester.pump(const Duration(milliseconds: 3500));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );

  testWidgets(
    'mengetuk impor backup saat workout aktif menampilkan pesan larangan',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(database.startWorkout);
      await pumpSettings(tester, database: database);

      await tester.tap(find.text('Impor backup'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Selesaikan atau buang workout aktif terlebih dahulu.'),
        findsOneWidget,
      );

      // Wait for toast auto-dismiss timer
      await tester.pump(const Duration(milliseconds: 3500));

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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
