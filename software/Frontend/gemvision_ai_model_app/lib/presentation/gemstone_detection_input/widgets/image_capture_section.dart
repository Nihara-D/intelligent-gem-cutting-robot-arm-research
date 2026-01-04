import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ImageCaptureSection extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isInitializing;
  final XFile? capturedImage;
  final VoidCallback onCapturePhoto;
  final VoidCallback onChooseFromGallery;
  final VoidCallback onRetakePhoto;

  const ImageCaptureSection({
    super.key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.isInitializing,
    required this.capturedImage,
    required this.onCapturePhoto,
    required this.onChooseFromGallery,
    required this.onRetakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemstone Image',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Capture or upload a clear image',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Camera preview or captured image
          capturedImage != null
              ? _buildCapturedImage(context, theme)
              : _buildCameraPreview(context, theme),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(4.w),
            child: capturedImage != null
                ? _buildRetakeButton(theme)
                : _buildCaptureButtons(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context, ThemeData theme) {
    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isInitializing
            ? _buildLoadingState(theme)
            : isCameraInitialized && cameraController != null
            ? Stack(
                children: [
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width:
                            cameraController!.value.previewSize?.height ?? 100,
                        height:
                            cameraController!.value.previewSize?.width ?? 100,
                        child: CameraPreview(cameraController!),
                      ),
                    ),
                  ),
                  _buildCameraOverlay(theme),
                ],
              )
            : _buildCameraUnavailable(theme),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Initializing camera...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUnavailable(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'camera_alt_outlined',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Camera not available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Please use gallery to upload image',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: _CameraGuidelinePainter(
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildCapturedImage(BuildContext context, ThemeData theme) {
    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            SizedBox.expand(
              child: kIsWeb
                  ? Image.network(capturedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(capturedImage!.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: 2.h,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Image Captured',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCapturePhoto,
            icon: CustomIconWidget(
              iconName: 'camera_alt',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            label: Text('Take Photo'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.6.h),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onChooseFromGallery,
            icon: CustomIconWidget(
              iconName: 'photo_library',
              color: Colors.white,
              size: 20,
            ),
            label: Text('Gallery'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.6.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetakeButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onRetakePhoto,
        icon: CustomIconWidget(
          iconName: 'refresh',
          color: theme.colorScheme.primary,
          size: 20,
        ),
        label: Text('Retake Photo'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.6.h),
          side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// Custom painter for camera guidelines
class _CameraGuidelinePainter extends CustomPainter {
  final Color color;

  _CameraGuidelinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double cornerLength = size.width * 0.1;
    final double margin = size.width * 0.15;

    // Top-left corner
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      paint,
    );

    // Center crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = size.width * 0.05;

    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
