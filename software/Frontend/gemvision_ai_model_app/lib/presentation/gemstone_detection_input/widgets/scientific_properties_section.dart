import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ScientificPropertiesSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final TextEditingController refractiveIndexController;
  final TextEditingController specificGravityController;
  final TextEditingController mohsHardnessController;
  final String? refractiveIndexError;
  final String? specificGravityError;
  final String? mohsHardnessError;
  final ValueChanged<String> onRefractiveIndexChanged;
  final ValueChanged<String> onSpecificGravityChanged;
  final ValueChanged<String> onMohsHardnessChanged;

  const ScientificPropertiesSection({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.refractiveIndexController,
    required this.specificGravityController,
    required this.mohsHardnessController,
    required this.refractiveIndexError,
    required this.specificGravityError,
    required this.mohsHardnessError,
    required this.onRefractiveIndexChanged,
    required this.onSpecificGravityChanged,
    required this.onMohsHardnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'science',
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scientific Properties',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Enter at least one property',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                children: [
                  Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  SizedBox(height: 2.h),
                  _buildPropertyField(
                    context: context,
                    theme: theme,
                    label: 'Refractive Index (RI)',
                    hint: 'e.g., 1.544',
                    controller: refractiveIndexController,
                    error: refractiveIndexError,
                    onChanged: onRefractiveIndexChanged,
                    helperText: 'Range: 1.0 - 3.0',
                    icon: 'opacity',
                  ),
                  SizedBox(height: 2.h),
                  _buildPropertyField(
                    context: context,
                    theme: theme,
                    label: 'Specific Gravity (SG)',
                    hint: 'e.g., 2.65',
                    controller: specificGravityController,
                    error: specificGravityError,
                    onChanged: onSpecificGravityChanged,
                    helperText: 'Range: 1.0 - 20.0',
                    icon: 'scale',
                  ),
                  SizedBox(height: 2.h),
                  _buildPropertyField(
                    context: context,
                    theme: theme,
                    label: 'Mohs Hardness',
                    hint: 'e.g., 7.0',
                    controller: mohsHardnessController,
                    error: mohsHardnessError,
                    onChanged: onMohsHardnessChanged,
                    helperText: 'Range: 1.0 - 10.0',
                    icon: 'diamond',
                  ),
                  SizedBox(height: 2.h),
                  _buildInfoCard(theme),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyField({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? error,
    required ValueChanged<String> onChanged,
    required String helperText,
    required String icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            helperText: error == null ? helperText : null,
            errorText: error,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.6.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'info_outline',
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accuracy Tip',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Providing more properties increases AI analysis accuracy. Use professional gemological tools for precise measurements.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
