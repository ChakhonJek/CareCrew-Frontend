import 'package:flutter/material.dart';
import 'package:myjek/Login/LoginPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/Background.png"),
            fit: BoxFit.cover)
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.1),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.8,
                maxHeight: screenHeight * 0.4,
              ),
              child: Image.asset(
                'images/CareCrewPng.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 40),
            ToLogin(),
            SizedBox(height: 20),
            // ToMoreProblem(),
          ],
        ),
      ),
    );
  }
}

class ToLogin extends StatelessWidget {
  const ToLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      width: screenWidth,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// class ToMoreProblem extends StatelessWidget {
//   const ToMoreProblem({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Container(
//       height: 50,
//       margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
//       width: screenWidth,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue[900],
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(60),
//           ),
//         ),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const ReportPage()),
//           );
//         },
//         child: const Text(
//           "More Problem",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }