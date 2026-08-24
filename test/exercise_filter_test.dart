import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/app.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/greek/greek.dart';

void main() {
  late AppDatabase database;
  late List<Exercise> exercises;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    exercises = await database.watchExercises().first;
  });

  tearDown(() => database.close());

  test('filter library menggabungkan pencarian, otot, dan peralatan', () {
    final result = filterExerciseLibrary(
      exercises,
      query: 'press',
      muscle: 'Dada',
      equipment: 'Barbell',
    );

    expect(result.map((item) => item.name), contains('Bench Press'));
    expect(
      result.every(
        (item) =>
            item.name.toLowerCase().contains('press') &&
            item.muscle == 'Dada' &&
            item.equipment == 'Barbell',
      ),
      isTrue,
    );
  });

  test('filter kosong menampilkan seluruh library aktif', () {
    expect(filterExerciseLibrary(exercises), hasLength(exercises.length));
  });

  test('kombinasi filter tanpa hasil mengembalikan daftar kosong', () {
    expect(
      filterExerciseLibrary(exercises, query: 'deadlift', muscle: 'Dada'),
      isEmpty,
    );
  });

  testWidgets('pemilih exercise menyediakan filter otot dan peralatan', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: buildGreekTheme(),
          home: Consumer(
            builder: (context, ref, _) => GreekButton(
              label: 'Pilih exercise',
              onPressed: () => showExercisePicker(context, ref),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('PILIH EXERCISE'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exercise-muscle-filter')), findsOneWidget);
    expect(find.byKey(const Key('exercise-equipment-filter')), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-muscle-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dada').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise-equipment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell').last);
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Bench Press'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
