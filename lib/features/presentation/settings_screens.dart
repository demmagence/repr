part of '../screens.dart';

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
                    Expanded(
                      child: Text(
                        'Exercise custom',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
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
