import 'package:flutter/material.dart';
import 'package:yourstory/start.dart';
import 'login.dart'; // Import your login screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main screen after a delay
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StartPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // Change this to your background image path
              fit: BoxFit.cover,
            ),
          ),
          // Centered Content with logo and optional text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50), // Add some space above the logo
                Image.asset('assets/app_logo.png', width: 200, height: 200),
                SizedBox(height: 20),
                // Text widgets are commented out and can be added later
                /*
                Text(
                  'Your Story',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 10),
                Text(
                  'Interactive Storytelling',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }
}
