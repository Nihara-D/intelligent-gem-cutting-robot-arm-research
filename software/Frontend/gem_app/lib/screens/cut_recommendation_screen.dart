import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

class CutRecommendationScreen extends StatefulWidget {
  const CutRecommendationScreen({super.key});

  @override
  State<CutRecommendationScreen> createState() => _CutRecommendationScreenState();
}

class _CutRecommendationScreenState extends State<CutRecommendationScreen> {
  double _aspectRatio = 1.5;
  String? _stoneType;
  String? _imagePath;
  bool _isLoading = false;

  final TextEditingController _riController = TextEditingController();
  final TextEditingController _caratController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();

  final List<String> _gemstoneOptions = [
    "Alexandrite", "Amethyst", "Aquamarine", "Blue Sapphire", "Chrysoberyl",
    "Citrine", "Garnet", "Hessonite", "Jade", "Kunzite", 
    "Moonstone", "Morganite", "Opal", "Peridot", "Pink Sapphire", "Quartz", 
    "Ruby", "Spinel", "Tanzanite", "Topaz", "Tourmaline", "Turquoise", 
    "Yellow Sapphire", "Zircon"
  ];

  @override
  void initState() {
    super.initState();
    _lengthController.addListener(_updateAspectRatio);
    _widthController.addListener(_updateAspectRatio);
  }

  void _updateAspectRatio() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    
    if (length != null && width != null && width > 0) {
      double calculatedRatio = length / width;
      // Clamp between slider bounds 1.0 - 3.0
      if (calculatedRatio < 1.0) calculatedRatio = 1.0;
      if (calculatedRatio > 3.0) calculatedRatio = 3.0;
      
      if (_aspectRatio != calculatedRatio) {
        setState(() {
          _aspectRatio = calculatedRatio;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _stoneType == null) {
      _stoneType = args['stoneType'] as String?;
      _imagePath = args['imagePath'] as String?;
      
      final passedRi = args['ri'] as String?;
      if (passedRi != null && passedRi.isNotEmpty && _riController.text.isEmpty) {
        _riController.text = passedRi;
      }
    }
  }

  @override
  void dispose() {
    _riController.dispose();
    _caratController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  Future<void> _calculateCut() async {
    final ri = double.tryParse(_riController.text);
    final carat = double.tryParse(_caratController.text);
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (ri == null || carat == null || length == null || width == null || depth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all dimension and property fields with valid numbers')),
      );
      return;
    }

    Navigator.pushNamed(context, '/cut_processing', arguments: {
      'stoneType': _stoneType ?? 'Garnet',
      'imagePath': _imagePath,
      'ri': ri,
      'carat': carat,
      'length': length,
      'width': width,
      'depth': depth,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102216),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF23482F)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Symbols.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Cut Recommendation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _riController.clear();
                    _caratController.clear();
                    _lengthController.clear();
                    _widthController.clear();
                    _depthController.clear();
                    setState(() {
                      _aspectRatio = 1.5;
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF11D452),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imagePath != null) ...[
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(_imagePath!) as ImageProvider
                        : FileImage(File(_imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Enter your gemstone details below to get AI-powered cut recommendations tailored for maximum brilliance.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            
            // Form Fields
            Text(
              'Gemstone Type',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_imagePath != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF193322),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                ),
                child: Text(
                  _stoneType ?? 'Garnet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _stoneType ?? 'Garnet',
                dropdownColor: const Color(0xFF193322),
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF193322),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF11D452)),
                  ),
                ),
                items: _gemstoneOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _stoneType = newValue;
                  });
                },
              ),
            const SizedBox(height: 16),
            
            // RI & Carat Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refractive Index',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_riController, 'e.g. 2.417', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carat Weight',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_caratController, 'e.g. 1.50', suffix: 'ct', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dimensions Row
            Row(
              children: [
                Expanded(child: _buildDimensionField(_lengthController, 'LENGTH', 'mm')),
                const SizedBox(width: 12),
                Expanded(child: _buildDimensionField(_widthController, 'WIDTH', 'mm')),
                const SizedBox(width: 12),
                Expanded(child: _buildDimensionField(_depthController, 'DEPTH', 'mm')),
              ],
            ),
            const SizedBox(height: 24),
            
            // Aspect Ratio Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Aspect Ratio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_aspectRatio.toStringAsFixed(1)} : 1',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF11D452),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF11D452),
                inactiveTrackColor: const Color(0xFF23482F),
                thumbColor: const Color(0xFF11D452),
                overlayColor: const Color(0xFF11D452).withOpacity(0.2),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _aspectRatio,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    _aspectRatio = value;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Square (1:1)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  'Elongated (3:1)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _calculateCut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11D452),
                  foregroundColor: const Color(0xFF102216),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                icon: const Icon(Symbols.diamond, size: 24),
                label: Text(
                  'Calculate Optimal Cut',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Estimated calculation time: < 2 seconds',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {String? suffix, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF193322),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16, top: 14),
                  child: Text(
                    suffix,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _buildDimensionField(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF193322),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF193322).withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF23482F)),
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
                child: const _NavIcon(icon: Symbols.diamond, label: 'Analyze', isActive: true),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
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
