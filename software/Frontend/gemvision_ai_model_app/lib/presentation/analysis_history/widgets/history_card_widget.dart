import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../../../core/app_export.dart';

class HistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;

  const HistoryCardWidget({
    super.key,
    required this.analysis,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = analysis["date"] as DateTime;
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    final confidence = analysis["confidence"] as double;
    final type = analysis["type"] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                if (isMultiSelectMode)
                  Padding(
                    padding: EdgeInsets.only(right: 3.w),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: analysis["thumbnail"] as String,
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                    semanticLabel: analysis["semanticLabel"] as String,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              analysis["name"] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(theme),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(
                                theme,
                                confidence,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'verified',
                                  color: _getConfidenceColor(theme, confidence),
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${confidence.toStringAsFixed(1)}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _getConfidenceColor(
                                      theme,
                                      confidence,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: type == "detection"
                                      ? 'camera_alt'
                                      : 'auto_awesome',
                                  color: theme.colorScheme.secondary,
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  type == "detection"
                                      ? 'Detection'
                                      : 'Cut Rec.',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMultiSelectMode)
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final status = analysis["status"] as String;
    final color = status == "genuine"
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: status == "genuine" ? 'check_circle' : 'cancel',
            color: color,
            size: 12,
          ),
          SizedBox(width: 1.w),
          Text(
            status == "genuine" ? 'Genuine' : 'Not Genuine',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(ThemeData theme, double confidence) {
    if (confidence >= 90) return theme.colorScheme.primary;
    if (confidence >= 75) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }
}
