import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Dashboard/Info.dart';
import 'Models.dart';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  final String personelID;
  const DashboardPage({super.key, required this.personelID});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    mapTaskData();
  }

  bool isLoading = true;

  Future<void> mapTaskData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final resPerson = await http.get(Uri.parse('https://api.lcadv.online/api/perlrubTasks'));
      final resTask = await http.get(Uri.parse('https://api.lcadv.online/api/Tasks'));
      final resParticipants = await http.get(Uri.parse('https://api.lcadv.online/api/lrubTasks'));

      if (resTask.statusCode != 200) {
        setState(() {
          tasks = [];
          isLoading = false;
        });
        return;
      }

      final resTaskJson = jsonDecode(utf8.decode(resTask.bodyBytes));
      final allTasks = resTaskJson.map<TaskModel>((data) => TaskModel.fromJson(data)).toList();

      if (resPerson.statusCode != 200 || resParticipants.statusCode != 200) {
        setState(() {
          tasks = allTasks;
          isLoading = false;
        });
        return;
      }

      final String participantsBody = utf8.decode(resParticipants.bodyBytes);
      if (participantsBody.isEmpty || participantsBody == 'null') {
        setState(() {
          tasks = allTasks;
          isLoading = false;
        });
        return;
      }

      final resPartJson = jsonDecode(participantsBody);
      final allParticipants = resPartJson
          .map<TaskParticipants>((data) => TaskParticipants.fromJson(data))
          .toList();

      List<TaskModel> filteredTasks = [];

      for (var task in allTasks) {
        final match = allParticipants.firstWhere(
          (p) => p.taskId == task.taskId,
          orElse: () => TaskParticipants(
            taskId: task.taskId,
            personnelName: '',
            personnelCount: 0,
            personnel_id: widget.personelID,
          ),
        );

        if (task.status == "ยังไม่ดำเนินการ" || task.status == "อยู่ระหว่างดำเนินการ") {
          filteredTasks.add(task);
        }
      }

      setState(() {
        tasks = filteredTasks;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        tasks = [];
        isLoading = false;
      });
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
            Text("จำนวนคนที่ต้องการ: ${task.peopleNeeded}"),
            Text("มอบหมายงานโดย: ${task.assignedBy}"),
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
    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID)),
      appBar: AppBar(
        title: Text("รายการงาน"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: mapTaskData,
        child: isLoading
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : tasks.isEmpty
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(child: Text("ไม่มีงานในขณะนี้")),
                ],
              )
            : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, i) => taskList(tasks[i]),
              ),
      ),
    );
  }
}
