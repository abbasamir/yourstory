import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yourstory/edit_profile.dart';
import 'package:yourstory/login.dart';
import 'package:yourstory/story_selection.dart'; // Ensure this is imported!
import 'package:auto_size_text/auto_size_text.dart';
import 'story_generation_screen.dart';

/// Initialize Firebase and run the app.
void student_dashboard() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

/// Basic MyApp to run the app.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

/// The main StudentDashboard widget.
class StudentDashboard extends StatefulWidget {
  final String childId;
  final String childName;
  final dynamic childImage;

  const StudentDashboard({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childImage,
  }) : super(key: key);

  @override
  StudentDashboardState createState() => StudentDashboardState();
}

class StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 1; // Default index for Home
  bool hasClassCode = false;
  String? profileImageUrl = '';
  String selectedAvatar = 'assets/profile.png';
  String? reminderMessage = 'No Reminder to display!';
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Controllers for PageViews.
  // Controllers for PageViews.
  late final PageController _pageController;
  late final PageController _landscapePageController;
  late final PageController _middlePageController;

  // Cycle-through options for performance stats.
  //final List<String> _periodOptions = ['LAST STORY', 'THIS WEEK', 'LAST MONTH'];
  final List<String> _periodOptions = ['THIS WEEK', 'THIS MONTH'];


  int _periodIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _landscapePageController = PageController(viewportFraction: 0.95);
    _middlePageController = PageController(initialPage: 0, viewportFraction: 0.95);
    _fetchProfileImage();
    fetchClassCode();
    _fetchReminder();
    _fetchThisWeekCompletedStories();
    _fetchThisMonthCompletedStories();
    _fetchThisWeekTimeSpent();
    _fetchThisMonthTimeSpent();

  }

  @override
  void dispose() {
    _pageController.dispose();
    _landscapePageController.dispose();
    _middlePageController.dispose();
    super.dispose();
  }


  Future<String> _fetchCorrectAnswers() async {
    try {
      print("Fetching correct answers...");

      // Fetch the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user: $userId");

      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        print("Parent document found for user: $userId");

        // Get the children map from the parent document
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Children map: $childrenMap");

        String childKey = widget.childId; // Using widget.childId dynamically
        print("Fetching correct answers for child: $childKey");

        // Ensure the child exists in the children map
        if (childrenMap.containsKey(childKey)) {
          // Fetch the number of correct answers for the child
          int correctAnswers = childrenMap[childKey]['correct_answers'] ?? 0;
          print("Correct answers found for $childKey: $correctAnswers");

          // Return the correct answers as a string
          return correctAnswers.toString(); // Corrected to return String
        } else {
          // Child not found in the children map
          print("Child $childKey not found in the children map");
          return "Child not found";
        }
      } else {
        // Parent document does not exist
        print("Parent document does not exist for user: $userId");
        return "Parent document does not exist";
      }
    } catch (e) {
      // Handle any errors
      print("Error fetching correct answers: $e");
      return "Error fetching correct answers: $e";
    }
  }


  Future<String> _fetchWrongAnswers() async {
    try {
      print("Fetching wrong answers...");

      // Fetch the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user: $userId");

      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        print("Parent document found for user: $userId");

        // Get the children map from the parent document
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Children map: $childrenMap");

        String childKey = widget.childId; // Using widget.childId dynamically
        print("Fetching wrong answers for child: $childKey");

        // Ensure the child exists in the children map
        if (childrenMap.containsKey(childKey)) {
          // Fetch the number of wrong answers for the child
          int wrongAnswers = childrenMap[childKey]['wrong_answers'] ?? 0;
          print("Wrong answers found for $childKey: $wrongAnswers");

          // Return the wrong answers as a string
          return wrongAnswers.toString(); // Corrected to return String
        } else {
          // Child not found in the children map
          print("Child $childKey not found in the children map");
          return "Child not found";
        }
      } else {
        // Parent document does not exist
        print("Parent document does not exist for user: $userId");
        return "Parent document does not exist";
      }
    } catch (e) {
      // Handle any errors
      print("Error fetching wrong answers: $e");
      return "Error fetching wrong answers: $e";
    }
  }


  Future<String> _fetchThisMonthTimeSpent() async {
    try {
      print("Starting to fetch time spent...");

      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user ID: $userId");

      final parentDoc = await parentRef.get();
      print("Parent document fetched: ${parentDoc.exists ? 'Exists' : 'Does not exist'}");

      if (parentDoc.exists) {
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Fetched children map: $childrenMap");

        String childKey = '${widget.childId}';
        print("Generated child key: $childKey");

        if (childrenMap.containsKey(childKey)) {
          List<dynamic> completedStoryList = childrenMap[childKey]['completed_story'] ?? [];
          print("Fetched completed stories for child: ${completedStoryList.length} stories found");

          // Calculate total time spent in the past 30 days
          DateTime now = DateTime.now();
          DateTime oneMonthAgo = now.subtract(Duration(days: 30));
          print("Filtering time spent from the past 30 days (from: $oneMonthAgo to: $now)");

          int totalSeconds = completedStoryList.fold(0, (sum, story) {
            var completedDate = story['completed_date'];
            var timeSpent = story['time_spent'];

            if (completedDate is String && timeSpent is int) {
              try {
                DateTime storyDate = DateTime.parse(completedDate);
                print("Evaluating story with completed date: $storyDate and time spent: $timeSpent seconds");

                if (storyDate.isAfter(oneMonthAgo)) {
                  return sum + timeSpent;
                }
              } catch (e) {
                print("Error parsing completed_date: $completedDate");
              }
            } else {
              print("Invalid data types - completed_date: ${completedDate.runtimeType}, time_spent: ${timeSpent.runtimeType}");
            }
            return sum;
          });

          print("Total time spent in the past 30 days (seconds): $totalSeconds");

          // Convert seconds into hours and minutes
          int hours = totalSeconds ~/ 3600;
          int minutes = (totalSeconds % 3600) ~/ 60;
          print("Total time spent converted: ${hours}h ${minutes}m");

          return "  $hours HR $minutes MIN";
        } else {
          print("Child key $childKey not found in children map");
        }
      } else {
        print("Parent document does not exist for user ID: $userId");
      }
    } catch (e) {
      print("Error fetching time spent: $e");
    }

    return "0"; // Return default if no data found
  }




  Future<String> _fetchThisWeekTimeSpent() async {
    try {
      print("Starting to fetch time spent...");

      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user ID: $userId");

      final parentDoc = await parentRef.get();
      print("Parent document fetched: ${parentDoc.exists ? 'Exists' : 'Does not exist'}");

      if (parentDoc.exists) {
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Fetched children map: $childrenMap");

        String childKey = '${widget.childId}';
        print("Generated child key: $childKey");

        if (childrenMap.containsKey(childKey)) {
          List<dynamic> completedStoryList = childrenMap[childKey]['completed_story'] ?? [];
          print("Fetched completed stories for child: ${completedStoryList.length} stories found");

          // Calculate total time spent in the past week
          DateTime now = DateTime.now();
          DateTime oneWeekAgo = now.subtract(Duration(days: 7));
          print("Filtering time spent from the past week (from: $oneWeekAgo to: $now)");

          int totalSeconds = completedStoryList.fold(0, (sum, story) {
            var completedDate = story['completed_date'];
            var timeSpent = story['time_spent'];

            if (completedDate is String && timeSpent is int) {
              try {
                DateTime storyDate = DateTime.parse(completedDate);
                print("Evaluating story with completed date: $storyDate and time spent: $timeSpent seconds");

                if (storyDate.isAfter(oneWeekAgo)) {
                  return sum + timeSpent;
                }
              } catch (e) {
                print("Error parsing completed_date: $completedDate");
              }
            } else {
              print("Invalid data types - completed_date: ${completedDate.runtimeType}, time_spent: ${timeSpent.runtimeType}");
            }
            return sum;
          });

          print("Total time spent in the past week (seconds): $totalSeconds");

          // Convert seconds into hours and minutes
          int hours = totalSeconds ~/ 3600;
          int minutes = (totalSeconds % 3600) ~/ 60;
          print("Total time spent converted: ${hours}h ${minutes}m");

          return "  $hours HR $minutes MIN";
        } else {
          print("Child key $childKey not found in children map");
        }
      } else {
        print("Parent document does not exist for user ID: $userId");
      }
    } catch (e) {
      print("Error fetching time spent: $e");
    }

    return "0"; // Return default if no data found
  }

  Future<int> _fetchThisWeekCompletedStories() async {
    try {
      print("Starting to fetch completed stories...");

      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user ID: $userId");

      final parentDoc = await parentRef.get();
      print("Parent document fetched: ${parentDoc.exists ? 'Exists' : 'Does not exist'}");

      if (parentDoc.exists) {
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Fetched children map: $childrenMap");

        // Corrected child key generation: 'child_1' instead of 'child_child_1'
        String childKey = '${widget.childId}';
        // String childKey = 'child_${widget.childId}';

        print("Generated child key: $childKey");

        if (childrenMap.containsKey(childKey)) {
          List<dynamic> completedStoryList = childrenMap[childKey]['completed_story'] ?? [];
          print("Fetched completed stories for child: ${completedStoryList.length} stories found");

          // Filter stories completed in the past week
          DateTime now = DateTime.now();
          DateTime oneWeekAgo = now.subtract(Duration(days: 7));
          print("Filtering completed stories from the past week (from: $oneWeekAgo to: $now)");

          int count = completedStoryList.where((story) {
            var completedDate = story['completed_date'];

            // Check if completedDate is a valid string
            if (completedDate is String) {
              try {
                DateTime storyDate = DateTime.parse(completedDate); // Convert string to DateTime
                print("Evaluating story with completed date: $storyDate");

                return storyDate.isAfter(oneWeekAgo);
              } catch (e) {
                print("Error parsing completed_date string: $completedDate");
                return false; // If parsing fails, return false
              }
            } else {
              print("Invalid completed_date type: ${completedDate.runtimeType}");
              return false;
            }
          }).length;

          print("Count of completed stories in the past week: $count");

          return count; // Return the count of completed stories in the past week
        } else {
          print("Child key $childKey not found in children map");
        }
      } else {
        print("Parent document does not exist for user ID: $userId");
      }
    } catch (e) {
      print("Error fetching completed stories: $e");
    }

    return 0; // Return 0 if there is an issue or no data
  }

  Future<int> _fetchThisMonthCompletedStories() async {
    try {
      print("Starting to fetch completed stories...");

      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      print("Fetching parent document for user ID: $userId");

      final parentDoc = await parentRef.get();
      print("Parent document fetched: ${parentDoc.exists ? 'Exists' : 'Does not exist'}");

      if (parentDoc.exists) {
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Fetched children map: $childrenMap");

        // Corrected child key generation: 'child_1' instead of 'child_child_1'
        String childKey = '${widget.childId}';
        // String childKey = 'child_${widget.childId}';

        print("Generated child key: $childKey");

        if (childrenMap.containsKey(childKey)) {
          List<dynamic> completedStoryList = childrenMap[childKey]['completed_story'] ?? [];
          print("Fetched completed stories for child: ${completedStoryList.length} stories found");

          // Filter stories completed in the past week
          DateTime now = DateTime.now();
          DateTime oneWeekAgo = now.subtract(Duration(days: 30));
          print("Filtering completed stories from the past week (from: $oneWeekAgo to: $now)");

          int count = completedStoryList.where((story) {
            var completedDate = story['completed_date'];

            // Check if completedDate is a valid string
            if (completedDate is String) {
              try {
                DateTime storyDate = DateTime.parse(completedDate); // Convert string to DateTime
                print("Evaluating story with completed date: $storyDate");

                return storyDate.isAfter(oneWeekAgo);
              } catch (e) {
                print("Error parsing completed_date string: $completedDate");
                return false; // If parsing fails, return false
              }
            } else {
              print("Invalid completed_date type: ${completedDate.runtimeType}");
              return false;
            }
          }).length;

          print("Count of completed stories in the past week: $count");

          return count; // Return the count of completed stories in the past week
        } else {
          print("Child key $childKey not found in children map");
        }
      } else {
        print("Parent document does not exist for user ID: $userId");
      }
    } catch (e) {
      print("Error fetching completed stories: $e");
    }

    return 0; // Return 0 if there is an issue or no data
  }

  /// Fetch the child's selected avatar.
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
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  /// Check if the user has joined a class.
  Future<void> fetchClassCode() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot classDoc = await FirebaseFirestore.instance
            .collection('class')
            .doc(user.uid)
            .get();
        if (classDoc.exists && classDoc.data() != null) {
          final classData = classDoc.data() as Map<String, dynamic>;
          final classCode = classData['classCode'] as String?;
          if (classCode != null && classCode.isNotEmpty) {
            setState(() {
              hasClassCode = true;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching class code: $e');
    }
  }

  /// Fetch the reminder message.
  Future<void> _fetchReminder() async {
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
              reminderMessage = childData['reminder'] ?? 'No reminders yet';
            });
          } else {
            setState(() {
              reminderMessage = 'No matching child found';
            });
          }
        } else {
          setState(() {
            reminderMessage = 'Parent data not found';
          });
        }
      }
    } catch (e) {
      print('Error fetching reminder: $e');
      setState(() {
        reminderMessage = 'Error fetching reminder';
      });
    }
  }

  /// Handle bottom navigation taps.
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
      // Stay on this page.
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StorySelectionPage(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
        );
        break;
    }
  }

  /// Log out the user.
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  /// Cycle through the performance period options.
  void _handlePeriodTap() {
    setState(() {
      _periodIndex = (_periodIndex + 1) % _periodOptions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final double boxHeight = MediaQuery.of(context).size.height * 0.31;

    return Scaffold(
      appBar: orientation == Orientation.portrait
          ? _buildPortraitAppBar(context)
          : _buildLandscapeAppBar(context),

      body: orientation == Orientation.portrait
      // PORTRAIT BODY
          ? SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 60,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildPerformanceBox(context, boxHeight),
                const SizedBox(height: 20),
                _buildYourStoriesBox(context, boxHeight),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      )
      // LANDSCAPE BODY
          : Stack(
        children: [
          // White background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
          // Top-left image
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/top left.jpeg',
              width: 250,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          // Bottom-left image
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              'assets/bottom left.jpeg',
              width: 200,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          // Main Column with PageView
          Column(
            children: [
              const SizedBox(height: 50),
              Expanded(
                child: PageView(
                  controller: _middlePageController,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Page 1: Performance Box
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildPerformanceBox(context, boxHeight),
                      ],
                    ),
                    // Page 2: Your Stories Box
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildYourStoriesBox(context, boxHeight),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: orientation == Orientation.portrait
          ? _buildPortraitBottomNav(context)
          : _buildLandscapeBottomNav(context),
    );
  }

  // ───────────────────────────────────────────────────
  // APP BAR BUILDERS
  // ───────────────────────────────────────────────────
  PreferredSizeWidget _buildPortraitAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: const Color(0xFFFF7B4D),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reminder container
                Padding(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.04),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF55B399),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AutoSizeText(
                              "Reminder: $reminderMessage",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              minFontSize: 8,
                              maxFontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Avatar button
                Padding(
                  padding: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.046),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            childId: widget.childId,
                            childName: widget.childName,
                            childImage: widget.childImage,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: (profileImageUrl != null &&
                            profileImageUrl!.isNotEmpty)
                            ? Image.asset(
                          profileImageUrl!,
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          selectedAvatar,
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        ),
                      ),
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

  PreferredSizeWidget _buildLandscapeAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: AppBar(
        backgroundColor: const Color(0xFFFF7B4D),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left logo
                const Padding(
                  padding: EdgeInsets.only(left: 20.0),
                  child: Image(
                    image: AssetImage('assets/logo.png'),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                // Reminder bar
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF55B399),
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            "Reminder: $reminderMessage",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.35),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            minFontSize: 8,
                            maxFontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Child name and avatar
                Row(
                  children: [
                    if (widget.childName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Text(
                          widget.childName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(
                                childId: widget.childId,
                                childName: widget.childName,
                                childImage: widget.childImage,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: (profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty)
                                ? Image.asset(
                              profileImageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              selectedAvatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // BOTTOM NAVIGATION BUILDERS
  // ───────────────────────────────────────────────────
  Widget _buildPortraitBottomNav(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF524686),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
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
            color: const Color(0xFF524686),
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

  // ───────────────────────────────────────────────────
  // PERFORMANCE BOX
  // ───────────────────────────────────────────────────
  Widget _buildPerformanceBox(BuildContext context, double boxHeight) {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      // PORTRAIT
      final TextStyle headerTextStyle = TextStyle(
        fontFamily: 'LuckiestGuy',
        fontSize: 16,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      );
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: boxHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF55C92),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PERFORMANCE', style: headerTextStyle),
                  GestureDetector(
                    onTap: _handlePeriodTap,
                    child: Row(
                      children: [
                        Text(_periodOptions[_periodIndex],
                            style: headerTextStyle),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_right,
                          color: Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // PageView for stats pills.
              //THIS WEEK PILL
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(32)),
                  child: PageView(
                    controller: _pageController,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Page 1: Stats (Stories Completed & Reading Time)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FutureBuilder<int>(
                              future: _periodIndex == 0
                                  ? _fetchThisWeekCompletedStories()
                                  : _fetchThisMonthCompletedStories(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildPerfPill('STORIES COMPLETED', '...', 18);
                                } else if (snapshot.hasError) {
                                  return _buildPerfPill('STORIES COMPLETED', 'Error', 18);
                                } else {
                                  return _buildPerfPill(
                                    'STORIES COMPLETED',
                                    '${snapshot.data ?? 0}',
                                    18,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<String>(
                              future: _periodIndex == 0
                                  ? _fetchThisWeekTimeSpent()
                                  : _fetchThisMonthTimeSpent(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildPerfPill('READING TIME', 'Loading...', 16);
                                } else if (snapshot.hasError) {
                                  return _buildPerfPill('READING TIME', 'Error', 16);
                                } else {
                                  return _buildPerfPill('READING TIME', snapshot.data ?? '0 HR 0 MIN', 16);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Page 2: Stats (Correct Answers & Wrong Answers)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FutureBuilder<String>(
                              future: _fetchCorrectAnswers(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildPerfPill('CORRECT ANSWERS', 'Loading...', 16);
                                } else if (snapshot.hasError) {
                                  return _buildPerfPill('CORRECT ANSWERS', 'Error', 16);
                                } else {
                                  return _buildPerfPill('CORRECT ANSWERS', snapshot.data ?? '0', 16);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<String>(
                              future: _fetchWrongAnswers(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildPerfPill('WRONG ANSWERS', '...', 16);
                                } else if (snapshot.hasError) {
                                  return _buildPerfPill('WRONG ANSWERS', 'Error', 16);
                                } else {
                                  return _buildPerfPill('WRONG ANSWERS', snapshot.data ?? '0', 16);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // LANDSCAPE
      final double containerWidth = MediaQuery.of(context).size.width * 0.60;
      final double containerHeight = MediaQuery.of(context).size.height * 0.55;
      final double headerFontSize = 28;
      final double arrowIconSize = 32;
      final double pillFontSize = 36;

      return Center(
        child: Container(
          width: containerWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF55C92),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PERFORMANCE',
                    style: TextStyle(
                      fontFamily: 'LuckiestGuy',
                      fontSize: headerFontSize,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(2, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _handlePeriodTap,
                    child: Row(
                      children: [
                        Text(
                          _periodOptions[_periodIndex],
                          style: TextStyle(
                            fontFamily: 'LuckiestGuy',
                            fontSize: headerFontSize,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                offset: const Offset(2, 2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_right,
                          color: Colors.white,
                          size: arrowIconSize,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              offset: const Offset(2, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // PageView in landscape
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(32)),
                  child: PageView(
                    controller: _landscapePageController,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Page 1
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: containerWidth * 0.075),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPerfPill('STORIES COMPLETED', '1/3', pillFontSize),
                            const SizedBox(height: 24),
                            _buildPerfPill('TIME SPENT', '1HR 30M', pillFontSize),
                          ],
                        ),
                      ),
                      // Page 2
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: containerWidth * 0.075),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPerfPill('CORRECT ANSWERS', '2/5', pillFontSize),
                            const SizedBox(height: 24),
                            _buildPerfPill('TIME ACTIVE', '2HR 15M', pillFontSize),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPerfPill(
      String label,
      String value,
      double fontSize, {
        double pillVerticalPadding = 16,
        double pillHorizontalPadding = 20,
      }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: pillVerticalPadding,
          horizontal: pillHorizontalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'LuckiestGuy',
                fontSize: fontSize,
                color: const Color(0xFFF55C92),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'LuckiestGuy',
                fontSize: fontSize,
                color: const Color(0xFFF55C92),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // YOUR STORIES BOX
  // ───────────────────────────────────────────────────
  Widget _buildYourStoriesBox(BuildContext context, double boxHeight) {
    final orientation = MediaQuery.of(context).orientation;

    double containerWidth, containerHeight;
    if (orientation == Orientation.landscape) {
      containerWidth = MediaQuery.of(context).size.width * 0.60;
      containerHeight = MediaQuery.of(context).size.height * 0.55;
    } else {
      containerWidth = MediaQuery.of(context).size.width * 0.85;
      containerHeight = boxHeight;
    }

    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFFCCE33),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR STORIES',
              style: TextStyle(
                fontFamily: 'LuckiestGuy',
                fontSize: 20,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(2, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // LEFT BUTTON: Practice
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Go to practice
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StoryGeneratorScreen(childId: widget.childId, childName: widget.childName, childImage: widget.childImage,)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.white],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD2C7B8),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/practice button.jpeg',
                              fit: BoxFit.cover,
                              height: containerHeight * 0.4,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Practice',
                              style: TextStyle(
                                fontFamily: 'LuckiestGuy',
                                fontSize: 16,
                                color: Color(0xFFFF3355),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 10,
                    color: Colors.black26,
                  ),
                  // RIGHT BUTTON: Assignments
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // <--- CHANGED HERE: always go to StorySelectionPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StorySelectionPage(
                              childId: widget.childId,
                              childName: widget.childName,
                              childImage: widget.childImage,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.white],
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD2C7B8),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/assignments button.jpeg',
                              fit: BoxFit.cover,
                              height: containerHeight * 0.4,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Assignments',
                              style: TextStyle(
                                fontFamily: 'LuckiestGuy',
                                fontSize: 16,
                                color: Color(0xFF524686),
                              ),
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
        ),
      ),
    );
  }
}
