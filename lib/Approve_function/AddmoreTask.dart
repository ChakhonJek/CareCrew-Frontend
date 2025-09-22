import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:intl/intl.dart';

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
  DateTime? selectedDueDateTime;

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
      final taskTypeRes = await http.get(
        Uri.parse("https://api.lcadv.online/api/tasktypelist"),
      );
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
          selectedDueDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> addTask() async {
    final response = await http.post(
      Uri.parse("https://api.lcadv.online/api/addtask"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "personnel_id": widget.personnelId,
        "task_type_id": selectedTaskType,
        "priority_type_id": selectedPriorityType,
        "title": titleController.text,
        "detail": detailController.text,
        "location": locationController.text,
        "people_needed": int.tryParse(peopleNeededController.text),
        "assigned_by": widget.personnelId,
        "task_due_at": selectedDueDateTime?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("เพิ่มงานสำเร็จ")));
        await Future.delayed(const Duration(seconds: 1));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApproveTaskPage(personelID: widget.personnelId.toString()),
          ),
        );
      }
    } else {
      showError("ไม่สามารถแก้ไขงานได้");
      setState(() {
      });
//      if (mounted) {
//        ScaffoldMessenger.of(context).showSnackBar(
//          const SnackBar(content: Text("เกิดข้อผิดพลาดในการเพิ่มงาน")),
//        );
//      }
    }
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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มงาน"),
        backgroundColor: Colors.lightBlue,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "ประเภทงาน",
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "ความสำคัญ",
                        prefixIcon: Icon(Icons.priority_high),
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "ชื่อเรื่อง",
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      decoration: const InputDecoration(
                        labelText: "รายละเอียด",
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "สถานที่",
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: peopleNeededController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "จำนวนคนที่ต้องการ",
                        prefixIcon: Icon(Icons.group),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDateTime != null
                                ? "กำหนดส่งงาน: ${DateFormat('dd-MM-yyyy HH:mmน.').format(selectedDueDateTime!.toLocal())}"
                                : "ยังไม่ได้กำหนดวันเวลาส่งงาน",
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
                              title: const Text("ยืนยันการเพิ่มงาน"),
                              content: const Text(
                                "คุณต้องการเพิ่มงานนี้หรือไม่?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            addTask();
                          }
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text(
                          "เพิ่มงาน",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    if (result.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          result,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
