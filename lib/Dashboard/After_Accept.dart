import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myjek/Dashboard/Info.dart';
import 'package:myjek/Dashboard/Models.dart';

class AfterAccept extends StatefulWidget {
  final String personelID;
  final TaskModel task;
  final bool isEditMode;
  const AfterAccept({
    super.key,
    required this.personelID,
    required this.task,
    this.isEditMode = false,
  });

  @override
  State<AfterAccept> createState() => _AfterAccept();
}

class _AfterAccept extends State<AfterAccept> {
  bool loading = false;

  List<File> newImages = [];
  List<String> existingImages = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      loadExistingEvidence();
    }
  }

  Future<void> loadExistingEvidence() async {
    setState(() => loading = true);
    try {
      final evidences = await fetchTaskEvidence(widget.task.taskId);

      final myEvidences = evidences
          .where((e) => e.assignedId == int.parse(widget.personelID))
          .toList();

      setState(() {
        existingImages = myEvidences.expand((e) => e.files).toList();
      });
    } catch (e) {
      print("โหลดหลักฐานเดิมไม่สำเร็จ: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<List<TaskEvidence>> fetchTaskEvidence(int taskId) async {
    final res = await http.get(Uri.parse("https://api.lcadv.online/api/gettaskevidence/$taskId"));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => TaskEvidence.fromJson(e)).toList();
    } else {
      throw Exception("โหลดข้อมูลงานไม่สำเร็จ: ${res.statusCode}");
    }
  }

  Future<void> pickFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        newImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> pickFromGallery() async {
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        newImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> sendReport() async {
    var uri = Uri.parse('https://api.lcadv.online/api/songtask');
    var request = http.MultipartRequest('POST', uri);

    request.fields['personnel_id'] = widget.personelID;
    request.fields['task_id'] = widget.task.taskId.toString();

    for (var imageFile in newImages) {
      String typee = '';
      if (imageFile.path.endsWith('.png'))
        typee = 'image/png';
      else if (imageFile.path.endsWith('.jpg') || imageFile.path.endsWith('.jpeg'))
        typee = 'image/jpeg';
      else
        typee = 'application/octet-stream';

      request.files.add(
        await http.MultipartFile.fromPath(
          'img',
          imageFile.path,
          contentType: MediaType(typee.split('/')[0], typee.split('/')[1]),
        ),
      );
    }

    for (var url in existingImages) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final bytes = res.bodyBytes;
          final fileName = url.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              'img',
              bytes,
              filename: fileName,
              contentType: MediaType('image', fileName.endsWith('.png') ? 'png' : 'jpeg'),
            ),
          );
        }
      } catch (e) {
        print("โหลดรูปจาก $url ไม่สำเร็จ: $e");
      }
    }

    var streamedResponse = await request.send();
    var responseBody = await streamedResponse.stream.bytesToString();

    Map<String, dynamic> resData;
    try {
      resData = jsonDecode(responseBody);
    } catch (_) {
      throw Exception("รูปแบบข้อมูลที่ได้ไม่ใช่ JSON: $responseBody");
    }

    if (streamedResponse.statusCode == 200 && resData['success'] == true) {
      print('ส่งข้อมูลสำเร็จ: ${resData['message']}');
      return;
    } else {
      throw Exception('ส่งข้อมูลล้มเหลว: ${resData['message']}');
    }
  }

  Widget imagePickerWidget() {
    List<Widget> widgets = [];

    widgets.addAll(
      existingImages.map((url) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, height: 100, width: 100, fit: BoxFit.cover),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    existingImages.remove(url);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        );
      }),
    );
    widgets.addAll(
      newImages.map((file) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(file, height: 100, width: 100, fit: BoxFit.cover),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    newImages.remove(file);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        );
      }),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("รูปภาพ:", style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: pickFromCamera,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 32, color: Colors.blue),
                        SizedBox(height: 4),
                        Text("ถ่ายรูป", style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: pickFromGallery,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo, size: 32, color: Colors.green),
                        SizedBox(height: 4),
                        Text("แกลเลอรี", style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (widgets.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: widgets),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? "แก้ไขหลักฐาน" : "ส่งงาน"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            imagePickerWidget(),
            SizedBox(height: 50),
            Center(
              child: SendButton(
                loading: loading,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("ยืนยันการส่งงาน"),
                      content: Text("คุณแน่ใจหรือไม่ว่าต้องการส่งงานนี้?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("ยกเลิก"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("ส่งงาน"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  setState(() => loading = true);

                  try {
                    await sendReport();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("สำเร็จ"),
                        content: Text("ข้อมูลถูกส่งเรียบร้อยแล้ว"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pop(context, true);
                            },
                            child: Text("ตกลง"),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("ข้อผิดพลาด"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text("ตกลง")),
                        ],
                      ),
                    );
                  } finally {
                    setState(() => loading = false);
                  }
                },
              ),
            ),

            SizedBox(height: 20),
            Center(child: BackButton()),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const SendButton({super.key, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                "ส่งข้อมูล",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  const BackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text("ย้อนกลับ", style: TextStyle(color: Colors.white)),
    );
  }
}
