import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Cut Type Card Widget
/// Displays individual cut type with image and basic information
class CutTypeCardWidget extends StatelessWidget {
  final Map<String, dynamic> cutData;
  final bool isSelected;
  final VoidCallback onTap;

  const CutTypeCardWidget({
    super.key,
    required this.cutData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cut image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CustomImageWidget(
                imageUrl: cutData["image"] as String,
                width: double.infinity,
                height: 15.h,
                fit: BoxFit.cover,
                semanticLabel: cutData["semanticLabel"] as String,
              ),
            ),

            // Cut information
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cutData["cutType"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${cutData["facetCount"]} facets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          theme,
                          cutData["difficulty"] as String,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cutData["difficulty"] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getDifficultyColor(
                            theme,
                            cutData["difficulty"] as String,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
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

  Color _getDifficultyColor(ThemeData theme, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'low':
        return theme.colorScheme.tertiary;
      case 'medium':
        return theme.colorScheme.primary;
      case 'medium-high':
        return theme.colorScheme.secondary;
      case 'high':
        return const Color(0xFFFF9800);
      case 'very high':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
