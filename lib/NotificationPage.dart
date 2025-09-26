import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:myjek/Dashboard/Models.dart';

class NotificationPage extends StatefulWidget {
  final int personnelId;
  const NotificationPage({super.key, required this.personnelId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final res = await http.get(Uri.parse('https://api.lcadv.online/api/notis'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final userNotis = data.where((e) => e['personnel_id'] == widget.personnelId).toList();
        if (!mounted) return;
        setState(() {
          notifications = List<Map<String, dynamic>>.from(userNotis);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      if (!mounted) return;
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(int notiId) async {
    try {
      await http.post(
        Uri.parse('https://api.lcadv.online/api/readnotis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"noti_id": notiId, "personnel_id": widget.personnelId}),
      );
      fetchNotifications();
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("แจ้งเตือน"), backgroundColor: Colors.lightBlue, elevation: 2),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
              child: Text("ไม่พบแจ้งเตือน", style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : RefreshIndicator(
              onRefresh: fetchNotifications,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final noti = notifications[index];
                  final isNew = noti['read'] == false;

                  return Card(
                    color: isNew ? Colors.blue[50] : Colors.grey[100],
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        "${noti['title']}${isNew ? " (ใหม่)" : ""}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isNew ? Colors.red : Colors.grey[800],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(noti['body']),
                          SizedBox(height: 4),
                          Text(
                            getFormatDate(noti['created_at']),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (isNew) markAsRead(noti['noti_id']);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
