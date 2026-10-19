part of '../screens.dart';

Future<void> _startWorkoutSession(
  BuildContext context,
  WidgetRef ref, {
  String? routineId,
  Workout? copied,
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
  final id = await database.startWorkout(
    routineId: routineId,
    copied: copied,
  );
  if (context.mounted) context.push('/workout/$id');
}

Future<void> _confirmAndStartRoutine(
  BuildContext context,
  WidgetRef ref,
  Routine routine,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: 'Mulai latihan?',
      actions: [
        AppButton(
          label: 'Batal',
          expand: false,
          variant: AppActionVariant.quiet,
          onPressed: () => Navigator.pop(context, false),
        ),
        AppButton(
          label: 'Mulai',
          expand: false,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      child: Text(
        routine.name.trim().isEmpty
            ? 'Mulai workout dari template routine ini?'
            : 'Mulai workout dari routine "${routine.name}"?',
      ),
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  await _startWorkoutSession(context, ref, routineId: routine.id);
}

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider).valueOrNull;
    final routines = ref.watch(routinesProvider);
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
                    'Train',
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
                  onPressed: () => showRoutineEditor(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Active workout banner
            if (active != null) ...[
              KineticCard(
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
                              'Workout sedang berjalan • Ketuk untuk lanjut',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],



            // Routines Header
            const Text(
              'Template Routine',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Routine list
            routines.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Gagal memuat routine: $error'),
              data: (items) => items.isEmpty
                  ? const SizedBox(
                      height: 200,
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
                            (routine) => _RoutineCard(
                              routine: routine,
                              onTap: () =>
                                  context.push('/routine/${routine.id}'),
                              onStart: () => _confirmAndStartRoutine(
                                context,
                                ref,
                                routine,
                              ),
                              onEdit: () => showRoutineEditor(
                                context,
                                ref,
                                routine: routine,
                              ),
                              onDelete: () => ref
                                  .read(databaseProvider)
                                  .deleteRoutine(routine.id),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({
    required this.routine,
    required this.onTap,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final namesAsync = ref.watch(routineExerciseNamesProvider(routine.id));
    final exerciseNames = namesAsync.valueOrNull ?? [];
    final exercisesText = exerciseNames.isNotEmpty
        ? exerciseNames.join(', ')
        : (routine.notes.isNotEmpty
            ? routine.notes
            : 'Belum ada latihan ditambahkan');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KineticCard(
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Routine Name & 3-dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      routine.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF8E8E93),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () async {
                      final value = await showAppActionSheet<String>(
                        context: context,
                        title: routine.name,
                        actions: const [
                          AppAction(
                            value: 'start',
                            label: 'Start Routine',
                          ),
                          AppAction(
                            value: 'edit',
                            label: 'Edit Routine',
                          ),
                          AppAction(
                            value: 'delete',
                            label: 'Hapus Routine',
                          ),
                        ],
                      );
                      if (value == 'start') {
                        onStart();
                      } else if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Exercises list / summary text
              SizedBox(
                width: double.infinity,
                child: Text(
                  exercisesText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "Start Routine" white button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Start Routine'),
                ),
              ),
            ],
          ),
        ),
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
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ExercisePicker(exercises: exercises, multiple: multiple),
  );
}

List<Exercise> filterExerciseLibrary(
  Iterable<Exercise> exercises, {
  String query = '',
  String? muscle,
  String? equipment,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return exercises.where((exercise) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        '${exercise.name} ${exercise.muscle} ${exercise.equipment}'
            .toLowerCase()
            .contains(normalizedQuery);
    final matchesMuscle = muscle == null || exercise.muscle == muscle;
    final matchesEquipment =
        equipment == null || exercise.equipment == equipment;
    return matchesQuery && matchesMuscle && matchesEquipment;
  }).toList();
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
  String? muscle;
  String? equipment;
  final selected = <String>{};
  Future<void> _openExerciseDemo(Exercise item) async {
    await showExerciseDemoSheet(
      context,
      exercise: ExerciseApiModel.fromLocal(item),
      onSelect: () {
        if (!widget.multiple) {
          Navigator.pop(context, [item]);
        } else {
          setState(() => selected.add(item.id));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscles = widget.exercises.map((item) => item.muscle).toSet().toList()
      ..sort();
    final equipmentOptions =
        widget.exercises.map((item) => item.equipment).toSet().toList()..sort();
    final items = filterExerciseLibrary(
      widget.exercises,
      query: query,
      muscle: muscle,
      equipment: equipment,
    );

    return AppPageShell(
      topBar: AppTopBar(
        title: 'Pilih exercise',
        showBack: true,
        actions: widget.multiple
            ? [
                AppButton(
                  label: 'Pilih (${selected.length})',
                  expand: false,
                  variant: AppActionVariant.quiet,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF71717A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: null,
                          onChanged: (value) => setState(() => query = value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'Search exercise',
                            hintStyle: const TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 14,
                            ),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF71717A),
                                    ),
                                    onPressed: () => setState(() => query = ''),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                        key: const Key('exercise-equipment-filter'),
                        initialValue: equipment,
                        tooltip: 'Filter Peralatan',
                        color: const Color(0xFF161618),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF27272A)),
                        ),
                        onSelected: (value) => setState(
                          () => equipment = value.isEmpty ? null : value,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: '',
                            child: Text('All Equipment', style: TextStyle(color: Colors.white)),
                          ),
                          for (final opt in equipmentOptions)
                            PopupMenuItem(
                              value: opt,
                              child: Text(opt, style: const TextStyle(color: Colors.white)),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: equipment != null
                                ? const Color(0xFF27272A)
                                : const Color(0xFF161618),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: equipment != null
                                  ? Colors.white24
                                  : const Color(0xFF27272A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                equipment ?? 'All Equipment',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: equipment != null
                                      ? Colors.white
                                      : const Color(0xFFA1A1AA),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Color(0xFF71717A),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        key: const Key('exercise-muscle-filter'),
                        initialValue: muscle,
                        tooltip: 'Filter Otot',
                        color: const Color(0xFF161618),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF27272A)),
                        ),
                        onSelected: (value) => setState(
                          () => muscle = value.isEmpty ? null : value,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: '',
                            child: Text('All Muscles', style: TextStyle(color: Colors.white)),
                          ),
                          for (final opt in muscles)
                            PopupMenuItem(
                              value: opt,
                              child: Text(opt, style: const TextStyle(color: Colors.white)),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: muscle != null
                                ? const Color(0xFF27272A)
                                : const Color(0xFF161618),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: muscle != null
                                  ? Colors.white24
                                  : const Color(0xFF27272A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                muscle ?? 'All Muscles',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: muscle != null
                                      ? Colors.white
                                      : const Color(0xFFA1A1AA),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Color(0xFF71717A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty && muscle == null && equipment == null
                      ? 'Recent Exercises'
                      : 'Exercises (${items.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'Exercise tidak ditemukan',
                    body: 'Ubah pencarian atau filter yang dipilih.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      MediaQuery.paddingOf(context).bottom + 120.0,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 80,
                      color: Color(0xFF1E1E20),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selected.contains(item.id);

                      return InkWell(
                        onTap: () {
                          if (!widget.multiple) {
                            Navigator.pop(context, [item]);
                          } else {
                            setState(
                              () => isSelected
                                  ? selected.remove(item.id)
                                  : selected.add(item.id),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161618),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF27272A),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: AppExerciseImage(
                                    gifUrl: item.gifUrl,
                                    exerciseId: item.id,
                                    fit: BoxFit.cover,
                                    fallbackIconSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFF4F4F5),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.muscle} • ${item.equipment}',
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
                              if (widget.multiple) ...[
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF52525B),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                              ],
                              KineticIconButton(
                                size: 34,
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFA1A1AA),
                                ),
                                onPressed: () => _openExerciseDemo(item),
                              ),
                            ],
                          ),
                        ),
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
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => RoutineEditorScreen(routine: routine),
    ),
  );
}

class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, this.routine});

  final Routine? routine;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  bool _loading = true;
  final List<_RoutineExerciseDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final database = ref.read(databaseProvider);
    final allExercises = await database.getAllExercises();
    final byId = {for (final exercise in allExercises) exercise.id: exercise};

    if (widget.routine != null) {
      final template = await database.getRoutineTemplate(widget.routine!.id);
      final weightUnit = ref.read(weightUnitProvider).valueOrNull ?? 'kg';
      _nameController.text = template.routine.name;
      _notesController.text = template.routine.notes;
      for (final item in template.exercises) {
        final ex = byId[item.exerciseId];
        if (ex != null) {
          _items.add(
            _RoutineExerciseDraft(
              exercise: ex,
              notes: item.notes,
              restSeconds: item.restSeconds,
              sets: item.sets
                  .map(
                    (s) => _RoutineSetDraft(
                      type: s.type,
                      weight: formatWeight(s.weightGrams, unit: weightUnit),
                      reps: s.reps > 0 ? s.reps.toString() : '10',
                    ),
                  )
                  .toList(),
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _items.isEmpty) {
      showMessage(context, 'Isi nama dan tambahkan minimal satu exercise.');
      return;
    }
    final database = ref.read(databaseProvider);
    final weightUnit = ref.read(weightUnitProvider).valueOrNull ?? 'kg';
    final exerciseTemplates = [
      for (final item in _items)
        RoutineExerciseTemplate(
          exerciseId: item.exercise.id,
          notes: item.notes,
          restSeconds: item.restSeconds,
          sets: [
            for (final set in item.sets)
              RoutineSetTemplate(
                type: set.type,
                weightGrams: parseWeight(set.weight, unit: weightUnit).clamp(0, 100000000),
                reps: (int.tryParse(set.reps.trim()) ?? 0).clamp(0, 9999),
              ),
          ],
        ),
    ];
    if (widget.routine == null) {
      await database.createRoutineTemplate(
        name: _nameController.text,
        notes: _notesController.text,
        exercises: exerciseTemplates,
      );
    } else {
      await database.updateRoutineTemplate(
        id: widget.routine!.id,
        name: _nameController.text,
        notes: _notesController.text,
        exercises: exerciseTemplates,
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.routine == null ? 'Routine baru' : 'Edit routine',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.paddingOf(context).bottom + 120.0,
                ),
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Nama routine',
                    hint: 'Contoh: Push Day',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _notesController,
                    label: 'Catatan routine',
                    hint: 'Opsional',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DAFTAR EXERCISE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.8,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27272A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () async {
                          final selected = await showExercisePicker(
                            context,
                            ref,
                            multiple: true,
                          );
                          if (selected == null || !mounted) return;
                          final database = ref.read(databaseProvider);
                          final weightUnit =
                              ref.read(weightUnitProvider).valueOrNull ?? 'kg';
                          final existing =
                              _items.map((item) => item.exercise.id).toSet();
                          final newDrafts = <_RoutineExerciseDraft>[];
                          for (final exercise in selected) {
                            if (existing.add(exercise.id)) {
                              final lastSet = await database
                                  .getLastCompletedSetForExercise(exercise.id);
                              final weightStr = lastSet != null
                                  ? formatWeight(
                                      lastSet.weightGrams,
                                      unit: weightUnit,
                                    )
                                  : '0';
                              final repsStr =
                                  (lastSet != null && lastSet.reps > 0)
                                      ? '${lastSet.reps}'
                                      : '10';
                              newDrafts.add(
                                _RoutineExerciseDraft(
                                  exercise: exercise,
                                  sets: [
                                    _RoutineSetDraft(
                                      type: 'working',
                                      weight: weightStr,
                                      reps: repsStr,
                                    ),
                                    _RoutineSetDraft(
                                      type: 'working',
                                      weight: weightStr,
                                      reps: repsStr,
                                    ),
                                    _RoutineSetDraft(
                                      type: 'working',
                                      weight: weightStr,
                                      reps: repsStr,
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          if (!mounted) return;
                          setState(() {
                            _items.addAll(newDrafts);
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah exercise'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.fitness_center,
                      title: 'Belum ada exercise',
                      body: 'Tambahkan gerakan untuk menyusun routine.',
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _items.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) => Padding(
                        key: ValueKey(_items[index].exercise.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RoutineExerciseEditor(
                          index: index,
                          item: _items[index],
                          weightUnit: weightUnit,
                          onChanged: () => setState(() {}),
                          onDelete: () => setState(() => _items.removeAt(index)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _RoutineSetDraft {
  _RoutineSetDraft({
    String? id,
    this.type = 'working',
    this.weight = '0',
    this.reps = '10',
  }) : id = id ?? const Uuid().v4();

  final String id;
  String type;
  String weight;
  String reps;
}

class _RoutineExerciseDraft {
  _RoutineExerciseDraft({
    required this.exercise,
    this.notes = '',
    this.restSeconds = 90,
    List<_RoutineSetDraft>? sets,
    List<String>? setTypes,
  }) : sets = sets ??
           (setTypes != null
               ? setTypes.map((t) => _RoutineSetDraft(type: t)).toList()
               : [
                   _RoutineSetDraft(type: 'working'),
                   _RoutineSetDraft(type: 'working'),
                   _RoutineSetDraft(type: 'working'),
                 ]);

  final Exercise exercise;
  String notes;
  int restSeconds;
  final List<_RoutineSetDraft> sets;

  List<String> get setTypes => sets.map((s) => s.type).toList();
}

class _RoutineExerciseEditor extends StatelessWidget {
  const _RoutineExerciseEditor({
    required this.index,
    required this.item,
    required this.weightUnit,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _RoutineExerciseDraft item;
  final String weightUnit;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  static const setLabels = {
    'working': 'Working',
    'warmUp': 'Warm-up',
    'drop': 'Drop',
    'failure': 'Failure',
  };

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const SizedBox.square(
                dimension: 40,
                child: Icon(Icons.drag_handle, color: Color(0xFF71717A)),
              ),
            ),
            Expanded(
              child: Text(
                item.exercise.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppButton(
              label: formatRestDuration(item.restSeconds, compact: true),
              expand: false,
              variant: AppActionVariant.quiet,
              onPressed: () async {
                final value = await showAppActionSheet<int>(
                  context: context,
                  title: 'Rest timer ${item.exercise.name}',
                  actions: const [30, 60, 90, 120, 180, 300]
                      .map(
                        (seconds) =>
                            AppAction(
                              value: seconds,
                              label: formatRestDuration(seconds, uppercase: false),
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
            AppIconButton(
              icon: Icons.delete_outline,
              semanticLabel: 'Hapus ${item.exercise.name}',
              onPressed: onDelete,
            ),
          ],
        ),
        AppTextField(
          key: ValueKey('notes-${item.exercise.id}'),
          initialValue: item.notes,
          label: 'Catatan exercise',
          hint: 'Opsional',
          onChanged: (value) => item.notes = value,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                flex: 3,
                child: Text(
                  'TIPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  'BEBAN (${weightUnit.toUpperCase()})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                flex: 2,
                child: Text(
                  'REPS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 76),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(item.sets.length, (setIndex) {
          final set = item.sets[setIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${setIndex + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Type selector
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () async {
                      final selected = await showAppActionSheet<String>(
                        context: context,
                        title: 'Jenis set ${setIndex + 1}',
                        actions: setLabels.entries
                            .map(
                              (entry) =>
                                  AppAction(value: entry.key, label: entry.value),
                            )
                            .toList(),
                      );
                      if (selected != null) {
                        set.type = selected;
                        onChanged();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              setLabels[set.type] ?? 'Working',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: Color(0xFF71717A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Weight input
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF09090B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    alignment: Alignment.center,
                    child: TextFormField(
                      key: ValueKey('routine-weight-${set.id}'),
                      initialValue: set.weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        fontFeatures: tabularFigures,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Color(0xFF52525B)),
                      ),
                      onChanged: (value) => set.weight = value,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Reps input
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF09090B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    alignment: Alignment.center,
                    child: TextFormField(
                      key: ValueKey('routine-reps-${set.id}'),
                      initialValue: set.reps,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        fontFeatures: tabularFigures,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Color(0xFF52525B)),
                      ),
                      onChanged: (value) => set.reps = value,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Reorder / Delete Actions
                SizedBox(
                  width: 76,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: 'Naikkan set ${setIndex + 1}',
                        child: InkWell(
                          onTap: setIndex == 0
                              ? null
                              : () {
                                  final value = item.sets.removeAt(setIndex);
                                  item.sets.insert(setIndex - 1, value);
                                  onChanged();
                                },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: setIndex == 0
                                  ? const Color(0xFF3F3F46)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Turunkan set ${setIndex + 1}',
                        child: InkWell(
                          onTap: setIndex == item.sets.length - 1
                              ? null
                              : () {
                                  final value = item.sets.removeAt(setIndex);
                                  item.sets.insert(setIndex + 1, value);
                                  onChanged();
                                },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: setIndex == item.sets.length - 1
                                  ? const Color(0xFF3F3F46)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Hapus set ${setIndex + 1}',
                        child: InkWell(
                          onTap: item.sets.length == 1
                              ? null
                              : () {
                                  item.sets.removeAt(setIndex);
                                  onChanged();
                                },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                            child: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 16,
                              color: item.sets.length == 1
                                  ? const Color(0xFF3F3F46)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        AppButton(
          label: 'Tambah set',
          icon: Icons.add,
          expand: false,
          variant: AppActionVariant.quiet,
          onPressed: () {
            final lastSet = item.sets.isNotEmpty ? item.sets.last : null;
            item.sets.add(
              _RoutineSetDraft(
                type: 'working',
                weight: lastSet?.weight ?? '0',
                reps: lastSet?.reps ?? '10',
              ),
            );
            onChanged();
          },
        ),
      ],
    ),
  );
}

final routineDetailProvider =
    FutureProvider.autoDispose.family<RoutineDetailData, String>((ref, id) {
  return ref.watch(databaseProvider).getRoutineDetail(id);
});

enum _RoutineMetricType { volume, reps, duration }

class RoutineDetailScreen extends ConsumerStatefulWidget {
  const RoutineDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  _RoutineMetricType _selectedMetric = _RoutineMetricType.volume;

  Future<void> _start(Routine routine) async {
    await _confirmAndStartRoutine(context, ref, routine);
  }

  Future<void> _edit(Routine routine) async {
    await showRoutineEditor(context, ref, routine: routine);
    ref.invalidate(routineDetailProvider(widget.id));
  }

  Future<void> _delete(Routine routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161618),
        title: const Text(
          'Hapus Routine',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus routine "${routine.name}"?',
          style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF71717A))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(databaseProvider).deleteRoutine(routine.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showMoreOptions(Routine routine) async {
    final val = await showAppActionSheet<String>(
      context: context,
      title: routine.name,
      actions: const [
        AppAction(value: 'start', label: 'Start Routine'),
        AppAction(value: 'edit', label: 'Edit Routine'),
        AppAction(value: 'delete', label: 'Hapus Routine'),
      ],
    );
    if (!mounted) return;
    if (val == 'start') {
      _start(routine);
    } else if (val == 'edit') {
      _edit(routine);
    } else if (val == 'delete') {
      _delete(routine);
    }
  }

  Widget _buildMetricPill({
    required String label,
    required _RoutineMetricType type,
  }) {
    final isSelected = _selectedMetric == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF0284C7) : const Color(0xFF161618),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF27272A),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(routineDetailProvider(widget.id));
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    final isLbs = weightUnit == 'lbs';

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Routine',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          detailAsync.maybeWhen(
            data: (detail) => IconButton(
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF8E8E93),
              ),
              onPressed: () => _showMoreOptions(detail.routine),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat routine: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (detail) {
          final points = detail.historyPoints;

          // Target calculations
          var plannedVolumeGrams = 0;
          var plannedTotalReps = 0;
          for (final ex in detail.exercises) {
            for (final s in ex.sets) {
              if (s.type != 'warmUp') {
                plannedVolumeGrams += s.weightGrams * s.reps;
                plannedTotalReps += s.reps;
              }
            }
          }

          // Metric Card Headline
          String metricHeadline;
          String metricSubtitle;
          if (points.isNotEmpty) {
            final lastPoint = points.last;
            final dateStr = DateFormat(
              'd MMM',
              'id_ID',
            ).format(lastPoint.workout.startedAt);
            if (_selectedMetric == _RoutineMetricType.volume) {
              metricHeadline =
                  '${formatWeight((lastPoint.volumeKg * 1000).round(), unit: weightUnit)} $weightUnit';
              metricSubtitle = dateStr;
            } else if (_selectedMetric == _RoutineMetricType.reps) {
              metricHeadline = '${lastPoint.totalReps} reps';
              metricSubtitle = dateStr;
            } else {
              metricHeadline = '${lastPoint.durationMinutes}m';
              metricSubtitle = dateStr;
            }
          } else {
            if (_selectedMetric == _RoutineMetricType.volume) {
              metricHeadline =
                  '${formatWeight(plannedVolumeGrams, unit: weightUnit)} $weightUnit';
              metricSubtitle = 'Target per sesi';
            } else if (_selectedMetric == _RoutineMetricType.reps) {
              metricHeadline = '$plannedTotalReps reps';
              metricSubtitle = 'Target per sesi';
            } else {
              metricHeadline = 'Est. 45m';
              metricSubtitle = 'Estimasi sesi';
            }
          }

          // Chart values
          final chartValues = <double>[];
          if (_selectedMetric == _RoutineMetricType.volume) {
            chartValues.addAll(
              points.map(
                (p) => isLbs ? p.volumeKg * 2.20462 : p.volumeKg,
              ),
            );
          } else if (_selectedMetric == _RoutineMetricType.reps) {
            chartValues.addAll(points.map((p) => p.totalReps.toDouble()));
          } else {
            chartValues.addAll(points.map((p) => p.durationMinutes.toDouble()));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // Routine Title
              Text(
                detail.routine.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail.routine.notes.isNotEmpty
                    ? detail.routine.notes
                    : 'Template Routine',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Start Routine Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('routine-detail-start-button'),
                  onPressed: () => _start(detail.routine),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Start Routine'),
                ),
              ),
              const SizedBox(height: 20),

              // Metrics & Chart Card
              KineticCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              metricHeadline,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              metricSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          points.isNotEmpty
                              ? '${points.length} Sesi'
                              : '0 Sesi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71717A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chart area
                    if (points.isEmpty)
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101012),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Belum ada riwayat sesi.\nSelesaikan routine ini untuk melihat grafik perkembangan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF71717A),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 130,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => const FlLine(
                                color: Color(0xFF27272A),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: (points.length > 5
                                      ? (points.length / 4).ceilToDouble()
                                      : 1),
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx < 0 || idx >= points.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat(
                                          'd MMM',
                                          'id_ID',
                                        ).format(points[idx].workout.startedAt),
                                        style: const TextStyle(
                                          color: Color(0xFF71717A),
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (points.length - 1)
                                .toDouble()
                                .clamp(1.0, 1000.0),
                            minY: (chartValues.reduce((a, b) => a < b ? a : b) *
                                    0.85)
                                .floorToDouble()
                                .clamp(0.0, double.infinity),
                            maxY: (chartValues.reduce((a, b) => a > b ? a : b) *
                                    1.15 +
                                1),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  if (chartValues.length == 1) ...[
                                    FlSpot(0, chartValues[0]),
                                    FlSpot(1, chartValues[0]),
                                  ] else
                                    for (var i = 0; i < chartValues.length; i++)
                                      FlSpot(i.toDouble(), chartValues[i]),
                                ],
                                isCurved: chartValues.length > 2,
                                color: const Color(0xFF38BDF8),
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 3.5,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF38BDF8),
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.25),
                                      const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Metric toggles: Volume, Reps, Duration
                    Row(
                      children: [
                        _buildMetricPill(
                          label: 'Volume',
                          type: _RoutineMetricType.volume,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricPill(
                          label: 'Reps',
                          type: _RoutineMetricType.reps,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricPill(
                          label: 'Duration',
                          type: _RoutineMetricType.duration,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Exercises Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercises (${detail.exercises.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: () => _edit(detail.routine),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Edit Routine',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Exercises List
              for (final item in detail.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KineticCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Header
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.exercise.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rest Timer
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Color(0xFF8E8E93),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rest Timer: ${item.restSeconds ~/ 60}min ${item.restSeconds % 60}s',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Table Header
                        Row(
                          children: [
                            const SizedBox(
                              width: 48,
                              child: Text(
                                'SET',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF71717A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'BEBAN (${weightUnit.toUpperCase()})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF71717A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 60,
                              child: Text(
                                'REPS',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF71717A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF27272A), height: 1),
                        const SizedBox(height: 8),

                        // Sets Rows
                        for (var i = 0; i < item.sets.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    formatWeight(
                                      item.sets[i].weightGrams,
                                      unit: weightUnit,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '${item.sets[i].reps}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
