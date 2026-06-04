import "package:http/http.dart" as http;

import "dart:convert";

import "../model/auto_complete_result.dart";
import "../utils/maps_api_config.dart";

class MapServices {
  final String key = MapsApiConfig.key;
  final String types = "geocode";

  Future<http.Response> _getWithRetry(Uri uri) async {
    final attempts = [0, 400, 900];
    Object? lastError;
    for (final waitMs in attempts) {
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
      try {
        return await http.get(uri).timeout(const Duration(seconds: 12));
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception("Network error: ${lastError ?? "request failed"}");
  }

  // https://maps.googleapis.com/maps/api/place/autocomplete/json
  // ?input=tade
  // &language=in
  // &types=geocode
  // &key=REDACTED_ROTATE_THIS_KEY

  Future<List<AutoCompleteResult>> searchPlace(String searchInput) async {
    final query = searchInput.trim();
    if (query.isEmpty) return <AutoCompleteResult>[];
    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/autocomplete/json",
      <String, String>{
        "input": query,
        "language": "en",
        "types": types,
        "key": key,
      },
    );
    final response = await _getWithRetry(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Places autocomplete failed (${response.statusCode})");
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (json["status"] ?? "").toString();
    if (status != "OK" && status != "ZERO_RESULTS") {
      final message = (json["error_message"] ?? status).toString();
      throw Exception("Places autocomplete error: $message");
    }
    final result = (json["predictions"] as List? ?? <dynamic>[]);
    return result
        .map((e) => AutoCompleteResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // https://maps.googleapis.com/maps/api/place/details/json
  // ?fields=geometry
  // &place_id=ChIJsyvJu7C0NzoRCgI1dytnJx8
  // &key=REDACTED_ROTATE_THIS_KEY

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final normalizedPlaceId = placeId.trim();
    if (normalizedPlaceId.isEmpty) {
      throw Exception("Missing place id");
    }
    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/details/json",
      <String, String>{
        "fields": "geometry",
        "place_id": normalizedPlaceId,
        "key": key,
      },
    );

    final response = await _getWithRetry(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Place details failed (${response.statusCode})");
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (json["status"] ?? "").toString();
    if (status != "OK") {
      final message = (json["error_message"] ?? status).toString();
      throw Exception("Place details error: $message");
    }
    return Map<String, dynamic>.from(json["result"] as Map);
  }
}
