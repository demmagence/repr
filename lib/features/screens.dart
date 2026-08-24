import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/backup_service.dart';
import '../core/metrics.dart';
import '../data/database.dart';
import '../ui/greek/greek.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

void showMessage(BuildContext context, String message) {
  GreekToast.show(context, message);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) =>
      GreekEmptyState(icon: icon, title: title, body: body);
}

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
    height: 42,
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
        height: 42,
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

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? exerciseId;
  var rangeMonths = 3;
  var metric = 'e1rm';

  @override
  Widget build(BuildContext context) {
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final selectedId =
        exerciseId ?? (exercises.isEmpty ? null : exercises.first.id);
    final selected = exercises.where((e) => e.id == selectedId).firstOrNull;
    final after = rangeMonths == 0
        ? null
        : DateTime.now().subtract(Duration(days: rangeMonths * 31));
    return GreekPageShell(
      topBar: const GreekTopBar(title: 'Progres'),
      body: ListView(
        padding: pagePadding,
        children: [
          GreekSelect<String>(
            label: 'Exercise',
            value: selectedId,
            options: {
              for (final exercise in exercises) exercise.id: exercise.name,
            },
            onChanged: (value) => setState(() => exerciseId = value),
          ),
          const SizedBox(height: 12),
          GreekSegmentedControl<int>(
            segments: const [
              GreekSegment(value: 1, label: '1 bln'),
              GreekSegment(value: 3, label: '3 bln'),
              GreekSegment(value: 6, label: '6 bln'),
              GreekSegment(value: 0, label: 'Semua'),
            ],
            value: rangeMonths,
            onChanged: (value) => setState(() => rangeMonths = value),
          ),
          const SizedBox(height: 12),
          GreekSegmentedControl<String>(
            segments: const [
              GreekSegment(value: 'weight', label: 'Beban'),
              GreekSegment(value: 'e1rm', label: 'e1RM'),
              GreekSegment(value: 'volume', label: 'Volume'),
            ],
            value: metric,
            onChanged: (value) => setState(() => metric = value),
          ),
          const SizedBox(height: 20),
          if (selected == null)
            const SizedBox(
              height: 300,
              child: EmptyState(
                icon: Icons.show_chart,
                title: 'Belum ada exercise',
                body: 'Mulai workout untuk melihat progres.',
              ),
            )
          else
            FutureBuilder<List<ProgressPoint>>(
              future: ref.read(databaseProvider).progress(selected.id, after),
              builder: (context, snapshot) {
                final points = snapshot.data;
                if (points == null)
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                if (points.isEmpty)
                  return const SizedBox(
                    height: 300,
                    child: EmptyState(
                      icon: Icons.insights,
                      title: 'Belum cukup data',
                      body:
                          'Selesaikan set untuk exercise ini agar grafik terbentuk.',
                    ),
                  );
                double value(ProgressPoint p) => switch (metric) {
                  'weight' => p.maxWeight,
                  'volume' => p.volume,
                  _ => p.e1rm,
                };
                final values = points.map(value).toList();
                final maxValue = values.reduce((a, b) => a > b ? a : b);
                final bestWeight = points
                    .map((p) => p.maxWeight)
                    .reduce((a, b) => a > b ? a : b);
                final bestE1rm = points
                    .map((p) => p.e1rm)
                    .reduce((a, b) => a > b ? a : b);
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GreekStatPlaque(
                            label: 'Max weight',
                            value: '${bestWeight.toStringAsFixed(1)} kg',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GreekStatPlaque(
                            label: 'Best e1RM',
                            value: '${bestE1rm.toStringAsFixed(1)} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GreekPanel(
                      padding: const EdgeInsets.fromLTRB(10, 18, 12, 8),
                      child: SizedBox(
                        height: 280,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => const FlLine(
                                color: GreekColors.limestone,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (_) => const FlLine(
                                color: GreekColors.limestone,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: points.length > 4
                                      ? (points.length / 4).ceilToDouble()
                                      : 1,
                                  getTitlesWidget: (x, meta) {
                                    final index = x.round();
                                    if (index < 0 || index >= points.length)
                                      return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat(
                                          'd/M',
                                        ).format(points[index].date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                barWidth: 3,
                                color: GreekColors.bronze,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: GreekColors.aegean.withValues(
                                    alpha: .12,
                                  ),
                                ),
                                spots: [
                                  for (var i = 0; i < points.length; i++)
                                    FlSpot(i.toDouble(), value(points[i])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int restSeconds = 90;
  bool timerSound = true;
  bool loaded = false;

  Future<void> _load() async {
    final database = ref.read(databaseProvider);
    restSeconds = await database.getDefaultRestSeconds();
    timerSound = (await database.getSetting('timerSound')) != 'false';
    if (mounted) setState(() => loaded = true);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _ensureNoActive() async {
    final active = await ref.read(databaseProvider).getActiveWorkout();
    if (active == null) return true;
    if (mounted)
      showMessage(
        context,
        'Selesaikan atau buang workout aktif terlebih dahulu.',
      );
    return false;
  }

  Future<void> _export() async {
    if (!await _ensureNoActive()) return;
    try {
      final saved = await BackupService(
        ref.read(databaseProvider),
      ).exportBackup();
      if (mounted && saved) showMessage(context, 'Backup berhasil disimpan.');
    } catch (error) {
      if (mounted) showMessage(context, 'Ekspor gagal: $error');
    }
  }

  Future<void> _import() async {
    if (!await _ensureNoActive()) return;
    try {
      final preview = await BackupService(
        ref.read(databaseProvider),
      ).pickBackup();
      if (preview == null || !mounted) return;
      final confirmed = await showGreekDialog<bool>(
        context: context,
        builder: (context) => GreekDialog(
          title: 'Pulihkan backup?',
          actions: [
            GreekButton(
              label: 'Batal',
              expand: false,
              compact: true,
              variant: GreekActionVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            GreekButton(
              label: 'Pulihkan',
              expand: false,
              compact: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          child: Text(
            'Backup berisi ${preview.routines} routine, ${preview.workouts} workout, dan ${preview.sets} set. Semua data saat ini akan diganti.',
          ),
        ),
      );
      if (confirmed != true) return;
      await ref.read(databaseProvider).importJson(preview.source);
      if (mounted) showMessage(context, 'Backup berhasil dipulihkan.');
    } catch (error) {
      if (mounted) showMessage(context, 'Impor gagal: $error');
    }
  }

  Future<void> _createExercise() async {
    final name = TextEditingController();
    var muscle = 'Dada';
    var equipment = 'Dumbbell';
    final saved = await showGreekDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => GreekDialog(
          title: 'Exercise custom',
          actions: [
            GreekButton(
              label: 'Batal',
              expand: false,
              compact: true,
              variant: GreekActionVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            GreekButton(
              label: 'Simpan',
              expand: false,
              compact: true,
              onPressed: () =>
                  Navigator.pop(context, name.text.trim().isNotEmpty),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GreekTextField(
                controller: name,
                label: 'Nama exercise',
                hint: 'Contoh: Landmine Press',
              ),
              const SizedBox(height: 12),
              GreekSelect<String>(
                label: 'Kelompok otot',
                value: muscle,
                options: const {
                  'Dada': 'Dada',
                  'Punggung': 'Punggung',
                  'Bahu': 'Bahu',
                  'Biceps': 'Biceps',
                  'Triceps': 'Triceps',
                  'Paha depan': 'Paha depan',
                  'Hamstring': 'Hamstring',
                  'Glutes': 'Glutes',
                  'Betis': 'Betis',
                  'Core': 'Core',
                  'Seluruh tubuh': 'Seluruh tubuh',
                },
                onChanged: (value) => setState(() => muscle = value!),
              ),
              const SizedBox(height: 12),
              GreekSelect<String>(
                label: 'Peralatan',
                value: equipment,
                options: const {
                  'Barbell': 'Barbell',
                  'Dumbbell': 'Dumbbell',
                  'Machine': 'Machine',
                  'Cable': 'Cable',
                  'Bodyweight': 'Bodyweight',
                  'Lainnya': 'Lainnya',
                },
                onChanged: (value) => setState(() => equipment = value!),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(databaseProvider)
          .createExercise(
            name: name.text,
            muscle: muscle,
            equipment: equipment,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom =
        (ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[])
            .where((e) => e.isCustom)
            .toList();
    return GreekPageShell(
      topBar: const GreekTopBar(title: 'Pengaturan'),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: pagePadding,
              children: [
                Text(
                  'Workout',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GreekPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      GreekListRow(
                        title: 'Rest timer default',
                        subtitle: '$restSeconds detik',
                        trailing: const Icon(Icons.expand_more),
                        onTap: () async {
                          final value = await showGreekActionSheet<int>(
                            context: context,
                            title: 'Rest timer default',
                            actions: const [30, 60, 90, 120, 180, 300]
                                .map(
                                  (value) => GreekAction(
                                    value: value,
                                    label: '$value detik',
                                  ),
                                )
                                .toList(),
                          );
                          if (value == null) return;
                          setState(() => restSeconds = value);
                          await ref
                              .read(databaseProvider)
                              .setSetting('defaultRestSeconds', '$value');
                        },
                      ),
                      const Divider(),
                      GreekListRow(
                        title: 'Suara timer',
                        subtitle: 'Gunakan suara notifikasi Android',
                        trailing: GreekToggle(
                          value: timerSound,
                          onChanged: (value) async {
                            setState(() => timerSound = value);
                            await ref
                                .read(databaseProvider)
                                .setSetting('timerSound', '$value');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercise custom',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GreekButton(
                      onPressed: _createExercise,
                      icon: Icons.add,
                      label: 'Tambah',
                      expand: false,
                      compact: true,
                      variant: GreekActionVariant.quiet,
                    ),
                  ],
                ),
                GreekPanel(
                  padding: EdgeInsets.zero,
                  child: custom.isEmpty
                      ? const GreekListRow(
                          title: 'Belum ada exercise custom',
                          subtitle: 'Library bawaan berisi 80 exercise umum.',
                        )
                      : Column(
                          children: custom
                              .map(
                                (exercise) => GreekListRow(
                                  title: exercise.name,
                                  subtitle:
                                      '${exercise.muscle} • ${exercise.equipment}',
                                  trailing: GreekIconButton(
                                    icon: Icons.archive_outlined,
                                    semanticLabel: 'Archive ${exercise.name}',
                                    onPressed: () => ref
                                        .read(databaseProvider)
                                        .archiveExercise(exercise.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GreekPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      GreekListRow(
                        leading: const Icon(Icons.upload_file),
                        title: 'Ekspor backup',
                        subtitle: 'Simpan seluruh data sebagai JSON',
                        onTap: _export,
                      ),
                      const Divider(height: 1),
                      GreekListRow(
                        leading: const Icon(Icons.restore),
                        title: 'Impor backup',
                        subtitle: 'Ganti data dari file backup Repr',
                        onTap: _import,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GreekPanel(
                  padding: EdgeInsets.zero,
                  child: GreekListRow(
                    leading: ClipPath(
                      clipper: const GreekCutCornerClipper(cut: 5),
                      child: Image.asset(
                        'assets/icon/repr_icon.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    title: 'Repr 1.0.0',
                    subtitle: 'Gym log pribadi • Offline • Tanpa akun',
                  ),
                ),
              ],
            ),
    );
  }
}
