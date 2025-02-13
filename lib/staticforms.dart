// Örnek bloklar (blok çeşitliliğini artırmak için)
import 'package:flutter/material.dart';
import 'package:puzzle_cube/puzzleblock.dart';

final List<PuzzleBlock> allStaticForms = [
  // 1) Kare (2x2)
  PuzzleBlock(
    shape: [
      [true, true],
      [true, true],
    ],
    color: Colors.blue,
  ),
  // 2) Dikey Çubuk (3 blok)
  PuzzleBlock(
    shape: [
      [true],
      [true],
      [true],
    ],
    color: Colors.red,
  ),
  // 3) T Şekli (T Block)
  PuzzleBlock(
    shape: [
      [true, true, true],
      [false, true, false],
    ],
    color: Colors.green,
  ),
  // 4) Z Şekli (ya da S Block'un aynası)
  PuzzleBlock(
    shape: [
      [true, true, false],
      [false, true, true],
    ],
    color: Colors.orange,
  ),
  // 5) Yatay Çizgi (4 blok)
  PuzzleBlock(
    shape: [
      [true, true, true, true],
    ],
    color: Colors.purple,
  ),
  // 6) Artı (Plus) Şekli (3x3)
  PuzzleBlock(
    shape: [
      [false, true, false],
      [true, true, true],
      [false, true, false],
    ],
    color: Colors.teal,
  ),
  // 7) L Şekli
  PuzzleBlock(
    shape: [
      [true, false],
      [true, false],
      [true, true],
    ],
    color: Colors.brown,
  ),
  // 8) Ters L (Reverse L)
  PuzzleBlock(
    shape: [
      [false, true],
      [false, true],
      [true, true],
    ],
    color: Colors.pink,
  ),
  // 9) Tek Hücre (1x1)
  PuzzleBlock(
    shape: [
      [true],
    ],
    color: Colors.indigo,
  ),
  // --- EK ŞEKİLLER ---
  // 10) Dikey Çubuk (4 blok) - Tetris I parçasının dikey hali
  PuzzleBlock(
    shape: [
      [true],
      [true],
      [true],
      [true],
    ],
    color: Colors.cyan,
  ),
  // 11) S Şekli (Z şeklinin aynası)
  PuzzleBlock(
    shape: [
      [false, true, true],
      [true, true, false],
    ],
    color: Colors.deepOrange,
  ),
  // 12) 2x2 Köşe (Bir hücre eksik)
  PuzzleBlock(
    shape: [
      [true, true],
      [true, false],
    ],
    color: Colors.amber,
  ),
  // 13) Yatay Çizgi (3 blok)
  PuzzleBlock(
    shape: [
      [true, true, true],
    ],
    color: Colors.lime,
  ),
  // 14) U Şekli
  PuzzleBlock(
    shape: [
      [true, false, true],
      [true, true, true],
    ],
    color: Colors.deepPurple,
  ),
  // 15) W Şekli
  PuzzleBlock(
    shape: [
      [true, false],
      [true, true],
      [false, true],
    ],
    color: Colors.indigo,
  ),
  // 16) 3x3 Dolu Kare
  PuzzleBlock(
    shape: [
      [true, true, true],
      [true, true, true],
      [true, true, true],
    ],
    color: Colors.grey,
  ),
];
