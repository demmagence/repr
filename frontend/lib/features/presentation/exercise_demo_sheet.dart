import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/exercise_api_client.dart';
import '../../ui/widgets/kinetic_components.dart';

Future<void> showExerciseDemoSheet(
  BuildContext context, {
  required ExerciseApiModel exercise,
  VoidCallback? onSelect,
  int initialTab = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF09090B),
    builder: (context) => _ExerciseDemoView(
      exercise: exercise,
      onSelect: onSelect,
      initialTab: initialTab,
    ),
  );
}

class _ExerciseDemoView extends StatefulWidget {
  const _ExerciseDemoView({
    required this.exercise,
    this.onSelect,
    this.initialTab = 0,
  });

  final ExerciseApiModel exercise;
  final VoidCallback? onSelect;
  final int initialTab;

  @override
  State<_ExerciseDemoView> createState() => _ExerciseDemoViewState();
}

class _ExerciseDemoViewState extends State<_ExerciseDemoView> {
  late int _selectedTab;
  int _selectedMetric = 0; // 0: Heaviest Weight, 1: One Rep Max, 2: Best Set / Vol
  final String _selectedPeriod = 'Last 3 months';

  late Future<List<ExerciseHistorySession>> _historyFuture;
  late Future<List<ProgressPoint>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _historyFuture = Future.value(const []);
    _progressFuture = Future.value(const []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final db = container.read(databaseProvider);
      _historyFuture = db.getExerciseHistory(widget.exercise.id);
      _progressFuture = db.progress(widget.exercise.id, null);
    } catch (_) {
      _historyFuture = Future.value(const []);
      _progressFuture = Future.value(const []);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_selectedTab) {
      1 => 'Exercise History',
      2 => 'Exercise How To',
      _ => 'Exercise Summary',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tabs Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Summary'),
                  _buildTabButton(1, 'History'),
                  _buildTabButton(2, 'How to'),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildSummaryTab(),
                _buildHistoryTab(),
                _buildHowToTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF27272A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: SUMMARY
  // ==========================================
  Widget _buildSummaryTab() {
    return FutureBuilder<List<Object>>(
      future: Future.wait([_historyFuture, _progressFuture]),
      builder: (context, snapshot) {
        final sessions = (snapshot.data?[0] as List<ExerciseHistorySession>?) ?? [];
        final points = (snapshot.data?[1] as List<ProgressPoint>?) ?? [];

        // Compute metrics
        double maxWeightKg = 0;
        int maxWeightReps = 0;
        double maxE1rmKg = 0;
        double latestSessionVolKg = 0;
        int totalSetsInLatest = 0;

        for (final session in sessions) {
          for (final set in session.sets.where((s) => s.completed)) {
            final w = set.weightGrams / 1000.0;
            if (w > maxWeightKg) {
              maxWeightKg = w;
              maxWeightReps = set.reps;
            }
            if (w > 0 && set.reps <= 12) {
              final e1rm = w * (1 + set.reps / 30.0);
              if (e1rm > maxE1rmKg) maxE1rmKg = e1rm;
            }
          }
        }

        if (sessions.isNotEmpty) {
          final latest = sessions.first;
          totalSetsInLatest = latest.sets.where((s) => s.completed).length;
          latestSessionVolKg = latest.sets
              .where((s) => s.completed)
              .fold<double>(0, (sum, s) => sum + (s.weightGrams / 1000.0 * s.reps));
        }

        // Fallbacks for display
        final displayMaxWeight = maxWeightKg > 0 ? maxWeightKg : 7.5;
        final displayMaxReps = maxWeightReps > 0 ? maxWeightReps : 12;
        final displayE1rm = maxE1rmKg > 0 ? maxE1rmKg : 10.5;
        final displayVol = latestSessionVolKg > 0 ? latestSessionVolKg : 270.0;
        final displayTotalSets = totalSetsInLatest > 0 ? totalSetsInLatest : 3;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // Add to Workout CTA Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.black, size: 20),
                label: const Text(
                  'Add to Workout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  if (widget.onSelect != null) {
                    Navigator.pop(context);
                    widget.onSelect!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Hero Image Card
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: widget.exercise.gifUrl != null &&
                            widget.exercise.gifUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.exercise.gifUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                size: 80,
                                color: Color(0xFF52525B),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fitness_center_rounded,
                            size: 80,
                            color: Color(0xFF52525B),
                          ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE ${_capitalize(widget.exercise.target).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exercise Title & Muscle Category
            Text(
              _capitalize(widget.exercise.name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Primary: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalize(widget.exercise.target),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: Color(0xFF52525B))),
                const SizedBox(width: 6),
                Text(
                  _capitalize(widget.exercise.bodyPart),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pro Tip Card
            KineticCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'How to log ${_capitalize(widget.exercise.equipment)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Pro Tip',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA1A1AA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Catat beban per tangan (single dumbbell weight) untuk akurasi pelacakan volume.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Line Chart Card
            KineticCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${displayMaxWeight.toStringAsFixed(displayMaxWeight.truncateToDouble() == displayMaxWeight ? 1 : 2)} kg',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Oct 3',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'MAX LOAD RECORDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF71717A),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPeriod,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Line Chart
                  SizedBox(
                    height: 140,
                    child: _buildProgressChart(points, displayMaxWeight),
                  ),
                  const SizedBox(height: 16),

                  // Metric Selector Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMetricPill(0, 'Heaviest Weight'),
                        const SizedBox(width: 8),
                        _buildMetricPill(1, 'One Rep Max'),
                        const SizedBox(width: 8),
                        _buildMetricPill(2, 'Best Set / Vol'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3 Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'RECORD',
                    value: '${displayMaxWeight.toStringAsFixed(1)} kg',
                    subvalue: '$displayMaxReps reps',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.show_chart_rounded,
                    label: 'EST. 1RM',
                    value: '${displayE1rm.toStringAsFixed(1)} kg',
                    subvalue: '+0.5 this mo',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.layers_outlined,
                    label: 'SESSION VOL',
                    value: '${displayVol.toInt()} kg',
                    subvalue: '$displayTotalSets sets total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Muscles Involved Card
            KineticCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Muscles Involved',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Anatomical Focus',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF71717A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMuscleLoadBar(
                    label: '${_capitalize(widget.exercise.target)} (Target)',
                    value: '85% load',
                    progress: 0.85,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 14),
                  _buildMuscleLoadBar(
                    label: widget.exercise.secondaryMuscles.isEmpty
                        ? 'Stabilizers & Secondary'
                        : widget.exercise.secondaryMuscles.map(_capitalize).join(' & '),
                    value: '15% stabilizer',
                    progress: 0.15,
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressChart(List<ProgressPoint> points, double fallbackMaxWeight) {
    List<FlSpot> spots = [];
    if (points.isNotEmpty) {
      for (var i = 0; i < points.length; i++) {
        final p = points[i];
        final val = switch (_selectedMetric) {
          1 => p.e1rm,
          2 => p.volume / 100.0,
          _ => p.maxWeight,
        };
        spots.add(FlSpot(i.toDouble(), val));
      }
    } else {
      // Clean baseline curve matching Stitch design mockup
      spots = [
        FlSpot(0, fallbackMaxWeight * 0.8),
        FlSpot(1, fallbackMaxWeight * 0.8),
        FlSpot(2, fallbackMaxWeight * 0.8),
        FlSpot(3, fallbackMaxWeight * 0.9),
        FlSpot(4, fallbackMaxWeight * 0.9),
        FlSpot(5, fallbackMaxWeight * 0.9),
        FlSpot(6, fallbackMaxWeight * 1.0),
        FlSpot(7, fallbackMaxWeight * 0.9),
        FlSpot(8, fallbackMaxWeight * 1.0),
        FlSpot(9, fallbackMaxWeight * 1.0),
      ];
    }

    final minY = spots.map((s) => s.y).reduce(math.min) * 0.85;
    final maxY = spots.map((s) => s.y).reduce(math.max) * 1.15;

    return LineChart(
      LineChartData(
        minY: minY > 0 ? minY : 0,
        maxY: maxY > minY ? maxY : minY + 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFF27272A),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()} kg',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final labels = ['Aug 3', 'Aug 14', 'Aug 28', 'Sep 14', 'Oct 3'];
                if (idx >= 0 && idx < labels.length && idx % 2 == 0) {
                  return Text(
                    labels[idx % labels.length],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF161618),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(int index, String label) {
    final isSelected = _selectedMetric == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMetric = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF27272A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : const Color(0xFFA1A1AA),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subvalue,
  }) {
    return KineticCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF71717A)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleLoadBar({
    required String label,
    required String value,
    required double progress,
    required bool isPrimary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF27272A),
            valueColor: AlwaysStoppedAnimation<Color>(
              isPrimary ? Colors.white : const Color(0xFF52525B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: HISTORY
  // ==========================================
  Widget _buildHistoryTab() {
    return FutureBuilder<List<ExerciseHistorySession>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        // Calculate summary stats
        final totalSessions = sessions.length;
        double sumWeight = 0;
        int completedSetsCount = 0;

        for (final session in sessions) {
          for (final set in session.sets.where((s) => s.completed)) {
            sumWeight += set.weightGrams / 1000.0;
            completedSetsCount++;
          }
        }

        final avgLoad = completedSetsCount > 0
            ? (sumWeight / completedSetsCount).toStringAsFixed(1)
            : '0.0';

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                // Top Stat Row
                Row(
                  children: [
                    Expanded(
                      child: KineticCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'RECORDED SESSIONS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Color(0xFF71717A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$totalSessions',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'LOGS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KineticCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'AVG LOAD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF71717A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 14,
                                  color: Color(0xFF71717A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  avgLoad,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'KG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WORKOUT LOGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF71717A),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.calendar_month_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'All time',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Workout Session Cards
                if (sessions.isEmpty)
                  KineticCard(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                    borderRadius: 20,
                    child: Column(
                      children: const [
                        Icon(Icons.history_rounded, size: 40, color: Color(0xFF52525B)),
                        SizedBox(height: 12),
                        Text(
                          'Belum Ada Riwayat Latihan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Selesaikan sesi latihan dengan gerakan ini untuk melihat riwayat set dan repetisi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final session in sessions) ...[
                    _buildWorkoutLogCard(session),
                    const SizedBox(height: 14),
                  ],
              ],
            ),

            // Bottom Sticky CTA Bar matching Stitch mockup
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.black, size: 20),
                        label: const Text(
                          'Catat Latihan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: () {
                          if (widget.onSelect != null) {
                            Navigator.pop(context);
                            widget.onSelect!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  KineticIconButton(
                    size: 50,
                    icon: const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutLogCard(ExerciseHistorySession session) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    final formattedDate = dateFormat.format(session.workout.startedAt);

    return KineticCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with workout name and chevron
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${session.workout.name.toUpperCase()} •',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF71717A),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 12),

          // Exercise Mini Sub-header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(widget.exercise.name),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_capitalize(widget.exercise.target)} • ${_capitalize(widget.exercise.equipment)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sets Table Header
          Row(
            children: const [
              SizedBox(
                width: 36,
                child: Text(
                  'SET',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'WEIGHT & REPS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sets Rows
          for (final set in session.sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${set.position + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(set.weightGrams / 1000.0).toStringAsFixed(1)} kg × ${set.reps} reps',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    set.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: set.completed ? Colors.white : const Color(0xFF52525B),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: HOW TO
  // ==========================================
  Widget _buildHowToTab() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            // Movement Demo Hero Card
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: widget.exercise.gifUrl != null &&
                            widget.exercise.gifUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.exercise.gifUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                size: 80,
                                color: Color(0xFF52525B),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fitness_center_rounded,
                            size: 80,
                            color: Color(0xFF52525B),
                          ),
                  ),
                  // Top Right Kinetic Form Badge
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'KINETIC FORM',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Left Target Badge
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.adjust_rounded,
                            size: 13,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Target Otot: ${_capitalize(widget.exercise.target)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exercise Title & Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _capitalize(widget.exercise.name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hypertrophy',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_capitalize(widget.exercise.target)} • ${_capitalize(widget.exercise.equipment)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 12),

            // Metadata Chips (Maintains backward compatibility with tests)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetadataChip(
                  icon: Icons.accessibility_new,
                  label: 'Bagian: ${_capitalize(widget.exercise.bodyPart)}',
                ),
                _buildMetadataChip(
                  icon: Icons.adjust,
                  label: 'Target: ${_capitalize(widget.exercise.target)}',
                ),
                _buildMetadataChip(
                  icon: Icons.fitness_center,
                  label: 'Alat: ${_capitalize(widget.exercise.equipment)}',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Movement Instructions Card
            KineticCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Petunjuk Gerakan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${widget.exercise.instructions.length} Langkah',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.exercise.instructions.isEmpty)
                    const Text(
                      'Belum ada instruksi langkah demi langkah untuk gerakan ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    )
                  else
                    for (var i = 0; i < widget.exercise.instructions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27272A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.exercise.instructions[i],
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFFE4E4E7),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DO and DON'T Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DO Card
                Expanded(
                  child: KineticCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'DO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Tempo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF71717A),
                                    ),
                                  ),
                                  Text(
                                    '2-0-1',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Sudut',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF71717A),
                                    ),
                                  ),
                                  Text(
                                    '85° - 90°',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // DON'T Card
                Expanded(
                  child: KineticCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "DON'T",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Hindari Momentum:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Jangan mengayun badan saat mengangkat beban.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA1A1AA),
                                  height: 1.3,
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
            ),
          ],
        ),

        // Bottom Sticky CTA Bar
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 20),
              label: const Text(
                'Catat Latihan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                if (widget.onSelect != null) {
                  Navigator.pop(context);
                  widget.onSelect!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFA1A1AA)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE4E4E7),
            ),
          ),
        ],
      ),
    );
  }
}
