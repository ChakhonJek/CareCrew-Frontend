import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String personnelId;

  const ProfilePage({super.key, required this.personnelId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse('https://api.lcadv.online/api/personnels/${widget.personnelId}'),
      );
      profileData = res.statusCode == 200 ? json.decode(res.body) : null;
    } catch (_) {
      profileData = null;
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://api.lcadv.online/api/personnels/${widget.personnelId}/profile'),
    );
    request.files.add(await http.MultipartFile.fromPath('img', pickedFile.path));

    final response = await request.send();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.statusCode == 200 ? 'อัปโหลดสำเร็จ' : 'อัปโหลดล้มเหลว')),
    );
    if (response.statusCode == 200) getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์"),
        backgroundColor: Colors.lightBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profileData == null
          ? const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 120,
                        backgroundImage: profileData!['file'] != null
                            ? NetworkImage('${profileData!['file']}')
                            : null,
                        child: profileData!['file'] == null
                            ? const Icon(Icons.account_circle, size: 120, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.photo_camera, color: Colors.black87),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo),
                                  title: const Text('จากแกลเลอรี่'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickAndUploadImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera),
                                  title: const Text('ถ่ายรูปใหม่'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickAndUploadImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text("PROFILE PHOTO", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 20),
                buildProfileItem("รหัส: ", profileData!['personnel_id']?.toString() ?? "-"),
                buildProfileItem(
                  "ชื่อ: ",
                  "${profileData!['first_name']} ${profileData!['last_name']}",
                ),
                buildProfileItem("ตำแหน่ง: ", profileData!['role_name'] ?? "-"),
                buildProfileItem("เบอร์โทร: ", profileData!['phone'] ?? "-"),
              ],
            ),
    );
  }

  Widget buildProfileItem(String title, String value) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black)),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
