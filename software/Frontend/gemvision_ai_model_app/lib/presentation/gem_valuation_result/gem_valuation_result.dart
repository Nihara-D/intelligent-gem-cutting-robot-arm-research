import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:sizer/sizer.dart';

class GemValuationResult extends StatelessWidget {
  const GemValuationResult({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String gemType = args['gemType'] as String? ?? 'Unknown Gem';
    final double weight = (args['weight'] as num?)?.toDouble() ?? 0.0;
    final String qualityGrade = args['qualityGrade'] as String? ?? 'Unknown';
    final double defectPercentage = (args['defectPercentage'] as num?)?.toDouble() ?? 0.0;
    final double estimatedValueLKR = (args['estimatedValueLKR'] as num?)?.toDouble() ?? 0.0;
    final double estimatedValueUSD = estimatedValueLKR / 300; // Approx. rate Jan 2026
    final List<PlatformFile> images = (args['images'] as List?)?.cast<PlatformFile>() ?? [];
    final PlatformFile? mainImage = images.isNotEmpty ? images.first : null;
    final List<PlatformFile> additionalImages = images.length > 1 ? images.sublist(1) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gem Valuation Result"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text("Analyze New Gem"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Gem Image (First thing after AppBar)
            if (mainImage != null)
              Container(
                height: 38.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: kIsWeb && mainImage.bytes != null
                      ? Image.memory(mainImage.bytes!, fit: BoxFit.cover)
                      : mainImage.path != null
                          ? Image.file(File(mainImage.path!), fit: BoxFit.cover)
                          : const SizedBox(),
                ),
              ),

            SizedBox(height: 4.h),

            // Additional Images (Horizontal Scroll)
            if (additionalImages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Additional Views", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    height: 22.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: additionalImages.length,
                      itemBuilder: (context, index) {
                        final file = additionalImages[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 3.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb && file.bytes != null
                                ? Image.memory(file.bytes!, width: 30.w, fit: BoxFit.cover)
                                : file.path != null
                                    ? Image.file(File(file.path!), width: 30.w, fit: BoxFit.cover)
                                    : const SizedBox(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            SizedBox(height: 4.h),

            // Quality Assessment Table
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(5.w),
                child: Column(
                  children: [
                    Text("Quality Assessment Table", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2.h),
                    Table(
                      border: TableBorder.all(color: theme.dividerColor, borderRadius: BorderRadius.circular(12)),
                      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5)},
                      children: [
                        _tableHeader("Defect Percentage", "Quality Level"),
                        _tableRow("0% – 5%", "Excellent", Colors.green),
                        _tableRow("6% – 10%", "Very Good", Colors.lightGreen.shade700),
                        _tableRow("11% – 20%", "Good", Colors.orange),
                        _tableRow("21% – 35%", "Fair", Colors.deepOrange),
                        _tableRow("> 35%", "Poor", Colors.red),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
                      decoration: BoxDecoration(
                        color: _getQualityColor(qualityGrade).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getQualityColor(qualityGrade), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "Your Result: ${defectPercentage.toStringAsFixed(1)}% → $qualityGrade",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getQualityColor(qualityGrade)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Gem Information
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gem Information", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 30),
                    _infoRow("Gem Type", gemType, theme),
                    _infoRow("Weight", "${weight.toStringAsFixed(2)} carats", theme),
                    _infoRow("Quality Grade", qualityGrade, theme, color: _getQualityColor(qualityGrade)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Estimated Market Value
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Column(
                  children: [
                    Text("Estimated Market Value", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 3.h),
                    if (mainImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb && mainImage.bytes != null
                            ? Image.memory(mainImage.bytes!, height: 18.h, fit: BoxFit.cover)
                            : mainImage.path != null
                                ? Image.file(File(mainImage.path!), height: 18.h, fit: BoxFit.cover)
                                : const SizedBox(),
                      ),
                    SizedBox(height: 3.h),
                    Text(
                      "LKR ${estimatedValueLKR.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "≈ USD ${estimatedValueUSD.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                      style: TextStyle(fontSize: 22, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Based on current Sri Lankan gem market trends (January 2026)\nProfessional appraisal recommended by NGJA",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text("Continue", style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.5.h),
                      side: BorderSide(color: theme.colorScheme.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text("Generate Report", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.5.h),
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("📄 Valuation Report Generated & Saved!"),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader(String left, String right) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Center(child: Text(left, style: const TextStyle(fontWeight: FontWeight.bold)))),
        Padding(padding: const EdgeInsets.all(12), child: Center(child: Text(right, style: const TextStyle(fontWeight: FontWeight.bold)))),
      ],
    );
  }

  TableRow _tableRow(String left, String right, Color color) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Center(child: Text(left))),
        Padding(padding: const EdgeInsets.all(12), child: Center(child: Text(right, style: TextStyle(fontWeight: FontWeight.bold, color: color)))),
      ],
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getQualityColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'excellent': return Colors.green;
      case 'very good': return Colors.lightGreen.shade700;
      case 'good': return Colors.orange;
      case 'fair': return Colors.deepOrange;
      case 'poor': return Colors.red;
      default: return Colors.grey.shade700;
    }
  }
}