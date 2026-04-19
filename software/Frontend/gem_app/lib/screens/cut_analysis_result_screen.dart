import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CutAnalysisResultScreen extends StatefulWidget {
  final String initialCutType;

  const CutAnalysisResultScreen({super.key, this.initialCutType = 'Emerald'});

  @override
  State<CutAnalysisResultScreen> createState() =>
      _CutAnalysisResultScreenState();
}

class _CutAnalysisResultScreenState extends State<CutAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCut = '';
  String? _stoneType;
  Map<String, dynamic>? _cutParameters;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = true;
  bool _hasNoVideo = false;
  bool _isExporting = false;
  bool _show3DView = true;

  String? _warningMessage;
  String? _noteMessage;
  List<dynamic>? _top3Cuts;
  String? _predictedCutFamily;
  String _cameraOrbit = "0deg 75deg 105%";

  double? _length;
  double? _width;
  double? _depth;

  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _cutOptions = [
    {
      'id': 'Emerald',
      'name': 'Precision Step Cut',
      'thumbnail': 'assets/images/cut_recommendation_result/Emerald.png',
      'yield': 'BASED ON DIMS',
      'description':
          'A precise step-cut architecture that emphasizes clarity, vibrant color reflection, and maximizes dimension presentation without heavy brilliance clutter.',
    },
    {
      'id': 'RoundBrilliant',
      'name': 'Round Brilliant',
      'thumbnail': 'assets/images/cut_recommendation_result/RoundBrilliant.png',
      'yield': 'HIGH FIRE',
      'description':
          'Engineered for unparalleled scintillation, the round brilliant concentrates light rays to create explosive brightness, albeit sacrificing more rough material.',
    },
    {
      'id': 'Oval',
      'name': 'Oval Cut',
      'thumbnail': 'assets/images/cut_recommendation_result/Oval.png',
      'yield': 'CARAT MAX',
      'description':
          'The sleek, elongated elliptical shape produces an incredible illusion of massive size, perfect for maximizing the visual footprint of a gemstone.',
    },
    {
      'id': 'Cushion',
      'name': 'Cushion Cut',
      'thumbnail': 'assets/images/cut_recommendation_result/Cushion.png',
      'yield': 'ANTIQUE FIRE',
      'description':
          'A romantic marriage of square geometry and delicate rounded corners. The cushion cut produces broad, majestic flashes of raw color intensity.',
    },
    {
      'id': 'Cabochon',
      'name': 'Cabochon',
      'thumbnail': 'assets/images/cut_recommendation_result/Cabochon.png',
      'yield': '99% RETENTION',
      'description':
          'A magnificent, highly polished dome that celebrates internal inclusions and optical phenomena without the distraction of geometric facets.',
    },
    {
      'id': 'MixedCut',
      'name': 'Mixed Cut',
      'thumbnail': 'assets/images/cut_recommendation_result/MixedCut.jpg',
      'yield': 'HYBRID LUXURY',
      'description':
          'Merging the fiery brilliance of detailed crown facets with the intense, bold color wells of step-cut pavilions. A masterpiece of light play.',
    },
    {
      'id': 'Princess',
      'name': 'Princess Cut',
      'thumbnail':
          'assets/images/cut_recommendation_result/Cushion.png', // Fallback
      'yield': 'MODERN BRILLIANCE',
      'description':
          'A stunning square brilliant cut offering intense light performance and clean modern architectural lines, holding excellent rough weight retention.',
    },
    {
      'id': 'Marquise',
      'name': 'Marquise Cut',
      'thumbnail':
          'assets/images/cut_recommendation_result/Oval.png', // Fallback
      'yield': 'MAXIMUM PRESENCE',
      'description':
          'An elegant, elongated boat-shape. Expertly maximizes carat weight spread, creating an illusion of a much larger gemstone surface area.',
    },
    {
      'id': 'Pear',
      'name': 'Pear Cut',
      'thumbnail':
          'assets/images/cut_recommendation_result/Oval.png', // Fallback
      'yield': 'ELEGANT TEARDROP',
      'description':
          'A graceful asymmetric teardrop design, blending the intense brilliance of a round cut with the distinctive point of a marquise cut.',
    },
    {
      'id': 'Radiant',
      'name': 'Radiant Cut',
      'thumbnail':
          'assets/images/cut_recommendation_result/Emerald.png', // Fallback
      'yield': 'FRACTAL FIRE',
      'description':
          'A hybrid featuring the elegant rectangular shape of an emerald cut combined with the mesmerizing facet pattern of a round brilliant.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeOut),
    );
    _fadeAnimController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('apiResult')) {
      final apiResult = args['apiResult'] as Map<String, dynamic>;
      final recommendedCut =
          apiResult['Best Exact Cut Recommendation'] as String?;

      _stoneType = args['stoneType'] as String?;
      _length = args['length'] as double?;
      _width = args['width'] as double?;
      _depth = args['depth'] as double?;

      if (apiResult.containsKey('Top-3 Exact Cut Recommendations') &&
          apiResult['Top-3 Exact Cut Recommendations'] != null) {
        _top3Cuts =
            apiResult['Top-3 Exact Cut Recommendations'] as List<dynamic>;
      }

      if (apiResult.containsKey('Predicted Cut Family') &&
          apiResult['Predicted Cut Family'] != null) {
        _predictedCutFamily = apiResult['Predicted Cut Family'] as String;
      }

      String? actualRecommendedCut = recommendedCut;
      if ((actualRecommendedCut == null || actualRecommendedCut.isEmpty) &&
          _top3Cuts != null &&
          _top3Cuts!.isNotEmpty) {
        actualRecommendedCut = _top3Cuts![0]['cut'] as String?;
      }

      if (actualRecommendedCut != null && _selectedCut.isEmpty) {
        final index = _cutOptions.indexWhere(
          (cut) =>
              cut['id'].toString().toLowerCase() ==
                  actualRecommendedCut!.toLowerCase() ||
              cut['name'].toString().toLowerCase().contains(
                actualRecommendedCut!.toLowerCase(),
              ),
        );

        if (index != -1) {
          final recommendedOption = _cutOptions.removeAt(index);
          _cutOptions.insert(0, recommendedOption);
          _selectedCut = recommendedOption['id'];
        } else {
          // Add unknown AI recommended cuts dynamically
          final newOption = {
            'id': actualRecommendedCut,
            'name': '$actualRecommendedCut Cut',
            'thumbnail': 'assets/images/cut_recommendation_result/Emerald.png',
            'yield': 'AI OPTIMIZED',
            'description':
                'An advanced cut pattern dynamically recommended by the AI based on the structure and dimensions of the gemstone.',
          };
          _cutOptions.insert(0, newOption);
          _selectedCut = newOption['id'] as String;
        }
      }

      if (apiResult.containsKey('Recommended Cutting Parameters')) {
        final params =
            apiResult['Recommended Cutting Parameters'] as Map<String, dynamic>;
        if (params.isNotEmpty) {
          _cutParameters = params;
        }
      }

      if (apiResult.containsKey('Warning') && apiResult['Warning'] != null) {
        _warningMessage = apiResult['Warning'] as String;
      }

      if (apiResult.containsKey('Note') && apiResult['Note'] != null) {
        _noteMessage = apiResult['Note'] as String;
      }
    }

    if (_selectedCut.isEmpty) {
      if (_cutOptions.any((cut) => cut['id'] == widget.initialCutType)) {
        _selectedCut = widget.initialCutType;
      } else {
        _selectedCut = _cutOptions.first['id'] as String;
      }
    }

    if (_videoController == null) {
      _initializeVideo(_selectedCut);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  String _getVideoForCut(String stoneType, String cutId) {
    final normalizedStone = stoneType.toLowerCase().replaceAll(' ', '_');
    String normalizedCut = cutId.toLowerCase().replaceAll(' ', '_');

    if (normalizedCut == 'roundbrilliant') normalizedCut = 'round';
    if (normalizedCut == 'mixedcut') normalizedCut = 'cushion';

    return 'assets/gem_video/${normalizedStone}_${normalizedCut}.mp4';
  }

  String _getGenericVideoForCut(String cutId) {
    String normalizedCut = cutId.toLowerCase().replaceAll(' ', '_');
    if (normalizedCut == 'roundbrilliant') normalizedCut = 'round';
    if (normalizedCut == 'mixedcut') normalizedCut = 'cushion';
    return 'assets/gem_video/$normalizedCut.mp4';
  }

  String _get3dModelForCut(String cutId) {
    String normalizedCut = cutId.toLowerCase().replaceAll(' ', '');
    // Map of specific files available in assets/gem_3d/
    if (normalizedCut.contains('round')) return 'assets/gem_3d/round.glb';
    if (normalizedCut.contains('emerald')) return 'assets/gem_3d/emerald.glb';
    if (normalizedCut.contains('oval')) return 'assets/gem_3d/oval.glb';
    if (normalizedCut.contains('cushion')) return 'assets/gem_3d/cushion.glb';
    if (normalizedCut.contains('cabochon')) return 'assets/gem_3d/cabochon.glb';
    if (normalizedCut.contains('mixed')) return 'assets/gem_3d/mixed.glb';
    if (normalizedCut.contains('marquise')) return 'assets/gem_3d/marquise.glb';
    if (normalizedCut.contains('pear')) return 'assets/gem_3d/pear.glb';
    if (normalizedCut.contains('princess')) return 'assets/gem_3d/princess.glb';
    if (normalizedCut.contains('radiant')) return 'assets/gem_3d/radiant.glb';

    // Default fallback
    return 'assets/gem_3d/cabochon.glb';
  }

  Future<void> _initializeVideo(String cutId) async {
    final primaryVideoPath = _getVideoForCut(_stoneType ?? 'Diamond', cutId);
    final fallbackVideoPath = _getGenericVideoForCut(cutId);

    if (mounted)
      setState(() {
        _isVideoLoading = true;
        _hasNoVideo = false;
      });

    VideoPlayerController? activeController;

    // Helper to test if asset exists
    Future<bool> assetExists(String path) async {
      try {
        await rootBundle.load(path);
        return true;
      } catch (_) {
        return false;
      }
    }

    try {
      // 1. Try Stone + Cut specific video (e.g., ruby_pear.mp4)
      if (await assetExists(primaryVideoPath)) {
        activeController = VideoPlayerController.asset(primaryVideoPath);
      }
      // 2. Fallback to Generic Cut video (e.g., pear.mp4)
      else if (await assetExists(fallbackVideoPath)) {
        activeController = VideoPlayerController.asset(fallbackVideoPath);
      }
      // 3. Absolute Fallback
      else {
        throw Exception("No specific or generic video found");
      }

      await activeController.initialize();

      if (activeController.value.hasError) {
        throw Exception("Video initialization failed silently");
      }

      await activeController.setVolume(0.0);
      await activeController.setLooping(true);
      await activeController.setPlaybackSpeed(0.5); // Slow down playback
      await activeController.play();

      if (mounted) {
        setState(() {
          final old = _videoController;
          _videoController = activeController;
          _isVideoLoading = false;
          old?.dispose();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasNoVideo = true;
        });
      }

      final defaultController = VideoPlayerController.asset(
        'assets/gem_video/default.mp4',
      );
      try {
        await defaultController.initialize();
        await defaultController.setVolume(0.0);
        await defaultController.setLooping(true);
        await defaultController.setPlaybackSpeed(0.5); // Slow down playback
        await defaultController.play();

        if (mounted) {
          setState(() {
            final old = _videoController;
            _videoController = defaultController;
            _isVideoLoading = false;
            old?.dispose();
          });
        }
      } catch (eFallback) {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      }
    }
  }

  void _onCutSelected(String cutId) {
    if (_selectedCut == cutId) return;
    setState(() {
      _selectedCut = cutId;
    });
    _fadeAnimController.reset();
    _fadeAnimController.forward();
    _initializeVideo(cutId);
  }

  Future<void> _exportBlueprintPdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      // Configure a clean, modern aesthetic
      final titleStyle = pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );

      final subtitleStyle = pw.TextStyle(
        fontSize: 14,
        color: PdfColors.grey700,
      );

      final sectionHeaderStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey600,
        letterSpacing: 1.5,
      );

      final valueStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );

      // Build the primary page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GEM AI ANALYSIS BLUEPRINT',
                      style: sectionHeaderStyle,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${(_stoneType ?? 'Gemstone').toUpperCase()} ANALYSIS',
                      style: titleStyle,
                    ),
                    pw.Text(
                      'Generated automatically for precision cutting',
                      style: subtitleStyle,
                    ),
                  ],
                ),
                // Pseudo logo / icon
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'AI',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 30),

            // PRIMARY CUT RECOMMENDATION
            pw.Text('OPTIMAL CUT RECOMMENDATION', style: sectionHeaderStyle),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _currentCutDetails['name'],
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#11D452'),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          _currentCutDetails['yield'],
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    _currentCutDetails['description'],
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey800,
                      lineSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // CUTTING PARAMETERS GRID
            if (_cutParameters != null && _cutParameters!.isNotEmpty) ...[
              pw.Text('AI OPTIMIZATION METRICS', style: sectionHeaderStyle),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPdfParamHighlight(
                          'Crown Angle',
                          '${(_cutParameters!['crown_angle'] as num).toStringAsFixed(1)}°',
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                        _buildPdfParamHighlight(
                          'Pavilion Angle',
                          '${(_cutParameters!['pavilion_angle'] as num).toStringAsFixed(1)}°',
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                        _buildPdfParamHighlight(
                          'Table Ratio',
                          '${(_cutParameters!['table_percent'] as num).toStringAsFixed(1)}%',
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPdfParamHighlight(
                          'Depth Ratio',
                          '${(_cutParameters!['depth_percent'] as num).toStringAsFixed(1)}%',
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                        _buildPdfParamHighlight(
                          'Aspect (L/W)',
                          (_cutParameters!['length_width_ratio'] as num)
                              .toStringAsFixed(2),
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                        _buildPdfParamHighlight(
                          'Total Facets',
                          '${(_cutParameters!['facet_count'] as num).toStringAsFixed(0)}',
                          sectionHeaderStyle,
                          valueStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
            ],

            // TOP 3 ALTERNATIVE RECOMMENDATIONS
            if (_top3Cuts != null && _top3Cuts!.isNotEmpty) ...[
              pw.Text('TOP ALTERNATIVE CUTS', style: sectionHeaderStyle),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  children: _top3Cuts!.map((cutInfo) {
                    final cutName = cutInfo['cut'] as String;
                    final confidence = (cutInfo['confidence'] as num)
                        .toDouble();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8.0),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            cutName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.Text(
                            '${(confidence * 100).toStringAsFixed(0)}%',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#11D452'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 30),
            ],

            // WARNINGS AND NOTES
            if (_warningMessage != null || _noteMessage != null) ...[
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              if (_warningMessage != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                    border: pw.Border.all(color: PdfColors.amber),
                  ),
                  child: pw.Text(
                    'WARNING: $_warningMessage',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.amber800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              if (_noteMessage != null) ...[
                pw.Text('DISCLAIMER', style: sectionHeaderStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  _noteMessage!,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                    lineSpacing: 1.5,
                  ),
                ),
              ],
            ],

            // FOOTER
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Gem Analysis Application • ${DateTime.now().toIso8601String().split('T')[0]}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      );

      // Trigger native share sheet with generated PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Blueprint_${(_stoneType ?? 'Gem').replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildPdfParamHighlight(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(), style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Map<String, dynamic> get _currentCutDetails {
    return _cutOptions.firstWhere(
      (cut) => cut['id'] == _selectedCut,
      orElse: () => _cutOptions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030805),
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
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
              icon: const Icon(
                Symbols.arrow_back,
                color: Colors.white,
                size: 20,
              ),
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
                // Left half: Video
                Expanded(
                  flex: 5,
                  child: _buildVideoSection(context, isTablet: true),
                ),
                // Right half: Details
                Expanded(
                  flex: 7,
                  child: Container(
                    color: const Color(0xFF030805),
                    child: _buildScrollableDetails(context, isTablet: true),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: [
                // 1. Fixed Video Background (FullScreen to prevent cutoff)
                Positioned.fill(
                  child: _buildVideoSection(context, isTablet: false),
                ),

                // 2. Draggable Bottom Sheet for premium overlapping vibe
                Positioned.fill(
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.40,
                    maxChildSize: 0.90,
                    builder: (context, scrollController) {
                      return _buildScrollableDetails(
                        context,
                        isTablet: false,
                        scrollController: scrollController,
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context, {required bool isTablet}) {
    final modelSrc = _get3dModelForCut(_selectedCut);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Content Layer (Video or 3D Model)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: isTablet
              ? 0
              : MediaQuery.of(context).size.height *
                    0.3, // Let model reach 70% height
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _show3DView
                ? ModelViewer(
                    key: ValueKey('3D_$modelSrc'),
                    src: modelSrc,
                    alt: '$_selectedCut 3D gem model',
                    ar: false,
                    autoRotate: true,
                    cameraControls: true,
                    cameraOrbit: _cameraOrbit,
                    backgroundColor: Colors.transparent,
                    touchAction: TouchAction.none,
                  )
                : // Video Background
                  AnimatedOpacity(
                    key: ValueKey('Video_$_selectedCut'),
                    opacity:
                        _isVideoLoading ||
                            _videoController == null ||
                            !_videoController!.value.isInitialized
                        ? 0.0
                        : 1.0,
                    duration: const Duration(milliseconds: 600),
                    child:
                        _videoController != null &&
                            _videoController!.value.isInitialized
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
          ),
        ),

        // Video dark gradient overlay
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isTablet ? Alignment.centerLeft : Alignment.topCenter,
                end: isTablet ? Alignment.centerRight : Alignment.bottomCenter,
                colors: [
                  const Color(0xFF030805).withOpacity(isTablet ? 0.6 : 0.8),
                  Colors.transparent,
                  Colors.transparent,
                  const Color(0xFF030805),
                  const Color(0xFF030805),
                ],
                stops: isTablet
                    ? const [0.0, 0.2, 0.6, 1.0, 1.0]
                    : const [
                        0.0,
                        0.15,
                        0.45,
                        0.65,
                        1.0,
                      ], // Becomes fully opaque black at 0.65, perfectly hiding the 0.70 model edge
              ),
            ),
          ),
        ),

        // Loading Indicator (only for video)
        if (!_show3DView && _isVideoLoading)
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF11D452).withOpacity(0.6),
              ),
            ),
          ),

        // Fallback Warning Overlay (only for video)
        if (!_show3DView && _hasNoVideo && !_isVideoLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.videocam_off,
                    color: Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '3D Video Model Not Available\nShowing Generic Render',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── View Mode Toggle Buttons ──
        Positioned(
          top: isTablet
              ? 120
              : MediaQuery.of(context).padding.top +
                    60, // accommodate appbar securely
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Video Toggle Button
                GestureDetector(
                  onTap: () => setState(() => _show3DView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: !_show3DView
                          ? const Color(0xFF11D452).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: !_show3DView
                            ? const Color(0xFF11D452).withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.play_circle,
                          color: !_show3DView
                              ? const Color(0xFF11D452)
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Video',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !_show3DView
                                ? const Color(0xFF11D452)
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 3D Model Toggle Button
                GestureDetector(
                  onTap: () => setState(() => _show3DView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _show3DView
                          ? const Color(0xFF11D452).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _show3DView
                            ? const Color(0xFF11D452).withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.view_in_ar,
                          color: _show3DView
                              ? const Color(0xFF11D452)
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '3D Model',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _show3DView
                                ? const Color(0xFF11D452)
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 3D Facet Highlight Labels ──
        if (_show3DView) ...[
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _buildFacetLabel('Table', () {
              setState(() => _cameraOrbit = "0deg 0deg 105%");
            }),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.45,
            child: _buildFacetLabel('Crown', () {
              setState(() => _cameraOrbit = "0deg 45deg 105%");
            }),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.55,
            child: _buildFacetLabel('Pavilion', () {
              setState(() => _cameraOrbit = "0deg 135deg 105%");
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildFacetLabel(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: const Color(0xFF11D452).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF11D452),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableDetails(
    BuildContext context, {
    required bool isTablet,
    ScrollController? scrollController,
  }) {
    String retentionText = '99%';
    if (_top3Cuts != null) {
      for (var cutData in _top3Cuts!) {
        if (cutData['cut'] == _selectedCut) {
          final conf = (cutData['confidence'] as num).toDouble();
          retentionText = '${(conf * 100).round()}% ';
          break;
        }
      }
    }

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (isTablet) const SizedBox(height: 100), // Padding below appbar
          // Detail Content Area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glassmorphic Detail Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.4,
                          ), // Base glass tint
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_warningMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Symbols.warning,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _warningMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.amber.shade200,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCut ?? 'Unknown',
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF11D452,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF11D452,
                                      ).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    retentionText,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF11D452),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cutOptions.firstWhere(
                                    (cut) => cut['id'] == _selectedCut,
                                    orElse: () => _cutOptions.first,
                                  )['description']
                                  as String,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AI OPTIMIZATION METRICS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white54,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Symbols.info,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: _showRatioMathDetails,
                                  tooltip: 'View Ratio Formulas',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Metrics Grid inside a dark glass panel
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Crown\nAngle',
                                          '${_cutParameters?['crown_angle']?.toStringAsFixed(1) ?? '--'}°',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Pavilion\nAngle',
                                          '${_cutParameters?['pavilion_angle']?.toStringAsFixed(1) ?? '--'}°',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Table\nRatio',
                                          '${_cutParameters?['table_percent'] != null ? (_cutParameters!['table_percent']).toStringAsFixed(1) : '--'}%',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(
                                      color: Colors.white10,
                                      height: 1,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Depth\nRatio',
                                          '${_cutParameters?['depth_percent'] != null ? (_cutParameters!['depth_percent']).toStringAsFixed(1) : '--'}%',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Aspect (L/\nW)',
                                          _cutParameters?['length_width_ratio']
                                                  ?.toStringAsFixed(2) ??
                                              '--',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildParamHighlight(
                                          'Total\nFacets',
                                          _cutParameters?['facet_count']
                                                  ?.round()
                                                  .toString() ??
                                              '--',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Display Predicted Cut Family if present
                  if (_predictedCutFamily != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF193322).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF11D452).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Symbols.diamond,
                            color: Color(0xFF11D452),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cut Family: $_predictedCutFamily',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF11D452),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Recommendations Scroll Section
                  const SizedBox(height: 24),
                  if (_top3Cuts != null && _top3Cuts!.isNotEmpty) ...[
                    Text(
                      'TOP 3 RECOMMENDATIONS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dark glass panel for recommendations
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: _top3Cuts!.take(3).map((cutData) {
                              final cutName = cutData['cut'] as String;
                              final conf = (cutData['confidence'] as num)
                                  .toDouble();
                              final isSelected = cutName == _selectedCut;

                              return GestureDetector(
                                onTap: () => _onCutSelected(cutName),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF193322,
                                          ).withOpacity(0.8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(
                                              0xFF11D452,
                                            ).withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cutName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        '${(conf * 100).round()}% ',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? const Color(0xFF11D452)
                                              : Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_noteMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Symbols.info,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _noteMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Export Blueprint Button
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _isExporting ? null : _exportBlueprintPdf,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _isExporting
                            ? const Color(0xFF193322)
                            : const Color(0xFF11D452),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!_isExporting)
                            BoxShadow(
                              color: const Color(0xFF11D452).withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isExporting)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF11D452),
                                ),
                              ),
                            )
                          else ...[
                            const Icon(Symbols.download, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Export Blueprint',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
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

  Widget _buildParamHighlight(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showRatioMathDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF193322),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ratio Formulas',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                _buildMathFormulaRow(
                  'Aspect Ratio',
                  'Length',
                  'Width',
                  _length,
                  _width,
                ),
                const SizedBox(height: 32),
                _buildMathFormulaRow(
                  'Depth Ratio',
                  'Depth',
                  'Width',
                  _depth,
                  _width,
                ),
                const SizedBox(height: 32),
                _buildMathFormulaRow(
                  'Length Width Ratio',
                  'Length',
                  'Width',
                  _length,
                  _width,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11D452).withOpacity(0.2),
                      foregroundColor: const Color(0xFF11D452),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMathFormulaRow(
    String title,
    String numeratorLabel,
    String denominatorLabel,
    double? numeratorVal,
    double? denominatorVal,
  ) {
    final hasVals =
        numeratorVal != null && denominatorVal != null && denominatorVal != 0;
    final valText = hasVals
        ? '= ${(numeratorVal / denominatorVal).toStringAsFixed(2)}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$title = ',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    numeratorLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: 1,
                    width: 60,
                    color: Colors.white54,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  Text(
                    denominatorLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (hasVals) ...[
                const SizedBox(width: 16),
                Text(
                  '=',
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      numeratorVal.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      height: 1,
                      width: 40,
                      color: Colors.white54,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    Text(
                      denominatorVal.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Text(
                  valText,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF11D452),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF193322).withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFF23482F))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                child: const _NavIcon(icon: Symbols.home, label: 'Home'),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, '/detection_input'),
                child: const _NavIcon(
                  icon: Symbols.diamond,
                  label: 'Analyze',
                  isActive: true,
                ),
              ),
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
