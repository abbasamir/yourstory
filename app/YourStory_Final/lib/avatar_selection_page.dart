import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yourstory/avatar_grid_page.dart';

class AvatarSelectionPage extends StatelessWidget {
  final String userId; // Pass the user ID to associate the selection with a user.

  AvatarSelectionPage({required this.userId});

  Future<void> saveAvatarToFirestore(String childId, String avatarUrl) async {
    try {
      // Reference to the parent's document
      final parentRef = FirebaseFirestore.instance.collection('parents').doc(userId);

      // Fetch the parent document
      final parentDoc = await parentRef.get();

      if (parentDoc.exists) {
        // Fetch the 'children' map from the parent document
        final children = parentDoc.data()?['children'] as Map<String, dynamic>?;

        if (children != null && children.containsKey(childId)) {
          // Update the selected avatar URL for the specific child in the map
          await parentRef.update({
            'children.$childId.selectedAvatar': avatarUrl,
          });

          print("Avatar for $childId saved successfully!");
        } else {
          print("Child with ID $childId does not exist.");
        }
      } else {
        print("Parent document does not exist.");
      }
    } catch (e) {
      print("Error saving avatar for $childId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Avatar"),
        backgroundColor: Color(0xFF9C4D9A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Choose Gender",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    // Navigate to AvatarGridPage with 'female' gender
                    final selectedAvatar = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvatarGridPage(gender: 'female'),
                      ),
                    );
                    if (selectedAvatar != null) {
                      // Replace 'child1' with the actual dynamic child ID
                      String childId = userId; // Example child ID
                      // Save the selected avatar to Firestore for this specific child
                      await saveAvatarToFirestore(childId, selectedAvatar);
                      Navigator.pop(context, selectedAvatar);
                    }
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.female,
                        color: Colors.pink,
                        size: 100,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Female",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Navigate to AvatarGridPage with 'male' gender
                    final selectedAvatar = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvatarGridPage(gender: 'male'),
                      ),
                    );
                    if (selectedAvatar != null) {
                      // Replace 'child2' with the actual dynamic child ID
                      String childId = 'child_2'; // Example child ID
                      // Save the selected avatar to Firestore for this specific child
                      await saveAvatarToFirestore(childId, selectedAvatar);
                      Navigator.pop(context, selectedAvatar);
                    }
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.male,
                        color: Colors.blue,
                        size: 100,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Male",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
