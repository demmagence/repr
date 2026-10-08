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

  testWidgets(
    'SettingsScreen memuat preferensi dan target tanpa seksi tampilan & aplikasi',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await pumpSettings(tester, database: database);

      expect(find.text('PREFERENSI LATIHAN'), findsOneWidget);
      expect(find.text('TARGET & BIOMETRIK'), findsOneWidget);
      expect(find.text('• SYSTEM TELEMETRY'), findsNothing);
      expect(find.text('Sinkronisasi Cloud & Sensor Aktif'), findsNothing);
      expect(find.text('TAMPILAN & APLIKASI'), findsNothing);
      expect(find.text('Palet Obsidian'), findsNothing);
      expect(find.text('Ekspor Telemetri Sesi'), findsNothing);
      expect(find.text('Impor Backup Data'), findsNothing);
      expect(find.text('Apple Health / Health Connect'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
