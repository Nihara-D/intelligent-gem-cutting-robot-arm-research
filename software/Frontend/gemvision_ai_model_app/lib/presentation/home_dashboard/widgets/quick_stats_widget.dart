import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quick stats widget displaying analysis metrics
/// Shows total analyses, accuracy rate, and other key statistics
class QuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAnalyses = stats['totalAnalyses'] as int? ?? 0;
    final accuracyRate = stats['accuracyRate'] as double? ?? 0.0;
    final genuineDetected = stats['genuineDetected'] as int? ?? 0;
    final cutRecommendations = stats['cutRecommendations'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'analytics',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Quick Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Analyses',
                    totalAnalyses.toString(),
                    'assessment',
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Accuracy Rate',
                    '${accuracyRate.toStringAsFixed(1)}%',
                    'verified',
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Genuine Detected',
                    genuineDetected.toString(),
                    'diamond',
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Cut Recommendations',
                    cutRecommendations.toString(),
                    'auto_awesome',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String iconName,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
