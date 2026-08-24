part of '../screens.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref, {
    String? routineId,
    Workout? copied,
  }) async {
    final database = ref.read(databaseProvider);
    final active = await database.getActiveWorkout();
    if (!context.mounted) return;
    if (active != null) {
      final discard = await showGreekDialog<bool>(
        context: context,
        builder: (context) => GreekDialog(
          title: 'Workout masih aktif',
          actions: [
            GreekButton(
              label: 'Lanjutkan',
              expand: false,
              compact: true,
              variant: GreekActionVariant.secondary,
              onPressed: () {
                Navigator.pop(context, false);
                context.push('/workout/${active.id}');
              },
            ),
            GreekButton(
              label: 'Buang draft',
              expand: false,
              compact: true,
              variant: GreekActionVariant.destructive,
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
    final id = await database.startWorkout(
      routineId: routineId,
      copied: copied,
    );
    if (context.mounted) context.push('/workout/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider).valueOrNull;
    final routines = ref.watch(routinesProvider);
    return GreekPageShell(
      topBar: const GreekTopBar(brand: true),
      body: ListView(
        padding: pagePadding,
        children: [
          const GreekMottoBanner(),
          const SizedBox(height: 16),
          if (active != null) ...[
            GreekPanel(
              variant: GreekPanelVariant.active,
              padding: EdgeInsets.zero,
              child: GreekListRow(
                minHeight: 72,
                leading: const GreekMedallion(
                  active: true,
                  child: Icon(Icons.timer_outlined, size: 20),
                ),
                title: active.name,
                subtitle: 'Workout sedang berjalan',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workout/${active.id}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          GreekButton(
            onPressed: () => _start(context, ref),
            icon: Icons.add,
            label: 'Mulai latihan kosong',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Routine',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GreekButton(
                onPressed: () => showRoutineEditor(context, ref),
                icon: Icons.add,
                label: 'Buat',
                expand: false,
                compact: true,
                variant: GreekActionVariant.quiet,
              ),
            ],
          ),
          const SizedBox(height: 8),
          routines.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Gagal memuat routine: $error'),
            data: (items) => items.isEmpty
                ? const SizedBox(
                    height: 240,
                    child: EmptyState(
                      icon: Icons.view_list_outlined,
                      title: 'Belum ada routine',
                      body:
                          'Buat template latihan agar sesi berikutnya lebih cepat dimulai.',
                    ),
                  )
                : Column(
                    children: items
                        .map(
                          (routine) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GreekPanel(
                              padding: EdgeInsets.zero,
                              child: GreekListRow(
                                minHeight: 72,
                                leading: GreekMedallion(
                                  child: Text(
                                    routine.name.substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                title: routine.name,
                                subtitle: routine.notes.isEmpty
                                    ? 'Template latihan tersimpan'
                                    : routine.notes,
                                onTap: () =>
                                    _start(context, ref, routineId: routine.id),
                                trailing: GreekIconButton(
                                  icon: Icons.more_vert,
                                  semanticLabel: 'Menu ${routine.name}',
                                  onPressed: () async {
                                    final value =
                                        await showGreekActionSheet<String>(
                                          context: context,
                                          title: routine.name,
                                          actions: const [
                                            GreekAction(
                                              value: 'start',
                                              label: 'Mulai',
                                            ),
                                            GreekAction(
                                              value: 'edit',
                                              label: 'Edit routine',
                                            ),
                                            GreekAction(
                                              value: 'delete',
                                              label: 'Hapus',
                                              danger: true,
                                            ),
                                          ],
                                        );
                                    if (!context.mounted) return;
                                    if (value == 'start') {
                                      await _start(
                                        context,
                                        ref,
                                        routineId: routine.id,
                                      );
                                    } else if (value == 'edit') {
                                      await showRoutineEditor(
                                        context,
                                        ref,
                                        routine: routine,
                                      );
                                    } else if (value == 'delete') {
                                      await ref
                                          .read(databaseProvider)
                                          .deleteRoutine(routine.id);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<List<Exercise>?> showExercisePicker(
  BuildContext context,
  WidgetRef ref, {
  bool multiple = false,
}) async {
  final exercises = await ref.read(databaseProvider).watchExercises().first;
  if (!context.mounted) return null;
  return showModalBottomSheet<List<Exercise>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: GreekColors.aegeanDeep.withValues(alpha: .55),
    builder: (context) =>
        _ExercisePicker(exercises: exercises, multiple: multiple),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.exercises, required this.multiple});
  final List<Exercise> exercises;
  final bool multiple;
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  var query = '';
  final selected = <String>{};
  @override
  Widget build(BuildContext context) {
    final items = widget.exercises
        .where(
          (e) => '${e.name} ${e.muscle} ${e.equipment}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return GreekPageShell(
      topBar: GreekTopBar(
        title: 'Pilih exercise',
        showBack: true,
        compact: true,
        actions: widget.multiple
            ? [
                GreekButton(
                  label: 'Pilih (${selected.length})',
                  expand: false,
                  compact: true,
                  variant: GreekActionVariant.quiet,
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          widget.exercises
                              .where((e) => selected.contains(e.id))
                              .toList(),
                        ),
                ),
              ]
            : const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GreekTextField(
              leading: Icons.search,
              hint: 'Cari nama, otot, atau alat',
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GreekCheckTile(
                  value: selected.contains(item.id),
                  leading: GreekMedallion(
                    child: Text(item.name.substring(0, 1)),
                  ),
                  title: item.name,
                  subtitle: '${item.muscle} • ${item.equipment}',
                  onChanged: (_) {
                    if (!widget.multiple) return Navigator.pop(context, [item]);
                    setState(
                      () => selected.contains(item.id)
                          ? selected.remove(item.id)
                          : selected.add(item.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showRoutineEditor(
  BuildContext context,
  WidgetRef ref, {
  Routine? routine,
}) async {
  final database = ref.read(databaseProvider);
  final allExercises = await database.getAllExercises();
  if (!context.mounted) return;
  final byId = {for (final exercise in allExercises) exercise.id: exercise};
  RoutineTemplate? template;
  if (routine != null) template = await database.getRoutineTemplate(routine.id);
  if (!context.mounted) return;

  final name = TextEditingController(text: template?.routine.name ?? '');
  final notes = TextEditingController(text: template?.routine.notes ?? '');
  final items = <_RoutineExerciseDraft>[
    for (final item in template?.exercises ?? const <RoutineExerciseTemplate>[])
      if (byId[item.exerciseId] != null)
        _RoutineExerciseDraft(
          exercise: byId[item.exerciseId]!,
          notes: item.notes,
          restSeconds: item.restSeconds,
          setTypes: [...item.setTypes],
        ),
  ];

  try {
    await showGreekDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => GreekDialog(
          title: routine == null ? 'Routine baru' : 'Edit routine',
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
                if (name.text.trim().isEmpty || items.isEmpty) {
                  return showMessage(
                    context,
                    'Isi nama dan tambahkan minimal satu exercise.',
                  );
                }
                final exerciseTemplates = [
                  for (final item in items)
                    RoutineExerciseTemplate(
                      exerciseId: item.exercise.id,
                      notes: item.notes,
                      restSeconds: item.restSeconds,
                      setTypes: [...item.setTypes],
                    ),
                ];
                if (routine == null) {
                  await database.createRoutineTemplate(
                    name: name.text,
                    notes: notes.text,
                    exercises: exerciseTemplates,
                  );
                } else {
                  await database.updateRoutineTemplate(
                    id: routine.id,
                    name: name.text,
                    notes: notes.text,
                    exercises: exerciseTemplates,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          child: SizedBox(
            width: 440,
            height: MediaQuery.sizeOf(context).height * .68,
            child: Column(
              children: [
                GreekTextField(
                  controller: name,
                  label: 'Nama routine',
                  hint: 'Contoh: Push Day',
                ),
                const SizedBox(height: 10),
                GreekTextField(
                  controller: notes,
                  label: 'Catatan routine',
                  hint: 'Opsional',
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                GreekButton(
                  onPressed: () async {
                    final selected = await showExercisePicker(
                      dialogContext,
                      ref,
                      multiple: true,
                    );
                    if (selected == null || !context.mounted) return;
                    setState(() {
                      final existing = items
                          .map((item) => item.exercise.id)
                          .toSet();
                      for (final exercise in selected) {
                        if (existing.add(exercise.id)) {
                          items.add(_RoutineExerciseDraft(exercise: exercise));
                        }
                      }
                    });
                  },
                  icon: Icons.add,
                  variant: GreekActionVariant.secondary,
                  label: 'Tambah exercise',
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? const GreekEmptyState(
                          icon: Icons.fitness_center,
                          title: 'Belum ada exercise',
                          body: 'Tambahkan gerakan untuk menyusun routine.',
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: items.length,
                          onReorderItem: (oldIndex, newIndex) {
                            setState(() {
                              final item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) => Padding(
                            key: ValueKey(items[index].exercise.id),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RoutineExerciseEditor(
                              index: index,
                              item: items[index],
                              onChanged: () => setState(() {}),
                              onDelete: () =>
                                  setState(() => items.removeAt(index)),
                            ),
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

class _RoutineExerciseDraft {
  _RoutineExerciseDraft({
    required this.exercise,
    this.notes = '',
    this.restSeconds = 90,
    List<String>? setTypes,
  }) : setTypes = setTypes ?? ['working', 'working', 'working'];

  final Exercise exercise;
  String notes;
  int restSeconds;
  final List<String> setTypes;
}

class _RoutineExerciseEditor extends StatelessWidget {
  const _RoutineExerciseEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _RoutineExerciseDraft item;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  static const setLabels = {
    'working': 'Working',
    'warmUp': 'Warm-up',
    'drop': 'Drop',
    'failure': 'Failure',
  };

  @override
  Widget build(BuildContext context) => GreekPanel(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(Icons.drag_handle),
              ),
            ),
            Expanded(
              child: Text(
                item.exercise.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GreekButton(
              label: '${item.restSeconds} dtk',
              expand: false,
              compact: true,
              variant: GreekActionVariant.quiet,
              onPressed: () async {
                final value = await showGreekActionSheet<int>(
                  context: context,
                  title: 'Rest timer ${item.exercise.name}',
                  actions: const [30, 60, 90, 120, 180, 300]
                      .map(
                        (seconds) => GreekAction(
                          value: seconds,
                          label: '$seconds detik',
                        ),
                      )
                      .toList(),
                );
                if (value != null) {
                  item.restSeconds = value;
                  onChanged();
                }
              },
            ),
            GreekIconButton(
              icon: Icons.delete_outline,
              semanticLabel: 'Hapus ${item.exercise.name}',
              danger: true,
              onPressed: onDelete,
            ),
          ],
        ),
        GreekTextField(
          key: ValueKey('notes-${item.exercise.id}'),
          initialValue: item.notes,
          label: 'Catatan exercise',
          hint: 'Opsional',
          onChanged: (value) => item.notes = value,
        ),
        const SizedBox(height: 8),
        ...List.generate(item.setTypes.length, (setIndex) {
          final type = item.setTypes[setIndex];
          return Row(
            children: [
              SizedBox(width: 34, child: Text('${setIndex + 1}.')),
              Expanded(
                child: GreekButton(
                  label: setLabels[type]!,
                  compact: true,
                  variant: GreekActionVariant.secondary,
                  onPressed: () async {
                    final selected = await showGreekActionSheet<String>(
                      context: context,
                      title: 'Jenis set ${setIndex + 1}',
                      actions: setLabels.entries
                          .map(
                            (entry) => GreekAction(
                              value: entry.key,
                              label: entry.value,
                            ),
                          )
                          .toList(),
                    );
                    if (selected != null) {
                      item.setTypes[setIndex] = selected;
                      onChanged();
                    }
                  },
                ),
              ),
              GreekIconButton(
                icon: Icons.arrow_upward,
                semanticLabel: 'Naikkan set ${setIndex + 1}',
                onPressed: setIndex == 0
                    ? null
                    : () {
                        final value = item.setTypes.removeAt(setIndex);
                        item.setTypes.insert(setIndex - 1, value);
                        onChanged();
                      },
              ),
              GreekIconButton(
                icon: Icons.arrow_downward,
                semanticLabel: 'Turunkan set ${setIndex + 1}',
                onPressed: setIndex == item.setTypes.length - 1
                    ? null
                    : () {
                        final value = item.setTypes.removeAt(setIndex);
                        item.setTypes.insert(setIndex + 1, value);
                        onChanged();
                      },
              ),
              GreekIconButton(
                icon: Icons.remove_circle_outline,
                semanticLabel: 'Hapus set ${setIndex + 1}',
                danger: true,
                onPressed: item.setTypes.length == 1
                    ? null
                    : () {
                        item.setTypes.removeAt(setIndex);
                        onChanged();
                      },
              ),
            ],
          );
        }),
        GreekButton(
          label: 'Tambah set',
          icon: Icons.add,
          expand: false,
          compact: true,
          variant: GreekActionVariant.quiet,
          onPressed: () {
            item.setTypes.add('working');
            onChanged();
          },
        ),
      ],
    ),
  );
}
