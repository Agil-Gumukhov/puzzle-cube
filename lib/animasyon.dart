
import 'package:flutter/material.dart';

class ExplosionPainter extends CustomPainter {
  final double animationValue; // 0.0 -> 1.0
  final Set<Offset> explodingCells;
  final double cellWidth;
  final double cellHeight;

  ExplosionPainter({
    required this.animationValue,
    required this.explodingCells,
    required this.cellWidth,
    required this.cellHeight,
  });

@override
void paint(Canvas canvas, Size size) {
  if (explodingCells.isEmpty) return;
  for (final offset in explodingCells) {
    // Hücre koordinatlarını hesaplayalım (satır ve sütun)
    double row = offset.dx;
    double col = offset.dy;
    double centerX = (col + 0.5) * cellWidth;
    double centerY = (row + 0.5) * cellHeight;
    
    // Maksimum yarıçapı biraz büyütüyoruz
    final double maxRadius = cellWidth * 1.5;
    final double radius = maxRadius * animationValue;
    final Rect circleRect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
    
    final Gradient gradient = RadialGradient(
      colors: [Colors.yellow, Colors.transparent],
      stops: [0.0, 1.0],
    );
    final Paint paint = Paint()
      ..shader = gradient.createShader(circleRect);
      // BlendMode.plus bazen çok hafif gösterebilir; eğer görünmüyorsa aşağıdaki satırı kaldırıp test edin:
      // ..blendMode = BlendMode.plus;
    
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }
}

  @override
  bool shouldRepaint(ExplosionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.explodingCells != explodingCells;
  }
}