import 'dart:math';

import 'package:flutter/material.dart';
import 'package:puzzle_cube/puzzleblock.dart';

/// PuzzleBoard: rows x cols boyutunda board oluşturur; blok yerleştirme, dolu satır/sütun kontrolü yapar.
class PuzzleBoard {
  final int rows;
  final int cols;
  final List<List<Color?>> grid;
  final Set<Offset> obstacles = {};
  PuzzleBoard({
    this.rows = 8,
    this.cols = 8,
  }) : grid = List.generate(
          rows,
          (_) => List.generate(cols, (_) => null),
        );

  void addObstacles(int count, {Random? random}) {
    random ??= Random();
    for (int i = 0; i < count; i++) {
      int row = random.nextInt(rows);
      int col = random.nextInt(cols);
      // Eğer bu konumda zaten engel yoksa ekleyelim:
      Offset pos = Offset(row.toDouble(), col.toDouble());
      if (!obstacles.contains(pos)) {
        obstacles.add(pos);
        grid[row][col] = Colors.grey; // veya engel için başka bir renk/işaret
      }
    }
  }

  bool isCellObstacle(int row, int col) =>
      obstacles.contains(Offset(row.toDouble(), col.toDouble()));

  bool canPlaceBlock(PuzzleBlock block, int row, int col) {
    if (row + block.rows > rows || col + block.cols > cols) {
      print(
          "Sınır aşılıyor: row=$row, col=$col, block: ${block.rows}x${block.cols}");
      return false;
    }
    for (int r = 0; r < block.rows; r++) {
      for (int c = 0; c < block.cols; c++) {
        if (block.shape[r][c] && grid[row + r][col + c] != null) {
          return false;
        }
      }
    }
    return true;
  }

  bool placeBlock(PuzzleBlock block, int row, int col) {
    if (!canPlaceBlock(block, row, col)) return false;
    for (int r = 0; r < block.rows; r++) {
      for (int c = 0; c < block.cols; c++) {
        if (block.shape[r][c]) {
          grid[row + r][col + c] = block.color;
        }
      }
    }
    return true;
  }

  List<int> findFullRows() {
    List<int> fullRows = [];
    for (int r = 0; r < rows; r++) {
      if (grid[r].every((cell) => cell != null)) {
        fullRows.add(r);
      }
    }
    return fullRows;
  }

  List<int> findFullCols() {
    List<int> fullCols = [];
    for (int c = 0; c < cols; c++) {
      bool full = true;
      for (int r = 0; r < rows; r++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }
    return fullCols;
  }

  // In your PuzzleBoard class:
  void clearFullRows(List<int> rows) {
    for (int row in rows) {
      for (int col = 0; col < grid[row].length; col++) {
        grid[row][col] = null; // or any value that indicates an empty cell
      }
    }
    // Optionally, call a callback or trigger a rebuild if needed.
  }

  void clearFullCols(List<int> cols) {
    for (int col in cols) {
      for (int row = 0; row < grid.length; row++) {
        grid[row][col] = null;
      }
    }
  }
}
