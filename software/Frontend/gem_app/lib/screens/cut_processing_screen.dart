import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../services/api_service.dart';

class CutProcessingScreen extends StatefulWidget {
  const CutProcessingScreen({super.key});

  @override
  State<CutProcessingScreen> createState() => _CutProcessingScreenState();
}

class _CutProcessingScreenState extends State<CutProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  bool _isProcessing = true;
  String _statusMessage = 'Initializing gem calculation...';
  String? _imagePath;
  Map<String, dynamic>? _apiResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && _imagePath == null) {
      _imagePath = args['imagePath'] as String?;
      _processCutRecommendation(args);
    }
  }

  Future<void> _processCutRecommendation(Map<String, dynamic> args) async {
    try {
      setState(() {
        _statusMessage = 'Calculating predictive 3D geometry...';
      });

      final result = await ApiService.recommendCut(
        gemstoneType: args['stoneType'] as String? ?? 'Garnet',
        ri: args['ri'] as double,
        caratWeight: args['carat'] as double,
        lengthMm: args['length'] as double,
        widthMm: args['width'] as double,
        depthMm: args['depth'] as double,
      );

      setState(() {
        _statusMessage = 'Calculations complete. Mapping to 3D shapes...';
        _apiResult = result;
      });

      // Brief delay to let the user see the "complete" message
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/cut_analysis_result',
          arguments: {
            'apiResult': _apiResult,
            'imagePath': _imagePath,
            'stoneType': args['stoneType'] as String?,
            'length': args['length'] as double,
            'width': args['width'] as double,
            'depth': args['depth'] as double,
          }
        );
      }
    } catch (e) {
      debugPrint('Error in _processCutRecommendation: $e');
      setState(() {
        _isProcessing = false;
        _error = e.toString();
        _statusMessage = 'Calculation failed.';
      });
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102216),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Symbols.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Cut AI Processing',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF11D452),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF11D452).withOpacity(0.1),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.8,
                            child: _imagePath != null
                                ? (kIsWeb
                                    ? Image.network(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ))
                                : Image.asset(
                                    'assets/images/cut_recommendation_result/Cabochon.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        // Dark overlay
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF102216).withOpacity(0.4),
                          ),
                        ),
                        // Scanner
                        if (_isProcessing && _error == null)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                return Align(
                                  alignment: Alignment(0.0, _scanAnimation.value),
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF11D452).withOpacity(0.3),
                                          const Color(0xFF11D452).withOpacity(0.7),
                                          const Color(0xFF11D452).withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_isProcessing && _error == null) ...[
                          Positioned(
                            top: 80,
                            left: 40,
                            child: _buildReticle('YIELD EST'),
                          ),
                          Positioned(
                            bottom: 100,
                            right: 40,
                            child: _buildReticle('FACETING'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(top: 16, left: 16, child: _buildCorner(top: true, left: true)),
                  Positioned(top: 16, right: 16, child: _buildCorner(top: true, left: false)),
                  Positioned(bottom: 16, left: 16, child: _buildCorner(top: false, left: true)),
                  Positioned(bottom: 16, right: 16, child: _buildCorner(top: false, left: false)),
                ],
              ),
            ),
          ),
          
          // Progress Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Text(
                    _error != null ? 'Error' : _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _error != null ? Colors.redAccent : Colors.white,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.redAccent.shade100,
                      ),
                    ),
                  ],
                  if (_error == null) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'CALCULATING ROUGH WEIGHT POTENTIAL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isProcessing ? 'COMPUTING' : 'DONE',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF11D452),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3322),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isProcessing 
                        ? const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF11D452)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF11D452),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Steps
                    _buildProgressStep(Symbols.diamond, 'Projecting 3D light return', const Color(0xFF11D452)),
                    const SizedBox(height: 12),
                    _buildProgressStep(
                      Symbols.compare_arrows, 
                      'Simulating optimal facet placement', 
                      const Color(0xFF11D452), 
                    ),
                    const SizedBox(height: 12),
                    _buildProgressStep(Symbols.data_usage, 'Maximizing carat retention', Colors.white30),
                    
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Evaluating billions of possible geometrical combinations to suggest the most valuable cut.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReticle(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF11D452).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF11D452), width: 2),
            boxShadow: const [BoxShadow(color: Color(0xFF11D452), blurRadius: 10)],
          ),
        ),
        Container(
          width: 60,
          height: 1,
          color: const Color(0xFF11D452),
          transform: Matrix4.rotationZ(0.5),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF11D452),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color == const Color(0xFF11D452) ? Colors.white : color,
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF11D452), width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF11D452), width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF11D452), width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF11D452), width: 2) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}
