import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<List<String>> notifications = ValueNotifier([]);

  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('notifications') ?? [];
    notifications.value = saved;
  }

  static Future<void> saveNotification(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('notifications') ?? [];
    current.add(message);
    await prefs.setStringList('notifications', current);
    notifications.value = current;
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('carecrewpng');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: DarwinInitializationSettings());

    await _notificationsPlugin.initialize(initSettings);

    await loadNotifications();
  }

  static Future<void> showNotification(RemoteNotification notification,
      {bool inForeground = false}) async {
    final title = notification.title ?? "";
    final body = notification.body ?? "";
    final message = "$title: $body";

    await saveNotification(message);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General Notifications',
      channelDescription: 'Used for general notifications',
      importance: inForeground ? Importance.low : Importance.max,
      priority: inForeground ? Priority.low : Priority.high,
      playSound: !inForeground,
      icon: 'carecrewpng',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(notification.hashCode, title, body, details);
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    notifications.value = [];
  }
}
