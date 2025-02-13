import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Text(
            "Your privacy is important to us at Puzzle Cube.\n\n"
            "This Privacy Policy explains how we collect, use, and protect your data when you play Puzzle Cube. "
            "We strive to ensure that your personal information remains secure. \n\n"
            "1. Data Collection:\n"
            "   Puzzle Cube does not require you to register or provide any personal information. "
            "We only collect anonymous usage statistics (such as high scores and levels) to help improve the game experience.\n\n"
            "2. Data Usage:\n"
            "   The data collected is used solely for analytics and to enhance your gaming experience. "
            "We do not share your information with third parties.\n\n"
            "3. Security:\n"
            "   We implement appropriate measures to safeguard your data from unauthorized access. "
            "However, no method of transmission over the internet is 100% secure.\n\n"
            "4. Changes to Privacy Policy:\n"
            "   We may update this policy from time to time. Any changes will be posted in the app, and your continued use of Puzzle Cube signifies your acceptance of the updated policy.\n\n"
            "Enjoy your puzzle journey, and thank you for trusting Puzzle Cube with your gaming experience!",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
