// ไม่ได้ใช้หน้านี้
import 'package:flutter/material.dart';
import 'package:myjek/Login/HomePage.dart';

class AfterReport extends StatelessWidget {
  const AfterReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Transform.translate(
            offset: Offset(0, -100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: Colors.green,
                ),
                SizedBox(height: 20),
                Text(
                  "ขอบคุณสำหรับการแจ้งปัญหา",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  "ข้อมูลของคุณถูกส่งเรียบร้อยแล้ว ทีมงานจะดำเนินการตรวจสอบและแก้ไขโดยเร็วที่สุด",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 100,),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                  child: Text("กลับสู่หน้าหลัก"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}