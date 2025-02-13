import 'dart:ui';

/// Her bir PuzzleBlock; 2D bir harita tutar.
/// Örneğin 3x3'lük bir blok tanımı şu şekil olabilir:
/// [
///   [true, true, true],
///   [false, true, false],
///   [false, false, false],
/// ]
class PuzzleBlock {
  final List<List<bool>> shape;
  final Color color;

  PuzzleBlock({
    required this.shape,
    required this.color,
  });

  /// Blok yüksekliği
  int get rows => shape.length;

  /// Blok genişliği
  int get cols => shape.isNotEmpty ? shape[0].length : 0;
}
