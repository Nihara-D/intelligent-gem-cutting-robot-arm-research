
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/image_capture_section.dart';
import './widgets/scientific_properties_section.dart';

class GemstoneDetectionInput extends StatefulWidget {
  const GemstoneDetectionInput({super.key});

  @override
  State<GemstoneDetectionInput> createState() => _GemstoneDetectionInputState();
}

class _GemstoneDetectionInputState extends State<GemstoneDetectionInput> {
  // Camera controllers
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _capturedImage;

  // Form controllers
  final TextEditingController _refractiveIndexController =
      TextEditingController();
  final TextEditingController _specificGravityController =
      TextEditingController();
  final TextEditingController _mohsHardnessController = TextEditingController();

  // Validation states
  String? _refractiveIndexError;
  String? _specificGravityError;
  String? _mohsHardnessError;

  // UI states
  bool _isPropertiesExpanded = true;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _refractiveIndexController.dispose();
    _specificGravityController.dispose();
    _mohsHardnessController.dispose();
    super.dispose();
  }

  // Camera initialization with platform detection
  Future<void> _initializeCamera() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        setState(() => _isInitializing = false);
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }

      // Select appropriate camera based on platform
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Apply platform-specific settings
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Focus mode not supported
    }

    if (!kIsWeb) {
      try {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } catch (e) {
        // Flash not supported
      }
    }
  }

  // Capture photo from camera
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorSnackBar(
        'Camera not initialized. Please wait or restart the app.',
      );
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _capturedImage = photo);
    } catch (e) {
      _showErrorSnackBar('Failed to capture photo. Please try again.');
    }
  }

  // Choose image from gallery
  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _capturedImage = image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image. Please try again.');
    }
  }

  // Validation methods
  bool _validateRefractiveIndex(String value) {
    if (value.isEmpty) return true;

    final double? ri = double.tryParse(value);
    if (ri == null) {
      setState(() => _refractiveIndexError = 'Invalid number format');
      return false;
    }

    if (ri < 1.0 || ri > 3.0) {
      setState(() => _refractiveIndexError = 'RI must be between 1.0 and 3.0');
      return false;
    }

    setState(() => _refractiveIndexError = null);
    return true;
  }

  bool _validateSpecificGravity(String value) {
    if (value.isEmpty) return true;

    final double? sg = double.tryParse(value);
    if (sg == null) {
      setState(() => _specificGravityError = 'Invalid number format');
      return false;
    }

    if (sg < 1.0 || sg > 20.0) {
      setState(() => _specificGravityError = 'SG must be between 1.0 and 20.0');
      return false;
    }

    setState(() => _specificGravityError = null);
    return true;
  }

  bool _validateMohsHardness(String value) {
    if (value.isEmpty) return true;

    final double? mh = double.tryParse(value);
    if (mh == null) {
      setState(() => _mohsHardnessError = 'Invalid number format');
      return false;
    }

    if (mh < 1.0 || mh > 10.0) {
      setState(
        () => _mohsHardnessError = 'Hardness must be between 1.0 and 10.0',
      );
      return false;
    }

    setState(() => _mohsHardnessError = null);
    return true;
  }

  // Check if form is valid for submission
  bool get _isFormValid {
    return _capturedImage != null &&
        (_refractiveIndexController.text.isNotEmpty ||
            _specificGravityController.text.isNotEmpty ||
            _mohsHardnessController.text.isNotEmpty) &&
        _refractiveIndexError == null &&
        _specificGravityError == null &&
        _mohsHardnessError == null;
  }

  // Calculate progress
  double get _progressValue {
    int completed = 0;
    int total = 4;

    if (_capturedImage != null) completed++;
    if (_refractiveIndexController.text.isNotEmpty) completed++;
    if (_specificGravityController.text.isNotEmpty) completed++;
    if (_mohsHardnessController.text.isNotEmpty) completed++;

    return completed / total;
  }

  // Analyze with AI
  Future<void> _analyzeWithAI() async {
    if (!_isFormValid) return;

    setState(() => _isAnalyzing = true);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isAnalyzing = false);
      Navigator.pushNamed(context, '/detection-results');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gemstone Analysis',
        variant: CustomAppBarVariant.standard,
        showBackButton: true,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(theme),

                // Image capture section
                ImageCaptureSection(
                  cameraController: _cameraController,
                  isCameraInitialized: _isCameraInitialized,
                  isInitializing: _isInitializing,
                  capturedImage: _capturedImage,
                  onCapturePhoto: _capturePhoto,
                  onChooseFromGallery: _chooseFromGallery,
                  onRetakePhoto: () => setState(() => _capturedImage = null),
                ),

                SizedBox(height: 2.h),

                // Scientific properties section
                ScientificPropertiesSection(
                  isExpanded: _isPropertiesExpanded,
                  onToggleExpanded: () => setState(
                    () => _isPropertiesExpanded = !_isPropertiesExpanded,
                  ),
                  refractiveIndexController: _refractiveIndexController,
                  specificGravityController: _specificGravityController,
                  mohsHardnessController: _mohsHardnessController,
                  refractiveIndexError: _refractiveIndexError,
                  specificGravityError: _specificGravityError,
                  mohsHardnessError: _mohsHardnessError,
                  onRefractiveIndexChanged: (value) =>
                      _validateRefractiveIndex(value),
                  onSpecificGravityChanged: (value) =>
                      _validateSpecificGravity(value),
                  onMohsHardnessChanged: (value) =>
                      _validateMohsHardness(value),
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),

          // Floating analyze button
          Positioned(
            left: 4.w,
            right: 4.w,
            bottom: 3.h,
            child: _buildAnalyzeButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Input Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${(_progressValue * 100).toInt()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 0.8.h,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isFormValid && !_isAnalyzing ? _analyzeWithAI : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFormValid
            ? AppTheme.accentLight
            : theme.colorScheme.outline.withValues(alpha: 0.3),
        foregroundColor: _isFormValid
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        elevation: _isFormValid ? 6 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isAnalyzing
          ? SizedBox(
              height: 2.4.h,
              width: 2.4.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'auto_awesome',
                  color: _isFormValid
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Analyze with AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isFormValid
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
