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
  const AfterAccept({super.key, required this.personelID, required this.task});

  @override
  State<AfterAccept> createState() => _AfterAccept();
}

class _AfterAccept extends State<AfterAccept> {
  bool loading = false;

  List<File> selectedImages = [];
  final picker = ImagePicker();

  Future<void> pickFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> pickFromGallery() async {
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> sendReport() async {
    var uri = Uri.parse('https://api.lcadv.online/api/songtask');

    var request = http.MultipartRequest('POST', uri);

    request.fields['personnel_id'] = widget.personelID;
    request.fields['task_id'] = widget.task.taskId.toString();

    for (var imageFile in selectedImages) {
      String Typee = '';
      if (imageFile.path.endsWith('.png')) {
        Typee = 'image/png';
      } else if (imageFile.path.endsWith('.jpg') || imageFile.path.endsWith('.jpeg')) {
        Typee = 'image/jpeg';
      } else if (imageFile.path.endsWith('.webp')) {
        Typee = 'image/webp';
      } else {
        Typee = 'application/octet-stream';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'img',
          imageFile.path,
          contentType: MediaType(Typee.split('/')[0], Typee.split('/')[1]),
        ),
      );
    }

    var streamedResponse = await request.send();
    var responseBody = await streamedResponse.stream.bytesToString();

    Map<String, dynamic> resData;
    try {
      resData = jsonDecode(responseBody);
    } catch (_) {
      throw Exception("รูปแบบข้อมูลที่ได้ไม่ใช่ JSON: $responseBody");
    }

    String message = resData['message'] ?? "ไม่พบข้อความตอบกลับ";

    if (streamedResponse.statusCode == 200 && resData['success'] == true) {
      print('ส่งข้อมูลสำเร็จ: $message');
      return;
    } else {
      print('ส่งข้อมูลล้มเหลว: $message');
      throw Exception(message);
    }
  }

  Widget imagePickerWidget() {
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
          if (selectedImages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedImages.map((img) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(img, height: 100, width: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImages.remove(img);
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
              }).toList(),
            ),
        ],
      ),
    );
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อมูลไม่ถูกต้อง'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง'))],
      ),
    );
  }

  void whileSubmit() async {
    loading = true;
    setState(() {});

    try {
      await sendReport();
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
                  MaterialPageRoute(
                    builder: (context) => Info(task: widget.task, personelID: widget.personelID),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("ตกลง"),
            ),
          ],
        ),
      );
    } catch (e) {
      showError(e.toString());
    }

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ส่งงาน"), centerTitle: true, automaticallyImplyLeading: true),
      drawer: AppDrawer(personnelId: int.parse(widget.personelID),),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              height: 2,
              width: double.infinity,
              color: Colors.black,
            ),
            SizedBox(height: 20),
            imagePickerWidget(),
            SizedBox(height: 50),
            Center(
              child: SendButton(onPressed: whileSubmit, loading: loading),
            ),
            SizedBox(height: 20),
            Center(child: BackButton()),
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
