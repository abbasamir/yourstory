import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:yourstory/story_generation_screen.dart';
import 'package:yourstory/story_selection.dart';
import 'package:yourstory/student_dashboard.dart';
import 'edit_profile.dart';
import 'coming_soon.dart';
import 'questions_page.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryPage extends StatefulWidget {
  final String childId;
  final String childName;
  final String childImage;
  final String title;
  final String storyContent;
  final List<Map<String, dynamic>> questions;
  final List<Image> storyImages;
  final String animationPath;

  const StoryPage({
    Key? key,
    required this.title,
    required this.storyContent,
    required this.animationPath,
    required this.childId,
    required this.childName,
    required this.childImage,
    required this.questions,
    required this.storyImages,
  }) : super(key: key);

  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final Stopwatch _stopwatch = Stopwatch();

  late List<String> _pageContents;
  late List<Image> _pageImages;
  int _currentPageIndex = 0;
  late String _fullStory;
  double _narrationSpeed = 0.5; // Default speed
  String userId = FirebaseAuth.instance.currentUser?.uid ?? ""; // Replace with actual user ID fetching logic

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setPitch(1.0);
    _fetchNarrationSpeed(); // Fetch speed from Firebase

    // Split the story content into pages
    _pageContents =
        widget.storyContent.split('.').map((e) => e.trim()).toList();
    _fullStory = widget.storyContent;

    // Assign images
    _pageImages = widget.storyImages.isNotEmpty
        ? widget.storyImages
        : List.generate(_pageContents.length, (index) =>
        Image.asset('assets/default_image.jpg'));

    _speakCurrentChunk();
  }

  // Fetch narration speed from Firebase
  void _fetchNarrationSpeed() async {
    try {
      print("Fetching narration speed from Firestore for user: $userId");

      // Reference to the child's document in Firestore
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      // Fetch document snapshot
      final snapshot = await parentRef.get();

      if (snapshot.exists) {
        print("Firestore document found for user: $userId");
        final data = snapshot.data();

        if (data != null && data.containsKey('children')) {
          print("Children data found in Firestore");

          // Get the narration speed from the specific child
          if (data['children'][widget.childId] != null &&
              data['children'][widget.childId]['narration_speed'] != null) {
            double fetchedSpeed = (data['children'][widget.childId]['narration_speed'] as num).toDouble();
            print("Fetched narration speed: $fetchedSpeed");

            setState(() {
              _narrationSpeed = fetchedSpeed.clamp(0.1, 1.0); // Clamp between 0.1 and 1.0
            });

            // Apply the fetched speed to TTS
            await _flutterTts.setSpeechRate(_narrationSpeed);
            print("Narration speed set to: $_narrationSpeed");
          } else {
            print("Narration speed not found in Firestore, using default 0.5");
          }
        } else {
          print("No children data found in Firestore, using default 0.5");
        }
      } else {
        print("No Firestore document found for user: $userId");
      }
    } catch (e) {
      print("Error fetching narration speed: $e");
    }
  }


  @override
  void dispose() {
    super.dispose();
    _stopwatch.stop(); // Stop the stopwatch when the page is disposed
  }

  // TTS for the current page's text
  Future<void> _speakCurrentChunk() async {
    if (_pageContents.isNotEmpty) {
      await _flutterTts.speak(_pageContents[_currentPageIndex]);
    }
  }

  // Move forward one page
  void _handleNext() {
    if (_currentPageIndex < _pageContents.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
      _speakCurrentChunk();
    } else {
      // Last page => go to questions
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>
            QuestionsPage(
              childId: widget.childId,
              childName: widget.childName,
              childImage: widget.childImage,
              questions: widget.questions,)),
      );
    }
  }

  // Move back one page
  void _handleBack() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
      _speakCurrentChunk();
    }
  }

  // Handle bottom nav
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>
            StoryGeneratorScreen(childName: widget.childName,
                childId: widget.childId,
                childImage: widget.childImage)),
      );
    } else if (index == 1) {
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
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>
            StorySelectionPage(childName: widget.childName,
                childId: widget.childId,
                childImage: widget.childImage)),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    // Check orientation
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      // ─────────────────────────────────────────────────────
      // Use orientation-based bottom nav
      // ─────────────────────────────────────────────────────
      bottomNavigationBar: orientation == Orientation.portrait
          ? _buildPortraitBottomNav(context)
          : _buildLandscapeBottomNav(context),

      // ─────────────────────────────────────────────────────
      // BODY
      // ─────────────────────────────────────────────────────
      body: Column(
        children: [
          // Top portion for the image
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  // negative velocity => swipe left => next
                  if (details.primaryVelocity! < 0) {
                    _handleNext();
                  }
                  // positive velocity => swipe right => back
                  else if (details.primaryVelocity! > 0) {
                    _handleBack();
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 8),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _pageImages.isNotEmpty
                    ?
                  _pageImages[_currentPageIndex]
                    : const SizedBox(),
              ),
            ),
          ),

          // Bottom portion with text
          Container(
            height: 180,
            color: Colors.white,
            child: Stack(
              children: [
                // Bookmark & page number
                Positioned(
                  top: 10,
                  left: 20,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark,
                        color: Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentPageIndex + 1}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // The story text itself
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _pageContents.isNotEmpty
                        ? Text(
                      _pageContents[_currentPageIndex],
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    )
                        : const SizedBox(),
                  ),
                ),
                // No next/back buttons: we rely on swipes
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Portrait bottom nav (original stacked version)
  // ─────────────────────────────────────────────────────────
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
              // Left Icon
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
              // Middle Icon (logo)
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
              // Right Icon
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

  // ─────────────────────────────────────────────────────────
  // Landscape bottom nav (bigger icons)
  // ─────────────────────────────────────────────────────────
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
}
