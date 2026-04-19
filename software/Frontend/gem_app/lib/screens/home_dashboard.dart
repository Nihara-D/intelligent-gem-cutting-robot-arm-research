import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body behind bottom nav
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: _buildHeader(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            _buildQuickActions(context),
            _buildGemOfTheDay(context),
            _buildRecentAnalyses(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/detection_input'),
        backgroundColor: const Color(0xFF11D452),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF102216), width: 4),
        ),
        elevation: 8,
        child: const Icon(Symbols.add, size: 32, color: Color(0xFF102216)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102216).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF11D452).withOpacity(0.1)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Symbols.menu, color: Color(0xFF11D452)),
              onPressed: () {},
            ),
            Row(
              children: [
                const Icon(Symbols.diamond, color: Color(0xFF11D452)),
                const SizedBox(width: 8),
                Text(
                  'GemLens AI',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11D452), Color(0xFF065F46)],
                    ),
                    border: Border.all(color: const Color(0xFF11D452).withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Icon(Symbols.person, size: 16, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF102216), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Welcome back, ',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: 'Waruni',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF11D452), // Use primary solid color, or ShaderMask for gradient
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your studio is ready for analysis.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/detection_input'),
              child: const _ActionCard(
                title: 'Analyze Gemstone',
                subtitle: 'AI purity check',
                icon: Symbols.linked_camera,
                imageUrl: 'assets/images/NaturalEmerald.jpg',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cut_recommendation'),
              child: const _ActionCard(
                title: 'Cut Guide',
                subtitle: 'Optimize value',
                icon: Symbols.diamond,
                imageUrl: 'assets/images/BlueSapphire.jpg',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemOfTheDay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gem of the Day',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                ),
                child: Text(
                  'FEATURED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {}, // Could navigate to a specialized feature screen
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A3825),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF11D452).withOpacity(0.1)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      'assets/images/BlueSapphire.jpg',
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Royal Sapphire',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Corundum Family',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: const Color(0xFF11D452),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Symbols.bookmark, color: Colors.white54, size: 20),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Historically symbolizing nobility, truth, sincerity, and faithfulness. Learn about the new Padparadscha variants found in Madagascar.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white60,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalyses(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Analyses',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF11D452),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AnalysisListItem(
            title: 'Burmese Ruby #402',
            date: 'Mar 12, 10:23 AM',
            status: '98% Clarity',
            statusColor: const Color(0xFF11D452),
            imageUrl: 'assets/images/cabochon.jpg',
            onTap: () {
               Navigator.pushNamed(context, '/result_details', arguments: {
                  'stone': {'label': 'Ruby', 'confidence': 0.98},
                  'authentication': {'label': 'Natural', 'confidence': 0.99},
                  'origin': {'label': 'Burma', 'confidence': 0.85},
              });
            }
          ),
          const SizedBox(height: 12),
          _AnalysisListItem(
            title: 'Amethyst Cluster A7',
            date: 'Mar 11, 04:15 PM',
            status: 'Inclusions detected',
            statusColor: const Color(0xFFEAB308), // Yellow-500
            imageUrl: 'assets/images/cushion.png',
            onTap: () {
               Navigator.pushNamed(context, '/result_details', arguments: {
                  'stone': {'label': 'Amethyst', 'confidence': 0.95},
                  'authentication': {'label': 'Natural', 'confidence': 0.92},
                  'origin': {'label': 'Unknown', 'confidence': 0.40},
              });
            }
          ),
          const SizedBox(height: 12),
          _AnalysisListItem(
            title: 'Swiss Blue Topaz',
            date: 'Mar 10, 09:00 AM',
            status: 'Cut Rec. Ready',
            statusColor: const Color(0xFF11D452),
            imageUrl: 'assets/images/oval.png',
            onTap: () {
              Navigator.pushNamed(context, '/cut_analysis_result', arguments: {
                'stoneType': 'Topaz',
                'apiResult': {
                  'Best Exact Cut Recommendation': 'Oval',
                }
              });
            }
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF193322).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: const Color(0xFF23482F)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Already on home
                child: const _NavIcon(icon: Symbols.home, label: 'Home', isActive: true),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, '/detection_input'),
                child: const _NavIcon(icon: Symbols.diamond, label: 'Analyze'),
              ),
              const SizedBox(width: 48), // Space for FAB
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: const _NavIcon(icon: Symbols.history, label: 'History'),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192, // h-48 = 12rem = 192px
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF11D452).withOpacity(0.2)),
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF11D452).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF11D452)),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
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

class _AnalysisListItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final Color statusColor;
  final String imageUrl;
  final VoidCallback onTap;

  const _AnalysisListItem({
    required this.title,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3825),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF11D452).withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Symbols.chevron_right, color: Colors.white30),
          ],
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
    final color = isActive ? Colors.white : const Color(0xFF92C9A4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
