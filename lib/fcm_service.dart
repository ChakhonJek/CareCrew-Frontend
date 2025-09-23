import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ฟังก์ชัน background ต้องเป็น top-level หรือ static
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    // บันทึกข้อความลง SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('notifications') ?? [];
    final msg = "${message.notification!.title ?? ''}: ${message.notification!.body ?? ''}";
    current.add(msg);
    await prefs.setStringList('notifications', current);

    // อัพเดต ValueNotifier ของ LocalNotification
    LocalNotification.loadNotifications();
  }
}

class FcmService {
  static String? token;

  static Future<void> init() async {
    await Firebase.initializeApp();

    // Background handler ต้องเป็น top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // ดึง token
    token = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      token = newToken;
    });

    // foreground notification
    FirebaseMessaging.onMessage.listen((message) async {
      if (message.notification != null) {
        await LocalNotification.showNotification(message.notification!, inForeground: true);
      }
    });

    // notification เปิดจาก background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (message.notification != null) {
        await LocalNotification.showNotification(message.notification!, inForeground: true);
      }
    });
  }
}
