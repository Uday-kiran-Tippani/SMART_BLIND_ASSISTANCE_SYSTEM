import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size widgetSize;
  final int rotation;

  ObjectPainter(this.objects, this.imageSize, this.widgetSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // Debugging print to ensure we are painting
    // debugPrint("Painting ${objects.length} objects");
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.lightGreenAccent;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.lightGreenAccent.withOpacity(0.1);
      
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (var object in objects) {
      // 1. Calculate scaling factors
      // Assuming camera preview covers the widget (BoxFit.cover)
      // and image is from portrait camera (rotated 90 deg relative to landscape sensor usually)
      
      // Standard rotation handling for MLKit is complex.
      // Simplified approach for portrait mode app on portrait device:
      // Image height -> Widget width
      // Image width -> Widget height
      // (Because sensor is rotated 90 deg)
      
      double scaleX = widgetSize.width / imageSize.height;
      double scaleY = widgetSize.height / imageSize.width;
      
      // Rect from MLKit is based on image coordinates
      final rect = object.boundingBox;
      
      // Transform rect based on rotation and scaling
      // For 90 deg rotation (common on Android portrait):
      // x' = y * scaleX
      // y' = x * scaleY
      // But we need to check mirror/orientation properly.
      // Let's assume standard behavior for now.
      
      final left = rect.top * scaleX;
      final top = rect.left * scaleY;
      final width = rect.height * scaleX;
      final height = rect.width * scaleY;
      
      // Draw Bounding Box
      final drawRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(drawRect, paint);
      canvas.drawRect(drawRect, fillPaint);
      
      // Draw Label
      if (object.labels.isNotEmpty) {
        final label = object.labels.first.text;
        final confidence = (object.labels.first.confidence * 100).toStringAsFixed(0);
        
        textPainter.text = TextSpan(
          text: '$label $confidence%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(left, top - textPainter.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
