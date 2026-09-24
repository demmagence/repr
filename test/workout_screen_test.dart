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
}
