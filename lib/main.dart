
import 'package:flutter/material.dart';
import 'package:puzzle_cube/oyungiris.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // PuzzleCube oyun örneğini oluşturuyoruz.
    

    return MaterialApp(
      title: 'Puzzle Cube',
      debugShowCheckedModeBanner: false,
      // Uygulamanın ana ekranı Scaffold içerisine yerleştirilmiş GameWidget ile sunuluyor.
      home: Scaffold(
        body: PuzzleEntrancePage(),
      ),
    );
  }
}
