import 'package:flutter/material.dart';
import 'local_notification.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    LocalNotification.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แจ้งเตือน')),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: LocalNotification.notifications,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'ไม่มีแจ้งเตือน',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(
                    notifications[index],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
