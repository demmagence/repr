import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app_metadata.dart';
import 'core/notification_service.dart';
import 'data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('id_ID');
  final metadata = await DefaultAppMetadataService().getMetadata();
  final metadataService = DefaultAppMetadataService(initialMetadata: metadata);
  final database = AppDatabase(null, metadataService);
  final notifications = NotificationService();
  await notifications.initialize();
  runApp(
    ProviderScope(
      overrides: [
        appMetadataProvider.overrideWithValue(metadataService),
        databaseProvider.overrideWithValue(database),
        notificationProvider.overrideWithValue(notifications),
      ],
      child: const ReprApp(),
    ),
  );
}
