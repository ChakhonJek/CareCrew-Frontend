import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:myjek/Approve/ApprovedTask.dart';
import 'package:myjek/Dashboard/Dashboard_worker.dart';
import 'package:myjek/Dashboard/Models.dart';
import 'package:myjek/Dashboard/mainpage.dart';
import 'package:myjek/Login/HomePage.dart';
import 'package:myjek/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _PageState();
}

class _PageState extends State<LoginPage> {
  bool loading = false;
  bool hidePass = true;
  String personelID = "";
  String password = "";

  void login() async {
    if (personelID.isEmpty || password.isEmpty) {
      showError("กรุณากรอกให้ครบทุกช่อง");
      return;
    }

    FocusScope.of(context).unfocus();

    loading = true;
    setState(() {});

    try {
      final url = Uri.parse("https://api.lcadv.online/api/loginv2");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personnel_id': int.parse(personelID),
          'password': password,
          'token': FcmService.token,
        }),
      );

      final resJson = jsonDecode(utf8.decode(res.bodyBytes));
      final success = resJson['success'];
      final message = resJson['message'];
      final role = resJson['role'];

      if (res.statusCode == 200 && success == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('personelID', personelID);
        await prefs.setString('role', role);
        Session.role = role;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Mainpage(personelID: int.parse(personelID))),
          (Route<dynamic> route) => false,
        );
      } else {
        showError(message);
      }
    } catch (e) {
      showError("เกิดข้อผิดพลาด: $e");
    }

    loading = false;
    setState(() {});
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาดในการเข้าสู่ระบบ'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
      ),
    );
  }

  void togglePass() {
    setState(() {
      hidePass = !hidePass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue[800]!, Colors.blue[800]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Login", style: TextStyle(color: Colors.white, fontSize: 40)),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(225, 95, 27, .3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              LoginField(onChanged: (val) => personelID = val),
                              PasswordField(
                                obscureText: hidePass,
                                onToggle: togglePass,
                                onChanged: (val) {
                                  password = val;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        LoginButton(onPressed: login, loading: loading),
                        const SizedBox(height: 30),
                        BackButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginField extends StatelessWidget {
  final Function(String) onChanged;

  const LoginField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "ID",
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final bool obscureText;
  final VoidCallback onToggle;
  final Function(String) onChanged;

  const PasswordField({
    super.key,
    required this.obscureText,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Password",
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;

  const LoginButton({super.key, required this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                "Login",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
