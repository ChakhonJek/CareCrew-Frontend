import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static String? token;

  static Future<void> init() async {
    await Firebase.initializeApp();

    // Handler ตอนแอพถูกปิดแล้วมีข้อความเข้า
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ขอสิทธิ์แจ้งเตือน (iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // พิมพ์ Token ออกมา
    token = await FirebaseMessaging.instance.getToken();
    //print("📱 Device Token: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      token = newToken;
      //print("♻️ Token refreshed: $newToken");
      // 👉 ถ้าต้องการ อัปเดต token นี้ไปที่ server ด้วย
    });

    // เวลาแอพเปิดอยู่
    FirebaseMessaging.onMessage.listen((message) {
      //print("🔔 Foreground: ${message.notification?.title}");
    });

    // เวลา user กด notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      //print("📂 Notification clicked: ${message.notification?.title}");
    });
  }

  // ฟังก์ชัน handle background
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    //print("📩 Background message: ${message.notification?.title}");
  }
}
