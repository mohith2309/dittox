import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_notifications.dart';
import '../../providers/app_settings.dart';
import '../../providers/current_user.dart';
import '../../utils/color_pallets.dart';
import '../../utils/notification_sounds.dart';
import '../../utils/ui_sounds.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/user_preferences_store.dart';
import '../../widgets/common/pill_appbar_title.dart';
import '../auth/auth_screen.dart';
import 'support_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = "/settings";

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  String _language = 'English';
  String _distanceUnit = 'km';
  List<String> _savedAddresses = const <String>[];
  String _defaultPayment = 'Wallet';
  Map<String, bool> _emailPrefs = {
    'orders': true,
    'offers': false,
    'newsletter': false
  };
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  String _profilePhotoPath = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await UserPreferencesStore.recordCurrentSession();
    final addresses = await UserPreferencesStore.getSavedAddresses();
    final payment = await UserPreferencesStore.getDefaultPayment();
    final emailPrefs = await UserPreferencesStore.getEmailPrefs();
    final sessions = await UserPreferencesStore.getSessions();
    final photo = await UserPreferencesStore.getProfilePhotoPath();
    final notifications = await UserPreferencesStore.getNotificationsEnabled();
    final sound = await UserPreferencesStore.getSoundEnabled();
    final vibration = await UserPreferencesStore.getVibrationEnabled();
    final language = await UserPreferencesStore.getLanguage();
    final distanceUnit = await UserPreferencesStore.getDistanceUnit();
    if (!mounted) return;
    setState(() {
      _savedAddresses = addresses;
      _defaultPayment = payment;
      _emailPrefs = emailPrefs;
      _sessions = sessions;
      _profilePhotoPath = photo;
      _notifications = notifications;
      _sound = sound;
      _vibration = vibration;
      _language = language;
      _distanceUnit = distanceUnit;
    });
    // Sync with NotificationSounds singleton
    NotificationSounds.setSoundEnabled(sound);
    NotificationSounds.setVibrationEnabled(vibration);
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Settings',
          icon: Icons.settings_rounded,
        ),
        backgroundColor: ColorPallets.deepBlue,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(
              'Notifications', Icons.notifications_active_rounded),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive order updates'),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              UserPreferencesStore.setNotificationsEnabled(v);
            },
            secondary: const Icon(Icons.notifications),
          ),
          _buildNotificationToggles(),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for notifications'),
            value: _sound,
            onChanged: (v) {
              setState(() => _sound = v);
              UserPreferencesStore.setSoundEnabled(v);
              NotificationSounds.setSoundEnabled(v);
            },
            secondary: const Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate for notifications'),
            value: _vibration,
            onChanged: (v) {
              setState(() => _vibration = v);
              UserPreferencesStore.setVibrationEnabled(v);
              NotificationSounds.setVibrationEnabled(v);
            },
            secondary: const Icon(Icons.vibration),
          ),
          _buildSectionHeader('Appearance', Icons.palette_outlined),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: appSettings.isDarkMode,
            onChanged: (v) => context.read<AppSettings>().setDarkMode(v),
            secondary: const Icon(Icons.dark_mode),
          ),
          _buildSectionHeader('Performance', Icons.speed_rounded),
          Consumer<AppSettings>(
            builder: (context, settings, _) => SwitchListTile(
              title: const Text('Potato Mode 🥔'),
              subtitle: const Text(
                  'Disables blur effects and animations. Improves performance on older devices.'),
              value: settings.potatoMode,
              onChanged: (v) => settings.setPotatoMode(v),
              secondary: const Icon(Icons.flash_on_rounded),
            ),
          ),
          Consumer<AppSettings>(
            builder: (context, settings, _) => SwitchListTile(
              title: const Text('Reduce Animations'),
              subtitle: const Text('Skip non-essential transitions'),
              value: settings.reduceAnimations,
              onChanged: settings.potatoMode
                  ? null
                  : (v) => settings.setReduceAnimations(v),
              secondary: const Icon(Icons.animation_rounded),
            ),
          ),
          Consumer<AppSettings>(
            builder: (context, settings, _) => SwitchListTile(
              title: const Text('UI Sounds & Haptics'),
              subtitle: const Text(
                  'Haptic feedback and sounds on button taps and tab switches'),
              value: settings.uiSounds,
              onChanged: (v) => settings.setUiSounds(v),
              secondary: const Icon(Icons.touch_app_rounded),
            ),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            leading: const Icon(Icons.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguagePicker,
          ),
          _buildSectionHeader('Location', Icons.location_on_outlined),
          ListTile(
            title: const Text('Distance Unit'),
            subtitle: Text(_distanceUnit),
            leading: const Icon(Icons.straighten),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDistancePicker,
          ),
          _buildSectionHeader('Order Preferences', Icons.shopping_bag_outlined),
          ListTile(
            title: const Text('Saved Addresses'),
            subtitle: Text(_savedAddresses.isEmpty
                ? 'No saved addresses'
                : '${_savedAddresses.length} saved'),
            leading: const Icon(Icons.location_city_rounded),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAddressesSheet,
          ),
          ListTile(
            title: const Text('Default Payment Method'),
            subtitle: Text(_defaultPayment),
            leading: const Icon(Icons.payments_rounded),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDefaultPaymentPicker,
          ),
          _buildSectionHeader(
              'Account Preferences', Icons.manage_accounts_outlined),
          ListTile(
            title: const Text('Profile Photo'),
            subtitle: Text(_profilePhotoPath.isEmpty
                ? 'No local photo selected'
                : 'Photo selected'),
            leading: const Icon(Icons.account_circle_rounded),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickProfilePhoto,
          ),
          Consumer<CurrentUser>(
            builder: (context, user, _) {
              final phone = user.getUserPhoneNumber;
              final verified = phone.trim().length >= 10 ||
                  FirebaseAuth.instance.currentUser?.phoneNumber != null;
              return ListTile(
                title: const Text('Phone Verification'),
                subtitle:
                    Text(phone.trim().isEmpty ? 'No phone number' : phone),
                leading: Icon(
                  verified
                      ? Icons.verified_rounded
                      : Icons.error_outline_rounded,
                  color: verified ? ColorPallets.deepBlue : Colors.orange,
                ),
                trailing: Text(verified ? 'Verified' : 'Pending'),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Order Emails'),
            subtitle: const Text('Receipts and order updates'),
            value: _emailPrefs['orders'] == true,
            secondary: const Icon(Icons.receipt_long_rounded),
            onChanged: (value) => _setEmailPref('orders', value),
          ),
          SwitchListTile(
            title: const Text('Offer Emails'),
            subtitle: const Text('Coupons and promotions'),
            value: _emailPrefs['offers'] == true,
            secondary: const Icon(Icons.local_offer_rounded),
            onChanged: (value) => _setEmailPref('offers', value),
          ),
          SwitchListTile(
            title: const Text('Newsletter Emails'),
            subtitle: const Text('Dittox news and tips'),
            value: _emailPrefs['newsletter'] == true,
            secondary: const Icon(Icons.email_rounded),
            onChanged: (value) => _setEmailPref('newsletter', value),
          ),
          ListTile(
            title: const Text('Active Sessions'),
            subtitle: Text('${_sessions.length} session(s)'),
            leading: const Icon(Icons.devices_rounded),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSessionsSheet,
          ),
          ListTile(
            title: const Text('Export Account Data'),
            subtitle: const Text('Copy a JSON export to clipboard'),
            leading: const Icon(Icons.download_rounded),
            onTap: _exportAccountData,
          ),
          _buildSectionHeader('About', Icons.info_outline_rounded),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl('https://dittox.in/privacy'),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl('https://dittox.in/terms'),
          ),
          ListTile(
            title: const Text('Help & Support'),
            leading: const Icon(Icons.help),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).pushNamed(SupportCenterScreen.routeName),
          ),
          ListTile(
            title: const Text('About Dittox'),
            subtitle: const Text('Version 1.0.0'),
            leading: const Icon(Icons.info),
            onTap: () => _showAbout(),
          ),
          _buildSectionHeader('Account', Icons.manage_accounts_rounded),
          ListTile(
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: _confirmSignOut,
          ),
          ListTile(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _confirmDeleteAccount,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: ColorPallets.deepBlue,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPallets.deepBlue,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggles() {
    if (!_notifications) return const SizedBox.shrink();
    return Consumer<AppNotifications>(
      builder: (context, notifs, child) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Order Updates'),
              subtitle:
                  const Text('Order accepted, printing, ready, collected'),
              value: notifs.orderUpdatesEnabled,
              onChanged: (v) => notifs.toggleOrderUpdates(v),
              secondary: const Icon(Icons.local_shipping_outlined),
            ),
            SwitchListTile(
              title: const Text('Store Alerts'),
              subtitle: const Text('Issues, delays, important store updates'),
              value: notifs.storeAlertsEnabled,
              onChanged: (v) => notifs.toggleStoreAlerts(v),
              secondary: const Icon(Icons.warning_amber_rounded),
            ),
            SwitchListTile(
              title: const Text('Offers & Tips'),
              subtitle: const Text('Promotions and helpful tips'),
              value: notifs.offersEnabled,
              onChanged: (v) => notifs.toggleOffers(v),
              secondary: const Icon(Icons.celebration_outlined),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('English'),
            trailing: _language == 'English' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _language = 'English');
              UserPreferencesStore.setLanguage('English');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Hindi'),
            trailing: _language == 'Hindi' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _language = 'Hindi');
              UserPreferencesStore.setLanguage('Hindi');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Kannada'),
            trailing: _language == 'Kannada' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _language = 'Kannada');
              UserPreferencesStore.setLanguage('Kannada');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDistancePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Kilometers (km)'),
            trailing: _distanceUnit == 'km' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _distanceUnit = 'km');
              UserPreferencesStore.setDistanceUnit('km');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Miles (mi)'),
            trailing: _distanceUnit == 'mi' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _distanceUnit = 'mi');
              UserPreferencesStore.setDistanceUnit('mi');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddressesSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text('Saved Addresses'),
                    subtitle: Text('Used for delivery checkout'),
                    leading: Icon(Icons.location_on_rounded),
                  ),
                  for (final address in _savedAddresses)
                    ListTile(
                      title: Text(address),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await UserPreferencesStore.removeAddress(address);
                          await _loadPrefs();
                          setSheetState(() {});
                        },
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final added = await _showAddAddressDialog();
                        if (added) setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Address'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    await _loadPrefs();
  }

  Future<bool> _showAddAddressDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Address'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'House/hostel, street, area, city',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return false;
    await UserPreferencesStore.addAddress(value);
    await _loadPrefs();
    return true;
  }

  void _showDefaultPaymentPicker() {
    const methods = ['Wallet', 'Razorpay', 'UPI', 'Pay Later'];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) {
            return ListTile(
              title: Text(method),
              trailing:
                  _defaultPayment == method ? const Icon(Icons.check) : null,
              onTap: () async {
                await UserPreferencesStore.setDefaultPayment(method);
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadPrefs();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _setEmailPref(String key, bool value) async {
    await UserPreferencesStore.setEmailPref(key, value);
    await _loadPrefs();
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    await UserPreferencesStore.setProfilePhotoPath(path);
    await _loadPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo saved locally')),
    );
  }

  void _showSessionsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Active Sessions'),
                subtitle: Text('Local session records for this account'),
                leading: Icon(Icons.devices_rounded),
              ),
              for (final session in _sessions)
                ListTile(
                  title: Text((session['label'] ?? 'Device').toString()),
                  subtitle: Text((session['lastActive'] ?? '').toString()),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await UserPreferencesStore.clearSessions();
                    await UserPreferencesStore.recordCurrentSession();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _loadPrefs();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out other sessions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAccountData() async {
    final user = context.read<CurrentUser>().userMap;
    final export = await UserPreferencesStore.exportUserData(user);
    await Clipboard.setData(ClipboardData(text: export));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account data copied to clipboard')),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Dittox',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: ColorPallets.deepBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.print,
          color: Colors.white,
          size: 40,
        ),
      ),
      children: [
        const Text(
          'Print Anywhere, Anytime',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _confirmSignOut() {
    UiSounds.tap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('AccessToken');
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await DemoOrdersStore.clearAllOrders();
              await UserPreferencesStore.clearAccountPreferences();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('AccessToken');
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
