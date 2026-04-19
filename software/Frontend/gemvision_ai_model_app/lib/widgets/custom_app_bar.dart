import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with back button and title
  detail,

  /// Transparent app bar for overlays
  transparent,

  /// App bar with large title (iOS style)
  large,
}

/// Custom app bar with luxury theming and contextual variants
/// Implements Refined Technical Luxury design for professional gemstone analysis
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title
  final String? title;

  /// App bar variant
  final CustomAppBarVariant variant;

  /// Leading widget (overrides default back button)
  final Widget? leading;

  /// Action widgets
  final List<Widget>? actions;

  /// Whether to show back button
  final bool showBackButton;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom foreground color
  final Color? foregroundColor;

  /// Custom elevation
  final double? elevation;

  /// Whether to center title
  final bool centerTitle;

  /// Search controller for search variant
  final TextEditingController? searchController;

  /// Search hint text
  final String? searchHint;

  /// Search callback
  final ValueChanged<String>? onSearchChanged;

  /// Search submit callback
  final ValueChanged<String>? onSearchSubmitted;

  /// Bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Flexible space widget for large variant
  final Widget? flexibleSpace;

  /// Custom height
  final double? toolbarHeight;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.bottom,
    this.flexibleSpace,
    this.toolbarHeight,
  });

  @override
  Size get preferredSize {
    final double height = toolbarHeight ?? kToolbarHeight;
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    final double totalHeight = variant == CustomAppBarVariant.large
        ? height + 52 + bottomHeight
        : height + bottomHeight;
    return Size.fromHeight(totalHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final colorScheme = theme.colorScheme;

    final bgColor =
        backgroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? Colors.transparent
            : appBarTheme.backgroundColor ?? colorScheme.surface);

    final fgColor =
        foregroundColor ?? appBarTheme.foregroundColor ?? colorScheme.onSurface;

    final appBarElevation = variant == CustomAppBarVariant.transparent
        ? 0.0
        : (elevation ?? appBarTheme.elevation ?? 0.0);

    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchAppBar(context, bgColor, fgColor, appBarElevation);
      case CustomAppBarVariant.large:
        return _buildLargeAppBar(context, bgColor, fgColor, appBarElevation);
      default:
        return _buildStandardAppBar(context, bgColor, fgColor, appBarElevation);
    }
  }

  Widget _buildStandardAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
    double appBarElevation,
  ) {
    final theme = Theme.of(context);

    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: theme.appBarTheme.titleTextStyle?.copyWith(color: fgColor),
            )
          : null,
      leading: _buildLeading(context, fgColor),
      actions: _buildActions(context, fgColor),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: appBarElevation,
      centerTitle: centerTitle,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: _getSystemOverlayStyle(context, bgColor),
    );
  }

  Widget _buildSearchAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
    double appBarElevation,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: searchHint ?? 'Search gemstones...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            suffixIcon: searchController?.text.isNotEmpty ?? false
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () {
                      searchController?.clear();
                      onSearchChanged?.call('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
      leading: _buildLeading(context, fgColor),
      actions: _buildActions(context, fgColor),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: appBarElevation,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: _getSystemOverlayStyle(context, bgColor),
    );
  }

  Widget _buildLargeAppBar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
    double appBarElevation,
  ) {
    final theme = Theme.of(context);

    return SliverAppBar(
      title: Text(
        title ?? '',
        style: theme.appBarTheme.titleTextStyle?.copyWith(color: fgColor),
      ),
      leading: _buildLeading(context, fgColor),
      actions: _buildActions(context, fgColor),
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: appBarElevation,
      centerTitle: centerTitle,
      pinned: true,
      expandedHeight: (toolbarHeight ?? kToolbarHeight) + 52,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title ?? '',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: flexibleSpace,
      ),
      bottom: bottom,
      systemOverlayStyle: _getSystemOverlayStyle(context, bgColor),
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (leading != null) return leading;

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: Icon(Icons.arrow_back, color: fgColor),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        tooltip: 'Back',
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context, Color fgColor) {
    if (actions == null) return null;

    return actions!.map((action) {
      if (action is IconButton) {
        return IconButton(
          icon: action.icon,
          onPressed: () {
            HapticFeedback.lightImpact();
            action.onPressed?.call();
          },
          tooltip: action.tooltip,
          color: fgColor,
        );
      }
      return action;
    }).toList();
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(
    BuildContext context,
    Color bgColor,
  ) {
    final brightness = ThemeData.estimateBrightnessForColor(bgColor);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      statusBarBrightness: brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
    );
  }
}

/// Extension to easily add CustomAppBar to Scaffold
extension CustomAppBarExtension on Widget {
  Widget withCustomAppBar({
    String? title,
    CustomAppBarVariant variant = CustomAppBarVariant.standard,
    Widget? leading,
    List<Widget>? actions,
    bool showBackButton = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = false,
    TextEditingController? searchController,
    String? searchHint,
    ValueChanged<String>? onSearchChanged,
    ValueChanged<String>? onSearchSubmitted,
    PreferredSizeWidget? bottom,
    Widget? flexibleSpace,
    double? toolbarHeight,
  }) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        variant: variant,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        centerTitle: centerTitle,
        searchController: searchController,
        searchHint: searchHint,
        onSearchChanged: onSearchChanged,
        onSearchSubmitted: onSearchSubmitted,
        bottom: bottom,
        flexibleSpace: flexibleSpace,
        toolbarHeight: toolbarHeight,
      ),
      body: this,
    );
  }
}
