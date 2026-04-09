import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // ======================================================
  // 🔹 CHANGE THIS to your Vercel deployment URL after deploying!
  // Example: "https://bhu-jalam-backend.vercel.app"
  // For local testing: "http://10.0.2.2:8000" (Android emulator)
  //                    "http://localhost:8000" (web/desktop)
  // ======================================================
  static const String baseUrl = "http://10.0.2.2:8000";

  // Helper: make GET request
  static Future<http.Response> _get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      return response;
    } on TimeoutException {
      throw Exception("Request timed out. Please try again.");
    } catch (e) {
      throw Exception("Failed request: $e");
    }
  }

  // Get all districts
  static Future<List<String>> getDistricts() async {
    final response = await _get("$baseUrl/districts");
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    }
    throw Exception("Failed to load districts");
  }

  // Get all blocks for a district
  static Future<List<String>> getBlocks(String district) async {
    final response = await _get("$baseUrl/blocks?district=$district");
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    }
    throw Exception("Failed to load blocks");
  }

  // Get district name if you only have block
  static Future<String?> getDistrictByBlock(String block) async {
    try {
      final response = await _get("$baseUrl/district-by-block?block=$block");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['district'];
      }
    } catch (e) {
      print("Error getting district: $e");
    }
    return null;
  }

  // Get all blocks with their district
  static Future<Map<String, String>> getAllBlocks() async {
    final response = await _get("$baseUrl/blocks-all");
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.cast<String, String>();
    }
    throw Exception("Failed to load all blocks");
  }

  // Get plot data (JSON data points for client-side fl_chart rendering)
  static Future<List<Map<String, dynamic>>?> getPlotData(String district, String block) async {
    try {
      final response = await _get("$baseUrl/plot-mean-levels?district=$district&block=$block&days=10");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data_points'] != null) {
          return List<Map<String, dynamic>>.from(data['data_points']);
        }
      }
    } catch (e) {
      print("Error getting plot: $e");
    }
    return null;
  }

  // Fetch all extra stats
  static Future<Map<String, dynamic>> getExtras(String district, String block) async {
    final response = await _get("$baseUrl/extras?district=$district&block=$block");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load extras");
  }

  // Get daily fluctuation
  static Future<Map<String, dynamic>?> getDailyFluctuation(String district, String block) async {
    try {
      final response = await _get("$baseUrl/fluctuations-daily?district=$district&block=$block");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getting fluctuation: $e");
    }
    return null;
  }

  // Get yield estimate
  static Future<Map<String, dynamic>?> getYield(String district, String block, {int days = 30}) async {
    try {
      final response = await _get("$baseUrl/yield?district=$district&block=$block&days=$days");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getting yield: $e");
    }
    return null;
  }

  // Get sustainability score
  static Future<Map<String, dynamic>?> getScore(String district, String block) async {
    try {
      final response = await _get("$baseUrl/score?district=$district&block=$block");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getting score: $e");
    }
    return null;
  }

  // Get last recorded timestamp
  static Future<String?> getLastRecorded(String district, String block) async {
    try {
      final response = await _get("$baseUrl/last-recorded?district=$district&block=$block");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['last_recorded'];
      }
    } catch (e) {
      print("Error getting last recorded: $e");
    }
    return null;
  }

  // Get last water level
  static Future<double?> getLastWaterLevel(String district, String block) async {
    try {
      final response = await _get("$baseUrl/last-water-level?district=$district&block=$block");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['last_water_level']?.toDouble();
      }
    } catch (e) {
      print("Error getting water level: $e");
    }
    return null;
  }

  // Get rainfall
  static Future<double?> getRainfall(String district, String block) async {
    try {
      final response = await _get("$baseUrl/rainfall?district=$district&block=$block");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rainfall_mm']?.toDouble();
      }
    } catch (e) {
      print("Error getting rainfall: $e");
    }
    return null;
  }

  // Get aquifer type
  static Future<String?> getAquiferType(String district, String block) async {
    try {
      final response = await _get("$baseUrl/aquifer?district=$district&block=$block");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['aquifer_type'];
      }
    } catch (e) {
      print("Error getting aquifer: $e");
    }
    return null;
  }
}
