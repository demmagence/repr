import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/data/database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('database baru memiliki 80 exercise dan setting default', () async {
    final exercises = await database.watchExercises().first;
    expect(exercises, hasLength(80));
    expect(await database.getDefaultRestSeconds(), 90);
    final bench = exercises.firstWhere((e) => e.name == 'Bench Press');
    expect(bench.bodyPart, 'Chest');
    expect(bench.target, 'Pectorals');
    expect(bench.gifUrl, isNotEmpty);
    expect(bench.instructions, isNotNull);
  });

  test('constraint database hanya mengizinkan satu workout aktif', () async {
    final outcomes = await Future.wait(
      List.generate(2, (_) async {
        try {
          return await database.startWorkout();
        } catch (error) {
          return error;
        }
      }),
    );

    expect(outcomes.whereType<String>(), hasLength(1));
    expect(outcomes.where((value) => value is! String), hasLength(1));
    await expectLater(
      database.customStatement(
        "INSERT INTO workouts (id, name, notes, status, started_at) VALUES ('forced-active', 'Paksa', '', 'active', 0)",
      ),
      throwsA(anything),
    );
    final activeCount = await database
        .customSelect(
          "SELECT COUNT(*) AS amount FROM workouts WHERE status = 'active'",
        )
        .getSingle();
    expect(activeCount.read<int>('amount'), 1);
  });

  test('migrasi schema 1 menambahkan constraint workout aktif', () async {
    await database.close();
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE workouts (
              id TEXT NOT NULL PRIMARY KEY,
              routine_id TEXT NULL,
              name TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL,
              started_at INTEGER NOT NULL,
              ended_at INTEGER NULL,
              rest_ends_at INTEGER NULL
            )
          ''');
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(legacy.close);

    final index = await legacy
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'one_active_workout_idx'",
        )
        .getSingleOrNull();

    expect(legacy.schemaVersion, 6);
    expect(index?.read<String>('name'), 'one_active_workout_idx');
  });

  test('migrasi schema 1 menyimpan draft aktif terbaru dan history', () async {
    await database.close();
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE workouts (
              id TEXT NOT NULL PRIMARY KEY,
              routine_id TEXT NULL,
              name TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL,
              started_at INTEGER NOT NULL,
              ended_at INTEGER NULL,
              rest_ends_at INTEGER NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE workout_exercises (
              id TEXT NOT NULL PRIMARY KEY,
              workout_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              rest_seconds INTEGER NOT NULL DEFAULT 90
            )
          ''');
          raw.execute('''
            CREATE TABLE workout_sets (
              id TEXT NOT NULL PRIMARY KEY,
              workout_exercise_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              type TEXT NOT NULL DEFAULT 'working',
              weight_grams INTEGER NOT NULL DEFAULT 0,
              reps INTEGER NOT NULL DEFAULT 0,
              rpe REAL NULL,
              completed INTEGER NOT NULL DEFAULT 0
            )
          ''');
          raw.execute(
            "INSERT INTO workouts VALUES ('older', NULL, 'Draft lama', '', 'active', 10, NULL, NULL)",
          );
          raw.execute(
            "INSERT INTO workouts VALUES ('newer', NULL, 'Draft terbaru', '', 'active', 20, NULL, NULL)",
          );
          raw.execute(
            "INSERT INTO workouts VALUES ('history', NULL, 'Selesai', '', 'completed', 5, 6, NULL)",
          );
          raw.execute(
            "INSERT INTO workout_exercises VALUES ('old-exercise', 'older', 'exercise', 0, '', 90)",
          );
          raw.execute(
            "INSERT INTO workout_sets VALUES ('old-set', 'old-exercise', 0, 'working', 60000, 8, NULL, 1)",
          );
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(legacy.close);

    expect((await legacy.getActiveWorkout())?.id, 'newer');
    final all = await legacy.customSelect('SELECT id FROM workouts').get();
    expect(
      all.map((row) => row.read<String>('id')),
      containsAll(['newer', 'history']),
    );
    expect(all.map((row) => row.read<String>('id')), isNot(contains('older')));
    final remainingSets = await legacy
        .customSelect('SELECT COUNT(*) AS amount FROM workout_sets')
        .getSingle();
    expect(remainingSets.read<int>('amount'), 0);
  });

  test(
    'migrasi schema 2 menambahkan kolom rich exercise dan memperkaya data',
    () async {
      await database.close();
      final legacy = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE exercises (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              muscle TEXT NOT NULL,
              equipment TEXT NOT NULL,
              is_custom INTEGER NOT NULL DEFAULT 0,
              archived INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
            raw.execute(
              "INSERT INTO exercises VALUES ('ex-1', 'Bench Press', 'Dada', 'Barbell', 0, 0, 1)",
            );
            raw.userVersion = 2;
          },
        ),
      );
      addTearDown(legacy.close);

      expect(legacy.schemaVersion, 6);
      final migrated = await (legacy.select(
        legacy.exercises,
      )..where((e) => e.id.equals('ex-1'))).getSingle();
      expect(migrated.bodyPart, 'Chest');
      expect(migrated.target, 'Pectorals');
      expect(migrated.gifUrl, isNotEmpty);
      expect(migrated.instructions, isNotNull);
    },
  );

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

  test('routine menyimpan berat dan repetisi serta mengisi workout sets saat dimulai', () async {
    final library = await database.watchExercises().first;
    final id = await database.createRoutineTemplate(
      name: 'Chest Strength',
      notes: 'Heavy bench',
      exercises: [
        RoutineExerciseTemplate(
          exerciseId: library[0].id,
          sets: const [
            RoutineSetTemplate(type: 'warmUp', weightGrams: 40000, reps: 15),
            RoutineSetTemplate(type: 'working', weightGrams: 80000, reps: 8),
            RoutineSetTemplate(type: 'failure', weightGrams: 85000, reps: 6),
          ],
        ),
      ],
    );

    final template = await database.getRoutineTemplate(id);
    expect(template.exercises.single.sets, hasLength(3));
    expect(template.exercises.single.sets[0].weightGrams, 40000);
    expect(template.exercises.single.sets[0].reps, 15);
    expect(template.exercises.single.sets[1].weightGrams, 80000);
    expect(template.exercises.single.sets[1].reps, 8);
    expect(template.exercises.single.sets[2].weightGrams, 85000);
    expect(template.exercises.single.sets[2].reps, 6);

    final workoutId = await database.startWorkout(routineId: id);
    final workoutExercise = (await database.getWorkoutExercises(workoutId)).single;
    expect(workoutExercise.sets, hasLength(3));
    expect(workoutExercise.sets[0].weightGrams, 40000);
    expect(workoutExercise.sets[0].reps, 15);
    expect(workoutExercise.sets[0].type, 'warmUp');
    expect(workoutExercise.sets[1].weightGrams, 80000);
    expect(workoutExercise.sets[1].reps, 8);
    expect(workoutExercise.sets[1].type, 'working');
    expect(workoutExercise.sets[2].weightGrams, 85000);
    expect(workoutExercise.sets[2].reps, 6);
    expect(workoutExercise.sets[2].type, 'failure');
  });

  test('finishWorkout memperbarui berat dan repetisi pada template routine asal', () async {
    final library = await database.watchExercises().first;
    final routineId = await database.createRoutineTemplate(
      name: 'Leg Day',
      notes: 'Squats',
      exercises: [
        RoutineExerciseTemplate(
          exerciseId: library[0].id,
          sets: const [
            RoutineSetTemplate(type: 'working', weightGrams: 50000, reps: 10),
            RoutineSetTemplate(type: 'working', weightGrams: 50000, reps: 10),
          ],
        ),
      ],
    );

    // Mulai workout dari routine
    final workoutId = await database.startWorkout(routineId: routineId);
    final workoutExercise = (await database.getWorkoutExercises(workoutId)).single;
    expect(workoutExercise.sets, hasLength(2));
    expect(workoutExercise.sets[0].weightGrams, 50000);
    expect(workoutExercise.sets[1].weightGrams, 50000);

    // Naikkan beban saat workout: Set 1 jadi 52.5kg x 10, Set 2 jadi 55kg x 8
    await database.updateWorkoutSet(
      id: workoutExercise.sets[0].id,
      weightGrams: 52500,
      reps: 10,
      completed: true,
    );
    await database.updateWorkoutSet(
      id: workoutExercise.sets[1].id,
      weightGrams: 55000,
      reps: 8,
      completed: true,
    );

    // Selesaikan workout
    await database.finishWorkout(workoutId);

    // Template routine harus sudah ter-update dengan beban dan reps baru
    final updatedTemplate = await database.getRoutineTemplate(routineId);
    expect(updatedTemplate.exercises.single.sets[0].weightGrams, 52500);
    expect(updatedTemplate.exercises.single.sets[0].reps, 10);
    expect(updatedTemplate.exercises.single.sets[1].weightGrams, 55000);
    expect(updatedTemplate.exercises.single.sets[1].reps, 8);

    // Saat memulai routine berikutnya, nilai baru langsung terisi otomatis
    final nextWorkoutId = await database.startWorkout(routineId: routineId);
    final nextExercise = (await database.getWorkoutExercises(nextWorkoutId)).single;
    expect(nextExercise.sets[0].weightGrams, 52500);
    expect(nextExercise.sets[0].reps, 10);
    expect(nextExercise.sets[1].weightGrams, 55000);
    expect(nextExercise.sets[1].reps, 8);
  });

  test('getLastCompletedSetForExercise mengembalikan set terakhir yang selesai', () async {
    final library = await database.watchExercises().first;
    final exerciseId = library[0].id;

    // Belum pernah latihan
    expect(await database.getLastCompletedSetForExercise(exerciseId), isNull);

    // Latihan pertama
    final wId = await database.startWorkout();
    await database.addExerciseToWorkout(wId, exerciseId);
    final view = (await database.getWorkoutExercises(wId)).single;
    await database.updateWorkoutSet(
      id: view.sets[0].id,
      weightGrams: 60000,
      reps: 12,
      completed: true,
    );
    await database.finishWorkout(wId);

    // Harusnya mengembalikan set 60kg x 12
    final lastSet = await database.getLastCompletedSetForExercise(exerciseId);
    expect(lastSet, isNotNull);
    expect(lastSet!.weightGrams, 60000);
    expect(lastSet.reps, 12);
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

  test('previous set dicocokkan berdasarkan posisi dan jenis', () async {
    final exercise = (await database.watchExercises().first).first;
    final previousWorkout = await database.startWorkout();
    await database.addExerciseToWorkout(previousWorkout, exercise.id);
    final previousView = (await database.getWorkoutExercises(
      previousWorkout,
    )).single;
    const previousTypes = ['warmUp', 'working', 'failure'];
    for (var index = 0; index < previousView.sets.length; index++) {
      await database.updateWorkoutSet(
        id: previousView.sets[index].id,
        type: previousTypes[index],
        weightGrams: (index + 1) * 10000,
        reps: 10 - index,
        completed: true,
      );
    }
    await database.finishWorkout(previousWorkout);

    final currentWorkout = await database.startWorkout();
    await database.addExerciseToWorkout(currentWorkout, exercise.id);
    final currentView = (await database.getWorkoutExercises(
      currentWorkout,
    )).single;
    await database.updateWorkoutSet(
      id: currentView.sets[2].id,
      type: 'failure',
    );
    final matches = await database.previousSetMatches(
      exercise.id,
      currentWorkout,
      currentView.item.id,
    );

    expect(matches.containsKey(currentView.sets[0].id), isFalse);
    expect(matches[currentView.sets[1].id]?.weightGrams, 20000);
    expect(matches[currentView.sets[2].id]?.type, 'failure');
    expect(matches[currentView.sets[2].id]?.weightGrams, 30000);
  });

  test('finish menghasilkan ringkasan dan hanya menandai PR baru', () async {
    final exercise = (await database.watchExercises().first).first;
    final firstWorkout = await database.startWorkout();
    await database.addExerciseToWorkout(firstWorkout, exercise.id);
    final firstSet = (await database.getWorkoutExercises(
      firstWorkout,
    )).single.sets.first;
    await database.updateWorkoutSet(
      id: firstSet.id,
      weightGrams: 60000,
      reps: 10,
      completed: true,
    );
    final firstSummary = await database.finishWorkoutWithSummary(firstWorkout);
    expect(firstSummary.completedSets, 1);
    expect(firstSummary.volumeKg, 600);
    expect(
      firstSummary.personalRecords.map((record) => record.kind),
      containsAll([
        PersonalRecordKind.maxWeight,
        PersonalRecordKind.estimatedOneRepMax,
      ]),
    );

    final secondWorkout = await database.startWorkout();
    await database.addExerciseToWorkout(secondWorkout, exercise.id);
    final secondSet = (await database.getWorkoutExercises(
      secondWorkout,
    )).single.sets.first;
    await database.updateWorkoutSet(
      id: secondSet.id,
      weightGrams: 50000,
      reps: 8,
      completed: true,
    );
    final secondSummary = await database.finishWorkoutWithSummary(
      secondWorkout,
    );
    expect(secondSummary.personalRecords, isEmpty);
  });

  test('edit riwayat langsung menghitung ulang statistik', () async {
    final exercise = (await database.watchExercises().first).first;
    final workoutId = await database.startWorkout();
    await database.addExerciseToWorkout(workoutId, exercise.id);
    final view = (await database.getWorkoutExercises(workoutId)).single;
    await database.updateWorkoutSet(
      id: view.sets.first.id,
      weightGrams: 50000,
      reps: 10,
      completed: true,
    );
    await database.finishWorkout(workoutId);

    await database.updateHistoricalWorkout(
      id: workoutId,
      name: 'Riwayat diperbarui',
      notes: 'Catatan baru',
      exercises: [
        HistoricalExerciseUpdate(
          id: view.item.id,
          notes: 'Catatan exercise baru',
          sets: [
            HistoricalSetUpdate(
              id: view.sets.first.id,
              weightGrams: 70000,
              reps: 5,
              type: 'working',
              rpe: 8.5,
            ),
          ],
        ),
      ],
    );

    final workout = await database.watchWorkout(workoutId).first;
    expect(workout?.name, 'Riwayat diperbarui');
    expect(workout?.notes, 'Catatan baru');
    final editedView = (await database.getWorkoutExercises(workoutId)).single;
    expect(editedView.item.notes, 'Catatan exercise baru');
    expect(editedView.sets.single.weightGrams, 70000);
    expect(editedView.sets.single.rpe, 8.5);
    final point = (await database.progress(exercise.id, null)).single;
    expect(point.maxWeight, 70);
    expect(point.volume, 350);
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

  test(
    'backup tidak lengkap atau versi baru ditolak tanpa mengubah data',
    () async {
      final exercise = (await database.watchExercises().first).first;
      await database.createRoutine('Data aman', [exercise.id]);
      final original = await database.exportDocument();

      final incomplete =
          jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      (incomplete['data'] as Map<String, dynamic>).remove('exercises');
      await expectLater(
        database.importJson(jsonEncode(incomplete)),
        throwsFormatException,
      );
      expect((await database.watchRoutines().first).single.name, 'Data aman');
      expect(await database.watchExercises().first, hasLength(80));

      final newer = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      newer['schemaVersion'] = 2;
      await expectLater(
        database.importJson(jsonEncode(newer)),
        throwsFormatException,
      );
      expect((await database.watchRoutines().first).single.name, 'Data aman');
    },
  );

  test('backup dengan relasi rusak ditolak sebelum restore', () async {
    final exercise = (await database.watchExercises().first).first;
    await database.createRoutine('Tetap ada', [exercise.id]);
    final document =
        jsonDecode(jsonEncode(await database.exportDocument()))
            as Map<String, dynamic>;
    final data = document['data'] as Map<String, dynamic>;
    data['exercises'] = <Object>[];

    expect(
      () => database.validateBackup(jsonEncode(document)),
      throwsFormatException,
    );
    await expectLater(
      database.importJson(jsonEncode(document)),
      throwsFormatException,
    );
    expect((await database.watchRoutines().first).single.name, 'Tetap ada');
    expect(await database.watchExercises().first, hasLength(80));
  });

  test('removeWorkoutExercise menghapus exercise beserta seluruh set terkait', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final exercise = (await database.watchExercises().first).first;
    final workoutId = await database.startWorkout();
    await database.addExerciseToWorkout(workoutId, exercise.id);

    var exercises = await database.getWorkoutExercises(workoutId);
    expect(exercises, hasLength(1));
    expect(exercises.first.sets, hasLength(3));

    await database.removeWorkoutExercise(exercises.first.item.id);

    exercises = await database.getWorkoutExercises(workoutId);
    expect(exercises, isEmpty);
  });

  test('watchWorkoutExercises reaktif saat workout set diperbarui', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final exercise = (await database.watchExercises().first).first;
    final workoutId = await database.startWorkout();
    await database.addExerciseToWorkout(workoutId, exercise.id);

    final stream = database.watchWorkoutExercises(workoutId);
    final initialList = await stream.first;
    expect(initialList.first.sets.first.weightGrams, 0);

    // Update weight of set
    await database.updateWorkoutSet(
      id: initialList.first.sets.first.id,
      weightGrams: 50000,
      reps: 12,
    );

    // Stream should emit updated data without re-fetching manually
    final updatedList = await stream.first;
    expect(updatedList.first.sets.first.weightGrams, 50000);
    expect(updatedList.first.sets.first.reps, 12);
  });

  test('getRoutineDetail dan getRoutineHistoryPoints memuat detail dan riwayat latihan', () async {
    final exercise = (await database.watchExercises().first).first;
    final routineId = await database.createRoutineTemplate(
      name: 'Chest & Arms',
      notes: 'Push focus',
      exercises: [
        RoutineExerciseTemplate(
          exerciseId: exercise.id,
          restSeconds: 120,
          sets: const [
            RoutineSetTemplate(type: 'working', weightGrams: 40000, reps: 10),
            RoutineSetTemplate(type: 'working', weightGrams: 45000, reps: 8),
          ],
        ),
      ],
    );

    final detailBefore = await database.getRoutineDetail(routineId);
    expect(detailBefore.routine.name, 'Chest & Arms');
    expect(detailBefore.routine.notes, 'Push focus');
    expect(detailBefore.exercises, hasLength(1));
    expect(detailBefore.exercises.first.exercise.id, exercise.id);
    expect(detailBefore.exercises.first.restSeconds, 120);
    expect(detailBefore.exercises.first.sets, hasLength(2));
    expect(detailBefore.exercises.first.sets.first.weightGrams, 40000);
    expect(detailBefore.exercises.first.sets.first.reps, 10);
    expect(detailBefore.historyPoints, isEmpty);

    // Complete a workout from this routine
    final workoutId = await database.startWorkout(routineId: routineId);
    final workoutExercises = await database.getWorkoutExercises(workoutId);
    for (final s in workoutExercises.first.sets) {
      await database.updateWorkoutSet(id: s.id, weightGrams: 50000, reps: 10, completed: true);
    }
    await database.finishWorkout(workoutId);

    final detailAfter = await database.getRoutineDetail(routineId);
    expect(detailAfter.historyPoints, hasLength(1));
    expect(detailAfter.historyPoints.first.totalReps, greaterThan(0));
    expect(detailAfter.historyPoints.first.volumeKg, greaterThan(0));
  });
}
