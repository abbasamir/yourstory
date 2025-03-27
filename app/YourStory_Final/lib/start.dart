import 'package:flutter/material.dart';
import 'package:yourstory/class_code.dart';
import 'package:yourstory/login.dart';
import 'package:yourstory/signup.dart';
import 'package:yourstory/main.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // For portrait, keep your original sizing
    final double portraitButtonWidth = screenWidth * 0.85;
    final double portraitButtonHeight = 250.0;

    // Reduce button width for landscape mode
    final double landscapeButtonWidth = screenWidth * 0.5; // Reduced width
    final double landscapeButtonHeight = 230.0;

    // Choose button dimensions based on orientation
    final double buttonWidth = isLandscape ? landscapeButtonWidth : portraitButtonWidth;
    final double buttonHeight = isLandscape ? landscapeButtonHeight : portraitButtonHeight;

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  AppWidgets.buildTopPlaceholder(
                    assetPath: 'assets/logo.png',
                    color: const Color(0xFFFF3355),
                    height: 200,
                  ),
                  const SizedBox(height: 50),
                  buildButtons(context, buttonWidth, buttonHeight),
                ],
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFFFF3355),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: screenHeight * 0.5,
                        height: screenHeight * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: buildButtons(context, buttonWidth, buttonHeight),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildButtons(BuildContext context, double buttonWidth, double buttonHeight) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildButton(
            context,
            'assets/email_icon.png',
            'Join with Email',
            const Color(0xFF524686),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Signup(classCode: '',)),
              );
            },
            buttonWidth,
            buttonHeight,
          ),
          SizedBox(height: isLandscape ? 60 : 30),
          buildButton(
            context,
            'assets/class_code_icon.png',
            'Join with Class Code',
            const Color(0xFFFF3355),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClassCodePage()),
              );
            },
            buttonWidth,
            buttonHeight,
          ),
          SizedBox(height: isLandscape ? 50 : 40),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Already a user?',
              style: TextStyle(
                fontSize: isLandscape ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(BuildContext context, String iconPath, String text, Color color,
      VoidCallback onTap, double width, double height) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppShadows.universalShadow(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Image.asset(
                      iconPath,
                      width: isLandscape ? height * 0.95 : (width / 2) - 20,
                      height: height * 0.95,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isLandscape ? 26 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
