import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myjek/Approve/After_ApprovedTask.dart';
import 'package:myjek/Dashboard/After_Accept.dart';
import 'Models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Info extends StatefulWidget {
  final TaskModel task;
  final String personelID;
  Info({super.key, required this.task, required this.personelID});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  List<TaskParticipants> workerData = [];
  bool isLoading = false;
  bool alreadyAcc = false;
  bool isFull = false;
  bool hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    workerGetData();
    submitStatus();
  }

  void updateTaskStatus(String newStatus) {
    setState(() {
      widget.task.status = newStatus;
    });
  }

  Future<void> workerGetData() async {
    isLoading = true;
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

        final taskWorker = workerData.firstWhere((worker) => worker.taskId == widget.task.taskId);

        alreadyAcc = workerData.any((worker) {
          final List<String> idList = worker.personnel_id
              .split(',')
              .map((id) => id.trim())
              .toList();

          return idList.contains(widget.personelID);
        });

        isFull = taskWorker.personnelCount >= widget.task.peopleNeeded;
      } catch (e) {
        print("เกิดข้อผิดพลาดในการแปลงข้อมูล: $e");
      }
    } else {
      print('API status code: ${res.statusCode}');
      throw Exception('เกิดข้อผิดพลาด');
    }

    isLoading = false;
    setState(() {});
  }

  Future<void> submitStatus() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.lcadv.online/api/persubmittasksbor/${widget.personelID}/${widget.task.taskId}',
        ),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        print("Submit API response: $decoded");
        hasSubmitted = decoded['submit'] ?? false;
        setState(() {});
      } else {
        print('ไม่สามารถโหลด submit status ได้: ${res.statusCode}');
        hasSubmitted = false;
        setState(() {});
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลด submit status: $e");
      hasSubmitted = false;
      setState(() {});
    }
  }

  Future<void> unSendReport() async {
    final res = await http.post(
      Uri.parse('https://api.lcadv.online/api/yoklerksongtask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'personnel_id': int.parse(widget.personelID),
        'task_id': widget.task.taskId,
      }),
    );

    if (res.statusCode == 200) {
      print("ยกเลิกส่งงานเรียบร้อย");
      setState(() {});
    } else {
      print("เกิดข้อผิดพลาด: ${res.statusCode}");
    }
  }

  Future<void> AcceptWork() async {
    final res = await http.post(
      Uri.parse('https://api.lcadv.online/api/lrubtask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'personnel_id': int.parse(widget.personelID),
        'task_id': widget.task.taskId,
      }),
    );
    if (res.statusCode == 200) {
      print("ok");
      await workerGetData();
      updateTaskStatus("อยู่ระหว่างดำเนินการ");
    } else {
      print("เกิดข้อผิดพลาด: ${res.statusCode}");
    }
  }

  Future<void> cancelWork() async {
    final res = await http.post(
      Uri.parse('https://api.lcadv.online/api/yoklerktask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'personnel_id': int.parse(widget.personelID),
        'task_id': widget.task.taskId,
      }),
    );
    if (res.statusCode == 200) {
      print("ok");

      alreadyAcc = false;
      isFull = false;
      workerData = [];
      await workerGetData();
      updateTaskStatus("ยังไม่ดำเนินการ");
      setState(() {});
    } else {
      print("เกิดข้อผิดพลาด: ${res.statusCode}");
    }
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
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
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
                  SizedBox(height: 2),
                  Row(children: [
                    Text("สถานะงาน: " , style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(task.status),
                  ],),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เวลาลงงาน ${getFormatDate(task.created_at)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Divider(height: 20, thickness: 1),
                  detail('หัวข้องาน:', task.title),
                  detail('หมายเลขงาน:', task.taskId.toString().padLeft(6, '0')),
                  detail('ผู้มอบหมายงาน:', task.assignedBy),
                  detail('ประเภทงาน:', task.typeName),
                  detail('สถานที่:', task.location),
                  detail(
                    'จำนวนบุคคลที่ต้องการ:',
                    '${task.personnel_count}/${task.peopleNeeded.toString()}คน',
                  ),
                  detail('กำหนดส่งงาน:', getFormatDate(task.task_due_at)),
                  detail('รายละเอียด:', task.detail),

                  if (task.status == "ต้องการแก้ไข") detail('หมายเหตุ:', task.nosuccess_detail!),

                  SizedBox(height: 16),
                  Center(child: SeeWorkerButton(onPressed: showWorker)),
                ],
              ),
            ),

            SizedBox(height: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Center(
                  child: ActionWorkButtons(
                    task: task,
                    personelID: int.parse(widget.personelID),
                    isFull: isFull,
                    hasAccepted: alreadyAcc,
                    hasSubmitted: hasSubmitted,
                    taskStatus: task.status,
                    onAccept: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('ยืนยัน'),
                          content: Text('คุณแน่ใจที่จะรับงานนี้?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('ตกลง'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AcceptWork();
                      }
                    },
                    onCancel: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('ยืนยัน'),
                          content: Text('คุณแน่ใจที่จะยกเลิกงานนี้?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('ตกลง'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await cancelWork();
                      }
                    },
                    onGoToSubmit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AfterAccept(personelID: widget.personelID, task: task),
                        ),
                      );
                      await submitStatus();
                      setState(() {});
                    },
                    onUnSubmit: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('ยืนยัน'),
                          content: Text('คุณแน่ใจที่จะยกเลิกการส่งงาน?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('ตกลง'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await unSendReport();
                        await submitStatus();
                        setState(() {});
                      }
                    },
                    onViewEvidence: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AfterAccept(
                            personelID: widget.personelID,
                            task: task,
                            isEditMode: true,
                          ),
                        ),
                      );
                      await submitStatus();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
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

class ActionWorkButtons extends StatelessWidget {
  final TaskModel task;
  final int personelID;
  final bool isFull;
  final bool hasAccepted;
  final bool hasSubmitted;
  final String taskStatus;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onGoToSubmit;
  final VoidCallback onUnSubmit;
  final VoidCallback? onViewEvidence;

  const ActionWorkButtons({
    super.key,
    required this.isFull,
    required this.hasAccepted,
    required this.hasSubmitted,
    required this.taskStatus,
    required this.onAccept,
    required this.onCancel,
    required this.onGoToSubmit,
    required this.onUnSubmit,
    required this.task,
    required this.personelID,
    this.onViewEvidence,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (taskStatus == 'เสร็จสิ้น') {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CheckTaskPage(taskId: task.taskId, taskmodel: task, personnelId: personelID),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text("แสดงหลักฐานการทำงาน", style: TextStyle(color: Colors.white)),
        ),
      );

      return Column(children: buttons);
    }

    if (hasAccepted) {
      if (hasSubmitted) {
        buttons.add(
          ElevatedButton(
            onPressed: onViewEvidence,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("ดู / แก้ไขหลักฐาน", style: TextStyle(color: Colors.white)),
          ),
        );

        buttons.add(SizedBox(height: 20));

        buttons.add(
          ElevatedButton(
            onPressed: onUnSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("ยกเลิกส่งงาน", style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        buttons.add(
          ElevatedButton(
            onPressed: onGoToSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("ส่งงาน", style: TextStyle(color: Colors.white)),
          ),
        );

        buttons.add(SizedBox(height: 20));

        buttons.add(
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("ยกเลิกงาน", style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } else if (isFull) {
      buttons.add(
        ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text("เต็มแล้ว", style: TextStyle(color: Colors.white)),
        ),
      );
    } else {
      buttons.add(
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text("ยอมรับงาน", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Column(children: buttons);
  }
}
