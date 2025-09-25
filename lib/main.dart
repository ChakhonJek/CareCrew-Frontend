import 'package:flutter/material.dart';
import 'package:myjek/Dashboard/mainpage.dart';
import 'package:myjek/fcm_service.dart';
import 'package:myjek/local_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myjek/Login/HomePage.dart';
import 'package:myjek/Dashboard/Dashboard_worker.dart';
import 'package:myjek/Approve/ApprovedTask.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotification.init();
  await FcmService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final personelID = prefs.getString('personelID');
    final role = prefs.getString('role');

    if (personelID != null && role != null) {
      return Mainpage(personelID: int.parse(personelID));
    } else {
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareCrew',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return snapshot.hasData ? snapshot.data! : HomePage();
          }
        },
      ),
    );
  }
}
