import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/data/database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('database baru memiliki 80 exercise dan setting default', () async {
    expect(await database.watchExercises().first, hasLength(80));
    expect(await database.getDefaultRestSeconds(), 90);
  });

  test('routine dapat dimulai dan draft bertahan di database', () async {
    final exercise = (await database.watchExercises().first).first;
    final routine = await database.createRoutine('Push day', [exercise.id]);
    final workoutId = await database.startWorkout(routineId: routine);
    final active = await database.getActiveWorkout();
    expect(active?.id, workoutId);
    final exercises = await database.getWorkoutExercises(workoutId);
    expect(exercises, hasLength(1));
    expect(exercises.first.sets, hasLength(3));
  });

  test('finish memerlukan set selesai dan membuang set kosong', () async {
    final exercise = (await database.watchExercises().first).first;
    final workoutId = await database.startWorkout();
    await database.addExerciseToWorkout(workoutId, exercise.id);
    expect(() => database.finishWorkout(workoutId), throwsStateError);
    final view = (await database.getWorkoutExercises(workoutId)).first;
    await database.updateWorkoutSet(
      id: view.sets.first.id,
      weightGrams: 50000,
      reps: 10,
      completed: true,
    );
    await database.finishWorkout(workoutId);
    expect(await database.completedSetCount(workoutId), 1);
    expect(
      (await database.getWorkoutExercises(workoutId)).first.sets,
      hasLength(1),
    );
  });

  test('backup JSON round-trip mengganti data secara transaksional', () async {
    final exercise = (await database.watchExercises().first).first;
    await database.createRoutine('Pull day', [exercise.id]);
    final source = jsonEncode(await database.exportDocument());
    await database.importJson(source);
    expect(await database.watchRoutines().first, hasLength(1));
    expect(await database.watchExercises().first, hasLength(80));
    expect(
      () => database.importJson('{"format":"lain"}'),
      throwsFormatException,
    );
  });
}
