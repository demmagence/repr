import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'seed_exercises.dart';

part 'database.g.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscle => text()();
  TextColumn get equipment => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RoutineExercises extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RoutineSets extends Table {
  TextColumn get id => text()();
  TextColumn get routineExerciseId =>
      text().references(RoutineExercises, #id)();
  IntColumn get position => integer()();
  TextColumn get type => text().withDefault(const Constant('working'))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get restEndsAt => dateTime().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id)();
  IntColumn get position => integer()();
  TextColumn get type => text().withDefault(const Constant('working'))();
  IntColumn get weightGrams => integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get rpe => real().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Exercises,
    Routines,
    RoutineExercises,
    RoutineSets,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'repr'));

  static const uuid = Uuid();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX workouts_date_idx ON workouts(started_at)',
      );
      await customStatement(
        'CREATE INDEX workout_exercise_idx ON workout_exercises(exercise_id, workout_id)',
      );
      await _seed();
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seed() async {
    final now = DateTime.now();
    await batch((batch) {
      for (var i = 0; i < seedExercises.length; i++) {
        final item = seedExercises[i];
        batch.insert(
          exercises,
          ExercisesCompanion.insert(
            id: 'seed-${i + 1}',
            name: item.$1,
            muscle: item.$2,
            equipment: item.$3,
            createdAt: now,
          ),
        );
      }
      batch.insert(
        appSettings,
        AppSettingsCompanion.insert(key: 'defaultRestSeconds', value: '90'),
      );
      batch.insert(
        appSettings,
        AppSettingsCompanion.insert(key: 'timerSound', value: 'true'),
      );
    });
  }

  Stream<List<Exercise>> watchExercises({String search = ''}) {
    final query = select(exercises)
      ..where((e) => e.archived.equals(false))
      ..orderBy([(e) => OrderingTerm.asc(e.name)]);
    if (search.trim().isNotEmpty) {
      query.where((e) => e.name.lower().like('%${search.toLowerCase()}%'));
    }
    return query.watch();
  }

  Future<List<Exercise>> getAllExercises() =>
      (select(exercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).get();

  Stream<List<Routine>> watchRoutines() => (select(
    routines,
  )..orderBy([(r) => OrderingTerm.asc(r.position)])).watch();

  Stream<List<Workout>> watchHistory() =>
      (select(workouts)
            ..where((w) => w.status.equals('completed'))
            ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
          .watch();

  Stream<Workout?> watchActiveWorkout() => (select(
    workouts,
  )..where((w) => w.status.equals('active'))).watchSingleOrNull();

  Stream<Workout?> watchWorkout(String id) =>
      (select(workouts)..where((w) => w.id.equals(id))).watchSingleOrNull();

  Future<Workout?> getActiveWorkout() => (select(
    workouts,
  )..where((w) => w.status.equals('active'))).getSingleOrNull();

  Future<int> getDefaultRestSeconds() async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals('defaultRestSeconds'))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 90;
  }

  Future<String?> getSetting(String key) async =>
      (select(appSettings)..where((s) => s.key.equals(key)))
          .getSingleOrNull()
          .then((row) => row?.value);

  Future<void> setSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<String> createExercise({
    required String name,
    required String muscle,
    required String equipment,
  }) async {
    final id = uuid.v4();
    await into(exercises).insert(
      ExercisesCompanion.insert(
        id: id,
        name: name.trim(),
        muscle: muscle,
        equipment: equipment,
        isCustom: const Value(true),
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<void> archiveExercise(String id) =>
      (update(exercises)..where((e) => e.id.equals(id))).write(
        const ExercisesCompanion(archived: Value(true)),
      );

  Future<String> createRoutine(String name, List<String> exerciseIds) async {
    return createRoutineTemplate(
      name: name,
      exercises: [
        for (final id in exerciseIds)
          RoutineExerciseTemplate(
            exerciseId: id,
            setTypes: const ['working', 'working', 'working'],
          ),
      ],
    );
  }

  Future<String> createRoutineTemplate({
    required String name,
    String notes = '',
    required List<RoutineExerciseTemplate> exercises,
  }) async {
    _validateRoutineTemplate(name, exercises);
    final routineId = uuid.v4();
    final now = DateTime.now();
    final count = await routines.count().getSingle();
    await transaction(() async {
      await into(routines).insert(
        RoutinesCompanion.insert(
          id: routineId,
          name: name.trim(),
          notes: Value(notes.trim()),
          position: Value(count),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _insertRoutineTemplate(routineId, exercises);
    });
    return routineId;
  }

  Future<RoutineTemplate> getRoutineTemplate(String routineId) async {
    final routine = await (select(
      routines,
    )..where((row) => row.id.equals(routineId))).getSingle();
    final rows =
        await (select(routineExercises)
              ..where((row) => row.routineId.equals(routineId))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    final items = <RoutineExerciseTemplate>[];
    for (final row in rows) {
      final sets =
          await (select(routineSets)
                ..where((set) => set.routineExerciseId.equals(row.id))
                ..orderBy([(set) => OrderingTerm.asc(set.position)]))
              .get();
      items.add(
        RoutineExerciseTemplate(
          exerciseId: row.exerciseId,
          notes: row.notes,
          restSeconds: row.restSeconds,
          setTypes: sets.map((set) => set.type).toList(),
        ),
      );
    }
    return RoutineTemplate(routine: routine, exercises: items);
  }

  Future<void> updateRoutineTemplate({
    required String id,
    required String name,
    required String notes,
    required List<RoutineExerciseTemplate> exercises,
  }) async {
    _validateRoutineTemplate(name, exercises);
    await transaction(() async {
      await (update(routines)..where((row) => row.id.equals(id))).write(
        RoutinesCompanion(
          name: Value(name.trim()),
          notes: Value(notes.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _deleteRoutineChildren(id);
      await _insertRoutineTemplate(id, exercises);
    });
  }

  void _validateRoutineTemplate(
    String name,
    List<RoutineExerciseTemplate> exercises,
  ) {
    const allowedTypes = {'working', 'warmUp', 'drop', 'failure'};
    if (name.trim().isEmpty) throw ArgumentError('Nama routine wajib diisi.');
    if (exercises.isEmpty) {
      throw ArgumentError('Routine wajib memiliki minimal satu exercise.');
    }
    for (final exercise in exercises) {
      if (exercise.restSeconds < 0 || exercise.setTypes.isEmpty) {
        throw ArgumentError('Konfigurasi exercise routine tidak valid.');
      }
      if (exercise.setTypes.any((type) => !allowedTypes.contains(type))) {
        throw ArgumentError('Jenis set routine tidak valid.');
      }
    }
  }

  Future<void> _insertRoutineTemplate(
    String routineId,
    List<RoutineExerciseTemplate> items,
  ) async {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final routineExerciseId = uuid.v4();
      await into(routineExercises).insert(
        RoutineExercisesCompanion.insert(
          id: routineExerciseId,
          routineId: routineId,
          exerciseId: item.exerciseId,
          position: index,
          notes: Value(item.notes.trim()),
          restSeconds: Value(item.restSeconds),
        ),
      );
      for (var setIndex = 0; setIndex < item.setTypes.length; setIndex++) {
        await into(routineSets).insert(
          RoutineSetsCompanion.insert(
            id: uuid.v4(),
            routineExerciseId: routineExerciseId,
            position: setIndex,
            type: Value(item.setTypes[setIndex]),
          ),
        );
      }
    }
  }

  Future<void> _deleteRoutineChildren(String routineId) async {
    final exerciseRows = await (select(
      routineExercises,
    )..where((row) => row.routineId.equals(routineId))).get();
    for (final row in exerciseRows) {
      await (delete(
        routineSets,
      )..where((set) => set.routineExerciseId.equals(row.id))).go();
    }
    await (delete(
      routineExercises,
    )..where((row) => row.routineId.equals(routineId))).go();
  }

  Future<void> deleteRoutine(String id) async {
    await transaction(() async {
      await _deleteRoutineChildren(id);
      await (delete(routines)..where((row) => row.id.equals(id))).go();
    });
  }

  Future<String> startWorkout({String? routineId, Workout? copied}) async {
    if (await getActiveWorkout() != null) {
      throw StateError('Masih ada workout aktif.');
    }
    final id = uuid.v4();
    await transaction(() async {
      Routine? routine;
      if (routineId != null) {
        routine = await (select(
          routines,
        )..where((r) => r.id.equals(routineId))).getSingle();
      }
      await into(workouts).insert(
        WorkoutsCompanion.insert(
          id: id,
          routineId: Value(routineId),
          name: routine?.name ?? copied?.name ?? 'Latihan kosong',
          status: 'active',
          startedAt: DateTime.now(),
        ),
      );
      if (routineId != null) {
        final items =
            await (select(routineExercises)
                  ..where((e) => e.routineId.equals(routineId))
                  ..orderBy([(e) => OrderingTerm.asc(e.position)]))
                .get();
        for (final item in items) {
          final workoutExerciseId = uuid.v4();
          await into(workoutExercises).insert(
            WorkoutExercisesCompanion.insert(
              id: workoutExerciseId,
              workoutId: id,
              exerciseId: item.exerciseId,
              position: item.position,
              notes: Value(item.notes),
              restSeconds: Value(item.restSeconds),
            ),
          );
          final sets =
              await (select(routineSets)
                    ..where((s) => s.routineExerciseId.equals(item.id))
                    ..orderBy([(s) => OrderingTerm.asc(s.position)]))
                  .get();
          for (final set in sets) {
            await into(workoutSets).insert(
              WorkoutSetsCompanion.insert(
                id: uuid.v4(),
                workoutExerciseId: workoutExerciseId,
                position: set.position,
                type: Value(set.type),
              ),
            );
          }
        }
      } else if (copied != null) {
        await _copyWorkoutExercises(copied.id, id);
      }
    });
    return id;
  }

  Future<void> _copyWorkoutExercises(String sourceId, String targetId) async {
    final items =
        await (select(workoutExercises)
              ..where((e) => e.workoutId.equals(sourceId))
              ..orderBy([(e) => OrderingTerm.asc(e.position)]))
            .get();
    for (final item in items) {
      final targetExerciseId = uuid.v4();
      await into(workoutExercises).insert(
        WorkoutExercisesCompanion.insert(
          id: targetExerciseId,
          workoutId: targetId,
          exerciseId: item.exerciseId,
          position: item.position,
          notes: Value(item.notes),
          restSeconds: Value(item.restSeconds),
        ),
      );
      final sets =
          await (select(workoutSets)
                ..where((s) => s.workoutExerciseId.equals(item.id))
                ..orderBy([(s) => OrderingTerm.asc(s.position)]))
              .get();
      for (final set in sets) {
        await into(workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: uuid.v4(),
            workoutExerciseId: targetExerciseId,
            position: set.position,
            type: Value(set.type),
          ),
        );
      }
    }
  }

  Future<void> addExerciseToWorkout(String workoutId, String exerciseId) async {
    final count =
        await (select(workoutExercises)
              ..where((e) => e.workoutId.equals(workoutId)))
            .get()
            .then((rows) => rows.length);
    final id = uuid.v4();
    await transaction(() async {
      await into(workoutExercises).insert(
        WorkoutExercisesCompanion.insert(
          id: id,
          workoutId: workoutId,
          exerciseId: exerciseId,
          position: count,
          restSeconds: Value(await getDefaultRestSeconds()),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await into(workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: uuid.v4(),
            workoutExerciseId: id,
            position: i,
          ),
        );
      }
    });
  }

  Stream<List<WorkoutExerciseView>> watchWorkoutExercises(String workoutId) {
    final query =
        select(workoutExercises).join([
            innerJoin(
              exercises,
              exercises.id.equalsExp(workoutExercises.exerciseId),
            ),
          ])
          ..where(workoutExercises.workoutId.equals(workoutId))
          ..orderBy([OrderingTerm.asc(workoutExercises.position)]);
    return query.watch().asyncMap((rows) async {
      final result = <WorkoutExerciseView>[];
      for (final row in rows) {
        final workoutExercise = row.readTable(workoutExercises);
        final sets =
            await (select(workoutSets)
                  ..where((s) => s.workoutExerciseId.equals(workoutExercise.id))
                  ..orderBy([(s) => OrderingTerm.asc(s.position)]))
                .get();
        result.add(
          WorkoutExerciseView(workoutExercise, row.readTable(exercises), sets),
        );
      }
      return result;
    });
  }

  Future<List<WorkoutExerciseView>> getWorkoutExercises(String workoutId) =>
      watchWorkoutExercises(workoutId).first;

  Future<void> updateWorkoutSet({
    required String id,
    int? weightGrams,
    int? reps,
    double? rpe,
    String? type,
    bool? completed,
  }) => (update(workoutSets)..where((s) => s.id.equals(id))).write(
    WorkoutSetsCompanion(
      weightGrams: weightGrams == null
          ? const Value.absent()
          : Value(weightGrams),
      reps: reps == null ? const Value.absent() : Value(reps),
      rpe: rpe == null ? const Value.absent() : Value(rpe),
      type: type == null ? const Value.absent() : Value(type),
      completed: completed == null ? const Value.absent() : Value(completed),
    ),
  );

  Future<void> addSet(String workoutExerciseId) async {
    final count =
        await (select(workoutSets)
              ..where((s) => s.workoutExerciseId.equals(workoutExerciseId)))
            .get()
            .then((rows) => rows.length);
    await into(workoutSets).insert(
      WorkoutSetsCompanion.insert(
        id: uuid.v4(),
        workoutExerciseId: workoutExerciseId,
        position: count,
      ),
    );
  }

  Future<void> removeSet(String id) =>
      (delete(workoutSets)..where((s) => s.id.equals(id))).go();

  Future<List<WorkoutSet>> previousSets(
    String exerciseId,
    String workoutId,
  ) async {
    final query =
        select(workoutExercises).join([
            innerJoin(
              workouts,
              workouts.id.equalsExp(workoutExercises.workoutId),
            ),
          ])
          ..where(
            workoutExercises.exerciseId.equals(exerciseId) &
                workouts.status.equals('completed') &
                workouts.id.equals(workoutId).not(),
          )
          ..orderBy([OrderingTerm.desc(workouts.startedAt)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return [];
    final exercise = row.readTable(workoutExercises);
    return (select(workoutSets)
          ..where(
            (s) =>
                s.workoutExerciseId.equals(exercise.id) &
                s.completed.equals(true),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  Future<int> completedSetCount(String workoutId) async {
    final ids =
        await (select(workoutExercises)
              ..where((e) => e.workoutId.equals(workoutId)))
            .get()
            .then((rows) => rows.map((e) => e.id).toList());
    if (ids.isEmpty) return 0;
    return (select(workoutSets)..where(
          (s) => s.workoutExerciseId.isIn(ids) & s.completed.equals(true),
        ))
        .get()
        .then((rows) => rows.length);
  }

  Future<void> finishWorkout(String id) async {
    if (await completedSetCount(id) == 0) {
      throw StateError('Selesaikan minimal satu set.');
    }
    await transaction(() async {
      final exerciseIds =
          await (select(workoutExercises)..where((e) => e.workoutId.equals(id)))
              .get()
              .then((rows) => rows.map((e) => e.id).toList());
      if (exerciseIds.isNotEmpty) {
        await (delete(workoutSets)..where(
              (s) =>
                  s.workoutExerciseId.isIn(exerciseIds) &
                  s.completed.equals(false),
            ))
            .go();
      }
      await (update(workouts)..where((w) => w.id.equals(id))).write(
        WorkoutsCompanion(
          status: const Value('completed'),
          endedAt: Value(DateTime.now()),
          restEndsAt: const Value(null),
        ),
      );
    });
  }

  Future<void> discardWorkout(String id) => _deleteWorkout(id);

  Future<void> deleteWorkout(String id) => _deleteWorkout(id);

  Future<void> updateWorkoutDate(String id, DateTime value) async {
    final workout = await (select(
      workouts,
    )..where((w) => w.id.equals(id))).getSingle();
    final duration = workout.endedAt?.difference(workout.startedAt);
    await (update(workouts)..where((w) => w.id.equals(id))).write(
      WorkoutsCompanion(
        startedAt: Value(value),
        endedAt: Value(duration == null ? null : value.add(duration)),
      ),
    );
  }

  Future<void> _deleteWorkout(String id) async {
    await transaction(() async {
      final exerciseRows = await (select(
        workoutExercises,
      )..where((e) => e.workoutId.equals(id))).get();
      for (final row in exerciseRows) {
        await (delete(
          workoutSets,
        )..where((set) => set.workoutExerciseId.equals(row.id))).go();
      }
      await (delete(
        workoutExercises,
      )..where((e) => e.workoutId.equals(id))).go();
      await (delete(workouts)..where((w) => w.id.equals(id))).go();
    });
  }

  Future<void> setRestEnd(String workoutId, DateTime? value) =>
      (update(workouts)..where((w) => w.id.equals(workoutId))).write(
        WorkoutsCompanion(restEndsAt: Value(value)),
      );

  Future<List<ProgressPoint>> progress(
    String exerciseId,
    DateTime? after,
  ) async {
    final query =
        select(workoutExercises).join([
            innerJoin(
              workouts,
              workouts.id.equalsExp(workoutExercises.workoutId),
            ),
          ])
          ..where(
            workoutExercises.exerciseId.equals(exerciseId) &
                workouts.status.equals('completed'),
          )
          ..orderBy([OrderingTerm.asc(workouts.startedAt)]);
    if (after != null)
      query.where(workouts.startedAt.isBiggerOrEqualValue(after));
    final rows = await query.get();
    final result = <ProgressPoint>[];
    for (final row in rows) {
      final item = row.readTable(workoutExercises);
      final workout = row.readTable(workouts);
      final sets =
          await (select(workoutSets)..where(
                (s) =>
                    s.workoutExerciseId.equals(item.id) &
                    s.completed.equals(true),
              ))
              .get();
      final relevant = sets.where((s) => s.type != 'warmUp').toList();
      if (relevant.isEmpty) continue;
      final maxWeight =
          relevant.map((s) => s.weightGrams).reduce((a, b) => a > b ? a : b) /
          1000;
      final e1rms = relevant
          .where((s) => s.weightGrams > 0 && s.reps <= 12)
          .map((s) => (s.weightGrams / 1000) * (1 + s.reps / 30));
      final maxE1rm = e1rms.isEmpty
          ? 0.0
          : e1rms.reduce((a, b) => a > b ? a : b);
      final volume = relevant.fold<double>(
        0,
        (sum, s) => sum + s.weightGrams / 1000 * s.reps,
      );
      result.add(ProgressPoint(workout.startedAt, maxWeight, maxE1rm, volume));
    }
    return result;
  }

  Future<Map<String, Object?>> exportDocument() async => {
    'format': 'repr-backup',
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'appVersion': '1.0.0',
    'data': {
      'exercises': (await select(
        exercises,
      ).get()).map((e) => e.toJson()).toList(),
      'routines': (await select(
        routines,
      ).get()).map((e) => e.toJson()).toList(),
      'routineExercises': (await select(
        routineExercises,
      ).get()).map((e) => e.toJson()).toList(),
      'routineSets': (await select(
        routineSets,
      ).get()).map((e) => e.toJson()).toList(),
      'workouts': (await select(
        workouts,
      ).get()).map((e) => e.toJson()).toList(),
      'workoutExercises': (await select(
        workoutExercises,
      ).get()).map((e) => e.toJson()).toList(),
      'workoutSets': (await select(
        workoutSets,
      ).get()).map((e) => e.toJson()).toList(),
      'settings': (await select(
        appSettings,
      ).get()).map((e) => e.toJson()).toList(),
    },
  };

  Future<void> importJson(String source) async {
    final document = jsonDecode(source);
    if (document is! Map<String, dynamic> ||
        document['format'] != 'repr-backup' ||
        document['schemaVersion'] != 1 ||
        document['data'] is! Map<String, dynamic>) {
      throw const FormatException('File bukan backup Repr versi 1 yang valid.');
    }
    final data = document['data'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) =>
        (data[key] as List? ?? const []).cast<Map<String, dynamic>>();
    await transaction(() async {
      await delete(workoutSets).go();
      await delete(workoutExercises).go();
      await delete(workouts).go();
      await delete(routineSets).go();
      await delete(routineExercises).go();
      await delete(routines).go();
      await delete(exercises).go();
      await delete(appSettings).go();
      for (final row in rows('exercises')) {
        await into(exercises).insert(Exercise.fromJson(row).toCompanion(true));
      }
      for (final row in rows('routines')) {
        await into(routines).insert(Routine.fromJson(row).toCompanion(true));
      }
      for (final row in rows('routineExercises')) {
        await into(
          routineExercises,
        ).insert(RoutineExercise.fromJson(row).toCompanion(true));
      }
      for (final row in rows('routineSets')) {
        await into(
          routineSets,
        ).insert(RoutineSet.fromJson(row).toCompanion(true));
      }
      for (final row in rows('workouts')) {
        await into(workouts).insert(Workout.fromJson(row).toCompanion(true));
      }
      for (final row in rows('workoutExercises')) {
        await into(
          workoutExercises,
        ).insert(WorkoutExercise.fromJson(row).toCompanion(true));
      }
      for (final row in rows('workoutSets')) {
        await into(
          workoutSets,
        ).insert(WorkoutSet.fromJson(row).toCompanion(true));
      }
      for (final row in rows('settings')) {
        await into(
          appSettings,
        ).insert(AppSetting.fromJson(row).toCompanion(true));
      }
    });
  }
}

class WorkoutExerciseView {
  const WorkoutExerciseView(this.item, this.exercise, this.sets);
  final WorkoutExercise item;
  final Exercise exercise;
  final List<WorkoutSet> sets;
}

class ProgressPoint {
  const ProgressPoint(this.date, this.maxWeight, this.e1rm, this.volume);
  final DateTime date;
  final double maxWeight;
  final double e1rm;
  final double volume;
}

class RoutineTemplate {
  const RoutineTemplate({required this.routine, required this.exercises});

  final Routine routine;
  final List<RoutineExerciseTemplate> exercises;
}

class RoutineExerciseTemplate {
  const RoutineExerciseTemplate({
    required this.exerciseId,
    required this.setTypes,
    this.notes = '',
    this.restSeconds = 90,
  });

  final String exerciseId;
  final String notes;
  final int restSeconds;
  final List<String> setTypes;
}
