import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeAvatarPage extends StatefulWidget {
  final String childId; // Added childId to identify which child to update

  ChangeAvatarPage({
    required this.childId,
  });

  @override
  _ChangeAvatarPageState createState() => _ChangeAvatarPageState();
}

class _ChangeAvatarPageState extends State<ChangeAvatarPage> {
  String gender = ''; // Variable to hold the gender

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

  @override
  void initState() {
    super.initState();
    _fetchGenderFromFirestore();
  }

  // Fetch gender from Firestore
  Future<void> _fetchGenderFromFirestore() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      // Fetch the parent document
      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        // Fetch the gender from the specific child document
        final children = parentDoc.data()?['children'] as Map<String, dynamic>?;

        if (children != null && children.containsKey(widget.childId)) {
          // Fetch the gender of the child
          final childGender = children[widget.childId]['gender'];
          setState(() {
            gender = childGender ?? '';
          });

          print("Fetched gender for child ${widget.childId}: $gender");
        } else {
          print("Child with ID ${widget.childId} does not exist.");
        }
      } else {
        print("Parent document does not exist.");
      }
    } catch (e) {
      print("Error fetching gender for child ${widget.childId}: $e");
    }
  }

  Future<void> saveAvatarToFirestore(String avatarUrl) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      // Reference to the parent's document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      // Fetch the parent document
      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        // Fetch the 'children' map from the parent document
        final children = parentDoc.data()?['children'] as Map<String, dynamic>?;

        if (children != null && children.containsKey(widget.childId)) {
          // Update the selected avatar URL for the specific child in the map
          await parentRef.update({
            'children.${widget.childId}.selectedAvatar': avatarUrl,
          });

          print("Avatar for ${widget.childId} saved successfully!");
        } else {
          print("Child with ID ${widget.childId} does not exist.");
        }
      } else {
        print("Parent document does not exist.");
      }
    } catch (e) {
      print("Error saving avatar for ${widget.childId}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (gender.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Select Avatar'),
          backgroundColor: Color(0xFF9C4D9A),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Debugging: Check the gender fetched from Firestore
    print("Gender fetched from Firestore: $gender");

    // Determine which gender's avatars to display
    final avatarList = gender == 'female' ? femaleAvatars : maleAvatars;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Avatar'),
        backgroundColor: Color(0xFF9C4D9A),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns in the grid
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: avatarList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              // Debugging: Print the selected avatar URL
              print("Selected avatar: ${avatarList[index]}");

              // Save selected avatar to Firestore
              await saveAvatarToFirestore(avatarList[index]);

              // Return the selected avatar to the previous screen
              Navigator.pop(context, avatarList[index]);
            },
            child: Card(
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.asset(avatarList[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
