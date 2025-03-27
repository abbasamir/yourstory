import 'package:flutter/material.dart';

class AvatarGridPage extends StatelessWidget {
  final String gender;

  AvatarGridPage({required this.gender});

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
  Widget build(BuildContext context) {
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
            onTap: () {
              // Pass selected avatar back to EditProfilePage
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
