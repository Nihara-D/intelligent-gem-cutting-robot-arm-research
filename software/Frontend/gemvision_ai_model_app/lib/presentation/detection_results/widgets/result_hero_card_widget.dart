import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Hero card displaying gemstone name, reference image, and confidence score
class ResultHeroCardWidget extends StatelessWidget {
  final String gemstoneName;
  final double confidenceScore;
  final String referenceImage;
  final String semanticLabel;
  final VoidCallback? onLongPress;

  const ResultHeroCardWidget({
    super.key,
    required this.gemstoneName,
    required this.confidenceScore,
    required this.referenceImage,
    required this.semanticLabel,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gemstone Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CustomImageWidget(
                imageUrl: referenceImage,
                width: double.infinity,
                height: 30.h,
                fit: BoxFit.cover,
                semanticLabel: semanticLabel,
              ),
            ),

            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gemstone Name
                  Text(
                    gemstoneName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Confidence Score
                  _buildConfidenceScore(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceScore(BuildContext context, ThemeData theme) {
    final Color scoreColor = _getScoreColor(confidenceScore, theme);
    final String accuracyLevel = _getAccuracyLevel(confidenceScore);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'verified',
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),

          SizedBox(width: 3.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence Score',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      '${confidenceScore.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        accuracyLevel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score, ThemeData theme) {
    if (score >= 90) {
      return AppTheme.successLight;
    } else if (score >= 75) {
      return AppTheme.accentLight;
    } else if (score >= 60) {
      return theme.colorScheme.secondary;
    } else {
      return AppTheme.errorLight;
    }
  }

  String _getAccuracyLevel(double score) {
    if (score >= 90) {
      return 'Excellent';
    } else if (score >= 75) {
      return 'High';
    } else if (score >= 60) {
      return 'Moderate';
    } else {
      return 'Low';
    }
  }
}
