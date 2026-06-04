import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/notification_item.dart';
import '../../providers/app_notifications.dart';
import '../../utils/color_pallets.dart';
import '../../utils/notification_sounds.dart';
import '../../utils/shop_auto_mode_store.dart';

class ShopAutoModeScreen extends StatefulWidget {
  static const routeName = "/shopAutoMode";
  final String shopId;

  const ShopAutoModeScreen({super.key, required this.shopId});

  @override
  State<ShopAutoModeScreen> createState() => _ShopAutoModeScreenState();
}

class _ShopAutoModeScreenState extends State<ShopAutoModeScreen> {
  bool _isLoading = true;
  bool _autoAccept = false;
  bool _autoPrint = false;
  int _printCopies = 1;
  String _printQuality = '80gsm';
  bool _notificationSound = true;
  bool _requireValidation = true;
  int _autoRejectTimeout = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ShopAutoModeStore.getAllSettings(widget.shopId);
    await NotificationSounds.setVibrationEnabled(true);
    await NotificationSounds.setSoundEnabled(
      settings['notificationSound'] ?? true,
    );
    if (!mounted) return;
    setState(() {
      _autoAccept = settings['autoAccept'] ?? false;
      _autoPrint = settings['autoPrint'] ?? false;
      _printCopies = settings['printCopies'] ?? 1;
      _printQuality = settings['printQuality'] ?? '80gsm';
      _notificationSound = settings['notificationSound'] ?? true;
      _requireValidation = settings['requireValidation'] ?? true;
      _autoRejectTimeout = settings['autoRejectTimeout'] ?? 30;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await ShopAutoModeStore.setAutoAcceptEnabled(widget.shopId, _autoAccept);
    await ShopAutoModeStore.setAutoPrintEnabled(widget.shopId, _autoPrint);
    await ShopAutoModeStore.setPrintCopies(widget.shopId, _printCopies);
    await ShopAutoModeStore.setPrintQuality(widget.shopId, _printQuality);
    await ShopAutoModeStore.setNotificationSoundEnabled(
      widget.shopId,
      _notificationSound,
    );
    await ShopAutoModeStore.setValidationRequired(
      widget.shopId,
      _requireValidation,
    );
    await ShopAutoModeStore.setAutoRejectTimeout(
      widget.shopId,
      _autoRejectTimeout,
    );
    await NotificationSounds.setSoundEnabled(_notificationSound);
  }

  Future<void> _updateSetting(
    VoidCallback mutate, {
    String? successTitle,
    String? successBody,
    String type = AppNotification.typeSuccess,
  }) async {
    setState(mutate);
    await _saveSettings();
    if (!mounted || successTitle == null || successBody == null) return;
    final notifs = context.read<AppNotifications>();
    switch (type) {
      case AppNotification.typeInfo:
        notifs.addInfo(title: successTitle, body: successBody);
        break;
      case AppNotification.typeWarning:
        notifs.addWarning(title: successTitle, body: successBody);
        break;
      default:
        notifs.addSuccess(title: successTitle, body: successBody);
    }
  }

  Future<void> _applyQuickAction(String action) async {
    final notifs = context.read<AppNotifications>();
    switch (action) {
      case 'accept_all':
        await _updateSetting(
          () {
            _autoAccept = true;
            _autoPrint = true;
            _requireValidation = false;
            _autoRejectTimeout = 60;
            _notificationSound = true;
          },
          successTitle: 'Fast lane enabled',
          successBody: 'Incoming shop orders will move straight into print.',
        );
        break;
      case 'reject_all':
        await _updateSetting(
          () {
            _autoAccept = false;
            _autoPrint = false;
            _requireValidation = true;
            _autoRejectTimeout = 15;
          },
          successTitle: 'Manual review restored',
          successBody: 'Orders now wait for review instead of auto-flowing.',
          type: AppNotification.typeWarning,
        );
        break;
      case 'print_queue':
        await _updateSetting(
          () {
            _autoPrint = true;
            _printCopies = _printCopies < 1 ? 1 : _printCopies;
          },
          successTitle: 'Print queue primed',
          successBody: 'Auto-print is on and ready for the next accepted order.',
          type: AppNotification.typeInfo,
        );
        break;
      case 'validate_all':
        await _updateSetting(
          () {
            _requireValidation = true;
            _autoAccept = false;
          },
          successTitle: 'Validation locked in',
          successBody: 'Every order will pause for staff confirmation first.',
        );
        break;
      default:
        notifs.addInfo(
          title: 'Quick action unavailable',
          body: 'That shortcut is not wired yet.',
        );
    }
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
            Text('Shop Auto Mode'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      _buildInsightsRow(),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Order Automation',
                        subtitle: 'Tune how fast new jobs move through the store.',
                        icon: Icons.bolt_rounded,
                        children: [
                          _buildSwitchTile(
                            title: 'Auto-Accept Orders',
                            subtitle:
                                'Accept fresh orders without waiting for a tap.',
                            value: _autoAccept,
                            onChanged: (value) => _updateSetting(
                              () => _autoAccept = value,
                              successTitle: value
                                  ? 'Auto-accept enabled'
                                  : 'Auto-accept disabled',
                              successBody: value
                                  ? 'New orders will start moving immediately.'
                                  : 'Orders will wait for manual confirmation.',
                            ),
                          ),
                          _buildSwitchTile(
                            title: 'Require Order Validation',
                            subtitle:
                                'Pause jobs until someone checks customer details.',
                            value: _requireValidation,
                            onChanged: (value) => _updateSetting(
                              () => _requireValidation = value,
                              successTitle: value
                                  ? 'Validation enabled'
                                  : 'Validation skipped',
                              successBody: value
                                  ? 'We will hold jobs before printing.'
                                  : 'Orders can flow straight through.',
                              type: value
                                  ? AppNotification.typeInfo
                                  : AppNotification.typeWarning,
                            ),
                          ),
                          _buildDropdownTile<int>(
                            title: 'Auto-Reject Timeout',
                            subtitle:
                                'Fallback timeout when an order stalls in review.',
                            value: _autoRejectTimeout,
                            items: const [15, 30, 45, 60, 90],
                            labelBuilder: (value) => '$value min',
                            onChanged: (value) => _updateSetting(
                              () => _autoRejectTimeout = value,
                              successTitle: 'Timeout updated',
                              successBody:
                                  'Review timeout is now set to $value minutes.',
                              type: AppNotification.typeInfo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Auto Print Settings',
                        subtitle: 'Set the defaults for jobs that can print instantly.',
                        icon: Icons.print_rounded,
                        children: [
                          _buildSwitchTile(
                            title: 'Enable Auto Print',
                            subtitle:
                                'Push accepted orders directly into the queue.',
                            value: _autoPrint,
                            onChanged: (value) => _updateSetting(
                              () => _autoPrint = value,
                              successTitle: value
                                  ? 'Auto print enabled'
                                  : 'Auto print disabled',
                              successBody: value
                                  ? 'Accepted orders will head straight to print.'
                                  : 'Printing will wait for staff action.',
                            ),
                          ),
                          if (_autoPrint) ...[
                            _buildDropdownTile<int>(
                              title: 'Print Copies',
                              subtitle: 'Default copies for auto-processed jobs.',
                              value: _printCopies,
                              items: const [1, 2, 3, 4, 5],
                              labelBuilder: (value) => '$value',
                              onChanged: (value) => _updateSetting(
                                () => _printCopies = value,
                                successTitle: 'Copies updated',
                                successBody:
                                    'Auto print will use $value copy${value == 1 ? '' : 'ies'}.',
                                type: AppNotification.typeInfo,
                              ),
                            ),
                            _buildDropdownTile<String>(
                              title: 'Paper Quality',
                              subtitle: 'Default stock for auto-printed jobs.',
                              value: _printQuality,
                              items: const ['80gsm', '100gsm', 'bond'],
                              labelBuilder: (value) =>
                                  value == 'bond' ? 'Bond' : value.toUpperCase(),
                              onChanged: (value) => _updateSetting(
                                () => _printQuality = value,
                                successTitle: 'Quality updated',
                                successBody:
                                    'Auto print now prefers ${value == 'bond' ? 'Bond' : value.toUpperCase()}.',
                                type: AppNotification.typeInfo,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Alerts',
                        subtitle: 'Keep the shop feedback loop calm but noticeable.',
                        icon: Icons.notifications_active_rounded,
                        children: [
                          _buildSwitchTile(
                            title: 'Notification Sound',
                            subtitle:
                                'Play a softer chime when store alerts arrive.',
                            value: _notificationSound,
                            onChanged: (value) => _updateSetting(
                              () => _notificationSound = value,
                              successTitle: value
                                  ? 'Sound enabled'
                                  : 'Sound muted',
                              successBody: value
                                  ? 'Store alerts will chime again.'
                                  : 'Popups stay visible but silent.',
                              type: AppNotification.typeInfo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final headline = _autoAccept && _autoPrint
        ? 'Hands-off print flow is active'
        : _requireValidation
            ? 'Orders are staying under review'
            : 'Automation is partially active';

    final subline = _autoPrint
        ? 'Fast queue mode is ready for the next accepted job.'
        : 'Turn on auto print when you want jobs to move without manual queueing.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [ColorPallets.deepBlue, ColorPallets.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPallets.deepBlue.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Store Flow 2.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subline,
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

  Widget _buildInsightsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            label: 'Mode',
            value: _autoAccept ? 'Fast' : 'Manual',
            icon: _autoAccept ? Icons.bolt_rounded : Icons.pan_tool_alt_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            label: 'Queue',
            value: _autoPrint ? 'Auto Print' : 'Staff Queue',
            icon: Icons.print_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorPallets.deepBlue, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: ColorPallets.deepBlue,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: ColorPallets.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ColorPallets.textSecondary),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
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
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ColorPallets.textSecondary),
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

  Widget _buildQuickActions() {
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
              Icon(Icons.flash_on_rounded, color: ColorPallets.deepBlue),
              SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ColorPallets.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'One-tap presets for busy shop moments.',
            style: TextStyle(
              color: ColorPallets.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildQuickActionChip(
                'Accept All',
                Icons.check_circle_rounded,
                () => _applyQuickAction('accept_all'),
              ),
              _buildQuickActionChip(
                'Review Mode',
                Icons.rule_folder_rounded,
                () => _applyQuickAction('reject_all'),
              ),
              _buildQuickActionChip(
                'Print Queue',
                Icons.local_printshop_rounded,
                () => _applyQuickAction('print_queue'),
              ),
              _buildQuickActionChip(
                'Validate All',
                Icons.verified_user_rounded,
                () => _applyQuickAction('validate_all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ColorPallets.deepBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ColorPallets.deepBlue.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: ColorPallets.deepBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
