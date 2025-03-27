import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Replace with your actual pages
import 'package:yourstory/start.dart';
import 'package:yourstory/coming_soon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yourstory/stories_page_teachers.dart';
import 'package:yourstory/students_page_teachers.dart';
import 'main.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  // Existing state variables
  String? profileImageUrl;
  String? _selectedClassCode;
  List<String> _classes = [];
  String? teacherName;
  String? classCode;
  int _numStudents = 0;
  List<Map<String, dynamic>> assignedTasks = [];

  // Visualization data
  Map<String, dynamic> s3Data = {};
  List<Map<String, dynamic>> storyCompletionData = [];
  List<String> storyTitles = [];
  Map<String, double> storyGrades = {};
  List<String> atRiskStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
    fetchAssignedTasks();
    fetchS3Data();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String email = user.email ?? '';
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      setState(() {
        teacherName = data['teacher_name']?.toString() ?? 'Teacher Name';
        profileImageUrl = data['profileImageUrl']?.toString() ?? '';
        final code = data['class_code']?.toString();
        _classes = code != null ? [code] : [];
        _selectedClassCode = code ?? '';
      });
    } catch (e, stacktrace) {
      print("ERROR: $e\n$stacktrace");
    }
  }


  Future<void> fetchNumberOfStudents() async {
    if (classCode == null || classCode!.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('class_code', isEqualTo: classCode)
          .get();
      setState(() {
        _numStudents = snapshot.size;
      });
    } catch (e) {
      print('Error fetching number of students: $e');
    }
  }

  Future<void> fetchAssignedTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final tasksSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('teacherId', isEqualTo: user.uid)
            .get();

        setState(() {
          assignedTasks = tasksSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching assigned tasks: $e');
    }
  }

  Future<void> fetchS3Data() async {
    try {
      final urlInfo = Uri.parse(
          'https://graduation-project-bucket-s3.s3.eu-north-1.amazonaws.com/user_info.json');
      final urlActivity = Uri.parse(
          'https://graduation-project-bucket-s3.s3.eu-north-1.amazonaws.com/user_activity.json');

      final responseInfo = await http.get(urlInfo);
      final responseActivity = await http.get(urlActivity);

      if (responseInfo.statusCode == 200 && responseActivity.statusCode == 200) {
        final userInfo = json.decode(responseInfo.body);
        final userActivity = json.decode(responseActivity.body);

        setState(() {
          s3Data['user_info'] = userInfo;
          s3Data['user_activity'] = userActivity;
        });

        processStoryCompletionData(userInfo, userActivity);
        processStudentStatisticsData(userInfo, userActivity);
        processAtRiskStudentsData(userInfo, userActivity);
      } else {
        print('Failed to fetch data from S3');
      }
    } catch (e) {
      print('Error fetching S3 data: $e');
    }
  }

  // Process Story Completion
  void processStoryCompletionData(List userInfo, List userActivity) {
    List<Map<String, dynamic>> completionData = [];
    Map<String, double> storyCompletionMap = {};

    for (var activity in userActivity) {
      if (activity['interaction_type'] == 'story_reading') {
        var storyTitle = activity['story_title'];
        var compRaw = activity['completion_percentage'];
        double completion =
        (compRaw is int) ? compRaw.toDouble()
            : (compRaw is double) ? compRaw
            : 0.0;

        storyCompletionMap[storyTitle] = completion;
      }
    }

    storyCompletionMap.forEach((storyTitle, completion) {
      completionData.add({
        'story_title': storyTitle,
        'completion_rate': completion,
      });
    });

    setState(() {
      storyCompletionData = completionData;
    });
  }

  // Process Student Stats
  void processStudentStatisticsData(List userInfo, List userActivity) {
    Map<String, List<int>> storyScores = {};

    for (var activity in userActivity) {
      if (activity['interaction_type'] == 'quiz_attempt' &&
          activity['score'] != null) {
        String storyTitle = activity['story_title'];
        int score = activity['score'];
        if (!storyScores.containsKey(storyTitle)) {
          storyScores[storyTitle] = [];
        }
        storyScores[storyTitle]!.add(score);
      }
    }

    Map<String, double> newGrades = {};
    storyScores.forEach((title, scores) {
      double average = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
      newGrades[title] = average;
      if (!storyTitles.contains(title)) {
        storyTitles.add(title);
      }
    });

    setState(() {
      storyGrades = newGrades;
    });
  }

  // Process At-Risk
  void processAtRiskStudentsData(List userInfoData, List userActivityData) {
    List<String> atRiskList = [];

    for (var activity in userActivityData) {
      if (activity['interaction_type'] == 'quiz_attempt' &&
          activity['score'] != null &&
          activity['score'] < 50) {
        final student = userInfoData.firstWhere(
              (user) => user['email'] == activity['email'],
          orElse: () => null,
        );
        if (student != null) {
          atRiskList.add(student['student_name']);
        }
      }
    }

    setState(() {
      atRiskStudents = atRiskList;
    });
  }

  // Logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StartPage()),
    );
  }

  void _navigateToComingSoon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComingSoonPage()),
    );
  }

  void _navigateToTeacherDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherDashboard()),
    );
  }

  void _navigateToStudentsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentsPageTeachers()),
    );
  }

  void _navigateToStoryCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryCreationPage()),
    );
  }

  // Generate Story Buttons
  Widget _buildGenerateStoryButtonPortrait() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToStoryCreation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF524686),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          "Generate Story",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGenerateStoryButtonLandscape() {
    return ElevatedButton(
      onPressed: _navigateToStoryCreation,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF524686),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "Generate Story",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        // --------------------------
        // PORTRAIT MODE
        // --------------------------
        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
            drawer: _buildDrawer(),
            body: RefreshIndicator(
              onRefresh: () async {
                await _fetchTeacherData();
                await fetchAssignedTasks();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildBannerPortrait(),
                        const SizedBox(height: 20),
                        _buildStudentStatistics(),
                        const SizedBox(height: 20),
                        _buildStoryCompletionGraph(),
                        const SizedBox(height: 20),
                        _buildAssignedStoriesBlock(),
                        const SizedBox(height: 20),
                        _buildAtRiskStudents(),
                        const SizedBox(height: 20),
                        _buildGenerateStoryButtonPortrait(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // --------------------------
        // LANDSCAPE MODE
        // --------------------------
        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  // Permanent sidebar
                  Container(
                    width: 180,
                    color: const Color(0xFF524686),
                    child: _buildDrawerContent(),
                  ),
                  // Main content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _fetchTeacherData();
                        await fetchAssignedTasks();
                      },
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Row 1: Banner
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      // Add a maxHeight to keep banner from being too tall
                                      constraints: const BoxConstraints(maxHeight: 140),
                                      child: _buildBannerLandscape(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Row 2: 3 columns => stats, story comp, assigned
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      child: _buildStudentStatistics(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      child: _buildStoryCompletionGraph(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildAssignedStoriesBlock(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Row 3: [ spacer, at-risk, generate story button ]
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // left spacer
                                  const Spacer(flex: 1),

                                  // at-risk in the middle
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      child: _buildAtRiskStudents(),
                                    ),
                                  ),

                                  // generate story on the right
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: _buildGenerateStoryButtonLandscape(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
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
    });
  }

  // ======================
  // DRAWER
  // ======================
  Widget _buildDrawer() {
    return Container(
      width: 180,
      color: const Color(0xFF524686),
      child: SafeArea(
        child: _buildDrawerContent(),
      ),
    );
  }

  Widget _buildDrawerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            'assets/logo.png',
            width: 120,
            fit: BoxFit.contain,
          ),
        ),
        _buildDrawerItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
          //Stay on same page
          },
        ),
        _buildDrawerItem(
          icon: Icons.people,
          label: 'Students',
          onTap: _navigateToStudentsPage,
        ),
        _buildDrawerItem(
          icon: Icons.settings,
          label: 'Settings',
          onTap: _navigateToComingSoon,
        ),
        _buildDrawerItem(
          icon: Icons.book,
          label: 'Stories',
          onTap: _navigateToStoryCreation,
        ),
        const Spacer(),
        // Sign out
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextButton.icon(
            onPressed: _logout,
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
    );
  }

  Widget _buildDrawerItem({
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

  // ======================
  // BANNER - Portrait
  // ======================
  Widget _buildBannerPortrait() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF524686),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
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
              ],
            ),
          ),
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
    );
  }

  // ======================
  // BANNER - Landscape
  // ======================
  Widget _buildBannerLandscape() {
    // Smaller maximum height (140), smaller text so it doesn't overflow
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF524686),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
      ),
      child: Row(
        children: [
          // Left text
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slightly smaller text from previous
                Text(
                  "Welcome back, ${teacherName ?? 'Teacher'}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You have 27 new student(s) in your domain.\n"
                      "Please reach out to the Head Teacher if you want them excluded\n"
                      "from your domain.",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          // Right image
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
    );
  }

  // ======================
  // STUDENT STATISTICS
  // ======================
  Widget _buildStudentStatistics() {
    if (storyGrades.isEmpty) {
      return const Center();
    }

    final barChartData = storyGrades.entries.map((entry) {
      return BarChartGroupData(
        x: storyTitles.indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: const Color(0xFF524686),
            width: 14,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Statistic',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: barChartData,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < storyTitles.length) {
                          return Text(
                            storyTitles[index],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // STORY COMPLETION
  // ======================
  Widget _buildStoryCompletionGraph() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Story completion Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          storyCompletionData.isNotEmpty
              ? Column(
            children: storyCompletionData.map<Widget>((data) {
              var storyTitle = data['story_title'] ?? 'Untitled Story';
              var completionRate = data['completion_rate'] ?? 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows1.universalShadow(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        storyTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: completionRate / 100,
                            strokeWidth: 8,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF524686),
                            ),
                          ),
                          Text(
                            '${completionRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
              : const Center(
            child: Text('No story completion data available.'),
          ),
        ],
      ),
    );
  }

  // ======================
  // ASSIGNED STORIES
  // ======================
  Widget _buildAssignedStoriesBlock() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Assigned stories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _navigateToComingSoon,
                child: const Text(
                  "See all",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          assignedTasks.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignedTasks.length,
            itemBuilder: (context, index) {
              final task = assignedTasks[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task['title'] ?? 'Untitled Task'),
                subtitle: Text(
                  'Deadline: ${task['deadline'] ?? 'N/A'}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // navigate if needed
                },
              );
            },
          )
              : const Center(
            child: Text('No assigned stories yet.'),
          ),
        ],
      ),
    );
  }

  // ======================
  // AT-RISK STUDENTS
  // ======================
  Widget _buildAtRiskStudents() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows1.universalShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'At risk students',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _navigateToComingSoon,
                child: const Text(
                  "See all",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          atRiskStudents.isEmpty
              ? const Text('No at-risk students identified.')
              : Column(
            children: atRiskStudents.map((student) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        student,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToComingSoon,
                      child: const Text(
                        'send reminder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Simple shadows for consistency
class AppShadows1 {
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
