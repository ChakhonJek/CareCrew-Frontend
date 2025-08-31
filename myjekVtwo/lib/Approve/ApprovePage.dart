import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve_function/EditTask.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'dart:convert';

class ApprovePage extends StatefulWidget {
  final String personelID;
  const ApprovePage({super.key, required this.personelID});

  @override
  State<ApprovePage> createState() => _ApprovePageState();
}

class _ApprovePageState extends State<ApprovePage> {
  List<TaskModel> tasks = [];

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
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('${status.dateStatus}: ${status.date}'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.status != "รอการตรวจสอบ" && task.status != "เสร็จสิ้น") ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Edittask(task: task, personelID: widget.personelID),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: TextStyle(fontSize: 12),
                ),
                child: Text("แก้ไข"),
              ),
            ],
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // รอทำหน้าตรวจสอบ

                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: TextStyle(fontSize: 12),
              ),
              child: Text("ตรวจสอบ"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(personnelId: int.parse(widget.personelID),),
      appBar: AppBar(
        title: Text("ตรวจสอบงาน"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: tasks.isEmpty
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, i) {
                  return taskList(tasks[i]);
                },
              ),
      ),
    );
  }
}
