import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/cut_type_card_widget.dart';
import './widgets/interactive_diagram_widget.dart';
import './widgets/technical_specifications_widget.dart';

/// Cut Recommendation Results Screen
/// Displays professional cutting parameters with visual diagrams and technical specifications
class CutRecommendationResults extends StatefulWidget {
  const CutRecommendationResults({super.key});

  @override
  State<CutRecommendationResults> createState() =>
      _CutRecommendationResultsState();
}

class _CutRecommendationResultsState extends State<CutRecommendationResults>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCutIndex = 0;
  bool _isComparisonMode = false;
  int _comparisonCutIndex = 1;

  // Mock data for cut recommendations
  final List<Map<String, dynamic>> _cutRecommendations = [
    {
      "cutType": "Round Brilliant",
      "image": "assets/images/cut_recommendation_results/RoundBrilliant.png",
      "semanticLabel":
          "Round brilliant cut diamond with symmetrical facets reflecting light",
      "pavilionAngle": "40.8°",
      "crownAngle": "34.5°",
      "tablePercentage": "57%",
      "depthPercentage": "61.5%",
      "facetCount": 58,
      "lengthToWidthRatio": "1.00",
      "difficulty": "Medium",
      "description":
          "Classic round brilliant cut maximizes light return and brilliance. Ideal for high-quality gemstones with excellent clarity.",
      "tolerances": {
        "pavilionAngle": "±0.5°",
        "crownAngle": "±0.5°",
        "tablePercentage": "±2%",
        "depthPercentage": "±1%",
      },
    },
    {
      "cutType": "Oval",
      "image": "assets/images/cut_recommendation_results/Oval.png",
      "semanticLabel":
          "Oval cut gemstone with elongated shape and brilliant faceting pattern",
      "pavilionAngle": "41.2°",
      "crownAngle": "35.0°",
      "tablePercentage": "60%",
      "depthPercentage": "62.0%",
      "facetCount": 56,
      "lengthToWidthRatio": "1.35",
      "difficulty": "Medium-High",
      "description":
          "Elongated oval cut creates illusion of larger size while maintaining brilliance. Excellent for colored gemstones.",
      "tolerances": {
        "pavilionAngle": "±0.5°",
        "crownAngle": "±0.5°",
        "tablePercentage": "±2%",
        "depthPercentage": "±1%",
      },
    },
    {
      "cutType": "Cushion",
      "image": "assets/images/cut_recommendation_results/Cushion.png",
      "semanticLabel":
          "Cushion cut gemstone with rounded corners and large facets creating vintage appeal",
      "pavilionAngle": "42.0°",
      "crownAngle": "36.0°",
      "tablePercentage": "62%",
      "depthPercentage": "63.5%",
      "facetCount": 64,
      "lengthToWidthRatio": "1.10",
      "difficulty": "High",
      "description":
          "Vintage-inspired cushion cut with rounded corners and larger facets. Creates romantic appearance with excellent fire.",
      "tolerances": {
        "pavilionAngle": "±0.5°",
        "crownAngle": "±0.5°",
        "tablePercentage": "±2%",
        "depthPercentage": "±1%",
      },
    },
    {
      "cutType": "Emerald",
      "image": "assets/images/cut_recommendation_results/Emerald.png",
      "semanticLabel":
          "Emerald cut gemstone with rectangular step-cut facets and beveled corners",
      "pavilionAngle": "39.5°",
      "crownAngle": "33.0°",
      "tablePercentage": "65%",
      "depthPercentage": "60.0%",
      "facetCount": 50,
      "lengthToWidthRatio": "1.50",
      "difficulty": "High",
      "description":
          "Elegant step-cut with rectangular facets emphasizing clarity. Requires high-quality gemstones with minimal inclusions.",
      "tolerances": {
        "pavilionAngle": "±0.5°",
        "crownAngle": "±0.5°",
        "tablePercentage": "±2%",
        "depthPercentage": "±1%",
      },
    },
    {
      "cutType": "Cabochon",
      "image": "assets/images/cut_recommendation_results/Cabochon.png",
      "semanticLabel":
          "Smooth cabochon cut gemstone with polished dome surface without facets",
      "pavilionAngle": "N/A",
      "crownAngle": "N/A",
      "tablePercentage": "N/A",
      "depthPercentage": "45.0%",
      "facetCount": 0,
      "lengthToWidthRatio": "1.20",
      "difficulty": "Low",
      "description":
          "Smooth, polished dome cut ideal for opaque or translucent gemstones. Showcases color and special optical effects.",
      "tolerances": {
        "pavilionAngle": "N/A",
        "crownAngle": "N/A",
        "tablePercentage": "N/A",
        "depthPercentage": "±2%",
      },
    },
    {
      "cutType": "Mixed Cut",
      "image": "assets/images/cut_recommendation_results/MixedCut.png",
      "semanticLabel":
          "Mixed cut gemstone combining brilliant crown and step-cut pavilion for optimal light performance",
      "pavilionAngle": "40.0°",
      "crownAngle": "35.5°",
      "tablePercentage": "58%",
      "depthPercentage": "61.0%",
      "facetCount": 62,
      "lengthToWidthRatio": "1.25",
      "difficulty": "Very High",
      "description":
          "Hybrid cut combining brilliant crown with step-cut pavilion. Maximizes both brilliance and color depth.",
      "tolerances": {
        "pavilionAngle": "±0.5°",
        "crownAngle": "±0.5°",
        "tablePercentage": "±2%",
        "depthPercentage": "±1%",
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleComparisonMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isComparisonMode = !_isComparisonMode;
      if (_isComparisonMode && _comparisonCutIndex == _selectedCutIndex) {
        _comparisonCutIndex =
            (_selectedCutIndex + 1) % _cutRecommendations.length;
      }
    });
  }

  void _selectCut(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCutIndex = index;
      if (_isComparisonMode && _comparisonCutIndex == index) {
        _comparisonCutIndex = (index + 1) % _cutRecommendations.length;
      }
    });
  }

  void _selectComparisonCut(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _comparisonCutIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Cut Recommendations',
        variant: CustomAppBarVariant.standard,
        showBackButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _exportParameters,
            tooltip: 'Export Parameters',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'calendar_today',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _bookConsultation,
            tooltip: 'Book Consultation',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Comparison mode toggle
            Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comparison Mode', style: theme.textTheme.titleMedium),
                  Switch(
                    value: _isComparisonMode,
                    onChanged: (value) => _toggleComparisonMode(),
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: _isComparisonMode
                  ? _buildComparisonView(theme)
                  : _buildSingleView(theme),
            ),

            // Action buttons
            ActionButtonsWidget(
              onSaveParameters: _saveParameters,
              onShareWithCutter: _shareWithCutter,
              onBookConsultation: _bookConsultation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleView(ThemeData theme) {
    final selectedCut = _cutRecommendations[_selectedCutIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cut type cards horizontal scroll
          SizedBox(
            height: 28.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              scrollDirection: Axis.horizontal,
              itemCount: _cutRecommendations.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                return CutTypeCardWidget(
                  cutData: _cutRecommendations[index],
                  isSelected: index == _selectedCutIndex,
                  onTap: () => _selectCut(index),
                );
              },
            ),
          ),

          SizedBox(height: 2.h),

          // Interactive diagram
          InteractiveDiagramWidget(cutData: selectedCut),

          SizedBox(height: 2.h),

          // Technical specifications
          TechnicalSpecificationsWidget(
            cutData: selectedCut,
            onParameterLongPress: _showParameterContext,
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildComparisonView(ThemeData theme) {
    final selectedCut = _cutRecommendations[_selectedCutIndex];
    final comparisonCut = _cutRecommendations[_comparisonCutIndex];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Cut selection for comparison
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildComparisonSelector(
                    theme,
                    'Primary Cut',
                    _selectedCutIndex,
                    _selectCut,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildComparisonSelector(
                    theme,
                    'Compare With',
                    _comparisonCutIndex,
                    _selectComparisonCut,
                  ),
                ),
              ],
            ),
          ),

          // Side-by-side comparison
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InteractiveDiagramWidget(
                        cutData: selectedCut,
                        isCompact: true,
                      ),
                      SizedBox(height: 2.h),
                      TechnicalSpecificationsWidget(
                        cutData: selectedCut,
                        isCompact: true,
                        onParameterLongPress: _showParameterContext,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    children: [
                      InteractiveDiagramWidget(
                        cutData: comparisonCut,
                        isCompact: true,
                      ),
                      SizedBox(height: 2.h),
                      TechnicalSpecificationsWidget(
                        cutData: comparisonCut,
                        isCompact: true,
                        onParameterLongPress: _showParameterContext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildComparisonSelector(
    ThemeData theme,
    String label,
    int selectedIndex,
    Function(int) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<int>(
            value: selectedIndex,
            isExpanded: true,
            underline: const SizedBox(),
            icon: CustomIconWidget(
              iconName: 'arrow_drop_down',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            items: List.generate(
              _cutRecommendations.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(
                  _cutRecommendations[index]["cutType"] as String,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            onChanged: (value) {
              if (value != null) onSelect(value);
            },
          ),
        ),
      ],
    );
  }

  void _showParameterContext(String parameter, String value) {
    final theme = Theme.of(context);
    final contextInfo = _getParameterContext(parameter);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(parameter, style: theme.textTheme.titleLarge),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Current Value: $value',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              contextInfo['description'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Difficulty: ${contextInfo['difficulty']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getParameterContext(String parameter) {
    final contexts = {
      'Pavilion Angle': {
        'description':
            'The angle of the pavilion facets relative to the girdle plane. Critical for light return and brilliance. Too shallow causes light leakage, too steep creates a dark center.',
        'difficulty': 'High - Requires precise angle control',
      },
      'Crown Angle': {
        'description':
            'The angle of the crown facets relative to the girdle plane. Affects fire and scintillation. Balances with pavilion angle for optimal light performance.',
        'difficulty': 'High - Must coordinate with pavilion angle',
      },
      'Table Percentage': {
        'description':
            'The width of the table facet as a percentage of the girdle diameter. Larger tables show more color, smaller tables create more fire and brilliance.',
        'difficulty': 'Medium - Affects overall appearance',
      },
      'Depth Percentage': {
        'description':
            'The total depth of the gemstone as a percentage of the girdle diameter. Critical for proportions and light performance. Affects weight retention.',
        'difficulty': 'Medium - Balances beauty and weight',
      },
      'Facet Count': {
        'description':
            'The total number of polished facets on the gemstone. More facets generally create more brilliance but require more cutting time and skill.',
        'difficulty': 'Very High - Each facet must be precisely placed',
      },
      'Length to Width Ratio': {
        'description':
            'The ratio of the gemstone\'s length to its width. Defines the overall shape and proportions. Critical for fancy shapes like oval and emerald cuts.',
        'difficulty': 'Low - Determined by rough shape',
      },
    };

    return contexts[parameter] ??
        {
          'description':
              'Professional cutting parameter requiring expert skill.',
          'difficulty': 'Medium',
        };
  }

  void _saveParameters() {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cutting parameters saved to history',
          style: theme.snackBarTheme.contentTextStyle,
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareWithCutter() {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Parameters', style: theme.textTheme.titleLarge),
        content: Text(
          'Share cutting parameters with your professional cutter via email or messaging app?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Parameters shared successfully',
                    style: theme.snackBarTheme.contentTextStyle,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _bookConsultation() {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Consultation', style: theme.textTheme.titleLarge),
        content: Text(
          'Schedule a consultation with our gemstone cutting experts to discuss these recommendations in detail?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Consultation request sent',
                    style: theme.snackBarTheme.contentTextStyle,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _exportParameters() {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export Format', style: theme.textTheme.titleLarge),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'picture_as_pdf',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text('PDF Document', style: theme.textTheme.bodyLarge),
              subtitle: Text(
                'Professional cutting specification sheet',
                style: theme.textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'PDF exported successfully',
                      style: theme.snackBarTheme.contentTextStyle,
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'image',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text(
                'High-Resolution Image',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Diagram with parameters overlay',
                style: theme.textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Image exported successfully',
                      style: theme.snackBarTheme.contentTextStyle,
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
