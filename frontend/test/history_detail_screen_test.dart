import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repr/app.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'HistoryDetailScreen menampilkan layout lengkap: top bar, user info, stats, muscle split, dan list exercise beserta set, beban, reps',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      final workoutId = (await tester.runAsync(() async {
        final exercises = await database.watchExercises().first;
        final ex1 = exercises.first;

        final r1 = await database.createRoutineTemplate(
          name: 'Afternoon workout',
          exercises: [
            RoutineExerciseTemplate(
              exerciseId: ex1.id,
              setTypes: const ['working', 'working'],
            ),
          ],
        );
        final id = await database.startWorkout(routineId: r1);
        final v = (await database.getWorkoutExercises(id)).single;
        await database.updateWorkoutSet(
          id: v.sets[0].id,
          weightGrams: 20000,
          reps: 12,
          completed: true,
        );
        await database.updateWorkoutSet(
          id: v.sets[1].id,
          weightGrams: 25000,
          reps: 10,
          completed: true,
        );
        await database.finishWorkout(id);
        return id;
      }))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(home: HistoryDetailScreen(id: workoutId)),
        ),
      );

      // Pompa awal untuk stream dan future builder
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Top bar
      expect(find.text('Workout Detail'), findsOneWidget);

      // 2. User info & Location
      expect(find.text('stinging_rhino46310'), findsOneWidget);
      expect(find.text('OTISTA GYM'), findsOneWidget);

      // 3. Workout title
      expect(find.textContaining('Afternoon workout'), findsWidgets);

      // 4. Metric columns
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);

      // 5. Muscle Split section
      expect(find.text('Muscle Split'), findsOneWidget);

      // 6. Workout Section & Edit Workout
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Edit Workout'), findsOneWidget);

      // 7. Table headers: SET, BEBAN, REPS
      expect(find.text('SET'), findsOneWidget);
      expect(find.textContaining('BEBAN'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);

      // 8. Completed checkmarks
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
