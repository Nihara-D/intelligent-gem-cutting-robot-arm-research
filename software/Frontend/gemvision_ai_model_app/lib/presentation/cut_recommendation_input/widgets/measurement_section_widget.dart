import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Measurement section widget with precise input fields
class MeasurementSectionWidget extends StatelessWidget {
  final TextEditingController caratController;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController depthController;
  final VoidCallback onMeasurementChanged;

  const MeasurementSectionWidget({
    super.key,
    required this.caratController,
    required this.lengthController,
    required this.widthController,
    required this.depthController,
    required this.onMeasurementChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'straighten',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Measurements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context: context,
              controller: caratController,
              label: 'Carat Weight',
              hint: 'Enter carat weight',
              suffix: 'ct',
              icon: 'scale',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              required: true,
              helpText: 'Weight of the gemstone in carats',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    context: context,
                    controller: lengthController,
                    label: 'Length',
                    hint: 'Length',
                    suffix: 'mm',
                    icon: 'height',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    context: context,
                    controller: widthController,
                    label: 'Width',
                    hint: 'Width',
                    suffix: 'mm',
                    icon: 'width_normal',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context: context,
              controller: depthController,
              label: 'Depth',
              hint: 'Enter depth',
              suffix: 'mm',
              icon: 'layers',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              required: true,
              helpText: 'Total depth of the gemstone',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'tips_and_updates',
                    color: theme.colorScheme.tertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use precise measurements for accurate cutting recommendations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required String icon,
    required TextInputType keyboardType,
    bool required = false,
    String? helpText,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => onMeasurementChanged(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            suffixText: suffix,
            suffixStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
