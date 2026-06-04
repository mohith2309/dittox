class MapsApiConfig {
  static const String _fromDefine = String.fromEnvironment(
    "GOOGLE_MAPS_API_KEY",
  );

  static String get key {
    if (_fromDefine.trim().isEmpty) {
      throw Exception('MAPS_API_KEY not configured. Build with --dart-define=GOOGLE_MAPS_API_KEY=your_key');
    }
    return _fromDefine;
  }
}
