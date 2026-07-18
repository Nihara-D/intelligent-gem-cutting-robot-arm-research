import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/action_card_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/recent_analysis_card_widget.dart';

/// Home Dashboard - Luxury navigation hub for gemstone analysis
/// Implements tab bar navigation with Dashboard as active tab
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomNavIndex = 0;
  bool _isRefreshing = false;

  // Mock data for recent analyses
  final List<Map<String, dynamic>> _recentAnalyses = [
    {
      "id": 1,
      "gemName": "Blue Sapphire",
      "confidence": 94.5,
      "date": "2025-12-27",

      "image": "assets/images/BlueSapphire.jpg",

      "semanticLabel":
          "Deep blue sapphire gemstone with brilliant cut facets reflecting light against dark background",
      "classification": "Genuine Gemstone",
    },
    {
      "id": 2,
      "gemName": "Emerald",
      "confidence": 89.2,
      "date": "2025-12-26",
      "image": "assets/images/cut_recommendation_results/Emerald.png",
      "semanticLabel":
          "Rich green emerald gemstone with rectangular cut displaying natural inclusions",
      "classification": "Genuine Gemstone",
    },
    {
      "id": 3,
      "gemName": "Ruby",
      "confidence": 91.8,
      "date": "2025-12-25",
      "image": "assets/images/analysis_history/ruby-polished.jpg",
      "semanticLabel":
          "Vibrant red ruby gemstone with oval cut showing deep crimson color",
      "classification": "Genuine Gemstone",
    },
  ];

  // Quick stats data
  final Map<String, dynamic> _quickStats = {
    "totalAnalyses": 127,
    "accuracyRate": 92.3,
    "genuineDetected": 98,
    "cutRecommendations": 45,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/gemstone-detection-input');
        break;
      case 2:
        Navigator.pushNamed(context, '/cut-recommendation-input');
        break;
      case 3:
        Navigator.pushNamed(context, '/analysis-history');
        break;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recent analyses updated',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAnalysisCardTap(Map<String, dynamic> analysis) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/detection-results', arguments: analysis);
  }

  void _handleAnalysisCardLongPress(Map<String, dynamic> analysis) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContextMenu(analysis),
    );
  }

  Widget _buildContextMenu(Map<String, dynamic> analysis) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text('View Details', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _handleAnalysisCardTap(analysis);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Share Results', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share functionality coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: theme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Delete',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(analysis);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> analysis) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Analysis', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to delete this analysis?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _recentAnalyses.removeWhere(
                  (item) => item['id'] == analysis['id'],
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Analysis deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'GemVision AI',
        variant: CustomAppBarVariant.standard,
        centerTitle: false,
        showBackButton: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No new notifications'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          SizedBox(width: 2.w),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Detection'),
            Tab(text: 'Cut'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: _recentAnalyses.isEmpty
            ? _buildEmptyState()
            : _buildDashboardContent(),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          _handleTabChange(index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/gemstone-detection-input');
        },
        icon: CustomIconWidget(
          iconName: 'camera_alt',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text(
          'New Analysis',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.tertiary,
      ),
    );
  }

  Widget _buildDashboardContent() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting
            Text(
              'Welcome Back',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Analyze gemstones with AI precision',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 3.h),

            // Top Row: Two Cards
            Row(
              children: [
                Expanded(
                  child: ActionCardWidget(
                    title: 'Analyze\nGemstone',
                    iconName: 'camera_alt',
                    gradientColors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/gemstone-detection-input');
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ActionCardWidget(
                    title: 'Cut\nRecommendation',
                    iconName: 'auto_awesome',
                    gradientColors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.secondaryContainer,
                    ],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/cut-recommendation-input');
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Full Width: Gem Valuation Card (Professional & Prominent)
            ActionCardWidget(
              title: 'Gem\nValuation',
              iconName: 'attach_money',
              gradientColors: [
                theme.colorScheme.tertiary,
                theme.colorScheme.tertiaryContainer,
              ],
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/gem-valuation-input');
              },
            ),

            SizedBox(height: 4.h),

            // Quick Stats
            QuickStatsWidget(stats: _quickStats),
            SizedBox(height: 4.h),

            // Recent Analyses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Analyses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/analysis-history');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Recent Analysis Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentAnalyses.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final analysis = _recentAnalyses[index];
                return RecentAnalysisCardWidget(
                  analysis: analysis,
                  onTap: () => _handleAnalysisCardTap(analysis),
                  onLongPress: () => _handleAnalysisCardLongPress(analysis),
                );
              },
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                  iconName: 'auto_awesome',
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Start Your First Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Upload a gemstone image or enter properties to begin your AI-powered analysis journey',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, '/gemstone-detection-input');
              },
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text('Analyze Gemstone'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
