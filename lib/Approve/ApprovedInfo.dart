import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myjek/Approve/After_ApprovedTask.dart';
import 'package:myjek/Approve_function/EditTask.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovedInfopage extends StatefulWidget {
  final TaskModel task;
  final String personelID;
  ApprovedInfopage({super.key, required this.task, required this.personelID});

  @override
  State<ApprovedInfopage> createState() => _ApprovedInfopageState();
}

class _ApprovedInfopageState extends State<ApprovedInfopage> {
  List<TaskParticipants> workerData = [];

  @override
  void initState() {
    super.initState();
    workerGetData();
  }

  Future<void> workerGetData() async {
    setState(() {});

    final res = await http.get(Uri.parse('https://api.lcadv.online/api/lrubTasks'));

    if (res.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));

        if (decoded == null || decoded is! List) {
          throw Exception("Response ไม่ใช่ List: $decoded");
        }

        final List<dynamic> resJson = decoded;
        final allWorker = resJson.map((data) => TaskParticipants.fromJson(data)).toList();
        workerData = allWorker.where((worker) => worker.taskId == widget.task.taskId).toList();
        workerData.firstWhere((worker) => worker.taskId == widget.task.taskId);
        
        workerData.any((worker) {
          final List<String> idList = worker.personnel_id
              .split(',')
              .map((id) => id.trim())
              .toList();

          return idList.contains(widget.personelID);
        });
      } catch (e) {
        print("เกิดข้อผิดพลาดในการแปลงข้อมูล: $e");
      }
    } else {
      print('API status code: ${res.statusCode}');
      throw Exception('เกิดข้อผิดพลาด');
    }

    false;
    setState(() {});
  }

  void showWorker() async {
    await workerGetData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายชื่อผู้ร่วมงาน'),
        content: Container(
          width: double.maxFinite,
          height: 150,
          child: workerData.isEmpty
              ? Center(child: Text('ไม่มีผู้ร่วมงานสำหรับงานนี้'))
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
                          'งานหมายเลข: ${(workerData[i].taskId).toString().padLeft(6, '0')}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...names.map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                            child: Text("ชื่อ: $name"),
                          ),
                        ),
                        Divider(),
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
      appBar: AppBar(
        title: Text("รายละเอียดงาน"),
        actions: [
          if (task.status != "เสร็จสิ้น" && task.status != "รอการตรวจสอบ")
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Edittask(personelID: widget.personelID, task: task),
                  ),
                );

                if (result == true) {
                  await workerGetData();
                  setState(() {});
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
                  Text(task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ลงงานเมื่อ ${getFormatDate(task.created_at)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(task.status, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(height: 20, thickness: 1),
                  detail('หัวข้องาน', task.title),
                  detail('หมายเลขงาน:', task.taskId.toString().padLeft(6, '0')),
                  detail('ผู้มอบหมายงาน:', task.assignedBy),
                  detail('ประเภทงาน:', task.typeName),
                  detail('สถานที่:', task.location),
                  detail('จำนวนบุคคลที่ต้องการ:', task.peopleNeeded.toString()),
                  detail('รายละเอียด:', task.detail),
                  SizedBox(height: 16),
                  Center(child: SeeWorkerButton(onPressed: showWorker)),
                  if (task.status == "รอการตรวจสอบ") ...[
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckTaskPage(
                                taskId: task.taskId,
                                taskmodel: task,
                                personnelId: int.parse(widget.personelID),
                              ),
                            ),
                          );
                        },
                        child: Text("ตรวจสอบงาน", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                  if (task.status == "เสร็จสิ้น") ...[
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckTaskPage(
                                taskId: task.taskId,
                                taskmodel: task,
                                personnelId: int.parse(widget.personelID),
                              ),
                            ),
                          );
                        },
                        child: Text("หลักฐานการทำงาน", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24),
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

class SeeWorkerButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SeeWorkerButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 24, 131, 231),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text("รายชื่อผู้เข้าร่วม", style: TextStyle(color: Colors.white)),
    );
  }
}
