import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart'; // Import the ThemeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state variables
  bool _soundEffects = true;
  bool _narrationEnabled = true;
  double _narrationSpeed = 1.0;


  Future<void> _saveNarrationSpeed(double speed) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    String childKey = "child_1"; // Change based on selected child

    try {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(userId)
          .update({
        'children.$childKey.narration_speed': speed,  // Dot notation for nested update
      });
      print("Narration speed updated successfully: $speed");
    } catch (e) {
      print("Error updating narration speed: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context); // Access ThemeNotifier
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Theme Section
              _buildSectionTitle('App Theme'),
              _buildThemeSelector(themeNotifier),
              const Divider(),

              // Sound Effects Section
              _buildSectionTitle('Sound Effects'),
              SwitchListTile(
                title: const Text('Enable Sound Effects'),
                value: _soundEffects,
                onChanged: (bool value) {
                  setState(() {
                    _soundEffects = value;
                  });
                },
                activeColor: Colors.purple,
              ),
              const Divider(),

              // Narration Section
              _buildSectionTitle('Narration'),
              SwitchListTile(
                title: const Text('Enable Narration'),
                value: _narrationEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _narrationEnabled = value;
                  });
                },
                activeColor: Colors.purple,
              ),
              if (_narrationEnabled) _buildNarrationSpeedSlider(),
              const Divider(),

              // Profile Management Section
              _buildSectionTitle('Profile'),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.purple),
                title: const Text('Manage Profile'),
                onTap: () {
                  // Navigate to Profile Management Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileManagementPage()),
                  );
                },
              ),
              const Divider(),

              // Reset Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _resetSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Reset to Default',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  // Build theme selector
  Widget _buildThemeSelector(ThemeNotifier themeNotifier) {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Bright Theme'),
          value: ThemeMode.light,
          groupValue: themeNotifier.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeNotifier.setThemeMode(value);
            }
          },
          activeColor: Colors.purple,
        ),
        RadioListTile(
          title: const Text('Dark Theme'),
          value: ThemeMode.dark,
          groupValue: themeNotifier.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeNotifier.setThemeMode(value);
            }
          },
          activeColor: Colors.purple,
        ),
      ],
    );
  }

  // Build narration speed slider
  Widget _buildNarrationSpeedSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Narration Speed',
          style: TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            const Text('Slow'),
            Expanded(
              child: Slider(
                value: _narrationSpeed,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${_narrationSpeed.toStringAsFixed(1)}x',
                onChanged: (double value) {
                  setState(() {
                    _narrationSpeed = value;
                  });
                  _saveNarrationSpeed(value);
                },
                activeColor: Colors.purple,
              ),
            ),
            const Text('Fast'),
          ],
        ),
      ],
    );
  }

  // Reset settings to default
  void _resetSettings() {
    setState(() {
      _soundEffects = true;
      _narrationEnabled = true;
      _narrationSpeed = 1.0;
    });

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.setThemeMode(ThemeMode.light);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to default.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ProfileManagementPage extends StatelessWidget {
  const ProfileManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          'Profile Management Page Coming Soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
