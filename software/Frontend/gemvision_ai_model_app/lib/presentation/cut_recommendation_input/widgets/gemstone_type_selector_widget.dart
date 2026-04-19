import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Gemstone type data model
class GemstoneType {
  final String name;
  final String imageUrl;
  final String semanticLabel;
  final double minRI;
  final double maxRI;

  const GemstoneType({
    required this.name,
    required this.imageUrl,
    required this.semanticLabel,
    required this.minRI,
    required this.maxRI,
  });
}

/// Gemstone type selector widget with search and thumbnails
class GemstoneTypeSelectorWidget extends StatelessWidget {
  final GemstoneType? selectedGemstone;
  final ValueChanged<GemstoneType?> onChanged;

  const GemstoneTypeSelectorWidget({
    super.key,
    required this.selectedGemstone,
    required this.onChanged,
  });

  static const List<GemstoneType> gemstoneTypes = [
    GemstoneType(
      name: 'Diamond',
      imageUrl: 'assets/images/analysis_history/diamond.jpg',
      semanticLabel:
          'Brilliant cut diamond with white sparkle on dark background',
      minRI: 2.417,
      maxRI: 2.419,
    ),
    GemstoneType(
      name: 'Ruby',
      imageUrl: 'assets/images/analysis_history/ruby-polished.jpg',
      semanticLabel: 'Deep red ruby gemstone with rich crimson color',
      minRI: 1.762,
      maxRI: 1.770,
    ),
    GemstoneType(
      name: 'Sapphire',
      imageUrl: 'assets/images/analysis_history/sapphire.jpg',
      semanticLabel: 'Blue sapphire gemstone with deep azure color',
      minRI: 1.762,
      maxRI: 1.770,
    ),
    GemstoneType(
      name: 'Emerald',
      imageUrl: 'assets/images/analysis_history/Emarald.png',
      semanticLabel: 'Green emerald gemstone with vibrant forest green color',
      minRI: 1.577,
      maxRI: 1.583,
    ),
    GemstoneType(
      name: 'Amethyst',
      imageUrl: 'assets/images/analysis_history/amethyst.jpg',
      semanticLabel: 'Purple amethyst gemstone with violet hue',
      minRI: 1.544,
      maxRI: 1.553,
    ),
    GemstoneType(
      name: 'Topaz',
      imageUrl: 'assets/images/analysis_history/topaz.png',
      semanticLabel: 'Golden topaz gemstone with warm amber color',
      minRI: 1.609,
      maxRI: 1.643,
    ),
    GemstoneType(
      name: 'Aquamarine',
      imageUrl: 'assets/images/analysis_history/aquamarine.jpg',
      semanticLabel: 'Light blue aquamarine gemstone with sea-like color',
      minRI: 1.577,
      maxRI: 1.583,
    ),
    GemstoneType(
      name: 'Garnet',
      imageUrl: 'assets/images/analysis_history/garnet.png',
      semanticLabel: 'Dark red garnet gemstone with burgundy color',
      minRI: 1.714,
      maxRI: 1.888,
    ),
    GemstoneType(
      name: 'Peridot',
      imageUrl: 'assets/images/analysis_history/peridot.jpg',
      semanticLabel: 'Olive green peridot gemstone with lime color',
      minRI: 1.654,
      maxRI: 1.690,
    ),
    GemstoneType(
      name: 'Opal',
      imageUrl: 'assets/images/analysis_history/opal.png',
      semanticLabel:
          'Multicolored opal gemstone with iridescent play of colors',
      minRI: 1.450,
      maxRI: 1.460,
    ),
  ];

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
                  iconName: 'diamond',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gemstone Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownSearch<GemstoneType>(
              items: (filter, loadProps) async => gemstoneTypes,
              selectedItem: selectedGemstone,
              onChanged: onChanged,
              itemAsString: (GemstoneType gemstone) => gemstone.name,
              compareFn: (item1, item2) => item1.name == item2.name,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  hintText: 'Select gemstone type',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search gemstones...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isDisabled, isSelected) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomImageWidget(
                            imageUrl: item.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            semanticLabel: item.semanticLabel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RI: ${item.minRI.toStringAsFixed(3)} - ${item.maxRI.toStringAsFixed(3)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                },
                menuProps: MenuProps(
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                ),
              ),
            ),
            if (selectedGemstone != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Expected RI range: ${selectedGemstone!.minRI.toStringAsFixed(3)} - ${selectedGemstone!.maxRI.toStringAsFixed(3)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
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
}
