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
    await _start(context, ref, routineId: routine.id);
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Template Routine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => showRoutineEditor(context, ref),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '+ Buat Baru',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
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
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final Routine routine;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Routine Name & 3-dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onStart,
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onStart,
              child: SizedBox(
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
            ),
            const SizedBox(height: 16),
            // "Start Routine" blue button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
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
                    padding: const EdgeInsets.only(bottom: 24),
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
  return Navigator.of(context).push(
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
              setTypes: [...item.setTypes],
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
    final exerciseTemplates = [
      for (final item in _items)
        RoutineExerciseTemplate(
          exerciseId: item.exercise.id,
          notes: item.notes,
          restSeconds: item.restSeconds,
          setTypes: [...item.setTypes],
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                          setState(() {
                            final existing =
                                _items.map((item) => item.exercise.id).toSet();
                            for (final exercise in selected) {
                              if (existing.add(exercise.id)) {
                                _items.add(
                                  _RoutineExerciseDraft(exercise: exercise),
                                );
                              }
                            }
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
  Widget build(BuildContext context) => AppCard(
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
            AppButton(
              label: '${item.restSeconds} dtk',
              expand: false,
              variant: AppActionVariant.quiet,
              onPressed: () async {
                final value = await showAppActionSheet<int>(
                  context: context,
                  title: 'Rest timer ${item.exercise.name}',
                  actions: const [30, 60, 90, 120, 180, 300]
                      .map(
                        (seconds) =>
                            AppAction(value: seconds, label: '$seconds detik'),
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
        const SizedBox(height: 8),
        ...List.generate(item.setTypes.length, (setIndex) {
          final type = item.setTypes[setIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${setIndex + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: AppButton(
                    label: setLabels[type]!,
                    variant: AppActionVariant.secondary,
                    onPressed: () async {
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
                        item.setTypes[setIndex] = selected;
                        onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Naikkan set ${setIndex + 1}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: setIndex == 0
                      ? null
                      : () {
                          final value = item.setTypes.removeAt(setIndex);
                          item.setTypes.insert(setIndex - 1, value);
                          onChanged();
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Turunkan set ${setIndex + 1}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: setIndex == item.setTypes.length - 1
                      ? null
                      : () {
                          final value = item.setTypes.removeAt(setIndex);
                          item.setTypes.insert(setIndex + 1, value);
                          onChanged();
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  tooltip: 'Hapus set ${setIndex + 1}',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: item.setTypes.length == 1
                      ? null
                      : () {
                          item.setTypes.removeAt(setIndex);
                          onChanged();
                        },
                ),
              ],
            ),
          );
        }),
        AppButton(
          label: 'Tambah set',
          icon: Icons.add,
          expand: false,
          variant: AppActionVariant.quiet,
          onPressed: () {
            item.setTypes.add('working');
            onChanged();
          },
        ),
      ],
    ),
  );
}
