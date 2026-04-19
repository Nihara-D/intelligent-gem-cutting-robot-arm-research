import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GemValuationService {
  // ⚠️ IMPORTANT: Replace with YOUR computer's IP address
  // Find it: Windows (ipconfig) / Mac (ifconfig) / Linux (ip addr)
  static const String baseUrl = 'http://192.168.1.100:8000';
  
  static Future<Map<String, dynamic>> analyzeGemstone({
    required String gemType,
    required List<File> images,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/analyze-gem/');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['gem_type'] = gemType;
      
      for (var image in images) {
        var imageFile = await http.MultipartFile.fromPath(
          'images',
          image.path,
        );
        request.files.add(imageFile);
      }
      
      print('📤 Sending request to: $uri');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error: $e');
    }
  }
  
  static double convertUsdToLkr(double usd) {
    return usd * 320.0; // Current approximate rate
  }
  
  static String getQualityGrade(double defectPercentage) {
    if (defectPercentage < 5) return "Excellent";
    if (defectPercentage < 10) return "Very Good";
    if (defectPercentage < 20) return "Good";
    if (defectPercentage < 30) return "Fair";
    return "Poor";
  }
}