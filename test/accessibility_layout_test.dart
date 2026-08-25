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

  const sizes = [Size(320, 640), Size(360, 800), Size(412, 915)];
  const scales = [1.0, 1.3, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets(
        'halaman utama tidak overflow pada ${size.width}x${size.height} scale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          final database = AppDatabase(NativeDatabase.memory());
          final workoutId = (await tester.runAsync(database.startWorkout))!;
          final pages = <String, Widget>{
            'Latihan': const TrainingScreen(),
            'Workout': WorkoutScreen(id: workoutId),
            'Riwayat': const HistoryScreen(),
            'Progres': const ProgressScreen(),
            'Pengaturan': const SettingsScreen(),
          };

          for (final page in pages.entries) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  databaseProvider.overrideWithValue(database),
                  notificationProvider.overrideWithValue(
                    _NoopNotificationService(),
                  ),
                ],
                child: MaterialApp(
                  theme: buildGreekTheme(),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: page.value,
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.key} overflow pada $size scale $scale',
            );
          }

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
          await tester.runAsync(database.close);
        },
      );
    }
  }
}
