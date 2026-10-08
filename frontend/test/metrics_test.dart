import 'package:flutter_test/flutter_test.dart';
import 'package:repr/core/metrics.dart';

void main() {
  group('format dan parsing berat', () {
    test('menggunakan gram sebagai storage', () {
      expect(parseKg('62,5'), 62500);
      expect(formatKg(62500), '62.5');
      expect(formatKg(60000), '60');
    });

    test('input invalid menghasilkan nilai negatif', () {
      expect(parseKg('abc'), -1000);
    });
  });

  group('statistik strength', () {
    test('Epley hanya berlaku untuk 1 sampai 12 reps dan beban positif', () {
      expect(estimatedOneRepMax(100000, 10), closeTo(133.33, .01));
      expect(estimatedOneRepMax(100000, 13), isNull);
      expect(estimatedOneRepMax(0, 10), isNull);
    });

    test('volume mengabaikan warm-up dan set belum selesai', () {
      const sets = [
        MetricSet(weightGrams: 60000, reps: 10, type: 'working'),
        MetricSet(weightGrams: 20000, reps: 10, type: 'warmUp'),
        MetricSet(
          weightGrams: 60000,
          reps: 8,
          type: 'working',
          completed: false,
        ),
        MetricSet(weightGrams: 50000, reps: 8, type: 'drop'),
      ];
      expect(totalVolume(sets), 1000);
    });
  });

  group('format durasi istirahat (formatRestDuration)', () {
    test('format menit dan detik (uppercase, title/lowercase, dan compact)', () {
      expect(formatRestDuration(90), '1 MENIT 30 DETIK');
      expect(formatRestDuration(60), '1 MENIT');
      expect(formatRestDuration(45), '45 DETIK');
      expect(formatRestDuration(120), '2 MENIT');
      expect(formatRestDuration(75), '1 MENIT 15 DETIK');

      expect(formatRestDuration(90, uppercase: false), '1 menit 30 detik');
      expect(formatRestDuration(60, uppercase: false), '1 menit');
      expect(formatRestDuration(45, uppercase: false), '45 detik');

      expect(formatRestDuration(90, compact: true), '1m 30s');
      expect(formatRestDuration(60, compact: true), '1m');
      expect(formatRestDuration(45, compact: true), '45s');
      expect(formatRestDuration(0, compact: true), '0s');
    });
  });
}
