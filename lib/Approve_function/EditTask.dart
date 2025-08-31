import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovePage.dart';
import 'package:myjek/Dashboard/Models.dart';

class Edittask extends StatefulWidget {
  final TaskModel task;
  final String personelID;
  const Edittask({super.key, required this.task, required this.personelID});

  @override
  State<Edittask> createState() => _EdittaskState();
}

class _EdittaskState extends State<Edittask> {
  bool isLoading = false;
  String? typeID = "0";
  String title = "";
  String detail = "";
  String location = "";
  String peopleNeed = "";
  List<dynamic> taskType = [];
  List<dynamic> priority = [];
  String? priorityID = "0";

  @override
  void initState() {
    super.initState();
    getTaskTypeID();
    getPrioritylist();

    title = widget.task.title;
    detail = widget.task.detail;
    location = widget.task.location;
    peopleNeed = widget.task.peopleNeeded.toString();
  }

  void getTaskTypeID() async {
    final res = await http.get(Uri.parse('https://api.lcadv.online/api/tasktypelist'));
    if (res.statusCode == 200) {
      taskType = jsonDecode(res.body);
      setState(() {});
    }
  }

  void getPrioritylist() async {
    final res = await http.get(Uri.parse('https://api.lcadv.online/api/taskprioritylist'));
    if (res.statusCode == 200) {
      priority = jsonDecode(res.body);
      setState(() {});
    }
  }

  void sendEdit() async {
    isLoading = true;
    setState(() {});

    try {
      final res = await http.post(
        Uri.parse('https://api.lcadv.online/api/edittask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': widget.task.taskId,
          'task_type_id': int.parse(typeID ?? ""),
          'title': title,
          'detail': detail,
          'location': location,
          'people_needed': int.parse(peopleNeed),
          'priority_type_id': int.parse(priorityID ?? ""),
        }),
      );

      if (res.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("ส่งสำเร็จ"),
            content: Text("ข้อมูลถูกส่งเรียบร้อยแล้ว"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => ApprovePage(personelID: widget.personelID)),
                    (route) => false,
                  );
                },
                child: Text("ตกลง"),
              ),
            ],
          ),
        );
      } else {
        showError("เกิดข้อผิดพลาด: ${res.statusCode}");
      }
    } catch (e) {
      showError(e.toString());
    }

    isLoading = false;
    setState(() {});
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("เกิดข้อผิดพลาด"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("ปิด"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("แก้ไขงาน")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: title,
              decoration: InputDecoration(labelText: "ชื่องาน"),
              onChanged: (val) => setState(() => title = val),
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: detail,
              decoration: InputDecoration(labelText: "รายละเอียด"),
              onChanged: (val) => setState(() => detail = val),
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: location,
              decoration: InputDecoration(labelText: "สถานที่"),
              onChanged: (val) => setState(() => location = val),
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: peopleNeed,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "จำนวนคนที่ต้องการ"),
              onChanged: (val) => setState(() => peopleNeed = val),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: typeID ?? "0",
              hint: Text("ประเภทงาน"),
              items: [
                DropdownMenuItem(value: "0", child: Text("--ใช้ค่าเดิม--")),
                ...taskType.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['task_type_id'].toString(),
                    child: Text(item['name']),
                  );
                }).toList(),
              ],
              onChanged: (value) => setState(() => typeID = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: priorityID ?? "0",
              hint: Text("ความสำคัญ"),
              items: [
                DropdownMenuItem(value: "0", child: Text("--ใช้ค่าเดิม--")),
                ...priority.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['priority_type_id'].toString(),
                    child: Text(item['name']),
                  );
                }).toList(),
              ],
              onChanged: (value) => setState(() => priorityID = value),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                sendEdit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text("แก้ไข", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
