double totalVolume(Iterable<MetricSet> sets) => sets
    .where((set) => set.completed && set.type != 'warmUp')
    .fold(0, (sum, set) => sum + (set.weightGrams / 1000) * set.reps);

double? estimatedOneRepMax(int weightGrams, int reps) {
  if (weightGrams <= 0 || reps < 1 || reps > 12) return null;
  return (weightGrams / 1000) * (1 + reps / 30);
}

const double kgToLbsMultiplier = 2.20462262;

double gramsToUnitValue(int grams, String unit) {
  final kg = grams / 1000.0;
  return unit == 'lbs' ? kg * kgToLbsMultiplier : kg;
}

int unitValueToGrams(double value, String unit) {
  final kg = unit == 'lbs' ? value / kgToLbsMultiplier : value;
  return (kg * 1000.0).round();
}

String formatWeight(int grams, {String unit = 'kg'}) {
  if (unit == 'lbs') {
    final lbs = grams / 1000.0 * kgToLbsMultiplier;
    return lbs == lbs.roundToDouble()
        ? lbs.toStringAsFixed(0)
        : lbs.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }
  final kg = grams / 1000.0;
  return kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String formatKg(int grams) => formatWeight(grams, unit: 'kg');

int parseWeight(String value, {String unit = 'kg'}) {
  final normalized = value.trim().replaceAll(',', '.');
  final val = double.tryParse(normalized);
  if (val == null || val < 0) return -1000;
  return unitValueToGrams(val, unit);
}

int parseKg(String value) => parseWeight(value, unit: 'kg');

int stepWeightGrams(int currentGrams, {required bool increment, String unit = 'kg'}) {
  if (unit == 'lbs') {
    final currentLbs = gramsToUnitValue(currentGrams, 'lbs');
    final snapped = (currentLbs / 2.5).round() * 2.5;
    final nextLbs = increment ? snapped + 5.0 : (snapped - 5.0).clamp(0.0, 99999.0);
    return unitValueToGrams(nextLbs, 'lbs');
  } else {
    final nextGrams = increment ? currentGrams + 2500 : (currentGrams - 2500).clamp(0, 100000000);
    return nextGrams;
  }
}

String formatVolume(double volumeKg, {String unit = 'kg'}) {
  if (unit == 'lbs') {
    return (volumeKg * kgToLbsMultiplier).toStringAsFixed(0);
  }
  return volumeKg.toStringAsFixed(0);
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
