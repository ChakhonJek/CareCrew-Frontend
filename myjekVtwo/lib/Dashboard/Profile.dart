import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Dashboard/Models.dart';

class ProfilePage extends StatefulWidget {
  final String personnelId;

  const ProfilePage({super.key, required this.personnelId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool Loading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      final res = await http.get(Uri.parse('https://api.lcadv.online/api/personnels/${widget.personnelId}'));
      if (res.statusCode == 200) {
        final resJson = json.decode(utf8.decode(res.bodyBytes));
        profileData = resJson;
        Loading = false;
        setState(() {});
      } else {
        throw Exception('เกิดข้อผิดพลาด');
      }
    } catch (e) {
      Loading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์')),
        drawer: AppDrawer(personnelId: int.parse(widget.personnelId)),
        body: Loading
            ? const Center(child: CircularProgressIndicator())
            : profileData == null
            ? const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Icon(Icons.account_circle, size: 100, color: Colors.grey)),
                    const SizedBox(height: 20),
                    Text(
                      'หมายเลขผู้ใช้: ${profileData!['personnel_id']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ชื่อ: ${profileData!['first_name']} ${profileData!['last_name']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'เบอร์โทร: ${profileData!['phone']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ตำแหน่ง: ${profileData!['role_name']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
      );
    }
  }