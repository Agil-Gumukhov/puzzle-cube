import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Terms of Service",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Text(
            "Welcome to Puzzle Cube!\n\n"
            "By playing Puzzle Cube, you agree to the following terms and conditions. "
            "Puzzle Cube is a brain-teasing game designed to challenge your logic and creativity. "
            "All content provided within the app is for entertainment purposes only. \n\n"
            "1. Use of Content:\n"
            "   All puzzles, graphics, and texts within Puzzle Cube are the property of the developer. "
            "You may not reproduce, distribute, or modify any part of the game without prior written consent.\n\n"
            "2. User Conduct:\n"
            "   You agree to use Puzzle Cube in a respectful and lawful manner. Any misuse or abusive behavior may result in termination of your access.\n\n"
            "3. No Warranty:\n"
            "   The game is provided 'as is' without any warranties. The developer is not liable for any loss or damage arising from your use of the app.\n\n"
            "4. Changes to Terms:\n"
            "   We reserve the right to update these Terms of Service at any time. Continued use of Puzzle Cube after any changes constitutes your acceptance of the new terms.\n\n"
            "Thank you for playing Puzzle Cube and challenging your mind!",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
