import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/current_user.dart';
import '../../screens/maps/setLocationMaps.dart';
import '../../utils/color_pallets.dart';
import '../../utils/pill_notifications.dart';
import '../../utils/store_auth_store.dart';
import '../../widgets/common/pill_appbar_title.dart';
import 'store_mode_screen.dart';

class StoreLoginScreen extends StatefulWidget {
  static const routeName = "/storeLogin";
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  bool _isRegisterMode = false;
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingTimeCtrl = TextEditingController(text: "09:00");
  final _closingTimeCtrl = TextEditingController(text: "21:00");
  final _bankAccountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _linkedStoreIdCtrl = TextEditingController();
  double _storeLat = 0;
  double _storeLng = 0;
  String _storeMapLabel = "";

  Future<void> _showStorePasswordReset() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset Store Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Store Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    final message = await StoreAuthStore.resetStorePassword(
      email: emailCtrl.text,
      newPassword: passCtrl.text,
    );
    if (!mounted) return;
    if (message != null) {
      PillNotifications.show(context, message: message, type: PillType.error);
      return;
    }
    _emailCtrl.text = emailCtrl.text.trim();
    _passwordCtrl.text = passCtrl.text;
    PillNotifications.show(
      context,
      message: 'Password reset complete. You can sign in now.',
      type: PillType.success,
    );
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    _openingTimeCtrl.dispose();
    _closingTimeCtrl.dispose();
    _bankAccountCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    _linkedStoreIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);

    String? error;
    if (_isRegisterMode) {
      error = await StoreAuthStore.registerStore(
        storeName: _storeNameCtrl.text,
        ownerName: _ownerNameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        storeAddress: _addressCtrl.text,
        openingTime: _openingTimeCtrl.text,
        closingTime: _closingTimeCtrl.text,
        bankAccountNumber: _bankAccountCtrl.text,
        ifscCode: _ifscCtrl.text,
        upiId: _upiCtrl.text,
        linkedStoreId: _linkedStoreIdCtrl.text,
        latitude: _storeLat,
        longitude: _storeLng,
      );
      error ??= await StoreAuthStore.loginStore(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      error = await StoreAuthStore.loginStore(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      PillNotifications.show(
        context,
        message: error,
        type: PillType.error,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StoreModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curUser = Provider.of<CurrentUser>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: PillAppBarTitle(
          title: _isRegisterMode ? 'Create Store Account' : 'Store Sign In',
          icon: Icons.storefront_rounded,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isRegisterMode)
              TextFormField(
                controller: _storeNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Store Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Store name is required"
                    : null,
              ),
            if (_isRegisterMode) const SizedBox(height: 12),
            if (_isRegisterMode)
              TextFormField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Owner Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Owner name is required"
                    : null,
              ),
            if (_isRegisterMode) const SizedBox(height: 12),
            if (_isRegisterMode)
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? "Enter valid phone number"
                    : null,
              ),
            if (_isRegisterMode) const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Store Email",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || !v.contains("@")) ? "Enter valid email" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 6)
                  ? "Password must be at least 6 characters"
                  : null,
            ),
            if (_isRegisterMode) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: "Store Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Address is required"
                    : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SetLocationMaps()),
                    );
                    if (!mounted) return;
                    setState(() {
                      _storeLat = curUser.latitude;
                      _storeLng = curUser.longitude;
                      _storeMapLabel =
                          "${curUser.placeName}, ${curUser.userCountryName}";
                      if (_addressCtrl.text.trim().isEmpty) {
                        _addressCtrl.text = _storeMapLabel;
                      }
                    });
                  },
                  icon: const Icon(Icons.map),
                  label: const Text("Pick Store Location from Google Maps"),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _storeLat == 0 || _storeLng == 0
                    ? "Location not selected"
                    : "Selected: ${_storeLat.toStringAsFixed(6)}, ${_storeLng.toStringAsFixed(6)}",
                style: const TextStyle(color: Colors.black54),
              ),
              if (_storeMapLabel.isNotEmpty)
                Text(
                  _storeMapLabel,
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingTimeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Opens (HH:MM)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _closingTimeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Closes (HH:MM)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Bank Account Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? "Enter valid bank account number"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ifscCtrl,
                decoration: const InputDecoration(
                  labelText: "IFSC Code",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 6)
                    ? "Enter valid IFSC"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _upiCtrl,
                decoration: const InputDecoration(
                  labelText: "UPI ID",
                  hintText: "store@upi",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || !v.contains("@"))
                    ? "Enter valid UPI ID"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkedStoreIdCtrl,
                decoration: const InputDecoration(
                  labelText: "Linked Store ID",
                  hintText: "Leave blank for a new store",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Leave blank to create a new store linked to your account. Use a shop ID from your Dittox admin panel to link an existing registered store.",
                style: TextStyle(color: Colors.black54),
              ),
            ],
            if (!_isRegisterMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showStorePasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPallets.deepBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _loading
                      ? "Please wait..."
                      : (_isRegisterMode ? "Create & Sign In" : "Sign In"),
                ),
              ),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _isRegisterMode = !_isRegisterMode),
              child: Text(
                _isRegisterMode
                    ? "Already have a store account? Sign in"
                    : "New store? Create account",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
