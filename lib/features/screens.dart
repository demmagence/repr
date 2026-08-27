import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/backup_service.dart';
import '../core/metrics.dart';
import '../data/database.dart';
import '../ui/material/app_ui.dart';

part 'presentation/training_screens.dart';
part 'presentation/workout_screens.dart';
part 'presentation/history_screens.dart';
part 'presentation/progress_screens.dart';
part 'presentation/settings_screens.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

void showMessage(BuildContext context, String message) {
  AppToast.show(context, message);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) =>
      AppEmptyState(icon: icon, title: title, body: body);
}
