import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'package:intl/intl.dart';

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
  DateTime? selectedDueDateTime;

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

  Future<void> pickDueDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDueDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: selectedDueDateTime != null
            ? TimeOfDay.fromDateTime(selectedDueDateTime!)
            : const TimeOfDay(hour: 12, minute: 0),
      );

      if (time != null) {
        setState(() {
          selectedDueDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
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
          "personnel_id": int.parse(widget.personelID),
          'task_id': widget.task.taskId,
          'task_type_id': int.parse(typeID ?? ""),
          'title': title,
          'detail': detail,
          'location': location,
          'people_needed': int.parse(peopleNeed),
          'priority_type_id': int.parse(priorityID ?? ""),
          "task_due_at": selectedDueDateTime?.toIso8601String(),
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("แก้ไขงานสำเร็จ")));
          await Future.delayed(const Duration(seconds: 1));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApproveTaskPage(personelID: widget.personelID)),
          );
        }
      } else {
        showError("ไม่สามารถแก้ไขงานได้");
      }
    } catch (e) {
      showError(e.toString());
    }

    isLoading = false;
    setState(() {});
  }

  Future<void> deleteTask() async {
    final res = await http.post(
      Uri.parse('https://api.lcadv.online/api/removetask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "personnel_id": int.parse(widget.personelID),
        "task_id": widget.task.taskId,
      }),
    );
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("เกิดข้อผิดพลาด"),
        content: Text("กรุณากรอกข้อมูลให้ครบถ้วน"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("ปิด"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขงาน"),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "ลบงาน",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("ยืนยันการลบ"),
                  content: const Text("คุณต้องการลบงานนี้จริงหรือไม่?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("ยกเลิก"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("ลบ", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await deleteTask();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("ลบงานเรียบร้อยแล้ว")));
                }
                if (mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: typeID ?? "0",
                  decoration: const InputDecoration(
                    labelText: "ประเภทงาน",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: "0", child: Text("--ใช้ค่าเดิม--")),
                    ...taskType.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['task_type_id'].toString(),
                        child: Text(item['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) => setState(() => typeID = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priorityID ?? "0",
                  decoration: const InputDecoration(
                    labelText: "ความสำคัญ",
                    prefixIcon: Icon(Icons.priority_high),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: "0", child: Text("--ใช้ค่าเดิม--")),
                    ...priority.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['priority_type_id'].toString(),
                        child: Text(item['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) => setState(() => priorityID = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(
                    labelText: "ชื่องาน",
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => title = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: detail,
                  decoration: const InputDecoration(
                    labelText: "รายละเอียด",
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => detail = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: location,
                  decoration: const InputDecoration(
                    labelText: "สถานที่",
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => location = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: peopleNeed,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "จำนวนคนที่ต้องการ",
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => peopleNeed = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDueDateTime != null
                            ? "กำหนดส่งงาน: ${DateFormat('dd-MM-yyyy HH:mmน.').format(selectedDueDateTime!.toLocal())}"
                            : "ใช้วันเวลาเดิม",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: pickDueDateTime,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("เลือกวันเวลา"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("ยืนยันการแก้ไข"),
                          content: const Text("คุณต้องการแก้ไขงานนี้หรือไม่?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("ยกเลิก"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("ตกลง"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        FocusScope.of(context).unfocus();
                        sendEdit();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("แก้ไข", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
