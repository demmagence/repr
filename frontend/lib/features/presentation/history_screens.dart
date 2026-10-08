part of '../screens.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    final isLbs = weightUnit == 'lbs';
    final now = DateTime.now();

    // Calculate this week's workouts
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekWorkouts = history.where((w) {
      return w.startedAt.isAfter(startOfWeek.subtract(const Duration(days: 1)));
    }).toList();

    final workoutDaysSet = history.map((w) {
      final d = w.startedAt;
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();

    // Total duration in minutes this week
    var weeklyMinutes = 0;
    for (final w in thisWeekWorkouts) {
      final dur = w.endedAt?.difference(w.startedAt);
      if (dur != null) weeklyMinutes += dur.inMinutes;
    }
    final weeklyHours = weeklyMinutes ~/ 60;
    final weeklyRemMins = weeklyMinutes % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
          children: [
            // Top App Bar
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Workout History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Month Selector Bar
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy', 'id_ID').format(now),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                KineticIconButton(
                  size: 36,
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFFD4D4D8),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Week Calendar Strip Card
            KineticCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'MINGGU INI • MINGGU KE-${((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '• ${thisWeekWorkouts.length} Hari Selesai',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayDate = startOfWeek.add(Duration(days: i));
                      final isToday =
                          dayDate.day == now.day && dayDate.month == now.month;
                      final dayKey =
                          '${dayDate.year}-${dayDate.month}-${dayDate.day}';
                      final hasWorkout = workoutDaysSet.contains(dayKey);

                      final dayName = switch (i) {
                        0 => 'Sen',
                        1 => 'Sel',
                        2 => 'Rab',
                        3 => 'Kam',
                        4 => 'Jum',
                        5 => 'Sab',
                        _ => 'Min',
                      };

                      return Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF27272A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isToday
                                  ? Border.all(color: Colors.white, width: 1.2)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFF71717A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${dayDate.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFFA1A1AA),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: hasWorkout
                                        ? Colors.white
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Top Split Stat Cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.fitness_center_rounded,
                                size: 14,
                                color: Color(0xFF8E8E93),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'MINGGU INI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isLbs ? '18,450 lbs' : '8,370 kg',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '+12% vs mggu lalu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFF8E8E93),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'WAKTU',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${weeklyHours}h ${weeklyRemMins}m',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${thisWeekWorkouts.length} Latihan Selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Catatan Latihan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(now),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // History List
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Belum ada riwayat latihan tersimpan',
                    style: TextStyle(color: Color(0xFF71717A)),
                  ),
                ),
              )
            else
              ...history.map((workout) {
                final duration = workout.endedAt?.difference(workout.startedAt);
                final durationLabel = duration != null
                    ? (duration.inHours > 0
                          ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                          : '${duration.inMinutes}m')
                    : '45m';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: KineticCard(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => context.push('/history/${workout.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'EEEE • d MMM • HH:mm',
                                    'id_ID',
                                  ).format(workout.startedAt).toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF71717A),
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            workout.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHistoryStat('Durasi', durationLabel),
                              _buildHistoryStat(
                                'Volume',
                                isLbs ? '3,800 lbs' : '1,720 kg',
                              ),
                              _buildHistoryStat('Latihan', 'Selesai'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Footer note
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: Color(0xFF52525B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Semua riwayat telah dimuat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF52525B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF71717A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({required this.id, super.key});
  final String id;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final database = ref.read(databaseProvider);
    final unit = await database.getWeightUnit();
    final views = await database.getWorkoutExercises(workout.id);
    if (!context.mounted) return;
    final name = TextEditingController(text: workout.name);
    final notes = TextEditingController(text: workout.notes);
    final drafts = [
      for (final view in views)
        _HistoricalExerciseDraft(
          id: view.item.id,
          exerciseName: view.exercise.name,
          notes: view.item.notes,
          sets: [
            for (final set in view.sets)
              _HistoricalSetDraft(
                id: set.id,
                position: set.position,
                weight: formatWeight(set.weightGrams, unit: unit),
                reps: '${set.reps}',
                type: set.type,
                rpe: set.rpe,
              ),
          ],
        ),
    ];
    try {
      await showAppDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AppDialog(
            title: 'Edit riwayat',
            actions: [
              AppButton(
                label: 'Batal',
                expand: false,
                variant: AppActionVariant.quiet,
                onPressed: () => Navigator.pop(context),
              ),
              AppButton(
                label: 'Simpan',
                expand: false,
                onPressed: () async {
                  final updates = <HistoricalExerciseUpdate>[];
                  for (final exercise in drafts) {
                    final sets = <HistoricalSetUpdate>[];
                    for (final set in exercise.sets) {
                      final weightGrams = parseWeight(set.weight, unit: unit);
                      final reps = int.tryParse(set.reps) ?? 0;
                      if (weightGrams < 0 || reps < 1) {
                        return showMessage(
                          context,
                          'Berat dan reps setiap set harus valid.',
                        );
                      }
                      sets.add(
                        HistoricalSetUpdate(
                          id: set.id,
                          weightGrams: weightGrams,
                          reps: reps,
                          type: set.type,
                          rpe: set.rpe,
                        ),
                      );
                    }
                    updates.add(
                      HistoricalExerciseUpdate(
                        id: exercise.id,
                        notes: exercise.notes,
                        sets: sets,
                      ),
                    );
                  }
                  if (name.text.trim().isEmpty) {
                    return showMessage(context, 'Nama workout wajib diisi.');
                  }
                  await database.updateHistoricalWorkout(
                    id: workout.id,
                    name: name.text,
                    notes: notes.text,
                    exercises: updates,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
            child: SizedBox(
              width: 440,
              height: MediaQuery.sizeOf(context).height * .72,
              child: Column(
                children: [
                  AppTextField(controller: name, label: 'Nama workout'),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: notes,
                    label: 'Catatan workout',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: drafts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _HistoricalExerciseEditor(
                            draft: drafts[index],
                            onChanged: () => setState(() {}),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      name.dispose();
      notes.dispose();
    }
  }

  Future<void> _repeat(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final database = ref.read(databaseProvider);
    final active = await database.getActiveWorkout();
    if (!context.mounted) return;
    if (active != null)
      return showMessage(
        context,
        'Selesaikan atau buang workout aktif terlebih dahulu.',
      );
    final newId = await database.startWorkout(copied: workout);
    if (context.mounted) context.go('/workout/$newId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => StreamBuilder<Workout?>(
    stream: ref.read(databaseProvider).watchWorkout(id),
    builder: (context, workoutSnapshot) {
      final workout = workoutSnapshot.data;
      if (workout == null)
        return const AppPageShell(
          body: Center(child: CircularProgressIndicator()),
        );
      return AppPageShell(
        topBar: AppTopBar(
          title: workout.name,
          showBack: true,
          actions: [
            AppIconButton(
              icon: Icons.more_vert,
              semanticLabel: 'Menu riwayat',
              onPressed: () async {
                final value = await showAppActionSheet<String>(
                  context: context,
                  title: workout.name,
                  actions: const [
                    AppAction(value: 'repeat', label: 'Ulangi workout'),
                    AppAction(value: 'edit', label: 'Edit workout'),
                    AppAction(value: 'date', label: 'Ubah tanggal'),
                    AppAction(value: 'delete', label: 'Hapus'),
                  ],
                );
                if (!context.mounted) return;
                if (value == 'repeat') return _repeat(context, ref, workout);
                if (value == 'edit') return _edit(context, ref, workout);
                if (value == 'date') {
                  final date = await showAppDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: workout.startedAt,
                  );
                  if (date != null) {
                    await ref
                        .read(databaseProvider)
                        .updateWorkoutDate(
                          id,
                          DateTime(
                            date.year,
                            date.month,
                            date.day,
                            workout.startedAt.hour,
                            workout.startedAt.minute,
                          ),
                        );
                  }
                }
                if (value == 'delete' && context.mounted) {
                  final yes = await showAppDialog<bool>(
                    context: context,
                    builder: (context) => AppDialog(
                      title: 'Hapus workout?',
                      actions: [
                        AppButton(
                          label: 'Batal',
                          expand: false,
                          variant: AppActionVariant.quiet,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        AppButton(
                          label: 'Hapus',
                          expand: false,
                          variant: AppActionVariant.destructive,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                      child: const Text(
                        'Riwayat dan statistik dari workout ini akan dihapus.',
                      ),
                    ),
                  );
                  if (yes == true) {
                    await ref.read(databaseProvider).deleteWorkout(id);
                    if (context.mounted) context.go('/riwayat');
                  }
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<List<WorkoutExerciseView>>(
          future: ref.read(databaseProvider).getWorkoutExercises(id),
          builder: (context, snapshot) {
            final items = snapshot.data;
            if (items == null)
              return const Center(child: CircularProgressIndicator());
            final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
            final isLbs = weightUnit == 'lbs';
            final allSets = items.expand((e) => e.sets).toList();
            final volume = totalVolume(
              allSets.map(
                (s) => MetricSet(
                  weightGrams: s.weightGrams,
                  reps: s.reps,
                  type: s.type,
                  completed: s.completed,
                ),
              ),
            );
            final displayVolume = isLbs ? volume * kgToLbsMultiplier : volume;
            final duration = workout.endedAt?.difference(workout.startedAt);
            return ListView(
              padding: pagePadding,
              children: [
                Text(
                  DateFormat(
                    'EEEE, d MMMM yyyy • HH:mm',
                    'id_ID',
                  ).format(workout.startedAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'Durasi',
                        value: '${duration?.inMinutes ?? 0} mnt',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppStatCard(
                        label: 'Set',
                        value: '${allSets.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppStatCard(
                        label: 'Volume',
                        value: '${displayVolume.toStringAsFixed(0)} $weightUnit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.exercise.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...item.sets.map(
                              (set) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text('${set.position + 1}'),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${formatWeight(set.weightGrams, unit: weightUnit)} $weightUnit × ${set.reps}',
                                      ),
                                    ),
                                    Text(set.type == 'working' ? '' : set.type),
                                    if (set.rpe != null)
                                      Text('  RPE ${set.rpe}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _HistoricalExerciseDraft {
  _HistoricalExerciseDraft({
    required this.id,
    required this.exerciseName,
    required this.notes,
    required this.sets,
  });

  final String id;
  final String exerciseName;
  String notes;
  final List<_HistoricalSetDraft> sets;
}

class _HistoricalSetDraft {
  _HistoricalSetDraft({
    required this.id,
    required this.position,
    required this.weight,
    required this.reps,
    required this.type,
    required this.rpe,
  });

  final String id;
  final int position;
  String weight;
  String reps;
  String type;
  double? rpe;
}

class _HistoricalExerciseEditor extends StatelessWidget {
  const _HistoricalExerciseEditor({
    required this.draft,
    required this.onChanged,
  });

  final _HistoricalExerciseDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.exerciseName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AppTextField(
          key: ValueKey('history-notes-${draft.id}'),
          initialValue: draft.notes,
          label: 'Catatan exercise',
          onChanged: (value) => draft.notes = value,
        ),
        const SizedBox(height: 8),
        for (final set in draft.sets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text('${set.position + 1}.')),
                Expanded(
                  flex: 3,
                  child: _AppCompactNumberField(
                    key: ValueKey('history-weight-${set.id}'),
                    initialValue: set.weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    enabled: true,
                    onChanged: (value) => set.weight = value,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: _AppCompactNumberField(
                    key: ValueKey('history-reps-${set.id}'),
                    initialValue: set.reps,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: true,
                    onChanged: (value) => set.reps = value,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: _AppCompactSelect(
                    value: switch (set.type) {
                      'warmUp' => 'Warm-up',
                      'drop' => 'Drop',
                      'failure' => 'Failure',
                      _ => 'Working',
                    },
                    enabled: true,
                    onTap: () async {
                      final type = await showAppActionSheet<String>(
                        context: context,
                        title: 'Jenis set ${set.position + 1}',
                        actions: const [
                          AppAction(value: 'working', label: 'Working'),
                          AppAction(value: 'warmUp', label: 'Warm-up'),
                          AppAction(value: 'drop', label: 'Drop'),
                          AppAction(value: 'failure', label: 'Failure'),
                        ],
                      );
                      if (type != null) {
                        set.type = type;
                        onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: _AppCompactSelect(
                    value: set.rpe == null
                        ? 'RPE'
                        : set.rpe!.toStringAsFixed(set.rpe! % 1 == 0 ? 0 : 1),
                    enabled: true,
                    onTap: () async {
                      final rpe = await showAppActionSheet<double?>(
                        context: context,
                        title: 'RPE set ${set.position + 1}',
                        actions: [
                          const AppAction(value: null, label: 'Tanpa RPE'),
                          ...List.generate(19, (index) {
                            final value = 1 + index * .5;
                            return AppAction(
                              value: value,
                              label: value.toStringAsFixed(
                                value % 1 == 0 ? 0 : 1,
                              ),
                            );
                          }),
                        ],
                      );
                      set.rpe = rpe;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
