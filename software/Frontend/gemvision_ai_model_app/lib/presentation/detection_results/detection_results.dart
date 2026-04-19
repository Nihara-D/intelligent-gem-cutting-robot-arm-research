import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/classification_status_widget.dart';
import './widgets/educational_section_widget.dart';
import './widgets/properties_comparison_widget.dart';
import './widgets/result_hero_card_widget.dart';

/// Detection Results Screen
/// Presents AI analysis findings with professional data visualization and educational content
class DetectionResults extends StatefulWidget {
  const DetectionResults({super.key});

  @override
  State<DetectionResults> createState() => _DetectionResultsState();
}

class _DetectionResultsState extends State<DetectionResults> {
  bool _isSaved = false;
  bool _isRefreshing = false;

  // Mock detection result data
  final Map<String, dynamic> _detectionResult = {
    "gemstone_name": "Natural Emerald",
    "confidence_score": 94.7,
    "classification": "Genuine Gemstone",
    "reference_image": "assets/images/NaturalEmarald.png",
    "semanticLabel":
        "Brilliant cut natural emerald gemstone with deep green color and hexagonal crystal structure on white background",
    "user_properties": {
      "refractive_index": 1.577,
      "specific_gravity": 2.71,
      "mohs_hardness": 7.5,
    },
    "database_properties": {
      "refractive_index": 1.577,
      "specific_gravity": 2.72,
      "mohs_hardness": 7.5,
    },
    "education": {
      "introduction":
          "Emerald is a precious gemstone and a variety of the mineral beryl, colored green by trace amounts of chromium and sometimes vanadium. It has been treasured throughout history and is one of the four traditionally recognized precious stones.",
      "characteristics": [
        "Vivid green to bluish-green color",
        "Hexagonal crystal system",
        "Excellent transparency when high quality",
        "Natural inclusions called 'jardin' (garden)",
      ],
      "formation":
          "Emeralds form in hydrothermal veins and pegmatites through a complex geological process requiring beryllium, chromium, and specific pressure-temperature conditions. This rare combination makes natural emeralds exceptionally valuable.",
      "market_value":
          "High-quality emeralds can command prices exceeding \$100,000 per carat. Colombian emeralds are particularly prized for their pure green color and exceptional clarity.",
    },
    "analysis_date": "2025-12-28T07:31:04",
    "is_genuine": true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: _buildBody(context, theme),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Detection Results',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'share',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _handleShare(context),
          tooltip: 'Share Results',
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: _isSaved ? 'bookmark' : 'bookmark_border',
            color: _isSaved
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _handleSave(context),
          tooltip: _isSaved ? 'Saved' : 'Save to History',
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Hero Result Card
            ResultHeroCardWidget(
              gemstoneName: _detectionResult["gemstone_name"] as String,
              confidenceScore: _detectionResult["confidence_score"] as double,
              referenceImage: _detectionResult["reference_image"] as String,
              semanticLabel: _detectionResult["semanticLabel"] as String,
              onLongPress: () => _showAdditionalOptions(context),
            ),

            SizedBox(height: 3.h),

            // Classification Status
            ClassificationStatusWidget(
              classification: _detectionResult["classification"] as String,
              isGenuine: _detectionResult["is_genuine"] as bool,
            ),

            SizedBox(height: 3.h),

            // Properties Comparison
            PropertiesComparisonWidget(
              userProperties:
                  _detectionResult["user_properties"] as Map<String, dynamic>,
              databaseProperties:
                  _detectionResult["database_properties"]
                      as Map<String, dynamic>,
            ),

            SizedBox(height: 3.h),

            // Educational Section
            EducationalSectionWidget(
              education: _detectionResult["education"] as Map<String, dynamic>,
            ),

            SizedBox(height: 3.h),

            // Action Buttons
            ActionButtonsWidget(
              isGenuine: _detectionResult["is_genuine"] as bool,
              onGetCutRecommendation: () =>
                  _navigateToCutRecommendation(context),
              onSaveToHistory: () => _handleSave(context),
              onShareResults: () => _handleShare(context),
              onAnalyzeAnother: () => _navigateToDetectionInput(context),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    // Simulate re-running analysis
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isRefreshing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analysis refreshed successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleShare(BuildContext context) {
    HapticFeedback.lightImpact();

    final String shareText =
        '''
GemVision AI Detection Results

Gemstone: ${_detectionResult["gemstone_name"]}
Classification: ${_detectionResult["classification"]}
Confidence: ${_detectionResult["confidence_score"]}%

Analysis Date: ${_formatDate(_detectionResult["analysis_date"] as String)}

Powered by GemVision AI
    '''
            .trim();

    Share.share(shareText, subject: 'Gemstone Detection Results');
  }

  void _handleSave(BuildContext context) {
    HapticFeedback.lightImpact();

    setState(() => _isSaved = !_isSaved);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved ? 'Saved to history' : 'Removed from history',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAdditionalOptions(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildAdditionalOptionsSheet(context),
    );
  }

  Widget _buildAdditionalOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            _buildOptionTile(
              context,
              icon: 'picture_as_pdf',
              title: 'Export PDF',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'PDF Export');
              },
            ),
            _buildOptionTile(
              context,
              icon: 'note_add',
              title: 'Add Notes',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Add Notes');
              },
            ),
            _buildOptionTile(
              context,
              icon: 'notifications',
              title: 'Set Reminder',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Set Reminder');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: theme.colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToCutRecommendation(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/cut-recommendation-input');
  }

  void _navigateToDetectionInput(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/gemstone-detection-input');
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}
