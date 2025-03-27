import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yourstory/avatar_grid_page.dart';
import 'package:yourstory/story_generation_screen.dart';
import 'package:yourstory/story_selection.dart';
import 'change_avatar_page.dart';
import 'coming_soon.dart';
import 'login.dart';
import 'student_dashboard.dart';
import 'settings.dart';
import 'help_page.dart';
import 'avatar_selection_page.dart';
import 'web_view.dart';

class EditProfilePage extends StatefulWidget {
  final String childId;
  final String childName;
  final String childImage;

  const EditProfilePage({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childImage,
  }) : super(key: key);

  @override
  _EditProfilePage createState() => _EditProfilePage();
}

class _EditProfilePage extends State<EditProfilePage> {
  int _selectedIndex = 1;
  String selectedAvatar = 'assets/profile.png';
  String userName = 'Loading...';
  String? profileImageUrl = '';
  bool isLoading = false;
  int _selectedSquareIndex = -1;
  final Color _purpleColor = const Color(0xFF524686);
  final List<String> _themeNames = ["happy", "space", "fantasy"];
  final List<String> _images = [
    'assets/smiling.png',
    'assets/planet.png',
    'assets/fantasy.png'
  ];
  String classCode = '';
  String gender = '';

  // Initialize PageController immediately
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchProfileImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot parentDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .get();

        if (parentDoc.exists && parentDoc.data() != null) {
          final parentData = parentDoc.data() as Map<String, dynamic>;
          final children = parentData['children'] as Map<String, dynamic>?;
          if (children != null && children.containsKey(widget.childId)) {
            final childData = children[widget.childId] as Map<String, dynamic>;
            setState(() {
              profileImageUrl = childData['selectedAvatar'] ?? '';
              classCode = childData['class_code'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> _saveThemeToFirebase(int index) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentReference parentRef =
      FirebaseFirestore.instance.collection('parents').doc(user.uid);
      DocumentSnapshot parentDoc = await parentRef.get();
      if (parentDoc.exists && parentDoc.data() != null) {
        final parentData = parentDoc.data() as Map<String, dynamic>;
        final children = parentData['children'] as Map<String, dynamic>?;
        if (children != null && children.containsKey(widget.childId)) {
          await parentRef.set({
            'children': {
              widget.childId: {
                'theme': _themeNames[index],
              }
            }
          }, SetOptions(merge: true));
          print("Theme saved for ${widget.childId}: ${_themeNames[index]}");
        } else {
          print("Child ID not found in Firestore.");
        }
      }
    } catch (e) {
      print("Error saving theme: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(widget.childId) // Use childId to access the specific child document
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final childData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = childData['name'] ?? widget.childName;
            profileImageUrl = childData['avatar'] ?? widget.childImage;
            classCode = childData['class_code']?.toString() ?? classCode;
            gender = childData['gender'];// Ensure it’s a number
          });
        } else {
          setState(() {
            userName = widget.childName;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        userName = widget.childName;
      });
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryGeneratorScreen(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(
              childId: widget.childId,
              childName: widget.childName,
              childImage: widget.childImage,
            ),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StorySelectionPage(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
        );
        break;
    }
  }

  void _showClassChangeDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    TextEditingController newClassCodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Request Class Change"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('parents')
                          .doc(user.uid)
                          .update({
                        'children.${widget.childId}.class_code': FieldValue.delete(), // ✅ Correct way
                      });

                      setState(() {
                        classCode = '';
                      });
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      print("Error removing class code: $e");
                    }
                  },
                  child: const Text("Remove from Class"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newClassCodeController,
                  decoration: const InputDecoration(
                    labelText: "New Class Code",
                  ),
                  keyboardType: TextInputType.number, // Assuming numeric input
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    String newClassCode = newClassCodeController.text.trim();
                    if (newClassCode.isNotEmpty) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('parents')
                            .doc(user.uid)
                            .update({
                          'children.${widget.childId}.class_code': int.parse(newClassCode), // ✅ Correct way
                        });

                        setState(() {
                          classCode = newClassCode;
                        });

                        Navigator.pop(dialogContext);
                      } catch (e) {
                        print("Error sending request: $e");
                      }
                    } else {
                      print("Class code cannot be empty.");
                    }
                  },
                  child: const Text("Send Request"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // New join class dialog
  void _showJoinClassDialog() {
    TextEditingController joinClassController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Join a Class"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: joinClassController,
                decoration: const InputDecoration(
                  labelText: "Enter Class Code",
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  String inputCode = joinClassController.text.trim();
                  print("Entered class code: $inputCode"); // Debugging

                  if (inputCode.isEmpty) {
                    print("Input code is empty."); // Debugging
                    return;
                  }

                  try {
                    // Fetch all documents in the 'class' collection
                    QuerySnapshot classDocs = await FirebaseFirestore.instance
                        .collection('class') // Assuming all classes are stored in 'class'
                        .get();

                    print("Fetched ${classDocs.docs.length} class documents."); // Debugging

                    bool classExists = false;

                    // Iterate through all class documents to find a match
                    for (var doc in classDocs.docs) {
                      print("Checking class document: ${doc.id}"); // Debugging

                      var classCode = doc['class_code']; // Retrieve class_code

                      if (classCode != null && classCode.toString() == inputCode) {
                        print("Found matching class code: $classCode"); // Debugging
                        classExists = true;
                        break;
                      }
                    }

                    if (!classExists) {
                      print("Class code doesn't exist."); // Debugging
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Class code doesn't exist.")),
                      );
                    } else {
                      print("Class exists, proceeding with update."); // Debugging

                      String userId = FirebaseAuth.instance.currentUser!.uid;
                      DocumentReference parentRef =
                      FirebaseFirestore.instance.collection('parents').doc(userId);

                      await parentRef.update({
                        'children.${widget.childId}.class_code': inputCode, // ✅ Correctly updates inside the children map
                      });

                      print("Class code updated for child: ${widget.childId}"); // Debugging

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Request to join class sent.")),
                      );
                    }
                  } catch (e) {
                    print("Error during class join process: $e"); // Debugging
                  }
                  Navigator.pop(dialogContext);
                },
                child: const Text("Send Request"),
              ),
            ],
          ),
        );
      },
    );
  }




  // Page 1: Profile header and theme selection
  Widget _buildProfileAndThemeCard() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                // Constrain card width for better aesthetics on larger screens.
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.30),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile header with purple background
                    Container(
                      decoration: BoxDecoration(
                        color: _purpleColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      padding: const EdgeInsets.all(25),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left quadrant: Profile image, username, and "STUDENT" label
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: (profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty)
                                      ? Image.asset(
                                    profileImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                      : Image.asset(
                                    selectedAvatar,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  userName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black12,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "STUDENT",
                                  style: TextStyle(
                                    color: Color(0xFF80DEEA),
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black12,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right quadrant: CLASS CODE, then CHANGE AVATAR button
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                const Text(
                                  "CLASS CODE:",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (classCode.isNotEmpty)
                                  Text(
                                    classCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else
                                  Text(
                                    'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final avatar = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChangeAvatarPage(
                                          childId: widget.childId,
                                        ),
                                      ),
                                    );
                                    if (avatar != null) {
                                      setState(() {
                                        selectedAvatar = avatar;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA726),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(double.infinity, 50),
                                    shadowColor: Colors.black.withOpacity(0.35),
                                    elevation: 6,
                                  ),
                                  child: const Text(
                                    "CHANGE AVATAR",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black12,
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Theme selection
                    Container(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          const Text(
                            "CHANGE THEME",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (index) {
                              final bool isSelected =
                              (index == _selectedSquareIndex);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSquareIndex = index;
                                  });
                                  _saveThemeToFirebase(index);
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: isSelected
                                        ? Border.all(width: 3, color: Colors.blue)
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        offset: const Offset(0, 4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      _images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page 2: Options with header in FF3355 and extra buttons
  Widget _buildOptionsCard() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.30),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with FF3355 background
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3355),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      padding: const EdgeInsets.all(25),
                      child: Center(
                        child: Text(
                          "MORE OPTIONS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (classCode.isNotEmpty) {
                                _showClassChangeDialog();
                              } else {
                                _showJoinClassDialog();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA726),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                              shadowColor: Colors.black.withOpacity(0.35),
                              elevation: 6,
                            ),
                            child: Text(
                              classCode.isNotEmpty
                                  ? "REQUEST CLASS CHANGE"
                                  : "JOIN CLASS",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildButton(
                            context,
                            "SETTINGS",
                            SettingsPage(),
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            hasCurves: false,
                          ),
                          const SizedBox(height: 25),
                          _buildButton(
                            context,
                            "HELP CENTER",
                            HelpPage(),
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            hasCurves: false,
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()),
                                    (Route<dynamic> route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(200, 60),
                              shadowColor: Colors.black.withOpacity(0.35),
                              elevation: 6,
                            ),
                            child: const Text(
                              "LOG OUT",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable button builder
  Widget _buildButton(
      BuildContext context,
      String text,
      Widget page, {
        required Color backgroundColor,
        Color textColor = Colors.black,
        bool hasCurves = true,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: hasCurves
              ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )
              : RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          minimumSize: const Size(double.infinity, 60),
          shadowColor: Colors.black.withOpacity(0.35),
          elevation: 6,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black12,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      backgroundColor: Colors.white,
      // ───────────────────────────────────────────
      // TWO APP BARS depending on orientation
      // ───────────────────────────────────────────
      appBar: orientation == Orientation.portrait
          ? _buildPortraitAppBar()
          : _buildLandscapeAppBar(),

      // ───────────────────────────────────────────
      // BODY: PageView with 2 pages
      // ───────────────────────────────────────────
      body: PageView(
        controller: _pageController,
        children: [
          _buildProfileAndThemeCard(),
          _buildOptionsCard(),
        ],
      ),

      // ───────────────────────────────────────────
      // BOTTOM NAV: portrait vs. landscape
      // ───────────────────────────────────────────
      bottomNavigationBar: orientation == Orientation.portrait
          ? _buildPortraitBottomNav()
          : _buildLandscapeBottomNav(context),
    );
  }

  // -----------------------------------------------------------------
  // PORTRAIT APP BAR (same as original)
  // -----------------------------------------------------------------
  PreferredSizeWidget _buildPortraitAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFF7B4D),
        elevation: 4,
        flexibleSpace: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebViewPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    "LEARN MORE ABOUT US",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // LANDSCAPE APP BAR (same size as code below, i.e. 90)
  // Move "LEARN MORE ABOUT US" to the right, make it larger
  // -----------------------------------------------------------------
  PreferredSizeWidget _buildLandscapeAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: AppBar(
        backgroundColor: const Color(0xFFFF7B4D),
        elevation: 4,
        automaticallyImplyLeading: false,
        flexibleSpace: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 20, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: "EDIT PROFILE"
                Expanded(
                  child: Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // Right: bigger "LEARN MORE ABOUT US"
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebViewPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "LEARN MORE ABOUT US",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // PORTRAIT BOTTOM NAV (unchanged)
  // -----------------------------------------------------------------
  Widget _buildPortraitBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: _purpleColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                spreadRadius: 4,
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left icon
              GestureDetector(
                onTap: () => _onItemTapped(0),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pink,
                      size: 80,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Middle icon
              GestureDetector(
                onTap: () => _onItemTapped(1),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Right icon
              GestureDetector(
                onTap: () => _onItemTapped(2),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Icon(
                      Icons.bar_chart,
                      color: Colors.orange,
                      size: 80,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // LANDSCAPE BOTTOM NAV (from snippet: large icons, row spacing)
  // -----------------------------------------------------------------
  Widget _buildLandscapeBottomNav(BuildContext context) {
    final double footerHeight = 90.0;
    final double iconSize = 140;
    final double containerSize = iconSize + 25;
    final double spacingBetween = 40;
    final double middleButtonSize = containerSize * 1.6;
    final double navIconOffset = -(containerSize / 2) - 60;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: footerHeight,
          decoration: BoxDecoration(
            color: _purpleColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Positioned(
          top: navIconOffset,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Icon
              GestureDetector(
                onTap: () => _onItemTapped(0),
                child: SizedBox(
                  width: containerSize,
                  height: containerSize,
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pink,
                      size: iconSize,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacingBetween),
              // Middle Icon: "Your Story" Logo
              GestureDetector(
                onTap: () => _onItemTapped(1),
                child: SizedBox(
                  width: middleButtonSize,
                  height: middleButtonSize,
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacingBetween),
              // Right Icon
              GestureDetector(
                onTap: () => _onItemTapped(2),
                child: SizedBox(
                  width: containerSize,
                  height: containerSize,
                  child: Center(
                    child: Icon(
                      Icons.bar_chart,
                      color: Colors.orange,
                      size: iconSize,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
