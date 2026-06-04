import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_notifications.dart';

enum PillType { info, success, warning, error }

class PillNotifications {
  static void show(
    BuildContext context, {
    required String message,
    PillType type = PillType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (type == PillType.error) HapticFeedback.heavyImpact();
    final notifs = context.read<AppNotifications>();
    // Route legacy pill calls as a single active Samsung-style notification.
    notifs.dismissAll();
    final String title = switch (type) {
      PillType.success => 'Success',
      PillType.warning => 'Warning',
      PillType.error => 'Error',
      PillType.info => 'Info',
    };
    switch (type) {
      case PillType.success:
        notifs.addSuccess(title: title, body: message);
      case PillType.warning:
        notifs.addWarning(title: title, body: message);
      case PillType.error:
        notifs.addError(title: title, body: message);
      case PillType.info:
        notifs.addInfo(title: title, body: message);
    }
  }
}
