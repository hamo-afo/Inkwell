import 'package:flutter/material.dart';

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final Color color;
  final double borderRadius;

  const DottedBorderBox({
    required this.child,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashGap = 4,
    required this.color,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashGap: dashGap,
        color: color,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: child,
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final Color color;
  final double borderRadius;

  DottedBorderPainter({
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    _drawDottedRRect(canvas, rrect, paint);
  }

  void _drawDottedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    final pathMetrics = path.computeMetrics(forceClosed: false);

    for (var metric in pathMetrics) {
      double distance = 0;
      bool isDash = true;

      while (distance < metric.length) {
        double nextDistance = distance + (isDash ? dashWidth : dashGap);
        if (nextDistance > metric.length) {
          nextDistance = metric.length;
        }

        if (isDash) {
          final startTangent = metric.getTangentForOffset(distance);
          final endTangent = metric.getTangentForOffset(nextDistance);

          if (startTangent != null && endTangent != null) {
            dashPath.moveTo(startTangent.position.dx, startTangent.position.dy);
            dashPath.lineTo(endTangent.position.dx, endTangent.position.dy);
          }
        }

        distance = nextDistance;
        isDash = !isDash;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) => false;
}
