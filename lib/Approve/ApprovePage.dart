import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedInfoChecking.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'dart:convert';

import 'package:myjek/NotificationBell.dart';

class ApprovePage extends StatefulWidget {
  final String personelID;
  const ApprovePage({super.key, required this.personelID});

  @override
  State<ApprovePage> createState() => _ApprovePageState();
}

class _ApprovePageState extends State<ApprovePage> {
  List<TaskModel> task = [];
  bool isLoading = true;

  Future<List<TaskModel>> getData() async {
    final res = await http.get(Uri.parse('https://api.lcadv.online/api/Tasks'));

    if (res.statusCode == 200) {
      List resJson = jsonDecode(utf8.decode(res.bodyBytes));
      return resJson.map((data) => TaskModel.fromJson(data)).toList();
    } else {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    isLoading = true;
    setState(() {});

    try {
      List<TaskModel> loadTask = await getData();
      task = (loadTask.where((task) => task.status == "รอการตรวจสอบ").toList());
      setState(() {});
    } catch (e) {
      print("Error: $e");
    }

    isLoading = false;
    setState(() {});
  }

  Widget taskList(TaskModel task) {
    final status = getStatus(task);

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: status.color, radius: 8),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text("จำนวนคนที่ต้องการ: ${task.personnel_count}/${task.peopleNeeded}คน"),
            Text("มอบหมายงานโดย: ${task.assignedBy}"),
            Text("กำหนดส่งงาน: ${getFormatDate(task.task_due_at)}"),
            SizedBox(height: 5),
            Chip(
              avatar: Icon(Icons.circle, size: 14, color: status.color),
              label: Text("${task.status}"),
              backgroundColor: status.color.withOpacity(0.1),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApprovedCheckpage(task: task, personelID: widget.personelID),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID)),
      appBar: AppBar(
        title: Text("ตรวจสอบงาน"),
        actions: [
          NotificationBell(personnelId: int.parse(widget.personelID)),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: isLoading
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      "ยังไม่มีงานให้ตรวจสอบ",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : task.isEmpty
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      "ยังไม่มีงานให้ตรวจสอบ",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: task.length,
                itemBuilder: (context, i) {
                  return taskList(task[i]);
                },
              ),
      ),
    );
  }
}
