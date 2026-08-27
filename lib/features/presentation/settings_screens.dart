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
      final confirmed = await showAppDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: 'Pulihkan backup?',
          actions: [
            AppButton(
              label: 'Batal',
              expand: false,
              variant: AppActionVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: 'Pulihkan',
              expand: false,
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
    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: 'Exercise custom',
          actions: [
            AppButton(
              label: 'Batal',
              expand: false,
              variant: AppActionVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: 'Simpan',
              expand: false,
              onPressed: () =>
                  Navigator.pop(context, name.text.trim().isNotEmpty),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: name,
                label: 'Nama exercise',
                hint: 'Contoh: Landmine Press',
              ),
              const SizedBox(height: 12),
              AppSelect<String>(
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
              AppSelect<String>(
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
    final metadata = ref.watch(appMetadataProvider).currentMetadata;
    final custom =
        (ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[])
            .where((e) => e.isCustom)
            .toList();
    final activeWorkout = ref.watch(activeWorkoutProvider).valueOrNull;
    final hasActiveWorkout = activeWorkout != null;
    return AppPageShell(
      topBar: const AppTopBar(title: 'Pengaturan'),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: pagePadding,
              children: [
                Text('Workout', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AppListRow(
                        title: 'Rest timer default',
                        subtitle: '$restSeconds detik',
                        trailing: const Icon(Icons.expand_more),
                        onTap: () async {
                          final value = await showAppActionSheet<int>(
                            context: context,
                            title: 'Rest timer default',
                            actions: const [30, 60, 90, 120, 180, 300]
                                .map(
                                  (value) => AppAction(
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
                      AppListRow(
                        title: 'Suara timer',
                        subtitle: 'Gunakan suara notifikasi Android',
                        trailing: AppToggle(
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      onPressed: _createExercise,
                      icon: Icons.add,
                      label: 'Tambah',
                      expand: false,
                      variant: AppActionVariant.quiet,
                    ),
                  ],
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: custom.isEmpty
                      ? const AppListRow(
                          title: 'Belum ada exercise custom',
                          subtitle: 'Library bawaan berisi 80 exercise umum.',
                        )
                      : Column(
                          children: custom
                              .map(
                                (exercise) => AppListRow(
                                  title: exercise.name,
                                  subtitle:
                                      '${exercise.muscle} • ${exercise.equipment}',
                                  trailing: AppIconButton(
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
                Text('Data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AppListRow(
                        leading: const Icon(Icons.upload_file),
                        title: 'Ekspor backup',
                        subtitle: hasActiveWorkout
                            ? 'Selesaikan atau buang workout aktif terlebih dahulu'
                            : 'Simpan seluruh data sebagai JSON',
                        onTap: hasActiveWorkout ? null : _export,
                      ),
                      const Divider(height: 1),
                      AppListRow(
                        leading: const Icon(Icons.restore),
                        title: 'Impor backup',
                        subtitle: hasActiveWorkout
                            ? 'Selesaikan atau buang workout aktif terlebih dahulu'
                            : 'Ganti data dari file backup Repr',
                        onTap: hasActiveWorkout ? null : _import,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AppListRow(
                    leading: Image.asset(
                      'assets/icon/repr_icon.png',
                      width: 48,
                      height: 48,
                    ),
                    title: 'Repr ${metadata.displayVersion}',
                    subtitle: 'Gym log pribadi • Offline • Tanpa akun',
                  ),
                ),
              ],
            ),
    );
  }
}
