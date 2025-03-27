import 'dart:async'; // Import for Timer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class ResetPassword extends StatefulWidget {
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  int _secondsRemaining = 0; // Countdown seconds
  Timer? _timer; // Timer for countdown
  bool _isEmailValid = false; // Email validation flag

  // Method to validate email address
  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    });
  }

  // Method to send password reset email
  Future<void> _sendPasswordResetEmail() async {
    if (!_isEmailValid) {
      setState(() {
        _message = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = ''; // Clear any previous message
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _isLoading = false;
        _message = 'You will receive an email if your account exists.';
        _startCountdown(); // Start countdown after sending email
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Failed to send reset link. Please check the email address.';
      });
    }
  }

  // Start countdown
  void _startCountdown() {
    setState(() {
      _secondsRemaining = 30; // Set countdown duration to 30 seconds
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel(); // Stop the timer when countdown ends
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel(); // Cancel the timer if active
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove top app bar and add back arrow
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent, // Make the AppBar background transparent
        elevation: 0, // Remove the shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Huge Text for "FORGOT PASSWORD?" positioned higher up
            Text(
              'FORGOT PASSWORD?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF655A93),
              ),
            ),
            SizedBox(height: 20),

            // Smaller Text below
            Text(
              'Enter your email and we\'ll send you a link to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Email Input Field with Drop Shadow
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: AppShadows.universalShadow(),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _validateEmail, // Validate email on input change
                style: TextStyle(
                  fontFamily: 'GillSansInfantStd', // Apply custom font
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.alternate_email),
                  hintText: 'Enter your registered email',
                  hintStyle: TextStyle(
                    fontFamily: 'GillSansInfantStd', // Apply custom font
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white, // Background color
                ),
              ),
            ),
            SizedBox(height: 20),

            // Reset Password Button with Conditional Styling
            ElevatedButton(
              onPressed: (_secondsRemaining > 0 || _isLoading)
                  ? null // Disable if countdown is active or loading
                  : _sendPasswordResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondsRemaining > 0
                    ? Colors.grey[800] // Dark gray during countdown
                    : Colors.blue[300], // Original styling
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                _secondsRemaining > 0
                    ? 'RESEND IN $_secondsRemaining' // Countdown text
                    : 'SUBMIT', // Original text
                style: TextStyle(
                  fontSize: 18,
                  color: _secondsRemaining > 0 ? Colors.black : Colors.white, // Text color
                ),
              ),
            ),
            SizedBox(height: 20),

            // Message Display
            if (_message.isNotEmpty)
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _message.contains('sent') ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
