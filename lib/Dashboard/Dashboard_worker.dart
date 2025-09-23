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
  String selectedStatus = "งานทั้งหมด";

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

        if ((task.status == "ยังไม่ดำเนินการ" || task.status == "อยู่ระหว่างดำเนินการ") && (task.personnel_count != task.peopleNeeded)){
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
      "ยังไม่ดำเนินการ",
      "อยู่ระหว่างดำเนินการ"
    ];

    List<TaskModel> filteredTasks = selectedStatus == "งานทั้งหมด"
        ? tasks
        : tasks.where((t) => t.status == selectedStatus).toList();

    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID)),
      appBar: AppBar(
        title: Text("รายการงานที่เข้าร่วมได้"),
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
