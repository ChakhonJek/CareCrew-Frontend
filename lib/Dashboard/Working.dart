import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Dashboard/Info.dart';
import 'package:myjek/NotificationBell.dart';
import 'Models.dart';
import 'dart:convert';

class MyWorkTask extends StatefulWidget {
  final String personelID;
  const MyWorkTask({super.key, required this.personelID});

  @override
  State<MyWorkTask> createState() => _MyWorkTask();
}

class _MyWorkTask extends State<MyWorkTask> {
  List<TaskModel> tasks = [];
  String selectedStatus = "งานทั้งหมด";

  @override
  void initState() {
    super.initState();
    mapTaskData();
  }

  Future<void> mapTaskData() async {
    try {
      final resPerson = await http.get(Uri.parse('https://api.lcadv.online/api/perlrubTasks'));

      if (resPerson.statusCode != 200) {
        setState(() => tasks = []);
        return;
      }

      final resPersonJson = jsonDecode(utf8.decode(resPerson.bodyBytes));
      final int personnelId = int.tryParse(widget.personelID) ?? -1;

      final entry = resPersonJson.firstWhere(
        (e) => e['personnel_id'] == personnelId,
        orElse: () => null,
      );

      if (entry == null) {
        setState(() => tasks = []);
        return;
      }

      final TaskIds = entry['task_id'];
      if (TaskIds == null || TaskIds is! String) {
        setState(() => tasks = []);
        return;
      }

      List<String> taskIds = TaskIds.split(',');

      final res = await http.get(Uri.parse('https://api.lcadv.online/api/Tasks'));

      if (res.statusCode != 200) {
        setState(() => tasks = []);
        return;
      }

      final resJson = jsonDecode(utf8.decode(res.bodyBytes));
      final allTasks = resJson.map<TaskModel>((e) => TaskModel.fromJson(e)).toList();

      print(allTasks);

      final userTasks = allTasks.where((task) => taskIds.contains(task.taskId.toString())).toList();

      setState(() => tasks = userTasks);
    } catch (e) {
      print("Error: $e");
      setState(() => tasks = []);
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
              builder: (_) => Info(task: task, personelID: widget.personelID),
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
      "อยู่ระหว่างดำเนินการ",
      "ต้องการแก้ไข",
      "เสร็จสิ้น",
    ];

    List<TaskModel> filteredTasks = selectedStatus == "งานทั้งหมด"
        ? tasks
        : tasks.where((t) => t.status == selectedStatus).toList();

    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID)),
      appBar: AppBar(
        title: Text("งานของฉัน"),
        actions: [NotificationBell(personnelId: int.parse(widget.personelID))],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
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
              onRefresh: mapTaskData,
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
