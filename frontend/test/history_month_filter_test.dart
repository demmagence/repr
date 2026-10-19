import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repr/app.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'HistoryScreen filter bulan membuka bottom sheet dan memfilter latihan sesuai bulan yang dipilih',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      // Seed 2 workouts in different months
      await tester.runAsync(() async {
        final exercises = await database.watchExercises().first;
        final ex1 = exercises.first;

        // Workout 1: Januari 2026
        final r1 = await database.createRoutineTemplate(
          name: 'Workout Januari',
          exercises: [
            RoutineExerciseTemplate(
              exerciseId: ex1.id,
              setTypes: const ['working'],
            ),
          ],
        );
        final id1 = await database.startWorkout(routineId: r1);
        final v1 = (await database.getWorkoutExercises(id1)).single;
        await database.updateWorkoutSet(
          id: v1.sets.first.id,
          weightGrams: 50000,
          reps: 10,
          completed: true,
        );
        await database.finishWorkout(id1);
        await database.updateWorkoutDate(id1, DateTime(2026, 1, 15, 10, 0));

        // Workout 2: Oktober 2026
        final r2 = await database.createRoutineTemplate(
          name: 'Workout Oktober',
          exercises: [
            RoutineExerciseTemplate(
              exerciseId: ex1.id,
              setTypes: const ['working'],
            ),
          ],
        );
        final id2 = await database.startWorkout(routineId: r2);
        final v2 = (await database.getWorkoutExercises(id2)).single;
        await database.updateWorkoutSet(
          id: v2.sets.first.id,
          weightGrams: 60000,
          reps: 8,
          completed: true,
        );
        await database.finishWorkout(id2);
        await database.updateWorkoutDate(id2, DateTime(2026, 10, 10, 15, 0));
      });

      final router = GoRouter(
        initialLocation: '/history',
        routes: [
          GoRoute(
            path: '/history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/history/:id',
            builder: (_, state) =>
                Text('Detail: ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both workouts should be visible
      expect(find.text('Workout Januari'), findsOneWidget);
      expect(find.text('Workout Oktober'), findsOneWidget);

      // Verify month filter button exists
      final filterPill = find.byKey(const Key('history-month-filter'));
      expect(filterPill, findsOneWidget);

      // 1. Tap the month filter pill to open month selector bottom sheet
      await tester.tap(filterPill);
      await tester.pumpAndSettle();

      expect(find.text('Pilih Bulan'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Semua Bulan'), findsOneWidget);

      // 2. Select Januari (month 1)
      final janButton = find.byKey(const Key('history-month-1'));
      expect(janButton, findsOneWidget);
      await tester.tap(janButton);
      await tester.pumpAndSettle();

      // Only Workout Januari should be visible
      expect(find.text('Workout Januari'), findsOneWidget);
      expect(find.text('Workout Oktober'), findsNothing);

      // Filter pill shows clear button
      final clearBtn = find.byKey(const Key('history-clear-month-filter'));
      expect(clearBtn, findsOneWidget);

      // 3. Tap clear button to reset filter
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Both workouts visible again
      expect(find.text('Workout Januari'), findsOneWidget);
      expect(find.text('Workout Oktober'), findsOneWidget);

      // 4. Select a month with no workouts (Maret / month 3)
      await tester.tap(find.byKey(const Key('history-month-filter')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-month-3')));
      await tester.pumpAndSettle();

      // Empty state shown
      expect(find.textContaining('Tidak ada riwayat latihan pada Maret'), findsOneWidget);
      expect(find.text('Tampilkan Semua Riwayat'), findsOneWidget);

      // 5. Tap "Tampilkan Semua Riwayat" to reset
      await tester.tap(find.text('Tampilkan Semua Riwayat'));
      await tester.pumpAndSettle();

      expect(find.text('Workout Januari'), findsOneWidget);
      expect(find.text('Workout Oktober'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(database.close);
    },
  );
}
