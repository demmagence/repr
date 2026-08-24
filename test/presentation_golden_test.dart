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

class _DeniedNotificationService extends NotificationService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {}

  @override
  Future<void> cancelRestTimer() async {}
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required AppDatabase database,
  required Widget child,
  required Size size,
  double textScale = 1,
  NotificationService? notifications,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        notificationProvider.overrideWithValue(
          notifications ?? _DeniedNotificationService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildGreekTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<String> _seedActiveWorkout(AppDatabase database) async {
  final exercise = (await database.watchExercises().first).first;
  final id = await database.startWorkout();
  await database.addExerciseToWorkout(id, exercise.id);
  return id;
}

Future<String> _seedCompletedWorkout(
  AppDatabase database, {
  int weightGrams = 60000,
  int reps = 10,
}) async {
  final exercise = (await database.watchExercises().first).first;
  final id = await database.startWorkout();
  await database.addExerciseToWorkout(id, exercise.id);
  final view = (await database.getWorkoutExercises(id)).single;
  await database.updateWorkoutSet(
    id: view.sets.first.id,
    weightGrams: weightGrams,
    reps: reps,
    rpe: 8,
    completed: true,
  );
  await database.finishWorkout(id);
  await database.updateWorkoutDate(id, DateTime(2026, 1, 15, 18, 30));
  return id;
}

void main() {
  const sizes = {
    '320x640': Size(320, 640),
    '360x800': Size(360, 800),
    '412x915': Size(412, 915),
  };

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');
  });

  Future<void> disposePage(WidgetTester tester, AppDatabase database) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(database.close);
  }

  for (final entry in sizes.entries) {
    testWidgets('golden Latihan ${entry.key}', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        final exercise = (await database.watchExercises().first).first;
        await database.createRoutineTemplate(
          name: 'Push Day',
          notes: 'Dada dan bahu',
          exercises: [
            RoutineExerciseTemplate(
              exerciseId: exercise.id,
              setTypes: const ['warmUp', 'working', 'working'],
            ),
          ],
        );
      });
      await _pumpPage(
        tester,
        database: database,
        child: const TrainingScreen(),
        size: entry.value,
      );
      await expectLater(
        find.byType(TrainingScreen),
        matchesGoldenFile('goldens/latihan-${entry.key}.png'),
      );
      await disposePage(tester, database);
    });

    testWidgets('golden Workout ${entry.key}', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final id = (await tester.runAsync(() async {
        final id = await _seedActiveWorkout(database);
        await database.setRestEnd(
          id,
          DateTime.now().add(const Duration(minutes: 1)),
        );
        return id;
      }))!;
      await _pumpPage(
        tester,
        database: database,
        child: WorkoutScreen(id: id),
        size: entry.value,
      );
      await expectLater(
        find.byType(WorkoutScreen),
        matchesGoldenFile('goldens/workout-${entry.key}.png'),
      );
      await disposePage(tester, database);
    });

    testWidgets('golden Riwayat ${entry.key}', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => _seedCompletedWorkout(database));
      await _pumpPage(
        tester,
        database: database,
        child: const HistoryScreen(),
        size: entry.value,
      );
      await expectLater(
        find.byType(HistoryScreen),
        matchesGoldenFile('goldens/riwayat-${entry.key}.png'),
      );
      await disposePage(tester, database);
    });

    testWidgets('golden Progres ${entry.key}', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => _seedCompletedWorkout(database));
      await _pumpPage(
        tester,
        database: database,
        child: const ProgressScreen(),
        size: entry.value,
      );
      await expectLater(
        find.byType(ProgressScreen),
        matchesGoldenFile('goldens/progres-${entry.key}.png'),
      );
      await disposePage(tester, database);
    });

    testWidgets('golden Pengaturan ${entry.key}', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      await _pumpPage(
        tester,
        database: database,
        child: const SettingsScreen(),
        size: entry.value,
      );
      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/pengaturan-${entry.key}.png'),
      );
      await disposePage(tester, database);
    });
  }
}
