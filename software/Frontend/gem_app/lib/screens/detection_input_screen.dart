import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DetectionInputScreen extends StatefulWidget {
  const DetectionInputScreen({super.key});

  @override
  State<DetectionInputScreen> createState() => _DetectionInputScreenState();
}

class _DetectionInputScreenState extends State<DetectionInputScreen> {
  final TextEditingController _riController = TextEditingController();
  final TextEditingController _sgController = TextEditingController();
  final TextEditingController _hardnessController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedColor;
  
  final List<String> _gemColors = [
    'Colorless',
    'Near Colorless',
    'Clear',
    'Red',
    'Green',
    'Blue',
    'Deep Blue',
    'Fancy Blue',
    'Milky Blue',
    'Fancy',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Light Brown',
    'Reddish Brown',
    'Smoky Brown',
    'Black',
    'White',
    'Milky White',
    'Pale Milky White',
    'Gray',
    'Various',
    'Multicolor'
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _startAnalysis() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image first')),
      );
      return;
    }

    final double ri = double.tryParse(_riController.text) ?? 0.0;
    final double sg = double.tryParse(_sgController.text) ?? 0.0;
    final double hardness = double.tryParse(_hardnessController.text) ?? 0.0;

    if (ri == 0.0 || sg == 0.0 || hardness == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all physical properties correctly')),
      );
      return;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose the color')),
      );
      return;
    }

    // Pass data to processing screen
    Navigator.pushNamed(context, '/processing', arguments: {
      'image': _selectedImage,
      'ri': ri,
      'sg': sg,
      'hardness': hardness,
      'color': _selectedColor,
      'notes': _notesController.text,
    });
  }

  @override
  void dispose() {
    _riController.dispose();
    _sgController.dispose();
    _hardnessController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102216),
      bottomNavigationBar: _buildBottomNav(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF102216).withOpacity(0.95),
            border: Border(
              bottom: BorderSide(color: const Color(0xFF162E1E)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Symbols.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Detect Gemstone',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance for centering
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Section
            GestureDetector(
              onTap: () => _showImagePickerOptions(context),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 240, // Match roughly 4/3 aspect ratio on mobile
                    decoration: BoxDecoration(
                      color: const Color(0xFF162E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF11D452).withOpacity(0.3),
                        style: BorderStyle.solid, 
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (_selectedImage != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/default_cut.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        if (_selectedImage == null)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF11D452).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Symbols.add_a_photo,
                                    color: Color(0xFF11D452),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Capture or Upload',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Take a photo for visual identification',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF11D452),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Symbols.videocam, color: Color(0xFF102216)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Physical Properties Info
            Row(
              children: [
                const Icon(Symbols.science, color: Color(0xFF11D452)),
                const SizedBox(width: 8),
                Text(
                  'Physical Properties',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildPropertyRow('Refractive Index', 'Typical range: 1.4 - 2.8', '0.00', _riController, TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            _buildPropertyRow('Specific Gravity', 'Relative density', '0.00', _sgController, TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            _buildPropertyRow('Mohs Hardness', 'Scale 1 - 10', '0.0', _hardnessController, TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            _buildColorDropdownRow(),
            const SizedBox(height: 24),

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF162E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: const Color(0xFF11D452),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: GoogleFonts.inter(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add any visible inclusions or color zoning...',
                      hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Start Analysis Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11D452),
                  foregroundColor: const Color(0xFF102216),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF11D452).withOpacity(0.5),
                ),
                icon: const Icon(Symbols.auto_awesome),
                label: Text(
                  'Start Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48), // SafeArea bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String title, String subtitle, String hint, TextEditingController controller, TextInputType inputType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: const Color(0xFF11D452),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF102216),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: controller,
              keyboardType: inputType,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white30),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDropdownRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLOR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: const Color(0xFF11D452),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visible primary color',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 170, // Increased width to fit the hint text
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF102216),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedColor,
                hint: const Text(
                  'Choose the color',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white30,
                  ),
                ),
                dropdownColor: const Color(0xFF102216),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Colors.white,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedColor = newValue;
                    });
                  }
                },
                items: _gemColors.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.photo_library, color: Colors.white),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.camera_alt, color: Colors.white),
                title: Text('Take a Photo', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
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
                onTap: () {},
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
