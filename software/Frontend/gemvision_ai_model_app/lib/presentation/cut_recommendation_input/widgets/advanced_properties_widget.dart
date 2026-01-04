import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Advanced properties section widget
class AdvancedPropertiesWidget extends StatelessWidget {
  final TextEditingController riController;
  final double? minRI;
  final double? maxRI;

  const AdvancedPropertiesWidget({
    super.key,
    required this.riController,
    this.minRI,
    this.maxRI,
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
                  iconName: 'science',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Properties',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Refractive Index (RI)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: riController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter refractive index',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CustomIconWidget(
                    iconName: 'opacity',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
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
            const SizedBox(height: 8),
            Text(
              'Measure the refractive index using a refractometer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (minRI != null && maxRI != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRIValidationColor(theme).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRIValidationColor(theme).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: _getRIValidationIcon(),
                      color: _getRIValidationColor(theme),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getRIValidationMessage(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getRIValidationColor(theme),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRIValidationColor(ThemeData theme) {
    if (riController.text.isEmpty) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    final ri = double.tryParse(riController.text);
    if (ri == null) {
      return theme.colorScheme.error;
    }

    if (minRI != null && maxRI != null) {
      if (ri >= minRI! && ri <= maxRI!) {
        return theme.colorScheme.primary;
      } else {
        return theme.colorScheme.error;
      }
    }

    return theme.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  String _getRIValidationIcon() {
    if (riController.text.isEmpty) {
      return 'info_outline';
    }

    final ri = double.tryParse(riController.text);
    if (ri == null) {
      return 'error_outline';
    }

    if (minRI != null && maxRI != null) {
      if (ri >= minRI! && ri <= maxRI!) {
        return 'check_circle_outline';
      } else {
        return 'warning_amber';
      }
    }

    return 'info_outline';
  }

  String _getRIValidationMessage() {
    if (riController.text.isEmpty) {
      return minRI != null && maxRI != null
          ? 'Expected range: ${minRI!.toStringAsFixed(3)} - ${maxRI!.toStringAsFixed(3)}'
          : 'Enter the refractive index value';
    }

    final ri = double.tryParse(riController.text);
    if (ri == null) {
      return 'Please enter a valid number';
    }

    if (minRI != null && maxRI != null) {
      if (ri >= minRI! && ri <= maxRI!) {
        return 'RI value is within expected range for selected gemstone';
      } else {
        return 'RI value outside expected range (${minRI!.toStringAsFixed(3)} - ${maxRI!.toStringAsFixed(3)})';
      }
    }

    return 'RI value: ${ri.toStringAsFixed(3)}';
  }
}
