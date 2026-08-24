import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/backup_service.dart';
import '../core/greek_theme.dart';
import '../core/metrics.dart';
import '../data/database.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
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
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workout masih aktif'),
          content: const Text(
            'Lanjutkan workout yang sedang berjalan atau buang draftnya.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                context.push('/workout/${active.id}');
              },
              child: const Text('Lanjutkan'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang draft'),
            ),
          ],
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        title: const GreekBrandMark(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(11),
          child: GreekKeyBorder(height: 11),
        ),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          const GreekMottoBanner(),
          const SizedBox(height: 16),
          if (active != null) ...[
            Card(
              color: const Color(0xFFE7DFCA),
              child: ListTile(
                minTileHeight: 72,
                leading: const Icon(Icons.timer_outlined),
                title: Text(
                  active.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Workout sedang berjalan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workout/${active.id}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: () => _start(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Mulai latihan kosong'),
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
              TextButton.icon(
                onPressed: () => showRoutineCreator(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Buat'),
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
                            child: Card(
                              child: ListTile(
                                minTileHeight: 72,
                                leading: CircleAvatar(
                                  backgroundColor: GreekPalette.aegean,
                                  foregroundColor: GreekPalette.ivory,
                                  child: Text(
                                    routine.name.substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  routine.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: routine.notes.isEmpty
                                    ? const Text('3 set per latihan')
                                    : Text(routine.notes),
                                onTap: () =>
                                    _start(context, ref, routineId: routine.id),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'start') {
                                      await _start(
                                        context,
                                        ref,
                                        routineId: routine.id,
                                      );
                                    } else {
                                      await ref
                                          .read(databaseProvider)
                                          .deleteRoutine(routine.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'start',
                                      child: Text('Mulai'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus'),
                                    ),
                                  ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih exercise'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(9),
          child: GreekKeyBorder(height: 9),
        ),
        actions: widget.multiple
            ? [
                TextButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          widget.exercises
                              .where((e) => selected.contains(e.id))
                              .toList(),
                        ),
                  child: Text('Pilih (${selected.length})'),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama, otot, atau alat',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckboxListTile(
                  value: selected.contains(item.id),
                  secondary: CircleAvatar(
                    child: Text(item.name.substring(0, 1)),
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.muscle} • ${item.equipment}'),
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

Future<void> showRoutineCreator(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  var selected = <Exercise>[];
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Routine baru'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama routine'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showExercisePicker(
                    dialogContext,
                    ref,
                    multiple: true,
                  );
                  if (result != null) setState(() => selected = result);
                },
                icon: const Icon(Icons.add),
                label: Text(
                  selected.isEmpty
                      ? 'Pilih exercise'
                      : '${selected.length} exercise dipilih',
                ),
              ),
              if (selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    selected.map((e) => e.name).join(', '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || selected.isEmpty) return;
              await ref
                  .read(databaseProvider)
                  .createRoutine(name.text, selected.map((e) => e.id).toList());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan workout?'),
        content: Text(
          '$count set selesai akan disimpan. Set yang belum selesai akan dibuang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await database.finishWorkout(widget.id);
    await ref.read(notificationProvider).cancelRestTimer();
    if (mounted) {
      showMessage(context, 'Workout tersimpan. Mantap!');
      context.go('/riwayat');
    }
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang workout?'),
        content: const Text('Seluruh draft workout ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
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
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (item) {
        if (item == null)
          return const Scaffold(
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
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(elapsedLabel, style: const TextStyle(fontSize: 13)),
                ],
              ),
              actions: [
                TextButton(onPressed: _finish, child: const Text('Selesai')),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'discard') _discard();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'discard',
                      child: Text('Buang workout'),
                    ),
                  ],
                ),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(9),
                child: GreekKeyBorder(height: 9),
              ),
            ),
            body: Column(
              children: [
                if (rest != null && !rest.isNegative)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE7DFCA),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(databaseProvider)
                                .setRestEnd(widget.id, null);
                            await ref
                                .read(notificationProvider)
                                .cancelRestTimer();
                          },
                          child: const Text('Lewati'),
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
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Tambah exercise'),
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
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
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
              IconButton(
                onPressed: () =>
                    ref.read(databaseProvider).addSet(view.item.id),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Tambah set',
              ),
            ],
          ),
          FutureBuilder<List<WorkoutSet>>(
            future: ref
                .read(databaseProvider)
                .previousSets(view.exercise.id, workoutId),
            builder: (context, snapshot) {
              final sets = snapshot.data ?? const <WorkoutSet>[];
              if (sets.isEmpty)
                return const Text(
                  'Previous: belum ada data',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                );
              return Text(
                'Previous: ${sets.map((s) => '${formatKg(s.weightGrams)} kg × ${s.reps}').join('  •  ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              );
            },
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(
                width: 38,
                child: Text('Set', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 72,
                child: Text('kg', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 64,
                child: Text('Reps', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 66,
                child: Text('RPE', textAlign: TextAlign.center),
              ),
              Spacer(),
            ],
          ),
          ...view.sets.map(
            (set) => SetInputRow(
              set: set,
              onComplete: (value) => _complete(context, ref, set, value),
            ),
          ),
          TextButton.icon(
            onPressed: () => ref.read(databaseProvider).addSet(view.item.id),
            icon: const Icon(Icons.add),
            label: const Text('Tambah set'),
          ),
        ],
      ),
    ),
  );
}

class SetInputRow extends ConsumerWidget {
  const SetInputRow({required this.set, required this.onComplete, super.key});
  final WorkoutSet set;
  final ValueChanged<bool> onComplete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);
    InputDecoration decoration() => const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: PopupMenuButton<String>(
              tooltip: 'Jenis set',
              onSelected: (value) =>
                  database.updateWorkoutSet(id: set.id, type: value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'working', child: Text('Working')),
                PopupMenuItem(value: 'warmUp', child: Text('Warm-up')),
                PopupMenuItem(value: 'drop', child: Text('Drop')),
                PopupMenuItem(value: 'failure', child: Text('Failure')),
              ],
              child: CircleAvatar(
                radius: 15,
                backgroundColor: set.completed
                    ? GreekPalette.olive
                    : Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: set.completed ? Colors.white : null,
                child: Text(switch (set.type) {
                  'warmUp' => 'W',
                  'drop' => 'D',
                  'failure' => 'F',
                  _ => '${set.position + 1}',
                }, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: TextFormField(
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
              decoration: decoration(),
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
            width: 64,
            child: TextFormField(
              key: ValueKey('reps-${set.id}-${set.reps}'),
              initialValue: set.reps == 0 ? '' : '${set.reps}',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: decoration(),
              enabled: !set.completed,
              onChanged: (value) => database.updateWorkoutSet(
                id: set.id,
                reps: int.tryParse(value) ?? 0,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 66,
            child: DropdownButtonFormField<double?>(
              initialValue: set.rpe,
              decoration: decoration(),
              isExpanded: true,
              items: [
                const DropdownMenuItem<double?>(value: null, child: Text('—')),
                ...List.generate(19, (i) {
                  final value = 1 + i * .5;
                  return DropdownMenuItem<double?>(
                    value: value,
                    child: Text(value.toStringAsFixed(value % 1 == 0 ? 0 : 1)),
                  );
                }),
              ],
              onChanged: set.completed
                  ? null
                  : (value) =>
                        database.updateWorkoutSet(id: set.id, rpe: value ?? 0),
            ),
          ),
          const Spacer(),
          Checkbox(
            value: set.completed,
            onChanged: (value) => onComplete(value ?? false),
          ),
          IconButton(
            onPressed: set.completed ? null : () => database.removeSet(set.id),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Hapus set',
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(9),
          child: GreekKeyBorder(height: 9),
        ),
      ),
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
                  return Card(
                    child: ListTile(
                      minTileHeight: 82,
                      leading: CircleAvatar(
                        child: Text(DateFormat('dd').format(workout.startedAt)),
                      ),
                      title: Text(
                        workout.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(workout.startedAt)}${duration == null ? '' : ' • ${duration.inMinutes} menit'}',
                      ),
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
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return Scaffold(
        appBar: AppBar(
          title: Text(workout.name),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'repeat') return _repeat(context, ref, workout);
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
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus workout?'),
                      content: const Text(
                        'Riwayat dan statistik dari workout ini akan dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    await ref.read(databaseProvider).deleteWorkout(id);
                    if (context.mounted) context.go('/riwayat');
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'repeat', child: Text('Ulangi workout')),
                PopupMenuItem(value: 'date', child: Text('Ubah tanggal')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(9),
            child: GreekKeyBorder(height: 9),
          ),
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
                      child: _StatCard(
                        label: 'Durasi',
                        value: '${duration?.inMinutes ?? 0} mnt',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Set',
                        value: '${allSets.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
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
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(9),
          child: GreekKeyBorder(height: 9),
        ),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Exercise'),
            items: exercises
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                .toList(),
            onChanged: (value) => setState(() => exerciseId = value),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1 bln')),
              ButtonSegment(value: 3, label: Text('3 bln')),
              ButtonSegment(value: 6, label: Text('6 bln')),
              ButtonSegment(value: 0, label: Text('Semua')),
            ],
            selected: {rangeMonths},
            onSelectionChanged: (value) =>
                setState(() => rangeMonths = value.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'weight', label: Text('Beban')),
              ButtonSegment(value: 'e1rm', label: Text('e1RM')),
              ButtonSegment(value: 'volume', label: Text('Volume')),
            ],
            selected: {metric},
            onSelectionChanged: (value) => setState(() => metric = value.first),
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
                          child: _StatCard(
                            label: 'Max weight',
                            value: '${bestWeight.toStringAsFixed(1)} kg',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Best e1RM',
                            value: '${bestE1rm.toStringAsFixed(1)} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 280,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
                          gridData: const FlGridData(show: true),
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
                              color: Theme.of(context).colorScheme.primary,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .12),
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pulihkan backup?'),
          content: Text(
            'Backup berisi ${preview.routines} routine, ${preview.workouts} workout, dan ${preview.sets} set. Semua data saat ini akan diganti.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Pulihkan'),
            ),
          ],
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Exercise custom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama exercise'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: muscle,
                decoration: const InputDecoration(labelText: 'Kelompok otot'),
                items:
                    const [
                          'Dada',
                          'Punggung',
                          'Bahu',
                          'Biceps',
                          'Triceps',
                          'Paha depan',
                          'Hamstring',
                          'Glutes',
                          'Betis',
                          'Core',
                          'Seluruh tubuh',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => muscle = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: equipment,
                decoration: const InputDecoration(labelText: 'Peralatan'),
                items:
                    const [
                          'Barbell',
                          'Dumbbell',
                          'Machine',
                          'Cable',
                          'Bodyweight',
                          'Lainnya',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => equipment = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, name.text.trim().isNotEmpty),
              child: const Text('Simpan'),
            ),
          ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(9),
          child: GreekKeyBorder(height: 9),
        ),
      ),
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
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Rest timer default'),
                        subtitle: Text('$restSeconds detik'),
                        trailing: DropdownButton<int>(
                          value: restSeconds,
                          items: const [30, 60, 90, 120, 180, 300]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value dtk'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() => restSeconds = value);
                            await ref
                                .read(databaseProvider)
                                .setSetting('defaultRestSeconds', '$value');
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Suara timer'),
                        subtitle: const Text(
                          'Gunakan suara notifikasi Android',
                        ),
                        value: timerSound,
                        onChanged: (value) async {
                          setState(() => timerSound = value);
                          await ref
                              .read(databaseProvider)
                              .setSetting('timerSound', '$value');
                        },
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
                    TextButton.icon(
                      onPressed: _createExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                Card(
                  child: custom.isEmpty
                      ? const ListTile(
                          title: Text('Belum ada exercise custom'),
                          subtitle: Text(
                            'Library bawaan berisi 80 exercise umum.',
                          ),
                        )
                      : Column(
                          children: custom
                              .map(
                                (exercise) => ListTile(
                                  title: Text(exercise.name),
                                  subtitle: Text(
                                    '${exercise.muscle} • ${exercise.equipment}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.archive_outlined),
                                    tooltip: 'Archive',
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
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.upload_file),
                        title: const Text('Ekspor backup'),
                        subtitle: const Text(
                          'Simpan seluruh data sebagai JSON',
                        ),
                        onTap: _export,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore),
                        title: const Text('Impor backup'),
                        subtitle: const Text(
                          'Ganti data dari file backup Repr',
                        ),
                        onTap: _import,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Repr 1.0.0'),
                    subtitle: Text('Gym log pribadi • Offline • Tanpa akun'),
                  ),
                ),
              ],
            ),
    );
  }
}
