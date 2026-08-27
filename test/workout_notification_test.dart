import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/app.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

class _DeniedNotificationService extends NotificationService {
  var permissionRequests = 0;
  var statusChecks = 0;
  var scheduleCalls = 0;

  @override
  Future<RestTimerPermissionStatus> requestRestTimerPermission() async {
    permissionRequests++;
    return const RestTimerPermissionStatus(
      notificationsGranted: false,
      exactAlarmsGranted: false,
    );
  }

  @override
  Future<RestTimerPermissionStatus> permissionStatus() async {
    statusChecks++;
    return const RestTimerPermissionStatus(
      notificationsGranted: false,
      exactAlarmsGranted: false,
    );
  }

  @override
  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {
    scheduleCalls++;
  }

  @override
  Future<void> cancelRestTimer() async {}
}

void main() {
  testWidgets(
    'set selesai tetap memulai rest timer saat izin notifikasi ditolak',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = _DeniedNotificationService();
      final seeded = (await tester.runAsync(() async {
        final exercise = (await database.watchExercises().first).first;
        final id = await database.startWorkout();
        await database.addExerciseToWorkout(id, exercise.id);
        final view = (await database.getWorkoutExercises(id)).single;
        await database.updateWorkoutSet(
          id: view.sets.first.id,
          weightGrams: 60000,
          reps: 8,
        );
        await database.updateWorkoutSet(
          id: view.sets[1].id,
          weightGrams: 60000,
          reps: 8,
        );
        return (id: id, view: (await database.getWorkoutExercises(id)).single);
      }))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            notificationProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: WorkoutExerciseCard(
                workoutId: seeded.id,
                view: seeded.view,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final completion = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Selesaikan set 1',
      );
      expect(completion, findsOneWidget);
      await tester.tap(completion);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.permissionRequests, 1);
      expect(service.scheduleCalls, 0);
      expect(
        find.text('Timer aktif di aplikasi. Izin notifikasi belum diberikan.'),
        findsOneWidget,
      );
      final active = await tester.runAsync(database.getActiveWorkout);
      expect(active?.restEndsAt, isNotNull);

      final secondCompletion = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Selesaikan set 2',
      );
      await tester.tap(secondCompletion);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.permissionRequests, 1);
      expect(service.statusChecks, 1);
      expect(
        find.text('Timer aktif di aplikasi. Izin notifikasi belum diberikan.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
