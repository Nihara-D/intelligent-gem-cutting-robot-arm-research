import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Technical Specifications Widget
/// Displays cutting parameters in professional format
class TechnicalSpecificationsWidget extends StatelessWidget {
  final Map<String, dynamic> cutData;
  final bool isCompact;
  final Function(String, String)? onParameterLongPress;

  const TechnicalSpecificationsWidget({
    super.key,
    required this.cutData,
    this.isCompact = false,
    this.onParameterLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tolerances = cutData["tolerances"] as Map<String, dynamic>;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(isCompact ? 3.w : 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: theme.colorScheme.primary,
                size: isCompact ? 20 : 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Technical Specifications',
                style:
                    (isCompact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Description
          if (!isCompact) ...[
            Text(
              cutData["description"] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 2.h),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),
            SizedBox(height: 2.h),
          ],

          // Parameters
          _buildParameterRow(
            theme,
            'Pavilion Angle',
            cutData["pavilionAngle"] as String,
            tolerances["pavilionAngle"] as String,
          ),
          SizedBox(height: isCompact ? 1.h : 1.5.h),
          _buildParameterRow(
            theme,
            'Crown Angle',
            cutData["crownAngle"] as String,
            tolerances["crownAngle"] as String,
          ),
          SizedBox(height: isCompact ? 1.h : 1.5.h),
          _buildParameterRow(
            theme,
            'Table Percentage',
            cutData["tablePercentage"] as String,
            tolerances["tablePercentage"] as String,
          ),
          SizedBox(height: isCompact ? 1.h : 1.5.h),
          _buildParameterRow(
            theme,
            'Depth Percentage',
            cutData["depthPercentage"] as String,
            tolerances["depthPercentage"] as String,
          ),
          SizedBox(height: isCompact ? 1.h : 1.5.h),
          _buildParameterRow(
            theme,
            'Facet Count',
            cutData["facetCount"].toString(),
            'Exact',
          ),
          SizedBox(height: isCompact ? 1.h : 1.5.h),
          _buildParameterRow(
            theme,
            'Length to Width Ratio',
            cutData["lengthToWidthRatio"] as String,
            '±0.05',
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(
    ThemeData theme,
    String label,
    String value,
    String tolerance,
  ) {
    return GestureDetector(
      onLongPress: onParameterLongPress != null
          ? () => onParameterLongPress!(label, value)
          : null,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 2.w : 3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        (isCompact
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                  ),
                  if (!isCompact) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Tolerance: $tolerance',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style:
                    (isCompact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                textAlign: TextAlign.right,
              ),
            ),
            if (onParameterLongPress != null) ...[
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: isCompact ? 16 : 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
