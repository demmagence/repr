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
    if (mounted) context.go('/riwayat');
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
    if (mounted) context.go('/latihan');
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
    final workout = ref.watch(
      StreamProvider.autoDispose<Workout?>(
        (ref) => ref.watch(databaseProvider).watchWorkout(widget.id),
      ),
    );
    return workout.when(
      loading: () =>
          const AppPageShell(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => AppPageShell(body: Center(child: Text('$error'))),
      data: (item) {
        if (item == null)
          return const AppPageShell(
            body: EmptyState(
              icon: Icons.error_outline,
              title: 'Workout tidak ditemukan',
              body: 'Draft mungkin sudah dihapus.',
            ),
          );
        final elapsed = DateTime.now().difference(item.startedAt);
        final elapsedLabel =
            '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        final rest = item.restEndsAt?.difference(DateTime.now());
        return PopScope(
          canPop: true,
          child: AppPageShell(
            topBar: AppTopBar(
              title: item.name,
              subtitle: elapsedLabel,
              showBack: true,
              actions: [
                AppButton(
                  label: 'Selesai',
                  onPressed: _finish,
                  expand: false,
                  variant: AppActionVariant.quiet,
                ),
                AppIconButton(
                  icon: Icons.more_vert,
                  semanticLabel: 'Menu workout',
                  onPressed: () async {
                    final value = await showAppActionSheet<String>(
                      context: context,
                      title: 'Menu workout',
                      actions: const [
                        AppAction(value: 'discard', label: 'Buang workout'),
                      ],
                    );
                    if (value == 'discard') await _discard();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (rest != null && !rest.isNegative)
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 8),
                        Text(
                          'Istirahat ${rest.inMinutes}:${(rest.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Lewati',
                          expand: false,
                          variant: AppActionVariant.quiet,
                          onPressed: () async {
                            await ref
                                .read(databaseProvider)
                                .setRestEnd(widget.id, null);
                            await ref
                                .read(notificationProvider)
                                .cancelRestTimer();
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<WorkoutExerciseView>>(
                    stream: ref
                        .read(databaseProvider)
                        .watchWorkoutExercises(widget.id),
                    builder: (context, snapshot) {
                      final items =
                          snapshot.data ?? const <WorkoutExerciseView>[];
                      if (items.isEmpty) {
                        return const EmptyState(
                          icon: Icons.fitness_center,
                          title: 'Tambahkan exercise',
                          body:
                              'Pilih gerakan pertama untuk mulai mencatat set.',
                        );
                      }
                      return ListView.separated(
                        padding: pagePadding,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => WorkoutExerciseCard(
                          workoutId: widget.id,
                          view: items[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            bottomBar: SafeArea(
              minimum: const EdgeInsets.all(12),
              child: AppButton(
                onPressed: _addExercise,
                icon: Icons.add,
                label: 'Tambah exercise',
              ),
            ),
          ),
        );
      },
    );
  }
}

class WorkoutExerciseCard extends ConsumerWidget {
  const WorkoutExerciseCard({
    required this.workoutId,
    required this.view,
    super.key,
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
        if (context.mounted)
          showMessage(
            context,
            'Timer aktif di aplikasi; notifikasi latar tidak tersedia.',
          );
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
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    padding: const EdgeInsets.all(11),
    child: Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      view.exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${view.exercise.muscle} • istirahat ${view.item.restSeconds} dtk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AppIconButton(
                onPressed: () =>
                    ref.read(databaseProvider).addSet(view.item.id),
                icon: Icons.add_circle_outline,
                semanticLabel: 'Tambah set',
              ),
            ],
          ),
          FutureBuilder<Map<String, WorkoutSet>>(
            future: ref
                .read(databaseProvider)
                .previousSetMatches(view.exercise.id, workoutId, view.item.id),
            builder: (context, snapshot) {
              final matches = snapshot.data ?? const <String, WorkoutSet>{};
              return Column(
                children: [
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text('Set', textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text('kg', textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('Reps', textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('RPE', textAlign: TextAlign.center),
                      ),
                      Spacer(),
                    ],
                  ),
                  ...view.sets.map(
                    (set) => SetInputRow(
                      set: set,
                      previous: matches[set.id],
                      onComplete: (value) =>
                          _complete(context, ref, set, value),
                    ),
                  ),
                ],
              );
            },
          ),
          AppButton(
            onPressed: () => ref.read(databaseProvider).addSet(view.item.id),
            icon: Icons.add,
            label: 'Tambah set',
            expand: false,
            variant: AppActionVariant.quiet,
          ),
        ],
      ),
    ),
  );
}

class SetInputRow extends ConsumerWidget {
  const SetInputRow({
    required this.set,
    required this.onComplete,
    this.previous,
    super.key,
  });
  final WorkoutSet set;
  final WorkoutSet? previous;
  final ValueChanged<bool> onComplete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: TextButton(
                  onPressed: set.completed
                      ? null
                      : () async {
                          final value = await showAppActionSheet<String>(
                            context: context,
                            title: 'Set ${set.position + 1}',
                            actions: const [
                              AppAction(value: 'working', label: 'Working'),
                              AppAction(value: 'warmUp', label: 'Warm-up'),
                              AppAction(value: 'drop', label: 'Drop'),
                              AppAction(value: 'failure', label: 'Failure'),
                              AppAction(value: 'delete', label: 'Hapus set'),
                            ],
                          );
                          if (value == 'delete') {
                            await database.removeSet(set.id);
                          } else if (value != null) {
                            await database.updateWorkoutSet(
                              id: set.id,
                              type: value,
                            );
                          }
                        },
                  child: Text(switch (set.type) {
                    'warmUp' => 'W',
                    'drop' => 'D',
                    'failure' => 'F',
                    _ => '${set.position + 1}',
                  }),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 64,
                child: _AppCompactNumberField(
                  key: ValueKey('weight-${set.id}-${set.weightGrams}'),
                  initialValue: set.weightGrams == 0
                      ? ''
                      : formatKg(set.weightGrams),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  enabled: !set.completed,
                  onChanged: (value) {
                    final grams = parseKg(value);
                    if (grams >= 0)
                      database.updateWorkoutSet(id: set.id, weightGrams: grams);
                  },
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: _AppCompactNumberField(
                  key: ValueKey('reps-${set.id}-${set.reps}'),
                  initialValue: set.reps == 0 ? '' : '${set.reps}',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !set.completed,
                  onChanged: (value) => database.updateWorkoutSet(
                    id: set.id,
                    reps: int.tryParse(value) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: _AppCompactSelect(
                  value: set.rpe == null
                      ? '—'
                      : set.rpe!.toStringAsFixed(set.rpe! % 1 == 0 ? 0 : 1),
                  enabled: !set.completed,
                  onTap: () async {
                    final value = await showAppActionSheet<double>(
                      context: context,
                      title: 'Pilih RPE',
                      actions: List.generate(19, (i) {
                        final value = 1 + i * .5;
                        return AppAction(
                          value: value,
                          label: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                        );
                      }),
                    );
                    if (value != null) {
                      await database.updateWorkoutSet(id: set.id, rpe: value);
                    }
                  },
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Selesaikan set ${set.position + 1}',
                child: Checkbox(
                  value: set.completed,
                  onChanged: (value) {
                    if (value != null) onComplete(value);
                  },
                ),
              ),
            ],
          ),
          if (previous != null)
            Padding(
              padding: const EdgeInsets.only(left: 42, bottom: 2),
              child: Text(
                'Sebelumnya: ${formatKg(previous!.weightGrams)} kg × ${previous!.reps}${previous!.rpe == null ? '' : ' • RPE ${previous!.rpe}'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFeatures: tabularFigures),
              ),
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
