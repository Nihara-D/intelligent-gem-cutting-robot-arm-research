import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Recent analysis card widget displaying gemstone analysis summary
/// Shows gemstone image, name, confidence score, and classification
class RecentAnalysisCardWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RecentAnalysisCardWidget({
    super.key,
    required this.analysis,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemName = analysis['gemName'] as String? ?? 'Unknown';
    final confidence = analysis['confidence'] as double? ?? 0.0;
    final date = analysis['date'] as String? ?? '';
    final imageUrl = analysis['image'] as String? ?? '';
    final semanticLabel = analysis['semanticLabel'] as String? ?? '';
    final classification = analysis['classification'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
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
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Gemstone Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                ),
              ),
              SizedBox(width: 4.w),

              // Analysis Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      classification,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'verified',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${confidence.toStringAsFixed(1)}% confidence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
