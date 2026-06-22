import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingPoint {
  final double x;
  final double y;

  DrawingPoint(this.x, this.y);

  Offset toOffset() => Offset(x, y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final int colorValue;
  final double strokeWidth;
  final String tool; // 'Pen', 'Eraser', 'Circle', 'Rectangle', 'Line', 'Move', 'Text Box', 'prefab:[name]', 'text:[val]'

  DrawingStroke({
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
    required this.tool,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
        'tool': tool,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p))
          .toList(),
      colorValue: json['colorValue'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      tool: json['tool'] ?? 'Pen',
    );
  }
}

class DrawingController extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStrokes = [];
  final Map<String, ui.Image> imageCache = {};

  Future<void> cacheImage(String source) async {
    if (imageCache.containsKey(source)) return;
    try {
      Uint8List bytes;
      if (source.startsWith('data:image/')) {
        final cleanBase64 = source.split(',').last;
        bytes = base64Decode(cleanBase64);
      } else {
        bytes = base64Decode(source);
      }
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      imageCache[source] = frame.image;
      notifyListeners();
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }

  void addImageStroke(String base64Str) {
    _redoStrokes.clear();
    const double defaultW = 250;
    const double defaultH = 180;
    const double startX = 100;
    const double startY = 100;
    _strokes.add(DrawingStroke(
      points: [
        DrawingPoint(startX, startY),
        DrawingPoint(startX + defaultW, startY + defaultH),
      ],
      colorValue: currentColor.value,
      strokeWidth: currentWidth,
      tool: 'image:$base64Str',
    ));
    cacheImage(base64Str);
    notifyListeners();
  }

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);

  Color currentColor = Colors.black;
  double currentWidth = 4.0;
  String currentTool = 'Pen'; 

  DrawingStroke? _activeStroke;
  DrawingStroke? selectedStroke;
  bool isResizingSelected = false;

  void startStroke(Offset point) {
    _redoStrokes.clear();
    selectedStroke = null;
    isResizingSelected = false;

    if (currentTool == 'Move') {
      selectStrokeAt(point);
      return;
    }

    _activeStroke = DrawingStroke(
      points: [DrawingPoint(point.dx, point.dy)],
      colorValue: currentTool == 'Eraser' ? Colors.white.value : currentColor.value,
      strokeWidth: currentWidth,
      tool: currentTool,
    );
    _strokes.add(_activeStroke!);
    notifyListeners();
  }

  void updateStroke(Offset point) {
    if (currentTool == 'Move') {
      return; // Handled by dragSelected in panning gestures
    }
    if (_activeStroke == null) return;
    
    if (_activeStroke!.tool == 'Pen' || _activeStroke!.tool == 'Eraser') {
      _activeStroke!.points.add(DrawingPoint(point.dx, point.dy));
    } else {
      if (_activeStroke!.points.length > 1) {
        _activeStroke!.points.removeLast();
      }
      _activeStroke!.points.add(DrawingPoint(point.dx, point.dy));
    }
    notifyListeners();
  }

  void endStroke() {
    _activeStroke = null;
    notifyListeners();
  }

  void selectStrokeAt(Offset point) {
    selectedStroke = null;
    isResizingSelected = false;

    for (var i = _strokes.length - 1; i >= 0; i--) {
      final s = _strokes[i];
      if (s.tool.startsWith('prefab:') || s.tool.startsWith('text:')) {
        final rect = Rect.fromPoints(s.points.first.toOffset(), s.points.last.toOffset());
        
        // Check for resize handle at bottom-right corner (within 24px)
        final br = s.points.last.toOffset();
        if ((point - br).distance < 24) {
          selectedStroke = s;
          isResizingSelected = true;
          notifyListeners();
          return;
        }

        if (rect.contains(point)) {
          selectedStroke = s;
          notifyListeners();
          return;
        }
      }
    }
    notifyListeners();
  }

  void dragSelected(Offset delta) {
    if (selectedStroke == null) return;
    final idx = _strokes.indexOf(selectedStroke!);
    if (idx == -1) return;

    final s = selectedStroke!;
    if (isResizingSelected) {
      final newLast = DrawingPoint(s.points.last.x + delta.dx, s.points.last.y + delta.dy);
      _strokes[idx] = DrawingStroke(
        points: [s.points.first, newLast],
        colorValue: s.colorValue,
        strokeWidth: s.strokeWidth,
        tool: s.tool,
      );
      selectedStroke = _strokes[idx];
    } else {
      final newPoints = s.points
          .map((p) => DrawingPoint(p.x + delta.dx, p.y + delta.dy))
          .toList();
      _strokes[idx] = DrawingStroke(
        points: newPoints,
        colorValue: s.colorValue,
        strokeWidth: s.strokeWidth,
        tool: s.tool,
      );
      selectedStroke = _strokes[idx];
    }
    notifyListeners();
  }

  void addTextStroke(Offset point, String text) {
    _redoStrokes.clear();
    // Default dimensions for a text box (150x40)
    _strokes.add(DrawingStroke(
      points: [
        DrawingPoint(point.dx, point.dy),
        DrawingPoint(point.dx + 150, point.dy + 40),
      ],
      colorValue: currentColor.value,
      strokeWidth: currentWidth,
      tool: 'text:$text',
    ));
    notifyListeners();
  }

  void editTextStroke(DrawingStroke stroke, String newText) {
    final idx = _strokes.indexOf(stroke);
    if (idx != -1) {
      _strokes[idx] = DrawingStroke(
        points: stroke.points,
        colorValue: stroke.colorValue,
        strokeWidth: stroke.strokeWidth,
        tool: 'text:$newText',
      );
      if (selectedStroke == stroke) {
        selectedStroke = _strokes[idx];
      }
      notifyListeners();
    }
  }

  void addPrefabStroke(String name) {
    _redoStrokes.clear();
    // Center of canvas page default positioning
    const double defaultW = 160;
    const double defaultH = 120;
    const double startX = 100;
    const double startY = 100;
    _strokes.add(DrawingStroke(
      points: [
        DrawingPoint(startX, startY),
        DrawingPoint(startX + defaultW, startY + defaultH),
      ],
      colorValue: currentColor.value,
      strokeWidth: 2.0,
      tool: 'prefab:$name',
    ));
    notifyListeners();
  }

  void addDroppedPrefab(String name, Offset point) {
    _redoStrokes.clear();
    const double defaultW = 160;
    const double defaultH = 120;
    _strokes.add(DrawingStroke(
      points: [
        DrawingPoint(point.dx - defaultW / 2, point.dy - defaultH / 2),
        DrawingPoint(point.dx + defaultW / 2, point.dy + defaultH / 2),
      ],
      colorValue: currentColor.value,
      strokeWidth: 2.0,
      tool: 'prefab:$name',
    ));
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStrokes.add(_strokes.removeLast());
      selectedStroke = null;
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStrokes.isNotEmpty) {
      _strokes.add(_redoStrokes.removeLast());
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _redoStrokes.clear();
    _activeStroke = null;
    selectedStroke = null;
    notifyListeners();
  }

  void removeStroke(DrawingStroke stroke) {
    _strokes.remove(stroke);
    if (selectedStroke == stroke) {
      selectedStroke = null;
    }
    notifyListeners();
  }

  String getStrokesJson() {
    final list = _strokes.map((s) => s.toJson()).toList();
    return jsonEncode(list);
  }

  void loadStrokesFromJson(String jsonStr) {
    try {
      if (jsonStr.isEmpty) {
        clear();
        return;
      }
      final List decoded = jsonDecode(jsonStr);
      _strokes.clear();
      _redoStrokes.clear();
      selectedStroke = null;
      for (var item in decoded) {
        final stroke = DrawingStroke.fromJson(item);
        _strokes.add(stroke);
        if (stroke.tool.startsWith('image:')) {
          cacheImage(stroke.tool.substring(6));
        }
      }
      notifyListeners();
    } catch (_) {
      clear();
    }
  }
}

class CustomDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? selectedStroke;
  final Map<String, ui.Image> imageCache;

  CustomDrawingPainter(this.strokes, {this.selectedStroke, required this.imageCache});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.isEmpty) continue;

      if (stroke.tool == 'Pen' || stroke.tool == 'Eraser') {
        final path = Path();
        path.moveTo(stroke.points.first.x, stroke.points.first.y);
        for (var i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].x, stroke.points[i].y);
        }
        canvas.drawPath(path, paint);
      } else if (stroke.tool == 'Line') {
        if (stroke.points.length > 1) {
          canvas.drawLine(
            stroke.points.first.toOffset(),
            stroke.points.last.toOffset(),
            paint,
          );
        }
      } else if (stroke.tool == 'Circle') {
        if (stroke.points.length > 1) {
          final rect = Rect.fromPoints(
            stroke.points.first.toOffset(),
            stroke.points.last.toOffset(),
          );
          canvas.drawOval(rect, paint);
        }
      } else if (stroke.tool == 'Rectangle') {
        if (stroke.points.length > 1) {
          final rect = Rect.fromPoints(
            stroke.points.first.toOffset(),
            stroke.points.last.toOffset(),
          );
          canvas.drawRect(rect, paint);
        }
      } else if (stroke.tool.startsWith('prefab:')) {
        if (stroke.points.length > 1) {
          final name = stroke.tool.substring(7);
          final rect = Rect.fromPoints(
            stroke.points.first.toOffset(),
            stroke.points.last.toOffset(),
          );
          _drawPrefab(canvas, rect, name, paint);
        }
      } else if (stroke.tool.startsWith('image:')) {
        if (stroke.points.length > 1) {
          final source = stroke.tool.substring(6);
          final rect = Rect.fromPoints(
            stroke.points.first.toOffset(),
            stroke.points.last.toOffset(),
          );
          final cachedImg = imageCache[source];
          if (cachedImg != null) {
            final srcRect = Rect.fromLTWH(0, 0, cachedImg.width.toDouble(), cachedImg.height.toDouble());
            canvas.drawImageRect(cachedImg, srcRect, rect, Paint());
          } else {
            final dashPaint = Paint()
              ..color = Colors.grey
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;
            canvas.drawRect(rect, dashPaint);
            const textStyle = TextStyle(color: Colors.grey, fontSize: 10);
            final textSpan = TextSpan(text: 'Loading Image...', style: textStyle);
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            )..layout();
            textPainter.paint(
              canvas,
              Offset(
                rect.center.dx - textPainter.width / 2,
                rect.center.dy - textPainter.height / 2,
              ),
            );
          }
        }
      } else if (stroke.tool.startsWith('text:')) {
        final text = stroke.tool.substring(5);
        final textStyle = TextStyle(
          color: stroke.color,
          fontSize: stroke.strokeWidth * 4.0 + 8.0,
          fontWeight: FontWeight.w500,
        );
        final textSpan = TextSpan(text: text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, stroke.points.first.toOffset());
      }

      // Draw active selected bounding outline
      if (stroke == selectedStroke) {
        final selectPaint = Paint()
          ..color = Colors.blueAccent.withOpacity(0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        final rect = Rect.fromPoints(
          stroke.points.first.toOffset(),
          stroke.points.last.toOffset(),
        );
        canvas.drawRect(rect, selectPaint);
        
        // Draw resize drag handle corner box
        final handlePaint = Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(stroke.points.last.toOffset(), 5.0, handlePaint);
      }
    }
    canvas.restore();
  }

  void _drawAxes(Canvas canvas, Rect rect, Paint paint) {
    // horizontal axis
    canvas.drawLine(
        Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), paint);
    // arrow right
    canvas.drawLine(Offset(rect.right - 8, rect.center.dy - 5),
        Offset(rect.right, rect.center.dy), paint);
    canvas.drawLine(Offset(rect.right - 8, rect.center.dy + 5),
        Offset(rect.right, rect.center.dy), paint);

    // vertical axis
    canvas.drawLine(
        Offset(rect.center.dx, rect.bottom), Offset(rect.center.dx, rect.top), paint);
    // arrow top
    canvas.drawLine(
        Offset(rect.center.dx - 5, rect.top + 8), Offset(rect.center.dx, rect.top), paint);
    canvas.drawLine(
        Offset(rect.center.dx + 5, rect.top + 8), Offset(rect.center.dx, rect.top), paint);
  }

  void _drawPrefab(Canvas canvas, Rect rect, String name, Paint paint) {
    if (name == 'axes') {
      _drawAxes(canvas, rect, paint);
    } else if (name == 'sine') {
      _drawAxes(canvas, rect, paint);
      final path = Path();
      final double startX = rect.left + 5;
      final double endX = rect.right - 5;
      final double centerY = rect.center.dy;
      final double amplitude = rect.height * 0.3;
      path.moveTo(startX, centerY);
      for (double x = startX; x <= endX; x++) {
        final double t = (x - startX) / (endX - startX);
        final double y = centerY - sin(t * 2 * pi * 1.5) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    } else if (name == 'cosine') {
      _drawAxes(canvas, rect, paint);
      final path = Path();
      final double startX = rect.left + 5;
      final double endX = rect.right - 5;
      final double centerY = rect.center.dy;
      final double amplitude = rect.height * 0.3;
      path.moveTo(startX, centerY - amplitude);
      for (double x = startX; x <= endX; x++) {
        final double t = (x - startX) / (endX - startX);
        final double y = centerY - cos(t * 2 * pi * 1.5) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    } else if (name == 'parabola') {
      _drawAxes(canvas, rect, paint);
      final path = Path();
      final double startX = rect.left + 5;
      final double endX = rect.right - 5;
      final double centerY = rect.bottom - 10;
      final double amplitude = rect.height * 0.6;
      path.moveTo(startX, rect.top + 10);
      for (double x = startX; x <= endX; x++) {
        final double t = (x - rect.center.dx) / (rect.width * 0.4);
        final double y = centerY - (t * t) * amplitude;
        if (y >= rect.top) {
          if (x == startX) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
      canvas.drawPath(path, paint);
    } else if (name == 'bell') {
      _drawAxes(canvas, rect, paint);
      final path = Path();
      final double startX = rect.left + 5;
      final double endX = rect.right - 5;
      final double centerY = rect.bottom - 10;
      final double peakY = rect.top + 10;
      final double height = centerY - peakY;
      path.moveTo(startX, centerY);
      for (double x = startX; x <= endX; x++) {
        final double t = (x - rect.center.dx) / (rect.width * 0.25);
        final double y = centerY - exp(-t * t) * height;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    } else if (name == 'exponential') {
      _drawAxes(canvas, rect, paint);
      final path = Path();
      final double startX = rect.left + 5;
      final double endX = rect.right - 5;
      final double centerY = rect.bottom - 10;
      path.moveTo(startX, centerY - 2);
      for (double x = startX; x <= endX; x++) {
        final double t = (x - startX) / (endX - startX);
        final double y = centerY - pow(2.0, t * 4.0) / 16.0 * (rect.height * 0.7);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    } else if (name == 'cube') {
      final double size = min(rect.width, rect.height) * 0.65;
      final double offset = size * 0.35;
      final rect1 = Rect.fromLTWH(rect.left, rect.top + offset, size, size);
      final rect2 = Rect.fromLTWH(rect.left + offset, rect.top, size, size);
      canvas.drawRect(rect1, paint);
      canvas.drawRect(rect2, paint);
      canvas.drawLine(rect1.topLeft, rect2.topLeft, paint);
      canvas.drawLine(rect1.topRight, rect2.topRight, paint);
      canvas.drawLine(rect1.bottomLeft, rect2.bottomLeft, paint);
      canvas.drawLine(rect1.bottomRight, rect2.bottomRight, paint);
    } else if (name == 'cylinder') {
      final double h = rect.height * 0.75;
      final double ry = rect.height * 0.08;
      final topOval = Rect.fromLTWH(rect.left, rect.top, rect.width, ry * 2);
      canvas.drawOval(topOval, paint);
      canvas.drawLine(Offset(rect.left, rect.top + ry), Offset(rect.left, rect.top + ry + h), paint);
      canvas.drawLine(
          Offset(rect.right, rect.top + ry), Offset(rect.right, rect.top + ry + h), paint);
      final path = Path()
        ..moveTo(rect.left, rect.top + ry + h)
        ..quadraticBezierTo(
            rect.center.dx, rect.top + ry + h + ry * 2, rect.right, rect.top + ry + h);
      canvas.drawPath(path, paint);
    } else if (name == 'sphere') {
      final double rx = rect.width * 0.45;
      final double ry = rect.height * 0.15;
      canvas.drawCircle(rect.center, rx, paint);
      canvas.drawOval(
          Rect.fromLTRB(rect.center.dx - rx, rect.center.dy - ry, rect.center.dx + rx,
              rect.center.dy + ry),
          paint);
    } else if (name == 'human') {
      final double cx = rect.center.dx;
      final double headR = rect.width * 0.12;
      canvas.drawCircle(Offset(cx, rect.top + headR), headR, paint);
      final double neckY = rect.top + headR * 2;
      final double waistY = rect.top + rect.height * 0.55;
      canvas.drawLine(Offset(cx, neckY), Offset(cx, waistY), paint); // spine
      canvas.drawLine(Offset(cx, neckY + 8), Offset(rect.left, neckY + 18), paint); // left arm
      canvas.drawLine(
          Offset(cx, neckY + 8), Offset(rect.right, neckY + 18), paint); // right arm
      canvas.drawLine(Offset(cx, waistY), Offset(rect.left + 8, rect.bottom), paint); // left leg
      canvas.drawLine(
          Offset(cx, waistY), Offset(rect.right - 8, rect.bottom), paint); // right leg
    } else if (name == 'database') {
      final double h = rect.height * 0.22;
      final double ry = rect.height * 0.05;
      for (int i = 0; i < 3; i++) {
        final double yOffset = rect.top + i * (h + 5);
        final topOval = Rect.fromLTWH(rect.left, yOffset, rect.width, ry * 2);
        canvas.drawOval(topOval, paint);
        canvas.drawLine(
            Offset(rect.left, yOffset + ry), Offset(rect.left, yOffset + ry + h), paint);
        canvas.drawLine(
            Offset(rect.right, yOffset + ry), Offset(rect.right, yOffset + ry + h), paint);
        final path = Path()
          ..moveTo(rect.left, yOffset + ry + h)
          ..quadraticBezierTo(
              rect.center.dx, yOffset + ry + h + ry * 2, rect.right, yOffset + ry + h);
        canvas.drawPath(path, paint);
      }
    } else if (name == 'laptop') {
      final double screenH = rect.height * 0.65;
      final screenRect =
          Rect.fromLTRB(rect.left + 10, rect.top, rect.right - 10, rect.top + screenH);
      canvas.drawRect(screenRect, paint);
      final path = Path()
        ..moveTo(rect.left + 10, rect.top + screenH)
        ..lineTo(rect.left, rect.bottom - 5)
        ..lineTo(rect.right, rect.bottom - 5)
        ..lineTo(rect.right - 10, rect.top + screenH)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(Offset(rect.left + 12, rect.bottom - 8),
          Offset(rect.right - 12, rect.bottom - 8), paint);
    } else if (name == 'cloud') {
      final path = Path()
        ..moveTo(rect.left + rect.width * 0.2, rect.bottom - 10)
        ..quadraticBezierTo(rect.left, rect.bottom - 25, rect.left + rect.width * 0.25,
            rect.bottom - 42)
        ..quadraticBezierTo(
            rect.center.dx, rect.top - 5, rect.right - rect.width * 0.25, rect.bottom - 42)
        ..quadraticBezierTo(
            rect.right, rect.bottom - 25, rect.right - rect.width * 0.2, rect.bottom - 10)
        ..close();
      canvas.drawPath(path, paint);
    } else if (name == 'code') {
      final leftPath = Path()
        ..moveTo(rect.center.dx - 10, rect.top + 10)
        ..lineTo(rect.left + 5, rect.center.dy)
        ..lineTo(rect.center.dx - 10, rect.bottom - 10);
      canvas.drawPath(leftPath, paint);
      canvas.drawLine(Offset(rect.center.dx - 3, rect.bottom - 5),
          Offset(rect.center.dx + 3, rect.top + 5), paint);
      final rightPath = Path()
        ..moveTo(rect.center.dx + 10, rect.top + 10)
        ..lineTo(rect.right - 5, rect.center.dy)
        ..lineTo(rect.center.dx + 10, rect.bottom - 10);
      canvas.drawPath(rightPath, paint);
    } else if (name == 'network') {
      final Offset n1 = Offset(rect.center.dx, rect.top + 15);
      final Offset n2 = Offset(rect.left + 20, rect.center.dy + 10);
      final Offset n3 = Offset(rect.right - 20, rect.center.dy + 10);
      final Offset n4 = Offset(rect.center.dx, rect.bottom - 15);
      canvas.drawLine(n1, n2, paint);
      canvas.drawLine(n1, n3, paint);
      canvas.drawLine(n2, n4, paint);
      canvas.drawLine(n3, n4, paint);
      canvas.drawLine(n2, n3, paint);
      
      final nodePaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(n1, 5, nodePaint);
      canvas.drawCircle(n2, 5, nodePaint);
      canvas.drawCircle(n3, 5, nodePaint);
      canvas.drawCircle(n4, 5, nodePaint);
    } else if (name == 'server') {
      final double h = rect.height * 0.25;
      for (int i = 0; i < 3; i++) {
        final double y = rect.top + i * (h + 5);
        final serverRect = Rect.fromLTWH(rect.left, y, rect.width, h);
        canvas.drawRect(serverRect, paint);
        
        final nodePaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(rect.left + 12, y + h / 2), 2.5, nodePaint);
        canvas.drawCircle(Offset(rect.left + 20, y + h / 2), 2.5, nodePaint);
        canvas.drawLine(Offset(rect.left + 35, y + h / 2), Offset(rect.right - 10, y + h / 2), paint);
      }
    } else if (name == 'table_classic') {
      canvas.drawRect(rect, paint);
      canvas.drawLine(Offset(rect.left, rect.top + 22), Offset(rect.right, rect.top + 22), paint);
      
      final tpTitle = TextPainter(
        text: const TextSpan(
          text: 'DB_USERS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpTitle.paint(canvas, Offset(rect.left + 8, rect.top + 6));

      final tpFields = TextPainter(
        text: const TextSpan(
          text: '🔑 id : INT\n👤 name : VARCHAR\n✉️ email : VARCHAR',
          style: TextStyle(color: Colors.black87, fontSize: 8.5, height: 1.4),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpFields.paint(canvas, Offset(rect.left + 8, rect.top + 28));
    } else if (name == 'table_data') {
      canvas.drawRect(rect, paint);
      canvas.drawLine(Offset(rect.left, rect.top + 18), Offset(rect.right, rect.top + 18), paint);
      canvas.drawLine(Offset(rect.left, rect.top + 36), Offset(rect.right, rect.top + 36), paint);
      canvas.drawLine(Offset(rect.left, rect.top + 54), Offset(rect.right, rect.top + 54), paint);
      final double colWidth = rect.width / 3;
      canvas.drawLine(
          Offset(rect.left + colWidth, rect.top), Offset(rect.left + colWidth, rect.bottom), paint);
      canvas.drawLine(Offset(rect.left + colWidth * 2, rect.top),
          Offset(rect.left + colWidth * 2, rect.bottom), paint);
    } else if (name == 'uml_class') {
      canvas.drawRect(rect, paint);
      canvas.drawLine(Offset(rect.left, rect.top + 20), Offset(rect.right, rect.top + 20), paint);
      canvas.drawLine(
          Offset(rect.left, rect.bottom - 30), Offset(rect.right, rect.bottom - 30), paint);

      final tpClass = TextPainter(
        text: const TextSpan(
          text: 'Class Student',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpClass.paint(canvas, Offset(rect.center.dx - tpClass.width / 2, rect.top + 4));

      final tpAttrs = TextPainter(
        text: const TextSpan(
          text: '- name: String\n- id: int',
          style: TextStyle(color: Colors.black87, fontSize: 8.5, height: 1.3),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpAttrs.paint(canvas, Offset(rect.left + 8, rect.top + 24));

      final tpMethods = TextPainter(
        text: const TextSpan(
          text: '+ enroll(): void\n+ study(): void',
          style: TextStyle(color: Colors.black87, fontSize: 8.5, height: 1.3),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpMethods.paint(canvas, Offset(rect.left + 8, rect.bottom - 26));
    } else if (name == 'flow_start') {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), paint);
      final tp = TextPainter(
        text: const TextSpan(
          text: 'START / END',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    } else if (name == 'flow_process') {
      canvas.drawRect(rect, paint);
      final tp = TextPainter(
        text: const TextSpan(
          text: 'PROCESS STEP',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    } else if (name == 'flow_decision') {
      final path = Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
      canvas.drawPath(path, paint);
      final tp = TextPainter(
        text: const TextSpan(
          text: 'DECISION',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomDrawingPainter oldDelegate) => true;
}
