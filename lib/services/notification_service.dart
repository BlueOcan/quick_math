import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _keyEnabled = 'notifications_enabled';

  bool _enabled = true;
  bool get isEnabled => _enabled;

  // ── Notification IDs ──────────────────────────────────────────
  static const int _morningId = 1001;
  static const int _eveningId = 1002;
  static const int _nightId = 1003;

  // ── Messages ──────────────────────────────────────────────────
  static const _schedule = [
    (
      id: _morningId,
      hour: 8,
      minute: 0,
      title: '🧠 Good Morning!',
      body: 'Kick off your day with a quick math session!',
    ),
    (
      id: _eveningId,
      hour: 17,
      minute: 0,
      title: '⚡ Evening Challenge',
      body: 'Take 5 minutes to sharpen your mind. Beat your streak!',
    ),
    (
      id: _nightId,
      hour: 21,
      minute: 0,
      title: '🔥 Night Drill',
      body: 'End the day strong with a quick logic puzzle!',
    ),
  ];

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    // 1. Init timezone data
    tz_data.initializeTimeZones();

    // 2. Set local timezone to ACTUAL device timezone (critical fix)
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    // 3. Init plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // 4. Create Android notification channel with HIGH importance
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'mathvibe_daily',
        'Daily Reminders',
        description: 'Daily practice reminders from mathVIBE',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Request notification permission on Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // 6. Load saved preference
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? true;

    // 7. Schedule if enabled
    if (_enabled) await scheduleAll();
  }

  // ── Request permission ────────────────────────────────────────
  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  // ── Toggle ────────────────────────────────────────────────────
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    if (value) {
      await requestPermission();
      await scheduleAll();
    } else {
      await cancelAll();
    }
  }

  // ── Schedule all 3 ───────────────────────────────────────────
  Future<void> scheduleAll() async {
    // Cancel existing before rescheduling to avoid duplicates
    await cancelAll();
    for (final s in _schedule) {
      await _scheduleDaily(
        id: s.id,
        hour: s.hour,
        minute: s.minute,
        title: s.title,
        body: s.body,
      );
    }
  }

  // ── Cancel all ───────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_eveningId);
    await _plugin.cancel(_nightId);
  }

  // ── Schedule one daily repeating notification ─────────────────
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mathvibe_daily',
      'Daily Reminders',
      channelDescription: 'Daily practice reminders from mathVIBE',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Build next occurrence in device's local timezone
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time already passed today, push to tomorrow
    if (scheduled.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Try exact alarm — fall back to inexact if not permitted (Android 12+)
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Silently skip — app continues normally
      }
    }
  }
}
