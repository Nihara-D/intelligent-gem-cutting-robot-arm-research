
//  gem_valuation_result.dart  


import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';
import 'gem_defect_map.dart';

//  Theme constants 
const _bg       = Color(0xFF102216);
const _surface  = Color(0xFF1A3825);
const _surface2 = Color(0xFF193322);
const _green    = Color(0xFF11D452);
const _gold     = Color(0xFFD4AF37);
const _border   = Color(0xFF23482F);
const _textHint = Color(0xFF92C9A4);

class GemValuationResult extends StatelessWidget {
  const GemValuationResult({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>;

    // Core fields 
    final String  gemType         = args['gemType']            as String? ?? 'Unknown';
    final double  weight          = (args['weight']            as num?)?.toDouble() ?? 0.0;
    final bool    weightEstimated = args['weightEstimated']    as bool?   ?? false;
    final String  qualityGrade    = args['qualityGrade']       as String? ?? 'Unknown';
    final double  defectPct       = (args['defectPercentage']  as num?)?.toDouble() ?? 0.0;
    final double  valueLKR        = (args['estimatedValueLKR'] as num?)?.toDouble() ?? 0.0;
    final double  valueUSD        = (args['estimatedValueUSD'] as num?)?.toDouble() ?? valueLKR / 300.0;
    final Uint8List? mainImageBytes = args['mainImageBytes'] as Uint8List?;
    final List<Uint8List> extraBytes =
        List<Uint8List>.from(args['additionalImageBytes'] ?? []);

    // ML fields 
    final bool    hasDefect   = args['hasDefect']         as bool?   ?? false;
    final String  defectType  = args['defectType']        as String? ?? 'None';
    final double  confidence  = (args['confidence']       as num?)?.toDouble() ?? 0.0;
    final String  severity    = args['severity']          as String? ?? 'NONE';
    final String  description = args['description']       as String? ?? '';
    final String  colorCode   = args['colorCode']         as String? ?? '#888888';
    final List    bboxes      = args['boundingBoxes']     as List?   ?? [];
    final Map<String, double> typeProbs =
        (args['typeProbabilities'] as Map<String, double>?) ?? {};
    final List<String> recommendations =
        List<String>.from(args['recommendations'] ?? []);
    final List<int> imageShape =
        List<int>.from((args['imageShape'] as List? ?? [300, 300, 3])
            .map((v) => (v as num).toInt()));

    final bool  hasMainImg  = mainImageBytes != null;
    final Color defectColor = _hexColor(colorCode);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            
            //  MAIN IMAGE / DEFECT MAP
           
            if (hasMainImg) ...[
              if (hasDefect && bboxes.isNotEmpty)
                _DefectMapSection(
                  imageBytes:    mainImageBytes!,
                  boundingBoxes: bboxes,
                  defectType:    defectType,
                  confidence:    confidence,
                  colorCode:     colorCode,
                  imageShape:    imageShape,
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 38.h,
                    child: Image.memory(mainImageBytes!, fit: BoxFit.cover),
                  ),
                ),
              SizedBox(height: 3.h),
            ],

            
            //  ADDITIONAL IMAGES
            
            if (extraBytes.isNotEmpty) ...[
              _SectionHeader(icon: Symbols.photo_library,
                  label: 'Additional Views'),
              SizedBox(height: 1.h),
              SizedBox(
                height: 18.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: extraBytes.length,
                  separatorBuilder: (_, __) => SizedBox(width: 2.w),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(extraBytes[i],
                        width: 25.w, fit: BoxFit.cover),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
            ],

            
            //  ML DETECTION BANNER
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hasDefect
                    ? Colors.red.withOpacity(0.08)
                    : _green.withOpacity(0.08),
                border: Border.all(
                    color: hasDefect
                        ? Colors.red.withOpacity(0.4)
                        : _green.withOpacity(0.4),
                    width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasDefect
                        ? Colors.red.withOpacity(0.12)
                        : _green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDefect
                        ? Symbols.warning
                        : Symbols.check_circle,
                    size: 44,
                    color: hasDefect ? Colors.red.shade400 : _green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasDefect ? defectType : 'No Defects Detected',
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: hasDefect ? defectColor : _green),
                  textAlign: TextAlign.center,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _textHint),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _Chip(
                      label: 'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                      bg: _green.withOpacity(0.12),
                      fg: _green,
                    ),
                    _Chip(
                      label: 'Severity: $severity',
                      bg: hasDefect
                          ? Colors.red.withOpacity(0.12)
                          : _green.withOpacity(0.12),
                      fg: hasDefect ? Colors.red.shade300 : _green,
                    ),
                  ],
                ),
              ]),
            ),

            SizedBox(height: 3.h),

           
            //  DEFECT TYPE PROBABILITY BARS
            
            if (typeProbs.isNotEmpty) ...[
              _GemCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(icon: Symbols.bar_chart,
                        label: 'Defect Type Probabilities'),
                    const SizedBox(height: 12),
                    ...(typeProbs.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .take(8)
                        .map((e) => _ProbBar(label: e.key, value: e.value))
                        .toList(),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
            ],

            
            //  QUALITY ASSESSMENT TABLE
         
            _GemCard(
              child: Column(children: [
                _SectionHeader(icon: Symbols.table_chart,
                    label: 'Quality Assessment'),
                const SizedBox(height: 14),
                Table(
                  border: TableBorder.all(
                      color: _border,
                      borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                  },
                  children: [
                    _tRow('Defect %',  'Quality',   isHeader: true),
                    _tRow('0% – 5%',   'Excellent', color: _green),
                    _tRow('6% – 10%',  'Very Good', color: Colors.lightGreen.shade400),
                    _tRow('11% – 20%', 'Good',      color: Colors.orange),
                    _tRow('21% – 35%', 'Fair',      color: Colors.deepOrange),
                    _tRow('> 35%',     'Poor',      color: Colors.red),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _gradeColor(qualityGrade).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _gradeColor(qualityGrade).withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      'Your Result: ${defectPct.toStringAsFixed(1)}%  →  $qualityGrade',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: _gradeColor(qualityGrade)),
                    ),
                  ),
                ),
              ]),
            ),

            SizedBox(height: 3.h),

            
            // GEM INFORMATION
            
            _GemCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Symbols.info,
                      label: 'Gem Information'),
                  Divider(color: _border, height: 20),
                  _InfoRow('Gem Type', gemType),
                  _InfoRow(
                    'Weight',
                    '${weight.toStringAsFixed(2)} ct'
                    '${weightEstimated ? "  (auto-estimated)" : ""}',
                    valueColor: weightEstimated ? Colors.orange : null,
                  ),
                  _InfoRow('Quality Grade', qualityGrade,
                      valueColor: _gradeColor(qualityGrade)),
                  if (hasDefect) ...[
                    _InfoRow('Defect Type', defectType,
                        valueColor: defectColor),
                    _InfoRow('Severity', severity,
                        valueColor: _severityColor(severity)),
                    _InfoRow('Confidence',
                        '${(confidence * 100).toStringAsFixed(1)} %'),
                  ],
                ],
              ),
            ),

            SizedBox(height: 3.h),

            
           
            //  BOUNDING BOX LIST
           
            if (bboxes.isNotEmpty) ...[
              _GemCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        icon: Symbols.crop_free,
                        label: '${bboxes.length} Defect Region(s) Found'),
                    Divider(color: _border, height: 20),
                    ...bboxes.take(6).map((b) {
                      final box = b as List;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Icon(Symbols.crop_square,
                              size: 16, color: defectColor),
                          const SizedBox(width: 8),
                          Text(defectType,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: defectColor)),
                          const Spacer(),
                          Text(
                            '(${box[0]}, ${box[1]}) → (${box[2]}, ${box[3]})',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _textHint),
                          ),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
            ],

            // ================================================================
            // 9. ESTIMATED MARKET VALUE
            // ================================================================
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withOpacity(0.06),
                      blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Symbols.price_change, color: _gold, size: 20),
                  const SizedBox(width: 8),
                  Text('Estimated Market Value',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18, color: Colors.white)),
                ]),
                SizedBox(height: 2.h),
                if (hasMainImg)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(mainImageBytes!,
                        height: 16.h, fit: BoxFit.cover),
                  ),
                SizedBox(height: 2.h),
                // LKR value
                Text(
                  'LKR ${_fmt(valueLKR)}',
                  style: GoogleFonts.inter(
                      fontSize: 38, fontWeight: FontWeight.bold,
                      color: _gold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '≈ USD ${_fmt(valueUSD)}',
                  style: GoogleFonts.inter(
                      fontSize: 22, color: _textHint),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.5.h),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    'Based on Sri Lankan gem market trends (2026)\n',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: _textHint,
                        height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),

            SizedBox(height: 4.h),

            // ================================================================
            // 10. ACTION BUTTONS
            // ================================================================
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.2.h),
                    side: const BorderSide(color: _green, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    foregroundColor: _green,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.arrow_back, size: 18),
                      const SizedBox(width: 6),
                      Text('Analyse Another',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('📄 Valuation Report Generated!',
                          style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: _surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _green)),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.2.h),
                    backgroundColor: _gold,
                    foregroundColor: _bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.picture_as_pdf, size: 18),
                      const SizedBox(width: 6),
                      Text('Generate Report',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ]),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: Container(
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.97),
        border: Border(bottom: BorderSide(color: _green.withOpacity(0.1))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          IconButton(
            icon: const Icon(Symbols.arrow_back, color: _green),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Symbols.diamond, color: _green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Gem Valuation Result',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Symbols.refresh, color: _green, size: 16),
                  const SizedBox(width: 4),
                  Text('New',
                      style: GoogleFonts.inter(
                          color: _green, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  TableRow _tRow(String left, String right,
      {bool isHeader = false, Color? color}) {
    return TableRow(
      decoration:
          BoxDecoration(color: isHeader ? _surface2 : null),
      children: [
        Padding(
          padding: const EdgeInsets.all(11),
          child: Center(child: Text(left,
              style: GoogleFonts.inter(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: isHeader ? Colors.white : _textHint,
                  fontSize: 13))),
        ),
        Padding(
          padding: const EdgeInsets.all(11),
          child: Center(child: Text(right,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isHeader ? Colors.white : color,
                  fontSize: 13))),
        ),
      ],
    );
  }

  static Color _gradeColor(String g) {
    switch (g.toLowerCase()) {
      case 'excellent': return _green;
      case 'very good': return Colors.lightGreen.shade400;
      case 'good':      return Colors.orange;
      case 'fair':      return Colors.deepOrange;
      case 'poor':      return Colors.red;
      default:          return _textHint;
    }
  }

  static Color _severityColor(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':        return Colors.red;
      case 'MEDIUM-HIGH': return Colors.deepOrange;
      case 'MEDIUM':      return Colors.orange;
      case 'LOW-MEDIUM':  return Colors.amber;
      case 'LOW':         return Colors.lightGreen;
      case 'NONE':        return _green;
      default:            return _textHint;
    }
  }

  static Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return Colors.grey; }
  }
}

// =============================================================================
// Shared card container
// =============================================================================
class _GemCard extends StatelessWidget {
  final Widget child;
  const _GemCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(4.w),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: child,
  );
}

// =============================================================================
// Section header row
// =============================================================================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: _green),
    const SizedBox(width: 8),
    Expanded(child: Text(label,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15, color: Colors.white))),
  ]);
}

// =============================================================================
// Info row
// =============================================================================
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(
            fontSize: 13, color: _textHint,
            fontWeight: FontWeight.w500)),
        Flexible(child: Text(value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white))),
      ],
    ),
  );
}

// =============================================================================
// Chip badge
// =============================================================================
class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3))),
    child: Text(label, style: GoogleFonts.inter(
        color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

// =============================================================================
// Probability bar
// =============================================================================
class _ProbBar extends StatelessWidget {
  final String label;
  final double value;
  const _ProbBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: Colors.white70)),
          Text('${pct.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(fontSize: 12, color: _textHint)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// Defect map section
// =============================================================================
class _DefectMapSection extends StatelessWidget {
  final Uint8List imageBytes;
  final List      boundingBoxes;
  final String    defectType;
  final double    confidence;
  final String    colorCode;
  final List<int> imageShape;

  const _DefectMapSection({
    required this.imageBytes,
    required this.boundingBoxes,
    required this.defectType,
    required this.confidence,
    required this.colorCode,
    required this.imageShape,
  });

  @override
  Widget build(BuildContext context) {
    final defectColor = _hexColor(colorCode);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Title row
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Icon(Symbols.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 6),
          Text('Defect Location Map',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, color: Colors.white)),
        ]),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => GemDefectMapFullscreen(
              imageBytes: imageBytes, boundingBoxes: boundingBoxes,
              defectType: defectType, confidence: confidence,
              colorCode: colorCode, imageShape: imageShape,
            ),
          )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.fullscreen, color: _green, size: 16),
              const SizedBox(width: 4),
              Text('Fullscreen',
                  style: GoogleFonts.inter(
                      color: _green, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),

      const SizedBox(height: 10),

      // Map
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => GemDefectMapFullscreen(
            imageBytes: imageBytes, boundingBoxes: boundingBoxes,
            defectType: defectType, confidence: confidence,
            colorCode: colorCode, imageShape: imageShape,
          ),
        )),
        child: Stack(children: [
          GemDefectMap(
            imageBytes: imageBytes, boundingBoxes: boundingBoxes,
            defectType: defectType, confidence: confidence,
            colorCode: colorCode, imageShape: imageShape,
            height: 38.h,
          ),
          // Tap hint
          Positioned(
            bottom: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Symbols.touch_app, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('Tap to zoom',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 11)),
              ]),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 10),

      // Legend
      Row(children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: defectColor, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$defectType detected  •  ${boundingBoxes.length} region(s)',
          style: GoogleFonts.inter(fontSize: 12, color: _textHint),
        ),
        const Spacer(),
        const Icon(Symbols.info, size: 13, color: _border),
        const SizedBox(width: 4),
        Text('Tap image to zoom in',
            style: GoogleFonts.inter(fontSize: 11, color: _border)),
      ]),
    ]);
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return Colors.red; }
  }
}