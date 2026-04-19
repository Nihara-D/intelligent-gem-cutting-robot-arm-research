import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResultDetailsScreen extends StatefulWidget {
  const ResultDetailsScreen({super.key});

  @override
  State<ResultDetailsScreen> createState() => _ResultDetailsScreenState();
}

class _ResultDetailsScreenState extends State<ResultDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper for glow colors based on confidence
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) return const Color(0xFF11D452); // Neon Green
    if (confidence >= 70) return const Color(0xFFFFD700); // Gold/Yellow
    return const Color(0xFFFF4D4D); // Red
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final apiResult = args['apiResult'] as Map<String, dynamic>? ?? {};
    final imagePath = args['imagePath'] as String?;
    final notes = args['notes'] as String? ?? '';

    final stoneData = apiResult['stone'] as Map<String, dynamic>? ?? {};
    final authData = apiResult['authentication'] as Map<String, dynamic>? ?? {};
    final originData = apiResult['origin'] as Map<String, dynamic>? ?? {};

    final stoneType = stoneData['label'] ?? 'Unknown Stone';
    final authentication = authData['label'] ?? 'Unknown';
    final origin = originData['label'] ?? 'Unknown';
    
    // Extract physical properties that might need to be passed forward
    final ri = args['ri'] as String?;

    final stoneConfidence = ((stoneData['confidence'] as num?)?.toDouble() ?? 0.0) * 100.0;
    final authConfidence = ((authData['confidence'] as num?)?.toDouble() ?? 0.0) * 100.0;
    final originConfidence = ((originData['confidence'] as num?)?.toDouble() ?? 0.0) * 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A140D), // Deeper, more premium dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Symbols.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 800;

          if (isTablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeroSection(context, imagePath: imagePath, isTablet: true),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    color: const Color(0xFF0A140D),
                    child: ListView(
                      padding: const EdgeInsets.only(top: 100, bottom: 120),
                      children: [
                         _buildDetailsSection(
                           context, 
                           stoneConfidence: stoneConfidence, 
                           stoneType: stoneType, 
                           authConfidence: authConfidence, 
                           authentication: authentication, 
                           originConfidence: originConfidence, 
                           origin: origin, 
                           notes: notes,
                         ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _buildHeroSection(context, imagePath: imagePath, isTablet: false),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: _buildDetailsSection(
                    context, 
                    stoneConfidence: stoneConfidence, 
                    stoneType: stoneType, 
                    authConfidence: authConfidence, 
                    authentication: authentication, 
                    originConfidence: originConfidence, 
                    origin: origin, 
                    notes: notes,
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomSheet: Container(
        color: const Color(0xFF0A140D),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), // extra padding for iOS home indicator
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF11D452).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/cut_recommendation', arguments: {
                'stoneType': stoneType,
                'imagePath': imagePath,
                'ri': ri, // Forward RI to cut advisor
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11D452),
              foregroundColor: const Color(0xFF0A140D),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Launch Cut Advisor',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Symbols.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, {required String? imagePath, required bool isTablet}) {
    return SizedBox(
      height: isTablet ? double.infinity : MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'gem_image_${imagePath ?? "default"}',
            child: Image(
              image: imagePath != null
                  ? (kIsWeb ? NetworkImage(imagePath) as ImageProvider : FileImage(File(imagePath)))
                  : const AssetImage('assets/images/NaturalEmerald.jpg'),
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.darken,
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          // Seamless Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isTablet ? Alignment.centerLeft : Alignment.topCenter,
                end: isTablet ? Alignment.centerRight : Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A140D).withOpacity(0.4),
                  Colors.transparent,
                  const Color(0xFF0A140D).withOpacity(isTablet ? 0.6 : 0.8),
                  const Color(0xFF0A140D),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context, {
    required double stoneConfidence,
    required String stoneType,
    required double authConfidence,
    required String authentication,
    required double originConfidence,
    required String origin,
    required String notes,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Glassmorphic Main Title Badge
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _getConfidenceColor(stoneConfidence).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getConfidenceColor(stoneConfidence).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  ),
                  child: Column(
                    children: [
                      Text(
                        'DETECTED GEMSTONE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stoneType.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                          shadows: [
                             Shadow(
                               color: _getConfidenceColor(stoneConfidence).withOpacity(0.8),
                               blurRadius: 15,
                             )
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Confidence Rings Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularIndicator('Match', stoneConfidence, Symbols.diamond),
                  _buildCircularIndicator('Authenticity', authConfidence, Symbols.verified),
                  _buildCircularIndicator('Origin', originConfidence, Symbols.public),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Detailed Stats Cards Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANALYSIS DETAILS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGlassCard(
                    icon: Symbols.verified,
                    title: 'Authentication',
                    value: authentication,
                    subtitle: 'Lab verification standard',
                    confidence: authConfidence,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    icon: Symbols.public,
                    title: 'Geological Origin',
                    value: origin,
                    subtitle: 'Estimated formation source',
                    confidence: originConfidence,
                  ),
                  
                  if (notes.isNotEmpty) ...[
                     const SizedBox(height: 24),
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.03),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.white10),
                       ),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Icon(Symbols.edit_note, color: Colors.white54, size: 20),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                               notes,
                               style: GoogleFonts.inter(
                                 fontSize: 14,
                                 color: Colors.white70,
                                 fontStyle: FontStyle.italic,
                                 height: 1.5,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Subtle Next Step Hint
                  Container(
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [
                         const Color(0xFF11D452).withOpacity(0.15),
                         const Color(0xFF0A140D).withOpacity(0.5),
                       ],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: const Color(0xFF11D452).withOpacity(0.3)),
                   ),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: const Color(0xFF11D452).withOpacity(0.2),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Symbols.auto_awesome, color: Color(0xFF11D452), size: 24),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'Unlock Potential',
                               style: GoogleFonts.outfit(
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                                 fontSize: 18,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               'Optimize the brilliance of this ${stoneType.toLowerCase()} using AI-driven cut recommendations.',
                               style: GoogleFonts.inter(
                                 fontSize: 13,
                                 color: Colors.white70,
                                 height: 1.4,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
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

  Widget _buildCircularIndicator(String label, double confidence, IconData icon) {
    final color = _getConfidenceColor(confidence);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: confidence / 100),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: color,
                    strokeCap: StrokeCap.round,
                  );
                }
              ),
            ),
            Icon(icon, color: Colors.white, size: 28),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${confidence.toStringAsFixed(0)}%',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required double confidence,
  }) {
    final glowColor = _getConfidenceColor(confidence);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: glowColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: glowColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${confidence.toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: glowColor,
                    ),
                  ),
                  Text(
                    'CONF.',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: glowColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
