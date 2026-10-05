import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repr/app.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<RestTimerPermissionStatus> permissionStatus() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<void> cancelRestTimer() async {}
}

void main() {
  testWidgets(
    'TrainingScreen tidak menampilkan card Mulai Latihan Kosong dan meminta konfirmasi saat memulai routine',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());

      // Seed routine template
      await tester.runAsync(() async {
        final exercise = (await database.watchExercises().first).first;
        await database.createRoutineTemplate(
          name: 'Leg Day Blast',
          notes: 'Fokus paha & betis',
          exercises: [
            RoutineExerciseTemplate(
              exerciseId: exercise.id,
              setTypes: const ['warmUp', 'working', 'working'],
            ),
          ],
        );
      });

      final router = GoRouter(
        initialLocation: '/train',
        routes: [
          GoRoute(
            path: '/train',
            builder: (_, __) => const TrainingScreen(),
          ),
          GoRoute(
            path: '/workout/:id',
            builder: (_, state) =>
                Text('Active Workout: ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            notificationProvider.overrideWithValue(_NoopNotificationService()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: buildAppTheme(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verifikasi card "Mulai Latihan Kosong" TIDAK ADA
      expect(find.text('Mulai Latihan Kosong'), findsNothing);
      expect(
        find.text('Catat latihan baru tanpa template'),
        findsNothing,
      );

      // 2. Verifikasi routine card "Leg Day Blast" ada
      expect(find.text('Leg Day Blast'), findsOneWidget);

      // 3. Ketuk routine card -> Dialog konfirmasi harus muncul
      await tester.tap(find.text('Leg Day Blast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Mulai latihan?'), findsOneWidget);
      expect(
        find.text('Mulai workout dari routine "Leg Day Blast"?'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);

      // 4. Batalkan dialog
      await tester.tap(find.text('Batal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog harus tertutup dan workout belum dimulai
      expect(find.text('Mulai latihan?'), findsNothing);
      expect(find.textContaining('Active Workout:'), findsNothing);

      // 5. Ketuk routine lagi dan konfirmasi Mulai
      await tester.tap(find.text('Leg Day Blast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Mulai latihan?'), findsOneWidget);
      await tester.tap(find.text('Mulai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog tertutup dan navigasi ke active workout
      expect(find.textContaining('Active Workout:'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(database.close);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
