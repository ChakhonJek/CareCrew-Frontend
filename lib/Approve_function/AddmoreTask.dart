import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Dashboard/Models.dart';

class AddTaskPage extends StatefulWidget {
  final int personnelId;
  final String? prefillTitle;
  final String? prefillDetail;
  final String? prefillLocation;

  const AddTaskPage({
    super.key,
    required this.personnelId,
    this.prefillTitle,
    this.prefillDetail,
    this.prefillLocation,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController peopleNeededController = TextEditingController();

  List<dynamic> taskTypes = [];
  List<dynamic> priorityTypes = [];
  int? selectedTaskType;
  int? selectedPriorityType;

  bool loading = true;
  String result = "";

  @override
  void initState() {
    super.initState();
    loadDropdownData();

    titleController.text = widget.prefillTitle ?? "";
    detailController.text = widget.prefillDetail ?? "";
    locationController.text = widget.prefillLocation ?? "";
  }

  Future<void> loadDropdownData() async {
    try {
      final taskTypeRes = await http.get(Uri.parse("https://api.lcadv.online/api/tasktypelist"));
      final priorityRes = await http.get(
        Uri.parse("https://api.lcadv.online/api/taskprioritylist"),
      );

      setState(() {
        taskTypes = jsonDecode(taskTypeRes.body);
        priorityTypes = jsonDecode(priorityRes.body);
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        result = "โหลดข้อมูลไม่สำเร็จ";
      });
    }
  }

  Future<void> addTask() async {
    final res = await http.post(
      Uri.parse("https://api.lcadv.online/api/addtask"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "task_type_id": selectedTaskType,
        "priority_type_id": selectedPriorityType,
        "title": titleController.text,
        "detail": detailController.text,
        "location": locationController.text,
        "people_needed": int.tryParse(peopleNeededController.text),
        "assigned_by": widget.personnelId,
      }),
    );

    if (res.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("เพิ่มงานสำเร็จ")));
        await Future.delayed(const Duration(seconds: 1));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApproveTaskPage(personelID: widget.personnelId.toString()),
          ),
        );
      }
    } else {
      setState(() {
        result = "Status: ${res.statusCode}\nBody: ${res.body}";
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("เกิดข้อผิดพลาดในการเพิ่มงาน")));
          setState(() {
            result = "";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มงาน")),
      drawer: AppDrawer(personnelId: widget.personnelId),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "ประเภทงาน"),
              items: taskTypes.map<DropdownMenuItem<int>>((item) {
                return DropdownMenuItem<int>(
                  value: item["task_type_id"],
                  child: Text(item["name"]),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedTaskType = val;
                });
              },
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "ความสำคัญ"),
              items: priorityTypes.map<DropdownMenuItem<int>>((item) {
                return DropdownMenuItem<int>(
                  value: item["priority_type_id"],
                  child: Text(item["name"]),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedPriorityType = val;
                });
              },
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "ชื่องาน"),
            ),
            TextField(
              controller: detailController,
              decoration: const InputDecoration(labelText: "รายละเอียด"),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "สถานที่"),
            ),
            TextField(
              controller: peopleNeededController,
              decoration: const InputDecoration(labelText: "จำนวนคนที่ต้องการ"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                addTask();
              },
              child: const Text("เพิ่มงาน"),
            ),
            const SizedBox(height: 20),
            Text(result),
          ],
        ),
      ),
    );
  }
}
