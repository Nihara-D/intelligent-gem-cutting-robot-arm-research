import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for the bottom bar
class CustomBottomBarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final int? badgeCount;

  const CustomBottomBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.badgeCount,
  });
}

/// Custom bottom navigation bar
class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;
  final double? elevation;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
    this.elevation,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  static const List<CustomBottomBarItem> _navigationItems = [
    CustomBottomBarItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/home-dashboard',
    ),
    CustomBottomBarItem(
      label: 'Detection',
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
      route: '/gemstone-detection-input',
    ),
    CustomBottomBarItem(
      label: 'Cut',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      route: '/cut-recommendation-input',
    ),
    CustomBottomBarItem(
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      route: '/analysis-history',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation =
        Tween<double>(begin: 1, end: 0.95).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;

    HapticFeedback.lightImpact();

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    Navigator.pushNamed(context, _navigationItems[index].route);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor =
        widget.backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor ?? colorScheme.surface;

    final selectedColor =
        widget.selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor ?? colorScheme.primary;

    final unselectedColor =
        widget.unselectedItemColor ?? theme.bottomNavigationBarTheme.unselectedItemColor ??
            colorScheme.onSurface.withOpacity(0.6);

    final elevation = widget.elevation ?? theme.bottomNavigationBarTheme.elevation ?? 8.0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.12),
            blurRadius: elevation * 2,
            offset: Offset(0, -elevation / 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72, // ✅ SAFE HEIGHT
          child: Row(
            children: List.generate(
              _navigationItems.length,
              (index) => _buildNavigationItem(
                context,
                index,
                _navigationItems[index],
                selectedColor,
                unselectedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    int index,
    CustomBottomBarItem item,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final theme = Theme.of(context);
    final isSelected = index == widget.currentIndex;

    return Expanded(
      child: ScaleTransition(
        scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1),
        child: InkWell(
          onTap: () => _handleTap(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: selectedColor.withOpacity(0.1),
          highlightColor: selectedColor.withOpacity(0.05),
          child: SizedBox(
            height: 56, // ✅ MATERIAL MINIMUM
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        size: 24, // ✅ REDUCED SIZE
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              height: 1,
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.showLabels) ...[
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (isSelected
                            ? theme.bottomNavigationBarTheme.selectedLabelStyle
                            : theme.bottomNavigationBarTheme.unselectedLabelStyle)
                        ?.copyWith(
                          height: 1.1, // ✅ PREVENTS OVERFLOW
                        ) ??
                        theme.textTheme.labelSmall!.copyWith(
                          height: 1.1,
                          color: isSelected ? selectedColor : unselectedColor,
                        ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension helper
extension CustomBottomBarExtension on Widget {
  Widget withCustomBottomBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool showLabels = true,
    double? elevation,
    Color? backgroundColor,
    Color? selectedItemColor,
    Color? unselectedItemColor,
  }) {
    return Scaffold(
      body: this,
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: onTap,
        showLabels: showLabels,
        elevation: elevation,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
      ),
    );
  }
}
