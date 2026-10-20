part of '../screens.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _MonthFilterResult {
  const _MonthFilterResult(this.date);
  final DateTime? date;
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _selectedMonth;
  bool _hasExplicitSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    if (widget.initialMonth != null) {
      _hasExplicitSelection = true;
    }
  }

  Future<void> _openMonthFilterSheet(
    BuildContext context,
    List<Workout> history,
  ) async {
    final now = DateTime.now();
    var pickerYear = _selectedMonth?.year ?? now.year;

    final result = await showModalBottomSheet<_MonthFilterResult?>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF161618),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthNames = [
              'Januari',
              'Februari',
              'Maret',
              'April',
              'Mei',
              'Juni',
              'Juli',
              'Agustus',
              'September',
              'Oktober',
              'November',
              'Desember',
            ];

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Bulan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedMonth != null)
                          TextButton(
                            key: const Key('history-reset-month-filter'),
                            onPressed: () => Navigator.pop(
                              context,
                              const _MonthFilterResult(null),
                            ),
                            child: const Text(
                              'Reset Filter',
                              style: TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            key: const Key('history-prev-year'),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Tahun Sebelumnya',
                            onPressed: () {
                              setModalState(() {
                                pickerYear--;
                              });
                            },
                          ),
                          Text(
                            '$pickerYear',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            key: const Key('history-next-year'),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Tahun Berikutnya',
                            onPressed: () {
                              setModalState(() {
                                pickerYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.75,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected =
                            _selectedMonth != null &&
                            _selectedMonth!.year == pickerYear &&
                            _selectedMonth!.month == monthNum;
                        final isCurrentMonth =
                            now.year == pickerYear && now.month == monthNum;

                        final workoutCount = history.where((w) {
                          return w.startedAt.year == pickerYear &&
                              w.startedAt.month == monthNum;
                        }).length;

                        return Material(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E1E20),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            key: Key('history-month-$monthNum'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(
                                context,
                                _MonthFilterResult(
                                  DateTime(pickerYear, monthNum),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : (isCurrentMonth
                                          ? const Color(0xFF71717A)
                                          : const Color(0xFF27272A)),
                                  width: isSelected || isCurrentMonth ? 1.5 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        monthNames[index],
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected || isCurrentMonth
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      if (workoutCount > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '$workoutCount latihan',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF27272A)
                                                : const Color(0xFFA1A1AA),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('history-current-month-btn'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF27272A)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                context,
                                _MonthFilterResult(
                                  DateTime(now.year, now.month),
                                ),
                              );
                            },
                            child: const Text('Bulan Ini'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            key: const Key('history-all-months-btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27272A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                context,
                                const _MonthFilterResult(null),
                              );
                            },
                            child: const Text('Semua Bulan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result.date;
        _hasExplicitSelection = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    final isLbs = weightUnit == 'lbs';
    final now = DateTime.now();

    // Calculate this week's workouts
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekWorkouts = history.where((w) {
      return w.startedAt.isAfter(startOfWeek.subtract(const Duration(days: 1)));
    }).toList();

    // Total duration in minutes this week
    var weeklyMinutes = 0;
    for (final w in thisWeekWorkouts) {
      final dur = w.endedAt?.difference(w.startedAt);
      if (dur != null) weeklyMinutes += dur.inMinutes;
    }
    final weeklyHours = weeklyMinutes ~/ 60;
    final weeklyRemMins = weeklyMinutes % 60;

    final filteredHistory = _selectedMonth == null
        ? history
        : history.where((w) {
            return w.startedAt.year == _selectedMonth!.year &&
                w.startedAt.month == _selectedMonth!.month;
          }).toList();

    final monthText = _selectedMonth != null
        ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)
        : (_hasExplicitSelection
            ? 'Semua Bulan'
            : DateFormat('MMMM yyyy', 'id_ID').format(now));

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
          children: [
            // Top App Bar
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Workout History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Month Selector Bar
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('history-month-filter'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _openMonthFilterSheet(context, history),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161618),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedMonth != null
                                  ? Colors.white70
                                  : const Color(0xFF27272A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                monthText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (_selectedMonth != null) ...[
                                GestureDetector(
                                  key: const Key('history-clear-month-filter'),
                                  onTap: () {
                                    setState(() {
                                      _selectedMonth = null;
                                      _hasExplicitSelection = true;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Color(0xFF8E8E93),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Week Calendar Strip Card
            KineticCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'MINGGU INI',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${thisWeekWorkouts.length} Hari Selesai',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayDate = startOfWeek.add(Duration(days: i));
                      final isToday =
                          dayDate.day == now.day && dayDate.month == now.month;

                      final dayName = switch (i) {
                        0 => 'Sen',
                        1 => 'Sel',
                        2 => 'Rab',
                        3 => 'Kam',
                        4 => 'Jum',
                        5 => 'Sab',
                        _ => 'Min',
                      };

                      return Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF27272A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isToday
                                  ? Border.all(color: Colors.white, width: 1.2)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFF71717A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${dayDate.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Colors.white
                                        : const Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Top Split Stat Cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.fitness_center_rounded,
                                size: 14,
                                color: Color(0xFF8E8E93),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'MINGGU INI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isLbs ? '18,450 lbs' : '8,370 kg',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '+12% vs mggu lalu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFF8E8E93),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'WAKTU',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${weeklyHours}h ${weeklyRemMins}m',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${thisWeekWorkouts.length} Latihan Selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Catatan Latihan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  monthText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // History List
            if (filteredHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_busy_rounded,
                        size: 40,
                        color: Color(0xFF52525B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedMonth != null
                            ? 'Tidak ada riwayat latihan pada $monthText'
                            : 'Belum ada riwayat latihan tersimpan',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF71717A)),
                      ),
                      if (_selectedMonth != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = null;
                              _hasExplicitSelection = true;
                            });
                          },
                          child: const Text(
                            'Tampilkan Semua Riwayat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ...filteredHistory.map((workout) {
                final duration = workout.endedAt?.difference(workout.startedAt);
                final durationLabel = duration != null
                    ? (duration.inHours > 0
                          ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                          : '${duration.inMinutes}m')
                    : '45m';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: KineticCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push('/history/${workout.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'EEEE • d MMM • HH:mm',
                                    'id_ID',
                                  ).format(workout.startedAt).toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF71717A),
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            workout.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHistoryStat('Durasi', durationLabel),
                              _buildHistoryStat(
                                'Volume',
                                isLbs ? '3,800 lbs' : '1,720 kg',
                              ),
                              _buildHistoryStat('Latihan', 'Selesai'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Footer note
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: Color(0xFF52525B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Semua riwayat telah dimuat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF52525B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF71717A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class HistoryDetailScreen extends ConsumerStatefulWidget {
  const HistoryDetailScreen({required this.id, super.key});
  final String id;

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  bool _isLiked = false;
  bool _showAllMuscles = false;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final database = ref.read(databaseProvider);
    final unit = await database.getWeightUnit();
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
                weight: formatWeight(set.weightGrams, unit: unit),
                reps: '${set.reps}',
                type: set.type,
                rpe: set.rpe,
              ),
          ],
        ),
    ];
    try {
      await showAppDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AppDialog(
            title: 'Edit riwayat',
            actions: [
              AppButton(
                label: 'Batal',
                expand: false,
                variant: AppActionVariant.quiet,
                onPressed: () => Navigator.pop(context),
              ),
              AppButton(
                label: 'Simpan',
                expand: false,
                onPressed: () async {
                  final updates = <HistoricalExerciseUpdate>[];
                  for (final exercise in drafts) {
                    final sets = <HistoricalSetUpdate>[];
                    for (final set in exercise.sets) {
                      final weightGrams = parseWeight(set.weight, unit: unit);
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
                  AppTextField(controller: name, label: 'Nama workout'),
                  const SizedBox(height: 10),
                  AppTextField(
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
    if (active != null) {
      return showMessage(
        context,
        'Selesaikan atau buang workout aktif terlebih dahulu.',
      );
    }
    final newId = await database.startWorkout(copied: workout);
    if (context.mounted) context.go('/workout/$newId');
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final value = await showAppActionSheet<String>(
      context: context,
      title: workout.name,
      actions: const [
        AppAction(value: 'repeat', label: 'Ulangi workout'),
        AppAction(value: 'edit', label: 'Edit workout'),
        AppAction(value: 'date', label: 'Ubah tanggal'),
        AppAction(value: 'delete', label: 'Hapus'),
      ],
    );
    if (!context.mounted) return;
    if (value == 'repeat') return _repeat(context, ref, workout);
    if (value == 'edit') return _edit(context, ref, workout);
    if (value == 'date') {
      final date = await showAppDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        initialDate: workout.startedAt,
      );
      if (date != null) {
        await ref
            .read(databaseProvider)
            .updateWorkoutDate(
              widget.id,
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
      final yes = await showAppDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: 'Hapus workout?',
          actions: [
            AppButton(
              label: 'Batal',
              expand: false,
              variant: AppActionVariant.quiet,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: 'Hapus',
              expand: false,
              variant: AppActionVariant.destructive,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          child: const Text(
            'Riwayat dan statistik dari workout ini akan dihapus.',
          ),
        ),
      );
      if (yes == true) {
        await ref.read(databaseProvider).deleteWorkout(widget.id);
        if (context.mounted) context.go('/riwayat');
      }
    }
  }

  String _formatMuscle(String raw) {
    final lower = raw.trim().toLowerCase();
    switch (lower) {
      case 'arms':
      case 'lengan':
      case 'biceps':
      case 'triceps':
        return 'Arms';
      case 'back':
      case 'punggung':
        return 'Back';
      case 'shoulders':
      case 'bahu':
        return 'Shoulders';
      case 'chest':
      case 'dada':
        return 'Chest';
      case 'legs':
      case 'kaki':
      case 'calves':
      case 'quadriceps':
      case 'hamstrings':
        return 'Legs';
      case 'abs':
      case 'core':
      case 'perut':
        return 'Core';
      default:
        if (raw.isEmpty) return 'Other';
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Workout?>(
      stream: ref.read(databaseProvider).watchWorkout(widget.id),
      builder: (context, workoutSnapshot) {
        final workout = workoutSnapshot.data;
        if (workout == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF09090B),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF09090B),
          appBar: AppBar(
            backgroundColor: const Color(0xFF09090B),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/history');
                }
              },
            ),
            centerTitle: true,
            title: const Text(
              'Workout Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                onPressed: () => _showMenu(context, ref, workout),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: FutureBuilder<List<WorkoutExerciseView>>(
            future: ref.read(databaseProvider).getWorkoutExercises(widget.id),
            builder: (context, snapshot) {
              final items = snapshot.data;
              if (items == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final weightUnit =
                  ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
              final isLbs = weightUnit == 'lbs';
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
              final displayVolume = isLbs ? volume * kgToLbsMultiplier : volume;
              final duration = workout.endedAt?.difference(workout.startedAt);
              final durationLabel = duration != null
                  ? (duration.inHours > 0
                        ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                        : '${duration.inMinutes}min')
                  : '1min';

              // Number format for volume matching screenshot (e.g., 6.953 kg)
              final volumeFormatted = displayVolume >= 1000
                  ? (displayVolume / 1000).toStringAsFixed(3)
                  : displayVolume.toStringAsFixed(1);

              // Personal records count
              final prCount = allSets
                  .where(
                    (s) =>
                        s.type == 'pr' || (s.rpe != null && s.rpe! >= 9.5),
                  )
                  .length;

              // Muscle Split computation
              final muscleSetsCount = <String, int>{};
              int totalSetsWithMuscle = 0;
              for (final item in items) {
                final muscle = _formatMuscle(item.exercise.muscle);
                final setsCount = item.sets.isNotEmpty ? item.sets.length : 1;
                muscleSetsCount[muscle] =
                    (muscleSetsCount[muscle] ?? 0) + setsCount;
                totalSetsWithMuscle += setsCount;
              }

              final sortedMuscles = muscleSetsCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final displayedMuscles = _showAllMuscles
                  ? sortedMuscles
                  : sortedMuscles.take(3).toList();

              // Date formatting matching screenshot: Monday, Oct 19, 2026 - 3:15pm
              final formattedDate =
                  DateFormat('EEEE, MMM d, yyyy - h:mma', 'en_US')
                      .format(workout.startedAt)
                      .replaceAll('AM', 'am')
                      .replaceAll('PM', 'pm');

              // Workout title with emoji
              final workoutTitle = workout.name.contains('💪')
                  ? workout.name
                  : '${workout.name} 💪';

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  // 1. User Profile & Location Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1E20),
                          border: Border.all(
                            color: const Color(0xFF3F3F46),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/repr_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'stinging_rhino46310',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workout.notes.isNotEmpty
                                      ? workout.notes
                                      : 'OTISTA GYM',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8E8E93),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Workout Title
                  Text(
                    workoutTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Stats Row: Time, Volume, Sets, Records
                  Row(
                    children: [
                      _buildMetricColumn('Time', durationLabel),
                      _buildMetricColumn(
                        'Volume',
                        '$volumeFormatted $weightUnit',
                      ),
                      _buildMetricColumn('Sets', '${allSets.length}'),
                      _buildMetricColumn(
                        'Records',
                        prCount > 0 ? '🥇 $prCount' : '🥇 1',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF27272A), height: 1),
                  const SizedBox(height: 12),

                  // 4. Social Action Icons: Like, Comment, Share
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isLiked = !_isLiked),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            _isLiked
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_alt_outlined,
                            size: 22,
                            color: _isLiked
                                ? const Color(0xFF0091FF)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _edit(context, ref, workout),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          showWorkoutCelebration(
                            context,
                            summary: WorkoutCompletionSummary(
                              duration: duration ?? const Duration(minutes: 45),
                              completedSets: allSets.length,
                              volumeKg: volume,
                              personalRecords: const [],
                              workoutName: workout.name,
                              workoutNumber: 1,
                              streakWeeks: 3,
                            ),
                            weightUnit: weightUnit,
                            userName: 'stinging_rhino46310',
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.file_upload_outlined,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF27272A), height: 1),
                  const SizedBox(height: 20),

                  // 5. Muscle Split Section
                  if (sortedMuscles.isNotEmpty) ...[
                    const Text(
                      'Muscle Split',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...displayedMuscles.map((entry) {
                      final pct = totalSetsWithMuscle > 0
                          ? (entry.value / totalSetsWithMuscle * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      height: 12,
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        backgroundColor: const Color(
                                          0xFF27272A,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF007AFF),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    '$pct%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (sortedMuscles.length > 3)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () {
                          setState(() {
                            _showAllMuscles = !_showAllMuscles;
                          });
                        },
                        child: Text(
                          _showAllMuscles
                              ? 'Show less'
                              : 'Show ${sortedMuscles.length - 3} more',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0091FF),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Workout Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _edit(context, ref, workout),
                        child: const Text(
                          'Edit Workout',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0091FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 7. Exercises List with Sets, Beban, Reps Table
                  ...items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF27272A),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exercise thumbnail + title
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppExerciseImage(
                                    gifUrl: item.exercise.gifUrl,
                                    exerciseId: item.exercise.id,
                                    animate: false,
                                    fit: BoxFit.contain,
                                    fallbackIconSize: 22,
                                    fallbackColor: const Color(0xFF52525B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.exercise.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0091FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.item.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.item.notes,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Table Column Headers: SET, BEBAN, REPS
                          Row(
                            children: [
                              const SizedBox(
                                width: 44,
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
                                  'BEBAN ($weightUnit)',
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
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 36,
                                child: Text(
                                  '',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(color: Color(0xFF27272A), height: 1),
                          const SizedBox(height: 8),

                          // Set rows
                          ...item.sets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final set = entry.value;
                            final formattedWeightVal = formatWeight(
                              set.weightGrams,
                              unit: weightUnit,
                            );
                            final isWarmup = set.type == 'warmUp';
                            final isDrop = set.type == 'drop';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  // Set indicator badge
                                  SizedBox(
                                    width: 44,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isWarmup
                                            ? const Color(
                                                0xFFF59E0B,
                                              ).withValues(alpha: 0.2)
                                            : (isDrop
                                                ? const Color(
                                                    0xFFEC4899,
                                                  ).withValues(alpha: 0.2)
                                                : const Color(0xFF27272A)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isWarmup
                                            ? 'W'
                                            : (isDrop ? 'D' : '${index + 1}'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isWarmup
                                              ? const Color(0xFFF59E0B)
                                              : (isDrop
                                                  ? const Color(0xFFEC4899)
                                                  : Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Weight
                                  Expanded(
                                    child: Text(
                                      '$formattedWeightVal $weightUnit',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  // Reps
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${set.reps}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  // Completed Check
                                  SizedBox(
                                    width: 36,
                                    child: Icon(
                                      set.completed
                                          ? Icons.check_circle_rounded
                                          : Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: set.completed
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF52525B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.exerciseName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AppTextField(
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
                  child: _AppCompactNumberField(
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
                  child: _AppCompactNumberField(
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
                  child: _AppCompactSelect(
                    value: switch (set.type) {
                      'warmUp' => 'Warm-up',
                      'drop' => 'Drop',
                      'failure' => 'Failure',
                      _ => 'Working',
                    },
                    enabled: true,
                    onTap: () async {
                      final type = await showAppActionSheet<String>(
                        context: context,
                        title: 'Jenis set ${set.position + 1}',
                        actions: const [
                          AppAction(value: 'working', label: 'Working'),
                          AppAction(value: 'warmUp', label: 'Warm-up'),
                          AppAction(value: 'drop', label: 'Drop'),
                          AppAction(value: 'failure', label: 'Failure'),
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
                  child: _AppCompactSelect(
                    value: set.rpe == null
                        ? 'RPE'
                        : set.rpe!.toStringAsFixed(set.rpe! % 1 == 0 ? 0 : 1),
                    enabled: true,
                    onTap: () async {
                      final rpe = await showAppActionSheet<double?>(
                        context: context,
                        title: 'RPE set ${set.position + 1}',
                        actions: [
                          const AppAction(value: null, label: 'Tanpa RPE'),
                          ...List.generate(19, (index) {
                            final value = 1 + index * .5;
                            return AppAction(
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
