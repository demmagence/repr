import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';

class BackupService {
  BackupService(this.database);
  final AppDatabase database;

  Future<bool> exportBackup() async {
    final document = await database.exportDocument();
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(document)),
    );
    final result = await FilePicker.saveFile(
      dialogTitle: 'Simpan backup Repr',
      fileName:
          'repr-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json',
      bytes: bytes,
    );
    return result != null;
  }

  Future<BackupPreview?> pickBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return null;
    final bytes = await files.first.readAsBytes();
    final source = utf8.decode(bytes);
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic> ||
        value['format'] != 'repr-backup' ||
        value['schemaVersion'] != 1 ||
        value['data'] is! Map<String, dynamic>) {
      throw const FormatException('File bukan backup Repr versi 1 yang valid.');
    }
    final data = value['data'] as Map<String, dynamic>;
    int count(String key) => (data[key] as List?)?.length ?? 0;
    return BackupPreview(
      source,
      count('routines'),
      count('workouts'),
      count('workoutSets'),
    );
  }
}

class BackupPreview {
  const BackupPreview(this.source, this.routines, this.workouts, this.sets);
  final String source;
  final int routines;
  final int workouts;
  final int sets;
}
