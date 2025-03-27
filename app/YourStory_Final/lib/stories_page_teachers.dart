import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourstory/start.dart';
import 'package:yourstory/coming_soon.dart';
import 'package:yourstory/success_screen.dart';
import 'package:yourstory/teacher_dashboard.dart'; // Teacher Dashboard page.
import 'package:yourstory/students_page_teachers.dart'; // Correct story selection path.
import 'package:yourstory/story_generation_screen.dart';
import 'package:intl/intl.dart';

import 'main.dart';


void main() {
  runApp(MaterialApp(
    home: StoryCreationPage(),
    debugShowCheckedModeBanner: false,
  ));
}



/// Extracted Banner widget (matches your original _buildBanner())
class BannerWidget extends StatelessWidget {
  final String? teacherName;
  final int numStudents;

  const BannerWidget({
    Key? key,
    this.teacherName,
    required this.numStudents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0), // Same as original.
      decoration: BoxDecoration(
        color: const Color(0xFF524686), // new purple.
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadowsLight.universalShadow(),
      ),
      child: Row(
        children: [
          // Left side: text.
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
                Text(
                  "Create new assignements for students.",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right side: image stack.
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/classroom2.png', // background image.
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                Image.asset(
                  'assets/students.png', // foreground image.
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted Drawer widget (replicates your original _buildDrawer())
class AppDrawer extends StatelessWidget {
  final VoidCallback onNavigateToTeacherDashboard;
  final VoidCallback onNavigateToStudentsPage;
  final VoidCallback onNavigateToComingSoon;

  const AppDrawer({
    Key? key,
    required this.onNavigateToTeacherDashboard,
    required this.onNavigateToStudentsPage,
    required this.onNavigateToComingSoon,
  }) : super(key: key);

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      color: const Color(0xFF524686),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/logo.png',
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home,
              label: 'Home',
              onTap: onNavigateToTeacherDashboard,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.people,
              label: 'Students',
              onTap: onNavigateToStudentsPage,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.book,
              label: 'Stories',
              onTap: () {
                // Already on Stories page; simply close the drawer.
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: onNavigateToComingSoon,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut().then(
                      (_) => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => StartPage()),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// AssignmentFormWidget – first main widget for creating assignments.
class AssignmentFormWidget extends StatefulWidget {
  const AssignmentFormWidget({Key? key}) : super(key: key);

  @override
  _AssignmentFormWidgetState createState() => _AssignmentFormWidgetState();
}

class _AssignmentFormWidgetState extends State<AssignmentFormWidget> {
  final TextEditingController _assignmentNameController = TextEditingController();
  int? _selectedLevel;
  String _searchCategory = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedSuggestions = [];
  // Dummy suggestions for testing.
  List<String> _suggestions = [ ];

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
  Future<List<String>> fetchClasses() async {
    try {
      List<String> _classes = [];
      print("Starting to fetch classes...");

      // Get the reference to the Firestore 'class' collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('class').get();

      print("Classes fetched, total documents: ${snapshot.docs.length}");

      // Loop through each document in the collection
      for (var doc in snapshot.docs) {
        print("Processing document with ID: ${doc.id}");

        // Fetch class_code and assigned_teacher from each document
        var classCode = doc['class_code']; // class_code may be an int, so handle it accordingly
        String classCodeString = classCode.toString(); // Convert classCode to string if it's an int
        String assignedTeacher = doc['assigned_teacher'].toString(); // Ensure assigned_teacher is a string

        print("Class Code: $classCodeString, Assigned Teacher: $assignedTeacher");

        // You can store class_code in the _classes list
        _classes.add(classCodeString);

        // Optionally, you can print or store additional information
        print('Added class: $classCodeString to the list');
      }

      // Final debugging print for the list of classes
      print("Final list of classes: $_classes");

      return _classes; // Return the list of fetched classes

    } catch (e) {
      print('Error fetching classes: $e');
      return []; // Return an empty list in case of an error
    }
  }





  void _fetchStudentNames() {
    FirebaseFirestore.instance.collection('parents').snapshots().listen((snapshot) {
      List<String> studentNames = [];

      print("Fetching student names...");

      for (var parentDoc in snapshot.docs) {
        print("Parent Document ID: ${parentDoc.id}");
        Map<String, dynamic>? parentData = parentDoc.data();

        if (parentData != null && parentData.containsKey('children')) {
          var children = parentData['children'];

          if (children is Map<String, dynamic>) {
            children.forEach((key, value) {
              print("Checking child key: $key");

              if (key.startsWith('child_') &&
                  value is Map<String, dynamic> &&
                  value.containsKey('name')) {
                print("Found student: ${value['name']}");
                studentNames.add(value['name']);
              }
            });
          } else {
            print("children is not a Map<String, dynamic>: $children");
          }
        } else {
          print("No children found in this document.");
        }
      }

      print("Final student list: $studentNames");

      setState(() {
        _suggestions = studentNames;
      });
    }, onError: (error) {
      print("Error fetching students: $error");
    });
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

  // Filter suggestions based on the search query.
  List<String> get _filteredSuggestions {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _suggestions;
    return _suggestions.where((s) => s.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (Headline and description removed from inside the box)
            // Assignment Name.
            const Text("Assignment Name", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _assignmentNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter assignment name",
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            // Select Level with info icon above the dropdown.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Level", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showLevelInfo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
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
            // "To who are you sharing" section.
            const Text("To who are you sharing", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-width Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Search recipients",
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (query) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),

                // Toggle Buttons below the search bar
                Center(
                  child: ToggleButtons(
                    isSelected: [
                      _searchCategory == 'Students',
                      _searchCategory == 'Class'
                    ],
                    onPressed: (index) {
                      setState(() {
                        _searchCategory = index == 0 ? 'Students' : 'Class';
                        if (_searchCategory == 'Students') {
                          _fetchStudentNames();
                        } else if (_searchCategory == 'Class') {
                          fetchClasses();
                        }

                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 38),
                        child: Text("Students"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 38),
                        child: Text("Class"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Display filtered suggestions as selectable chips.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredSuggestions.map((suggestion) {
                final isSelected = _selectedSuggestions.contains(suggestion);
                return ChoiceChip(
                  label: Text(suggestion),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSuggestions.add(suggestion);
                      } else {
                        _selectedSuggestions.remove(suggestion);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Due Date selection: Start Date & Due Date.
            const Text("Select Due Date", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: _startDate != null ? _startDate!.toLocal().toString().split(' ')[0] : "Start Date",
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
                          border: OutlineInputBorder(),
                          hintText: _dueDate != null ? _dueDate!.toLocal().toString().split(' ')[0] : "Due Date",
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
            // Visibility section: Checkbox and Scheduled visibility.
            const Text("Visibility", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                // Immediate visibility checkbox.
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
                // Scheduled visibility date picker.
                GestureDetector(
                  onTap: _pickScheduledVisibilityDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      _scheduledVisibilityDate != null
                          ? "Schedule: ${_scheduledVisibilityDate!.toLocal().toString().split(' ')[0]}"
                          : "Schedule Visibility",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10, // Set smaller font size
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Assign button.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Perform form validation
                  if (_assignmentNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter an assignment name")),
                    );
                    return;
                  }

                  if (_selectedLevel == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a level")),
                    );
                    return;
                  }

                  if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a start date")),
                    );
                    return;
                  }

                  if (_dueDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a due date")),
                    );
                    return;
                  }

                  if (_selectedSuggestions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select at least one recipient")),
                    );
                    return;
                  }

                  // If validation passes, proceed with the assignment creation
                  Map<String, dynamic> storyData = {
                    'name': _assignmentNameController.text.trim(),
                    'level': _selectedLevel,
                    'start_date': _startDate?.toIso8601String(),
                    'due_date': _dueDate?.toIso8601String(),
                    'visibility': _visibleNow,
                  };

                  try {
                    print("Collecting all parent documents from Firestore...");

                    // Fetch all parents' documents
                    QuerySnapshot parentSnapshot = await FirebaseFirestore.instance.collection('parents').get();

                    print("Fetched ${parentSnapshot.docs.length} parent documents");

                    // Get current user's email (assuming the current user is a teacher)
                    User? user = FirebaseAuth.instance.currentUser;
                    String teacherEmail = user?.email ?? '';

                    // Loop through each parent document
                    for (var parentDoc in parentSnapshot.docs) {
                      print("Processing parent document with ID: ${parentDoc.id}");

                      Map<String, dynamic>? parentData = parentDoc.data() as Map<String, dynamic>?;

                      // Check if 'children' exists in the parent document
                      if (parentData != null && parentData.containsKey('children')) {
                        Map<String, dynamic> children = parentData['children'];
                        print("Found ${children.keys.length} children for this parent");

                        // Loop through each selected child name
                        for (var childName in _selectedSuggestions) {
                          print("Checking if child $childName exists in parent's children map...");

                          // Check if the child exists in the 'children' map
                          if (children.containsKey(childName)) {
                            print("Child $childName found, updating story data...");

                            // Store the story data under the matched child
                            await FirebaseFirestore.instance.collection('parents')
                                .doc(parentDoc.id) // Use the parent document ID
                                .update({
                              'children.$childName.story': storyData, // Store under the corresponding child
                            });

                            print("Story data for $childName successfully updated.");
                          } else {
                            print("Child $childName does not exist in this parent's children map. Checking child_1...");

                            // If the child name doesn't match directly, check for child_1, child_2, etc.
                            for (var childKey in children.keys) {
                              if (children[childKey]['name'] == childName) {
                                print("Matching child found under $childKey, updating story data...");

                                // Store the story data under the matched child
                                await FirebaseFirestore.instance.collection('parents')
                                    .doc(parentDoc.id)
                                    .update({
                                  'children.$childKey.assigned_story': FieldValue.arrayUnion([storyData]), // Store storyData as an array under the corresponding child
                                });

                                print("Story data for $childName successfully updated under $childKey.");
                                break; // Exit the loop once the child is found and updated
                              }
                            }
                          }
                        }
                      } else {
                        print("No 'children' field found for parent with ID: ${parentDoc.id}");
                      }

                      // Check if the current parent's teacher matches the logged-in user's email
                      try {
                        // Get the current user's email (assuming you're using Firebase Auth)
                        String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

                        if (currentUserEmail.isNotEmpty) {
                          // Find the teacher document matching the current user's email
                          QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance.collection('parents')
                              .where('email', isEqualTo: currentUserEmail)
                              .get();

                          if (teacherSnapshot.docs.isNotEmpty) {
                            // Assume there is only one teacher with the current user's email
                            String teacherDocId = teacherSnapshot.docs.first.id;

                            // Add story data to the teacher's assigned_story array
                            await FirebaseFirestore.instance.collection('parents')
                                .doc(teacherDocId)
                                .update({
                              'assigned_story': FieldValue.arrayUnion([storyData]), // Add storyData to assigned_story array
                            });

                            print("Story data successfully added to teacher's assigned_story array.");
                          } else {
                            print("No teacher found with the current user's email.");
                          }
                        } else {
                          print("No current user email found.");
                        }
                      } catch (e) {
                        print("Error updating teacher's assigned story: $e");
                      }
                    }

                    print("Data update complete. Navigating to success screen...");

                    // After successful data storage, navigate to the success screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuccessScreen()),
                    );
                  } catch (e) {
                    // Handle any errors during the Firebase update
                    print("Error occurred during Firebase operation: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524686),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Assign"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// AssignmentHistoryWidget – second main widget showing previously assigned stories.

class AssignmentHistoryWidget extends StatefulWidget {
  const AssignmentHistoryWidget({Key? key}) : super(key: key);

  @override
  _AssignmentHistoryWidgetState createState() => _AssignmentHistoryWidgetState();
}

class _AssignmentHistoryWidgetState extends State<AssignmentHistoryWidget> {
  // List to hold the assignment history fetched from Firestore
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;  // Flag to show loading indicator
  String errorMessage = '';  // To display any error messages

  // Fetch data from Firestore
  Future<void> _fetchAssignmentHistory() async {
    try {
      setState(() {
        isLoading = true;  // Show loading indicator
        errorMessage = '';  // Clear previous error messages
      });

      print('Fetching assignment history from Firestore...');

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;

      final String email = user?.email ?? '';
      print("DEBUG: Logged-in user UID: ${user?.uid}, Email: $email");

      // Check if the user is logged in
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User is not logged in!';
        });
        return;
      }

      // Fetch data from the parents collection where the email matches the logged-in user
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('email', isEqualTo: email)
          .get();

      print('QuerySnapshot fetched: ${querySnapshot.size}');
      print('Current User UID: ${user?.uid}');

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs[0].data() as Map<String, dynamic>;

        // Debugging: Log the entire fetched data
        print('Fetched data: $data');

        // Check if the 'assigned_story' array exists
        if (data['assigned_story'] != null) {
          setState(() {
            history = List<Map<String, dynamic>>.from(data['assigned_story']);
          });

          // Debugging: Log the assigned stories list after fetching
          print('Assigned stories: $history');
        } else {
          setState(() {
            errorMessage = 'No assigned stories available.';
          });
          print('No "assigned_story" field found in the document.');
        }
      } else {
        setState(() {
          errorMessage = 'No document found for the given user ID.';
        });
        print('No document found with the given email.');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching assignment history: $e';
      });
      print('Error fetching assignment history: $e');
    } finally {
      setState(() {
        isLoading = false;  // Hide loading indicator
      });
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchAssignmentHistory();  // Fetch data when the widget is initialized
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Currently Assigned Story",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // If loading, show a loading indicator
            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            // If there is an error, show the error message
            if (errorMessage.isNotEmpty)
              Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // If data is available, show it
            if (!isLoading && errorMessage.isEmpty)
              history.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];

                  // Convert Firestore timestamp to DateTime and format it
                  String formatDateString(String dateString) {
                    DateTime date = DateTime.parse(dateString);  // Convert the string to DateTime
                    return DateFormat('dd-MM-yyyy').format(date);  // Format the DateTime object
                  }


                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Name: ${item["name"] ?? 'N/A'}"
                    ),
                    subtitle: Text(
                      "Level: ${item["level"] ?? 'N/A'}\n"
                          "Start: ${item["start_date"] != null ? formatDateString(item["start_date"]) : 'N/A'}\n"
                          "Due: ${item["due_date"] != null ? formatDateString(item["due_date"]) : 'N/A'}\n"
                          "Visibility: ${item["visibility"] ?? 'N/A'}",
                    )


                    ,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // navigate if needed
                    },
                  );
                },
              )
                  : const Center(child: Text('No assigned stories found.')),
          ],
        ),
      ),
    );
  }
}


/// StoryCreationPage combining BannerWidget, AppDrawer, the headline outside the box,
/// AssignmentFormWidget, and AssignmentHistoryWidget.
class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({Key? key}) : super(key: key);

  @override
  _StoryCreationPageState createState() => _StoryCreationPageState();
}

class _StoryCreationPageState extends State<StoryCreationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Teacher info (loaded from Firebase)
  String? teacherName;
  String? profileImageUrl;
  int _numStudents = 0;
  //List<String> _classes = ['1011', '1012'];
  List<String> _classes = [];
  String? _selectedClassCode;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        //print("DEBUG: No authenticated user found.");
        return;
      }

      final String email = user.email ?? '';
      //print("DEBUG: Logged-in user UID: ${user.uid}, Email: $email");

      // Query Firestore using email to fetch teacher data
      QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('email', isEqualTo: email)
          .get();

      if (teacherSnapshot.docs.isEmpty) {
        //print("DEBUG: No teacher document found for email: $email");
        return;
      }

      //print("DEBUG: Teacher document found!");
      var teacherData = teacherSnapshot.docs.first.data() as Map<String, dynamic>;

      //print("DEBUG: Teacher data retrieved: $teacherData");

      setState(() {
        teacherName = teacherData['teacher_name']?.toString() ?? 'Teacher Name';
        profileImageUrl = teacherData['profileImageUrl']?.toString() ?? '';
      });

      // Fetch teacher_code
      final String? teacherCode = teacherData['teacher_code']?.toString();
      if (teacherCode == null || teacherCode.isEmpty) {
        //print("DEBUG: No teacher_code found in teacher document.");
        return;
      }

      //print("DEBUG: Teacher Code: $teacherCode");

      // Query Firestore to find class documents matching this teacher_code
      QuerySnapshot classSnapshot = await FirebaseFirestore.instance
          .collection('class')
          .where('teacher_code', isEqualTo: int.tryParse(teacherCode) ?? teacherCode)
          .get();

      if (classSnapshot.docs.isEmpty) {
        //print("DEBUG: No classes found for teacher_code: $teacherCode");
        return;
      }

      // Extract class codes from matching documents
      List<String> classCodes = classSnapshot.docs
          .map((doc) => doc['class_code'].toString())
          .toList();

      setState(() {
        _classes = classCodes;
        _selectedClassCode = classCodes.isNotEmpty ? classCodes.first : '';
      });

      //print("DEBUG: Matched Classes: $_classes");
      //print("DEBUG: Selected Class Code: $_selectedClassCode");

      //await _fetchStudents();
    } catch (e, stacktrace) {
      //print("ERROR: Exception while fetching teacher data: $e");
      //print("STACKTRACE: $stacktrace");
    }
  }



  // Navigation functions (unchanged)
  void _navigateToTeacherDashboard() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
  }

  void _navigateToStudentsPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsPageTeachers()));
  }

  void _navigateToComingSoon() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComingSoonPage()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back-swipe.
      child: Scaffold(
        key: _scaffoldKey,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
        drawer: AppDrawer(
          onNavigateToTeacherDashboard: _navigateToTeacherDashboard,
          onNavigateToStudentsPage: _navigateToStudentsPage,
          onNavigateToComingSoon: _navigateToComingSoon,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), // Outer padding.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BannerWidget(
                  teacherName: teacherName,
                  numStudents: _numStudents,
                ),
                const SizedBox(height: 20),
                // Headline and description placed outside the assignment form box.
                const Text(
                  "Stories",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Assign stories to your students by setting an assignment name, level, recipients, and deadlines.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                const AssignmentFormWidget(),
                const AssignmentHistoryWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
