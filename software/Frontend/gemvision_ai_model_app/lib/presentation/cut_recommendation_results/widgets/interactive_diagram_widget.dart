import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Interactive Diagram Widget
/// Displays cut diagram with rotation and zoom capabilities
class InteractiveDiagramWidget extends StatefulWidget {
  final Map<String, dynamic> cutData;
  final bool isCompact;

  const InteractiveDiagramWidget({
    super.key,
    required this.cutData,
    this.isCompact = false,
  });

  @override
  State<InteractiveDiagramWidget> createState() =>
      _InteractiveDiagramWidgetState();
}

class _InteractiveDiagramWidgetState extends State<InteractiveDiagramWidget> {
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _offset = Offset.zero;

  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _offset = details.focalPoint;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.8, 3.0);
      _rotation += details.rotation;
    });
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _rotation = 0.0;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(widget.isCompact ? 3.w : 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'view_in_ar',
                    color: theme.colorScheme.primary,
                    size: widget.isCompact ? 20 : 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Cut Diagram',
                    style:
                        (widget.isCompact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (!widget.isCompact)
                TextButton.icon(
                  onPressed: _resetTransform,
                  icon: CustomIconWidget(
                    iconName: 'refresh',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: Text(
                    'Reset',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),

          // Interactive diagram area
          GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: Container(
              height: widget.isCompact ? 25.h : 35.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background grid
                  CustomPaint(
                    size: Size.infinite,
                    painter: _GridPainter(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),

                  // Diagram image
                  Center(
                    child: Transform.rotate(
                      angle: _rotation,
                      child: Transform.scale(
                        scale: _scale,
                        child: CustomImageWidget(
                          imageUrl: widget.cutData["image"] as String,
                          width: widget.isCompact ? 30.w : 40.w,
                          height: widget.isCompact ? 30.w : 40.w,
                          fit: BoxFit.contain,
                          semanticLabel:
                              widget.cutData["semanticLabel"] as String,
                        ),
                      ),
                    ),
                  ),

                  // Gesture hint
                  if (!widget.isCompact)
                    Positioned(
                      bottom: 2.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'pinch',
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                size: 16,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Pinch to zoom • Rotate to turn',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!widget.isCompact) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControlButton(theme, 'Zoom In', 'zoom_in', () {
                  setState(() {
                    _scale = (_scale + 0.2).clamp(0.8, 3.0);
                  });
                }),
                _buildControlButton(theme, 'Zoom Out', 'zoom_out', () {
                  setState(() {
                    _scale = (_scale - 0.2).clamp(0.8, 3.0);
                  });
                }),
                _buildControlButton(theme, 'Rotate', 'rotate_right', () {
                  setState(() {
                    _rotation += 0.785398; // 45 degrees in radians
                  });
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton(
    ThemeData theme,
    String label,
    String iconName,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Grid Painter for diagram background
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const gridSpacing = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
