import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Action Buttons Widget
/// Displays action buttons for saving, sharing, and booking consultation
class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onSaveParameters;
  final VoidCallback onShareWithCutter;
  final VoidCallback onBookConsultation;

  const ActionButtonsWidget({
    super.key,
    required this.onSaveParameters,
    required this.onShareWithCutter,
    required this.onBookConsultation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSaveParameters,
                    icon: CustomIconWidget(
                      iconName: 'bookmark_border',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShareWithCutter,
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBookConsultation,
                icon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: const Text('Book Consultation'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
