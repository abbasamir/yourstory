import 'dart:async';
//import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourstory/story_selection.dart';
import 'package:yourstory/student_dashboard.dart';
import 'example_story.dart';
import 'dart:typed_data';

class StoryGeneratorScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String childImage;

  const StoryGeneratorScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childImage,
  }) : super(key: key);

  @override
  _StoryGeneratorScreenState createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  bool _isLoading = false;
  String _story = "Click 'Practice' to generate a story. \n \nThis mode doesn't send your results to the teacher .";
  String _theme = 'space adventure';
  int _difficulty = 300;
  int _selectedIndex = 1;
  final Color _purpleColor = const Color(0xFF524686);

  @override
  void initState() {
    super.initState();
    _fetchThemeFromFirebase();
    _fetchDifficultyFromFirebase();
  }

  Future<void> _fetchDifficultyFromFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
            _difficulty = (childData['difficulty'] as num?)?.toInt() ??
                300; // Ensure it's an int
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching difficulty: $e');
      setState(() {
        _difficulty = 300; // Default if error occurs
      });
    }
  }

  Future<void> _fetchThemeFromFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
            _theme = childData['theme'] ?? 'space adventure';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching theme: $e');
      setState(() {
        _story = "Error fetching theme. Using default.";
      });
    }
  }

  Future<void> _generateStory() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Making request to generate story, questions, and images...');

      // Step 1: Generate story and initial questions from the first API
      final storyResponse = await http
          .post(
        Uri.parse(
            'https://abdalraheemdmd-story-image-api.hf.space/generate_story_questions_images'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'theme': _theme,
          'reading_level': 'beginner', // Set reading level
        }),
      )
          .timeout(const Duration(seconds: 90));

      if (storyResponse.statusCode == 200) {
        final data = jsonDecode(storyResponse.body);
        debugPrint('Full API Response: $data');

        // Ensure 'story' is handled correctly, use default if null

        String fullStory = data['story'] ?? "No story generated.";
        fullStory = fullStory.replaceAll('"', ''); // Remove all double quotes
        fullStory = fullStory.replaceAll(RegExp(r'[0-9]'), ''); // Remove all numbers

        int colonIndex = fullStory.indexOf(":");
        if (colonIndex != -1 && colonIndex + 1 < fullStory.length) {
          fullStory = fullStory.substring(colonIndex + 1).trim();
        }




        // Ensure questions are properly handled
        List<Map<String, dynamic>> questions = [];
        if (data['questions'] is List) {
          // If the questions are already in a valid List format
          questions = (data['questions'] as List).map((item) {
            return {
              'question': item['question'] ?? 'No question provided',
              'options': List<String>.from(item['options'] ?? []),
              'correct_answer': item['correct_answer'] ??
                  'No correct answer provided',
            };
          }).toList();
        } else if (data['questions'] is String) {
          // If the questions are in raw text format, process it
          String rawData = data['questions'];
          List<String> questionBlocks = rawData.split('\n\n');

          // Process each question block
          for (String block in questionBlocks) {
            List<String> lines = block.split('\n');
            if (lines.length < 5) continue; // Skip invalid blocks

            // Extract the question (the first line)
            String question = lines[0].trim();

            // Extract options (the next 4 lines)
            List<String> options = [];
            for (int i = 1; i <= 4; i++) {
              options.add(lines[i].trim());
            }

            // Extract the correct answer (usually the last line)
            String correctAnswer = lines.length > 5
                ? lines[5].replaceFirst('Correct Answer: ', '').trim()
                : 'No correct answer provided';

            // Save the question, options, and correct answer
            questions.add({
              'question': question,
              'options': options,
              'correct_answer': correctAnswer,
            });
          }

          debugPrint('Parsed Questions: $questions');
        }

        // Step 2: Modify questions based on difficulty using the Groq API
        // Set a difficulty level here (between 1 and 700)
        String grokApiKey = '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';
        final groqResponse = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          // Replace with your Groq API URL
          headers: {
            'Authorization': 'Bearer $grokApiKey',
            // Replace with your Groq API key
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama-3.3-70b-versatile",
            // Specify the model you want to use
            "messages": [
              {
                "role": "system",
                "content":
                "Adjust the difficulty of the following question to level $_difficulty (1-700). Return output strictly in this format:\nQuestion: <text>\nA) <option 1>\nB) <option 2>\nC) <option 3>\nD) <option 4>\nCorrect Answer: <A/B/C/D>"
              },
              {
                "role": "user",
                "content":
                "Question: ${questions[0]['question']}\nOptions: ${questions[0]['options']
                    .join(
                    ', ')}\nCorrect Answer: ${questions[0]['correct_answer']}"
              }
            ],
            "temperature": 0.6,
          }),
        );

        if (groqResponse.statusCode == 200) {
          final groqData = jsonDecode(groqResponse.body);
          debugPrint('Groq API Response: $groqData');

          // Update questions with the modified data
          if (groqData['modified_questions'] is List) {
            questions = (groqData['modified_questions'] as List).map((item) {
              return {
                'question': item['question'] ?? 'No question provided',
                'options': List<String>.from(item['options'] ?? []),
                'correct_answer': item['correct_answer'] ??
                    'No correct answer provided',
              };
            }).toList();
          }
        } else {
          _showError("Failed to modify questions. Try again later.");
        }

        List<String> base64Images = [];
        if (data['images'] is List) {
          base64Images =
          List<String>.from(data['images'].map((img) => img.toString()));
        }

        debugPrint("Received ${base64Images.length} images for decoding.");

        List<Image> images = [];
        String? imageUrl; // Make sure imageUrl is not null

// Decode base64 images safely
        for (int i = 0; i < base64Images.length; i++) {
          try {
            Uint8List decodedBytes = base64Decode(base64Images[i]);
            images.add(Image.memory(decodedBytes));
            debugPrint(
                "✅ Decoded image ${i + 1} successfully. Size: ${decodedBytes
                    .length} bytes.");
          } catch (e) {
            debugPrint("❌ Error decoding image ${i + 1}: $e");
          }
        }

        // If fewer than 50 images, cycle through available images
        if (images.isNotEmpty && images.length < 35) {
          debugPrint("Only ${images
              .length} images available. Recycling to fill 50 slots.");
          int initialLength = images.length;

          if (initialLength == 0) {
            debugPrint(
                "🚨 Error: images list is empty, cannot cycle through it.");
          } else {
            for (int i = 0; images.length < 35; i++) {
              images.add(images[i % initialLength]);
              debugPrint(
                  "🔄 Reused image ${i % initialLength} to fill slot ${images
                      .length}.");
            }
          }
        } else {
          debugPrint("✅ Images list is already 35.");
        }

        setState(() {
          _story = fullStory;
        });

        if (_story.isEmpty) {
          _showError("Story is empty. Try again later.");
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StoryPage(
                  childId: widget.childId,
                  childName: widget.childName,
                  childImage: widget.childImage,
                  title: _theme,
                  storyContent: _story,
                  questions: questions,
                  storyImages: images,
                  animationPath: 'assets/space_animation.gif',
                ),
          ),
        );
      } else {
        _showError("Failed to generate story. Try again later.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _story = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
      //stay on same page
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentDashboard(
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
          MaterialPageRoute(builder: (_) =>
              StorySelectionPage(childName: widget.childName,
                  childId: widget.childId,
                  childImage: widget.childImage)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery
        .of(context)
        .orientation;

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
        children: [
          _appbar(),
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

  Widget _appbar() {
    return WillPopScope(
      onWillPop: () async => !_isLoading, // Prevent back button when loading
      child: Scaffold(
        body: Stack(
          children: [
            AbsorbPointer( // This disables all interactions when loading
              absorbing: _isLoading,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _story,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10), // Reduce height from 20 to 10

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      // Moves it up slightly
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40,
                              vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isLoading ? null : _generateStory,
                        child: const Center(
                          child: Text(
                            "Practice",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Center vertically
                  children: [
                    Image.asset(
                      'assets/logo_loading.gif',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 20), // Space between image and text
                    const Text(
                      "Loading your story! \nThis can take about 30 seconds!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // PORTRAIT APP BAR (same as original)
  // -----------------------------------------------------------------
  PreferredSizeWidget _buildPortraitAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
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
                    'Practice Page',
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
            color: _isLoading ? Colors.grey : _purpleColor,
            // Grey out when loading
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
          child: AbsorbPointer( // Disables interactions when loading
            absorbing: _isLoading,
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
                        color: _isLoading ? Colors.grey[600] : Colors.pink, // Grey when loading
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
                          _isLoading ? 'assets/greyed_logo.png' : 'assets/logo.png',
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
                        color: _isLoading ? Colors.grey[600] : Colors.orange, // Grey when loading
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
        ),
      ],
    );
  }

// Landscape Bottom Nav
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
            color: _isLoading ? Colors.grey : _purpleColor,
            // Grey out when loading
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
          child: AbsorbPointer( // Disables interactions when loading
            absorbing: _isLoading,
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
                        color: _isLoading ? Colors.grey[600] : Colors.pink, // Grey when loading
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
                      width: 120,
                      height: 120,
                      child: Center(
                        child: Image.asset(
                          _isLoading ? 'assets/greyed_logo.png' : 'assets/logo.png',
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
                        color: _isLoading ? Colors.grey[600] : Colors.orange, // Grey when loading
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
        ),
      ],
    );
  }
}