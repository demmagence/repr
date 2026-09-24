import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repr/app.dart';
import 'package:repr/core/app_metadata.dart';
import 'package:repr/core/notification_service.dart';
import 'package:repr/data/database.dart';
import 'package:repr/features/screens.dart';
import 'package:repr/ui/material/app_ui.dart';

class _MockAssetBundle extends CachingAssetBundle {
  _MockAssetBundle(this.content);
  final String content;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'pubspec.yaml') return content;
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final list = Uint8List.fromList(str.codeUnits);
    return ByteData.view(list.buffer);
  }
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<RestTimerPermissionStatus> requestRestTimerPermission() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<RestTimerPermissionStatus> permissionStatus() async =>
      const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );

  @override
  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {}

  @override
  Future<void> cancelRestTimer() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('AppMetadata parsing', () {
    test('mem-parsing versi dan build number dari string pubspec.yaml', () {
      const yaml = '''
name: repr
description: Gym tracker
version: 2.4.1+15
environment:
  sdk: ^3.12.0
''';
      final metadata = AppMetadata.fromPubspecYaml(yaml);
      expect(metadata.version, '2.4.1');
      expect(metadata.buildNumber, '15');
      expect(metadata.fullVersion, '2.4.1+15');
      expect(metadata.displayVersion, '2.4.1');
    });

    test('mem-parsing versi tanpa build number dengan aman', () {
      const yaml = '''
name: repr
version: 3.0.0
''';
      final metadata = AppMetadata.fromPubspecYaml(yaml);
      expect(metadata.version, '3.0.0');
      expect(metadata.buildNumber, '');
      expect(metadata.fullVersion, '3.0.0');
      expect(metadata.displayVersion, '3.0.0');
    });

    test('menggunakan fallback default saat versi tidak ditemukan', () {
      const yaml = '''
name: repr
''';
      final metadata = AppMetadata.fromPubspecYaml(yaml);
      expect(metadata.version, '1.0.0');
      expect(metadata.buildNumber, '1');
      expect(metadata.fullVersion, '1.0.0+1');
    });
  });

  group('DefaultAppMetadataService', () {
    test('memuat metadata dari AssetBundle secara async', () async {
      final bundle = _MockAssetBundle('version: 4.2.0+88\n');
      final service = DefaultAppMetadataService(bundle: bundle);
      final meta = await service.getMetadata();

      expect(meta.version, '4.2.0');
      expect(meta.buildNumber, '88');
      expect(meta.fullVersion, '4.2.0+88');
      expect(service.currentMetadata.version, '4.2.0');
    });
  });

  group('Database backup export appVersion dinamik', () {
    test(
      'exportDocument menggunakan versi dari AppMetadata yang di-inject',
      () async {
        const customMeta = AppMetadata(version: '2.5.0', buildNumber: '42');
        final service = DefaultAppMetadataService(initialMetadata: customMeta);
        final db = AppDatabase(NativeDatabase.memory(), service);

        final doc = await db.exportDocument();
        expect(doc['appVersion'], '2.5.0+42');
        expect(doc['appVersion'], isNot('1.0.0'));

        await db.close();
      },
    );
  });

  group('SettingsScreen version display dinamik', () {
    testWidgets(
      'menampilkan versi dinamis sesuai appMetadataProvider yang di-inject',
      (tester) async {
        const customMeta = AppMetadata(version: '3.1.4', buildNumber: '159');
        final service = DefaultAppMetadataService(initialMetadata: customMeta);
        final database = AppDatabase(NativeDatabase.memory(), service);

        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appMetadataProvider.overrideWithValue(service),
              databaseProvider.overrideWithValue(database),
              notificationProvider.overrideWithValue(
                _NoopNotificationService(),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: const Scaffold(body: SettingsScreen()),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Repr 3.1.4'), findsOneWidget);
        expect(find.text('Repr 1.0.0'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.runAsync(database.close);
      },
    );
  });
}
