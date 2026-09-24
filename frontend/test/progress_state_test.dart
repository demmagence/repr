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
    expect(chart.data.lineBarsData.single.spots, hasLength(3));
    expect(find.text('60.0 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(database.close);
  });
}
