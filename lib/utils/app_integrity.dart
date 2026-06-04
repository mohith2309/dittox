import 'dart:async';

import 'package:flutter/services.dart';

class AppIntegrity {
  static const MethodChannel _channel = MethodChannel("dittox/security");

  static Future<bool> isDeviceCompromised() async {
    try {
      final value = await _channel
          .invokeMethod<bool>("isDeviceCompromised")
          .timeout(const Duration(milliseconds: 800), onTimeout: () => false);
      return value ?? false;
    } catch (_) {
      return false;
    }
  }
}
