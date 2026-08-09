import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorio diario local, 100% offline (no usa push/FCM). Envuelve
/// flutter_local_notifications + timezone/flutter_timezone, que son
/// las dependencias oficialmente recomendadas por el propio plugin
/// para programar notificaciones recurrentes con hora exacta.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 1001;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Daily reminder';
  static const String _channelDescription =
      'Reminds you to practice for your citizenship exam';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Si no se puede determinar la zona horaria del dispositivo, UTC
      // como fallback seguro. El recordatorio sigue funcionando; la
      // hora exacta podría desviarse hasta que el usuario reconfigure.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    _initialized = true;
  }

  /// Pide el permiso de notificaciones (obligatorio desde Android 13).
  /// Devuelve `true` si quedó concedido.
  Future<bool> requestPermission() async {
    await _ensureInit();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Programa (o reprograma) el recordatorio diario a la hora indicada.
  /// Usa `AndroidScheduleMode.inexactAllowWhileIdle` a propósito: no
  /// necesita el permiso especial `SCHEDULE_EXACT_ALARM`, a costa de
  /// que el sistema puede retrasar la notificación algunos minutos si
  /// el dispositivo está en modo ahorro de batería. Para un
  /// recordatorio motivacional (no una alarma crítica), es el
  /// compromiso correcto.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureInit();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      dailyReminderId,
      title,
      body,
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInit();
    await _plugin.cancel(dailyReminderId);
  }

  Future<bool> isDailyReminderScheduled() async {
    await _ensureInit();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == dailyReminderId);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}