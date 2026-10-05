part of '../screens.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int selectedPeriod = 1; // 0: 1M, 1: 3M, 2: 6M, 3: 1Y

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider).valueOrNull ?? [];

    // Calculate total sessions in last 90 days
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final recentSessions = history
        .where((w) => w.startedAt.isAfter(ninetyDaysAgo))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 100.0),
          children: [
            // Top App Bar
            Row(
              children: [
                const Expanded(
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
                KineticIconButton(
                  size: 38,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFFD4D4D8),
                    size: 18,
                  ),
                  onPressed: () {},
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
                              children: const [
                                Text(
                                  '198.4',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'lbs',
                                  style: TextStyle(
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
                                    spots: const [
                                      FlSpot(0, 203),
                                      FlSpot(1, 201),
                                      FlSpot(2, 200.5),
                                      FlSpot(3, 199.2),
                                      FlSpot(4, 198.4),
                                    ],
                                    isCurved: true,
                                    color: Colors.white,
                                    barWidth: 2,
                                    dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, barData) =>
                                          spot.x == 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '↘ -4.2 lbs  3M Delta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
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
                              children: const [
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
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
                                const CircularProgressBadge(
                                  progress: 0.96,
                                  label: '',
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '96%',
                                  style: TextStyle(
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
                            'Optimal $recentSessions/38 Sessions',
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
                    children: const [
                      Expanded(
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
                      SizedBox(width: 8),
                      Text(
                        '↗ +14.2%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '34,200 lbs / week avg',
                      style: TextStyle(
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
                                final idx = val.toInt() + 1;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'W$idx',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: idx == 8
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: idx == 8
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
                          _buildBarGroup(0, 18000, false),
                          _buildBarGroup(1, 22000, false),
                          _buildBarGroup(2, 21000, false),
                          _buildBarGroup(3, 26000, false),
                          _buildBarGroup(4, 24000, false),
                          _buildBarGroup(5, 29000, false),
                          _buildBarGroup(6, 31000, false),
                          _buildBarGroup(7, 36000, true),
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
                      _buildBenchmarkItem('Bench Press', '225 lbs', '+10'),
                      const SizedBox(width: 10),
                      _buildBenchmarkItem('Back Squat', '315 lbs', '+15'),
                      const SizedBox(width: 10),
                      _buildBenchmarkItem('Deadlift', '405 lbs', '+20'),
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
                        children: const [
                          Expanded(
                            flex: 28,
                            child: ColoredBox(color: Colors.white),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 26,
                            child: ColoredBox(color: Color(0xFFA1A1AA)),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 24,
                            child: ColoredBox(color: Color(0xFF71717A)),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 14,
                            child: ColoredBox(color: Color(0xFF3F3F46)),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            flex: 8,
                            child: ColoredBox(color: Color(0xFF27272A)),
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
                          child: _buildDistributionLabel('Chest', '28%'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel('Back', '26%'),
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
                          child: _buildDistributionLabel('Legs', '24%'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildDistributionLabel('Arms', '14%'),
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
                          child: _buildDistributionLabel('Shoulders', '8%'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Export CSV row
            KineticCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: InkWell(
                onTap: () {
                  showMessage(
                    context,
                    'Mempersiapkan ekspor telemetri .CSV...',
                  );
                },
                child: Row(
                  children: const [
                    Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Export Biometric Telemetry (.CSV)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF71717A),
                      size: 20,
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
