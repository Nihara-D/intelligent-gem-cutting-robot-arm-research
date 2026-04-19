import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String date;
  final String type;
  final String category; // 'Detection', 'Cut Rec'
  final bool isVerified;
  final bool isPending;
  final bool isFavorite;
  final String imageUrl;

  HistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.type,
    required this.category,
    this.isVerified = false,
    this.isPending = false,
    this.isFavorite = false,
    required this.imageUrl,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  final List<HistoryItem> _allHistory = [
    HistoryItem(
      id: '1',
      title: 'Oval Brilliant Cut',
      subtitle: 'Found in rough scan #204',
      time: '2:45 PM',
      date: 'TODAY',
      type: 'Ruby',
      category: 'Cut Rec',
      isVerified: true,
      isFavorite: true,
      imageUrl: 'assets/images/oval.png',
    ),
    HistoryItem(
      id: '2',
      title: 'Cushion Mixed Cut',
      subtitle: 'High clarity, potential inclusion',
      time: '10:12 AM',
      date: 'TODAY',
      type: 'Sapphire',
      category: 'Detection',
      isVerified: false,
      isFavorite: false,
      imageUrl: 'assets/images/cushion.png',
    ),
    HistoryItem(
      id: '3',
      title: 'Emerald Step Cut',
      subtitle: 'Excellent symmetry detected',
      time: '4:20 PM',
      date: 'YESTERDAY',
      type: 'Emerald',
      category: 'Cut Rec',
      isVerified: true,
      isFavorite: true,
      imageUrl: 'assets/images/emerald.png',
    ),
    HistoryItem(
      id: '4',
      title: 'Round Brilliant',
      subtitle: 'Raw diamond analysis pending',
      time: '11:05 AM',
      date: 'YESTERDAY',
      type: 'Diamond',
      category: 'Detection',
      isPending: true,
      isFavorite: false,
      imageUrl: 'assets/images/placeholder.png',
    ),
  ];

  List<HistoryItem> get _filteredHistory {
    if (_selectedFilter == 'All') {
      return _allHistory;
    } else if (_selectedFilter == 'Favorites') {
      return _allHistory.where((item) => item.isFavorite).toList();
    } else {
      return _allHistory.where((item) => item.category == _selectedFilter).toList();
    }
  }

  void _navigateToDetails(HistoryItem item) {
    if (item.category == 'Detection') {
      Navigator.pushNamed(
        context,
        '/result_details',
        arguments: {
          'stone': {'label': item.type, 'confidence': 0.98},
          'authentication': {'label': 'Natural', 'confidence': 0.95},
          'origin': {'label': 'Unknown', 'confidence': 0.5},
        },
      );
    } else if (item.category == 'Cut Rec') {
      Navigator.pushNamed(
        context,
        '/cut_analysis_result',
        arguments: {
          'stoneType': item.type,
          'apiResult': {
            'Best Exact Cut Recommendation': item.title.replaceAll(' Cut', ''),
          }
        },
      );
    }
  }

  void _toggleFavorite(HistoryItem item) {
    setState(() {
      final index = _allHistory.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        _allHistory[index] = HistoryItem(
          id: item.id,
          title: item.title,
          subtitle: item.subtitle,
          time: item.time,
          date: item.date,
          type: item.type,
          category: item.category,
          isVerified: item.isVerified,
          isPending: item.isPending,
          imageUrl: item.imageUrl,
          isFavorite: !item.isFavorite,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;
    
    // Group by date
    final Map<String, List<HistoryItem>> grouped = {};
    for (var item in filtered) {
      if (!grouped.containsKey(item.date)) {
        grouped[item.date] = [];
      }
      grouped[item.date]!.add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF102216),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              color: const Color(0xFF102216).withOpacity(0.9),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Symbols.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Analysis History',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Spacer
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 12),
                _buildFilterChip('Detection'),
                const SizedBox(width: 12),
                _buildFilterChip('Cut Rec'),
                const SizedBox(width: 12),
                _buildFilterChip('Favorites'),
              ],
            ),
          ),
          
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Symbols.history, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'No history found',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final dateStr = grouped.keys.elementAt(index);
                      final items = grouped[dateStr]!;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index > 0) const SizedBox(height: 24),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: item.isPending
                                    ? _buildPendingCard(item)
                                    : _buildHistoryCard(item),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF11D452) : const Color(0xFF183222),
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.white10),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF11D452).withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF102216) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return GestureDetector(
      onTap: () => _navigateToDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF183222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image Area
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          if (item.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Symbols.verified, color: Color(0xFF11D452), size: 20),
                            ),
                          GestureDetector(
                            onTap: () => _toggleFavorite(item),
                            child: Icon(
                              item.isFavorite ? Symbols.favorite : Symbols.favorite,
                              fill: item.isFavorite ? 1.0 : 0.0,
                              color: item.isFavorite ? Colors.redAccent : Colors.white54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF11D452),
                            ),
                          ),
                          const Icon(Symbols.chevron_right, color: Color(0xFF11D452), size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(HistoryItem item) {
    return GestureDetector(
      onTap: () => _navigateToDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF183222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Placeholder Image Area
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10, style: BorderStyle.none),
                color: const Color(0xFF102216),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Symbols.diamond, color: Colors.white24, size: 32),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(item),
                        child: Icon(
                          item.isFavorite ? Symbols.favorite : Symbols.favorite,
                          fill: item.isFavorite ? 1.0 : 0.0,
                          color: item.isFavorite ? Colors.redAccent : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF11D452),
                            ),
                          ),
                          const Icon(Symbols.chevron_right, color: Color(0xFF11D452), size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102216).withOpacity(0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: const _NavIcon(icon: Symbols.home, label: 'Home'),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, '/detection_input'),
                child: const _NavIcon(icon: Symbols.photo_camera, label: 'Scan'),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Already on history
                child: const _NavIcon(icon: Symbols.history, label: 'History', isActive: true),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: const _NavIcon(icon: Symbols.person, label: 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavIcon({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF11D452).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF11D452), size: 24),
          )
        else
          Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }
}
