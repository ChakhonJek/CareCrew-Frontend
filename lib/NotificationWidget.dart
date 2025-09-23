import 'package:flutter/material.dart';
import 'NotificationPage.dart';
import 'local_notification.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: LocalNotification.notifications,
      builder: (context, notifications, _) {
        int notificationCount = notifications.length;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationPage(),
                  ),
                ).then((_) {
                  LocalNotification.clearNotifications();
                });
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
