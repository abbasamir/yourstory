import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yourstory/signup.dart';
import 'package:yourstory/terms_and_conditions.dart';
import 'main.dart';
import 'student_dashboard.dart';
import 'privacy_policy.dart'; // Import Privacy Policy screen
import 'reset_password.dart'; // Import Reset Password screen
import 'select_user.dart';
import 'teacher_dashboard.dart';
import 'start.dart';

void main() {
  runApp(MyApp());
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscureText = false,
  String? Function(String?)? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30.0),
      boxShadow: AppShadows.universalShadow(),
    ),
    child: TextFormField(
      // 1) Typed text in GillSansInfant
      style: const TextStyle(
        fontFamily: 'GillSansInfant',
        fontSize: 16,
        color: Colors.black,
      ),
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        // 2) Keep label text (placeholder) in LuckiestGuy
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'LuckiestGuy',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'LuckiestGuy',
            color: Colors.black,
            shadows: AppShadows.universalShadow(),
          ),
          bodyMedium: TextStyle(
            fontSize: 18,
            fontFamily: 'LuckiestGuy',
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.35),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  String? validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}",
    );
    if (!emailRegex.hasMatch(email)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty || password.length < 6) {
      return "Password must be at least 6 characters long";
    }
    return null;
  }

  Future<void> _login() async {
    try {
      // Authenticate the user
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Retrieve the logged-in user's email
      String email = userCredential.user?.email ?? '';

      // Query Firestore for the user's document in the 'parents' collection
      QuerySnapshot querySnapshot = await _firestore
          .collection('parents')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        String role = userData['role'] ?? '';

        if (role == 'teacher') {
          // Navigate to the Teacher Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TeacherDashboard()),
          );
        } else if (role == 'parent') {
          // Navigate to the UserSelectionScreen
          String randomDocumentID = querySnapshot.docs.first.id;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserSelectionScreen(
                documentID: randomDocumentID,
              ),
            ),
          );
        } else {
          throw Exception("Invalid user role");
        }
      } else {
        throw Exception("User document not found");
      }
    } catch (e) {
      // Show an error message if login fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent! Check your email.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          // =========================
          // Portrait Layout
          // =========================
          if (orientation == Orientation.portrait) {
            return Column(
              children: [
                // Top Placeholder Section
                Container(
                  width: double.infinity,
                  height: 200,
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
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Extra spacing below placeholder
                const SizedBox(height: 30),
                // Login Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildLoginForm(context),
                  ),
                ),
              ],
            );
          }
          // =========================
          // Landscape Layout
          // =========================
          else {
            return Row(
              children: [
                // Left side: Larger Logo
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFFFF3355),
                    child: Center(
                      // Enlarge the logo in landscape
                      child: Image.asset(
                        'assets/logo.png',
                        width: MediaQuery.of(context).size.height * 0.4,
                        height: MediaQuery.of(context).size.height * 0.4,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Right side: Login Form
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildLoginForm(context),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Builds the main login form content so we can reuse in both orientations
  Widget _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Welcome Text with Drop Shadow
        Text(
          "WELCOME BACK!",
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: const Color(0xFF524686),
            shadows: AppShadowsLight.universalShadow(),
          ),
        ),
        const SizedBox(height: 40),

        // Email Input with Shadow
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.universalShadow(),
          ),
          child: TextField(
            controller: _emailController,
            style: const TextStyle(
              fontFamily: 'GillSansInfantStd',
              fontSize: 16,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Password Input with Shadow
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.universalShadow(),
          ),
          child: TextField(
            controller: _passwordController,
            style: const TextStyle(
              fontFamily: 'GillSansInfantStd',
              fontSize: 16,
              color: Colors.black,
            ),
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Forgot Password Link
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResetPassword()),
                );
              },
              child: const Text(
                'FORGOT PASSWORD?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFfcce33),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Login Button with Shadow
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[300],
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            shadowColor: Colors.black.withOpacity(0.35),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            'LOGIN',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // "Not a member? Join us" link
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StartPage()),
            );
          },
          child: Text(
            "NOT A MEMBER? JOIN US",
            style: TextStyle(
              color: const Color(0xFF55b399),
              fontWeight: FontWeight.w900,
              shadows: AppShadowsLight.universalShadow(),
            ),
          ),
        ),
      ],
    );
  }
}
