import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class RestTimerPermissionStatus {
  const RestTimerPermissionStatus({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;

  bool get canSchedule => notificationsGranted && exactAlarmsGranted;
}

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

  Future<RestTimerPermissionStatus> permissionStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const RestTimerPermissionStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return RestTimerPermissionStatus(
      notificationsGranted: await android?.areNotificationsEnabled() ?? true,
      exactAlarmsGranted:
          await android?.canScheduleExactNotifications() ?? true,
    );
  }

  Future<RestTimerPermissionStatus> requestRestTimerPermission() async {
    final current = await permissionStatus();
    if (current.canSchedule ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return current;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsGranted =
        current.notificationsGranted ||
        (await android?.requestNotificationsPermission() ?? false);
    final exactAlarmsGranted =
        current.exactAlarmsGranted ||
        (await android?.requestExactAlarmsPermission() ?? false);
    return RestTimerPermissionStatus(
      notificationsGranted: notificationsGranted,
      exactAlarmsGranted: exactAlarmsGranted,
    );
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
          'rest_timer_v2',
          'Rest timer',
          channelDescription: 'Pengingat waktu istirahat antar set',
          importance: Importance.max,
          priority: Priority.high,
          playSound: sound,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: sound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> playRestAlarm({bool vibrate = true}) async {
    try {
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.electronic,
        volume: 1.0,
        looping: false,
        asAlarm: true,
      );
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
    if (vibrate) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  Future<void> cancelRestTimer() => _plugin.cancel(id: timerNotificationId);
}
