import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/presentation/workout_celebration_sheet.dart';
import 'package:repr/ui/material/app_theme.dart';

void main() {
  group('Weight Comparison Resolver', () {
    test('resolves correct animal comparison based on volume lifted', () {
      expect(resolveComparisonIndex(20), 0); // kitten
      expect(resolveComparisonIndex(100), 1); // panda
      expect(resolveComparisonIndex(300), 2); // lion
      expect(resolveComparisonIndex(800), 3); // horse
      expect(resolveComparisonIndex(1600), 4); // elephant (user's requested 1600kg!)
      expect(resolveComparisonIndex(6953), 4); // elephant (reference screenshot)
      expect(resolveComparisonIndex(10000), 5); // trex
      expect(resolveComparisonIndex(25000), 6); // jet
    });
  });

  group('WorkoutCelebrationScreen Widget Tests', () {
    testWidgets('renders celebratory header, cards, elephant comparison, and buttons', (tester) async {
      final summary = WorkoutCompletionSummary(
        duration: const Duration(minutes: 45),
        completedSets: 12,
        volumeKg: 1600.0,
        personalRecords: const [
          WorkoutPersonalRecord(
            exerciseName: 'Bench Press (Barbell)',
            kind: PersonalRecordKind.maxWeight,
            valueKg: 100.0,
          ),
        ],
        workoutName: 'Latihan Sore',
        workoutNumber: 47,
        exerciseSummaries: const [
          '4x Bench Press (Barbell)',
          '4x Incline Dumbbell Press',
          '4x Lateral Raise (Dumbbell)',
        ],
        streakWeeks: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: WorkoutCelebrationScreen(
            summary: summary,
            weightUnit: 'kg',
            userName: 'deryl',
            initialGreeting: defaultCelebrationGreetings.first,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Kerja bagus! 🎉'), findsOneWidget);
      expect(find.text('Ini adalah latihan ke-47 kamu'), findsOneWidget);

      // Verify Card 1 (Weight Comparison: 1.600 kg like an elephant)
      expect(find.text('Kamu mengangkat total'), findsOneWidget);
      expect(find.text('1.600 kg'), findsOneWidget);
      expect(find.text('Itu setara dengan mengangkat seekor gajah!'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('REPR'), findsWidgets);
      expect(find.text('@deryl'), findsNothing);

      // Verify Action Buttons
      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);
      expect(find.text('Salin Teks'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Tap Background to cycle theme
      await tester.tap(find.text('Background'));
      await tester.pumpAndSettle();

      // Tap illustration to cycle animal comparison
      await tester.tap(find.text('Itu setara dengan mengangkat seekor gajah!'));
      await tester.pumpAndSettle();

      // Verify Selesai button works without throwing
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
    });

    testWidgets('memilih kalimat ucapan bervariasi setiap kali menyelesaikan workout', (tester) async {
      final summary = WorkoutCompletionSummary(
        duration: const Duration(minutes: 30),
        completedSets: 10,
        volumeKg: 1000.0,
        personalRecords: const [],
        workoutName: 'Pagi Hari',
        workoutNumber: 1,
        exerciseSummaries: const ['3x Squat'],
        streakWeeks: 1,
      );

      final foundGreetings = <String>{};

      for (var i = 0; i < 25; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: WorkoutCelebrationScreen(
              key: ValueKey(i),
              summary: summary,
              weightUnit: 'kg',
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final greeting in defaultCelebrationGreetings) {
          if (find.text(greeting.fullTitle).evaluate().isNotEmpty) {
            foundGreetings.add(greeting.fullTitle);
          }
        }
      }

      // Verifikasi bahwa kata-kata yang muncul bervariasi (tidak hanya satu)
      expect(foundGreetings.length, greaterThan(1));
    });
  });
}
