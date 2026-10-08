import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/app.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

void main() {
  testWidgets('grafik progres merender banyak titik tanpa overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    final database = AppDatabase(NativeDatabase.memory());

    await tester.runAsync(() async {
      final exercise = (await database.watchExercises().first).first;
      for (var index = 0; index < 3; index++) {
        final workoutId = await database.startWorkout();
        await database.addExerciseToWorkout(workoutId, exercise.id);
        final view = (await database.getWorkoutExercises(workoutId)).single;
        await database.updateWorkoutSet(
          id: view.sets.first.id,
          weightGrams: 50000 + index * 5000,
          reps: 8,
          completed: true,
        );
        await database.finishWorkout(workoutId);
        await database.updateWorkoutDate(
          workoutId,
          DateTime.now().subtract(Duration(days: (2 - index) * 30)),
        );
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ProgressScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LineChart), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots, hasLength(greaterThanOrEqualTo(3)));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(database.close);
  });

  testWidgets(
    'filter periode 1M, 3M, 6M, 1Y mengubah delta, target sesi, dan data grafik',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      final database = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const ProgressScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Default: 3M
      expect(find.textContaining('3M Delta'), findsOneWidget);
      expect(find.text('Optimal 0/38 Sessions'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W8'), findsOneWidget);

      // Tap 1M
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1M Delta'), findsOneWidget);
      expect(find.text('Optimal 0/13 Sessions'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W4'), findsOneWidget);
      expect(find.text('W8'), findsNothing);

      // Tap 6M
      await tester.tap(find.text('6M'));
      await tester.pumpAndSettle();

      expect(find.textContaining('6M Delta'), findsOneWidget);
      expect(find.text('Optimal 0/76 Sessions'), findsOneWidget);
      expect(find.text('M1'), findsOneWidget);
      expect(find.text('M6'), findsOneWidget);

      // Tap 1Y
      await tester.tap(find.text('1Y'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1Y Delta'), findsOneWidget);
      expect(find.text('Optimal 0/156 Sessions'), findsOneWidget);
      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('Q4'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
    },
  );
}
