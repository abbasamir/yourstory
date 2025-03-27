import 'package:flutter/material.dart';
import 'package:yourstory/teacher_dashboard.dart';

class SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Story Assignment"),
        backgroundColor: const Color(0xFF524686),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Large tick icon
            Icon(
              Icons.check_circle_outline,
              size: 150.0,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            // Success message
            const Text(
              "Story successfully assigned!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 40),
            // Button to navigate to Teacher's Dashboard
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Teacher's Dashboard or Home screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherDashboard(), // Replace with your Teacher Dashboard screen
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524686),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Go to Teacher's Dashboard"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
