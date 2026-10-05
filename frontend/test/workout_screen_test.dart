import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/app.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<RestTimerPermissionStatus> permissionStatus() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<void> cancelRestTimer() async {}
}

void main() {
  testWidgets(
    'WorkoutScreen memuat data dan menampilkan detail tanpa stuck di loading',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      final workoutId = (await tester.runAsync(() async {
        final exercise = (await database.watchExercises().first).first;
        final id = await database.startWorkout();
        await database.addExerciseToWorkout(id, exercise.id);
        return id;
      }))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            notificationProvider.overrideWithValue(_NoopNotificationService()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: WorkoutScreen(id: workoutId),
          ),
        ),
      );

      // Pompa awal untuk memuat data stream
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Memastikan bukan loading spinner, melainkan konten workout
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Latihan kosong'), findsOneWidget);
      expect(find.byType(WorkoutExerciseCard), findsOneWidget);

      // Simulasikan berjalannya waktu (ticker memanggil setState)
      await tester.pump(const Duration(seconds: 2));

      // Tetap tidak kembali ke loading spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Latihan kosong'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'Rest timer menampilkan tombol -30s, +30s, dan Skip yang berfungsi',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      final workoutId = (await tester.runAsync(() async {
        final id = await database.startWorkout();
        final now = DateTime.now();
        await database.setRestEnd(id, now.add(const Duration(seconds: 90)));
        return id;
      }))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            notificationProvider.overrideWithValue(_NoopNotificationService()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: WorkoutScreen(id: workoutId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('REST TIMER'), findsOneWidget);
      expect(find.text('-30s'), findsOneWidget);
      expect(find.text('+30s'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap +30s
      await tester.tap(find.text('+30s'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var current = await database.getActiveWorkout();
      expect(current?.restEndsAt, isNotNull);

      // Tap -30s
      await tester.tap(find.text('-30s'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      current = await database.getActiveWorkout();
      expect(current?.restEndsAt, isNotNull);

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final finalWorkout = await database.getActiveWorkout();
      expect(finalWorkout?.restEndsAt, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'AppStatCard dan dialog Workout selesai responsif pada layar sempit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: AppDialog(
                title: 'Workout selesai',
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                actions: [
                  AppButton(
                    label: 'Lihat riwayat',
                    expand: false,
                    onPressed: () {},
                  ),
                ],
                child: const Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'Durasi',
                        value: '251 mnt',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: AppStatCard(
                        label: 'Set',
                        value: '3',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: AppStatCard(
                        label: 'Volume',
                        value: '20 kg',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Workout selesai'), findsOneWidget);
      expect(find.text('251 mnt'), findsOneWidget);
      expect(find.text('Durasi'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('20 kg'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
