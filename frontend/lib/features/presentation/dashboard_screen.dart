part of '../screens.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _startWorkout(
    BuildContext context,
    WidgetRef ref, {
    String? routineId,
  }) async {
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
          child: const Text(
            'Lanjutkan workout yang sedang berjalan atau buang draftnya.',
          ),
        ),
      );
      if (discard != true) return;
      await database.discardWorkout(active.id);
    }
    final id = await database.startWorkout(routineId: routineId);
    if (context.mounted) context.push('/workout/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final routines = ref.watch(routinesProvider).valueOrNull ?? [];
    final active = ref.watch(activeWorkoutProvider).valueOrNull;
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    final isLbs = weightUnit == 'lbs';

    final firstRoutine = routines.isNotEmpty ? routines.first : null;
    final secondRoutine = routines.length > 1 ? routines[1] : null;

    // Calculate workouts in last 7 days for quick summary
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentSevenDaysCount = history
        .where((w) => w.startedAt.isAfter(sevenDaysAgo))
        .length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Workouts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                KineticIconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFFD4D4D8),
                    size: 22,
                  ),
                  onPressed: () => _startWorkout(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Active Workout Banner (if any)
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'In Progress • Ketuk untuk lanjut',
                              style: TextStyle(
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
              const SizedBox(height: 14),
            ],

            // Top Split Grid (Two Cards)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Left Card: Primary Routine / Split
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () => _startWorkout(
                          context,
                          ref,
                          routineId: firstRoutine?.id,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  CircularProgressBadge(
                                    progress: 0.75,
                                    label: '1',
                                    size: 38,
                                  ),
                                  Icon(
                                    Icons.tune_rounded,
                                    color: Color(0xFF52525B),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstRoutine?.name ?? 'Chest + Triceps',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('EEEE', 'id_ID').format(now),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Top Right Card: Body Weight
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          isLbs ? '200' : '90',
                                          style: const TextStyle(
                                            fontSize: 27,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          weightUnit,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF8E8E93),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFF52525B),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Body Weight',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Target Maintenance',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Middle Card: Heatmap / Consistency Matrix Card
            KineticCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeatmap(history),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF27272A), height: 1),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _startWorkout(
                      context,
                      ref,
                      routineId: secondRoutine?.id,
                    ),
                    child: Row(
                      children: [
                        const CircularProgressBadge(
                          progress: 0.35,
                          label: '2',
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                secondRoutine?.name ?? 'Back + Biceps + Legs',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Next Split Session',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF52525B),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Volume Card
            KineticCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Volume lifted',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Last 7 days • $recentSevenDaysCount sesi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLbs ? '3,200' : '1,450',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            weightUnit,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF52525B),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Recent History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Recent History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Recent History Items
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Belum ada riwayat latihan',
                    style: TextStyle(color: Color(0xFF71717A)),
                  ),
                ),
              )
            else
              ...history.take(4).map((workout) {
                final duration = workout.endedAt?.difference(workout.startedAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: KineticCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push('/history/${workout.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E20),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF27272A),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('dd').format(workout.startedAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                  const SizedBox(height: 3),
                                  Text(
                                    '${DateFormat('EEEE, d MMM', 'id_ID').format(workout.startedAt)}${duration == null ? '' : ' • ${duration.inMinutes} mnt'}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF71717A),
                            ),
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

  Widget _buildHeatmap(List<Workout> history) {
    // Generate dates with completed workouts
    final workoutDays = history.map((w) {
      final d = w.startedAt;
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();

    final now = DateTime.now();

    return Column(
      children: [
        // Month headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _monthLabel(now.subtract(const Duration(days: 60))),
            _monthLabel(now.subtract(const Duration(days: 30))),
            _monthLabel(now),
          ],
        ),
        const SizedBox(height: 12),
        // 4 rows x 12 columns of dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(12, (colIndex) {
            return Column(
              children: List.generate(4, (rowIndex) {
                // Approximate past date
                final daysOffset = (11 - colIndex) * 7 + (3 - rowIndex);
                final checkDate = now.subtract(Duration(days: daysOffset));
                final dateKey =
                    '${checkDate.year}-${checkDate.month}-${checkDate.day}';
                final hasWorkout = workoutDays.contains(dateKey);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasWorkout
                          ? Colors.white
                          : const Color(0xFF27272A),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _monthLabel(DateTime date) {
    return Text(
      DateFormat('MMM').format(date),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8E8E93),
      ),
    );
  }
}
