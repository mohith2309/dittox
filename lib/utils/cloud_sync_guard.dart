import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CloudSyncGuard {
  static const bool cloudSyncEnabled = bool.fromEnvironment(
    "DITTOX_ENABLE_FIRESTORE_SYNC",
    defaultValue: true,
  );

  static bool _disabledForSession = false;

  static Future<void> runOptionalWrite(Future<void> Function() write) async {
    if (!cloudSyncEnabled) return;
    if (_disabledForSession) return;

    try {
      await write();
    } on FirebaseException catch (error) {
      if (_shouldDisableCloudSync(error)) {
        _disabledForSession = true;
        debugPrint(
          "Cloud sync disabled for this app session: ${error.code}. "
          "Enable Firestore for the Firebase project to restore cloud sync.",
        );
        return;
      }
      debugPrint("Optional cloud sync failed: ${error.code}");
    } catch (_) {
      // Local app flows should not fail because an optional cloud sync failed.
    }
  }

  static bool _shouldDisableCloudSync(FirebaseException error) {
    return error.code == "permission-denied" ||
        error.code == "failed-precondition" ||
        error.code == "unavailable";
  }
}
