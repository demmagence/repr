part of '../screens.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final selectedId =
        exerciseId ?? (exercises.isEmpty ? null : exercises.first.id);
    final selected = exercises.where((e) => e.id == selectedId).firstOrNull;
    final after = rangeMonths == 0
        ? null
        : DateTime.now().subtract(Duration(days: rangeMonths * 31));
    return AppPageShell(
      topBar: const AppTopBar(title: 'Progres'),
      body: ListView(
        padding: pagePadding,
        children: [
          AppSelect<String>(
            label: 'Exercise',
            value: selectedId,
            options: {
              for (final exercise in exercises) exercise.id: exercise.name,
            },
            onChanged: (value) => setState(() => exerciseId = value),
          ),
          const SizedBox(height: 12),
          AppSegmentedControl<int>(
            segments: const [
              AppSegment(value: 1, label: '1 bln'),
              AppSegment(value: 3, label: '3 bln'),
              AppSegment(value: 6, label: '6 bln'),
              AppSegment(value: 0, label: 'Semua'),
            ],
            value: rangeMonths,
            onChanged: (value) => setState(() => rangeMonths = value),
          ),
          const SizedBox(height: 12),
          AppSegmentedControl<String>(
            segments: const [
              AppSegment(value: 'weight', label: 'Beban'),
              AppSegment(value: 'e1rm', label: 'e1RM'),
              AppSegment(value: 'volume', label: 'Volume'),
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
                          child: AppStatCard(
                            label: 'Max weight',
                            value: '${bestWeight.toStringAsFixed(1)} kg',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppStatCard(
                            label: 'Best e1RM',
                            value: '${bestE1rm.toStringAsFixed(1)} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(10, 18, 12, 8),
                      child: SizedBox(
                        height: 280,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: colorScheme.outlineVariant,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color: colorScheme.outlineVariant,
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
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
                                color: colorScheme.primary,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: colorScheme.primary.withValues(
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
