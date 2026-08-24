import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/greek_theme.dart';
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
    return MaterialApp.router(
      title: 'Repr',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildGreekTheme(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: GreekPalette.ivory,
        boxShadow: [
          BoxShadow(
            color: Color(0x24272821),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GreekKeyBorder(height: 10),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fitness_center),
                label: 'Latihan',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart),
                label: 'Progres',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Pengaturan',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
