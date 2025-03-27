import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yourstory/student_dashboard.dart';
import 'package:yourstory/main.dart';

class AddChildrenDetailsScreen extends StatefulWidget {
  const AddChildrenDetailsScreen({Key? key}) : super(key: key);

  @override
  _AddChildrenDetailsScreenState createState() =>
      _AddChildrenDetailsScreenState();
}

class _AddChildrenDetailsScreenState extends State<AddChildrenDetailsScreen> {
  final PageController _controller = PageController(
    keepPage: true,
  );

  int _currentStep = 0;
  String _selectedGenderStr = "male";

  // 8 total pages (0..7)
  final List<String> questions = [
    'Welcome!', // 0
    'What is your child\'s name?', // 1
    'Is your child a boy or a girl?', // 2
    'What year was your child born in?', // 3
    'What type of stories does your child like?', // 4
    'Choose Your Child’s Avatar', // 5
    'Choose Your Child’s Theme', // 6
    'You\'re all set!', // 7
  ];

  final List<String> questionDescriptions = [
    'We’re excited to guide your child’s reading journey!\nAll details remain private and help us personalize stories.',
    'We’ll use your child’s name in story titles and dialogues for a personal touch.',
    'Selecting a gender helps us show relevant avatars and pronouns.',
    'If “2014 or older,” we’ll mark them as 11+ for story complexity.',
    'Examples: Fairy tales, silly adventures—helps shape the style of stories.',
    'Pick an avatar that matches your child. You can change it later in Edit Profile.',
    'More themes coming soon! They shape story environments. You can also change them later.',
    'Get ready to step into your own world filled with adventures',
  ];

  final List<TextEditingController> _controllers =
  List.generate(7, (_) => TextEditingController());

  int? _selectedGender;
  late List<int> years;
  int? _selectedYear;

  final List<String> maleAvatars = [
    'assets/male_avatar_1.png',
    'assets/male_avatar_2.png',
    'assets/male_avatar_3.png',
    'assets/male_avatar_4.png',
  ];
  final List<String> femaleAvatars = [
    'assets/female_avatar_1.png',
    'assets/female_avatar_2.jpg',
    'assets/female_avatar_3.jpg',
    'assets/female_avatar_4.jpg',
  ];
  String? _selectedAvatar;

  final List<String> themeImages = [
    'assets/smiling.png',
    'assets/planet.png',
    'assets/fantasy.png',
  ];
  final List<String> themeLabels = ["Animals", "Space", "Fantasy"];
  final List<String> themeInfos = [
    "Stories revolve around friendly creatures, pets, or safari adventures.",
    "Stories explore space journeys, planets, and cosmic wonders.",
    "Stories unfold in a magical realm with fantastical creatures.",
  ];
  int? _selectedThemeIndex;

  final int currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Generate years from currentYear down to 12 years older
    years = List.generate(12, (i) => currentYear - i);
    // Rebuild if child's name changes (affects question 4 text)
    _controllers[1].addListener(() => setState(() {}));
  }

  bool _isNextButtonEnabled() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _controllers[1].text.trim().isNotEmpty;
      case 2:
        return _selectedGender != null;
      case 3:
        return true;
      case 4:
        return _controllers[4].text.trim().isNotEmpty;
      case 5:
        return _selectedAvatar != null;
      case 6:
        return _selectedThemeIndex != null;
      default:
        return true;
    }
  }

  // -----------
  // A helper to produce the top label text:
  //  - Step 0 => "Welcome"
  //  - Step 7 => "Complete"
  //  - Otherwise => "Question X of 8"
  // -----------
  String _buildTopLabel() {
    if (_currentStep == 0) return 'Welcome';              // "Welcome"
    if (_currentStep == questions.length - 1) return 'Complete'; // "Complete"
    // Otherwise, use "Question X of 8"
    return 'Question ${_currentStep + 1} of ${questions.length}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            // ---------------- PORTRAIT (unchanged) ----------------
            return Column(
              children: [
                _buildHeaderPortrait(),
                const SizedBox(height: 40),
                Expanded(
                  child: _buildQuestionsPageView(),
                ),
              ],
            );
          } else {
            // ---------------- LANDSCAPE (modified) ----------------
            return Row(
              children: [
                // Left bar (pink w/ logo)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFFFF3355),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: MediaQuery.of(context).size.height * 0.3,
                        height: MediaQuery.of(context).size.height * 0.3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Right side: top header + page content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderLandscape(),
                      // Center + ConstrainedBox keeps content narrower & centered
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _buildQuestionsPageView(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ==============================================================
  // The main PageView with 8 steps
  // ==============================================================
  Widget _buildQuestionsPageView() {
    return PageView.builder(
      key: const PageStorageKey('AddChildrenPageView'),
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      onPageChanged: (index) => setState(() => _currentStep = index),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildWelcomePage();
          case 1:
          // "Question 2" => user wants more top space in landscape
            return _buildTextQuestion(index);
          case 2:
            return _buildGenderSelectionSnippet();
          case 3:
          // "Question 4": make everything smaller in landscape
            return _buildYearSelection();
          case 4:
          // "Question 5": more top space in landscape
            return _buildTextQuestion(index, isStoryNameStep: true);
          case 5:
          // "Question 6": smaller in landscape + not too low
            return _buildAvatarSelection();
          case 6:
            return _buildThemeSelection();
          case 7:
            return _buildAllSetPage();
          default:
            return Container();
        }
      },
    );
  }

  // ==============================================================
  // HEADER - PORTRAIT
  // ==============================================================
  Widget _buildHeaderPortrait() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3355),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: AppShadows.universalShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using _buildTopLabel()
          Text(
            _buildTopLabel(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildProgressBar(),
        ],
      ),
    );
  }

  // ==============================================================
  // HEADER - LANDSCAPE (slightly bigger text + bar)
  // ==============================================================
  Widget _buildHeaderLandscape() {
    return Padding(
      // Extra top padding to push it down
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
      child: Column(
        children: [
          Text(
            _buildTopLabel(), // "Welcome", "Complete", or "Question X of 8"
            style: const TextStyle(
              fontSize: 26, // bigger
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressBar(isLandscape: true),
        ],
      ),
    );
  }

  // ==============================================================
  // PROGRESS BAR
  // ==============================================================
  Widget _buildProgressBar({bool isLandscape = false}) {
    final double barHeight = isLandscape ? 30 : 20;
    final double barWidth = isLandscape ? 350 : 300;

    return Container(
      height: barHeight,
      width: barWidth,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.universalShadow(),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: (_currentStep + 1) / questions.length,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // WELCOME PAGE (step 0)
  // ==============================================================
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 180,
            height: 180,
          ),
          const SizedBox(height: 30),
          Text(
            questions[0], // "Welcome!"
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            questionDescriptions[0],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ==============================================================
  // TEXT QUESTION (steps 1 & 4)
  // * Adds extra top space in landscape for question 2 & 5
  // ==============================================================
  Widget _buildTextQuestion(int index, {bool isStoryNameStep = false}) {
    String questionText = questions[index];
    if (isStoryNameStep) {
      final name = _controllers[1].text.trim();
      if (name.isNotEmpty) {
        questionText = "What type of stories does $name like?";
      }
    }

    // Extra top padding for question #2 (index=1) & #5 (index=4) in landscape
    double topPadding = 20.0;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape && (index == 1 || index == 4)) {
      topPadding = 80.0; // Increase spacing from progress bar
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),
      child: Column(
        children: [
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            questionDescriptions[index],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppShadows.universalShadow(),
            ),
            child: TextField(
              controller: _controllers[index],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintText: 'Enter answer here',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ==============================================================
  // GENDER SELECTION (step 2)
  // ==============================================================
  Widget _buildGenderSelectionSnippet() {
    final String childName = _controllers[1].text.trim().isNotEmpty
        ? _controllers[1].text.trim()
        : "your child";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            "Is $childName a boy or a girl?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: AppShadowsLight.universalShadow(),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            questionDescriptions[2],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [0, 1].map((value) {
              final bool isSelected = (value == _selectedGender);
              final List<String> genderImages = [
                'assets/male_icon.jpeg',
                'assets/female_icon.jpeg',
              ];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedGender = value;
                  _selectedGenderStr = (value == 0) ? "male" : "female";
                }),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : Border.all(color: Colors.grey[300]!, width: 1),
                          boxShadow: AppShadows.universalShadow(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            genderImages[value],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (value == 0) ? "Boy" : "Girl",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: (value == 0) ? Colors.blue : Colors.pink,
                        shadows: AppShadowsLight.universalShadow(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ==============================================================
  // BIRTH YEAR (step 3) => "Question 4"
  // * In landscape, scale down slightly so buttons are higher
  // ==============================================================
  Widget _buildYearSelection() {
    final String childName = _controllers[1].text.trim().isNotEmpty
        ? _controllers[1].text.trim()
        : "your child";

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final scaleFactor = isLandscape ? 0.9 : 1.0;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Transform.scale(
                scale: scaleFactor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "What year was $childName born in?",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        questionDescriptions[3],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.3,
                        children: years.map((year) {
                          final bool isSelected = (year == _selectedYear);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedYear = year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : Border.all(color: Colors.grey[300]!, width: 1),
                                boxShadow: AppShadows.universalShadow(),
                              ),
                              child: Center(
                                child: Text(
                                  "$year",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(() => _selectedYear = null),
                        child: const Text(
                          '2014 or older',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildNavigationButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // AVATAR (step 5) => "Question 6"
  // * In landscape, scale it down so it likely fits on 11" without scrolling
  // ==============================================================
  Widget _buildAvatarSelection() {
    final bool isBoy = (_selectedGender == 0);
    final avatarList = isBoy ? maleAvatars : femaleAvatars;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final scaleFactor = isLandscape ? 0.9 : 1.0;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Transform.scale(
                scale: scaleFactor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        questions[5],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        questionDescriptions[5],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: avatarList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 columns
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemBuilder: (context, index) {
                          final avatarPath = avatarList[index];
                          final bool isSelected = (avatarPath == _selectedAvatar);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = avatarPath),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : Border.all(color: Colors.grey[300]!, width: 1),
                                boxShadow: AppShadows.universalShadow(),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.asset(
                                  avatarPath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildNavigationButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // THEME (step 6)
  // ==============================================================
  Widget _buildThemeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            questions[6],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            questionDescriptions[6],
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: themeImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, i) {
              final bool isSelected = (i == _selectedThemeIndex);
              return GestureDetector(
                onTap: () => setState(() => _selectedThemeIndex = i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: AppShadows.universalShadow(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            themeImages[i],
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              themeLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(themeLabels[i]),
                                    content: Text(themeInfos[i]),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ==============================================================
  // ALL SET PAGE (step 7)
  // ==============================================================
  Widget _buildAllSetPage() {
    return GestureDetector(
      onTap: _saveDataAndNavigate,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 240,
                height: 240,
              ),
              const SizedBox(height: 20),
              Text(
                questions[7], // "You're all set!"
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Tap anywhere to continue",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // NAVIGATION BUTTONS
  // ==============================================================
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_currentStep > 0)
          _buildButton("Back", Colors.grey, () {
            _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }),
        const SizedBox(width: 20),
        _buildButton(
          "Next",
          _isNextButtonEnabled()
              ? Colors.blue
              : Colors.blue.withOpacity(0.5),
              () {
            FocusScope.of(context).unfocus(); // close keyboard if open

            if (!_isNextButtonEnabled()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in the required information.'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (_currentStep == questions.length - 1) {
              _saveDataAndNavigate();
            } else {
              _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  // ==============================================================
  // SAVE DATA => NAVIGATE
  // ==============================================================
  Future<void> _saveDataAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Convert chosen year to either an age or "11+"
    String childAge;
    if (_selectedYear == null) {
      childAge = '11+';
    } else {
      childAge = (currentYear - _selectedYear!).toString();
    }

    final String childName = _controllers[1].text.trim();
    final String storiesLike = _controllers[4].text.trim();

    final newChildData = {
      'name': childName,
      'gender': _selectedGenderStr,
      'age': childAge,
      'likes_stories': storiesLike,
      'selectedAvatar': _selectedAvatar,
      'theme': (_selectedThemeIndex != null)
          ? themeLabels[_selectedThemeIndex!]
          : null,
    };

    try {
      final docRef =
      FirebaseFirestore.instance.collection('parents').doc(user.uid);

      final docSnapshot = await docRef.get();
      Map<String, dynamic> parentData = {};
      Map<String, dynamic> children = {};

      if (docSnapshot.exists) {
        parentData = docSnapshot.data() as Map<String, dynamic>;
        children = parentData['children'] ?? {};
      }

      int nextChildIndex = children.keys.length + 1;
      String nextChildKey = 'child_$nextChildIndex';

      children[nextChildKey] = newChildData;

      await docRef.set({
        'email': user.email,
        'children': children,
        'role' : 'parent'
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child details added successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboard(
            childId: nextChildKey,
            childName: childName.isNotEmpty ? childName : "Your Child",
            childImage: (_selectedAvatar != null && _selectedAvatar!.isNotEmpty)
                ? _selectedAvatar!
                : 'assets/profile.png',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }
}
