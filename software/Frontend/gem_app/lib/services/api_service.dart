import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Uses machine's local IP or fallback to 10.0.2.2 for Android emulator
  // Set this to true to use the local server, false for the deployed server
  static const bool _useLocalhost = false;
  
  static const String _baseUrl = _useLocalhost 
      ? (kIsWeb ? 'http://127.0.0.1:8000' : 'http://192.168.8.103:8000') 
      : 'http://51.20.8.248';

  /// Calls the Gem Identification API
  static Future<Map<String, dynamic>> identifyGem({
    required XFile imageFile,
    required double ri,
    required double sg,
    required double hardness,
    required String color,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');  //endpoint 
      final request = http.MultipartRequest('POST', uri)
        ..fields['ri'] = ri.toString()
        ..fields['sg'] = sg.toString()
        ..fields['hardness'] = hardness.toString()
        ..fields['color'] = color;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to identify gem: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during gem identification: $e');
    }
  }

  /// Calls the Gem Cut Advisor API
  static Future<Map<String, dynamic>> recommendCut({
    required String gemstoneType,
    required double ri,
    required double caratWeight,
    required double lengthMm,
    required double widthMm,
    required double depthMm,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/recommend-cut');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gemstone_type': gemstoneType,
          'ri': ri,
          'carat_weight': caratWeight,
          'length_mm': lengthMm,
          'width_mm': widthMm,
          'depth_mm': depthMm,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to recommend cut: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during cut recommendation: $e');
    }
  }
}
