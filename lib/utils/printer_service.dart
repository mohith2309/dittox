import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPrinter {
  final String id;
  final String name;
  final String host;
  final int port;
  final String workflowNote;

  const SavedPrinter({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.workflowNote = '',
  });

  bool get canDirectPrint => port == 9100;

  SavedPrinter copyWith({String? workflowNote}) {
    return SavedPrinter(
      id: id,
      name: name,
      host: host,
      port: port,
      workflowNote: workflowNote ?? this.workflowNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'workflowNote': workflowNote,
      };

  factory SavedPrinter.fromJson(Map<String, dynamic> json) {
    final host = (json['host'] ?? '').toString();
    final port = json['port'] is int
        ? json['port'] as int
        : int.tryParse((json['port'] ?? '').toString()) ?? 9100;
    return SavedPrinter(
      id: (json['id'] ?? '$host:$port').toString(),
      name: (json['name'] ?? 'Printer $host').toString(),
      host: host,
      port: port,
      workflowNote: (json['workflowNote'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SavedPrinter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PrinterService {
  static const String _savedPrintersKey = 'dittox_saved_printers_v1';
  static const String _lastPrinterKey = 'dittox_last_printer_v1';

  static Future<List<SavedPrinter>> loadSavedPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedPrintersKey);
    if (raw == null || raw.trim().isEmpty) return const <SavedPrinter>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <SavedPrinter>[];
      return decoded
          .whereType<Map>()
          .map((item) => SavedPrinter.fromJson(Map<String, dynamic>.from(item)))
          .where((printer) => printer.host.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const <SavedPrinter>[];
    }
  }

  static Future<void> savePrinter(SavedPrinter printer) async {
    final printers = await loadSavedPrinters();
    final merged = <String, SavedPrinter>{
      for (final existing in printers) existing.id: existing,
      printer.id: printer,
    }.values.toList();
    await _savePrinters(merged);
  }

  static Future<SavedPrinter?> loadLastPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastPrinterKey);
    if (id == null) return null;
    final printers = await loadSavedPrinters();
    for (final printer in printers) {
      if (printer.id == id) return printer;
    }
    return null;
  }

  static Future<void> rememberLastPrinter(SavedPrinter printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPrinterKey, printer.id);
    await savePrinter(printer);
  }

  static Future<List<SavedPrinter>> scanNetworkPrinters({
    Duration timeout = const Duration(milliseconds: 260),
  }) async {
    final prefix = await _localSubnetPrefix();
    if (prefix == null) return const <SavedPrinter>[];

    final found = <String, SavedPrinter>{};
    const ports = <int>[9100, 631];
    final addresses = List.generate(254, (index) => '$prefix.${index + 1}');

    for (var i = 0; i < addresses.length; i += 32) {
      final slice = addresses.skip(i).take(32);
      final checks = <Future<void>>[];
      for (final host in slice) {
        for (final port in ports) {
          checks.add(_probe(host, port, timeout).then((ok) {
            if (!ok) return;
            final id = '$host:$port';
            final label = port == 9100 ? 'Raw printer' : 'IPP printer';
            found[id] = SavedPrinter(
              id: id,
              name: '$label $host',
              host: host,
              port: port,
            );
          }));
        }
      }
      await Future.wait(checks);
    }

    final saved = await loadSavedPrinters();
    final merged = <String, SavedPrinter>{
      for (final printer in saved) printer.id: printer,
      ...found,
    };
    await _savePrinters(merged.values.toList());
    return merged.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<bool> sendRawPdf({
    required SavedPrinter printer,
    required File file,
  }) async {
    if (!printer.canDirectPrint) return false;
    final socket = await Socket.connect(
      printer.host,
      printer.port,
      timeout: const Duration(seconds: 4),
    );
    try {
      socket.add(await file.readAsBytes());
      await socket.flush();
      await socket.close();
      return true;
    } finally {
      socket.destroy();
    }
  }

  static Future<void> _savePrinters(List<SavedPrinter> printers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedPrintersKey,
      jsonEncode(printers.map((p) => p.toJson()).toList()),
    );
  }

  static Future<bool> _probe(
    String host,
    int port,
    Duration timeout,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  static Future<String?> _localSubnetPrefix() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final parts = address.address.split('.');
        if (parts.length != 4) continue;
        if (parts.first == '127' || parts.first == '169') continue;
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    }
    return null;
  }
}
