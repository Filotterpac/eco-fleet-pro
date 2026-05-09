import 'package:flutter/material.dart';

class RoadProfilePainter extends CustomPainter {
  final double slope1;
  final double slope2;
  RoadProfilePainter(this.slope1, this.slope2);

  @override
  void paint(Canvas canvas, Size size) {
    final paintRoad = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paintCar = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double startY = size.height / 2;
    double y1 = startY - (slope1 * 4);
    double y2 = y1 - (slope2 * 4);

    Path path = Path();
    path.moveTo(20, startY);
    path.lineTo(midX, y1);
    path.lineTo(size.width - 20, y2);
    canvas.drawPath(path, paintRoad);

    double carX = (20 + midX) / 2;
    double carY = (startY + y1) / 2;
    canvas.drawCircle(Offset(carX, carY), 5, paintCar);
    
    canvas.drawLine(Offset(midX, 10), Offset(midX, size.height - 10), 
        Paint()..color = Colors.grey.withOpacity(0.3)..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}