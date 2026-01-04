import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Classification status card with color-coded result
class ClassificationStatusWidget extends StatelessWidget {
  final String classification;
  final bool isGenuine;

  const ClassificationStatusWidget({
    super.key,
    required this.classification,
    required this.isGenuine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusData = _getStatusData(classification, theme);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusData['color'].withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: statusData['color'].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: statusData['icon'],
              color: statusData['color'],
              size: 28,
            ),
          ),

          SizedBox(width: 4.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classification Result',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  classification,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusData['color'],
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (statusData['subtitle'] != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    statusData['subtitle'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String classification, ThemeData theme) {
    if (classification == 'Genuine Gemstone') {
      return {
        'color': AppTheme.successLight,
        'icon': 'check_circle',
        'subtitle': 'Authentic natural gemstone verified',
      };
    } else if (classification == 'Not Genuine but Valuable') {
      return {
        'color': AppTheme.accentLight,
        'icon': 'info',
        'subtitle': 'Valuable material but not natural gemstone',
      };
    } else {
      return {
        'color': AppTheme.errorLight,
        'icon': 'cancel',
        'subtitle': 'Not a genuine gemstone',
      };
    }
  }
}
