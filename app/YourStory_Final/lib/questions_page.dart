import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yourstory/story_completion.dart';
import 'package:yourstory/story_generation_screen.dart';
import 'package:yourstory/story_selection.dart';
import 'package:yourstory/student_dashboard.dart';
import 'coming_soon.dart';

class QuestionsPage extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String childId;
  final String childName;
  final String childImage;

  const QuestionsPage({Key? key, required this.questions, required this.childId, required this.childName, required this.childImage}) : super(key: key);


  @override
  _QuestionsPageState createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  // Example data (simulate Firebase)
  late List<Map<String, dynamic>> _questionsData;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerCorrect = false;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _questionsData = widget.questions;
  }

  @override
  Widget build(BuildContext context) {

    if (_questionsData.isEmpty) {
      return Scaffold(
        body: Center(child: Text("No questions available.")),
      );
    }
    // Detect orientation
    final orientation = MediaQuery.of(context).orientation;

    final currentQ = _questionsData[_currentQuestionIndex];
    final questionText = currentQ['question'] as String? ?? 'No question available';
    final answers = List<String>.from(currentQ['options'] ?? []);
    final correctAnswer = currentQ['correct_answer'] as String? ?? '';

    return Scaffold(
      // -------------------------------------------------------------------
      // Show the landscape bottom nav ONLY in landscape, hide in portrait
      // -------------------------------------------------------------------
      bottomNavigationBar:
      (orientation == Orientation.landscape) ? _buildLandscapeBottomNav() : null,

      // -------------------------------------------------------------------
      // BODY
      // -------------------------------------------------------------------
      body: Stack(
        children: [
          // 1) Blue background
          Container(color: const Color(0xFF37BCF4)),

          // 2) White shape:
          //    - Portrait: big oval that bleeds off the screen edges.
          //    - Landscape: giant circle centered and partially off-screen.
          if (orientation == Orientation.portrait)
          // PORTRAIT: position a large oval that extends beyond the screen
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.height * 1.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(600),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            )
          else
          // LANDSCAPE: large circle centered, so it looks cropped around edges
            Center(
              child: Container(
                width: 1000, // big circle
                height: 1000,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
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

          // 3) Main content: instructions, question, answers, etc.
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 110, // space for bottom controls
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Instructions
                  Text(
                    "CHECK THE CORRECT WORD\nTO COMPLETE EACH QUESTION BELOW",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                      fontFamily: 'LuckiestGuy',
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: const Offset(1, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),

                  // QUESTION TEXT
                  Center(
                    child: Text(
                      questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'LuckiestGuy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ANSWERS
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          MaterialColor boxColor;
                          switch (index) {
                            case 0:
                              boxColor = Colors.amber;
                              break;
                            case 1:
                              boxColor = Colors.orange;
                              break;
                            default:
                              boxColor = Colors.green;
                              break;
                          }

                          final isSelected = (_selectedAnswerIndex == index);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _selectAnswer(index, correctAnswer),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: boxColor,
                                        width: 4,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? Icon(
                                      Icons.check,
                                      color: boxColor,
                                      size: 32,
                                    )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  answers[index],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: boxColor[900] ?? boxColor,
                                    fontFamily: 'LuckiestGuy',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40), // Space between rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          MaterialColor boxColor;
                          switch (index + 2) {
                            case 2:
                              boxColor = Colors.green;
                              break;
                            default:
                              boxColor = Colors.blue;
                              break;
                          }

                          final isSelected = (_selectedAnswerIndex == index + 2);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _selectAnswer(index + 2, correctAnswer),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: boxColor,
                                        width: 4,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? Icon(
                                      Icons.check,
                                      color: boxColor,
                                      size: 32,
                                    )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  answers[index + 2],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: boxColor[900] ?? boxColor,
                                    fontFamily: 'LuckiestGuy',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 70),

                  // BACK & NEXT BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _goToPreviousQuestion,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple.shade700,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LuckiestGuy',
                          ),
                        ),
                        child: const Text("BACK"),
                      ),
                      const SizedBox(width: 50),
                      TextButton(
                        onPressed: (_selectedAnswerIndex == null)
                            ? null
                            : _goToNextQuestion,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple.shade700,
                          disabledForegroundColor: Colors.grey.shade400,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LuckiestGuy',
                          ),
                        ),
                        child: Text(
                          (_currentQuestionIndex < _questionsData.length - 1)
                              ? "NEXT"
                              : "DONE",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // LANDSCAPE BOTTOM NAV
  // ------------------------------------------------------------------------
  Widget _buildLandscapeBottomNav() {
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
              // Middle Icon (logo)
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

  // ------------------------------------------------------------------------
  // EVENT HANDLERS
  // ------------------------------------------------------------------------

  //MMR Score calculation algorithm
  void _selectAnswer(int index, String correctAnswer) {
    setState(() {
      _selectedAnswerIndex = index;
      String selectedAnswer = _questionsData[_currentQuestionIndex]['options'][index];
      String selectedAnswerFirstLetter = selectedAnswer.isNotEmpty ? selectedAnswer[0] : '';

      print("Selected option: $selectedAnswerFirstLetter");
      print("Correct option: $correctAnswer");

      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      bool isCorrect = (selectedAnswerFirstLetter == correctAnswer);
      int S = isCorrect ? 1 : 0;  // Score (1 for correct, 0 for incorrect)
      int K = 32;  // Adjustment speed factor

      parentRef.get().then((parentDoc) async {
        if (parentDoc.exists) {
          Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
          String childKey = widget.childId;

          if (childrenMap.containsKey(childKey)) {
            int correctAnswers = childrenMap[childKey]['correct_answers'] ?? 0;
            int wrongAnswers = childrenMap[childKey]['wrong_answers'] ?? 0;
            int oldMMR = childrenMap[childKey]['difficulty'] ?? 200;  // Default MMR starts at 200

            // Define a baseline average MMR for expected success probability
            int baselineMMR = 350; // Mid-level average MMR for estimating difficulty

            // Expected success probability using child's MMR vs baseline
            double E = 1 / (1 + pow(10, (baselineMMR - oldMMR) / 400));

            // New MMR calculation
            double newMMR = oldMMR + K * (S - E);

            // Clamp MMR to 0-700 range
            newMMR = newMMR.clamp(0, 700);

            // Increment correct/wrong answers
            if (isCorrect) {
              correctAnswers++;
            } else {
              wrongAnswers++;
            }

            // Update Firestore
            await parentRef.update({
              'children.$childKey.correct_answers': correctAnswers,
              'children.$childKey.wrong_answers': wrongAnswers,
              'children.$childKey.difficulty': newMMR.round(),  // Save rounded MMR
            });

            print("Updated MMR for $childKey: ${newMMR.round()}");
            print("Updated correct answers: $correctAnswers, wrong answers: $wrongAnswers");
          } else {
            print("Child $childKey not found in children map");
          }
        } else {
          print("Parent document does not exist for user ID: $userId");
        }
      }).catchError((e) {
        print("Error fetching or updating data: $e");
      });

      _isAnswerCorrect = isCorrect;
    });
  }





  void _goToPreviousQuestion() {
    if (_currentQuestionIndex == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _currentQuestionIndex--;
      _selectedAnswerIndex = null;
    });
  }

  void _goToNextQuestion() {
    if (_selectedAnswerIndex == null) return;
    if (_currentQuestionIndex < _questionsData.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
      });
    } else {
      // Reached final question => proceed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryCompletionPage(
            childId: widget.childId,
            childName: widget.childName,
            childImage: widget.childImage,
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoryGeneratorScreen(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
      );
    } else if (index == 1) {
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
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StorySelectionPage(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
      );
    }
  }
}
