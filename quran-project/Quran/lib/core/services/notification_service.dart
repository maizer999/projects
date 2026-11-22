import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mushaf_text/mushaf_text.dart' as mt;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _notifCount = 48; // 24 h × 2

  /// Called with the page number when the user taps a notification.
  static void Function(int page)? onTap;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );
    _initialized = true;
  }

  static void _onResponse(NotificationResponse r) {
    final page = int.tryParse(r.payload ?? '');
    if (page != null) onTap?.call(page);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse r) {
    final page = int.tryParse(r.payload ?? '');
    if (page != null) onTap?.call(page);
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final darwin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      return await darwin.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  static Future<void> schedule(
    List<mt.Ayah> allAyahs, {
    int fromId = 1,
    int toId = 6236,
  }) async {
    await _plugin.cancelAll();
    final pool = allAyahs.where((a) => a.id >= fromId && a.id <= toId).toList();
    if (pool.isEmpty) return;

    final rng = Random();
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < _notifCount; i++) {
      final scheduledTime = now.add(Duration(minutes: 30 * (i + 1)));
      // Pick a random starting ayah within the pool, then take up to 3 consecutive
      final startIdx = rng.nextInt(pool.length);
      final startAyah = pool[startIdx];
      final pageAyahs = pool
          .where((a) => a.page == startAyah.page && a.id >= startAyah.id)
          .take(3)
          .toList();
      if (pageAyahs.isEmpty) continue;

      final surah = mt.Quran.surahs.firstWhere((s) => s.number == pageAyahs.first.surah);
      final first = pageAyahs.first.number;
      final last = pageAyahs.last.number;
      final ayahRange = first == last ? 'الآية $first' : 'الآيات $first – $last';

      // Title: surah name + ayah range
      final title = '${surah.nameArabic}  ·  $ayahRange';
      // Body: ayah texts joined
      final body = pageAyahs.map((a) => a.text).join('  ');

      await _plugin.zonedSchedule(
        i,
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'quran_reminder',
            'تذكير القرآن',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '${startAyah.page}', // page number so tap can navigate
      );
    }
  }

  static Future<void> cancel() => _plugin.cancelAll();
}
