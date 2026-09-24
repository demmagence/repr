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
    final counts = database.validateBackup(source);
    return BackupPreview(
      source,
      counts.routines,
      counts.workouts,
      counts.workoutSets,
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
