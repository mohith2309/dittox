import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/printer_service.dart';

class PrinterSelectionResult {
  final SavedPrinter printer;
  final String workflowNote;

  const PrinterSelectionResult({
    required this.printer,
    required this.workflowNote,
  });
}

class PrinterSelectionSheet extends StatefulWidget {
  const PrinterSelectionSheet({super.key});

  static Future<PrinterSelectionResult?> show(BuildContext context) {
    return showModalBottomSheet<PrinterSelectionResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PrinterSelectionSheet(),
    );
  }

  @override
  State<PrinterSelectionSheet> createState() => _PrinterSelectionSheetState();
}

class _PrinterSelectionSheetState extends State<PrinterSelectionSheet> {
  final TextEditingController _workflowController = TextEditingController();
  List<SavedPrinter> _printers = const <SavedPrinter>[];
  SavedPrinter? _selected;
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _workflowController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await PrinterService.loadSavedPrinters();
    final last = await PrinterService.loadLastPrinter();
    if (!mounted) return;
    setState(() {
      _printers = saved;
      _selected = last ?? (saved.isNotEmpty ? saved.first : null);
      _workflowController.text = _selected?.workflowNote ?? '';
      _loading = false;
    });
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final scanned = await PrinterService.scanNetworkPrinters();
    if (!mounted) return;
    setState(() {
      _printers = scanned;
      _selected ??= scanned.isNotEmpty ? scanned.first : null;
      _scanning = false;
    });
  }

  Future<void> _addManualPrinter() async {
    final hostController = TextEditingController();
    final nameController = TextEditingController();
    final portController = TextEditingController(text: '9100');
    final result = await showDialog<SavedPrinter>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Printer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Printer name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'IP address'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final host = hostController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 9100;
              if (host.isEmpty) return;
              Navigator.of(context).pop(
                SavedPrinter(
                  id: '$host:$port',
                  name: nameController.text.trim().isEmpty
                      ? 'Printer $host'
                      : nameController.text.trim(),
                  host: host,
                  port: port,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    hostController.dispose();
    nameController.dispose();
    portController.dispose();

    if (result == null) return;
    await PrinterService.savePrinter(result);
    await _load();
    if (!mounted) return;
    setState(() => _selected = result);
  }

  Future<void> _confirm() async {
    final printer = _selected;
    if (printer == null) return;
    final updated = printer.copyWith(
      workflowNote: _workflowController.text.trim(),
    );
    await PrinterService.rememberLastPrinter(updated);
    if (!mounted) return;
    Navigator.of(context).pop(
      PrinterSelectionResult(
        printer: updated,
        workflowNote: updated.workflowNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottom + 18),
      child: _loading
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_rounded, color: ColorPallets.deepBlue),
                    SizedBox(width: 10),
                    Text(
                      'Select Printer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<SavedPrinter>(
                  initialValue: _selected,
                  items: _printers.map((printer) {
                    return DropdownMenuItem(
                      value: printer,
                      child: Text(
                        '${printer.name} (${printer.host}:${printer.port})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (printer) {
                    setState(() {
                      _selected = printer;
                      _workflowController.text = printer?.workflowNote ?? '';
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Saved printers',
                    prefixIcon: Icon(Icons.local_printshop_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scanning ? null : _scan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find_rounded),
                        label: Text(_scanning ? 'Scanning...' : 'Auto-detect'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addManualPrinter,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add manual'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workflowController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Something else',
                    hintText: 'Describe your workflow',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selected == null ? null : _confirm,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Send to Printer'),
                  ),
                ),
                if (_printers.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No saved printers yet. Scan the same WiFi or add an IP address.',
                    style: TextStyle(color: ColorPallets.textSecondary),
                  ),
                ],
              ],
            ),
    );
  }
}
