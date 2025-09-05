import 'package:flutter/material.dart';
import 'package:myjek/Approve/ApprovePage.dart';
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Approve_function/AddmoreTask.dart';
import 'package:myjek/Approve_function/TaskFromReport.dart';
import 'package:myjek/Dashboard/Dashboard_worker.dart';
import 'package:myjek/Dashboard/Profile.dart';
import 'package:myjek/Login/LoginPage.dart';
import 'package:myjek/Report_Problem/ReportPage.dart';
import 'Working.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskModel {
  int taskId;
  String title;
  String typeName;
  String detail;
  String location;
  int peopleNeeded;
  String assignedBy;
  String status;
  String created_at;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.typeName,
    required this.detail,
    required this.location,
    required this.peopleNeeded,
    required this.assignedBy,
    required this.status,
    required this.created_at,
  });

  TaskModel.fromJson(Map<String, dynamic> json)
    : taskId = json['task_id'],
      title = json['title'],
      typeName = json['type_name'],
      detail = json['detail'],
      location = json['location'],
      peopleNeeded = json['people_needed'],
      assignedBy = json['assigned_by'],
      status = json['status'],
      created_at = json['created_at'];
}

class ReportModel {
  final int reportId;
  final String title;
  final int personnelid;
  final String detail;
  final String location;
  final DateTime createdAt;
  final List<dynamic> file;

  ReportModel({
    required this.reportId,
    required this.title,
    required this.personnelid,
    required this.detail,
    required this.location,
    required this.createdAt,
    required this.file,
  });

  ReportModel.fromJson(Map<String, dynamic> json)
    : reportId = json['report_id'] ?? 0,
      title = json['title'] ?? "",
      personnelid = json['personnel_id'] ?? 0,
      detail = json['detail'] ?? "",
      location = json['location'] ?? "",
      createdAt = DateTime.parse(json['created_at'] ?? ""),
      file = (json['files'] ?? []);
}

class TaskParticipants {
  final int taskId;
  final String personnelName;
  final int personnelCount;
  final String personnel_id;

  TaskParticipants({
    required this.taskId,
    required this.personnelName,
    required this.personnelCount,
    required this.personnel_id,
  });

  TaskParticipants.fromJson(Map<String, dynamic> json)
    : taskId = json['task_id'],
      personnelName = json['personnel_name'],
      personnelCount = json['personnel_count'],
      personnel_id = json['personnel_ids'];
}

class Session {
  static String role = "";
}

class StatusInfo {
  final String dateStatus;
  final String date;
  final Color color;

  StatusInfo({required this.dateStatus, required this.date, required this.color});
}

StatusInfo getStatus(TaskModel task) {
  String statusName;
  Color color;

  switch (task.status) {
    case 'ยังไม่ดำเนินการ':
      statusName = "ลงงานเมื่อ";
      color = Colors.red;
      break;
    case 'อยู่ระหว่างดำเนินการ':
      statusName = "รับงานเมื่อ";
      color = Colors.yellow;
      break;
    case 'เสร็จสิ้น':
      statusName = "เสร็จสิ้น";
      color = Colors.green;
      break;
    case 'รอการตรวจสอบ':
      statusName = "ส่งงานเมื่อ";
      color = Colors.lightBlue;
      break;
    default:
      statusName = "";
      color = Colors.grey;
  }

  final date = getFormatDate(task.created_at);

  return StatusInfo(dateStatus: statusName, date: date, color: color);
}

String getFormatDate(String dateData) {
  const thaiMonth = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  final date = DateTime.parse(dateData);
  final porSorYear = date.year + 543;
  final day = date.day;
  final month = thaiMonth[date.month];

  return '$day $month $porSorYear';
}

class AppDrawer extends StatefulWidget {
  final int personnelId;
  const AppDrawer({super.key, required this.personnelId});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? role;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('role') ?? "0";
    setState(() {
      role = savedRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return Drawer(child: Center(child: CircularProgressIndicator()));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text("เมนู", style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),

          if (role != "1") ...[
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("หน้าหลัก"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(personelID: widget.personnelId.toString()),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.work),
              title: const Text("งานของฉัน"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyWorkTask(personelID: widget.personnelId.toString()),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.work),
              title: const Text("แจ้งปัญหา"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportPage(personelID: widget.personnelId.toString()),
                  ),
                );
              },
            ),
          ],

          if (role == "1") ...[
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text("หน้าหลัก"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ApproveTaskPage(personelID: widget.personnelId.toString()),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("ตรวจสอบงาน"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApprovePage(personelID: widget.personnelId.toString()),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("เพิ่มงาน"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(personnelId: widget.personnelId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text("ปัญหา"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Taskfromreport(personnelId: widget.personnelId),
                  ),
                );
              },
            ),
          ],

          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text("โปรไฟล์"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(personnelId: widget.personnelId.toString()),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "ออกจากระบบ",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
