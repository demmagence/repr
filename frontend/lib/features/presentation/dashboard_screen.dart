part of '../screens.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final active = await database.getActiveWorkout();
    if (!context.mounted) return;
    if (active != null) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: 'Workout masih aktif',
          actions: [
            AppButton(
              label: 'Lanjutkan',
              expand: false,
              variant: AppActionVariant.secondary,
              onPressed: () {
                Navigator.pop(context, false);
                context.push('/workout/${active.id}');
              },
            ),
            AppButton(
              label: 'Buang draft',
              expand: false,
              variant: AppActionVariant.destructive,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          child: const Text('Lanjutkan workout yang sedang berjalan atau buang draftnya.'),
        ),
      );
      if (discard != true) return;
      await database.discardWorkout(active.id);
    }
    final id = await database.startWorkout();
    if (context.mounted) context.push('/workout/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final active = ref.watch(activeWorkoutProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workouts',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    KineticIconButton(
                      icon: const Icon(Icons.tune, color: Color(0xFFD4D4D8), size: 20),
                      onPressed: () {
                        // Filter action
                      },
                    ),
                    const SizedBox(width: 10),
                    KineticIconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFD4D4D8), size: 22),
                      onPressed: () => _startWorkout(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (active != null) ...[
              KineticCard(
                backgroundColor: const Color(0xFF161618),
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () => context.push('/workout/${active.id}'),
                  child: Row(
                    children: [
                      const CircularProgressBadge(
                        progress: 0.5,
                        label: '1',
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const Text(
                              'In Progress',
                              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Top Split Grid
            Row(
              children: [
                Expanded(
                  child: KineticCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const CircularProgressBadge(
                                progress: 0.75,
                                label: '2',
                                size: 44,
                              ),
                              Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chest + Triceps',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KineticCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text(
                                    '80',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ),
                          Text(
                            'Body Weight',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/riwayat');
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // History List
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No recent workouts',
                    style: TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              )
            else
              ...history.take(5).map((workout) {
                final duration = workout.endedAt?.difference(workout.startedAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: KineticCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push('/history/${workout.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF27272A)),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('dd').format(workout.startedAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workout.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat('EEEE', 'id_ID').format(workout.startedAt)}${duration == null ? '' : ' • ${duration.inMinutes} menit'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
