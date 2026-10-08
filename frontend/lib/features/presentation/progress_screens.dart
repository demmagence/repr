part of '../screens.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int selectedPeriod = 1; // 0: 1M, 1: 3M, 2: 6M, 3: 1Y

  static const List<_PeriodAnalytics> _periods = [
    _PeriodAnalytics(
      label: '1M',
      duration: Duration(days: 30),
      targetSessions: 13,
      deltaLabel: '1M Delta',
      weightDeltaLbs: '-1.4',
      weightDeltaKg: '-0.6',
      weightSpots: [200.0, 199.5, 198.9, 198.4],
      freqDaysPerWeek: '4.6',
      freqPercent: '92%',
      freqProgress: 0.92,
      volumeAvgLbs: '36,400 lbs / week avg',
      volumeAvgKg: '16,500 kg / week avg',
      volumeGrowth: '↗ +8.5%',
      barLabels: ['W1', 'W2', 'W3', 'W4'],
      barLoads: [31000, 33000, 34500, 36400],
      benchDeltaLbs: '+5',
      benchDeltaKg: '+2.5',
      squatDeltaLbs: '+5',
      squatDeltaKg: '+2.5',
      deadliftDeltaLbs: '+10',
      deadliftDeltaKg: '+5',
      distribution: {'Chest': 30, 'Back': 28, 'Legs': 22, 'Arms': 12, 'Shoulders': 8},
    ),
    _PeriodAnalytics(
      label: '3M',
      duration: Duration(days: 90),
      targetSessions: 38,
      deltaLabel: '3M Delta',
      weightDeltaLbs: '-4.2',
      weightDeltaKg: '-1.9',
      weightSpots: [203.0, 201.0, 200.5, 199.2, 198.4],
      freqDaysPerWeek: '4.8',
      freqPercent: '96%',
      freqProgress: 0.96,
      volumeAvgLbs: '34,200 lbs / week avg',
      volumeAvgKg: '15,500 kg / week avg',
      volumeGrowth: '↗ +14.2%',
      barLabels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'],
      barLoads: [18000, 22000, 21000, 26000, 24000, 29000, 31000, 36000],
      benchDeltaLbs: '+10',
      benchDeltaKg: '+4.5',
      squatDeltaLbs: '+15',
      squatDeltaKg: '+7',
      deadliftDeltaLbs: '+20',
      deadliftDeltaKg: '+9',
      distribution: {'Chest': 28, 'Back': 26, 'Legs': 24, 'Arms': 14, 'Shoulders': 8},
    ),
    _PeriodAnalytics(
      label: '6M',
      duration: Duration(days: 180),
      targetSessions: 76,
      deltaLabel: '6M Delta',
      weightDeltaLbs: '-7.5',
      weightDeltaKg: '-3.4',
      weightSpots: [206.0, 204.0, 202.5, 201.0, 199.5, 198.4],
      freqDaysPerWeek: '4.5',
      freqPercent: '90%',
      freqProgress: 0.90,
      volumeAvgLbs: '32,800 lbs / week avg',
      volumeAvgKg: '14,900 kg / week avg',
      volumeGrowth: '↗ +18.7%',
      barLabels: ['M1', 'M2', 'M3', 'M4', 'M5', 'M6'],
      barLoads: [22000, 25000, 27000, 30000, 33000, 36000],
      benchDeltaLbs: '+15',
      benchDeltaKg: '+7',
      squatDeltaLbs: '+25',
      squatDeltaKg: '+11.5',
      deadliftDeltaLbs: '+35',
      deadliftDeltaKg: '+16',
      distribution: {'Chest': 26, 'Back': 26, 'Legs': 26, 'Arms': 14, 'Shoulders': 8},
    ),
    _PeriodAnalytics(
      label: '1Y',
      duration: Duration(days: 365),
      targetSessions: 156,
      deltaLabel: '1Y Delta',
      weightDeltaLbs: '-12.8',
      weightDeltaKg: '-5.8',
      weightSpots: [212.0, 208.5, 205.0, 202.5, 200.0, 198.4],
      freqDaysPerWeek: '4.3',
      freqPercent: '86%',
      freqProgress: 0.86,
      volumeAvgLbs: '30,500 lbs / week avg',
      volumeAvgKg: '13,800 kg / week avg',
      volumeGrowth: '↗ +22.4%',
      barLabels: ['Q1', 'Q2', 'Q3', 'Q4'],
      barLoads: [24000, 28000, 32000, 36000],
      benchDeltaLbs: '+25',
      benchDeltaKg: '+11.5',
      squatDeltaLbs: '+40',
      squatDeltaKg: '+18',
      deadliftDeltaLbs: '+55',
      deadliftDeltaKg: '+25',
      distribution: {'Chest': 25, 'Back': 25, 'Legs': 26, 'Arms': 15, 'Shoulders': 9},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final weightUnit = ref.watch(weightUnitProvider).valueOrNull ?? 'kg';
    final isLbs = weightUnit == 'lbs';

    final now = DateTime.now();
    final period = _periods[selectedPeriod.clamp(0, _periods.length - 1)];
    final periodStart = now.subtract(period.duration);
    final recentSessions = history
        .where((w) => w.startedAt.isAfter(periodStart))
        .length;

    final freqDaysPerWeek = history.isNotEmpty
        ? (recentSessions / (period.duration.inDays / 7.0))
            .clamp(0.0, 7.0)
            .toStringAsFixed(1)
        : period.freqDaysPerWeek;
    final freqPercent = history.isNotEmpty
        ? '${((recentSessions / period.targetSessions) * 100).clamp(0, 100).round()}%'
        : period.freqPercent;
    final freqProgress = history.isNotEmpty
        ? (recentSessions / period.targetSessions).clamp(0.0, 1.0)
        : period.freqProgress;

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
                    'Analytics',
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

            // Segmented Period Pills (1M, 3M, 6M, 1Y)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                children: [
                  _buildPeriodPill(0, '1M'),
                  _buildPeriodPill(1, '3M'),
                  _buildPeriodPill(2, '6M'),
                  _buildPeriodPill(3, '1Y'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Split Grid (Weight & Frequency)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Weight Card
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(
                                child: Text(
                                  'WEIGHT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF52525B),
                                size: 15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  isLbs ? '198.4' : '90.0',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  weightUnit,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mini Sparkline Graph
                          SizedBox(
                            height: 32,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (int i = 0;
                                          i < period.weightSpots.length;
                                          i++)
                                        FlSpot(
                                          i.toDouble(),
                                          period.weightSpots[i],
                                        ),
                                    ],
                                    isCurved: true,
                                    color: Colors.white,
                                    barWidth: 2,
                                    dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, barData) =>
                                          spot.x ==
                                          period.weightSpots.length - 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isLbs
                                ? '↘ ${period.weightDeltaLbs} lbs  ${period.deltaLabel}'
                                : '↘ ${period.weightDeltaKg} kg  ${period.deltaLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Frequency Card
                  Expanded(
                    child: KineticCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(
                                child: Text(
                                  'FREQUENCY',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF52525B),
                                size: 15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  freqDaysPerWeek,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'd/wk',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                CircularProgressBadge(
                                  progress: freqProgress,
                                  label: '',
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  freqPercent,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Optimal $recentSessions/${period.targetSessions} Sessions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Gross Mechanical Load (Bar Chart Card)
            KineticCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'GROSS MECHANICAL LOAD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period.volumeGrowth,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isLbs ? period.volumeAvgLbs : period.volumeAvgKg,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 140,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 40000,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= period.barLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                final isLast =
                                    idx == period.barLabels.length - 1;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    period.barLabels[idx],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isLast
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isLast
                                          ? Colors.white
                                          : const Color(0xFF71717A),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < period.barLoads.length; i++)
                            _buildBarGroup(
                              i,
                              period.barLoads[i],
                              i == period.barLoads.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Benchmark Records (1-Rep Max Telemetry)
            KineticCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'BENCHMARK RECORDS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '1-Rep Max Telemetry',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildBenchmarkItem(
                        'Bench Press',
                        isLbs ? '225 lbs' : '102.5 kg',
                        isLbs ? period.benchDeltaLbs : period.benchDeltaKg,
                      ),
                      const SizedBox(width: 10),
                      _buildBenchmarkItem(
                        'Back Squat',
                        isLbs ? '315 lbs' : '142.5 kg',
                        isLbs ? period.squatDeltaLbs : period.squatDeltaKg,
                      ),
                      const SizedBox(width: 10),
                      _buildBenchmarkItem(
                        'Deadlift',
                        isLbs ? '405 lbs' : '185 kg',
                        isLbs ? period.deadliftDeltaLbs : period.deadliftDeltaKg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Volume Distribution Card
            KineticCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'VOLUME DISTRIBUTION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hypertrophy Split',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Multi-segment progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: period.distribution['Chest'] ?? 28,
                            child: const ColoredBox(color: Colors.white),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: period.distribution['Back'] ?? 26,
                            child: const ColoredBox(color: Color(0xFFA1A1AA)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: period.distribution['Legs'] ?? 24,
                            child: const ColoredBox(color: Color(0xFF71717A)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: period.distribution['Arms'] ?? 14,
                            child: const ColoredBox(color: Color(0xFF3F3F46)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: period.distribution['Shoulders'] ?? 8,
                            child: const ColoredBox(color: Color(0xFF27272A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel(
                            'Chest',
                            '${period.distribution['Chest']}%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel(
                            'Back',
                            '${period.distribution['Back']}%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel(
                            'Legs',
                            '${period.distribution['Legs']}%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel(
                            'Arms',
                            '${period.distribution['Arms']}%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel(
                            'Shoulders',
                            '${period.distribution['Shoulders']}%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodPill(int index, String label) {
    final isSelected = selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, bool isHighlight) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHighlight ? Colors.white : const Color(0xFF27272A),
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBenchmarkItem(String exercise, String weight, String delta) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF101012),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                weight,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '↑ $delta',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionLabel(String muscle, String percent) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF8E8E93),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          muscle,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(width: 14),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PeriodAnalytics {
  final String label;
  final Duration duration;
  final int targetSessions;
  final String deltaLabel;
  final String weightDeltaLbs;
  final String weightDeltaKg;
  final List<double> weightSpots;
  final String freqDaysPerWeek;
  final String freqPercent;
  final double freqProgress;
  final String volumeAvgLbs;
  final String volumeAvgKg;
  final String volumeGrowth;
  final List<String> barLabels;
  final List<double> barLoads;
  final String benchDeltaLbs;
  final String benchDeltaKg;
  final String squatDeltaLbs;
  final String squatDeltaKg;
  final String deadliftDeltaLbs;
  final String deadliftDeltaKg;
  final Map<String, int> distribution;

  const _PeriodAnalytics({
    required this.label,
    required this.duration,
    required this.targetSessions,
    required this.deltaLabel,
    required this.weightDeltaLbs,
    required this.weightDeltaKg,
    required this.weightSpots,
    required this.freqDaysPerWeek,
    required this.freqPercent,
    required this.freqProgress,
    required this.volumeAvgLbs,
    required this.volumeAvgKg,
    required this.volumeGrowth,
    required this.barLabels,
    required this.barLoads,
    required this.benchDeltaLbs,
    required this.benchDeltaKg,
    required this.squatDeltaLbs,
    required this.squatDeltaKg,
    required this.deadliftDeltaLbs,
    required this.deadliftDeltaKg,
    required this.distribution,
  });
}
