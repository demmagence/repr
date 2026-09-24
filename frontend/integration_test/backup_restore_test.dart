import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repr/data/database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'backup round-trip identik dan restore invalid tidak mengubah data',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final exercise = (await database.watchExercises().first).first;
      await database.createRoutine('Integration routine', [exercise.id]);
      final source = jsonEncode(await database.exportDocument());

      await database.deleteRoutine(
        (await database.watchRoutines().first).single.id,
      );
      expect(await database.watchRoutines().first, isEmpty);
      await database.importJson(source);
      expect(
        (await database.watchRoutines().first).single.name,
        'Integration routine',
      );
      final restored = await database.exportDocument();
      expect(
        restored['data'],
        (jsonDecode(source) as Map<String, dynamic>)['data'],
      );

      final invalid = jsonDecode(source) as Map<String, dynamic>;
      invalid['schemaVersion'] = 999;
      await expectLater(
        database.importJson(jsonEncode(invalid)),
        throwsFormatException,
      );
      expect(
        (await database.watchRoutines().first).single.name,
        'Integration routine',
      );
    },
  );
}
