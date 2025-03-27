import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourstory/start.dart';
import 'package:yourstory/coming_soon.dart';
import 'package:yourstory/stories_page_teachers.dart';
import 'package:yourstory/teacher_dashboard.dart'; // Ensure this file exists.
import 'package:yourstory/story_selection.dart';

import 'main.dart';   // Ensure this file exists.

class StudentsPageTeachers extends StatefulWidget {
  const StudentsPageTeachers({Key? key}) : super(key: key);

  @override
  _StudentsPageTeachersState createState() => _StudentsPageTeachersState();
}

class _StudentsPageTeachersState extends State<StudentsPageTeachers> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Teacher info
  String? teacherName;
  String? profileImageUrl;
  int _numStudents = 0;

  // Main students list.
  final List<Map<String, dynamic>> _allStudents = [];

  // At-Risk and Star Students lists.
  final List<String> atRiskStudents = [];
  final List<String> starStudents = [];

  // Dummy flag – force dummy data for testing.
  final bool _useDummyData = true;

  // For multiple classes:
  List<String> _classes = []; // List of class codes
  String? _selectedClassCode; // Variable to store the selected class code
  String? _selectedStudent; // Variable to store the selected student

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("DEBUG: No user is currently signed in.");
        return;
      }

      final String email = user.email ?? '';
      print("DEBUG: Fetching teacher data for email: $email");

      // Query Firestore using email to fetch teacher data
      QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('email', isEqualTo: email)
          .get();

      if (teacherSnapshot.docs.isEmpty) {
        print("DEBUG: No teacher found with email: $email");
        return;
      }

      var teacherData = teacherSnapshot.docs.first.data() as Map<String, dynamic>;
      print("DEBUG: Teacher data fetched: $teacherData");

      setState(() {
        teacherName = teacherData['teacher_name']?.toString() ?? 'Teacher Name';
        profileImageUrl = teacherData['profileImageUrl']?.toString() ?? '';
      });

      // Fetch teacher_code
      final String? teacherCode = teacherData['teacher_code']?.toString();
      if (teacherCode == null || teacherCode.isEmpty) {
        print("DEBUG: No teacher_code found for teacher: $teacherName");
        return;
      }
      print("DEBUG: Teacher code: $teacherCode");

      // Query Firestore to find class documents matching this teacher_code
      QuerySnapshot classSnapshot = await FirebaseFirestore.instance
          .collection('class')
          .where('teacher_code', isEqualTo: int.tryParse(teacherCode) ?? teacherCode)
          .get();

      if (classSnapshot.docs.isEmpty) {
        print("DEBUG: No classes found for teacher_code: $teacherCode");
        return;
      }

      // Extract class codes from matching documents
      List<String> classCodes = classSnapshot.docs
          .map((doc) => doc['class_code'].toString())
          .toList();

      print("DEBUG: Class codes fetched: $classCodes");

      setState(() {
        _classes = classCodes;
        _selectedClassCode = classCodes.isNotEmpty ? classCodes.first : '';
      });

      await _fetchStudents();
    } catch (e, stacktrace) {
      print("ERROR: Failed to fetch teacher data: $e");
      print("STACKTRACE: $stacktrace");
    }
  }


  Future<void> _fetchStudents() async {
    _allStudents.clear();
    atRiskStudents.clear();
    starStudents.clear();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('parents').get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data.containsKey('children')) {
            final children = data['children'] as Map<String, dynamic>;

            children.forEach((key, value) {
              final child = value as Map<String, dynamic>;
              final studentName = child['name']?.toString() ?? 'Unknown Student';
              final classCode = child['class_code']?.toString() ?? 'Unknown Class';

              if (_selectedClassCode != null && classCode == _selectedClassCode) {
                _allStudents.add({
                  'id': doc.id,  // parent document ID
                  'name': studentName,
                  'class_code': classCode,
                });
              }
            });
          }
        }
      }

      // Fallback to dummy data if none found
      if (_allStudents.isEmpty && _useDummyData) {
        _allStudents.addAll([
          {'id': 'dummy1', 'name': 'Dummy Student 1', 'class_code': 'dummy_class'},
          {'id': 'dummy2', 'name': 'Dummy Student 2', 'class_code': 'dummy_class'},
          {'id': 'dummy3', 'name': 'Dummy Student 3', 'class_code': 'dummy_class'},
        ]);
        atRiskStudents.addAll(["Dummy Student 1", "Dummy Student 2"]);
        starStudents.addAll(["Dummy Student 1", "Dummy Student 2"]);
      }

      setState(() {
        _numStudents = _allStudents.length;
      });
    } catch (e) {
      // Handle or log error
    }
  }

  void _sendReminder(String studentName) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sending a reminder to $studentName."),
            TextField(
              controller: _controller,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Enter Reminder',
                hintText: 'Max 30 characters',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String reminderMessage = _controller.text;
              if (reminderMessage.isNotEmpty) {
                try {
                  bool studentFound = false;
                  QuerySnapshot snapshot = await FirebaseFirestore.instance
                      .collection('parents')
                      .get();

                  for (var parentDoc in snapshot.docs) {
                    Map<String, dynamic>? parentData =
                    parentDoc.data() as Map<String, dynamic>?;

                    if (parentData != null && parentData.containsKey('children')) {
                      var children = parentData['children'];
                      if (children is Map<String, dynamic>) {
                        for (var key in children.keys) {
                          var value = children[key];
                          if (value is Map<String, dynamic> &&
                              value['name'] == studentName) {
                            studentFound = true;
                            DocumentReference parentRef =
                            FirebaseFirestore.instance
                                .collection('parents')
                                .doc(parentDoc.id);

                            await parentRef.update({
                              'children.$key.reminder': reminderMessage,
                              'children.$key.timestamp':
                              FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder sent successfully to $studentName',
                                ),
                              ),
                            );
                            break;
                          }
                        }
                      }
                    }
                    if (studentFound) break;
                  }

                  if (!studentFound) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No matching student found'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to send reminder')),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Send"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _openStudentStats(Map<String, dynamic> student) {
    _showStudentInfoPopup(student);
  }

  void _showStudentInfoPopup(Map<String, dynamic> student) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(16.0),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        student['name'] ?? 'Unknown Student',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Avg Level", "12"),
                      _buildStatItem("Required", "14"),
                      _buildStatItem("Class Rank", "5"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Story sections
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStorySection("Assigned Stories", 2, [
                          "• Story A (01/03 - 01/10)",
                          "• Story B (01/05 - 01/12)",
                        ]),
                        const Divider(),
                        _buildStorySection("Completed", 1, [
                          "• Story A done on 01/05",
                        ]),
                        const Divider(),
                        _buildStorySectionWithReassign("Overdue", 1, [
                          "• Story X (Due: 01/10)",
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // "Remind" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _sendReminder(student['name'] ?? 'Unknown Student'),
                      child: const Text(
                        "Remind",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onClassChanged(String? newClass) {
    if (newClass != null && newClass != _selectedClassCode) {
      setState(() {
        _selectedClassCode = newClass;
      });
      _fetchStudents();
    }
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(" ");
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildStatItem(String label, String number) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          number,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: AppShadows.universalShadow(),
          ),
        ),
      ],
    );
  }

  Widget _buildStorySection(String title, int count, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue,
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((line) => Text(line, style: const TextStyle(fontSize: 16)))
            .toList(),
      ],
    );
  }

  Widget _buildStorySectionWithReassign(String title, int count, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue,
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((line) => Text(line, style: const TextStyle(fontSize: 16)))
            .toList(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Reassign Story"),
                    content: const Text(
                        "Reassigning overdue story.\n(Scaffolding)"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                "Reassign",
                style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: 180,
      color: const Color(0xFF524686),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/logo.png',
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            _buildDrawerItem(icon: Icons.home, label: 'Home', onTap: _navigateToTeacherDashboard),
            _buildDrawerItem(icon: Icons.people, label: 'Students', onTap: _navigateToStudentsPage),
            _buildDrawerItem(icon: Icons.book, label: 'Stories', onTap: _navigateToStoryCreation),
            _buildDrawerItem(icon: Icons.settings, label: 'Settings', onTap: _navigateToComingSoon),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                label: const Text("Sign Out", style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }

  Widget _buildBanner() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF524686),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.universalShadow(),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome ${teacherName ?? 'Teacher'}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Glad to see you again. Find the latest insights below.",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total Students in Class: $_numStudents",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: isLandscape ? 100 : null, // Reduce height in landscape mode
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/classroom2.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  Image.asset(
                    'assets/students.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStudentList() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Title and class selector.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Students", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedClassCode,
                items: _classes.map((classCode) => DropdownMenuItem(value: classCode, child: Text(classCode))).toList(),
                onChanged: _onClassChanged,
                hint: const Text("Select Class"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_allStudents.isEmpty)
            const Text("No students found.")
          else
            ..._allStudents.map((stud) {
              final studentName = stud['name'] ?? 'Unnamed Student';
              return Column(
                children: [
                  InkWell(
                    onTap: () => _openStudentStats(stud),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getInitials(studentName),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(studentName, style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                          // Reminder button.
                          TextButton.icon(
                            onPressed: () => _sendReminder(studentName),
                            icon: const Icon(Icons.notifications, color: Colors.grey),
                            label: const Text("Remind", style: TextStyle(color: Colors.grey, fontSize: 14)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAtRiskWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("At-Risk Students", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey, size: 17),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text("At-Risk Info"),
                      content: Text("Shows students who may need extra support due to overdue tasks or lack of progress."),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (atRiskStudents.isEmpty)
            const Text("No at-risk students found.")
          else
            ...atRiskStudents.map((name) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(name),
                onTap: () => _openStudentStats({'id': 'atRisk_$name', 'name': name}),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStarWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Star Students", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text("Star Students Info"),
                      content: Text("Shows students demonstrating exceptional performance or achievements."),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (starStudents.isEmpty)
            const Text("No star students found.")
          else
            ...starStudents.map((name) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star, color: Colors.orange),
                title: Text(name),
                onTap: () => _openStudentStats({'id': 'star_$name', 'name': name}),
              );
            }).toList(),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppShadows.universalShadow(),
    );
  }

  void _navigateToTeacherDashboard() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
  }

  void _navigateToStoryCreation() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryCreationPage()));
  }

  void _navigateToComingSoon() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComingSoonPage()));
  }

  void _navigateToStudentsPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsPageTeachers()));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StartPage()));
  }

  // The original portrait layout
  Widget _buildPortraitLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBanner(),
                const SizedBox(height: 20),
                _buildStudentList(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAtRiskWidget()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStarWidget()),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The modified landscape layout
  Widget _buildLandscapeLayout() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Permanent Sidebar (left)
            Container(
              width: 180,
              color: const Color(0xFF524686),
              child: _buildDrawer(),
            ),

            // Main Content (right)
            Expanded(
              child: Column(
                children: [
                  // A smaller banner at the top
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 110), // smaller banner
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF524686),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.universalShadow(),
                      ),
                      child: Row(
                        children: [
                          // Left text
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome ${teacherName ?? 'Teacher'}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total Students: $_numStudents",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Right image stack
                          Expanded(
                            flex: 2,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/classroom2.png',
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                                Image.asset(
                                  'assets/students.png',
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // The row with student list (70%) + (At-Risk + Star) 30%
                  Expanded(
                    child: Row(
                      children: [
                        // Left side: Student List
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 8.0,
                              bottom: 16.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: _boxDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row: Title and class selector
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Students",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      DropdownButton<String>(
                                        value: _selectedClassCode,
                                        items: _classes
                                            .map((classCode) => DropdownMenuItem(
                                            value: classCode, child: Text(classCode)))
                                            .toList(),
                                        onChanged: _onClassChanged,
                                        hint: const Text("Select Class"),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_allStudents.isEmpty)
                                    const Text("No students found.")
                                  else
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _allStudents.length,
                                        separatorBuilder: (context, index) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final stud = _allStudents[index];
                                          final studentName = stud['name'] ?? 'Unnamed Student';
                                          return InkWell(
                                            onTap: () => _openStudentStats(stud),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    _getInitials(studentName),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      studentName,
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _sendReminder(studentName),
                                                  icon: const Icon(Icons.notifications, color: Colors.grey),
                                                  label: const Text(
                                                    "Remind",
                                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.grey[200],
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Right side: At-Risk (top), Star (bottom)
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16.0,
                              left: 8.0,
                              bottom: 16.0,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: _boxDecoration(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "At-Risk Students",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.info_outline, color: Colors.grey),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => const AlertDialog(
                                                    title: Text("At-Risk Info"),
                                                    content: Text(
                                                      "Shows students who may need extra support "
                                                          "due to overdue tasks or lack of progress.",
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: atRiskStudents.isEmpty
                                              ? const Center(
                                            child: Text("No at-risk students."),
                                          )
                                              : ListView.builder(
                                            itemCount: atRiskStudents.length,
                                            itemBuilder: (context, idx) {
                                              final name = atRiskStudents[idx];
                                              return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: const Icon(Icons.warning, color: Colors.red),
                                                title: Text(name),
                                                onTap: () => _openStudentStats({
                                                  'id': 'atRisk_$name',
                                                  'name': name,
                                                }),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: _boxDecoration(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Star Students",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.info_outline, color: Colors.grey),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => const AlertDialog(
                                                    title: Text("Star Students Info"),
                                                    content: Text(
                                                      "Shows students demonstrating "
                                                          "exceptional performance or achievements.",
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: starStudents.isEmpty
                                              ? const Center(
                                            child: Text("No star students."),
                                          )
                                              : ListView.builder(
                                            itemCount: starStudents.length,
                                            itemBuilder: (context, idx) {
                                              final name = starStudents[idx];
                                              return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: const Icon(Icons.star, color: Colors.orange),
                                                title: Text(name),
                                                onTap: () => _openStudentStats({
                                                  'id': 'star_$name',
                                                  'name': name,
                                                }),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disables default back navigation
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            // Original portrait code
            return _buildPortraitLayout();
          } else {
            // New landscape code
            return _buildLandscapeLayout();
          }
        },
      ),
    );
  }
}

// New widget: AssignStoryPopup – a pop-up form for assigning a story to a specific student.
class AssignStoryPopup extends StatefulWidget {
  final String studentName;
  const AssignStoryPopup({Key? key, required this.studentName}) : super(key: key);

  @override
  _AssignStoryPopupState createState() => _AssignStoryPopupState();
}

class _AssignStoryPopupState extends State<AssignStoryPopup> {
  final TextEditingController _assignmentNameController = TextEditingController();
  int? _selectedLevel;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _visibleNow = false;
  DateTime? _scheduledVisibilityDate;

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickScheduledVisibilityDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledVisibilityDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _scheduledVisibilityDate = picked;
      });
    }
  }

  void _showLevelInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Level System Info"),
        content: const Text(
          "Levels range from 1 to 7 and determine the threshold students must reach before the assignment is considered complete.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Assign Story for ${widget.studentName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Assignment Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _assignmentNameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter assignment name",
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Level",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showLevelInfo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              value: _selectedLevel,
              items: List.generate(7, (index) => index + 1).map((level) {
                return DropdownMenuItem<int>(
                  value: level,
                  child: Text(level.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value;
                });
              },
              hint: const Text("Select level"),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Select Due Date",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: _startDate != null
                              ? _startDate!.toLocal().toString().split(' ')[0]
                              : "Start Date",
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDueDate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: _dueDate != null
                              ? _dueDate!.toLocal().toString().split(' ')[0]
                              : "Due Date",
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Visibility",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _visibleNow,
                  onChanged: (value) {
                    setState(() {
                      _visibleNow = value ?? false;
                    });
                  },
                ),
                const Text("Visible Now"),
                const Spacer(),
                GestureDetector(
                  onTap: _pickScheduledVisibilityDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      _scheduledVisibilityDate != null
                          ? "Schedule: ${_scheduledVisibilityDate!.toLocal().toString().split(' ')[0]}"
                          : "Schedule Visibility",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implement assignment submission logic.
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524686),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Assign"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShadows {
  static List<BoxShadow> universalShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 5,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      )
    ];
  }
}
