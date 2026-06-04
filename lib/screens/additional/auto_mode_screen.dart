import 'package:flutter/material.dart';

import '../../utils/auto_mode_store.dart';
import '../../utils/color_pallets.dart';

class AutoModeScreen extends StatefulWidget {
  static const routeName = "/autoMode";

  const AutoModeScreen({super.key});

  @override
  State<AutoModeScreen> createState() => _AutoModeScreenState();
}

class _AutoModeScreenState extends State<AutoModeScreen> {
  bool _isLoading = true;
  bool _autoModeEnabled = false;
  bool _autoSelectShop = false;
  int _defaultCopies = 1;
  String _defaultQuality = '80gsm';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AutoModeSettings.getAllSettings();
    if (!mounted) return;
    setState(() {
      _autoModeEnabled = settings['autoModeEnabled'] ?? false;
      _autoSelectShop = settings['autoSelectShop'] ?? false;
      _defaultCopies = settings['defaultCopies'] ?? 1;
      _defaultQuality = settings['defaultQuality'] ?? '80gsm';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await AutoModeSettings.setAutoModeEnabled(_autoModeEnabled);
    await AutoModeSettings.setAutoSelectShopEnabled(_autoSelectShop);
    await AutoModeSettings.setDefaultCopies(_defaultCopies);
    await AutoModeSettings.setDefaultQuality(_defaultQuality);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPallets.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 20),
            SizedBox(width: 8),
            Text('Auto Mode'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Quick Print Settings',
                  subtitle: 'Default choices to make checkout feel instant.',
                  icon: Icons.flash_on_rounded,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Auto Mode'),
                      subtitle: const Text(
                        'Apply your preferred print setup to new orders automatically.',
                      ),
                      value: _autoModeEnabled,
                      onChanged: (value) {
                        setState(() => _autoModeEnabled = value);
                        _saveSettings();
                      },
                      activeThumbColor: ColorPallets.deepBlue,
                    ),
                    _buildDropdownTile<int>(
                      title: 'Default Copies',
                      value: _defaultCopies,
                      items: const [1, 2, 3, 4, 5],
                      labelBuilder: (value) => '$value',
                      onChanged: (value) {
                        setState(() => _defaultCopies = value);
                        _saveSettings();
                      },
                    ),
                    _buildDropdownTile<String>(
                      title: 'Default Quality',
                      value: _defaultQuality,
                      items: const ['80gsm', '100gsm', 'bond'],
                      labelBuilder: (value) =>
                          value == 'bond' ? 'Bond' : value.toUpperCase(),
                      onChanged: (value) {
                        setState(() => _defaultQuality = value);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Smart Selection',
                  subtitle: 'Reduce taps when the nearest good shop is obvious.',
                  icon: Icons.storefront_rounded,
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-Select Best Shop'),
                      subtitle: const Text(
                        'Prefer the best nearby shop using distance and rating.',
                      ),
                      value: _autoSelectShop,
                      onChanged: (value) {
                        setState(() => _autoSelectShop = value);
                        _saveSettings();
                      },
                      activeThumbColor: ColorPallets.deepBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(),
              ],
            ),
    );
  }

  Widget _buildHeroCard() {
    final stateLabel = _autoModeEnabled ? 'Ready to fly' : 'Manual control';
    final body = _autoModeEnabled
        ? 'Dittox will prefill your print choices so checkout stays fast.'
        : 'Turn this on when you want fewer taps and more repeatable orders.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [ColorPallets.deepBlue, ColorPallets.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Quick Print 2.0',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            stateLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ColorPallets.deepBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: ColorPallets.deepBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ColorPallets.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: ColorPallets.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: ColorPallets.textPrimary,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ColorPallets.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorPallets.cardBorder),
        ),
        child: DropdownButton<T>(
          value: value,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(16),
          items: items
              .map(
                (entry) => DropdownMenuItem<T>(
                  value: entry,
                  child: Text(labelBuilder(entry)),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: ColorPallets.deepBlue),
              SizedBox(width: 10),
              Text(
                'Auto Mode Summary',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ColorPallets.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Copies', '$_defaultCopies'),
          _summaryRow(
            'Quality',
            _defaultQuality == 'bond' ? 'Bond' : _defaultQuality.toUpperCase(),
          ),
          _summaryRow(
            'Shop selection',
            _autoSelectShop ? 'Automatic' : 'Manual',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ColorPallets.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
