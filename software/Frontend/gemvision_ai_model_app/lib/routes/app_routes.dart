import 'package:flutter/material.dart';
import '../presentation/analysis_history/analysis_history.dart';
import '../presentation/detection_results/detection_results.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/cut_recommendation_input/cut_recommendation_input.dart';
import '../presentation/gemstone_detection_input/gemstone_detection_input.dart';
import '../presentation/cut_recommendation_results/cut_recommendation_results.dart';

import '../presentation/gem_valuation_input/gem_valuation_input.dart';
import '../presentation/gem_valuation_result/gem_valuation_result.dart';


class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String analysisHistory = '/analysis-history';
  static const String detectionResults = '/detection-results';
  static const String homeDashboard = '/home-dashboard';
  static const String cutRecommendationInput = '/cut-recommendation-input';
  static const String gemstoneDetectionInput = '/gemstone-detection-input';
  static const String cutRecommendationResults = '/cut-recommendation-results';

  static const String gemValuationInput = '/gem-valuation-input';
  static const String gemValuationResult = '/gem-valuation-result';
  

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeDashboard(),
    analysisHistory: (context) => const AnalysisHistory(),
    detectionResults: (context) => const DetectionResults(),
    homeDashboard: (context) => const HomeDashboard(),
    cutRecommendationInput: (context) => const CutRecommendationInput(),
    gemstoneDetectionInput: (context) => const GemstoneDetectionInput(),
    cutRecommendationResults: (context) => const CutRecommendationResults(),

    gemValuationInput: (context) => const GemValuationInput(),
    
    gemValuationResult: (context) => const GemValuationResult(),

    // TODO: Add your other routes here
  };
}
