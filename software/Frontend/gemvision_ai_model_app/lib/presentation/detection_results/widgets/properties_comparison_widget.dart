import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Properties comparison table showing user inputs vs database values
class PropertiesComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> userProperties;
  final Map<String, dynamic> databaseProperties;

  const PropertiesComparisonWidget({
    super.key,
    required this.userProperties,
    required this.databaseProperties,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'compare_arrows',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Properties Comparison',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          _buildComparisonTable(context, theme),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          _buildTableHeader(context, theme),
          SizedBox(height: 1.h),
          _buildPropertyRow(
            context,
            theme,
            'Refractive Index',
            userProperties['refractive_index'],
            databaseProperties['refractive_index'],
          ),
          _buildPropertyRow(
            context,
            theme,
            'Specific Gravity',
            userProperties['specific_gravity'],
            databaseProperties['specific_gravity'],
          ),
          _buildPropertyRow(
            context,
            theme,
            'Mohs Hardness',
            userProperties['mohs_hardness'],
            databaseProperties['mohs_hardness'],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Property',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Your Input',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Database',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(
    BuildContext context,
    ThemeData theme,
    String property,
    dynamic userValue,
    dynamic dbValue,
  ) {
    final bool isMatch = _valuesMatch(userValue, dbValue);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isMatch
            ? AppTheme.successLight.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMatch
              ? AppTheme.successLight.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              property,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              userValue.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dbValue.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 1.w),
                if (isMatch)
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.successLight,
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _valuesMatch(dynamic value1, dynamic value2) {
    if (value1 is num && value2 is num) {
      return (value1 - value2).abs() < 0.05;
    }
    return value1 == value2;
  }
}
