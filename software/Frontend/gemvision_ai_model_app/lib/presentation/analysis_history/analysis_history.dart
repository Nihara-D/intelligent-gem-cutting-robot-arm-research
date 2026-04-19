import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/history_card_widget.dart';
import './widgets/statistics_card_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/filter_bottom_sheet_widget.dart';
import 'widgets/history_card_widget.dart';
import 'widgets/statistics_card_widget.dart';

class AnalysisHistory extends StatefulWidget {
  const AnalysisHistory({super.key});

  @override
  State<AnalysisHistory> createState() => _AnalysisHistoryState();
}

class _AnalysisHistoryState extends State<AnalysisHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  bool _isLoading = false;
  bool _isMultiSelectMode = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  Set<int> _selectedItems = {};

  // Mock data for analysis history
  final List<Map<String, dynamic>> _allAnalyses = [
    {
      "id": 1,
      "type": "detection",
      "thumbnail": "assets/images/analysis_history/emerald.png",
      "semanticLabel":
          "Close-up of a brilliant cut emerald gemstone with deep green color on black background",
      "name": "Emerald",
      "date": DateTime(2025, 12, 27, 14, 30),
      "confidence": 94.5,
      "status": "genuine",
      "properties": {
        "ri": "1.577-1.583",
        "sg": "2.70-2.78",
        "hardness": "7.5-8.0",
      },
    },
    {
      "id": 2,
      "type": "cut_recommendation",
      "thumbnail": "assets/images/analysis_history/sapphire.jpg",
      "semanticLabel":
          "Oval cut sapphire gemstone with brilliant blue color on white background",
      "name": "Sapphire",
      "date": DateTime(2025, 12, 26, 10, 15),
      "confidence": 89.2,
      "status": "genuine",
      "cutType": "Oval",
      "properties": {
        "pavilionAngle": "40.8°",
        "crownAngle": "34.5°",
        "tablePercentage": "58%",
      },
    },
    {
      "id": 3,
      "type": "detection",
      "thumbnail": "assets/images/analysis_history/diamond.jpg",
      "semanticLabel":
          "Round brilliant cut diamond with exceptional clarity on dark surface",
      "name": "Diamond",
      "date": DateTime(2025, 12, 25, 16, 45),
      "confidence": 97.8,
      "status": "genuine",
      "properties": {"ri": "2.417", "sg": "3.52", "hardness": "10.0"},
    },
    {
      "id": 4,
      "type": "detection",
      "thumbnail": "assets/images/analysis_history/ruby-polished.jpg",
      "semanticLabel":
          "Cushion cut ruby gemstone with deep red color and excellent transparency",
      "name": "Ruby",
      "date": DateTime(2025, 12, 24, 11, 20),
      "confidence": 91.3,
      "status": "genuine",
      "properties": {"ri": "1.762-1.770", "sg": "3.97-4.05", "hardness": "9.0"},
    },
    {
      "id": 5,
      "type": "cut_recommendation",
      "thumbnail": "assets/images/analysis_history/amethyst.jpg",
      "semanticLabel":
          "Pear shaped amethyst gemstone with purple hue on neutral background",
      "name": "Amethyst",
      "date": DateTime(2025, 12, 23, 9, 30),
      "confidence": 86.7,
      "status": "genuine",
      "cutType": "Pear",
      "properties": {
        "pavilionAngle": "42.0°",
        "crownAngle": "35.0°",
        "tablePercentage": "56%",
      },
    },
    {
      "id": 6,
      "type": "detection",
      "thumbnail": "assets/images/analysis_history/topaz.png",
      "semanticLabel":
          "Emerald cut topaz gemstone with golden yellow color and high clarity",
      "name": "Topaz",
      "date": DateTime(2025, 12, 22, 15, 10),
      "confidence": 88.9,
      "status": "genuine",
      "properties": {"ri": "1.609-1.643", "sg": "3.49-3.57", "hardness": "8.0"},
    },
    {
      "id": 7,
      "type": "detection",
      "thumbnail": "assets/images/analysis_history/garnet.png",
      "semanticLabel":
          "Round cut garnet gemstone with deep red color on black velvet",
      "name": "Garnet",
      "date": DateTime(2025, 12, 21, 13, 45),
      "confidence": 92.1,
      "status": "genuine",
      "properties": {
        "ri": "1.714-1.888",
        "sg": "3.47-4.15",
        "hardness": "6.5-7.5",
      },
    },
    {
      "id": 8,
      "type": "cut_recommendation",
      "thumbnail": "assets/images/analysis_history/opal.png",
      "semanticLabel":
          "Cabochon cut opal gemstone showing play of color with blue and green flashes",
      "name": "Opal",
      "date": DateTime(2025, 12, 20, 10, 30),
      "confidence": 84.5,
      "status": "genuine",
      "cutType": "Cabochon",
      "properties": {
        "pavilionAngle": "N/A",
        "crownAngle": "N/A",
        "tablePercentage": "100%",
      },
    },
  ];

  List<Map<String, dynamic>> _filteredAnalyses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredAnalyses = List.from(_allAnalyses);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreAnalyses();
    }
  }

  Future<void> _loadMoreAnalyses() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isLoading = false);
  }

  Future<void> _refreshAnalyses() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _filteredAnalyses = List.from(_allAnalyses);
    });
  }

  void _filterAnalyses(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAnalyses = List.from(_allAnalyses);
      } else {
        _filteredAnalyses = _allAnalyses
            .where(
              (analysis) => (analysis["name"] as String).toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilter: _selectedFilter,
        onFilterApplied: (filter) {
          setState(() {
            _selectedFilter = filter;
            _applyFilter(filter);
          });
        },
      ),
    );
  }

  void _applyFilter(String filter) {
    setState(() {
      if (filter == 'All') {
        _filteredAnalyses = List.from(_allAnalyses);
      } else if (filter == 'Detection') {
        _filteredAnalyses = _allAnalyses
            .where((analysis) => analysis["type"] == "detection")
            .toList();
      } else if (filter == 'Cut Recommendation') {
        _filteredAnalyses = _allAnalyses
            .where((analysis) => analysis["type"] == "cut_recommendation")
            .toList();
      } else if (filter == 'High Confidence') {
        _filteredAnalyses = _allAnalyses
            .where((analysis) => (analysis["confidence"] as double) >= 90.0)
            .toList();
      } else if (filter == 'This Week') {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        _filteredAnalyses = _allAnalyses
            .where(
              (analysis) => (analysis["date"] as DateTime).isAfter(weekAgo),
            )
            .toList();
      }
    });
  }

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedItems.contains(id)
          ? _selectedItems.remove(id)
          : _selectedItems.add(id);
    });
  }

  void _exportSelected() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export Analyses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Export ${_selectedItems.length} selected analyses?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Exported ${_selectedItems.length} analyses successfully',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {
                _isMultiSelectMode = false;
                _selectedItems.clear();
              });
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Analyses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Delete ${_selectedItems.length} selected analyses? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allAnalyses.removeWhere(
                  (analysis) => _selectedItems.contains(analysis["id"]),
                );
                _filteredAnalyses = List.from(_allAnalyses);
                _isMultiSelectMode = false;
                _selectedItems.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analyses deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> analysis) {
    HapticFeedback.lightImpact();
    final type = analysis["type"] as String;
    type == "detection"
        ? Navigator.pushNamed(context, '/detection-results')
        : Navigator.pushNamed(context, '/cut-recommendation-results');
  }

  void _shareAnalysis(Map<String, dynamic> analysis) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${analysis["name"]} analysis...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateAnalysis(Map<String, dynamic> analysis) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating ${analysis["name"]} analysis...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteAnalysis(Map<String, dynamic> analysis) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Delete ${analysis["name"]} analysis? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allAnalyses.removeWhere(
                  (item) => item["id"] == analysis["id"],
                );
                _filteredAnalyses = List.from(_allAnalyses);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
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
        title: _isSearching ? null : 'Analysis History',
        variant: _isSearching
            ? CustomAppBarVariant.search
            : CustomAppBarVariant.standard,
        showBackButton: false,
        searchController: _searchController,
        searchHint: 'Search gemstones...',
        onSearchChanged: _filterAnalyses,
        onSearchSubmitted: _filterAnalyses,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'search',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isSearching = true);
              },
              tooltip: 'Search',
            ),
          if (_isSearching)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filterAnalyses('');
                });
              },
              tooltip: 'Close search',
            ),
          if (!_isSearching)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'filter_list',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filter',
            ),
          if (_isMultiSelectMode)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleMultiSelect,
              tooltip: 'Cancel selection',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHistoryTab(theme), _buildStatisticsTab(theme)],
      ),
      bottomNavigationBar: _isMultiSelectMode
          ? _buildMultiSelectBottomBar(theme)
          : CustomBottomBar(
              currentIndex: 3,
              onTap: (index) {
                if (index == 0) Navigator.pushNamed(context, '/home-dashboard');
                if (index == 1)
                  Navigator.pushNamed(context, '/gemstone-detection-input');
                if (index == 2)
                  Navigator.pushNamed(context, '/cut-recommendation-input');
              },
            ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return _filteredAnalyses.isEmpty
        ? EmptyStateWidget(
            onStartAnalysis: () {
              Navigator.pushNamed(context, '/gemstone-detection-input');
            },
          )
        : RefreshIndicator(
            onRefresh: _refreshAnalyses,
            color: theme.colorScheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: _filteredAnalyses.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredAnalyses.length) {
                  return _buildLoadingIndicator(theme);
                }

                final analysis = _filteredAnalyses[index];
                final isSelected = _selectedItems.contains(analysis["id"]);

                return GestureDetector(
                  onLongPress: () {
                    if (!_isMultiSelectMode) {
                      _toggleMultiSelect();
                      _toggleItemSelection(analysis["id"] as int);
                    }
                  },
                  onTap: () {
                    _isMultiSelectMode
                        ? _toggleItemSelection(analysis["id"] as int)
                        : _viewDetails(analysis);
                  },
                  child: Slidable(
                    key: ValueKey(analysis["id"]),
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => _viewDetails(analysis),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          icon: Icons.visibility,
                          label: 'View',
                        ),
                        SlidableAction(
                          onPressed: (_) => _shareAnalysis(analysis),
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          icon: Icons.share,
                          label: 'Share',
                        ),
                        SlidableAction(
                          onPressed: (_) => _duplicateAnalysis(analysis),
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: theme.colorScheme.onTertiary,
                          icon: Icons.content_copy,
                          label: 'Duplicate',
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => _deleteAnalysis(analysis),
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: HistoryCardWidget(
                      analysis: analysis,
                      isSelected: isSelected,
                      isMultiSelectMode: _isMultiSelectMode,
                      onTap: () {
                        _isMultiSelectMode
                            ? _toggleItemSelection(analysis["id"] as int)
                            : _viewDetails(analysis);
                      },
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildStatisticsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          StatisticsCardWidget(
            title: 'Total Analyses',
            value: _allAnalyses.length.toString(),
            icon: 'analytics',
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          StatisticsCardWidget(
            title: 'Average Confidence',
            value:
                '${(_allAnalyses.fold<double>(0, (sum, item) => sum + (item["confidence"] as double)) / _allAnalyses.length).toStringAsFixed(1)}%',
            icon: 'trending_up',
            color: theme.colorScheme.secondary,
          ),
          SizedBox(height: 2.h),
          StatisticsCardWidget(
            title: 'Detection Analyses',
            value: _allAnalyses
                .where((item) => item["type"] == "detection")
                .length
                .toString(),
            icon: 'camera_alt',
            color: theme.colorScheme.tertiary,
          ),
          SizedBox(height: 2.h),
          StatisticsCardWidget(
            title: 'Cut Recommendations',
            value: _allAnalyses
                .where((item) => item["type"] == "cut_recommendation")
                .length
                .toString(),
            icon: 'auto_awesome',
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 3.h),
          Text(
            'Recent Activity',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildActivityChart(theme),
        ],
      ),
    );
  }

  Widget _buildActivityChart(ThemeData theme) {
    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyses per Day (Last 7 Days)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final height = (index + 1) * 3.h;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8.w,
                      height: height,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text('Day ${index + 1}', style: theme.textTheme.labelSmall),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildMultiSelectBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedItems.isEmpty ? null : _exportSelected,
                icon: CustomIconWidget(
                  iconName: 'file_download',
                  color: _selectedItems.isEmpty
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text('Export (${_selectedItems.length})'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedItems.isEmpty ? null : _deleteSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                icon: CustomIconWidget(
                  iconName: 'delete',
                  color: _selectedItems.isEmpty
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : theme.colorScheme.onError,
                  size: 20,
                ),
                label: Text('Delete (${_selectedItems.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
