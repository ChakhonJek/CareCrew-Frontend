import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myjek/Approve/ApprovePage.dart';
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Approve_function/AddmoreTask.dart';
import 'package:myjek/Approve_function/TaskFromReport.dart';
import 'package:myjek/Dashboard/Dashboard_worker.dart';
import 'package:myjek/Dashboard/Profile.dart';
import 'package:myjek/Dashboard/Working.dart';
import 'package:myjek/Report_Problem/ReportPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'package:myjek/NotificationBell.dart';
import 'package:http/http.dart' as http;

class Mainpage extends StatefulWidget {
  final int personelID;
  const Mainpage({super.key, required this.personelID});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  String? role;
  Map<String, dynamic>? profileData;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadRoleAndProfile();
  }

  Future<void> loadRoleAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('role') ?? "0";

    try {
      final res = await http.get(
        Uri.parse('https://api.lcadv.online/api/personnels/${widget.personelID}'),
      );
      profileData = res.statusCode == 200 ? json.decode(res.body) : null;
    } catch (_) {
      profileData = null;
    }

    setState(() {
      role = savedRole;
      loadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null || loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: AppDrawer(personnelId: widget.personelID),
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        title: const Text("CareCrew", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [NotificationBell(personnelId: widget.personelID)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Image.asset("images/CareCrewPng.png", height: 120),
                  ),
                  const Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      "แอปพลิเคชันจัดสรรงาน\nสำหรับแม่บ้านและภารโรง",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profileData?['file'] != null
                        ? Image.network(
                            profileData!['file'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset("images/CareCrewPng.png", width: 100, height: 100),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${profileData?['first_name'] ?? ''} ${profileData?['last_name'] ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileData?['role_name'] ?? '',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: role == "1" ? 5 : 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final menuItems = role == "1"
                      ? [
                          MenuOption(Icons.assignment, "รายการงานทั้งหมด", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ApproveTaskPage(personelID: widget.personelID.toString()),
                              ),
                            );
                          }),
                          MenuOption(Icons.check_circle, "ตรวจสอบงาน", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ApprovePage(personelID: widget.personelID.toString()),
                              ),
                            );
                          }),
                          MenuOption(Icons.note_add, "เพิ่มงาน", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTaskPage(personnelId: widget.personelID),
                              ),
                            );
                          }),
                          MenuOption(Icons.help_center, "รายการแจ้งเหตุสร้างงาน", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Taskfromreport(personnelId: widget.personelID),
                              ),
                            );
                          }),
                          MenuOption(Icons.account_circle, "โปรไฟล์", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(personnelId: widget.personelID.toString()),
                              ),
                            );
                          }),
                        ]
                      : [
                          MenuOption(Icons.assignment, "รายการงาน\nที่เข้าร่วมได้", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DashboardPage(personelID: widget.personelID.toString()),
                              ),
                            );
                          }),
                          MenuOption(Icons.work, "งานของฉัน", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MyWorkTask(personelID: widget.personelID.toString()),
                              ),
                            );
                          }),
                          MenuOption(Icons.help_center, "แจ้งเหตุสร้างงาน", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReportPage(personelID: widget.personelID.toString()),
                              ),
                            );
                          }),
                          MenuOption(Icons.account_circle, "โปรไฟล์", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(personnelId: widget.personelID.toString()),
                              ),
                            );
                          }),
                        ];

                  final item = menuItems[index];
                  return MenuItem(item.icon, item.title, item.onTap);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget MenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class MenuOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  MenuOption(this.icon, this.title, this.onTap);
}
