import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'cloud_sync_guard.dart';

enum HealthStatus { ok, warning, error }

class HealthCheckItem {
  final String title;
  final HealthStatus status;
  final String message;

  const HealthCheckItem({
    required this.title,
    required this.status,
    required this.message,
  });
}

class ServerHealthReport {
  final List<HealthCheckItem> checks;

  const ServerHealthReport({required this.checks});

  bool get hasBlockingIssue => checks.any((c) => c.status == HealthStatus.error);
}

class ServerHealthService {
  static const Duration _timeout = Duration(seconds: 5);

  static Future<ServerHealthReport> runStartupChecks() async {
    final checks = <HealthCheckItem>[];

    final connectivity = await Connectivity()
        .checkConnectivity()
        .timeout(_timeout, onTimeout: () => <ConnectivityResult>[]);

    final hasInternet = connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.ethernet);

    checks.add(
      HealthCheckItem(
        title: "Internet",
        status: hasInternet ? HealthStatus.ok : HealthStatus.error,
        message: hasInternet
            ? "Connected"
            : "No internet connection available.",
      ),
    );

    if (!hasInternet) {
      checks.add(
        const HealthCheckItem(
          title: "Dittox API",
          status: HealthStatus.error,
          message: "Skipped because internet is unavailable.",
        ),
      );
    } else {
      try {
        final response = await http.get(Uri.parse(ApiEndPoiunts.baseUrl)).timeout(_timeout);
        final reachable = response.statusCode < 500;
        checks.add(
          HealthCheckItem(
            title: "Dittox API",
            status: reachable ? HealthStatus.ok : HealthStatus.error,
            message: reachable
                ? "Reachable (HTTP ${response.statusCode})"
                : "Server returned ${response.statusCode}.",
          ),
        );
      } on TimeoutException {
        checks.add(
          const HealthCheckItem(
            title: "Dittox API",
            status: HealthStatus.error,
            message: "Timed out while contacting the API server.",
          ),
        );
      } catch (_) {
        checks.add(
          const HealthCheckItem(
            title: "Dittox API",
            status: HealthStatus.error,
            message: "Could not reach the API server.",
          ),
        );
      }
    }

    checks.add(
      const HealthCheckItem(
        title: "Cloud Sync",
        status: CloudSyncGuard.cloudSyncEnabled
            ? HealthStatus.ok
            : HealthStatus.warning,
        message: CloudSyncGuard.cloudSyncEnabled
            ? "Enabled"
            : "Disabled for this build (local/demo mode supported).",
      ),
    );

    return ServerHealthReport(checks: checks);
  }
}
