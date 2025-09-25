import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    await LocalNotification.showNotification(message.notification!, inForeground: false);
  }
}

class FcmService {
  static String? token;

  static Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    token = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      token = newToken;
    });

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.notification != null) {
        await LocalNotification.showNotification(message.notification!, inForeground: true);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (message.notification != null) {
        await LocalNotification.showNotification(message.notification!, inForeground: true);
      }
    });
  }
}
