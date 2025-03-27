import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yourstory/student_dashboard.dart';

class StoryCompletionPage extends StatefulWidget {
  final String childId;
  final String childName;
  final String childImage;
  final double imageSize;

  // Constructor for passing data from the previous screen
  const StoryCompletionPage({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childImage,
    this.imageSize = 200.0, // Default image size
  }) : super(key: key);

  @override
  _StoryCompletionPageState createState() => _StoryCompletionPageState();
}

class _StoryCompletionPageState extends State<StoryCompletionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final Stopwatch _stopwatch = Stopwatch();


  @override
  void initState() {
    super.initState();
    _saveStoryCompletion();
  }


  Future<void> _saveStoryCompletion() async {
    try {
      print("Starting _saveStoryCompletion...");
      print("Child ID: ${widget.childId}");
      print("User ID: $userId");

      // Reference to the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      print("Fetching parent document...");
      // Fetch the parent document
      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        print("Parent document exists. Proceeding...");

        // Fetch children map
        Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
        print("Children data: $childrenMap");

        // Check if the childId exists in the children map (in your case, it should be 'child_1', 'child_2', etc.)
        String childKey = widget.childId; // Format the childId to match the Firebase key
        if (childrenMap.containsKey(childKey)) {
          Map<String, dynamic> childData = childrenMap[childKey];
          List<dynamic> completedStoryList = childData['completed_story'] ?? [];

          // Get current count of completed stories
          print("Fetching completed stories...");
          int completedStoriesCount = completedStoryList.length;
          print("Fetched completed stories. Count: $completedStoriesCount");

          int practiceNumber = completedStoriesCount + 1;
          String practiceKey = 'practice_$practiceNumber';
          print("Generated practice number: $practiceNumber");
          print("Generated practice key: $practiceKey");

          String completedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          print("Generated completed date: $completedDate");

          // Calculate time spent (in seconds) using the stopwatch
          int timeSpentInSeconds = _stopwatch.elapsed.inSeconds;
          print("Time spent: $timeSpentInSeconds seconds");

          // Create the new completed story with time spent
          Map<String, dynamic> newStory = {
            'name': practiceKey,
            'completed_date': completedDate,
            'time_spent': timeSpentInSeconds, // Save the time spent
          };

          // Append the new story to the completed_story array
          completedStoryList.add(newStory);

          await parentRef.update({
            'children.$childKey.completed_story': completedStoryList,
          });

          print("Story completion saved successfully as $practiceKey with time spent: $timeSpentInSeconds seconds");
        } else {
          print("Child data not found for childId: $childKey");
          print("Available child IDs: ${childrenMap.keys}");
        }
      } else {
        print("Parent document does not exist.");
      }
    } catch (e) {
      print("Error saving story completion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect orientation
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      // Show bottom nav only in LANDSCAPE
      bottomNavigationBar:
      (orientation == Orientation.landscape) ? _buildLandscapeBottomNav(context) : null,

      body: Stack(
        children: [
          // 1) Background color
          Container(color: const Color(0xFF55B399)),

          // 2) A giant white oval that exceeds screen size
          Positioned.fill(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.height * 1.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    // Large elliptical corners to produce a huge oval
                    Radius.elliptical(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3) Tap anywhere => go to StudentDashboard
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDashboard(
                    childId: widget.childId,
                    childName: widget.childName,
                    childImage: widget.childImage,
                  ),
                ),
              );
            },
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The checkmark image
                    SizedBox(
                      width: widget.imageSize,
                      height: widget.imageSize,
                      child: Image.asset(
                        'assets/check_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // STORY COMPLETE text
                    Text(
                      "STORY COMPLETE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'LuckiestGuy',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // LANDSCAPE BOTTOM NAV (taken from the code above with big icons)
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
              // Left Icon: Favorite
              GestureDetector(
                onTap: () => _onItemTapped(context, 0),
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
              // Middle Icon (logo)
              GestureDetector(
                onTap: () => _onItemTapped(context, 1),
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
              // Right Icon: Bar Chart
              GestureDetector(
                onTap: () => _onItemTapped(context, 2),
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

  // -----------------------------------------------------------------
  // NAVIGATION TAPS
  // -----------------------------------------------------------------
  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Placeholder()));
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
            context, MaterialPageRoute(builder: (context) => const Placeholder()));
        break;
    }
  }
}
