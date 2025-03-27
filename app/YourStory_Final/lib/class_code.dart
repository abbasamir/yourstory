import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yourstory/signup.dart';

import 'main.dart';

class ClassCodePage extends StatelessWidget {
  final TextEditingController _classCodeController = TextEditingController();

  ClassCodePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          // ─────────────────────────────
          // PORTRAIT LAYOUT
          // ─────────────────────────────
          if (orientation == Orientation.portrait) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopPlaceholderPortrait(context),
                  _buildClassCodeForm(context),
                ],
              ),
            );
          }
          // ─────────────────────────────
          // LANDSCAPE LAYOUT
          // ─────────────────────────────
          else {
            return Row(
              children: [
                // Left Side: Enlarge the placeholder
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3355),
                          boxShadow: AppShadows.universalShadow(),
                        ),
                      ),
                      // Logo in the center
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          width: MediaQuery.of(context).size.height * 0.3,
                          height: MediaQuery.of(context).size.height * 0.3,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Positioned back button
                      Positioned(
                        top: 40,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Side: Form
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: _buildClassCodeForm(context),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Builds the top placeholder for *portrait* mode only.
  Widget _buildTopPlaceholderPortrait(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3355),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: AppShadows.universalShadow(),
          ),
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
          ),
        ),
        // Positioned Back Button
        Positioned(
          top: 40, // Adjust as needed for status bar height
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  /// Builds the class code form (shared by both portrait & landscape).
  Widget _buildClassCodeForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // "ENTER CLASS CODE" + Info button + short description
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ENTER CLASS CODE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF524686),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('About Class Code'),
                        content: const Text(
                          'A class code allows you to join an existing class under a teacher or instructor. '
                              'This helps you access custom content and track your progress under that class. '
                              'If you are unsure about the code, please contact your instructor.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "You're signing up for an existing class with a code!",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // Text field with drop shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: AppShadows.universalShadow(),
            ),
            child: TextFormField(
              controller: _classCodeController,
              decoration: InputDecoration(
                labelText: 'Class Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none, // Remove default border
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your class code';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 30),

          // "LET'S GO" Button
          Container(
            decoration: BoxDecoration(
              boxShadow: AppShadows.universalShadow(),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Signup page, passing the class code
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Signup(
                      classCode: _classCodeController.text.trim(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37bcf4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "LET'S GO",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
