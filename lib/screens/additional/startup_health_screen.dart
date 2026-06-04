import 'package:flutter/material.dart';

import '../../utils/server_health_service.dart';

class StartupHealthScreen extends StatelessWidget {
  final ServerHealthReport report;
  final VoidCallback onRetry;
  final VoidCallback onContinueDemo;

  const StartupHealthScreen({
    super.key,
    required this.report,
    required this.onRetry,
    required this.onContinueDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Startup Checks"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Some services are unavailable. You can continue in Demo Mode.",
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: report.checks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = report.checks[index];
                  final (_, fg, icon) = _styleFor(item.status);
                  return Card(
                    child: ListTile(
                      leading: Icon(icon, color: fg),
                      title: Text(item.title),
                      subtitle: Text(item.message),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinueDemo,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text("Continue in Demo Mode"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry checks"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _styleFor(HealthStatus status) {
    return switch (status) {
      HealthStatus.ok => (
          const Color(0x2022C55E),
          const Color(0xFF22C55E),
          Icons.check_rounded
        ),
      HealthStatus.warning => (
          const Color(0x20F59E0B),
          const Color(0xFFF59E0B),
          Icons.warning_amber_rounded
        ),
      HealthStatus.error => (
          const Color(0x20EF4444),
          const Color(0xFFEF4444),
          Icons.error_outline_rounded
        ),
    };
  }
}
