import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'NotificationPage.dart';

class NotificationBell extends StatefulWidget {
  final int personnelId;
  const NotificationBell({super.key, required this.personnelId});

  static Future<void> refreshNotifications() async {
    _NotificationBellState? state = _NotificationBellState.instance;
    if (state != null) {
      await state.fetchNotifications();
    }
  }

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  static _NotificationBellState? instance;
  List<Map<String, dynamic>> notifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    instance = this;
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await http.get(Uri.parse('https://api.lcadv.online/api/notis'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final userNotis = data.where((e) => e['personnel_id'] == widget.personnelId).toList();
        if (!mounted) return;
        setState(() {
          notifications = List<Map<String, dynamic>>.from(userNotis);
          unreadCount = notifications.where((n) => n['read'] == false).length;
        });
      }
    } catch (e) {
      print("แตกกกกกกกกกกกกกกกกกกกกกก: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationPage(personnelId: widget.personnelId),
              ),
            ).then((_) => fetchNotifications());
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$unreadCount",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
