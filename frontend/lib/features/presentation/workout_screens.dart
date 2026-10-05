part of '../screens.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    final database = ref.read(databaseProvider);
    final count = await database.completedSetCount(widget.id);
    if (!mounted) return;
    if (count == 0) return showMessage(context, 'Selesaikan minimal satu set.');
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Selesaikan workout?',
        actions: [
          AppButton(
            label: 'Kembali',
            expand: false,
            variant: AppActionVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: 'Selesaikan',
            expand: false,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        child: Text(
          '$count set selesai akan disimpan. Set yang belum selesai akan dibuang.',
        ),
      ),
    );
    if (confirmed != true) return;
    final summary = await database.finishWorkoutWithSummary(widget.id);
    await ref.read(notificationProvider).cancelRestTimer();
    if (!mounted) return;
    await showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: 'Workout selesai',
        actions: [
          AppButton(
            label: 'Lihat riwayat',
            expand: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    label: 'Durasi',
                    value: '${summary.duration.inMinutes} mnt',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppStatCard(
                    label: 'Set',
                    value: '${summary.completedSets}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppStatCard(
                    label: 'Volume',
                    value: '${summary.volumeKg.toStringAsFixed(0)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.personalRecords.isEmpty)
              const AppEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Belum ada PR baru',
                body: 'Konsistensi hari ini tetap tercatat.',
              )
            else ...[
              Text('PR BARU', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final record in summary.personalRecords)
                AppListRow(
                  leading: const AppAvatar(
                    child: Icon(Icons.emoji_events, size: 18),
                  ),
                  title: record.exerciseName,
                  subtitle:
                      '${record.kind == PersonalRecordKind.maxWeight ? 'Max weight' : 'Estimated 1RM'} • ${record.valueKg.toStringAsFixed(1)} kg',
                ),
            ],
          ],
        ),
      ),
    );
    if (mounted) context.go('/history');
  }

  Future<void> _discard() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Buang workout?',
        actions: [
          AppButton(
            label: 'Batal',
            expand: false,
            variant: AppActionVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: 'Buang',
            expand: false,
            variant: AppActionVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        child: const Text('Seluruh draft workout ini akan dihapus permanen.'),
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).discardWorkout(widget.id);
    await ref.read(notificationProvider).cancelRestTimer();
    if (mounted) context.go('/workouts');
  }

  Future<void> _addExercise() async {
    final selected = await showExercisePicker(context, ref);
    if (selected != null && selected.isNotEmpty) {
      await ref
          .read(databaseProvider)
          .addExerciseToWorkout(widget.id, selected.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutDetailProvider(widget.id));
    final exercisesAsync = ref.watch(workoutExercisesProvider(widget.id));

    return workout.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Text('$error', style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF09090B),
            body: EmptyState(
              icon: Icons.error_outline,
              title: 'Workout tidak ditemukan',
              body: 'Draft mungkin sudah dihapus.',
            ),
          );
        }

        final elapsed = DateTime.now().difference(item.startedAt);
        final elapsedLabel =
            '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        final rest = item.restEndsAt?.difference(DateTime.now());

        final exercises = exercisesAsync.valueOrNull ?? [];

        // Real-time calculation across all sets
        int totalSets = 0;
        int completedSets = 0;
        double totalVolumeKg = 0.0;
        WorkoutSet? firstUncompletedSet;
        WorkoutExerciseView? targetExerciseView;

        for (final ex in exercises) {
          for (final s in ex.sets) {
            totalSets++;
            if (s.completed) {
              completedSets++;
              totalVolumeKg += (s.weightGrams * s.reps) / 1000.0;
            } else if (firstUncompletedSet == null) {
              firstUncompletedSet = s;
              targetExerciseView = ex;
            }
          }
        }

        final progressPercent = totalSets > 0
            ? (completedSets / totalSets * 100).round()
            : 0;

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          body: SafeArea(
            child: Column(
              children: [
                // Header (Top App Bar matching Stitch)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      KineticIconButton(
                        size: 38,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Active Workout',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                        color: const Color(0xFF161618),
                        onSelected: (val) {
                          if (val == 'finish') _finish();
                          if (val == 'discard') _discard();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'finish',
                            child: Text(
                              'Selesaikan Workout',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'discard',
                            child: Text(
                              'Buang Draft Workout',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Under-Header Subtitle & Elapsed Timer
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161618),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Color(0xFF8E8E93),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              elapsedLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Content List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    children: [
                      // Top Split Metric Cards
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: Sets Progress
                            Expanded(
                              child: KineticCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CircularProgressBadge(
                                          progress: totalSets > 0
                                              ? (completedSets / totalSets)
                                              : 0,
                                          label: '$completedSets/$totalSets',
                                          size: 38,
                                        ),
                                        const Icon(
                                          Icons.tune_rounded,
                                          color: Color(0xFF52525B),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'SETS PROGRESS',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF71717A),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$progressPercent% Done',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right: Volume Lifted & Live BPM indicator
                            Expanded(
                              child: KineticCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E1E20),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFF27272A),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.favorite,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '134 bpm',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.sensors_rounded,
                                          color: Color(0xFF52525B),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'VOLUME LIFTED',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF71717A),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        totalVolumeKg.toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Text(
                                        'kg',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                      // Rest Timer Card (if active)
                      if (rest != null && !rest.isNegative) ...[
                        KineticCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.hourglass_bottom_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'REST TIMER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF71717A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${rest.inMinutes.toString().padLeft(2, '0')}:${(rest.inSeconds % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFeatures: tabularFigures,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFF1E1E20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final currentEnd = item.restEndsAt;
                                  if (currentEnd != null) {
                                    final newEnd = currentEnd.subtract(
                                      const Duration(seconds: 30),
                                    );
                                    if (newEnd.isBefore(DateTime.now())) {
                                      await ref
                                          .read(databaseProvider)
                                          .setRestEnd(widget.id, null);
                                      await ref
                                          .read(notificationProvider)
                                          .cancelRestTimer();
                                    } else {
                                      await ref
                                          .read(databaseProvider)
                                          .setRestEnd(widget.id, newEnd);
                                    }
                                  }
                                },
                                child: const Text(
                                  '-30s',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFF1E1E20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final newEnd = item.restEndsAt?.add(
                                    const Duration(seconds: 30),
                                  );
                                  if (newEnd != null) {
                                    await ref
                                        .read(databaseProvider)
                                        .setRestEnd(widget.id, newEnd);
                                  }
                                },
                                child: const Text(
                                  '+30s',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFF1E1E20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(databaseProvider)
                                      .setRestEnd(widget.id, null);
                                  await ref
                                      .read(notificationProvider)
                                      .cancelRestTimer();
                                },
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Exercises Cards
                      if (exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.fitness_center_rounded,
                                  color: Color(0xFF52525B),
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada gerakan latihan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tambahkan exercise untuk mulai mencatat sesi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: _addExercise,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Tambah Exercise'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...exercises.map(
                          (exView) => Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: WorkoutExerciseCard(
                              workoutId: widget.id,
                              view: exView,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Floating Action Button Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF09090B),
                    border: Border(top: BorderSide(color: Color(0xFF1E1E20))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (firstUncompletedSet != null &&
                                  targetExerciseView != null) {
                                // Complete the current target set
                                final database = ref.read(databaseProvider);
                                await database.updateWorkoutSet(
                                  id: firstUncompletedSet.id,
                                  completed: true,
                                );
                                // Start rest timer
                                final end = DateTime.now().add(
                                  Duration(
                                    seconds:
                                        targetExerciseView!.item.restSeconds,
                                  ),
                                );
                                await database.setRestEnd(widget.id, end);
                              } else {
                                // All sets completed, finish workout
                                _finish();
                              }
                            },
                            icon: Icon(
                              firstUncompletedSet != null
                                  ? Icons.check_circle_rounded
                                  : Icons.flag_rounded,
                              size: 20,
                            ),
                            label: Text(
                              firstUncompletedSet != null
                                  ? 'Complete Set & Rest'
                                  : 'Selesaikan Workout',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      KineticIconButton(
                        size: 52,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _addExercise,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WorkoutExerciseCard extends ConsumerWidget {
  const WorkoutExerciseCard({
    super.key,
    required this.workoutId,
    required this.view,
  });

  final String workoutId;
  final WorkoutExerciseView view;

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    WorkoutSet set,
    bool value,
  ) async {
    if (value && (set.reps < 1 || set.weightGrams < 0)) {
      return showMessage(
        context,
        'Isi berat dan reps yang valid terlebih dahulu.',
      );
    }
    final database = ref.read(databaseProvider);
    await database.updateWorkoutSet(id: set.id, completed: value);
    if (!value) return;
    final end = DateTime.now().add(Duration(seconds: view.item.restSeconds));
    await database.setRestEnd(workoutId, end);
    final sound = (await database.getSetting('timerSound')) != 'false';
    final service = ref.read(notificationProvider);
    final alreadyPrompted =
        (await database.getSetting('restTimerPermissionPrompted')) == 'true';
    final permission = alreadyPrompted
        ? await service.permissionStatus()
        : await service.requestRestTimerPermission();
    if (!alreadyPrompted) {
      await database.setSetting('restTimerPermissionPrompted', 'true');
    }
    if (permission.canSchedule) {
      try {
        await service.scheduleRestEnd(end, sound: sound);
      } catch (_) {
        if (context.mounted) {
          showMessage(
            context,
            'Timer aktif di aplikasi; notifikasi latar tidak tersedia.',
          );
        }
      }
    } else if ((await database.getSetting('restTimerPermissionNoticeShown')) !=
        'true') {
      await database.setSetting('restTimerPermissionNoticeShown', 'true');
      if (!context.mounted) return;
      showMessage(
        context,
        permission.notificationsGranted
            ? 'Timer aktif di aplikasi. Izin exact alarm belum diberikan.'
            : 'Timer aktif di aplikasi. Izin notifikasi belum diberikan.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);

    // Find the first uncompleted set in this exercise
    WorkoutSet? targetSet;
    for (final s in view.sets) {
      if (!s.completed) {
        targetSet = s;
        break;
      }
    }

    return KineticCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    showExerciseDemoSheet(
                      context,
                      exercise: ExerciseApiModel.fromLocal(view.exercise),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE LIFT • SET ${targetSet != null ? targetSet.position + 1 : view.sets.length}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              view.exercise.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.play_circle_outline,
                            size: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF71717A),
                ),
                color: const Color(0xFF161618),
                onSelected: (val) async {
                  if (val == 'demo') {
                    showExerciseDemoSheet(
                      context,
                      exercise: ExerciseApiModel.fromLocal(view.exercise),
                    );
                  } else if (val == 'delete') {
                    await database.removeWorkoutExercise(view.item.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'demo',
                    child: Text(
                      'Demo Gerakan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus Exercise',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sets list
          ...view.sets.map((set) {
            final isTarget = set.id == targetSet?.id;

            if (set.completed) {
              // Completed Set Row
              return Dismissible(
                key: ValueKey('completed-${set.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                onDismissed: (_) => database.removeSet(set.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Selesaikan set ${set.position + 1}',
                        child: InkWell(
                          onTap: () => _complete(context, ref, set, false),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27272A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SET ${set.position + 1}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatKg(set.weightGrams)} kg  ×  ${set.reps} reps',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA1A1AA),
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => database.removeSet(set.id),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF52525B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (isTarget) {
              // TARGET ACTIVE SET BOX (Micro-steppers matching Stitch)
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF101012),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF27272A),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Selesaikan set ${set.position + 1}',
                            child: InkWell(
                              onTap: () => _complete(context, ref, set, true),
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27272A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white70),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'SET ${set.position + 1} (TARGET SET)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final val = await showAppActionSheet<double>(
                              context: context,
                              title: 'Pilih RPE',
                              actions: List.generate(19, (i) {
                                final rpeVal = 1 + i * 0.5;
                                return AppAction(
                                  value: rpeVal,
                                  label: rpeVal.toStringAsFixed(
                                    rpeVal % 1 == 0 ? 0 : 1,
                                  ),
                                );
                              }),
                            );
                            if (val != null)
                              database.updateWorkoutSet(id: set.id, rpe: val);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'RPE ${set.rpe?.toStringAsFixed(1) ?? '8.5'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => database.removeSet(set.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Weight Stepper
                        Expanded(
                          child: _MicroStepper(
                            label: 'WEIGHT (KG)',
                            value: formatKg(set.weightGrams),
                            onTapValue: () async {
                              final ctrl = TextEditingController(text: formatKg(set.weightGrams));
                              final val = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF161618),
                                  title: const Text('Ubah Beban (kg)', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    autofocus: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 20),
                                    decoration: const InputDecoration(
                                      suffixText: 'kg',
                                      suffixStyle: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal', style: TextStyle(color: Color(0xFF71717A))),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (val != null) {
                                final parsed = double.tryParse(val.replaceAll(',', '.'));
                                if (parsed != null && parsed >= 0) {
                                  database.updateWorkoutSet(
                                    id: set.id,
                                    weightGrams: (parsed * 1000).round(),
                                  );
                                }
                              }
                            },
                            onMinus: () {
                              final newGrams = (set.weightGrams - 2500).clamp(
                                0,
                                1000000,
                              );
                              database.updateWorkoutSet(
                                id: set.id,
                                weightGrams: newGrams,
                              );
                            },
                            onPlus: () {
                              final newGrams = set.weightGrams + 2500;
                              database.updateWorkoutSet(
                                id: set.id,
                                weightGrams: newGrams,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Reps Stepper
                        Expanded(
                          child: _MicroStepper(
                            label: 'TARGET REPS',
                            value: '${set.reps}',
                            onTapValue: () async {
                              final ctrl = TextEditingController(text: '${set.reps}');
                              final val = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF161618),
                                  title: const Text('Ubah Repetisi', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 20),
                                    decoration: const InputDecoration(
                                      suffixText: 'reps',
                                      suffixStyle: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal', style: TextStyle(color: Color(0xFF71717A))),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (val != null) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed >= 0) {
                                  database.updateWorkoutSet(
                                    id: set.id,
                                    reps: parsed,
                                  );
                                }
                              }
                            },
                            onMinus: () {
                              final newReps = (set.reps - 1).clamp(1, 999);
                              database.updateWorkoutSet(
                                id: set.id,
                                reps: newReps,
                              );
                            },
                            onPlus: () {
                              database.updateWorkoutSet(
                                id: set.id,
                                reps: set.reps + 1,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              // Upcoming set
              return Dismissible(
                key: ValueKey('upcoming-${set.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                onDismissed: (_) => database.removeSet(set.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Selesaikan set ${set.position + 1}',
                        child: InkWell(
                          onTap: () => _complete(context, ref, set, true),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161618),
                              border: Border.all(color: const Color(0xFF27272A)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${set.position + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF71717A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SET ${set.position + 1}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF52525B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatKg(set.weightGrams)} kg  ×  ${set.reps > 0 ? '${set.reps} reps' : 'Target'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF52525B),
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => database.removeSet(set.id),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF52525B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 10),

          // Add set button
          Center(
            child: TextButton.icon(
              onPressed: () => database.addSet(view.item.id),
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF8E8E93)),
              label: const Text(
                'Tambah Set',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroStepper extends StatelessWidget {
  const _MicroStepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onTapValue,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onTapValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF71717A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onMinus,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27272A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: onTapValue,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onPlus,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27272A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppCompactNumberField extends StatelessWidget {
  const _AppCompactNumberField({
    this.initialValue,
    required this.keyboardType,
    required this.inputFormatters,
    required this.enabled,
    required this.onChanged,
    super.key,
  });
  final String? initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initialValue,
    enabled: enabled,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    textAlign: TextAlign.center,
    decoration: const InputDecoration(hintText: '—'),
    style: const TextStyle(fontFeatures: tabularFigures),
  );
}

class _AppCompactSelect extends StatelessWidget {
  const _AppCompactSelect({
    required this.value,
    required this.enabled,
    required this.onTap,
  });
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: enabled ? onTap : null,
    child: Text(value, style: const TextStyle(fontFeatures: tabularFigures)),
  );
}
