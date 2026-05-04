
//  gem_defect_map.dart


import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';


//  Main widget — loads image then renders boxes via CustomPaint

class GemDefectMap extends StatefulWidget {
  final Uint8List     imageBytes;
  final List          boundingBoxes;   // [[x1,y1,x2,y2], ...]
  final String        defectType;
  final double        confidence;      // 0.0 – 1.0
  final String        colorCode;       // hex e.g. "#FF6B6B"
  final List<int>     imageShape;      // [height, width, channels]
  final double?       height;

  const GemDefectMap({
    super.key,
    required this.imageBytes,
    required this.boundingBoxes,
    required this.defectType,
    required this.confidence,
    required this.colorCode,
    required this.imageShape,
    this.height,
  });

  @override
  State<GemDefectMap> createState() => _GemDefectMapState();
}

class _GemDefectMapState extends State<GemDefectMap> {
  ui.Image? _uiImage;
  bool      _loading = true;
  String?   _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = widget.imageBytes;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _uiImage = frame.image;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 320.0;

    if (_loading) {
      return SizedBox(
        height: h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _uiImage == null) {
      return SizedBox(
        height: h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Could not load image'),
            ],
          ),
        ),
      );
    }

    final color = _hexColor(widget.colorCode);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: CustomPaint(
          painter: _DefectBoxPainter(
            gemImage:     _uiImage!,
            boundingBoxes: widget.boundingBoxes,
            defectType:   widget.defectType,
            confidence:   widget.confidence,
            boxColor:     color,
            // model output image size (used for coordinate scaling)
            modelWidth:   widget.imageShape.length > 1
                ? widget.imageShape[1].toDouble()
                : 300.0,
            modelHeight:  widget.imageShape.isNotEmpty
                ? widget.imageShape[0].toDouble()
                : 300.0,
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.red;
    }
  }
}


//  CustomPainter — draws image + all bounding boxes + labels

class _DefectBoxPainter extends CustomPainter {
  final ui.Image  gemImage;
  final List      boundingBoxes;
  final String    defectType;
  final double    confidence;
  final Color     boxColor;
  final double    modelWidth;
  final double    modelHeight;

  _DefectBoxPainter({
    required this.gemImage,
    required this.boundingBoxes,
    required this.defectType,
    required this.confidence,
    required this.boxColor,
    required this.modelWidth,
    required this.modelHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Compute BoxFit.contain rect so image is not stretched
    // This ensures box coordinates map exactly to visible image pixels.
    final imgW = gemImage.width.toDouble();
    final imgH = gemImage.height.toDouble();
    final fitScale = (size.width / imgW).clamp(0.0, size.height / imgH);
    final drawW    = imgW * fitScale;
    final drawH    = imgH * fitScale;
    final offsetX  = (size.width  - drawW) / 2;
    final offsetY  = (size.height - drawH) / 2;
    final dstRect  = Rect.fromLTWH(offsetX, offsetY, drawW, drawH);
    final srcRect  = Rect.fromLTWH(0, 0, imgW, imgH);

    // Fill background black before drawing image
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );
    canvas.drawImageRect(gemImage, srcRect, dstRect, Paint());

    if (boundingBoxes.isEmpty) return;

    //  Scale factors: original image coords → widget pixels
    // Boxes are in original image space (same as modelWidth x modelHeight).
    // We scale them into the drawn image rect (which may have black bars).
    final scaleX = drawW / modelWidth;
    final scaleY = drawH / modelHeight;

    //Draw semi-transparent overlay over entire drawn image area
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.35);
    canvas.drawRect(dstRect, overlayPaint);

    for (int i = 0; i < boundingBoxes.length; i++) {
      final box = boundingBoxes[i] as List;
      if (box.length < 4) continue;

      // Convert from image coords to widget coords
      final x1 = offsetX + (box[0] as num).toDouble() * scaleX;
      final y1 = offsetY + (box[1] as num).toDouble() * scaleY;
      final x2 = offsetX + (box[2] as num).toDouble() * scaleX;
      final y2 = offsetY + (box[3] as num).toDouble() * scaleY;

      // Clamp to drawn image area
      final rx1 = x1.clamp(dstRect.left,   dstRect.right);
      final ry1 = y1.clamp(dstRect.top,    dstRect.bottom);
      final rx2 = x2.clamp(dstRect.left,   dstRect.right);
      final ry2 = y2.clamp(dstRect.top,    dstRect.bottom);

      if (rx2 - rx1 < 4 || ry2 - ry1 < 4) continue; // skip tiny boxes

      final rect = Rect.fromLTRB(rx1, ry1, rx2, ry2);

      //Restore image inside the defect box (remove overlay)
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawImageRect(gemImage, srcRect, dstRect, Paint());
      canvas.restore();

      //Animated pulsing border 
      // Outer glow
      canvas.drawRect(
        rect.inflate(3),
        Paint()
          ..color  = boxColor.withOpacity(0.35)
          ..style  = PaintingStyle.stroke
          ..strokeWidth = 6,
      );

      // Main border
      canvas.drawRect(
        rect,
        Paint()
          ..color       = boxColor
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Corner accents (like a targeting reticle)
      _drawCornerAccents(canvas, rect, boxColor);

      //  Label background + text 
      final label =
          '$defectType  ${(confidence * 100).toStringAsFixed(1)}%';
      _drawLabel(canvas, label, x1, y1, boxColor, i);
    }

    //"Defect Map" watermark in top-right 
    _drawWatermark(canvas, size);
  }

  // Draw corner L-shaped accents like a targeting scope
  void _drawCornerAccents(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color       = Colors.white
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap   = StrokeCap.round;

    const len = 12.0; // length of each corner arm

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0),  paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0,  len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0,  len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0),  paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0,  -len), paint);
  }

  void _drawLabel(Canvas canvas, String label,
      double x1, double y1, Color color, int index) {
    final tp = TextPainter(
      text: TextSpan(
        text: '  $label  ',
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelH  = tp.height + 6;
    final labelW  = tp.width;
    final labelY  = y1 > labelH + 4 ? y1 - labelH - 2 : y1 + 2;
    final labelX  = x1;

    // Badge background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelW, labelH),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = color);

    // Index circle
    final circleR = labelH / 2;
    canvas.drawCircle(
      Offset(labelX - circleR - 2, labelY + circleR),
      circleR,
      Paint()..color = Colors.white,
    );
    TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color:      color,
          fontSize:   9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(
          canvas,
          Offset(labelX - circleR * 1.7, labelY + circleR * 0.3));

    tp.paint(canvas, Offset(labelX, labelY + 3));
  }

  void _drawWatermark(Canvas canvas, Size size) {
    TextPainter(
      text: const TextSpan(
        text: 'GemScan Defect Map',
        style: TextStyle(
          color:    Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(size.width - 135, 8));
  }

  @override
  bool shouldRepaint(_DefectBoxPainter old) =>
      old.gemImage     != gemImage     ||
      old.boundingBoxes != boundingBoxes;
}

//  Fullscreen viewer — tap the map to open fullscreen

class GemDefectMapFullscreen extends StatelessWidget {
  final Uint8List imageBytes;
  final List      boundingBoxes;
  final String    defectType;
  final double    confidence;
  final String    colorCode;
  final List<int> imageShape;

  const GemDefectMapFullscreen({
    super.key,
    required this.imageBytes,
    required this.boundingBoxes,
    required this.defectType,
    required this.confidence,
    required this.colorCode,
    required this.imageShape,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '$defectType — Defect Map',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: GemDefectMap(
            imageBytes:   imageBytes,
            boundingBoxes: boundingBoxes,
            defectType:   defectType,
            confidence:   confidence,
            colorCode:    colorCode,
            imageShape:   imageShape,
            height:       MediaQuery.of(context).size.height * 0.85,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pinch, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              'Pinch to zoom  •  ${boundingBoxes.length} defect region(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}