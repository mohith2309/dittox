class SecurityUtils {
  static String sanitizeToken(String? token) {
    final raw = (token ?? "").trim();
    if (raw.isEmpty) return "";
    final safe = raw.replaceAll(RegExp(r'[\r\n]'), "");
    return safe;
  }

  static Map<String, String> authHeaders(String? token) {
    final safeToken = sanitizeToken(token);
    if (safeToken.isEmpty) return <String, String>{};
    return <String, String>{"X-auth-token": "bearer $safeToken"};
  }

  static Uri? safeWebUri(
    dynamic value, {
    bool allowHttp = false,
  }) {
    final raw = (value ?? "").toString().trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.scheme == "https") return uri;
    if (allowHttp && uri.scheme == "http") return uri;
    return null;
  }
}
