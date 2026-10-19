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

  static const timerOngoingNotificationId = 9002;

  Future<void> scheduleRestEnd(DateTime when, {required bool sound}) async {
    await cancelRestTimer();

    // 1. Tampilkan notifikasi live countdown di menu notifikasi (notification drawer)
    try {
      await _plugin.show(
        id: timerOngoingNotificationId,
        title: 'Waktu Istirahat',
        body: 'Istirahat antar set sedang berjalan',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'rest_timer_live',
            'Rest timer aktif',
            channelDescription:
                'Menampilkan hitungan mundur waktu istirahat di notification menu',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showWhen: true,
            when: when.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            onlyAlertOnce: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (_) {}

    // 2. Jadwalkan alarm notifikasi bersuara/getar ketika waktu istirahat habis
    try {
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
    } catch (_) {}
  }

  Future<void> showRestCompletedNotification({required bool sound}) async {
    try {
      await _plugin.cancel(id: timerOngoingNotificationId);
      await _plugin.show(
        id: timerNotificationId,
        title: 'Waktu istirahat selesai!',
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
      );
    } catch (_) {}
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

  Future<void> cancelRestTimer() async {
    try {
      await _plugin.cancel(id: timerOngoingNotificationId);
      await _plugin.cancel(id: timerNotificationId);
    } catch (_) {}
  }
}
