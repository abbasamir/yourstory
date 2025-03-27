import 'package:flutter/material.dart';

class AddChildrenDetailsScreen extends StatefulWidget {
  const AddChildrenDetailsScreen({Key? key}) : super(key: key);

    @override
    _AddChildrenDetailsScreenState createState() =>
    _AddChildrenDetailsScreenState();
}

class _AddChildrenDetailsScreenState extends State<AddChildrenDetailsScreen> {
    final _controller = PageController();
    int _currentStep = 0;

    final List<String> questions = [
            'What is your child\'s name?',
            'What year was your child born in?',
            'What are your child\'s favorite activities?',
            'Does your child like stories?',
            'What genre of stories does your child like?',
            'What is your child\'s favorite color?',
            'Does your child enjoy drawing?',
            'What is your child\'s favorite animal?',
            'Is your child a fan of cartoons?',
            'Choose Your Child’s Theme',
            ];

    final List<TextEditingController> _controllers =
            List.generate(10, (_) => TextEditingController());

    int? _selectedYear;
    final int currentYear = DateTime.now().year;
    List<int> years = [];
    int olderThanYear = 0;

    int? _selectedThemeIndex;
    final List<String> themeNames = ["Planet", "Smiling", "Fantasy"];
    final List<String> themeImages = [
            'assets/planet.png',
            'assets/smiling.png',
            'assets/fantasy.png',
            ];

    @override
    void initState() {
        super.initState();
        _initYearGrid();
    }

    void _initYearGrid() {
        years = List.generate(12, (i) => currentYear - i);
        olderThanYear = years.last - 1;
    }

    bool _isNextButtonEnabled() {
        if (_currentStep == 1) {
            return _selectedYear != null;
        } else if (_currentStep == 9) {
            return _selectedThemeIndex != null;
        } else {
            return _controllers[_currentStep].text.trim().isNotEmpty;
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
                body: Column(
                children: [
        _buildHeader(),
          const SizedBox(height: 20),
        Expanded(
                child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                setState(() {
                _currentStep = index;
                });
              },
        physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
            if (index == 1) {
                return _buildYearSelection();
            } else if (index == 9) {
                return _buildThemeSelection();
            } else {
                return _buildTextQuestion(index);
            }
        },
            ),
          ),
        ],
      ),
    );
    }

    Widget _buildHeader() {
        return Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                color: const Color(0xFFFF3355),
                borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
        ),
        boxShadow: [
        BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 4,
                blurRadius: 10,
                offset: const Offset(0, 3),
          ),
        ],
      ),
        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
        Text(
                'QUESTION ${_currentStep + 1} OF ${questions.length}',
                style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
        Container(
                height: 20,
                width: 300,
                decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
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
          ),
        ],
      ),
    );
    }

    Widget _buildYearSelection() {
        final String childName = _controllers[0].text.trim().isNotEmpty
                ? _controllers[0].text
                : "your child";

        return _buildSelectionUI(
                title: "What year was $childName born in?",
                items: years,
                selectedValue: _selectedYear,
                onSelect: (year) {
                setState(() {
                _selectedYear = year;
        });
      },
        additionalButtonText: "$olderThanYear or before",
                onAdditionalButtonPress: () {
            setState(() {
                _selectedYear = olderThanYear;
            });
        },
    );
    }

    Widget _buildThemeSelection() {
        return _buildSelectionUI(
                title: "Choose Your Child’s Theme",
                items: List.generate(themeImages.length, (index) => index),
        selectedValue: _selectedThemeIndex,
                onSelect: (index) {
                setState(() {
                _selectedThemeIndex = index;
        });
      },
        useImages: true,
    );
    }

    Widget _buildSelectionUI({
        required String title,
                required List<int> items,
        required int? selectedValue,
                required Function(int) onSelect,
                bool useImages = false,
                String? additionalButtonText,
                VoidCallback? onAdditionalButtonPress,
    }) {
        return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                children: [
        Text(
                title,
                style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
            ),
        textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2,
                children: items.map((value) {
        final isSelected = (selectedValue == value);
        return GestureDetector(
                onTap: () => onSelect(value),
                child: Column(
                children: [
        Image.asset(themeImages[value], width: 80, height: 80),
        Text(
                themeNames[value],
                style: TextStyle(
                fontSize: 18,
                color: isSelected ? Colors.blue : Colors.black,
                fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (additionalButtonText != null)
            TextButton(
                    onPressed: onAdditionalButtonPress,
                child: Text(
                additionalButtonText,
                style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20),
        _buildNavigationButtons(),
        ],
      ),
    );
    }

    Widget _buildNavigationButtons() {
        return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
        _buildButton("Back", Colors.grey, () {
            _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        }),
        const SizedBox(width: 20),
        _buildButton("Next", _isNextButtonEnabled() ? Colors.blue : Colors.blue.withOpacity(0.5), () {
            if (_isNextButtonEnabled()) {
                _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
            }
        }),
      ],
    );
    }
}
