import 'package:flutter/material.dart';

import 'notifications_screen.dart';

class NotificationPage extends StatelessWidget {
  static const routeName = "/notification page";
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsScreen();
  }
}
