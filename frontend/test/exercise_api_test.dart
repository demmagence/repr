import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
        }
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
                  onPressed: () => showExerciseDemoSheet(
                    context,
                    exercise: exercise,
                  ),
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
}
