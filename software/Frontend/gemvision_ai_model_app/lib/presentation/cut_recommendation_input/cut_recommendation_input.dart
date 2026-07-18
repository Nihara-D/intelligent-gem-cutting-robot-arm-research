import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/advanced_properties_widget.dart';
import './widgets/calculated_fields_widget.dart';
import './widgets/gemstone_type_selector_widget.dart';
import './widgets/measurement_section_widget.dart';

/// Cut Recommendation Input screen for manual gemstone parameter entry
class CutRecommendationInput extends StatefulWidget {
  const CutRecommendationInput({super.key});

  @override
  State<CutRecommendationInput> createState() => _CutRecommendationInputState();
}

class _CutRecommendationInputState extends State<CutRecommendationInput>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomNavIndex = 2; // Cut Recommendation tab

  // Form controllers
  GemstoneType? _selectedGemstone;
  final TextEditingController _caratController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _riController = TextEditingController();

  // Calculated values
  double? _aspectRatio;
  double? _depthRatio;

  // Form validation
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);

    // Add listeners to controllers
    _caratController.addListener(_updateCalculatedFields);
    _lengthController.addListener(_updateCalculatedFields);
    _widthController.addListener(_updateCalculatedFields);
    _depthController.addListener(_updateCalculatedFields);
    _riController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _caratController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _riController.dispose();
    super.dispose();
  }

  void _updateCalculatedFields() {
    setState(() {
      final length = double.tryParse(_lengthController.text);
      final width = double.tryParse(_widthController.text);
      final depth = double.tryParse(_depthController.text);

      if (length != null && width != null && width > 0) {
        _aspectRatio = length / width;
      } else {
        _aspectRatio = null;
      }

      if (depth != null && width != null && width > 0) {
        _depthRatio = (depth / width) * 100;
      } else {
        _depthRatio = null;
      }

      _validateForm();
    });
  }

  void _validateForm() {
    final isValid =
        _selectedGemstone != null &&
        _caratController.text.isNotEmpty &&
        _lengthController.text.isNotEmpty &&
        _widthController.text.isNotEmpty &&
        _depthController.text.isNotEmpty &&
        _riController.text.isNotEmpty &&
        double.tryParse(_caratController.text) != null &&
        double.tryParse(_lengthController.text) != null &&
        double.tryParse(_widthController.text) != null &&
        double.tryParse(_depthController.text) != null &&
        double.tryParse(_riController.text) != null;

    setState(() {
      _isFormValid = isValid;
    });
  }

  void _handleGenerateRecommendations() {
    if (!_isFormValid) return;

    HapticFeedback.mediumImpact();

    // Navigate to results screen with parameters
    Navigator.pushNamed(
      context,
      '/cut-recommendation-results',
      arguments: {
        'gemstoneType': _selectedGemstone!.name,
        'caratWeight': double.parse(_caratController.text),
        'length': double.parse(_lengthController.text),
        'width': double.parse(_widthController.text),
        'depth': double.parse(_depthController.text),
        'refractiveIndex': double.parse(_riController.text),
        'aspectRatio': _aspectRatio,
        'depthRatio': _depthRatio,
      },
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentBottomNavIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentBottomNavIndex = index;
    });

    // Navigate to corresponding screen
    final routes = [
      '/home-dashboard',
      '/gemstone-detection-input',
      '/cut-recommendation-input',
      '/analysis-history',
    ];

    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cut Recommendation',
        variant: CustomAppBarVariant.standard,
        centerTitle: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'help_outline',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHelpDialog();
            },
            tooltip: 'Help',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            HapticFeedback.lightImpact();
            if (index == 0) {
              Navigator.pushReplacementNamed(
                context,
                '/gemstone-detection-input',
              );
            }
          },
          tabs: const [
            Tab(text: 'Detection'),
            Tab(text: 'Cut Recommendation'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                            theme.colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: 'content_cut',
                              color: theme.colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Professional Cutting Analysis',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter precise measurements for optimal cut recommendations',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gemstone type selector
                    GemstoneTypeSelectorWidget(
                      selectedGemstone: _selectedGemstone,
                      onChanged: (gemstone) {
                        setState(() {
                          _selectedGemstone = gemstone;
                          _validateForm();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Measurement section
                    MeasurementSectionWidget(
                      caratController: _caratController,
                      lengthController: _lengthController,
                      widthController: _widthController,
                      depthController: _depthController,
                      onMeasurementChanged: _updateCalculatedFields,
                    ),
                    const SizedBox(height: 16),

                    // Advanced properties
                    AdvancedPropertiesWidget(
                      riController: _riController,
                      minRI: _selectedGemstone?.minRI,
                      maxRI: _selectedGemstone?.maxRI,
                    ),
                    const SizedBox(height: 16),

                    // Calculated fields
                    CalculatedFieldsWidget(
                      aspectRatio: _aspectRatio,
                      depthRatio: _depthRatio,
                    ),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _isFormValid ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: _isFormValid ? _handleGenerateRecommendations : null,
          backgroundColor: _isFormValid
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          foregroundColor: _isFormValid
              ? theme.colorScheme.onTertiary
              : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          icon: CustomIconWidget(
            iconName: 'auto_awesome',
            color: _isFormValid
                ? theme.colorScheme.onTertiary
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            size: 24,
          ),
          label: const Text('Generate Recommendations'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'help_outline',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Measurement Guide'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  theme: theme,
                  icon: 'scale',
                  title: 'Carat Weight',
                  description:
                      'Use a precision scale to measure the gemstone weight in carats (1 carat = 0.2 grams)',
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  theme: theme,
                  icon: 'straighten',
                  title: 'Dimensions',
                  description:
                      'Measure length, width, and depth using a digital caliper for accuracy (in millimeters)',
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  theme: theme,
                  icon: 'opacity',
                  title: 'Refractive Index',
                  description:
                      'Use a refractometer to measure the RI. Each gemstone type has a specific RI range',
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  theme: theme,
                  icon: 'calculate',
                  title: 'Calculated Ratios',
                  description:
                      'Aspect ratio and depth ratio are automatically calculated from your measurements',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({
    required ThemeData theme,
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
