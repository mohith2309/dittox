import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase auth error codes to short, user-friendly messages.
/// Falls back to the SDK message (or a generic line) for unmapped codes.
String friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
      return 'Incorrect email or password.';
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'email-already-in-use':
      return 'An account already exists for that email. Try signing in.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled for this app.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'account-exists-with-different-credential':
      return 'This email is already linked to a different sign-in method.';
    case 'invalid-verification-code':
      return 'That code is incorrect. Check the SMS and try again.';
    case 'invalid-verification-id':
    case 'session-expired':
    case 'code-expired':
      return 'The code expired. Request a new one.';
    case 'missing-verification-code':
      return 'Enter the 6-digit code sent to your phone.';
    case 'invalid-phone-number':
    case 'missing-phone-number':
      return 'That phone number looks invalid.';
    case 'quota-exceeded':
      return 'SMS limit reached. Please try again later.';
    case 'credential-already-in-use':
      return 'That phone number is already linked to another account.';
    case 'requires-recent-login':
      return 'Please sign in again to complete this change.';
    default:
      final msg = e.message?.trim();
      return (msg == null || msg.isEmpty) ? 'Authentication failed.' : msg;
  }
}
