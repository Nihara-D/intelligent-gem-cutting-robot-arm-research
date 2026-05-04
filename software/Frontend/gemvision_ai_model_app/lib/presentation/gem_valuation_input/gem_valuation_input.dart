
//  gem_valuation_input.dart  


import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

//  Theme constants  
const _bg       = Color(0xFF102216);
const _surface  = Color(0xFF1A3825);
const _green    = Color(0xFF11D452);
const _gold     = Color(0xFFD4AF37);
const _border   = Color(0xFF23482F);
const _textHint = Color(0xFF92C9A4);

class GemValuationInput extends StatefulWidget {
  const GemValuationInput({super.key});
  @override
  State<GemValuationInput> createState() => _GemValuationInputState();
}

class _GemValuationInputState extends State<GemValuationInput> {

  static String get _apiBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.0.2.2:5000';
    // return 'http://192.168.1.10:5000'; // real device on WiFi
  }

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _gemTypeController = TextEditingController();
  final TextEditingController _weightController  = TextEditingController();

  Uint8List? _mainBytes;
  String     _mainName   = 'gem.jpg';
  final List<Uint8List> _extraBytes = [];
  final List<String>    _extraNames = [];

  bool   _isAnalyzing   = false;
  String _statusMessage = '';

  //  Image picking 

  Future<void> _pickMainImage() async =>
      kIsWeb ? await _galleryPick(isMain: true) : _showSheet(isMain: true);

  Future<void> _pickAdditionalImages() async =>
      kIsWeb ? await _multiPick() : _showSheet(isMain: false);

  Future<void> _galleryPick({required bool isMain}) async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (f == null) return;
    final b = await f.readAsBytes();
    setState(() {
      if (isMain) { _mainBytes = b; _mainName = f.name; }
      else        { _extraBytes.add(b); _extraNames.add(f.name); }
    });
  }

  Future<void> _multiPick() async {
    final fs = await _picker.pickMultiImage(imageQuality: 90);
    for (final f in fs) {
      final b = await f.readAsBytes();
      setState(() { _extraBytes.add(b); _extraNames.add(f.name); });
    }
  }

  Future<void> _cameraPick({required bool isMain}) async {
    final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (f == null) return;
    final b = await f.readAsBytes();
    setState(() {
      if (isMain) { _mainBytes = b; _mainName = f.name; }
      else        { _extraBytes.add(b); _extraNames.add(f.name); }
    });
  }

  void _showSheet({required bool isMain}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Select Image Source',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, color: Colors.white)),
            const SizedBox(height: 12),
            _SheetTile(
              icon: Symbols.photo_library,
              iconBg: _green.withOpacity(0.15),
              iconColor: _green,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(ctx);
                isMain ? _galleryPick(isMain: true) : _multiPick();
              },
            ),
            Divider(color: _border, height: 1),
            _SheetTile(
              icon: Symbols.camera_alt,
              iconBg: _gold.withOpacity(0.15),
              iconColor: _gold,
              label: 'Camera',
              onTap: () { Navigator.pop(ctx); _cameraPick(isMain: isMain); },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _removeMain()       => setState(() { _mainBytes = null; _mainName = 'gem.jpg'; });
  void _removeExtra(int i) => setState(() { _extraBytes.removeAt(i); _extraNames.removeAt(i); });

  // Analyse 
  Future<void> _analyzeGemstone() async {
    final gemType = _gemTypeController.text.trim();
    final weight  = double.tryParse(_weightController.text.trim()) ?? 0.0;

    if (gemType.isEmpty || _mainBytes == null) {
      _snack('Please enter gem type and upload the main gem photo.');
      return;
    }

    setState(() { _isAnalyzing = true; _statusMessage = 'Connecting to server...'; });

    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_apiBaseUrl/predict'))
        ..fields['gemType'] = gemType
        ..fields['weight']  = weight.toString()
        ..files.add(http.MultipartFile.fromBytes(
          'image', _mainBytes!,
          filename: _mainName,
          contentType: _mimeType(_mainName),
        ));

      setState(() => _statusMessage = 'Analysing gem with ML model...');
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        final b = _safeJson(response.body);
        _snack('Server error: ${b?['error'] ?? 'HTTP ${response.statusCode}'}');
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if ((data['error'] ?? '').toString().isNotEmpty) {
        _snack('Model error: ${data['error']}'); return;
      }

      if (!mounted) return;
      Navigator.pushNamed(context, '/gem-valuation-result', arguments: {
        'gemType':              gemType,
        'weight':               ((data['weight_used'] ?? weight) as num).toDouble(),
        'weightEstimated':      data['weight_estimated']      ?? false,
        'qualityGrade':         data['quality_grade']         ?? 'Unknown',
        'defectPercentage':     (data['defect_percentage']    ?? 0.0 as num).toDouble(),
        'estimatedValueLKR':    (data['estimated_value_lkr']  ?? 0.0 as num).toDouble(),
        'estimatedValueUSD':    (data['estimated_value_usd']  ?? 0.0 as num).toDouble(),
        'mainImageBytes':       _mainBytes,
        'additionalImageBytes': List<Uint8List>.from(_extraBytes),
        'hasDefect':            data['has_defect']            ?? false,
        'defectType':           data['defect_type']           ?? 'None',
        'confidence':           (data['confidence']           ?? 0.0 as num).toDouble(),
        'severity':             data['severity']              ?? 'NONE',
        'description':          data['description']           ?? '',
        'colorCode':            data['color_code']            ?? '#888888',
        'boundingBoxes':        data['bounding_boxes']        ?? [],
        'typeProbabilities':    Map<String, double>.from(
            (data['type_probabilities'] as Map? ?? {})
                .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))),
        'recommendations':      List<String>.from(data['recommendations'] ?? []),
        'imageShape':           List<int>.from(
            (data['image_shape'] as List? ?? [0, 0, 3])
                .map((v) => (v as num).toInt())),
      });

    } on http.ClientException catch (e) {
      _snack('Network error: ${e.message}\nURL: $_apiBaseUrl');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() { _isAnalyzing = false; _statusMessage = ''; });
    }
  }

  //  Helpers 

  MediaType _mimeType(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'png':  return MediaType('image', 'png');
      case 'gif':  return MediaType('image', 'gif');
      case 'webp': return MediaType('image', 'webp');
      default:     return MediaType('image', 'jpeg');
    }
  }

  Map<String, dynamic>? _safeJson(String s) {
    try { return json.decode(s) as Map<String, dynamic>; } catch (_) { return null; }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border)),
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  void dispose() {
    _gemTypeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Web banner
          if (kIsWeb) ...[
            _InfoBanner(icon: Symbols.language,
                text: 'Browser mode  •  API: $_apiBaseUrl', color: _green),
            SizedBox(height: 2.h),
          ],

          //  Gem Type
          _SectionLabel('Gem Type'),
          SizedBox(height: 1.h),
          _ThemedField(
            controller: _gemTypeController,
            hint: 'e.g. Blue Sapphire, Ruby, Garnet',
            icon: Symbols.diamond,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 2.5.h),

          // Weight
          _SectionLabel('Weight (Carats)'),
          SizedBox(height: 1.h),
          _ThemedField(
            controller: _weightController,
            hint: 'Enter weight in carats (ct)',
            icon: Symbols.scale,
            suffix: 'ct',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 2.5.h),

          //  Main Image 
          _SectionLabel('Main Gem Photo', badge: 'Required'),
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: _isAnalyzing ? null : _pickMainImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 22.h,
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(
                  color: _mainBytes != null ? _green : _green.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _mainBytes == null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: _green.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Icon(Symbols.add_photo_alternate,
                            size: 36, color: _green),
                      ),
                      SizedBox(height: 1.2.h),
                      Text('Tap to add gem photo',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white, fontSize: 14)),
                      SizedBox(height: 0.4.h),
                      Text(kIsWeb ? 'Pick from files' : 'Gallery or Camera',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _textHint)),
                    ])
                  : Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_mainBytes!, fit: BoxFit.cover),
                      ),
                      Positioned(top: 8, right: 8,
                        child: GestureDetector(
                          onTap: _removeMain,
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ]),
            ),
          ),
          SizedBox(height: 2.5.h),

          // Additional Images 
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _SectionLabel('Additional Photos', badge: 'Optional'),
            GestureDetector(
              onTap: _isAnalyzing ? null : _pickAdditionalImages,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Symbols.add, color: _green, size: 16),
                  const SizedBox(width: 4),
                  Text('Add More',
                      style: GoogleFonts.inter(
                          color: _green, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          SizedBox(height: 1.h),
          Container(
            height: 16.h,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _green.withOpacity(0.2), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _extraBytes.isEmpty
                ? Center(child: Text(
                    'No additional photos\n'
                    'Add side / top views for better accuracy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: _textHint, fontSize: 13)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(1.h),
                    itemCount: _extraBytes.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(right: 2.w),
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_extraBytes[i],
                              width: 20.w, height: 14.h, fit: BoxFit.cover),
                        ),
                        Positioned(top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExtra(i),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
          ),
          SizedBox(height: 4.h),

          // Analyse Button
          SizedBox(
            width: double.infinity, height: 7.h,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeGemstone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: _green.withOpacity(0.4),
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isAnalyzing)
                    const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: _bg, strokeWidth: 2.5),
                    )
                  else
                    const Icon(Symbols.analytics, size: 22, color: _bg),
                  const SizedBox(width: 10),
                  Text(
                    _isAnalyzing ? 'Analyzing...' : 'Analyze Gemstone',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.bold,
                        color: _bg),
                  ),
                ],
              ),
            ),
          ),

          if (_statusMessage.isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: _green),
              ),
              const SizedBox(width: 8),
              Text(_statusMessage,
                  style: GoogleFonts.inter(
                      color: _green, fontSize: 13,
                      fontStyle: FontStyle.italic)),
            ])),
          ],

          SizedBox(height: 2.h),

          // API info strip 
          _InfoBanner(
            icon: Symbols.dns,
            text: 'API: $_apiBaseUrl  •  python api_server.py',
            color: _textHint,
            subtle: true,
          ),
          SizedBox(height: 2.h),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: Container(
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.97),
        border: Border(
            bottom: BorderSide(color: _green.withOpacity(0.1))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          IconButton(
            icon: const Icon(Symbols.arrow_back, color: _green),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Symbols.price_change, color: _gold, size: 22),
          const SizedBox(width: 10),
          Text('Gem Valuation',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, color: Colors.white)),
        ]),
      ),
    ),
  );
}


// Shared widgets

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? badge;
  const _SectionLabel(this.text, {this.badge});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text, style: GoogleFonts.inter(
        fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
    if (badge != null) ...[
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.25)),
        ),
        child: Text(badge!,
            style: GoogleFonts.inter(
                fontSize: 10, color: _textHint,
                fontWeight: FontWeight.w500)),
      ),
    ],
  ]);
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool subtle;
  const _InfoBanner({required this.icon, required this.text,
      required this.color, this.subtle = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: subtle ? _surface.withOpacity(0.5) : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(subtle ? 0.15 : 0.25)),
    ),
    child: Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12, color: color))),
    ]),
  );
}

class _ThemedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _ThemedField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    style: GoogleFonts.inter(color: Colors.white),
    cursorColor: _green,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: _textHint, fontSize: 13),
      suffixText: suffix,
      suffixStyle: GoogleFonts.inter(color: _textHint),
      prefixIcon: Icon(icon, color: _green, size: 20),
      filled: true,
      fillColor: _surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5)),
    ),
  );
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SheetTile({required this.icon, required this.iconBg,
      required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: iconBg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(label, style: GoogleFonts.inter(
        fontWeight: FontWeight.w600, color: Colors.white)),
    trailing: const Icon(Symbols.chevron_right, color: _textHint, size: 18),
    onTap: onTap,
  );
}