import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static String? token;

  static Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    token = await FirebaseMessaging.instance.getToken();
    //print("📱 Device Token: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      token = newToken;
      //print("♻️ Token refreshed: $newToken");
    });

    FirebaseMessaging.onMessage.listen((message) {
      //print("🔔 Foreground: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      //print("📂 Notification clicked: ${message.notification?.title}");
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    //print("📩 Background message: ${message.notification?.title}");
  }
}
