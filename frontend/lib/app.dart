import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_metadata.dart';
import 'core/notification_service.dart';
import 'data/database.dart';
import 'data/exercise_api_client.dart';
import 'features/screens.dart';
import 'ui/material/app_ui.dart';
import 'ui/widgets/kinetic_components.dart';

final appMetadataProvider = Provider<AppMetadataService>(
  (ref) => DefaultAppMetadataService(),
);
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);
final notificationProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final exerciseApiClientProvider = Provider<ExerciseApiClient>(
  (ref) => ExerciseApiClient(),
);
final exercisesProvider = StreamProvider<List<Exercise>>(
  (ref) => ref.watch(databaseProvider).watchExercises(),
);
final routinesProvider = StreamProvider<List<Routine>>(
  (ref) => ref.watch(databaseProvider).watchRoutines(),
);
final historyProvider = StreamProvider<List<Workout>>(
  (ref) => ref.watch(databaseProvider).watchHistory(),
);
final activeWorkoutProvider = StreamProvider<Workout?>(
  (ref) => ref.watch(databaseProvider).watchActiveWorkout(),
);
final workoutDetailProvider = StreamProvider.autoDispose
    .family<Workout?, String>(
      (ref, id) => ref.watch(databaseProvider).watchWorkout(id),
    );
final workoutExercisesProvider = StreamProvider.autoDispose
    .family<List<WorkoutExerciseView>, String>(
      (ref, id) => ref.watch(databaseProvider).watchWorkoutExercises(id),
    );
final routineExerciseNamesProvider = StreamProvider.autoDispose
    .family<List<String>, String>(
      (ref, id) => ref.watch(databaseProvider).watchRoutineExerciseNames(id),
    );
final weightUnitProvider = StreamProvider<String>(
  (ref) => ref.watch(databaseProvider).watchWeightUnit(),
);

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/workouts',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (_, __) => const DashboardScreen(),
              ),
              GoRoute(path: '/latihan', redirect: (_, __) => '/workouts'),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (_, __) => const TrainingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, __) => const HistoryScreen(),
              ),
              GoRoute(path: '/riwayat', redirect: (_, __) => '/history'),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/metrics',
                builder: (_, __) => const ProgressScreen(),
              ),
              GoRoute(path: '/progres', redirect: (_, __) => '/metrics'),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
              GoRoute(path: '/pengaturan', redirect: (_, __) => '/settings'),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/workout/:id',
        builder: (_, state) => WorkoutScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) =>
            HistoryDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  ),
);

class ReprApp extends ConsumerWidget {
  const ReprApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Repr',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildAppTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: shell,
    bottomNavigationBar: KineticBottomNav(
      currentIndex: shell.currentIndex,
      onTap: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
    ),
  );
}
