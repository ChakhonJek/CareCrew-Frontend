import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myjek/Dashboard/Models.dart';

class ReportPage extends StatefulWidget {
  final String personelID;
  const ReportPage({super.key, required this.personelID});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool loading = false;
  String title = "";
  String detail = "";
  String email = "";
  String location = "";

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
    var uri = Uri.parse('https://api.lcadv.online/api/reportv2');

    var request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['personnel_id'] = widget.personelID;
    request.fields['detail'] = detail;
    request.fields['location'] = location;
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

      request.files.add(await http.MultipartFile.fromPath(
        'img',
        imageFile.path,
        contentType: MediaType(
          Typee.split('/')[0],
          Typee.split('/')[1],
        ),
      ));
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
              ElevatedButton.icon(
                onPressed: pickFromCamera,
                icon: Icon(Icons.camera_alt),
                label: Text("ถ่ายรูป"),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: pickFromGallery,
                icon: Icon(Icons.photo),
                label: Text("เลือกจากแกลเลอรี"),
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
    if (detail.isEmpty || location.isEmpty || title.isEmpty) {
      showError("กรุณากรอกข้อมูลให้ครบ");
      return;
    }

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
              onPressed: (){Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => ReportPage(personelID: widget.personelID)),
            (route) => false,
          );},
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
      appBar: AppBar(
        title: Text("แจ้งเหตุสร้างงาน"),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
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
            TitleField(onChanged: (val) => title = val),
            LocationField(onChanged: (val) => location = val),
            DetailField(onChanged: (val) => detail = val),
            imagePickerWidget(),
            SizedBox(height: 50),
            Center(
              child: SendButton(onPressed: whileSubmit, loading: loading),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleField extends StatelessWidget {
  final Function(String) onChanged;
  const TitleField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ปัญหา:", style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "เรื่องปัญหา",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailField extends StatelessWidget {
  final Function(String) onChanged;
  const DetailField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("รายละเอียด:", style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: TextField(
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: "รายละเอียดปัญหา",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationField extends StatelessWidget {
  final Function(String) onChanged;
  const LocationField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("สถานที่:", style: TextStyle(fontSize: 18)),
          SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "กรอกสถานที่",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;
  const SendButton({super.key, required this.onPressed, required this.loading});

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
