import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';

Future<void> generateAppIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(1024, 1024);
  
  // Draw background
  final paint = Paint()
    ..color = const Color(0xFF2196F3) // Material Blue
    ..style = PaintingStyle.fill;
  canvas.drawRect(Offset.zero & size, paint);
  
  // Draw grid
  final gridPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20;
  
  // Draw 3x3 grid
  for (int i = 0; i < 4; i++) {
    double pos = size.width / 3 * i;
    canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
    canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
  }
  
  // Draw numbers
  final textStyle = TextStyle(
    color: Colors.white,
    fontSize: 200,
    fontWeight: FontWeight.bold,
  );
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  
  // Draw sample numbers (1, 5, 9 for a clean look)
  final numbers = ['1', '5', '9'];
  final positions = [
    Offset(size.width / 6, size.height / 6),
    Offset(size.width / 2, size.height / 2),
    Offset(size.width * 5/6, size.height * 5/6),
  ];
  
  for (int i = 0; i < numbers.length; i++) {
    textPainter.text = TextSpan(text: numbers[i], style: textStyle);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        positions[i].dx - textPainter.width / 2,
        positions[i].dy - textPainter.height / 2,
      ),
    );
  }
  
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save the main icon
  final iconFile = File('assets/icon/icon.png');
  await iconFile.parent.create(recursive: true);
  await iconFile.writeAsBytes(buffer);
  
  // Save the foreground icon (same as main icon for now)
  final foregroundFile = File('assets/icon/icon_foreground.png');
  await foregroundFile.writeAsBytes(buffer);
  
  print('Icons generated at: ${iconFile.path} and ${foregroundFile.path}');
} 