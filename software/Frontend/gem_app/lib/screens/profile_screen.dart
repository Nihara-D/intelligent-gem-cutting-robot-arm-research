import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Profile',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Profile Header
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11D452), Color(0xFF065F46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFF11D452).withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF11D452).withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Symbols.person, size: 48, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3825),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF102216), width: 2),
                      ),
                      child: const Icon(Symbols.edit, size: 16, color: Color(0xFF11D452)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Waruni',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'waruni@gemlens.ai',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Text(
                'PRO MEMBER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Settings Sections
            _buildSettingsGroup(
              title: 'ACCOUNT',
              items: [
                _buildSettingsItem(
                  icon: Symbols.person_outline,
                  title: 'Personal Information',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: Symbols.workspace_premium,
                  title: 'Subscription',
                  onTap: () {},
                ),
              ],
            ),
            
            _buildSettingsGroup(
              title: 'PREFERENCES',
              items: [
                _buildSettingsItem(
                  icon: Symbols.palette,
                  title: 'App Theme',
                  subtitle: 'Dark',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: Symbols.notifications,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: Symbols.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
              ],
            ),

            _buildSettingsGroup(
              title: 'SUPPORT',
              items: [
                _buildSettingsItem(
                  icon: Symbols.help,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _buildSettingsItem(
                  icon: Symbols.description,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'GemLens AI v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white24,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF183222),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final int index = entry.key;
              final Widget item = entry.value;
              return Column(
                children: [
                  item,
                  if (index != items.length - 1)
                    const Divider(height: 1, color: Colors.white10, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF11D452).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF11D452), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Symbols.chevron_right, color: Colors.white30, size: 20),
        ],
      ),
      onTap: onTap,
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
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: const _NavIcon(icon: Symbols.history, label: 'History'),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Already on profile
                child: const _NavIcon(icon: Symbols.person, label: 'Profile', isActive: true),
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
