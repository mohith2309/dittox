/// Helpers for Firebase Phone Authentication (SMS OTP).
class FirebasePhoneAuth {
  /// Normalizes a user-entered phone number to E.164 (e.g. +919876543210),
  /// which is what FirebaseAuth.verifyPhoneNumber expects.
  ///
  /// - Already-prefixed numbers ("+44...") are kept as-is (digits only after +).
  /// - Bare numbers get [defaultCountryCode], after stripping a leading 0.
  static String toE164(String raw, {String defaultCountryCode = '+91'}) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) {
      final digits = trimmed.substring(1).replaceAll(RegExp(r'\D'), '');
      return '+$digits';
    }
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return '$defaultCountryCode$digits';
  }

  /// Masks a number for display: +919876543210 -> +91 ******3210.
  static String maskForDisplay(String e164) {
    if (e164.length <= 4) return e164;
    final tail = e164.substring(e164.length - 4);
    return '${e164.substring(0, e164.length - 4).replaceAll(RegExp(r'\d'), '*')}$tail';
  }
}
