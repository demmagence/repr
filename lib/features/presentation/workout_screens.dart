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
    final confirmed = await showGreekDialog<bool>(
      context: context,
      builder: (context) => GreekDialog(
        title: 'Selesaikan workout?',
        actions: [
          GreekButton(
            label: 'Kembali',
            expand: false,
            compact: true,
            variant: GreekActionVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          GreekButton(
            label: 'Selesaikan',
            expand: false,
            compact: true,
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
    await showGreekDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GreekDialog(
        title: 'Workout selesai',
        actions: [
          GreekButton(
            label: 'Lihat riwayat',
            expand: false,
            compact: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GreekStatPlaque(
                    label: 'Durasi',
                    value: '${summary.duration.inMinutes} mnt',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GreekStatPlaque(
                    label: 'Set',
                    value: '${summary.completedSets}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GreekStatPlaque(
                    label: 'Volume',
                    value: '${summary.volumeKg.toStringAsFixed(0)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.personalRecords.isEmpty)
              const GreekEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Belum ada PR baru',
                body: 'Konsistensi hari ini tetap tercatat.',
              )
            else ...[
              Text(
                'PR BARU',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: GreekColors.terracotta,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              for (final record in summary.personalRecords)
                GreekListRow(
                  leading: const GreekMedallion(
                    active: true,
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
    final confirmed = await showGreekDialog<bool>(
      context: context,
      builder: (context) => GreekDialog(
        title: 'Buang workout?',
        actions: [
          GreekButton(
            label: 'Batal',
            expand: false,
            compact: true,
            variant: GreekActionVariant.quiet,
            onPressed: () => Navigator.pop(context, false),
          ),
          GreekButton(
            label: 'Buang',
            expand: false,
            compact: true,
            variant: GreekActionVariant.destructive,
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
      loading: () => const GreekPageShell(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => GreekPageShell(body: Center(child: Text('$error'))),
      data: (item) {
        if (item == null)
          return const GreekPageShell(
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
          child: GreekPageShell(
            topBar: GreekTopBar(
              title: item.name,
              subtitle: elapsedLabel,
              showBack: true,
              compact: true,
              actions: [
                GreekButton(
                  label: 'Selesai',
                  onPressed: _finish,
                  expand: false,
                  compact: true,
                  variant: GreekActionVariant.quiet,
                ),
                GreekIconButton(
                  icon: Icons.more_vert,
                  semanticLabel: 'Menu workout',
                  onPressed: () async {
                    final value = await showGreekActionSheet<String>(
                      context: context,
                      title: 'Menu workout',
                      actions: const [
                        GreekAction(
                          value: 'discard',
                          label: 'Buang workout',
                          danger: true,
                        ),
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
                  GreekPanel(
                    variant: GreekPanelVariant.warning,
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        GreekButton(
                          label: 'Lewati',
                          expand: false,
                          compact: true,
                          variant: GreekActionVariant.quiet,
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
              child: GreekButton(
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
    final permitted = await service.requestPermission();
    if (permitted) {
      try {
        await service.scheduleRestEnd(end, sound: sound);
      } catch (_) {
        if (context.mounted)
          showMessage(
            context,
            'Timer aktif di aplikasi; notifikasi latar tidak tersedia.',
          );
      }
    } else if (context.mounted) {
      showMessage(
        context,
        'Timer aktif di aplikasi. Izin notifikasi belum diberikan.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => GreekPanel(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${view.exercise.muscle} • istirahat ${view.item.restSeconds} dtk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GreekIconButton(
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
          GreekButton(
            onPressed: () => ref.read(databaseProvider).addSet(view.item.id),
            icon: Icons.add,
            label: 'Tambah set',
            expand: false,
            compact: true,
            variant: GreekActionVariant.quiet,
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
                width: 38,
                height: 48,
                child: Semantics(
                  button: true,
                  label: 'Jenis set',
                  child: InkWell(
                    onTap: set.completed
                        ? null
                        : () async {
                            final value = await showGreekActionSheet<String>(
                              context: context,
                              title: 'Set ${set.position + 1}',
                              actions: const [
                                GreekAction(value: 'working', label: 'Working'),
                                GreekAction(value: 'warmUp', label: 'Warm-up'),
                                GreekAction(value: 'drop', label: 'Drop'),
                                GreekAction(value: 'failure', label: 'Failure'),
                                GreekAction(
                                  value: 'delete',
                                  label: 'Hapus set',
                                  danger: true,
                                ),
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
                    child: Center(
                      child: GreekMedallion(
                        active: set.completed,
                        child: Text(switch (set.type) {
                          'warmUp' => 'W',
                          'drop' => 'D',
                          'failure' => 'F',
                          _ => '${set.position + 1}',
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 64,
                child: _GreekCompactNumberField(
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
                child: _GreekCompactNumberField(
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
                child: _GreekCompactSelect(
                  value: set.rpe == null
                      ? '—'
                      : set.rpe!.toStringAsFixed(set.rpe! % 1 == 0 ? 0 : 1),
                  enabled: !set.completed,
                  onTap: () async {
                    final value = await showGreekActionSheet<double>(
                      context: context,
                      title: 'Pilih RPE',
                      actions: List.generate(19, (i) {
                        final value = 1 + i * .5;
                        return GreekAction(
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
              SizedBox.square(
                dimension: 48,
                child: Semantics(
                  checked: set.completed,
                  button: true,
                  label: 'Selesaikan set ${set.position + 1}',
                  child: InkWell(
                    onTap: () => onComplete(!set.completed),
                    child: Container(
                      margin: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: set.completed
                            ? GreekColors.olive
                            : Colors.transparent,
                        border: Border.all(
                          color: set.completed
                              ? GreekColors.olive
                              : GreekColors.bronze,
                        ),
                      ),
                      child: set.completed
                          ? const Icon(
                              Icons.check,
                              size: 17,
                              color: GreekColors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (previous != null)
            Padding(
              padding: const EdgeInsets.only(left: 42, bottom: 2),
              child: Text(
                'Sebelumnya: ${formatKg(previous!.weightGrams)} kg × ${previous!.reps}${previous!.rpe == null ? '' : ' • RPE ${previous!.rpe}'}',
                style: const TextStyle(
                  color: GreekColors.inkMuted,
                  fontSize: 10,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GreekCompactNumberField extends StatelessWidget {
  const _GreekCompactNumberField({
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
  Widget build(BuildContext context) => Container(
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: enabled ? GreekColors.marbleLight : GreekColors.limestone,
      border: Border.all(color: GreekColors.limestoneDark),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      decoration: const InputDecoration.collapsed(hintText: '—'),
      style: const TextStyle(fontSize: 14, fontFeatures: tabularFigures),
    ),
  );
}

class _GreekCompactSelect extends StatelessWidget {
  const _GreekCompactSelect({
    required this.value,
    required this.enabled,
    required this.onTap,
  });
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: 'RPE $value',
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? GreekColors.marbleLight : GreekColors.limestone,
          border: Border.all(color: GreekColors.limestoneDark),
        ),
        child: Text(
          value,
          style: const TextStyle(fontFeatures: tabularFigures),
        ),
      ),
    ),
  );
}
