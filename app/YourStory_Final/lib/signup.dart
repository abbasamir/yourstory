import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:yourstory/class_code.dart';
import 'package:yourstory/login.dart';
import 'package:yourstory/privacy_policy.dart';
import 'package:yourstory/terms_and_conditions.dart';
import 'package:yourstory/add_child_info.dart';

class Signup extends StatefulWidget {
  final String? classCode;

  const Signup({Key? key, this.classCode}) : super(key: key);

  @override
  State<Signup> createState() => _SignupPageState();
}

class _SignupPageState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isAgreeChecked = false;

  // Password Validity Booleans (real-time)
  bool _isLengthOk = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    // Listen to password text for real-time checks
    _passwordController.addListener(_checkPasswordValidity);
  }

  void _checkPasswordValidity() {
    final password = _passwordController.text;
    setState(() {
      _isLengthOk = password.length >= 8;
      _hasNumber = RegExp(r'(?=.*[0-9])').hasMatch(password);
      _hasSpecialChar = RegExp(r'(?=.*[!@#$%^&*])').hasMatch(password);
    });
  }

  Future<void> _signUp() async {
    _checkPasswordValidity();

    if (_formKey.currentState!.validate() && _isAgreeChecked) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final String uid = userCredential.user!.uid;
        final Map<String, dynamic> parentData = {
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        };

        if (widget.classCode != null && widget.classCode!.isNotEmpty) {
          parentData['classCode'] = widget.classCode;
        }

        await FirebaseFirestore.instance
            .collection('parents')
            .doc(uid)
            .set(parentData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully created!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddChildrenDetailsScreen()),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (!_isAgreeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Privacy Policy and Terms.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasClassCode =
    (widget.classCode != null && widget.classCode!.isNotEmpty);
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          // ========== PORTRAIT ==========
          if (orientation == Orientation.portrait) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Pink banner EXACT height: 200
                  Container(
                    color: const Color(0xFFFF3355),
                    height: 200,
                    width: double.infinity,
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Form with horizontal padding to make it narrower
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                    child: _buildFormContent(hasClassCode),
                  ),
                ],
              ),
            );
          }
          // ========== LANDSCAPE ==========
          else {
            // Use flex=2 for the pink banner, same as StartPage
            // Use the same image sizing: width/height ~ screenHeight*0.5
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
                // Form on the right with flex=3
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 20),
                      child: _buildFormContent(hasClassCode),
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

  /// The core form content
  Widget _buildFormContent(bool hasClassCode) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Title
          Text(
            'CREATE ACCOUNT',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF524686),
              shadows: [
                Shadow(
                  color: const Color(0x33000000),
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Optional Class Code
          if (hasClassCode) ...[
            Text(
              'CLASS CODE:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.classCode!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF55b399),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Enter Email',
            icon: Icons.email,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Create Password',
            icon: Icons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              } else if (value.length < 8) {
                return 'Password must be at least 8 characters';
              } else if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                return 'Password must contain at least 1 number';
              } else if (!RegExp(r'(?=.*[!@#$%^&*])').hasMatch(value)) {
                return 'Password must contain at least 1 special character';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Requirements bullets
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('At least 8 characters', _isLengthOk),
              _buildBulletPoint(
                'At least 1 special character (!,@,#,%)',
                _hasSpecialChar,
              ),
              _buildBulletPoint('At least 1 number (1,2,3...)', _hasNumber),
            ],
          ),
          const SizedBox(height: 20),

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock,
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Agree to T&C
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _isAgreeChecked,
                onChanged: (value) {
                  setState(() {
                    _isAgreeChecked = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAgreeChecked = !_isAgreeChecked;
                    });
                  },
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF655A93),
                      ),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Color(0xFF55b399),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivacyPolicy(),
                                ),
                              );
                            },
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Color(0xFF55b399),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TermsAndConditions(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Full-width "JOIN US" button
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37bcf4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                'JOIN US',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Row with "JOIN WITH CLASS CODE" and "ALREADY HAVE AN ACCOUNT?" below
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!hasClassCode)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ClassCodePage()),
                    );
                  },
                  child: const Text(
                    'JOIN WITH CLASS CODE',
                    style: TextStyle(
                      fontSize: 20, // a bit bigger
                      color: Color(0xFF55b399),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(width: 1),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: const Text(
                  'ALREADY HAVE AN ACCOUNT?',
                  style: TextStyle(
                    fontSize: 20, // a bit bigger
                    color: Color(0xFFfcce33),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// TextFormField with drop shadow
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        validator: validator,
      ),
    );
  }

  /// Bullet point row for password requirements
  Widget _buildBulletPoint(String text, bool isValid) {
    final Color greenColor = const Color(0xFF55b399);
    final Color redColor = const Color(0xFFFF3355);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 20,
              color: isValid ? greenColor : redColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isValid ? greenColor : redColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
