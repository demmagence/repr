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

  test('routine menyimpan dan memperbarui konfigurasi lengkap', () async {
    final library = await database.watchExercises().first;
    final id = await database.createRoutineTemplate(
      name: 'Upper',
      notes: 'Fokus teknik',
      exercises: [
        RoutineExerciseTemplate(
          exerciseId: library[0].id,
          notes: 'Tempo pelan',
          restSeconds: 120,
          setTypes: const ['warmUp', 'working', 'failure'],
        ),
        RoutineExerciseTemplate(
          exerciseId: library[1].id,
          restSeconds: 60,
          setTypes: const ['working', 'drop'],
        ),
      ],
    );

    var template = await database.getRoutineTemplate(id);
    expect(template.routine.notes, 'Fokus teknik');
    expect(template.exercises.map((item) => item.exerciseId), [
      library[0].id,
      library[1].id,
    ]);
    expect(template.exercises.first.restSeconds, 120);
    expect(template.exercises.first.notes, 'Tempo pelan');
    expect(template.exercises.first.setTypes, ['warmUp', 'working', 'failure']);

    await database.updateRoutineTemplate(
      id: id,
      name: 'Upper baru',
      notes: 'Urutan dibalik',
      exercises: [
        RoutineExerciseTemplate(
          exerciseId: library[1].id,
          restSeconds: 180,
          setTypes: const ['drop', 'working', 'warmUp'],
        ),
      ],
    );
    template = await database.getRoutineTemplate(id);
    expect(template.routine.name, 'Upper baru');
    expect(template.exercises, hasLength(1));
    expect(template.exercises.single.exerciseId, library[1].id);
    expect(template.exercises.single.restSeconds, 180);
    expect(template.exercises.single.setTypes, ['drop', 'working', 'warmUp']);

    final workoutId = await database.startWorkout(routineId: id);
    final workoutExercise = (await database.getWorkoutExercises(
      workoutId,
    )).single;
    expect(workoutExercise.item.restSeconds, 180);
    expect(workoutExercise.sets.map((set) => set.type), [
      'drop',
      'working',
      'warmUp',
    ]);
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
