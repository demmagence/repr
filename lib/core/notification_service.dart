import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  static const timerNotificationId = 9001;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // UTC remains a safe fallback; dates are converted from absolute time.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notification = await android?.requestNotificationsPermission();
    final exact = await android?.requestExactAlarmsPermission();
    return (notification ?? true) && (exact ?? true);
  }

  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {
    await cancelRestTimer();
    await _plugin.zonedSchedule(
      id: timerNotificationId,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      title: 'Waktu istirahat selesai',
      body: 'Saatnya melanjutkan set berikutnya.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Rest timer',
          channelDescription: 'Pengingat waktu istirahat antar set',
          importance: Importance.high,
          priority: Priority.high,
          playSound: sound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelRestTimer() => _plugin.cancel(id: timerNotificationId);
}
