import 'dart:async';
import 'dart:convert';
//import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
//import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yourstory/edit_profile.dart';
import 'package:yourstory/story_generation_screen.dart';
import 'package:yourstory/student_dashboard.dart'; // if needed
import 'package:yourstory/example_story.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data'; // ✅ Required for base64Decode
import 'package:intl/intl.dart';
// Add any other imports you need

class StorySelectionPage extends StatefulWidget {
  final String childId;
  final String childName;
  final dynamic childImage;

  /// You can choose to require these if you want the avatar/edit profile logic
  const StorySelectionPage({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childImage,
  }) : super(key: key);

  @override
  _StorySelectionPageState createState() => _StorySelectionPageState();
}

class _StorySelectionPageState extends State<StorySelectionPage> {
  /// We replicate references to avatar logic (profileImageUrl, selectedAvatar)
  String? profileImageUrl = '';
  String selectedAvatar = '';
  bool isLoading = false;
  String _theme = '';
  String _story = "Click 'Assign' to generate a story.";
  String reminderMessage = '';
  int _difficulty = 300;
  String? selectedStoryTitle;


  int _selectedIndex = 1;

  // Example splitting: first 3 are "Stories Due," last 3 are "Completed"
  List<int> dueStoryIndices = [0, 1, 2];
  List<int> completedStoryIndices = [3, 4, 5];


  late List<String> dueStoryTitles = [];
  late List<String> completedStoryTitles = [];
  late List<String> dueStoryDates = [];

  final List<String> storyImages = [
    "assets/stories_due_default_question_mark.png",
    "assets/stories_due_default_question_mark.png",
    "assets/stories_due_default_question_mark.png",
  ];

  late List<String> completedStoryImages = [];

  final List<String> storyContents = [

  ];

  final List<String> storySummaries = [

  ];

  final List<String> animationPaths = [
    "assets/rabbit_animation.json",
    "assets/rabbit_animation.json",
    "assets/rabbit_animation.json",
    "assets/rabbit_animation.json",
    "assets/rabbit_animation.json",
    "assets/rabbit_animation.json",
  ];

  @override
  void initState() {
    super.initState();
    // If needed, you could fetch the user's avatar from Firestore,
    // then set profileImageUrl or selectedAvatar here.
    // For now, we assume you pass them in or keep defaults.
    profileImageUrl = widget.childImage; // Or some logic to fetch it
    fetchAssignedStories();
    fetchCompletedStories();
    _fetchReminder();
    _fetchDifficultyFromFirebase();
  }


  Future<void> deleteAssignedStory(String selectedStoryTitle) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      setState(() {
        //isLoading = true; // Start loading
      });

      print("Deleting assigned story for childId: ${widget.childId}, Title: $selectedStoryTitle");


      // Fetch the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      final parentDoc = await parentRef.get();

      if (!parentDoc.exists || parentDoc.data() == null) {
        print("Parent document does not exist or is empty.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
      print("Fetched children map: $childrenMap");

      String childKey = '${widget.childId}';
      print("Generated child key: $childKey");

      if (!childrenMap.containsKey(childKey)) {
        print("Child key $childKey not found in children map.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get the list of assigned stories
      List<dynamic> assignedStories = childrenMap[childKey]['assigned_story'] ?? [];
      print("Assigned stories list: $assignedStories");

      // Remove the story with the matching title
      List<dynamic> updatedAssignedStories = assignedStories.where((story) {
        // Keep stories that don't match the selected title
        if (story is Map<String, dynamic> && story['name'] == selectedStoryTitle) {
          print("Story with title '$selectedStoryTitle' found, removing it.");
          return false; // Remove the story if it matches the title
        }
        return true; // Keep the story if it doesn't match the title
      }).toList();

      // Update the Firestore document if the list has changed
      if (updatedAssignedStories.length != assignedStories.length) {
        await parentRef.update({
          "children.$childKey.assigned_story": updatedAssignedStories,
        });

        print("Assigned story with title '$selectedStoryTitle' has been removed.");
      } else {
        print("No matching story found to remove.");
      }

      setState(() {
        isLoading = false; // Stop loading after update
      });
    } catch (e, stackTrace) {
      print("Error deleting assigned story: $e");
      print("Stack Trace: $stackTrace");
      setState(() {
        isLoading = false;
      });
    }
  }




 /* Future<void> _fetchThemeFromFirebase() async {
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
*/

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
            _difficulty = (childData['difficulty'] as num?)?.toInt() ?? 300; // Ensure it's an int
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



  Future<void> _generateStory() async {
    setState(() => isLoading = true);

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
          'reading_level': 'beginner',  // Set reading level
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
              'correct_answer': item['correct_answer'] ?? 'No correct answer provided',
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
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'), // Replace with your Groq API URL
          headers: {
            'Authorization': 'Bearer $grokApiKey', // Replace with your Groq API key
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama-3.3-70b-versatile",  // Specify the model you want to use
            "messages": [
              {
                "role": "system",
                "content":
                "Adjust the difficulty of the following question to level $_difficulty (1-700). Return output strictly in this format:\nQuestion: <text>\nA) <option 1>\nB) <option 2>\nC) <option 3>\nD) <option 4>\nCorrect Answer: <A/B/C/D>"
              },
              {
                "role": "user",
                "content":
                "Question: ${questions[0]['question']}\nOptions: ${questions[0]['options'].join(', ')}\nCorrect Answer: ${questions[0]['correct_answer']}"
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
                'correct_answer': item['correct_answer'] ?? 'No correct answer provided',
              };
            }).toList();
          }
        } else {
          _showError("Failed to modify questions. Try again later.");
        }

        // Step 3: Ensure images are properly handled
        List<String> base64Images = [];
        if (data['images'] is List) {
          base64Images = List<String>.from(data['images'].map((img) => img.toString()));
        }

        debugPrint("Received ${base64Images.length} images for decoding.");

        List<Image> images = [];
        String? imageUrl; // Make sure imageUrl is not null

// Decode base64 images safely
        for (int i = 0; i < base64Images.length; i++) {
          try {
            Uint8List decodedBytes = base64Decode(base64Images[i]);
            images.add(Image.memory(decodedBytes));
            debugPrint("✅ Decoded image ${i + 1} successfully. Size: ${decodedBytes.length} bytes.");
          } catch (e) {
            debugPrint("❌ Error decoding image ${i + 1}: $e");
          }
        }

// If fewer than 25 images, cycle through available images
        if (images.isNotEmpty && images.length < 35) {
          debugPrint("Only ${images.length} images available. Recycling to fill 25 slots.");
          int initialLength = images.length;

          if (initialLength == 0) {
            debugPrint("🚨 Error: images list is empty, cannot cycle through it.");
          } else {
            for (int i = 0; images.length < 35; i++) {
              images.add(images[i % initialLength]);
              debugPrint("🔄 Reused image ${i % initialLength} to fill slot ${images.length}.");
            }
          }
        } else {
          debugPrint("✅ Images list is already 35.");
        }

// If no images were decoded, assign a default image URL
        if (images.isEmpty) {
          debugPrint("❌ No valid images found, assigning default image URL.");
          imageUrl = 'default_image.jpg'; // Use a placeholder or default image URL
        } else {
          // Proceed to upload the first image or any image (if needed)
          // (Optional: You can choose a specific image or upload the first image)
          String? base64Image = base64Images.isNotEmpty ? base64Images[0] : null;

          if (base64Image != null && base64Image.isNotEmpty) {
            imageUrl = await _uploadImageToFirebase(base64Image); // Upload the image and get the URL
          }

          // If the upload fails or no image URL is returned, fallback to a default image
          if (imageUrl == null) {
            debugPrint("❌ Image upload failed or no image URL, assigning default.");
            imageUrl = 'https://example.com/default-image.png'; // Fallback to a default URL
          }
        }

        debugPrint("Generate Story - Final image URL to store: $imageUrl");


        setState(() {
          _story = fullStory;
        });

        if (_story.isEmpty) {
          _showError("Story is empty. Try again later.");
          return;
        }

        // Debugging before navigation
        debugPrint('Passing data to StoryPage:');
        debugPrint('Questions: $questions');
        debugPrint('Images: ${images.length} images decoded');

        await _saveStoryToFirebase(fullStory, questions, imageUrl);
        // Delete from assigned_story before saving to completed_assignments
        await deleteAssignedStory(selectedStoryTitle!);

        // Navigate to StoryPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryPage(
              childId: widget.childId,
              childName: widget.childName,
              childImage: widget.childImage,
              title: _theme,
              storyContent: _story,
              questions: questions,  // ✅ Ensure this is passed as a list
              storyImages: images,   // ✅ Ensure this is passed as a list of Image widgets
              animationPath: 'assets/space_animation.gif',
            ),
          ),
        );
      } else {
        _showError("Failed to generate story. Try again later.");
      }

    } on TimeoutException {
      _showError("Request timed out. Please check your internet.");
    } on http.ClientException catch (e) {
      _showError("Network error: $e");
    } catch (e) {
      _showError("An unexpected error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveStoryToFirebase(
      String story,
      List<Map<String, dynamic>> questions,
      String? imageUrl // Expect image URL, can be null if no image
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("Error: No authenticated user found.");
        return;
      }

      String parentId = user.uid;
      String childId = widget.childId;

      // Firestore reference
      DocumentReference parentRef =
      FirebaseFirestore.instance.collection("parents").doc(parentId);

      // Fetch existing completed assignments if available
      DocumentSnapshot parentDoc = await parentRef.get();
      List<dynamic> completedAssignments = [];

      if (parentDoc.exists) {
        Map<String, dynamic>? parentData =
        parentDoc.data() as Map<String, dynamic>?;

        if (parentData?['children']?[childId]?['completed_assignments'] != null) {
          completedAssignments =
              List.from(parentData!['children'][childId]['completed_assignments']);
        }
      }

      // Create the new assignment object with a timestamp
      Map<String, dynamic> newAssignment = {
        "title": selectedStoryTitle, // Ensure selectedStoryTitle is defined
        "storyContent": story,
        "questions": questions,
        "imageUrl": imageUrl, // Nullable if no image was uploaded
        "timestamp": DateTime.now().toUtc().millisecondsSinceEpoch, // Use manual timestamp
      };

      // Add new assignment to the list
      completedAssignments.add(newAssignment);


      // Update Firestore with the new list of completed assignments
      await parentRef.update({
        "children.$childId.completed_assignments": completedAssignments,
      });

      debugPrint("Story successfully saved in Firestore!");
    } catch (e) {
      debugPrint("Error saving story to Firestore: $e");
    }
  }





  Future<String?> _uploadImageToFirebase(String base64Image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("Error: No authenticated user found.");
        return null;
      }

      // Strip any data URL prefix (if present) before decoding the base64 string
      String cleanBase64 = base64Image.contains("base64,")
          ? base64Image.split("base64,")[1]
          : base64Image;

      // Decode the base64 string into bytes
      Uint8List imageBytes = Uint8List.fromList(base64Decode(cleanBase64));
      String fileName = "story_${DateTime.now().millisecondsSinceEpoch}.png";

      Reference storageRef = FirebaseStorage.instance.ref().child("story_images/$fileName");
      UploadTask uploadTask = storageRef.putData(imageBytes, SettableMetadata(contentType: 'image/png'));

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint("Upload Progress: ${(progress * 100).toStringAsFixed(2)}%");
      });

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {
        debugPrint("✅ Upload completed for: $fileName");
      });

      String imageUrl = await snapshot.ref.getDownloadURL();
      debugPrint("✅ Image uploaded successfully: $imageUrl");

      // Return the full URL as a string
      return imageUrl; // Return the full image URL
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
    }
  }




  Future<void> fetchAssignedStories() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      setState(() {
      //  isLoading = true; // Start loading
      });

      print("Fetching assigned stories for childId: ${widget.childId}");

      // Fetch the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      final parentDoc = await parentRef.get();

      if (!parentDoc.exists || parentDoc.data() == null) {
        print("Parent document does not exist or is empty.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
      print("Fetched children map: $childrenMap");

      String childKey = '${widget.childId}';
      print("Generated child key: $childKey");

      if (!childrenMap.containsKey(childKey)) {
        print("Child key $childKey not found in children map.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Ensure 'assigned_story' exists and is a list
      List<dynamic> assignedStories = childrenMap[childKey]['assigned_story'] ?? [];
      print("Assigned stories raw data: $assignedStories");

      if (assignedStories.isEmpty) {
        print("Assigned stories list is empty.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Extract assignment name and due_date safely
      List<Map<String, dynamic>> storyList = [];
      DateFormat dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

      for (var story in assignedStories) {
        if (story is Map<String, dynamic> && story.containsKey('name') && story.containsKey('due_date')) {
          try {
            DateTime dueDate = dateFormat.parse(story['due_date']);
            storyList.add({
              'name': story['name'] as String,
              'due_date': dueDate,
            });
          } catch (e) {
            print("Error parsing due_date: ${story['due_date']}");
          }
        } else {
          print("Skipping invalid story entry: $story");
        }
      }

      // Sort stories by due_date (nearest date first)
      storyList.sort((a, b) => a['due_date'].compareTo(b['due_date']));

      // Fetch only the 3 nearest due stories
      List<String> fetchedTitles = [];
      List<DateTime> fetchedDueDates = []; // Store due dates as DateTime

      int count = 0;
      for (var story in storyList) {
        if (count >= 3) break; // Stop after 3 stories
        fetchedTitles.add(story['name']);
        fetchedDueDates.add(story['due_date']);
        count++;
      }

      print("Fetched story titles: $fetchedTitles");
      print("Fetched due dates: $fetchedDueDates");

      if (mounted) {
        setState(() {
          dueStoryTitles = fetchedTitles;
          dueStoryDates = fetchedDueDates.cast<String>();
          isLoading = false; // Stop loading after fetching
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching stories: $e");
      print("Stack Trace: $stackTrace");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  Future<void> _fetchReminder() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      print('Current User: $user'); // Debugging print statement

      if (user != null) {
        // Fetch the parent document from Firestore
        DocumentSnapshot parentDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .get();

        print('Parent document fetched: ${parentDoc.exists}'); // Debugging print statement

        if (parentDoc.exists && parentDoc.data() != null) {
          // Extract parent data
          Map<String, dynamic> parentData =
          parentDoc.data() as Map<String, dynamic>;
          print('Parent data: $parentData'); // Debugging print statement

          // Extract children data
          Map<String, dynamic>? children =
          parentData['children'] as Map<String, dynamic>?;
          print('Children data: $children'); // Debugging print statement

          if (children != null && children.containsKey(widget.childId)) {
            // Fetch child data
            Map<String, dynamic> childData =
            children[widget.childId] as Map<String, dynamic>;
            print('Child data: $childData'); // Debugging print statement

            // Update the reminder message
            setState(() {
              reminderMessage = childData['reminder'] ?? 'No reminders yet';
            });
          } else {
            print('No matching child found for childId: ${widget.childId}'); // Debugging print statement
            setState(() {
              reminderMessage = 'Error fetching reminder';
            });
          }
        } else {
          print('Parent data not found or empty'); // Debugging print statement
          setState(() {
            reminderMessage = 'Error fetching data';
          });
        }
      }
    } catch (e) {
      print('Error fetching reminder: $e'); // Debugging print statement
      setState(() {
        reminderMessage = 'Error fetching reminder';
      });
    }
  }


  Future<void> fetchCompletedStories() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      setState(() {
       // isLoading = true; // Start loading
      });

      print("Fetching completed stories for childId: ${widget.childId}");

      // Fetch the parent document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);
      final parentDoc = await parentRef.get();

      if (!parentDoc.exists || parentDoc.data() == null) {
        print("Parent document does not exist or is empty.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> childrenMap = parentDoc.data()?['children'] ?? {};
      print("Fetched children map: $childrenMap");

      String childKey = '${widget.childId}';
      print("Generated child key: $childKey");

      if (!childrenMap.containsKey(childKey)) {
        print("Child key $childKey not found in children map.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get the list of completed assignments
      List<dynamic> completedAssignments = childrenMap[childKey]['completed_assignments'] ?? [];
      print("Completed assignments list: $completedAssignments");

      // Check if there are any assignments and extract titles and image URLs
      List<String> fetchedTitles = [];
      List<String> fetchedImageUrls = []; // List to store image URLs

      // Sort assignments by timestamp (descending order)
      completedAssignments.sort((a, b) {
        int timestampA = a['timestamp'] ?? 0;
        int timestampB = b['timestamp'] ?? 0;
        return timestampB.compareTo(timestampA); // Descending order
      });

      // Fetch the latest 3 assignments
      int count = 0;
      for (var assignment in completedAssignments) {
        if (count >= 3) break; // Stop after 3 assignments

        if (assignment is Map<String, dynamic>) {
          // Extract title and imageUrl if they exist
          if (assignment.containsKey('title')) {
            fetchedTitles.add(assignment['title'] as String);
            print("Added title: ${assignment['title']}");
          }

          if (assignment.containsKey('imageUrl')) {
            fetchedImageUrls.add(assignment['imageUrl'] as String);
            print("Added image URL: ${assignment['imageUrl']}");
          }
        } else {
          print("Skipping invalid assignment: $assignment");
        }
        count++;
      }

      print("Fetched story titles: $fetchedTitles");
      print("Fetched image URLs: $fetchedImageUrls");

      if (mounted) {
        setState(() {
          completedStoryTitles = fetchedTitles;
          completedStoryImages = fetchedImageUrls; // Store image URLs in the list
          isLoading = false; // Stop loading after fetching
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching stories: $e");
      print("Stack Trace: $stackTrace");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }






  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          //
          // ───────────────── USE YOUR HEADER SNIPPET ─────────────────
          //
          appBar: PreferredSize(
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
                      // Left: reminder container
                      Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.04,
                        ),
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
                                  color: Colors.black.withOpacity(0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
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
                      // Right: avatar -> goes to EditProfilePage
                      Padding(
                        padding: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.046,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(
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
                                  color: Colors.black.withOpacity(0.25),
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
          ),
          //
          // ───────────────── BODY: TWO SHELVES + STAGE ─────────────────
          //
          body: AbsorbPointer(
            absorbing: isLoading, // Disable interactions while loading
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "STORIES DUE",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildShelfContainer(context, dueStoryIndices),
                  const SizedBox(height: 40),
                  Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.brown[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "STAGE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "COMPLETED STORIES",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildShelfContainer(context, completedStoryIndices),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          //
          // ───────────────── FOOTER ─────────────────
          //
          bottomNavigationBar: Stack(
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
          ),
        ),
        //
        // ───────────────── LOADING SCREEN ─────────────────
        //
        if (isLoading)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo_loading.gif',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
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
    );
  }


  Widget _buildButton(BuildContext context,
      String text,
      Widget page, {
        required Color backgroundColor,
        Color textColor = Colors.black,
        bool hasCurves = true,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: hasCurves
              ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )
              : RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          minimumSize: const Size(double.infinity, 60),
          shadowColor: Colors.black.withOpacity(0.35),
          elevation: 6,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black12,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///

  ///
  /// Builds the shelf container (Row of "books")
  ///
  Widget _buildShelfContainer(BuildContext context, List<int> indices) {
    // Ensure only valid indices are used
    List<int> validIndices = indices.where((idx) => idx < 6).toList(); // Limit to index 0-5

    if (validIndices.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          "No stories available",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: validIndices.map((idx) {
          return _buildStoryBook(context, idx);
        }).toList(),
      ),
    );
  }

  Widget _buildStoryBook(BuildContext context, int index) {
    // Use the correct list based on index
    List<String> titles = index < 3 ? dueStoryTitles : completedStoryTitles;
   // List<String> dueDate = index < 3 ? dueStoryDates : List.filled(titles.length, "");
    List<String> images = index < 3 ? storyImages : completedStoryImages;

    print("Building StoryBook:");
    print("Index: $index");
    print("Available Titles: $titles");
    print("Available Images: $images");

    // Check if the index is within bounds
    if (index % 3 >= titles.length || index % 3 >= images.length) {
      print("ERROR: Index $index is out of range! Titles Length: ${titles.length}, Images Length: ${images.length}");
      return Container(); // Prevents crash
    }

  /*  String formattedDueDate = "No Due Date";
    if (index < 3 && dueStoryDates[index % 3].isNotEmpty) {
      // Optional: If you want to remove time, you can use substring to just show the date part
      formattedDueDate = dueStoryDates[index % 3].substring(0, 10);  // Extracts "YYYY-MM-DD"
    }
*/
    return GestureDetector(
      onTap: () async {
        setState(() {
         // isLoading = true;  // Start loading
        });

        selectedStoryTitle = dueStoryTitles[index];


        await _generateStory();  // Ensure story is generated before navigation

        setState(() {
          isLoading = false;  // Stop loading
        });

        print("Selected Story Title: $selectedStoryTitle");
      },

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: images[index % 3].startsWith('http') // Check if it's a network URL
                      ? NetworkImage(images[index % 3]) // Use NetworkImage for remote images
                      : AssetImage(images[index % 3]) as ImageProvider, // Use AssetImage for local assets
                  height: 50,
                  width: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      // Image has been fully loaded
                      return child;
                    } else {
                      // Show loading indicator while the image is loading
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    }
                  },
                )
                ,
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    titles[index % 3], // Ensure within bounds
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (index >= 3)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

// Displays the due stories shelf (indices 0-2)
  Widget buildDueStoryShelf(BuildContext context) {
    print("Due Story Indices: $dueStoryIndices"); // Debugging print
    print("Due Story Titles: $dueStoryTitles");   // Check if titles are fetched
    return _buildShelfContainer(context, [0, 1, 2]);
  }

// Displays the completed stories shelf (indices 3-5)
  Widget buildCompletedStoryShelf(BuildContext context) {
    print("Completed Story Indices: $completedStoryIndices"); // Debugging print
    print("Completed Story Titles: $completedStoryTitles");   // Check if titles are fetched
    return _buildShelfContainer(context, [3, 4, 5]);
  }

// Combine both shelves
  Widget buildStoryShelves(BuildContext context) {
    return Column(
      children: [
        buildDueStoryShelf(context), // Due stories (0-2)
        const SizedBox(height: 16),  // Space between shelves
        buildCompletedStoryShelf(context), // Completed stories (3-5)
      ],
    );
  }



  void _showError(String message) {
    setState(() => _story = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Bottom nav onItemTapped
  void _onItemTapped(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryGeneratorScreen(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
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
          MaterialPageRoute(builder: (_) => StorySelectionPage(childName: widget.childName,childId: widget.childId ,childImage: widget.childImage)),
        );
        break;
    }
  }
}