import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onStartAnalysis;

  const EmptyStateWidget({super.key, required this.onStartAnalysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'history',
                  color: theme.colorScheme.primary,
                  size: 20.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No Analysis History',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Start your first gemstone analysis to see your history here. Your analyses will be saved for future reference.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onStartAnalysis();
              },
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              label: const Text('Start Your First Analysis'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
            SizedBox(height: 2.h),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/cut-recommendation-input');
              },
              icon: CustomIconWidget(
                iconName: 'auto_awesome',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              label: const Text('Get Cut Recommendation'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
