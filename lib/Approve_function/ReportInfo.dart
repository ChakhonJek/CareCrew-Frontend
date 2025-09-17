import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myjek/Approve_function/AddmoreTask.dart';
import 'package:myjek/Approve_function/TaskFromReport.dart';
import 'package:myjek/Dashboard/Models.dart';

class ReportInfopage extends StatelessWidget {
  final ReportModel reportModel;
  final int personnelid;
  const ReportInfopage({super.key, required this.reportModel, required this.personnelid});

  Future<void> deleteReport() async {
    final res = await http.post(
      Uri.parse('https://api.lcadv.online/api/removereport'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'report_id': reportModel.reportId}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดงาน"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: "ลบงาน",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("ยืนยันการลบ"),
                  content: Text("คุณต้องการลบรายงานนี้จริงหรือไม่?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("ยกเลิก"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("ลบ", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await deleteReport();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("ลบงานเรียบร้อยแล้ว")));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => Taskfromreport(personnelId: personnelid)),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportModel.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เวลาที่แจ้ง ${DateFormat('dd/MM/yyyy HH:mm').format(reportModel.createdAt.toLocal())}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Divider(height: 20, thickness: 1),
                  detail('หัวข้อปัญหา', reportModel.title),
                  detail('หมายเลขผู้แจ้ง:', reportModel.personnelid.toString()),
                  detail('สถานที่:', reportModel.location),
                  detail('รายละเอียด:', reportModel.detail),
                  SizedBox(height: 16),
                  Text("📷 หลักฐานที่ส่งมา", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  reportModel.file.isEmpty
                      ? const Center(child: Text("ยังไม่มีรูปแนบ"))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: reportModel.file.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        reportModel.file[index],
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
                                  reportModel.file[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTaskPage(
                              personnelId: personnelid,
                              prefillTitle: reportModel.title,
                              prefillDetail: reportModel.detail,
                              prefillLocation: reportModel.location,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("สร้างงาน", style: TextStyle(color: Colors.white)),
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

  Widget detail(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
