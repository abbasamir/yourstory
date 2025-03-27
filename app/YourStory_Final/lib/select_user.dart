import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'student_dashboard.dart';
import 'add_child_info.dart'; // Import the AddChildInfo screen

class UserSelectionScreen extends StatelessWidget {
  final String documentID;

  const UserSelectionScreen({Key? key, required this.documentID})
      : super(key: key);

  Future<Map<String, dynamic>> _getChildren() async {
    try {
      // Fetch parent document using the provided documentID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(documentID)
          .get();

      if (userDoc.exists) {
        // Access children data
        return userDoc['children'] as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching children data: $e');
    }
    return {}; // Return an empty map if no children found or error occurs
  }

  // Updated function to navigate to the dashboard with child details and track access
  Future<void> _trackChildAccess(BuildContext context, String childId,
      String childName, String childImage) async {
    try {
      // Reference to the parent document
      var parentDocRef =
      FirebaseFirestore.instance.collection('parents').doc(documentID);

      // Update lastAccessed field for the selected child
      await parentDocRef.update({
        'children.$childId.lastAccessed': FieldValue.serverTimestamp(),
      });

      // Now navigate to the dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboard(
            childId: childId,
            childName: childName,
            childImage: childImage,
          ),
        ),
      );
    } catch (e) {
      print("Error updating access for $childId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the heavy shadow as used in your StartPage header.
    final List<BoxShadow> heavyShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        offset: const Offset(0, 4),
        blurRadius: 10,
        spreadRadius: 3,
      ),
    ];

    return Scaffold(
      // Updated AppBar: background is the same pink as the header, and the icon is white.
      appBar: AppBar(
        title: const Text('Select User', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF3355),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Wrap everything in a SingleChildScrollView so the header and grid scroll together.
      body: SingleChildScrollView(
        child: Column(
          children: [
            //────────────────────────────────────────────────────────────
            // Header from StartPage (Top Placeholder with Logo and Heavy Shadow)
            //────────────────────────────────────────────────────────────
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3355),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: heavyShadow,
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            //────────────────────────────────────────────────────────────
            // FutureBuilder for Children Grid
            //────────────────────────────────────────────────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _getChildren(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error fetching children data.'));
                }

                final children = snapshot.data ?? {};

                if (children.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: AppShadowsLight.universalShadow(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add User'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const AddChildrenDetailsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: children.length + 1,
                  itemBuilder: (context, index) {
                    if (index == children.length) {
                      // "Add User" card with heavy drop shadow.
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const AddChildrenDetailsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.universalShadow(),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 50,
                              color: Colors.grey.shade600,
                              shadows: AppShadows.universalShadow(),
                            ),
                          ),
                        ),
                      );
                    }

                    // Display child profile card with heavy drop shadow.
                    String childId = children.keys.elementAt(index);
                    Map<String, dynamic> childData = children[childId];
                    String childName = childData['name'] ?? 'Unknown';
                    String childImage = childData['selectedAvatar'] ?? '';

                    return GestureDetector(
                      onTap: () => _trackChildAccess(
                          context, childId, childName, childImage),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.shade100,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.universalShadow(),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconData(Icons.person.codePoint,
                                  fontFamily: 'MaterialIcons'),
                              size: 50,
                              color: Colors.white,
                              shadows: AppShadows.universalShadow(),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              childName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                shadows: AppShadows.universalShadow(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
