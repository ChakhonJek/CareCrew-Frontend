import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Dashboard/Models.dart';

class CheckTaskPage extends StatelessWidget {
  final int personnelId;
  final int taskId;
  final TaskModel taskmodel;

  CheckTaskPage({
    super.key,
    required this.taskId,
    required this.taskmodel,
    required this.personnelId,
  });

  Future<List<Map<String, dynamic>>> fetchTaskDetails() async {
    final res = await http.get(Uri.parse("https://api.lcadv.online/api/gettaskevidence/$taskId"));

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      if (data.isNotEmpty) {
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("ไม่พบข้อมูลงาน");
      }
    } else {
      throw Exception("โหลดข้อมูลงานไม่สำเร็จ");
    }
  }

  Future<void> alright(BuildContext context) async {
    try {
      final res = await http.post(
        Uri.parse("https://api.lcadv.online/api/tasksuccess"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "personnel_id": personnelId,
          "task_id": taskId}),
      );

      if (res.statusCode == 200) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("สำเร็จ"),
            content: const Text("ตรวจสอบงานสำเร็จ"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApproveTaskPage(personelID: personnelId.toString()),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("ตกลง"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("เกิดข้อผิดพลาด"),
            content: Text("โหลด API ไม่สำเร็จ: ${res.statusCode}"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ปิด")),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ปิด"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(taskmodel.status == "รอการตรวจสอบ" ? "ตรวจสอบ" : "หลักฐานการทำงาน"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchTaskDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
            }

            final List<Map<String, dynamic>> taskList = snapshot.data!;

            final List<String> allFiles = taskList
                .expand((item) => List<String>.from(item["files"]))
                .toList();

            final task = taskList.first;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📝 รายละเอียดงาน", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text("รหัสงาน: ${task["task_id"]}"),
                Text("ชื่องาน: ${task["title"] ?? "-"}"),
                Text("รายละเอียด: ${task["detail"] ?? "-"}"),
                Text("ผู้รับผิดชอบ: ${task["assigned_by"] ?? "-"}"),
                const Divider(height: 32),
                Text("📷 หลักฐานที่ส่งมา", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                allFiles.isEmpty
                    ? const Center(child: Text("ยังไม่มีรูปแนบ"))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: allFiles.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      allFiles[index],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Text("โหลดรูปไม่สำเร็จ"),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                allFiles[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 16),
                if (taskmodel.status == "รอการตรวจสอบ")
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        alright(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("ตรวจสอบงาน", style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
