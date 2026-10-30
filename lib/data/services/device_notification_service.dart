import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class DeviceNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  Future<void> initAndRequestPermissions() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
      _permissionGranted = true;
    } catch (e) {
      debugPrint('Cihaz bildirim servisi başlatma uyarısı: $e');
    }
  }

  Future<bool> requestPermissionsExplicitly() async {
    try {
      bool granted = false;
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final res = await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        granted = res ?? true;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final res = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = res ?? true;
      }

      _permissionGranted = granted;
      return granted;
    } catch (e) {
      debugPrint('Bildirim izni isteme uyarısı: $e');
      return false;
    }
  }

  Future<void> sendDeviceNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initAndRequestPermissions();
    }

    const androidDetails = AndroidNotificationDetails(
      'family_planner_alarm_channel_v2',
      'Saatlik Plan & İlaç Alarmları',
      channelDescription:
          'Günlük saatlik plan, namaz, ilaç ve su tüketimi yüksek öncelikli alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Cihaz bildirimi gönderme uyarısı: $e');
    }
  }
}
