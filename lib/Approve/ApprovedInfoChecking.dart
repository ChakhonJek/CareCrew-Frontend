import 'package:flutter/material.dart';
import 'package:myjek/Approve/After_ApprovedTask.dart';
import 'package:myjek/Dashboard/After_Accept.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovedCheckpage extends StatefulWidget {
  final TaskModel task;
  final String personelID;

  const ApprovedCheckpage({super.key, required this.task, required this.personelID});

  @override
  State<ApprovedCheckpage> createState() => _ApprovedCheckpageState();
}

class _ApprovedCheckpageState extends State<ApprovedCheckpage> {
  List<TaskParticipants> workerData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadWorkerData();
  }

  Future<void> loadWorkerData() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('https://api.lcadv.online/api/lrubTasks'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final allWorkers = (decoded as List).map((e) => TaskParticipants.fromJson(e)).toList();
        workerData = allWorkers.where((w) => w.taskId == widget.task.taskId).toList();
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดผู้ร่วมงาน: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showWorkerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('รายชื่อผู้ร่วมงาน'),
        content: Container(
          width: double.maxFinite,
          height: 150,
          child: workerData.isEmpty
              ? const Center(child: Text('ไม่มีผู้ร่วมงานสำหรับงานนี้'))
              : ListView.builder(
                  itemCount: workerData.length,
                  itemBuilder: (context, i) {
                    final names = workerData[i].personnelName
                        .split(',')
                        .map((e) => e.trim())
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'งานหมายเลข: ${workerData[i].taskId.toString().padLeft(6, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...names.map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                            child: Text("ชื่อ: $name"),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(title: const Text("รายละเอียดงาน")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  buildDetailRow('หมายเลขงาน:', task.taskId.toString().padLeft(6, '0')),
                  buildDetailRow('ผู้มอบหมายงาน:', task.assignedBy),
                  buildDetailRow('ประเภทงาน:', task.typeName),
                  buildDetailRow('สถานที่:', task.location),
                  buildDetailRow('จำนวนบุคคลที่ต้องการ:', task.peopleNeeded.toString()),
                  buildDetailRow('รายละเอียด:', task.detail),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: showWorkerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 24, 131, 231),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text(
                        "รายชื่อผู้เข้าร่วม",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckTaskPage(taskId: task.taskId, taskmodel:task),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("ตรวจสอบงาน", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}