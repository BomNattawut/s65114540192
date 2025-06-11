

import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationService {
  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combine both Android and iOS settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await notificationPlugin.initialize(initializationSettings);

    _isInitialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'normal_notification_id',
        'normal_notification',
        channelDescription: 'This channel is used for normal notifications.',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ticker',
        
      ),
      iOS: DarwinNotificationDetails(),
    );

    await notificationPlugin.show(
      0, // Notification ID
      title, // Title of the notification
      body, // Body of the notification
      notificationDetails,
    );
  }

Future<void> showPersistentNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'foreground_service_id',
        'Foreground Service',
        
        channelDescription: 'This notification stays visible while the service is running.',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // 🚨 ทำให้แจ้งเตือนลบไม่ได้
      ),
      iOS: DarwinNotificationDetails(),
    );

    await notificationPlugin.show(
      1, // ใช้ ID ที่แตกต่างจาก Notification ปกติ
      "Workout Active",
      "สถานะออกกำลังกายกำลังทำงาน...",
      notificationDetails,
    );
  }

  /// ❌ ลบแจ้งเตือน
  Future<void> cancelNotification() async {
    await notificationPlugin.cancel(1); // ลบเฉพาะ Foreground Service Notification
  }


}
