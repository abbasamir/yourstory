import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
              // Title
              _buildSectionTitle('How to Use the App'),

              // Simple instructions for children
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '1. Tap on the icons to explore!\n'
                      '2. Tap the settings to change your theme.\n'
                      '3. Check your profile to see your progress.',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              // Divider
              const Divider(),

              // Title for Troubleshooting
              _buildSectionTitle('Need Help?'),

              // Simple Troubleshooting Steps
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '1. If the app is not opening, try restarting.\n'
                      '2. Make sure your device is connected to the internet.\n'
                      '3. Tap the "Help" button if something is not working!',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              // Divider
              const Divider(),

              // Title for Contact Support
              _buildSectionTitle('Contact Us'),

              // Contact Information
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'If you need more help, ask an adult to contact us:\n\n'
                      'Email: privacy@yourstory.com',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              // Divider
              const Divider(),

              // Title for FAQ
              _buildSectionTitle('FAQ'),

              // Simple FAQ section
              _buildFAQItem('How does the app track my child’s progress?',
                  'Child’s progress is recorded based on the number of stories completed and time spent in the app. You can check progress in the parent dashboard.'),

              _buildFAQItem('How is difficulty (MMR) calculated?',
                  'The difficulty score (MMR) adjusts based on the child’s performance. It increases for correct answers and decreases for incorrect ones, ensuring an adaptive learning experience.'),

              _buildFAQItem('Can I add multiple children under one account?',
                  'Yes! You can add multiple children under your account, and each child will have their own personalized progress and story recommendations.'),

              _buildFAQItem('How do I reset my child’s progress?',
                  'Currently, progress cannot be reset manually to maintain accurate learning records. However, you can create a new child profile if needed.'),

              _buildFAQItem('How can I provide feedback or report an issue?',
                  'You can send feedback through the app’s "Contact Us" section above and email our support team.'),

              _buildFAQItem('Does the app work offline?',
                  'No, You need to be connected to internet to use the app!'),

              _buildFAQItem('How do I log in on another device?',
                  'Simply log in using your registered email and password. Your data syncs automatically across devices.')

            ],
          ),
        ),
      ),
    );
  }

  // Build a simple section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  // Simple FAQ item
  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
