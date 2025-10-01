import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings, iOS: DarwinInitializationSettings());

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> showNotification(RemoteNotification notification,
      {bool inForeground = false}) async {
    final title = notification.title ?? "";
    final body = notification.body ?? "";

    final androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General Notifications',
      channelDescription: 'Used for general notifications',
      importance: inForeground ? Importance.low : Importance.max,
      priority: inForeground ? Priority.low : Priority.high,
      playSound: !inForeground,
      icon: '@mipmap/ic_launcher',
    );

    final details =
    NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _notificationsPlugin.show(notification.hashCode, title, body, details);
  }
}