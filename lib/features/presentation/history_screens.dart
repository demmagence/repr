part of '../screens.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return GreekPageShell(
      topBar: const GreekTopBar(title: 'Riwayat'),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.history,
                title: 'Belum ada riwayat',
                body: 'Workout yang selesai akan muncul di sini.',
              )
            : ListView.separated(
                padding: pagePadding,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final workout = items[index];
                  final duration = workout.endedAt?.difference(
                    workout.startedAt,
                  );
                  return GreekPanel(
                    padding: EdgeInsets.zero,
                    child: GreekListRow(
                      minHeight: 82,
                      leading: GreekMedallion(
                        child: Text(DateFormat('dd').format(workout.startedAt)),
                      ),
                      title: workout.name,
                      subtitle:
                          '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(workout.startedAt)}${duration == null ? '' : ' • ${duration.inMinutes} menit'}',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/history/${workout.id}'),
                    ),
                  );
                },
              ),
      ),
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
                weight: formatKg(set.weightGrams),
                reps: '${set.reps}',
                type: set.type,
                rpe: set.rpe,
              ),
          ],
        ),
    ];
    try {
      await showGreekDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => GreekDialog(
            title: 'Edit riwayat',
            actions: [
              GreekButton(
                label: 'Batal',
                expand: false,
                compact: true,
                variant: GreekActionVariant.quiet,
                onPressed: () => Navigator.pop(context),
              ),
              GreekButton(
                label: 'Simpan',
                expand: false,
                compact: true,
                onPressed: () async {
                  final updates = <HistoricalExerciseUpdate>[];
                  for (final exercise in drafts) {
                    final sets = <HistoricalSetUpdate>[];
                    for (final set in exercise.sets) {
                      final weightGrams = parseKg(set.weight);
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
                  GreekTextField(controller: name, label: 'Nama workout'),
                  const SizedBox(height: 10),
                  GreekTextField(
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
        return const GreekPageShell(
          body: Center(child: CircularProgressIndicator()),
        );
      return GreekPageShell(
        topBar: GreekTopBar(
          title: workout.name,
          showBack: true,
          actions: [
            GreekIconButton(
              icon: Icons.more_vert,
              semanticLabel: 'Menu riwayat',
              onPressed: () async {
                final value = await showGreekActionSheet<String>(
                  context: context,
                  title: workout.name,
                  actions: const [
                    GreekAction(value: 'repeat', label: 'Ulangi workout'),
                    GreekAction(value: 'edit', label: 'Edit workout'),
                    GreekAction(value: 'date', label: 'Ubah tanggal'),
                    GreekAction(value: 'delete', label: 'Hapus', danger: true),
                  ],
                );
                if (!context.mounted) return;
                if (value == 'repeat') return _repeat(context, ref, workout);
                if (value == 'edit') return _edit(context, ref, workout);
                if (value == 'date') {
                  final date = await showDatePicker(
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
                  final yes = await showGreekDialog<bool>(
                    context: context,
                    builder: (context) => GreekDialog(
                      title: 'Hapus workout?',
                      actions: [
                        GreekButton(
                          label: 'Batal',
                          expand: false,
                          compact: true,
                          variant: GreekActionVariant.quiet,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        GreekButton(
                          label: 'Hapus',
                          expand: false,
                          compact: true,
                          variant: GreekActionVariant.destructive,
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
                      child: GreekStatPlaque(
                        label: 'Durasi',
                        value: '${duration?.inMinutes ?? 0} mnt',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GreekStatPlaque(
                        label: 'Set',
                        value: '${allSets.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GreekStatPlaque(
                        label: 'Volume',
                        value: '${volume.toStringAsFixed(0)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GreekPanel(
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.exercise.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                                        '${formatKg(set.weightGrams)} kg × ${set.reps}',
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
  Widget build(BuildContext context) => GreekPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.exerciseName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GreekTextField(
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
                  child: _GreekCompactNumberField(
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
                  child: _GreekCompactNumberField(
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
                  child: _GreekCompactSelect(
                    value: switch (set.type) {
                      'warmUp' => 'Warm-up',
                      'drop' => 'Drop',
                      'failure' => 'Failure',
                      _ => 'Working',
                    },
                    enabled: true,
                    onTap: () async {
                      final type = await showGreekActionSheet<String>(
                        context: context,
                        title: 'Jenis set ${set.position + 1}',
                        actions: const [
                          GreekAction(value: 'working', label: 'Working'),
                          GreekAction(value: 'warmUp', label: 'Warm-up'),
                          GreekAction(value: 'drop', label: 'Drop'),
                          GreekAction(value: 'failure', label: 'Failure'),
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
                  child: _GreekCompactSelect(
                    value: set.rpe == null
                        ? 'RPE'
                        : set.rpe!.toStringAsFixed(set.rpe! % 1 == 0 ? 0 : 1),
                    enabled: true,
                    onTap: () async {
                      final rpe = await showGreekActionSheet<double?>(
                        context: context,
                        title: 'RPE set ${set.position + 1}',
                        actions: [
                          const GreekAction(value: null, label: 'Tanpa RPE'),
                          ...List.generate(19, (index) {
                            final value = 1 + index * .5;
                            return GreekAction(
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
