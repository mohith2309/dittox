import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationHistoryStore {
  static const String _key = 'recent_locations';
  static const int _maxLocations = 5;

  static Future<List<Map<String, dynamic>>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addLocation({
    required String placeName,
    required double latitude,
    required double longitude,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getRecentLocations();
    
    locations.removeWhere((loc) => 
      loc['placeName'] == placeName || 
      (loc['latitude'] == latitude && loc['longitude'] == longitude)
    );
    
    locations.insert(0, {
      'placeName': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'country': country ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (locations.length > _maxLocations) {
      locations.removeRange(_maxLocations, locations.length);
    }
    
    await prefs.setString(_key, jsonEncode(locations));
  }

  static Future<void> clearLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<Map<String, dynamic>?> getLastLocation() async {
    final locations = await getRecentLocations();
    return locations.isNotEmpty ? locations.first : null;
  }
}
