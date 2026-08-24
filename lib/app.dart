import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/notification_service.dart';
import 'data/database.dart';
import 'features/screens.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);
final notificationProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
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

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/latihan',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/latihan',
                builder: (_, __) => const TrainingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/riwayat',
                builder: (_, __) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progres',
                builder: (_, __) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pengaturan',
                builder: (_, __) => const SettingsScreen(),
              ),
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5),
      brightness: Brightness.light,
      surface: const Color(0xFFF7F7FA),
    );
    return MaterialApp.router(
      title: 'Repr',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.fitness_center),
          label: 'Latihan',
        ),
        NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
        NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progres'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Pengaturan'),
      ],
    ),
  );
}
