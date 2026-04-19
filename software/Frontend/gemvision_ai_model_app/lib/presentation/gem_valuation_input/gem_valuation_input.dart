import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:sizer/sizer.dart';

class GemValuationInput extends StatefulWidget {
  const GemValuationInput({super.key});

  @override
  State<GemValuationInput> createState() => _GemValuationInputState();
}

class _GemValuationInputState extends State<GemValuationInput> {
  final TextEditingController _gemTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  PlatformFile? mainImage;
  List<PlatformFile> additionalImages = [];

  bool isAnalyzing = false;

  final Random random = Random();

  Future<void> pickMainImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => mainImage = result.files.first);
    }
  }

  Future<void> pickAdditionalImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => additionalImages.addAll(result.files));
    }
  }

  void removeMainImage() => setState(() => mainImage = null);

  void removeAdditionalImage(int index) => setState(() => additionalImages.removeAt(index));

  void analyzeGemstone() {
    final gemType = _gemTypeController.text.trim();
    final weightText = _weightController.text.trim();

    if (gemType.isEmpty || weightText.isEmpty || mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter gem type, weight, and upload main gem photo")),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid weight")),
      );
      return;
    }

    setState(() => isAnalyzing = true);

    // Simulate processing delay
    Future.delayed(const Duration(seconds: 2), () {
      final grades = ['Excellent', 'Very Good', 'Good', 'Fair', 'Poor'];
      final qualityGrade = grades[random.nextInt(grades.length)];

      int defectPercentage;
      switch (qualityGrade) {
        case 'Excellent':
          defectPercentage = 1 + random.nextInt(4);
          break;
        case 'Very Good':
          defectPercentage = 5 + random.nextInt(7);
          break;
        case 'Good':
          defectPercentage = 12 + random.nextInt(8);
          break;
        case 'Fair':
          defectPercentage = 21 + random.nextInt(9);
          break;
        default:
          defectPercentage = 31 + random.nextInt(20);
      }

      // Realistic LKR pricing based on Sri Lankan gems
      final gemKey = gemType.toLowerCase();
      double basePricePerCarat = 100000; // fallback
      if (gemKey.contains("blue sapphire")) basePricePerCarat = 1550000;
      else if (gemKey.contains("pink sapphire")) basePricePerCarat = 1600000;
      else if (gemKey.contains("ruby")) basePricePerCarat = 1550000;
      else if (gemKey.contains("star sapphire")) basePricePerCarat = 400000;
      else if (gemKey.contains("yellow sapphire")) basePricePerCarat = 300000;
      else if (gemKey.contains("white sapphire")) basePricePerCarat = 100000;
      else if (gemKey.contains("geuda")) basePricePerCarat = 250000;
      else if (gemKey.contains("spinel")) basePricePerCarat = 550000;
      else if (gemKey.contains("garnet")) basePricePerCarat = 80000;

      final qualityFactor = (100 - defectPercentage) / 100.0;
      final sizeMultiplier = weight >= 5 ? 1.8 : weight >= 2 ? 1.35 : weight >= 1 ? 1.15 : 1.0;
      final estimatedValueLKR = (basePricePerCarat * weight * qualityFactor * sizeMultiplier).round();

      // Combine all images
      final allImages = <PlatformFile>[];
      if (mainImage != null) allImages.add(mainImage!);
      allImages.addAll(additionalImages);

      Navigator.pushNamed(
        context,
        '/gem-valuation-result',
        arguments: {
          'gemType': gemType,
          'weight': weight,
          'qualityGrade': qualityGrade,
          'defectPercentage': defectPercentage.toDouble(),
          'estimatedValueLKR': estimatedValueLKR.toDouble(),
          'images': allImages,
        },
      );

      setState(() => isAnalyzing = false);
    });
  }

  @override
  void dispose() {
    _gemTypeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Gem Valuation"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gem Type
            Text("Gem Type", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            TextField(
              controller: _gemTypeController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "e.g. Blue Sapphire, Ruby",
                prefixIcon: const Icon(Icons.diamond_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),

            SizedBox(height: 3.h),

            // Weight
            Text("Weight (Carats)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "Enter weight",
                suffixText: "ct",
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),

            SizedBox(height: 3.h),

            // Main Image (Required)
            Text("Main Gem Photo (Required)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            InkWell(
              onTap: isAnalyzing ? null : pickMainImage,
              child: Container(
                height: 22.h,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                ),
                child: mainImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: theme.colorScheme.primary),
                          SizedBox(height: 1.h),
                          Text("Tap to upload main photo", style: theme.textTheme.titleMedium),
                          Text("Clear front view recommended", style: theme.textTheme.bodySmall),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb && mainImage!.bytes != null
                                ? Image.memory(mainImage!.bytes!, fit: BoxFit.cover)
                                : Image.file(File(mainImage!.path!), fit: BoxFit.cover),
                          ),
                          Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: removeMainImage)),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 3.h),

            // Additional Images (Optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Additional Photos (Optional)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: isAnalyzing ? null : pickAdditionalImages, icon: const Icon(Icons.add), label: const Text("Add More")),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              child: additionalImages.isEmpty
                  ? Center(child: Text("No additional photos\nAdd side/top views for better analysis", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: additionalImages.length,
                      itemBuilder: (context, i) {
                        final file = additionalImages[i];
                        return Padding(
                          padding: EdgeInsets.all(1.h),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb && file.bytes != null
                                    ? Image.memory(file.bytes!, width: 20.w, height: 18.h, fit: BoxFit.cover)
                                    : Image.file(File(file.path!), width: 20.w, height: 18.h, fit: BoxFit.cover),
                              ),
                              Positioned(top: 4, right: 4, child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 24), onPressed: () => removeAdditionalImage(i))),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(height: 5.h),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton.icon(
                icon: isAnalyzing ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.analytics),
                label: Text(isAnalyzing ? "Analyzing..." : "Analyze Gemstone", style: const TextStyle(fontSize: 18)),
                onPressed: isAnalyzing ? null : analyzeGemstone,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}