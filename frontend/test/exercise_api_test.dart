import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repr/data/database.dart';
import 'package:repr/data/exercise_api_client.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

void main() {
  group('ExerciseApiClient', () {
    test('serializes and deserializes ExerciseApiModel correctly', () {
      final model = ExerciseApiModel(
        id: '0025',
        name: 'barbell bench press',
        bodyPart: 'chest',
        equipment: 'barbell',
        gifUrl: 'https://v2.exercisedb.io/image/9Z7KjV4v-B9z8l',
        target: 'pectorals',
        secondaryMuscles: const ['triceps', 'shoulders'],
        instructions: const ['Step 1: Lie down', 'Step 2: Press bar'],
      );

      final json = model.toJson();
      expect(json['id'], '0025');
      expect(json['name'], 'barbell bench press');

      final fromJson = ExerciseApiModel.fromJson(json);
      expect(fromJson.id, '0025');
      expect(fromJson.name, 'barbell bench press');
      expect(fromJson.secondaryMuscles, contains('triceps'));
      expect(fromJson.instructions, hasLength(2));
    });

    test('fetches exercises using mock http client', () async {
      final mockData = [
        {
          'id': '0025',
          'name': 'barbell bench press',
          'bodyPart': 'chest',
          'equipment': 'barbell',
          'gifUrl': 'https://v2.exercisedb.io/image/9Z7KjV4v-B9z8l',
          'target': 'pectorals',
          'secondaryMuscles': ['triceps'],
          'instructions': ['Lie on bench', 'Press bar'],
        },
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/exercises')) {
          return http.Response(
            jsonEncode({'data': mockData, 'total': 1}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ExerciseApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3000/api',
      );

      final result = await client.fetchExercises(search: 'bench');
      expect(result, hasLength(1));
      expect(result.first.name, 'barbell bench press');
      expect(result.first.target, 'pectorals');
    });

    test('fetches single exercise by id', () async {
      final mockItem = {
        'id': '0025',
        'name': 'barbell bench press',
        'bodyPart': 'chest',
        'equipment': 'barbell',
        'gifUrl': 'https://v2.exercisedb.io/image/9Z7KjV4v-B9z8l',
        'target': 'pectorals',
        'secondaryMuscles': ['triceps'],
        'instructions': ['Lie on bench'],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/exercises/0025')) {
          return http.Response(
            jsonEncode(mockItem),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ExerciseApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3000/api',
      );

      final item = await client.fetchExercise('0025');
      expect(item.id, '0025');
      expect(item.name, 'barbell bench press');
    });
  });

  group('ExerciseDemoSheet Widget', () {
    testWidgets('renders movement details and instructions', (tester) async {
      final exercise = ExerciseApiModel(
        id: '0025',
        name: 'barbell bench press',
        bodyPart: 'chest',
        equipment: 'barbell',
        gifUrl: null,
        target: 'pectorals',
        secondaryMuscles: const ['triceps', 'anterior deltoids'],
        instructions: const [
          'Lie back on a flat bench with feet flat on the ground.',
          'Grip barbell slightly wider than shoulders.',
          'Lower bar with control to mid-chest.',
          'Press bar back up until arms are extended.',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showExerciseDemoSheet(context, exercise: exercise),
                  child: const Text('Open Demo'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Demo'));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Petunjuk Gerakan'), findsOneWidget);
      expect(find.textContaining('Lie back on a flat bench'), findsOneWidget);
      expect(find.textContaining('Grip barbell slightly'), findsOneWidget);
      expect(find.textContaining('Bagian: Chest'), findsOneWidget);
      expect(find.textContaining('Target: Pectorals'), findsOneWidget);
      expect(find.textContaining('Alat: Barbell'), findsOneWidget);
    });
  });

  group('Exercise Backend to SQLite Sync', () {
    test(
      'ExerciseApiModel.fromLocal parses rich fields and JSON collections',
      () {
        final local = Exercise(
          id: 'ex-001',
          name: 'Incline Dumbbell Press',
          muscle: 'Dada',
          equipment: 'Dumbbell',
          bodyPart: 'Chest',
          target: 'Upper Pectorals',
          gifUrl: 'https://cdn.example.com/incline.gif',
          secondaryMuscles: jsonEncode(['Triceps', 'Shoulders']),
          instructions: jsonEncode([
            'Sit on incline bench',
            'Press dumbbells up',
          ]),
          isCustom: false,
          archived: false,
          createdAt: DateTime.now(),
        );

        final apiModel = ExerciseApiModel.fromLocal(local);
        expect(apiModel.id, 'ex-001');
        expect(apiModel.name, 'Incline Dumbbell Press');
        expect(apiModel.bodyPart, 'Chest');
        expect(apiModel.target, 'Upper Pectorals');
        expect(apiModel.gifUrl, 'https://cdn.example.com/incline.gif');
        expect(
          apiModel.secondaryMuscles,
          containsAll(['Triceps', 'Shoulders']),
        );
        expect(apiModel.instructions, hasLength(2));
      },
    );

    test(
      'upsertExercisesFromApi inserts new exercises and updates existing',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final apiItems = [
          const ExerciseApiModel(
            id: 'api-1',
            name: 'Lat Pulldown',
            bodyPart: 'Back',
            equipment: 'Cable',
            gifUrl: 'https://example.com/lat.gif',
            target: 'Lats',
            secondaryMuscles: ['Biceps'],
            instructions: ['Pull bar down to upper chest'],
          ),
          const ExerciseApiModel(
            id: 'api-2',
            name: 'Leg Press',
            bodyPart: 'Upper Legs',
            equipment: 'Machine',
            target: 'Quadriceps',
          ),
        ];

        final count = await db.upsertExercisesFromApi(apiItems);
        expect(count, 2);

        final saved = await db.watchExercises().first;
        final lat = saved.firstWhere((e) => e.id == 'api-1');
        expect(lat.name, 'Lat Pulldown');
        expect(lat.bodyPart, 'Back');
        expect(lat.target, 'Lats');
        expect(lat.gifUrl, 'https://example.com/lat.gif');
        expect(lat.secondaryMuscles, contains('Biceps'));
        expect(lat.instructions, contains('Pull bar down'));

        // Test updating existing
        final updateItems = [
          const ExerciseApiModel(
            id: 'api-1',
            name: 'Lat Pulldown (Updated)',
            bodyPart: 'Back',
            equipment: 'Cable',
            gifUrl: 'https://example.com/lat-v2.gif',
            target: 'Lats',
          ),
        ];
        await db.upsertExercisesFromApi(updateItems);

        final updatedList = await db.watchExercises().first;
        final updatedLat = updatedList.firstWhere((e) => e.id == 'api-1');
        expect(updatedLat.name, 'Lat Pulldown (Updated)');
        expect(updatedLat.gifUrl, 'https://example.com/lat-v2.gif');
      },
    );

    test(
      'syncAllExercisesToDatabase paginates and syncs into database',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final mockData = [
          {
            'id': 'sync-1',
            'name': 'Chest Fly',
            'bodyPart': 'Chest',
            'equipment': 'Dumbbell',
            'target': 'Pectorals',
          },
        ];

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'data': mockData, 'total': 1}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = ExerciseApiClient(
          client: mockClient,
          baseUrl: 'http://localhost:3000/api',
        );

        final syncedCount = await client.syncAllExercisesToDatabase(db);
        expect(syncedCount, 1);

        final saved = await db.watchExercises().first;
        expect(saved.any((e) => e.name == 'Chest Fly'), isTrue);
      },
    );
  });
}
