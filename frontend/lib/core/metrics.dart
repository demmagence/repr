double totalVolume(Iterable<MetricSet> sets) => sets
    .where((set) => set.completed && set.type != 'warmUp')
    .fold(0, (sum, set) => sum + (set.weightGrams / 1000) * set.reps);

double? estimatedOneRepMax(int weightGrams, int reps) {
  if (weightGrams <= 0 || reps < 1 || reps > 12) return null;
  return (weightGrams / 1000) * (1 + reps / 30);
}

String formatKg(int grams) {
  final kg = grams / 1000;
  return kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

int parseKg(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return ((double.tryParse(normalized) ?? -1) * 1000).round();
}

class MetricSet {
  const MetricSet({
    required this.weightGrams,
    required this.reps,
    required this.type,
    this.completed = true,
  });

  final int weightGrams;
  final int reps;
  final String type;
  final bool completed;
}
