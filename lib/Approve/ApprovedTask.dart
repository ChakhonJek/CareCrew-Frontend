import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedInfoChecking.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'dart:convert';

class ApproveTaskPage extends StatefulWidget {
  final String personelID;
  const ApproveTaskPage({super.key, required this.personelID});

  @override
  State<ApproveTaskPage> createState() => _ApproveTaskPageState();
}

class _ApproveTaskPageState extends State<ApproveTaskPage> {
  List<TaskModel> tasks = [];
  String selectedStatus = "งานทั้งหมด";

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
    try {
      List<TaskModel> loadTask = await getData();
      tasks = loadTask;
      setState(() {});
    } catch (e) {
      print("Error: $e");
    }
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
    final List<String> statusOptions = [
      "งานทั้งหมด",
      "ยังไม่ดำเนินการ",
      "อยู่ระหว่างดำเนินการ",
      "รอการตรวจสอบ",
      "ต้องการแก้ไข",
      "เสร็จสิ้น"
    ];

    List<TaskModel> filteredTasks = selectedStatus == "งานทั้งหมด"
        ? tasks
        : tasks.where((t) => t.status == selectedStatus).toList();

    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID)),
      appBar: AppBar(
        title: Text("รายการงานทั้งหมด"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // ChoiceChip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(8),
            child: Row(
              children: statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selectedStatus == status,
                    onSelected: (_) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadTasks,
              child: filteredTasks.isEmpty
                  ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      "ไม่พบงานสถานะดังกล่าว",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                itemBuilder: (context, i) {
                  return taskList(filteredTasks[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
